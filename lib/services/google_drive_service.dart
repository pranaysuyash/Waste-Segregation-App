import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import '../models/user_profile.dart';

class GoogleDriveService {

  GoogleDriveService(this._storageService);
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  final StorageService _storageService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to fetch UserProfile from Firestore
  Future<UserProfile?> _fetchUserProfileFromFirestore(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserProfile.fromJson(docSnapshot.data()!);
      }
      debugPrint('No user profile found in Firestore for user ID: $userId');
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile $userId from Firestore: $e');
      return null; 
    }
  }

  // Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final userId = account.id;
        var userProfile = await _fetchUserProfileFromFirestore(userId);

        if (userProfile == null) {
          // Truly new user, or Firestore fetch failed. Create a new UserProfile.
          debugPrint('Creating new UserProfile for user ID: $userId');
          userProfile = UserProfile(
            id: userId,
            email: account.email,
            displayName: account.displayName ?? account.email.split('@').first,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
            photoUrl: account.photoUrl,
            // gamificationProfile will be null here, and GamificationService will handle its creation
          );
        } else {
          // Existing user, update relevant fields
          debugPrint('Found existing UserProfile for user ID: $userId. Updating fields.');
          userProfile = userProfile.copyWith(
            lastActive: DateTime.now(),
            displayName: account.displayName ?? userProfile.displayName,
            email: account.email, // Keep email updated
            photoUrl: account.photoUrl ?? userProfile.photoUrl,
          );
        }
        
        // Save the fetched/updated or newly created UserProfile to local storage
        await _storageService.saveUserProfile(userProfile);
        debugPrint('UserProfile for $userId saved locally after sign-in.');

        // Optional: If it was a new user, explicitly save to Firestore now.
        // Otherwise, CloudStorageService.saveUserProfileToFirestore will be called 
        // by other services (like GamificationService) when they make changes.
        // For a new user, ensuring their basic profile exists in Firestore early can be beneficial.
        if (userProfile.createdAt == userProfile.lastActive) { // Heuristic for new profile
             try {
               await _firestore
                   .collection('users')
                   .doc(userProfile.id)
                   .set(userProfile.toJson(), SetOptions(merge: true));
                debugPrint('New UserProfile for $userId also synced to Firestore.');
             } catch (e) {
                debugPrint('Error syncing new UserProfile $userId to Firestore immediately: $e');
             }
        }
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
    return _googleSignIn.isSignedIn();
  }

  // Get authenticated HTTP client
  Future<http.Client> _getAuthenticatedHttpClient() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw Exception('User not signed in');
    }

    final auth = await account.authentication;
    final authHeaders = <String, String>{
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
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the media content
      final dataStore = <int>[];
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

      final query = isFolder
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
      final userData = await _storageService.exportUserData();

      // Find app folder or create it
      const appFolderName = 'WasteSegregationApp';
      var folderId = await findFileOrFolder(appFolderName, isFolder: true);

      folderId ??= await createFolder(appFolderName);

      // Backup file name with timestamp
      final fileName =
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
      final userData = await downloadFromDrive(fileId);
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
      const appFolderName = 'WasteSegregationApp';
      final folderId =
          await findFileOrFolder(appFolderName, isFolder: true);

      if (folderId == null) {
        return [];
      }

      // List files in the folder
      final query =
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

  _AuthenticatedClient(this._client, this._headers);
  final http.Client _client;
  final Map<String, String> _headers;

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
