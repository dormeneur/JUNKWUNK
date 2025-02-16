import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleDriveService {
  static const _scope = [drive.DriveApi.driveFileScope];
  static const _credentialsPath = 'assets/credentials/service_account.json';
  static const _folderId = '1GduVgC80KAdbbfu0FVZ94CLdCLf98WT9';

  Future<String?> uploadFile(dynamic file, String filename) async {
    try {
      print('Starting upload process...');

      // Load credentials
      print('Reading credentials file...');
      final String jsonString = await rootBundle.loadString(_credentialsPath);
      print('Successfully read credentials file');

      print('Parsing service account credentials...');
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      print('Successfully parsed credentials');

      print('Getting authenticated client...');
      final client = await clientViaServiceAccount(credentials, _scope);
      print('Successfully got authenticated client');

      try {
        print('Initializing Drive API...');
        final driveApi = drive.DriveApi(client);

        // Create Drive file metadata
        print('Creating Drive file metadata...');
        var fileMetadata = drive.File()
          ..name = filename
          ..parents = [_folderId];

        // Handle file upload based on platform
        print('Starting file upload to Drive...');
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
        print('Upload response received. File ID: ${uploadResponse.id}');

        if (uploadResponse.id == null) {
          print('Error: File uploaded but no ID returned');
          return null;
        }

        // Set public permissions
        print('Setting public permissions...');
        await driveApi.permissions.create(
          drive.Permission()
            ..type = 'anyone'
            ..role = 'reader',
          uploadResponse.id!,
        );
        print('Public permissions set successfully');

        // Get shareable link
        print('Retrieving shareable link...');
        final sharedFile = await driveApi.files.get(
          uploadResponse.id!,
          $fields: 'webViewLink',
        ) as drive.File;

        String? webViewLink = sharedFile.webViewLink;
        if (webViewLink == null) {
          print('Error: No webViewLink available');
          return null;
        }
        print('Successfully retrieved webViewLink: $webViewLink');

        final fileId = webViewLink.split('/d/')[1].split('/view')[0];
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      } finally {
        print('Closing client connection...');
        client.close();
      }
    } catch (e, stack) {
      print('Error in uploadFile: $e');
      print('Stack trace: $stack');
      return null;
    }
  }
}
