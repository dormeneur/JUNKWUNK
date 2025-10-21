import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/google_drive_service.dart';

class ImageUploader {
  static final GoogleDriveService _driveService = GoogleDriveService();

  static Future<String?> pickAndUploadImage(BuildContext context) async {
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

      // Generate filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'lost_found_$timestamp.jpg';
      debugPrint('Generated filename: $fileName');

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

      // Upload to Google Drive
      debugPrint('Starting upload to Google Drive...');
      final String? downloadURL =
          await _driveService.uploadFile(fileToUpload, fileName);
      debugPrint('Received URL: $downloadURL');

      if (downloadURL == null) {
        debugPrint('Upload failed - no URL returned');
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to upload image');
          return null;
        }
      }

      return downloadURL;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
