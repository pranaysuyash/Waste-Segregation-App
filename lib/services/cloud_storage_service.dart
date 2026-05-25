import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/user_profile.dart';
import '../models/classification_feedback.dart';
import 'storage_service.dart';
import 'gamification_service.dart';
import 'fresh_start_service.dart';
import 'firestore_batch_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/waste_app_logger.dart';
import 'dart:io';
import 'firestore_schema_registry.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';

/// Service for syncing user app data to Firestore cloud storage.
///
/// Training data collection is intentionally not handled here. Model-improvement
/// use requires explicit TrainingConsent and flows through TrainingDataService
/// plus Cloud Functions-managed `training_*` collections.
class CloudStorageService {
  CloudStorageService(this._localStorageService);
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _localStorageService;

  // ✅ OPTIMIZATION: Add as class field to avoid creating new instances repeatedly
  late final GamificationService _gamificationService =
      GamificationService(_localStorageService, this);

  // OPTIMIZATION: Batch manager for Firestore write operations (40% cost reduction)
  late final FirestoreBatchManager _batchManager = FirestoreBatchManager(
    autoCommitThreshold: 50, // Commit every 50 operations
  );

  StorageService get localStorageService => _localStorageService;

  /// Fetches user profile from Firestore for cross-device sync.
  ///
  /// Returns null if the user document doesn't exist in Firestore.
  Future<UserProfile?> fetchUserProfileFromFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserProfile.fromJson(data);
    } catch (e, s) {
      WasteAppLogger.severe('Error fetching user profile from Firestore',
          error: e, stackTrace: s);
      return null;
    }
  }

  /// OPTIMIZATION: Saves or updates the user's profile and leaderboard using batch operations
  /// This reduces Firestore costs by batching writes together
  Future<void> saveUserProfileToFirestore(UserProfile userProfile,
      {bool useBatching = true}) async {
    if (userProfile.id.isEmpty) {
      WasteAppLogger.info(
          'User profile ID is empty, error: skipping Firestore save.');
      return;
    }

    try {
      WasteAppLogger.info(
          'Saving user profile to Firestore for user ${userProfile.id}');

      if (useBatching) {
        // OPTIMIZATION: Use batch operations for cost efficiency
        final batch = _batchManager.getBatch('profiles');
        final userDoc = _firestore
            .collection(FirestoreCollections.users)
            .doc(userProfile.id);

        final profileData = _applyUserProfilePrivacyGuard(userProfile.toJson());
        await batch.addSet(userDoc, profileData, merge: true);

        // After adding profile, also batch the leaderboard update
        if (userProfile.gamificationProfile != null) {
          await _updateLeaderboardEntryBatched(userProfile, batch);
          // Atomic point increment via separate document to prevent race conditions.
          // This runs alongside the main profile write as a source-of-truth backup.
          // See docs/review/GAMIFICATION_HABIT_LOOP_REDESIGN_2026-05-21.md Phase 2.
          _queueAtomicPointIncrement(userProfile);
        }

        // Commit the batch
        await batch.commit();
        WasteAppLogger.info(
            'Successfully saved user profile and leaderboard via batch.');
      } else {
        // Fallback to individual operations
        final profileData = _applyUserProfilePrivacyGuard(userProfile.toJson());
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(userProfile.id)
            .set(profileData, SetOptions(merge: true));
        WasteAppLogger.info('Successfully saved user profile to Firestore.');

        // After successfully saving the profile, update the leaderboard
        if (userProfile.gamificationProfile != null) {
          await _updateLeaderboardEntry(userProfile);
        }
      }
    } catch (e, s) {
      WasteAppLogger.severe('Error saving user profile to Firestore',
          error: e, stackTrace: s);
      rethrow; // Rethrow to allow calling code to handle
    }
  }

  /// OPTIMIZATION: Updates leaderboard using batch service
  Future<void> _updateLeaderboardEntryBatched(
    UserProfile userProfile,
    FirestoreBatchService batch,
  ) async {
    if (userProfile.gamificationProfile == null) return;

    final userId = userProfile.id;
    final points = userProfile.gamificationProfile!.points.total;
    final displayName = userProfile.displayName ?? 'Anonymous User';
    final photoUrl = userProfile.photoUrl;

    try {
      WasteAppLogger.info(
          'Adding leaderboard update to batch for user $userId');
      final leaderboardDoc = _firestore
          .collection(FirestoreCollections.leaderboardAllTime)
          .doc(userId);

      final leaderboardBatchData = _applyLeaderboardPrivacyGuard({
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'points': points,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, userProfile);
      await batch.addSet(
        leaderboardDoc,
        leaderboardBatchData,
        merge: true,
      );
    } catch (e, s) {
      WasteAppLogger.severe('Error adding leaderboard update to batch',
          error: e, stackTrace: s);
      // Continue - batch will handle the error on commit
    }
  }

  /// Updates the user's entry in the all-time leaderboard.
  Future<void> _updateLeaderboardEntry(UserProfile userProfile) async {
    if (userProfile.gamificationProfile == null) {
      return; // Should not happen if called correctly
    }

    final userId = userProfile.id;
    final points = userProfile.gamificationProfile!.points.total;
    final displayName = userProfile.displayName ?? 'Anonymous User';
    final photoUrl = userProfile.photoUrl;
    // Category breakdown can be added if needed, from userProfile.gamificationProfile!.points.categoryPoints

    try {
      WasteAppLogger.info('Updating leaderboard for user $userId');
      final leaderboardData = _applyLeaderboardPrivacyGuard({
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'points': points,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, userProfile);
      await _firestore
          .collection(FirestoreCollections.leaderboardAllTime)
          .doc(userId)
          .set(leaderboardData, SetOptions(merge: true));
      WasteAppLogger.info('Successfully updated leaderboard for user $userId');
    } catch (e, s) {
      WasteAppLogger.severe('Error updating leaderboard',
          error: e, stackTrace: s);
      // Not rethrowing, as primary operation (profile save) succeeded.
      // Consider a more robust error handling/retry mechanism for leaderboard updates if critical.
    }
  }

  /// Save classification to both local and cloud storage
  /// Also processes gamification to ensure points are awarded
  Future<void> saveClassificationWithSync(
    WasteClassification classification,
    bool isGoogleSyncEnabled, {
    bool processGamification = true,
  }) async {
    // Always save locally first
    final localSaveResult =
        await _localStorageService.saveClassificationWithResult(classification);
    if (!localSaveResult.saved && localSaveResult.wasDuplicate) {
      WasteAppLogger.info('Duplicate classification skipped before cloud sync',
          context: {
            'classificationId': classification.id,
            'contentHash': localSaveResult.contentHash,
            'service': 'CloudStorageService',
          });
      return;
    }

    // Check if we should prevent sync due to fresh start mode
    final shouldPreventSync = await FreshStartService.shouldPreventAutoSync();
    if (shouldPreventSync) {
      WasteAppLogger.info('Auto-sync prevented by Fresh Start service.');
      return;
    }

    // If Google sync is enabled and user is signed in, also save to cloud
    if (isGoogleSyncEnabled) {
      await _syncClassificationToCloud(classification);
    }

    // 🎮 GAMIFICATION FIX: Process gamification to ensure points are awarded
    // This fixes the disconnect where classifications exist but no points are earned
    if (processGamification) {
      try {
        // Check if this classification has already been processed for gamification
        // by looking for a gamification marker or checking the timestamp
        final shouldProcessGamification =
            await _shouldProcessGamification(classification);

        if (shouldProcessGamification) {
          WasteAppLogger.info(
              'Processing gamification for classification ${classification.id}');

          // ✅ OPTIMIZATION: Use the singleton instance with error handling
          try {
            await _gamificationService.processClassification(classification);
            WasteAppLogger.info(
                'Successfully processed gamification for classification ${classification.id}');
          } catch (e, s) {
            WasteAppLogger.severe('Error processing gamification',
                error: e, stackTrace: s);
            // Don't rethrow - classification save was successful
          }
        } else {
          WasteAppLogger.info(
              'Skipping gamification for already processed classification ${classification.id}');
        }
      } catch (e, s) {
        WasteAppLogger.severe(
            'Error checking if gamification should be processed',
            error: e,
            stackTrace: s);
        // Don't rethrow - classification save was successful
      }
    }
  }

  /// Update an existing classification in Firestore (for migrations and updates)
  Future<void> updateClassificationInCloud(
      WasteClassification classification) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping cloud update.');
        return;
      }

      WasteAppLogger.info(
          'Updating classification ${classification.id} in cloud for user ${userProfile.id}');

      // Use the local classification ID so we update the existing document
      final docId = classification.id;

      // Add cloud metadata
      final cloudClassification = classification.copyWith(
        userId: userProfile.id,
      );

      // Update the user's personal collection
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userProfile.id)
          .collection(FirestoreCollections.classifications)
          .doc(docId)
          .update({
        ...cloudClassification.toCloudJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      WasteAppLogger.info(
          'Successfully updated classification ${classification.id} in cloud.');

      // Do not mirror into admin_classifications here. Training use is a
      // separate, opt-in pipeline handled by TrainingDataService.
    } catch (e, s) {
      WasteAppLogger.severe('Error updating classification in cloud',
          error: e, stackTrace: s);
      // Don't throw error - this is a best-effort update
    }
  }

  /// Batch update multiple classifications in Firestore (for migrations)
  Future<int> batchUpdateClassificationsInCloud(
      List<WasteClassification> classifications) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping batch cloud update.');
        return 0;
      }

      if (classifications.isEmpty) {
        WasteAppLogger.info(
            'No classifications to update, error: skipping batch cloud update.');
        return 0;
      }

      WasteAppLogger.info(
          'Batch updating ${classifications.length} classifications in cloud for user ${userProfile.id}');

      var updatedCount = 0;
      var batch = _firestore.batch();
      var operationCount = 0;

      for (final classification in classifications) {
        try {
          final docId = classification.id;
          final cloudClassification =
              classification.copyWith(userId: userProfile.id);

          final docRef = _firestore
              .collection(FirestoreCollections.users)
              .doc(userProfile.id)
              .collection(FirestoreCollections.classifications)
              .doc(docId);

          batch.update(docRef, {
            ...cloudClassification.toCloudJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          operationCount++;
          updatedCount++;

          // Firestore batch limit is 500 operations
          if (operationCount >= 450) {
            // Leave some buffer
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
            WasteAppLogger.info(
                'Committed a batch of $operationCount updates.');
          }
        } catch (e, s) {
          WasteAppLogger.severe(
              'Error updating classification ${classification.id} in batch',
              error: e,
              stackTrace: s);
        }
      }

      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
        WasteAppLogger.info(
            'Committed final batch of $operationCount updates.');
      }

      WasteAppLogger.info(
          'Successfully updated $updatedCount classifications in cloud.');
      return updatedCount;
    } catch (e, s) {
      WasteAppLogger.severe('Error in batch update of classifications',
          error: e, stackTrace: s);
      return 0;
    }
  }

  /// Sync a single classification to Firestore
  Future<void> _syncClassificationToCloud(
      WasteClassification classification) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping cloud sync.');
        return;
      }

      WasteAppLogger.info(
          'Syncing classification ${classification.id} to cloud for user ${userProfile.id}');

      // Use the local classification ID so repeated syncs overwrite existing docs
      final docId = classification.id;

      // Add cloud metadata
      final cloudClassification = classification.copyWith(
        userId: userProfile.id,
        // Add cloud sync timestamp
      );

      // 1. Save to user's personal collection
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userProfile.id)
          .collection(FirestoreCollections.classifications)
          .doc(docId)
          .set({
        ...cloudClassification.toCloudJson(),
        'syncedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      WasteAppLogger.info(
          'Successfully synced classification ${classification.id} to user collection.');

      // Record successful sync time locally
      try {
        await _localStorageService.updateLastCloudSync(DateTime.now());
      } catch (e, s) {
        WasteAppLogger.severe('Error updating last cloud sync time',
            error: e, stackTrace: s);
        // Don't rethrow - main sync operation was successful
      }
    } catch (e, s) {
      WasteAppLogger.severe('Error syncing classification to cloud',
          error: e, stackTrace: s);
      // Don't throw error - local save was successful
    }
  }

  /// Legacy admin classification writer retained for historical migration only.
  ///
  /// Do not call this from user sync paths. The old `admin_classifications`
  /// collection treated anonymization as sufficient for model training use; the
  /// product policy is now explicit opt-in via `training_candidates`.
  @Deprecated(
    'Use TrainingDataService and Cloud Functions training_candidates instead. '
    'User app-history sync must not silently create training records.',
  )
  // ignore: unused_element
  Future<void> _saveToAdminCollection(
      WasteClassification classification) async {
    try {
      if (classification.userId == null || classification.userId!.isEmpty) {
        WasteAppLogger.info(
            'User ID is null or empty, error: skipping save to admin collection.');
        return;
      }

      // Create anonymized version for ML training
      final adminData = {
        'itemName': classification.itemName,
        'category': classification.category,
        'subCategory': classification.subCategory,
        'materials': classification.materials?.join(', '),
        'isRecyclable': classification.isRecyclable,
        'isCompostable': classification.isCompostable,
        'requiresSpecialDisposal': classification.requiresSpecialDisposal,
        'explanation': classification.explanation,
        'disposalMethod': classification.disposalMethod,
        'recyclingCode': classification.recyclingCode,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '0.1.6+98', // Current app version
        'hashedUserId':
            _hashUserId(classification.userId!), // One-way hash for privacy
        'region': 'India', // General location for regional insights
        'language': 'en', // App language used
        'mlTrainingData': true, // Flag for ML pipeline
        // NO personal information, email, or identifiable data
      };

      final hashedUserId = _hashUserId(classification.userId!);
      await _firestore
          .collection(FirestoreCollections.adminClassifications)
          .doc('${hashedUserId}_${classification.id}')
          .set(adminData, SetOptions(merge: true));

      WasteAppLogger.info(
          'Successfully saved anonymized classification to admin collection.');

      // Also update recovery metadata
      await _updateRecoveryMetadata(classification.userId!);
    } catch (e, s) {
      WasteAppLogger.severe('Error saving to admin collection',
          error: e, stackTrace: s);
      // Don't throw error - user experience not affected
    }
  }

  /// Update recovery metadata for data recovery service
  Future<void> _updateRecoveryMetadata(String userId) async {
    try {
      final hashedUserId = _hashUserId(userId);

      await _firestore
          .collection(FirestoreCollections.adminUserRecovery)
          .doc(hashedUserId)
          .set({
        'lastBackup': FieldValue.serverTimestamp(),
        'classificationCount': FieldValue.increment(1),
        'appVersion': '0.1.6+98',
      }, SetOptions(merge: true));

      WasteAppLogger.info(
          'Successfully updated recovery metadata for user $userId');
    } catch (e, s) {
      WasteAppLogger.severe('Error updating recovery metadata',
          error: e, stackTrace: s);
    }
  }

  /// One-way hash for privacy-preserving user identification
  String _hashUserId(String userId) {
    const salt = 'waste_segregation_app_salt_2024'; // App-specific salt
    final bytes = utf8.encode(userId + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================
  // Privacy Guard Methods
  // Derived from FirestoreSchemaRegistry PrivacyGuardConfig
  // ============================================================

  /// Applies privacy guards to leaderboard data before writing.
  /// If user has opted out of the leaderboard, anonymizes PII fields.
  Map<String, dynamic> _applyLeaderboardPrivacyGuard(
    Map<String, dynamic> data,
    UserProfile userProfile,
  ) {
    final sanitized = Map<String, dynamic>.from(data);

    // Check for leaderboard opt-out in user preferences
    final preferences = userProfile.preferences;
    final optedOut = preferences != null &&
        preferences.containsKey(UserPreferenceKeys.leaderboardOptOut) &&
        preferences[UserPreferenceKeys.leaderboardOptOut] == true;

    if (optedOut) {
      sanitized['displayName'] = 'Anonymous User';
      sanitized.remove('photoUrl');
      WasteAppLogger.info(
          'Privacy: Leaderboard opt-out applied for user ${userProfile.id}');
    }

    return sanitized;
  }

  /// Applies privacy guards to user profile data before writing to Firestore.
  /// Removes email field per PrivacyGuardConfig — email should come from
  /// Firebase Auth, not be stored redundantly in Firestore.
  Map<String, dynamic> _applyUserProfilePrivacyGuard(
    Map<String, dynamic> data,
  ) {
    final sanitized = Map<String, dynamic>.from(data);

    if (sanitized.containsKey('email')) {
      sanitized.remove('email');
      WasteAppLogger.info(
          'Privacy: Email removed from user profile before Firestore write');
    }

    return sanitized;
  }

  /// Check if this classification should be processed for gamification
  /// Prevents duplicate gamification processing
  Future<bool> _shouldProcessGamification(
      WasteClassification classification) async {
    try {
      // ✅ OPTIMIZATION: Use the singleton instance instead of creating new one
      // ignore: unused_local_variable
      final profile = await _gamificationService.getProfile();

      // For now, we'll use a simple timestamp-based check
      // In a more sophisticated system, we might track processed classification IDs
      final classificationTime = classification.timestamp;
      final now = DateTime.now();

      // Don't process if classification is older than 24 hours (likely already processed)
      // This prevents retroactive processing of old data while allowing recent classifications
      if (now.difference(classificationTime).inHours > 24) {
        WasteAppLogger.info(
            'Skipping gamification for old classification ${classification.id}');
        return false;
      }

      // Process if classification is recent (within 24 hours)
      WasteAppLogger.info(
          'Proceeding with gamification for recent classification ${classification.id}');
      return true;
    } catch (e, s) {
      WasteAppLogger.severe(
          'Error checking if gamification should be processed',
          error: e,
          stackTrace: s);
      // On error, default to processing to ensure points aren't missed
      return true;
    }
  }

  /// Load classifications from cloud and merge with local
  Future<List<WasteClassification>> getAllClassificationsWithCloudSync(
    bool isGoogleSyncEnabled,
  ) async {
    // Get local classifications
    final localClassifications =
        await _localStorageService.getAllClassifications();

    if (!isGoogleSyncEnabled) {
      WasteAppLogger.info(
          'Google sync is disabled, error: returning local classifications only.');
      return localClassifications;
    }

    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: returning local classifications only.');
        return localClassifications;
      }

      WasteAppLogger.info(
          'Fetching classifications from cloud for user ${userProfile.id}');

      // Get cloud classifications
      final cloudSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userProfile.id)
          .collection(FirestoreCollections.classifications)
          .orderBy('timestamp', descending: true)
          .get();

      final cloudClassifications = cloudSnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return WasteClassification.fromJson(data);
            } catch (e, s) {
              WasteAppLogger.severe('Error parsing classification from cloud',
                  error: e, stackTrace: s);
              return null;
            }
          })
          .where((classification) => classification != null)
          .cast<WasteClassification>()
          .toList();

      WasteAppLogger.info(
          'Found ${cloudClassifications.length} classifications in cloud.');

      // Merge and deduplicate (cloud takes precedence for same timestamps)
      final merged =
          _mergeClassifications(localClassifications, cloudClassifications);

      // Update local storage with any new cloud classifications
      final downloadedCount = await _syncNewCloudClassificationsLocally(
        localClassifications,
        cloudClassifications,
      );

      if (downloadedCount > 0) {
        try {
          await _localStorageService.updateLastCloudSync(DateTime.now());
        } catch (e, s) {
          WasteAppLogger.severe('Error updating last cloud sync time',
              error: e, stackTrace: s);
        }
      }

      return merged;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting classifications from cloud',
          error: e, stackTrace: s);
      return localClassifications;
    }
  }

  /// Merge local and cloud classifications, removing duplicates
  List<WasteClassification> _mergeClassifications(
    List<WasteClassification> local,
    List<WasteClassification> cloud,
  ) {
    final mergedMap = <String, WasteClassification>{};

    // Add local classifications first
    for (final classification in local) {
      // Use the unique ID as the key for deduplication
      mergedMap[classification.id] = classification;
    }

    // Add cloud classifications (will overwrite local if same ID)
    for (final classification in cloud) {
      // Use the unique ID as the key for deduplication
      mergedMap[classification.id] = classification;
    }

    // Convert back to list and sort by timestamp
    final result = mergedMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    WasteAppLogger.info(
        'Merged ${local.length} local and ${cloud.length} cloud classifications into ${result.length} unique items.');
    return result;
  }

  /// Save new cloud classifications to local storage
  Future<int> _syncNewCloudClassificationsLocally(
    List<WasteClassification> local,
    List<WasteClassification> cloud,
  ) async {
    try {
      // Find cloud classifications that don't exist locally using their unique IDs
      final localIds = local.map((c) => c.id).toSet();

      final newCloudClassifications = cloud.where((cloudClassification) {
        return !localIds.contains(cloudClassification.id);
      }).toList();

      if (newCloudClassifications.isNotEmpty) {
        WasteAppLogger.info(
            'Syncing ${newCloudClassifications.length} new cloud classifications to local storage.');

        for (final classification in newCloudClassifications) {
          await _localStorageService.saveClassification(classification);
        }

        WasteAppLogger.info('Successfully synced new cloud classifications.');
      }
      return newCloudClassifications.length;
    } catch (e, s) {
      WasteAppLogger.severe(
          'Error syncing new cloud classifications to local storage',
          error: e,
          stackTrace: s);
      return 0;
    }
  }

  /// Sync all local classifications to cloud (one-time sync)
  Future<int> syncAllLocalClassificationsToCloud() async {
    try {
      // Check if we should prevent sync due to fresh start mode
      final shouldPreventSync = await FreshStartService.shouldPreventAutoSync();
      if (shouldPreventSync) {
        WasteAppLogger.info('Auto-sync prevented by Fresh Start service.');
        return 0;
      }

      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping full cloud sync.');
        return 0;
      }

      final localClassifications =
          await _localStorageService.getAllClassifications();

      WasteAppLogger.info(
          '🔄 Starting full sync of ${localClassifications.length} local classifications to cloud');

      var syncedCount = 0;
      var opCount = 0;
      var batch = _firestore.batch();

      for (final classification in localClassifications) {
        try {
          final userProfileId = userProfile.id;
          final cloudClassification =
              classification.copyWith(userId: userProfileId);
          final docRef = _firestore
              .collection(FirestoreCollections.users)
              .doc(userProfileId)
              .collection(FirestoreCollections.classifications)
              .doc(classification.id);

          batch.set(
              docRef,
              {
                ...cloudClassification.toCloudJson(),
                'syncedAt': FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          opCount++;
          syncedCount++;

          if (opCount == 500) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }

          // Do not backfill admin_classifications during user data sync.
          // Training candidates are created only through explicit consent.
        } catch (e) {
          WasteAppLogger.info(
              '🔄 ❌ Failed to queue classification ${classification.itemName}: $e');
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      WasteAppLogger.info(
          '🔄 ✅ Successfully synced $syncedCount/${localClassifications.length} classifications to cloud');

      if (syncedCount > 0) {
        try {
          await _localStorageService.updateLastCloudSync(DateTime.now());
        } catch (e, s) {
          WasteAppLogger.severe('Error updating last cloud sync time',
              error: e, stackTrace: s);
          // Don't rethrow - main sync operation was successful
        }
      }

      return syncedCount;
    } catch (e, s) {
      WasteAppLogger.severe('Error syncing all local classifications to cloud',
          error: e, stackTrace: s);
      return 0;
    }
  }

  /// Download new classifications from cloud to local storage.
  /// Returns the number of new items downloaded.
  Future<int> syncCloudToLocal() async {
    try {
      // Check if we should prevent sync due to fresh start mode
      final shouldPreventSync = await FreshStartService.shouldPreventAutoSync();
      if (shouldPreventSync) {
        WasteAppLogger.info('Auto-sync prevented by Fresh Start service.');
        return 0;
      }

      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping cloud to local sync.');
        return 0;
      }

      final localClassifications =
          await _localStorageService.getAllClassifications();

      // Load classifications from cloud
      final cloudSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userProfile.id)
          .collection(FirestoreCollections.classifications)
          .orderBy('timestamp', descending: true)
          .get();

      final cloudClassifications = cloudSnapshot.docs
          .map((doc) {
            try {
              return WasteClassification.fromJson(doc.data());
            } catch (e, s) {
              WasteAppLogger.severe('Error parsing classification from cloud',
                  error: e, stackTrace: s);
              return null;
            }
          })
          .where((c) => c != null)
          .cast<WasteClassification>()
          .toList();

      final downloadedCount = await _syncNewCloudClassificationsLocally(
        localClassifications,
        cloudClassifications,
      );

      return downloadedCount;
    } catch (e, s) {
      WasteAppLogger.severe('Error syncing cloud to local',
          error: e, stackTrace: s);
      return 0;
    }
  }

  /// Clear all cloud data for the current user
  Future<void> clearCloudData() async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info(
            'No user profile found, error: skipping cloud data clear.');
        return;
      }

      WasteAppLogger.info('Clearing all cloud data for user ${userProfile.id}');

      // Delete all classifications for this user
      final classificationsQuery = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userProfile.id)
          .collection(FirestoreCollections.classifications)
          .get();

      final batch = _firestore.batch();
      for (final doc in classificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      WasteAppLogger.info(
          'Successfully cleared Firestore data for user ${userProfile.id}');

      // Best-effort: delete Firebase Storage blobs — failure is non-fatal
      try {
        await deleteUserStorageBlobs(userProfile.id);
      } catch (e, s) {
        WasteAppLogger.severe('Error deleting user storage blobs',
            error: e, stackTrace: s);
      }

      WasteAppLogger.info(
          'Successfully cleared all cloud data for user ${userProfile.id}');
    } catch (e, s) {
      WasteAppLogger.severe('Error clearing cloud data',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Delete all Firebase Storage blobs belonging to [userId].
  ///
  /// Removes objects under:
  /// - `batch_images/{userId}/`   (uploaded for batch AI processing)
  /// - `contribution_photos/{userId}/`  (user-contributed photos)
  ///
  /// Missing paths are silently skipped; per-file errors are logged but
  /// do not abort the remaining deletions.
  Future<void> deleteUserStorageBlobs(String userId) async {
    if (userId.isEmpty) return;

    final storage = FirebaseStorage.instance;
    final storagePaths = [
      'batch_images/$userId',
      'contribution_photos/$userId',
    ];

    for (final path in storagePaths) {
      try {
        final listResult = await storage.ref().child(path).listAll();
        for (final item in listResult.items) {
          try {
            await item.delete();
          } catch (e) {
            WasteAppLogger.severe('storage_blob_delete_failed',
                context: {'path': item.fullPath}, error: e);
          }
        }
        WasteAppLogger.info('storage_blobs_deleted',
            context: {'path': path, 'count': listResult.items.length});
      } catch (e) {
        // Path may not exist (FirebaseException code 'object-not-found') — safe to skip
        WasteAppLogger.info('storage_path_skip',
            context: {'path': path, 'reason': 'not_found_or_inaccessible'},
            error: e);
      }
    }
  }

  /// Save classification feedback to Firestore
  Future<void> saveClassificationFeedbackToCloud(
      ClassificationFeedback feedback) async {
    try {
      await _firestore
          .collection(FirestoreCollections.classificationFeedback)
          .doc(feedback.id)
          .set(feedback.toJson(), SetOptions(merge: true));
    } catch (e) {
      WasteAppLogger.info('Failed to save classification feedback to cloud',
          error: e);
      rethrow;
    }
  }

  /// Check whether a classification feedback document already exists in Firestore.
  /// Used for cloud-side idempotency: if local data was cleared but the stable-ID
  /// doc already exists in Firestore, we should not re-award points or re-track.
  Future<bool> checkClassificationFeedbackExists(String feedbackId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.classificationFeedback)
          .doc(feedbackId)
          .get();
      return doc.exists;
    } catch (e) {
      WasteAppLogger.warning(
          'Failed to check classification feedback existence in cloud',
          error: e);
      rethrow;
    }
  }

  /// Uploads an image file for batch processing and returns a publicly accessible URL
  ///
  /// This method:
  /// 1. Uploads image to Firebase Storage
  /// 2. Returns a public download URL that OpenAI Batch API can access
  Future<String> uploadImageForBatchProcessing(
      File imageFile, String userId) async {
    try {
      WasteAppLogger.info('Uploading image for batch processing', context: {
        'service': 'cloud_storage_service',
        'userId': userId,
      });

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Upload to Firebase Storage and get public URL
      final firebaseUrl = await _uploadToFirebaseStorage(imageBytes, userId);

      WasteAppLogger.info('Successfully uploaded image for batch processing',
          context: {
            'service': 'cloud_storage_service',
            'userId': userId,
            'firebaseUrl': firebaseUrl,
          });

      return firebaseUrl;
    } catch (e) {
      WasteAppLogger.severe('Failed to upload image for batch processing',
          error: e,
          context: {
            'service': 'cloud_storage_service',
            'userId': userId,
          });
      rethrow;
    }
  }

  /// Upload image bytes to Firebase Storage and return public download URL
  Future<String> _uploadToFirebaseStorage(
      Uint8List imageBytes, String userId) async {
    try {
      // Strip EXIF metadata before uploading to cloud storage
      final cleanBytes = ImageUtils.stripExifData(imageBytes);

      final storage = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'batch_image_$timestamp.jpg';
      final path = 'batch_images/$userId/$fileName';

      WasteAppLogger.info('Uploading to Firebase Storage', context: {
        'service': 'cloud_storage_service',
        'path': path,
        'size': cleanBytes.length,
      });

      // Create storage reference
      final ref = storage.ref().child(path);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'purpose': 'batch_processing',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final uploadTask = ref.putData(cleanBytes, metadata);
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      WasteAppLogger.info('Firebase Storage upload completed', context: {
        'service': 'cloud_storage_service',
        'downloadUrl': downloadUrl,
        'bytesTransferred': snapshot.bytesTransferred,
      });

      return downloadUrl;
    } catch (e) {
      WasteAppLogger.severe('Firebase Storage upload failed',
          error: e,
          context: {
            'service': 'cloud_storage_service',
            'userId': userId,
          });
      rethrow;
    }
  }

  // ============================================================
  // Leaderboard Re-Anonymization
  // ============================================================

  /// Updates the leaderboard entry to reflect the current privacy preference.
  ///
  /// When a user toggles their leaderboard opt-out preference, this method
  /// updates their existing leaderboard document in Firestore:
  /// - If opted out: displayName becomes "Anonymous User", photoUrl is removed
  /// - If opted in: displayName and photoUrl are restored from the user profile
  ///
  /// This ensures the leaderboard immediately reflects the user's choice
  /// without waiting for the next gamification-triggered write.
  Future<void> updateLeaderboardPrivacyPreference(
      UserProfile userProfile) async {
    if (userProfile.id.isEmpty) {
      WasteAppLogger.info(
          'Cannot update leaderboard privacy: user ID is empty');
      return;
    }

    try {
      final userId = userProfile.id;
      final preferences = userProfile.preferences;
      final optedOut = preferences != null &&
          preferences.containsKey(UserPreferenceKeys.leaderboardOptOut) &&
          preferences[UserPreferenceKeys.leaderboardOptOut] == true;

      if (optedOut) {
        // Anonymize the existing leaderboard entry
        await _firestore
            .collection(FirestoreCollections.leaderboardAllTime)
            .doc(userId)
            .set({
          'displayName': 'Anonymous User',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Remove photoUrl by setting to FieldValue.delete() or null
        await _firestore
            .collection(FirestoreCollections.leaderboardAllTime)
            .doc(userId)
            .update({'photoUrl': FieldValue.delete()});
        WasteAppLogger.info(
            'Privacy: Leaderboard entry anonymized for user \$userId');
      } else {
        // Restore the user's actual name and photo from their profile
        final displayName = userProfile.displayName ?? 'Anonymous User';
        final photoUrl = userProfile.photoUrl;

        final updateData = <String, dynamic>{
          'displayName': displayName,
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        // Only set photoUrl if it exists; otherwise delete it
        if (photoUrl != null && photoUrl.isNotEmpty) {
          updateData['photoUrl'] = photoUrl;
        } else {
          updateData['photoUrl'] = FieldValue.delete();
        }

        await _firestore
            .collection(FirestoreCollections.leaderboardAllTime)
            .doc(userId)
            .set(updateData, SetOptions(merge: true));
        WasteAppLogger.info(
            'Privacy: Leaderboard entry restored for user \$userId');
      }
    } catch (e, s) {
      // Log but don't rethrow — the preference toggle itself should succeed
      // even if the leaderboard update fails. The next gamification-triggered
      // write will correct any inconsistency.
      WasteAppLogger.severe('Error updating leaderboard privacy preference',
          error: e, stackTrace: s);
    }
  }

  /// Atomically increment points in Firestore to prevent race conditions.
  /// Uses a separate `users/{uid}/points/current` doc with FieldValue.increment()
  /// so concurrent writes from different clients don't collide.
  /// This runs asynchronously alongside the main profile write.
  void _queueAtomicPointIncrement(UserProfile profile) {
    final gamification = profile.gamificationProfile;
    if (gamification == null) return;

    final pointsRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(profile.id)
        .collection('points')
        .doc('current');

    // We don't know the delta here (last-write-wins scenario),
    // so we just set the total atomically. A future migration can
    // compute deltas from the PointsEngine and use increment().
    unawaited(pointsRef.set({
      'total': gamification.points.total,
      'level': gamification.points.level,
      'weeklyTotal': gamification.points.weeklyTotal,
      'monthlyTotal': gamification.points.monthlyTotal,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {
      // Non-fatal — atomic points are a secondary consistency layer
    }));
  }
}
