import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  final StorageService _storageService;

  GoogleDriveService(this._storageService);

  // Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        // Save user info to local storage
        await _storageService.saveUserInfo(
          userId: account.id,
          email: account.email,
          displayName: account.displayName ?? account.email.split('@').first,
        );
      }
      return account;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storageService.clearUserInfo();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
      rethrow;
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get authenticated HTTP client
  Future<http.Client> _getAuthenticatedHttpClient() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw Exception('User not signed in');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final Map<String, String> authHeaders = {
      'Authorization': 'Bearer ${auth.accessToken}',
      'Content-Type': 'application/json',
    };

    return _AuthenticatedClient(http.Client(), authHeaders);
  }

  // Upload data to Google Drive
  Future<String> uploadToDrive({
    required String fileName,
    required String mimeType,
    required String content,
    String? folderId,
  }) async {
    try {
      final client = await _getAuthenticatedHttpClient();
      final driveApi = drive.DriveApi(client);

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(content);

      // Create drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = mimeType;

      if (folderId != null) {
        driveFile.parents = [folderId];
      }

      // Upload file to drive
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(tempFile.openRead(), tempFile.lengthSync()),
      );

      // Delete temp file
      await tempFile.delete();

      return uploadedFile.id!;
    } catch (e) {
      debugPrint('Error uploading to Drive: $e');
      rethrow;
    }
  }

  // Download file from Google Drive
  Future<String> downloadFromDrive(String fileId) async {
    try {
      final client = await _getAuthenticatedHttpClient();
      final driveApi = drive.DriveApi(client);

      // Get file
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the media content
      final List<int> dataStore = [];
      await media.stream.forEach((data) {
        dataStore.insertAll(dataStore.length, data);
      });

      return utf8.decode(dataStore);
    } catch (e) {
      debugPrint('Error downloading from Drive: $e');
      rethrow;
    }
  }

  // Create a folder in Google Drive
  Future<String> createFolder(String folderName) async {
    try {
      final client = await _getAuthenticatedHttpClient();
      final driveApi = drive.DriveApi(client);

      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id!;
    } catch (e) {
      debugPrint('Error creating folder in Drive: $e');
      rethrow;
    }
  }

  // Find file or folder in Google Drive
  Future<String?> findFileOrFolder(String name, {bool isFolder = false}) async {
    try {
      final client = await _getAuthenticatedHttpClient();
      final driveApi = drive.DriveApi(client);

      final String query = isFolder
          ? "name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
          : "name = '$name' and trashed = false";

      final fileList = await driveApi.files.list(q: query);
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding file/folder in Drive: $e');
      rethrow;
    }
  }

  // Backup user data to Google Drive
  Future<String> backupUserData() async {
    try {
      // Export all user data
      final String userData = await _storageService.exportUserData();

      // Find app folder or create it
      final String appFolderName = 'WasteSegregationApp';
      String? folderId = await findFileOrFolder(appFolderName, isFolder: true);

      folderId ??= await createFolder(appFolderName);

      // Backup file name with timestamp
      final String fileName =
          'waste_seg_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Upload backup to drive
      return await uploadToDrive(
        fileName: fileName,
        mimeType: 'application/json',
        content: userData,
        folderId: folderId,
      );
    } catch (e) {
      debugPrint('Error backing up user data: $e');
      rethrow;
    }
  }

  // Restore user data from Google Drive
  Future<void> restoreUserData(String fileId) async {
    try {
      final String userData = await downloadFromDrive(fileId);
      await _storageService.importUserData(userData);
    } catch (e) {
      debugPrint('Error restoring user data: $e');
      rethrow;
    }
  }

  // List backup files in Google Drive
  Future<List<Map<String, String>>> listBackupFiles() async {
    try {
      final client = await _getAuthenticatedHttpClient();
      final driveApi = drive.DriveApi(client);

      // Find app folder
      final String appFolderName = 'WasteSegregationApp';
      final String? folderId =
          await findFileOrFolder(appFolderName, isFolder: true);

      if (folderId == null) {
        return [];
      }

      // List files in the folder
      final String query =
          "'$folderId' in parents and name contains 'waste_seg_backup_' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files == null) {
        return [];
      }

      // Convert to list of maps with id and name
      return fileList.files!.map((file) {
        return {
          'id': file.id!,
          'name': file.name!,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error listing backup files: $e');
      rethrow;
    }
  }
}

// Custom HTTP Client for authentication
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _client;
  final Map<String, String> _headers;

  _AuthenticatedClient(this._client, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
