import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// AWS S3 Upload Service
/// Handles image uploads to S3 bucket with direct PUT requests
///
/// ⚠️ IMPORTANT: AWS credentials are loaded from .env file
/// Make sure .env file contains AWS_ACCESS_KEY and AWS_SECRET_KEY
class S3Service {
  static const String _bucketName = 'junkwunk-images-ap-south-1';
  static const String _region = 'ap-south-1';

  // AWS credentials loaded from .env file
  static String get _accessKey => dotenv.env['AWS_ACCESS_KEY'] ?? '';
  static String get _secretKey => dotenv.env['AWS_SECRET_KEY'] ?? '';

  /// Upload file to S3
  /// Returns the S3 object key (path) on success, null on failure
  Future<String?> uploadImage(dynamic file, String folder) async {
    try {
      debugPrint('S3: Starting upload process...');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension =
          file is File ? path.extension(file.path) : '.jpg'; // Default for web
      final fileName = '$timestamp$extension';
      final objectKey = '$folder/$fileName';

      debugPrint('S3: Object key: $objectKey');

      // Get file bytes
      List<int> fileBytes;
      if (file is File) {
        fileBytes = await file.readAsBytes();
      } else if (file is List<int>) {
        fileBytes = file;
      } else {
        debugPrint('S3: Unsupported file type');
        return null;
      }

      // Upload to S3 using HTTP PUT
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$objectKey';

      // Create date for AWS signature
      final now = DateTime.now().toUtc();
      final dateStamp = _formatDate(now);
      final amzDate = _formatDateTime(now);

      // Create canonical request
      final contentType = 'image/jpeg';
      final payloadHash = sha256.convert(fileBytes).toString();

      final headers = {
        'Host': '$_bucketName.s3.$_region.amazonaws.com',
        'Content-Type': contentType,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
      };

      // Generate AWS Signature V4
      final authorization = _generateSignature(
        method: 'PUT',
        uri: '/$objectKey',
        headers: headers,
        payloadHash: payloadHash,
        dateStamp: dateStamp,
        amzDate: amzDate,
      );

      headers['Authorization'] = authorization;

      debugPrint('S3: Uploading to $url');

      // Upload file
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        debugPrint('S3: Upload successful!');
        return objectKey;
      } else {
        debugPrint('S3: Upload failed with status ${response.statusCode}');
        debugPrint('S3: Response: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('S3: Error uploading file: $e');
      debugPrint('S3: Stack trace: $stack');
      return null;
    }
  }

  /// Get viewable URL for an image (generates presigned URL valid for 1 hour)
  Future<String> getImageUrl(String objectKey) async {
    try {
      final now = DateTime.now().toUtc();
      final dateStamp = _formatDate(now);
      final amzDate = _formatDateTime(now);
      const expirationSeconds = 3600; // 1 hour

      // Create canonical request for presigned URL
      final credential = '$_accessKey/$dateStamp/$_region/s3/aws4_request';

      final queryParams = {
        'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
        'X-Amz-Credential': credential,
        'X-Amz-Date': amzDate,
        'X-Amz-Expires': expirationSeconds.toString(),
        'X-Amz-SignedHeaders': 'host',
      };

      // Sort query params
      final sortedParams = queryParams.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      final canonicalQueryString = sortedParams
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final canonicalRequest = [
        'GET',
        '/$objectKey',
        canonicalQueryString,
        'host:$_bucketName.s3.$_region.amazonaws.com',
        '',
        'host',
        'UNSIGNED-PAYLOAD',
      ].join('\n');

      final stringToSign = [
        'AWS4-HMAC-SHA256',
        amzDate,
        '$dateStamp/$_region/s3/aws4_request',
        sha256.convert(utf8.encode(canonicalRequest)).toString(),
      ].join('\n');

      final signature = _calculateSignature(stringToSign, dateStamp);

      final url =
          'https://$_bucketName.s3.$_region.amazonaws.com/$objectKey?$canonicalQueryString&X-Amz-Signature=$signature';

      return url;
    } catch (e) {
      debugPrint('S3: Error generating presigned URL: $e');
      // Return direct URL as fallback (won't work for private buckets)
      return 'https://$_bucketName.s3.$_region.amazonaws.com/$objectKey';
    }
  }

  /// Delete image from S3
  Future<bool> deleteImage(String objectKey) async {
    try {
      debugPrint('S3: Deleting $objectKey');

      final now = DateTime.now().toUtc();
      final dateStamp = _formatDate(now);
      final amzDate = _formatDateTime(now);

      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/$objectKey';

      final headers = {
        'Host': '$_bucketName.s3.$_region.amazonaws.com',
        'x-amz-date': amzDate,
        'x-amz-content-sha256': sha256.convert([]).toString(),
      };

      final authorization = _generateSignature(
        method: 'DELETE',
        uri: '/$objectKey',
        headers: headers,
        payloadHash: sha256.convert([]).toString(),
        dateStamp: dateStamp,
        amzDate: amzDate,
      );

      headers['Authorization'] = authorization;

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('S3: Delete successful!');
        return true;
      } else {
        debugPrint('S3: Delete failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('S3: Error deleting file: $e');
      return false;
    }
  }

  // Helper methods for AWS Signature V4
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0].replaceAll('-', '');
  }

  String _formatDateTime(DateTime date) {
    return '${date
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')[0]}Z';
  }

  String _generateSignature({
    required String method,
    required String uri,
    required Map<String, String> headers,
    required String payloadHash,
    required String dateStamp,
    required String amzDate,
  }) {
    // Create canonical headers
    final sortedHeaders = headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    final canonicalHeaders = sortedHeaders
        .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}')
        .join('\n');

    final signedHeaders =
        sortedHeaders.map((e) => e.key.toLowerCase()).join(';');

    // Create canonical request
    final canonicalRequest = [
      method,
      uri,
      '',
      canonicalHeaders,
      '',
      signedHeaders,
      payloadHash,
    ].join('\n');

    // Create string to sign
    final credentialScope = '$dateStamp/$_region/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    // Calculate signature
    final signature = _calculateSignature(stringToSign, dateStamp);

    // Create authorization header
    return 'AWS4-HMAC-SHA256 Credential=$_accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';
  }

  String _calculateSignature(String stringToSign, String dateStamp) {
    final kDate =
        _hmacSha256(utf8.encode('AWS4$_secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmacSha256(kDate, utf8.encode(_region));
    final kService = _hmacSha256(kRegion, utf8.encode('s3'));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));

    return signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }
}
