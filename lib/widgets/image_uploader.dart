import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/google_drive_service.dart';

/// Conditional import for File (only for mobile)
import 'dart:io' show File;

class ImageUploader {
  static final GoogleDriveService _driveService = GoogleDriveService();

  static Future<String?> pickAndUploadImage(BuildContext context) async {
    print('Starting image upload process...');
    final ImagePicker picker = ImagePicker();

    try {
      print('Picking image from gallery...');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('No image selected');
        return null;
      }
      print('Image selected: ${image.path}');

      // Generate filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'lost_found_$timestamp.jpg';
      print('Generated filename: $fileName');

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
      print('Starting upload to Google Drive...');
      final String? downloadURL =
          await _driveService.uploadFile(fileToUpload, fileName);
      print('Received URL: $downloadURL');

      if (downloadURL == null) {
        print('Upload failed - no URL returned');
        _showErrorSnackBar(context, 'Failed to upload image');
        return null;
      }

      return downloadURL;
    } catch (e, stackTrace) {
      print('Error in image upload: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar(context, 'Failed to upload image');
      return null;
    }
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
