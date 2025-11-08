import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/s3_service.dart';
import '../utils/custom_toast.dart';

class ImageUploader {
  static final S3Service _s3Service = S3Service();

  static Future<String?> pickAndUploadImage(BuildContext context,
      {String folder = 'images'}) async {
    debugPrint('Starting image upload process...');
    final ImagePicker picker = ImagePicker();

    try {
      debugPrint('Picking image from gallery...');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('No image selected');
        return null;
      }
      debugPrint('Image selected: ${image.path}');

      // Handle file based on platform
      dynamic fileToUpload;
      if (kIsWeb) {
        // For web, convert to bytes
        final bytes = await image.readAsBytes();
        fileToUpload = bytes;
      } else {
        // For mobile, create a File instance
        fileToUpload = File(image.path);
      }

      // Upload to S3
      debugPrint('Starting upload to S3...');
      final String? objectKey =
          await _s3Service.uploadImage(fileToUpload, folder);
      debugPrint('Received S3 key: $objectKey');

      if (objectKey == null) {
        debugPrint('Upload failed - no key returned');
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to upload image');
          return null;
        }
      }

      // Return the S3 object key (we'll get the URL when displaying)
      return objectKey;
    } catch (e, stackTrace) {
      debugPrint('Error in image upload: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to upload image');
        return null;
      }
    }
    return null;
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    CustomToast.showError(context, message);
  }
}
