import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleDriveService {
  static const _scope = [drive.DriveApi.driveFileScope];
  static const _credentialsPath = 'assets/credentials/service_account.json';
  static const _folderId = '1GduVgC80KAdbbfu0FVZ94CLdCLf98WT9';

  Future<String?> uploadFile(dynamic file, String filename) async {
    try {
      debugPrint('Starting upload process...');

      // Load credentials
      debugPrint('Reading credentials file...');
      final String jsonString = await rootBundle.loadString(_credentialsPath);
      debugPrint('Successfully read credentials file');

      debugPrint('Parsing service account credentials...');
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      debugPrint('Successfully parsed credentials');

      debugPrint('Getting authenticated client...');
      final client = await clientViaServiceAccount(credentials, _scope);
      debugPrint('Successfully got authenticated client');

      try {
        debugPrint('Initializing Drive API...');
        final driveApi = drive.DriveApi(client);

        // Create Drive file metadata
        debugPrint('Creating Drive file metadata...');
        var fileMetadata = drive.File()
          ..name = filename
          ..parents = [_folderId];

        // Handle file upload based on platform
        debugPrint('Starting file upload to Drive...');
        late final drive.File uploadResponse;

        if (file is List<int>) {
          // Handle web upload (bytes)
          uploadResponse = await driveApi.files.create(
            fileMetadata,
            uploadMedia: drive.Media(
              Stream.fromIterable([file]),
              file.length,
            ),
            $fields: 'id,webViewLink',
          );
        } else {
          // Handle mobile upload (File)
          final ioFile = file as File;
          uploadResponse = await driveApi.files.create(
            fileMetadata,
            uploadMedia: drive.Media(
              ioFile.openRead(),
              await ioFile.length(),
            ),
            $fields: 'id,webViewLink',
          );
        }

        // Rest of your code remains the same...
        debugPrint('Upload response received. File ID: ${uploadResponse.id}');

        if (uploadResponse.id == null) {
          debugPrint('Error: File uploaded but no ID returned');
          return null;
        }

        // Set public permissions
        debugPrint('Setting public permissions...');
        await driveApi.permissions.create(
          drive.Permission()
            ..type = 'anyone'
            ..role = 'reader',
          uploadResponse.id!,
        );
        debugPrint('Public permissions set successfully');

        // Get shareable link
        debugPrint('Retrieving shareable link...');
        final sharedFile = await driveApi.files.get(
          uploadResponse.id!,
          $fields: 'webViewLink',
        ) as drive.File;

        String? webViewLink = sharedFile.webViewLink;
        if (webViewLink == null) {
          debugPrint('Error: No webViewLink available');
          return null;
        }
        debugPrint('Successfully retrieved webViewLink: $webViewLink');

        final fileId = webViewLink.split('/d/')[1].split('/view')[0];
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      } finally {
        debugPrint('Closing client connection...');
        client.close();
      }
    } catch (e, stack) {
      debugPrint('Error in uploadFile: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }
}
