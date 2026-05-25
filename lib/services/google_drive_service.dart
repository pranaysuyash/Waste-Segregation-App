import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import '../models/user_profile.dart';
import '../utils/safe_file_path.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

class GoogleDriveService {
  GoogleDriveService(
    this._storageService, {
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    Future<Directory> Function()? temporaryDirectoryProvider,
    Future<http.Client> Function()? authenticatedHttpClientOverride,
  })  : _googleSignIn = googleSignIn ??
            (kIsWeb
                ? null
                : GoogleSignIn(
                    scopes: [
                      'email',
                      'https://www.googleapis.com/auth/drive.file',
                    ],
                  )),
        _firestore = firestore,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _authenticatedHttpClientOverride = authenticatedHttpClientOverride;

  final GoogleSignIn? _googleSignIn;
  final StorageService _storageService;
  final FirebaseFirestore? _firestore;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  final Future<http.Client> Function()? _authenticatedHttpClientOverride;

  Future<UserCredential> _signInToFirebaseAuth(
    GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  FirebaseFirestore get _firestoreInstance =>
      _firestore ?? FirebaseFirestore.instance;

  String _safeIdPrefix(String value, {int length = 16}) {
    if (value.length <= length) return value;
    return value.substring(0, length);
  }

  // Helper method to fetch UserProfile from Firestore
  Future<UserProfile?> _fetchUserProfileFromFirestore(String userId) async {
    try {
      final docSnapshot = await _firestoreInstance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserProfile.fromJson(docSnapshot.data()!);
      }
      WasteAppLogger.info('No user profile found in Firestore', context: {
        'user_id': userId.substring(0, 16),
        'service': 'google_drive',
        'action': 'return_null_for_new_user'
      });
      return null;
    } catch (e) {
      WasteAppLogger.severe('Error fetching user profile from Firestore',
          error: e,
          context: {
            'user_id': userId.substring(0, 16),
            'service': 'google_drive'
          });
      return null;
    }
  }

  // Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final googleSignIn = _googleSignIn;
      if (googleSignIn == null) {
        throw UnsupportedError(
          'Google Drive sign-in is not available on web builds.',
        );
      }
      final account = await googleSignIn.signIn();
      if (account != null) {
        final legacyGoogleUserId = account.id;
        final userCredential = await _signInToFirebaseAuth(account);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          throw StateError(
            'Google sign-in succeeded but FirebaseAuth user is null.',
          );
        }
        final userId = firebaseUser.uid;

        if (legacyGoogleUserId != userId) {
          try {
            await FirebaseFunctions.instanceFor(region: 'asia-south1')
                .httpsCallable('migrateLegacyUserData')
                .call(<String, dynamic>{'legacyUserId': legacyGoogleUserId});
          } catch (e) {
            WasteAppLogger.warning(
              'Cloud legacy identity migration failed; continuing with local migration',
              error: e,
              context: {
                'legacy_user_id': _safeIdPrefix(legacyGoogleUserId),
                'firebase_uid': _safeIdPrefix(userId),
              },
            );
          }

          try {
            final migration = await _storageService.migrateLocalIdentity(
              fromUserId: legacyGoogleUserId,
              toUserId: userId,
            );
            WasteAppLogger.info('Local identity migration completed', context: {
              'legacy_user_id': _safeIdPrefix(legacyGoogleUserId),
              'firebase_uid': _safeIdPrefix(userId),
              ...migration,
            });
          } catch (e) {
            WasteAppLogger.warning(
              'Local legacy identity migration failed',
              error: e,
              context: {
                'legacy_user_id': _safeIdPrefix(legacyGoogleUserId),
                'firebase_uid': _safeIdPrefix(userId),
              },
            );
          }
        }

        var userProfile = await _fetchUserProfileFromFirestore(userId);

        if (userProfile == null) {
          // Truly new user, or Firestore fetch failed. Create a new UserProfile.
          WasteAppLogger.info('Creating new UserProfile for user', context: {
            'user_id': userId.substring(0, 16),
            'email': account.email,
            'service': 'google_drive',
            'action': 'create_new_profile'
          });
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
          WasteAppLogger.info(
              'Found existing UserProfile, error: updating fields');
          userProfile = userProfile.copyWith(
            lastActive: DateTime.now(),
            displayName: account.displayName ?? userProfile.displayName,
            email: account.email, // Keep email updated
            photoUrl: account.photoUrl ?? userProfile.photoUrl,
          );
        }

        // Save the fetched/updated or newly created UserProfile to local storage
        await _storageService.saveUserProfile(userProfile);
        WasteAppLogger.info('UserProfile saved locally after sign-in',
            context: {
              'user_id': userId.substring(0, 16),
              'service': 'google_drive',
              'action': 'local_save_complete'
            });

        // Optional: If it was a new user, explicitly save to Firestore now.
        // Otherwise, CloudStorageService.saveUserProfileToFirestore will be called
        // by other services (like GamificationService) when they make changes.
        // For a new user, ensuring their basic profile exists in Firestore early can be beneficial.
        if (userProfile.createdAt == userProfile.lastActive) {
          // Heuristic for new profile
          try {
            await _firestoreInstance
                .collection(FirestoreCollections.users)
                .doc(userProfile.id)
                .set(userProfile.toJson(), SetOptions(merge: true));
            WasteAppLogger.info('New UserProfile synced to Firestore',
                context: {
                  'user_id': userId.substring(0, 16),
                  'service': 'google_drive',
                  'action': 'firestore_sync_complete'
                });
          } catch (e) {
            WasteAppLogger.severe(
                'Error syncing new UserProfile $userId to Firestore immediately: $e');
          }
        }
      }
      return account;
    } catch (e) {
      WasteAppLogger.severe('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      final googleSignIn = _googleSignIn;
      if (googleSignIn != null) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
      await _storageService.clearUserInfo();
    } catch (e) {
      WasteAppLogger.severe('Error signing out from Google: $e');
      rethrow;
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) return false;
    return googleSignIn.isSignedIn();
  }

  // Get authenticated HTTP client
  Future<http.Client> _getAuthenticatedHttpClient() async {
    final override = _authenticatedHttpClientOverride;
    if (override != null) {
      return override();
    }

    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw UnsupportedError(
        'Google Drive upload and download are not available on web builds.',
      );
    }
    final account = await googleSignIn.signInSilently();
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
      final tempDir = await _temporaryDirectoryProvider();
      final extension = p.extension(fileName);
      final safeFileName = sanitizeFileName(
        fileName,
        fallback:
            extension.isEmpty ? 'drive_export.txt' : 'drive_export$extension',
      );
      final tempFile = File(safeJoinWithin(tempDir.path, safeFileName));
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
      WasteAppLogger.severe('Error uploading to Drive: $e');
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
      WasteAppLogger.severe('Error downloading from Drive: $e');
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
      WasteAppLogger.severe('Error creating folder in Drive: $e');
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
      WasteAppLogger.severe('Error finding file/folder in Drive: $e');
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
      WasteAppLogger.severe('Error backing up user data: $e');
      rethrow;
    }
  }

  // Restore user data from Google Drive
  Future<void> restoreUserData(String fileId) async {
    try {
      final userData = await downloadFromDrive(fileId);
      await _storageService.importUserData(userData);
    } catch (e) {
      WasteAppLogger.severe('Error restoring user data: $e');
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
      final folderId = await findFileOrFolder(appFolderName, isFolder: true);

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
      WasteAppLogger.severe('Error listing backup files: $e');
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
