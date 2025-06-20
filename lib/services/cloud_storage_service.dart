import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/waste_classification.dart';
import '../models/user_profile.dart';
import '../models/classification_feedback.dart';
import 'storage_service.dart';
import 'gamification_service.dart';
import 'fresh_start_service.dart';
import 'enhanced_image_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/waste_app_logger.dart';
import 'dart:io';

/// Service for syncing classifications to Firestore cloud storage
/// Also handles admin data collection for ML training and data recovery
class CloudStorageService {

  CloudStorageService(this._localStorageService);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _localStorageService;
  
  // ✅ OPTIMIZATION: Add as class field to avoid creating new instances repeatedly
  late final GamificationService _gamificationService = GamificationService(_localStorageService, this);

  StorageService get localStorageService => _localStorageService;

  /// Saves or updates the user's profile in Firestore and updates the all-time leaderboard.
  Future<void> saveUserProfileToFirestore(UserProfile userProfile) async {
    if (userProfile.id.isEmpty) {
      WasteAppLogger.info('User profile ID is empty, skipping Firestore save.');
      return;
    }

    try {
      WasteAppLogger.info('Saving user profile to Firestore for user ${userProfile.id}');
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .set(userProfile.toJson(), SetOptions(merge: true));
      WasteAppLogger.info('Successfully saved user profile to Firestore.');

      // After successfully saving the profile, update the leaderboard
      if (userProfile.gamificationProfile != null) {
        await _updateLeaderboardEntry(userProfile);
      }
    } catch (e, s) {
      WasteAppLogger.severe('Error saving user profile to Firestore', e, s);
      rethrow; // Rethrow to allow calling code to handle
    }
  }

  /// Updates the user's entry in the all-time leaderboard.
  Future<void> _updateLeaderboardEntry(UserProfile userProfile) async {
    if (userProfile.gamificationProfile == null) return; // Should not happen if called correctly

    final userId = userProfile.id;
    final points = userProfile.gamificationProfile!.points.total;
    final displayName = userProfile.displayName ?? 'Anonymous User';
    final photoUrl = userProfile.photoUrl;
    // Category breakdown can be added if needed, from userProfile.gamificationProfile!.points.categoryPoints

    try {
      WasteAppLogger.info('Updating leaderboard for user $userId');
      await _firestore.collection('leaderboard_allTime').doc(userId).set({
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'points': points,
        // 'categoryBreakdown': userProfile.gamificationProfile!.points.categoryPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      WasteAppLogger.info('Successfully updated leaderboard for user $userId');
    } catch (e, s) {
      WasteAppLogger.severe('Error updating leaderboard', e, s);
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
    await _localStorageService.saveClassification(classification);
    
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
        final shouldProcessGamification = await _shouldProcessGamification(classification);
        
        if (shouldProcessGamification) {
          WasteAppLogger.info('Processing gamification for classification ${classification.id}');
          
          // ✅ OPTIMIZATION: Use the singleton instance with error handling
          try {
            await _gamificationService.processClassification(classification);
            WasteAppLogger.info('Successfully processed gamification for classification ${classification.id}');
          } catch (e, s) {
            WasteAppLogger.severe('Error processing gamification', e, s);
            // Don't rethrow - classification save was successful
          }
        } else {
          WasteAppLogger.info('Skipping gamification for already processed classification ${classification.id}');
        }
      } catch (e, s) {
        WasteAppLogger.severe('Error checking if gamification should be processed', e, s);
        // Don't rethrow - classification save was successful
      }
    }
  }

  /// Update an existing classification in Firestore (for migrations and updates)
  Future<void> updateClassificationInCloud(WasteClassification classification) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('No user profile found, skipping cloud update.');
        return;
      }

      WasteAppLogger.info('Updating classification ${classification.id} in cloud for user ${userProfile.id}');
      
      // Use the local classification ID so we update the existing document
      final docId = classification.id;
      
      // Add cloud metadata
      final cloudClassification = classification.copyWith(
        userId: userProfile.id,
      );

      // Update the user's personal collection
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .collection('classifications')
          .doc(docId)
          .update({
        ...cloudClassification.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      WasteAppLogger.info('Successfully updated classification ${classification.id} in cloud.');

      // Also update the admin collection for consistency
      await _saveToAdminCollection(cloudClassification);

    } catch (e, s) {
      WasteAppLogger.severe('Error updating classification in cloud', e, s);
      // Don't throw error - this is a best-effort update
    }
  }

  /// Batch update multiple classifications in Firestore (for migrations)
  Future<int> batchUpdateClassificationsInCloud(List<WasteClassification> classifications) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('No user profile found, skipping batch cloud update.');
        return 0;
      }

      if (classifications.isEmpty) {
        WasteAppLogger.info('No classifications to update, skipping batch cloud update.');
        return 0;
      }

      WasteAppLogger.info('Batch updating ${classifications.length} classifications in cloud for user ${userProfile.id}');
      
      var updatedCount = 0;
      var batch = _firestore.batch();
      var operationCount = 0;

      for (final classification in classifications) {
        try {
          final docId = classification.id;
          final cloudClassification = classification.copyWith(userId: userProfile.id);
          
          final docRef = _firestore
              .collection('users')
              .doc(userProfile.id)
              .collection('classifications')
              .doc(docId);

          batch.update(docRef, {
            ...cloudClassification.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          operationCount++;
          updatedCount++;

          // Firestore batch limit is 500 operations
          if (operationCount >= 450) { // Leave some buffer
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
            WasteAppLogger.info('Committed a batch of $operationCount updates.');
          }
        } catch (e, s) {
          WasteAppLogger.severe('Error updating classification ${classification.id} in batch', e, s);
        }
      }

      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
        WasteAppLogger.info('Committed final batch of $operationCount updates.');
      }

      WasteAppLogger.info('Successfully updated $updatedCount classifications in cloud.');
      return updatedCount;

    } catch (e, s) {
      WasteAppLogger.severe('Error in batch update of classifications', e, s);
      return 0;
    }
  }

  /// Sync a single classification to Firestore
  Future<void> _syncClassificationToCloud(WasteClassification classification) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('No user profile found, skipping cloud sync.');
        return;
      }

      WasteAppLogger.info('Syncing classification ${classification.id} to cloud for user ${userProfile.id}');
      
      // Use the local classification ID so repeated syncs overwrite existing docs
      final docId = classification.id;
      
      // Add cloud metadata
      final cloudClassification = classification.copyWith(
        userId: userProfile.id,
        // Add cloud sync timestamp
      );

      // 1. Save to user's personal collection
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .collection('classifications')
          .doc(docId)
          .set({
        ...cloudClassification.toJson(),
        'syncedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      WasteAppLogger.info('Successfully synced classification ${classification.id} to user collection.');

      // 2. Save anonymized version to admin collection for ML training and data recovery
      await _saveToAdminCollection(cloudClassification);

      // Record successful sync time locally
      try {
        await _localStorageService.updateLastCloudSync(DateTime.now());
      } catch (e, s) {
        WasteAppLogger.severe('Error updating last cloud sync time', e, s);
        // Don't rethrow - main sync operation was successful
      }

    } catch (e, s) {
      WasteAppLogger.severe('Error syncing classification to cloud', e, s);
      // Don't throw error - local save was successful
    }
  }

  /// Save anonymized classification to admin collection for ML training and data recovery
  Future<void> _saveToAdminCollection(WasteClassification classification) async {
    try {
      if (classification.userId == null || classification.userId!.isEmpty) {
        WasteAppLogger.info('User ID is null or empty, skipping save to admin collection.');
        return;
      }

      // Create anonymized version for ML training
      final adminData = {
        'itemName': classification.itemName,
        'category': classification.category,
        'subcategory': classification.subcategory,
        'materialType': classification.materialType,
        'isRecyclable': classification.isRecyclable,
        'isCompostable': classification.isCompostable,
        'requiresSpecialDisposal': classification.requiresSpecialDisposal,
        'explanation': classification.explanation,
        'disposalMethod': classification.disposalMethod,
        'recyclingCode': classification.recyclingCode,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '0.1.6+98', // Current app version
        'hashedUserId': _hashUserId(classification.userId!), // One-way hash for privacy
        'region': 'India', // General location for regional insights
        'language': 'en', // App language used
        'mlTrainingData': true, // Flag for ML pipeline
        // NO personal information, email, or identifiable data
      };

      final hashedUserId = _hashUserId(classification.userId!);
      await _firestore
          .collection('admin_classifications')
          .doc('${hashedUserId}_${classification.id}')
          .set(adminData, SetOptions(merge: true));

      WasteAppLogger.info('Successfully saved anonymized classification to admin collection.');

      // Also update recovery metadata
      await _updateRecoveryMetadata(classification.userId!);

    } catch (e, s) {
      WasteAppLogger.severe('Error saving to admin collection', e, s);
      // Don't throw error - user experience not affected
    }
  }

  /// Update recovery metadata for data recovery service
  Future<void> _updateRecoveryMetadata(String userId) async {
    try {
      final hashedUserId = _hashUserId(userId);
      
      await _firestore
          .collection('admin_user_recovery')
          .doc(hashedUserId)
          .set({
        'lastBackup': FieldValue.serverTimestamp(),
        'classificationCount': FieldValue.increment(1),
        'appVersion': '0.1.6+98',
      }, SetOptions(merge: true));

      WasteAppLogger.info('Successfully updated recovery metadata for user $userId');
    } catch (e, s) {
      WasteAppLogger.severe('Error updating recovery metadata', e, s);
    }
  }

  /// One-way hash for privacy-preserving user identification
  String _hashUserId(String userId) {
    const salt = 'waste_segregation_app_salt_2024'; // App-specific salt
    final bytes = utf8.encode(userId + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if this classification should be processed for gamification
  /// Prevents duplicate gamification processing
  Future<bool> _shouldProcessGamification(WasteClassification classification) async {
    try {
      // ✅ OPTIMIZATION: Use the singleton instance instead of creating new one
      final profile = await _gamificationService.getProfile();
      
      // For now, we'll use a simple timestamp-based check
      // In a more sophisticated system, we might track processed classification IDs
      final classificationTime = classification.timestamp;
      final now = DateTime.now();
      
      // Don't process if classification is older than 24 hours (likely already processed)
      // This prevents retroactive processing of old data while allowing recent classifications
      if (now.difference(classificationTime).inHours > 24) {
        WasteAppLogger.info('Skipping gamification for old classification ${classification.id}');
        return false;
      }
      
      // Process if classification is recent (within 24 hours)
      WasteAppLogger.info('Proceeding with gamification for recent classification ${classification.id}');
      return true;
    } catch (e, s) {
      WasteAppLogger.severe('Error checking if gamification should be processed', e, s);
      // On error, default to processing to ensure points aren't missed
      return true;
    }
  }

  /// Load classifications from cloud and merge with local
  Future<List<WasteClassification>> getAllClassificationsWithCloudSync(
    bool isGoogleSyncEnabled,
  ) async {
    // Get local classifications
    final localClassifications = await _localStorageService.getAllClassifications();
    
    if (!isGoogleSyncEnabled) {
      WasteAppLogger.info('Google sync is disabled, returning local classifications only.');
      return localClassifications;
    }

    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('No user profile found, returning local classifications only.');
        return localClassifications;
      }

      WasteAppLogger.info('Fetching classifications from cloud for user ${userProfile.id}');
      
      // Get cloud classifications
      final cloudSnapshot = await _firestore
          .collection('users')
          .doc(userProfile.id)
          .collection('classifications')
          .orderBy('timestamp', descending: true)
          .get();

      final cloudClassifications = cloudSnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return WasteClassification.fromJson(data);
            } catch (e, s) {
              WasteAppLogger.severe('Error parsing classification from cloud', e, s);
              return null;
            }
          })
          .where((classification) => classification != null)
          .cast<WasteClassification>()
          .toList();

      WasteAppLogger.info('Found ${cloudClassifications.length} classifications in cloud.');
      
      // Merge and deduplicate (cloud takes precedence for same timestamps)
      final merged = _mergeClassifications(localClassifications, cloudClassifications);

      // Update local storage with any new cloud classifications
      final downloadedCount = await _syncNewCloudClassificationsLocally(
        localClassifications,
        cloudClassifications,
      );

      if (downloadedCount > 0) {
        try {
          await _localStorageService.updateLastCloudSync(DateTime.now());
        } catch (e, s) {
          WasteAppLogger.severe('Error updating last cloud sync time', e, s);
        }
      }

      return merged;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting classifications from cloud', e, s);
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
    final result = mergedMap.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    WasteAppLogger.info('Merged ${local.length} local and ${cloud.length} cloud classifications into ${result.length} unique items.');
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
        WasteAppLogger.info('Syncing ${newCloudClassifications.length} new cloud classifications to local storage.');

        for (final classification in newCloudClassifications) {
          await _localStorageService.saveClassification(classification);
        }

        WasteAppLogger.info('Successfully synced new cloud classifications.');
      }
      return newCloudClassifications.length;
    } catch (e, s) {
      WasteAppLogger.severe('Error syncing new cloud classifications to local storage', e, s);
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
        WasteAppLogger.info('No user profile found, skipping full cloud sync.');
        return 0;
      }

      final localClassifications =
          await _localStorageService.getAllClassifications();

      WasteAppLogger.info('🔄 Starting full sync of ${localClassifications.length} local classifications to cloud');

      var syncedCount = 0;
      var opCount = 0;
      var batch = _firestore.batch();

      for (final classification in localClassifications) {
        try {
          final userProfileId = userProfile.id;
          final cloudClassification =
              classification.copyWith(userId: userProfileId);
          final docRef = _firestore
              .collection('users')
              .doc(userProfileId)
              .collection('classifications')
              .doc(classification.id);

          batch.set(docRef, {
            ...cloudClassification.toJson(),
            'syncedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          opCount++;
          syncedCount++;

          if (opCount == 500) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }

          try {
            await _saveToAdminCollection(cloudClassification);
          } catch (e, s) {
            WasteAppLogger.severe('Error saving to admin collection during full sync', e, s);
            // Don't block user data sync
          }
        } catch (e) {
          WasteAppLogger.info('🔄 ❌ Failed to queue classification ${classification.itemName}: $e');
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      WasteAppLogger.info('🔄 ✅ Successfully synced $syncedCount/${localClassifications.length} classifications to cloud');

      if (syncedCount > 0) {
        try {
          await _localStorageService.updateLastCloudSync(DateTime.now());
        } catch (e, s) {
          WasteAppLogger.severe('Error updating last cloud sync time', e, s);
          // Don't rethrow - main sync operation was successful
        }
      }

      return syncedCount;
    } catch (e, s) {
      WasteAppLogger.severe('Error syncing all local classifications to cloud', e, s);
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
        WasteAppLogger.info('No user profile found, skipping cloud to local sync.');
        return 0;
      }

      final localClassifications = await _localStorageService.getAllClassifications();

      // Load classifications from cloud
      final cloudSnapshot = await _firestore
          .collection('users')
          .doc(userProfile.id)
          .collection('classifications')
          .orderBy('timestamp', descending: true)
          .get();

      final cloudClassifications = cloudSnapshot.docs
          .map((doc) {
            try {
              return WasteClassification.fromJson(doc.data());
            } catch (e, s) {
              WasteAppLogger.severe('Error parsing classification from cloud', e, s);
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
      WasteAppLogger.severe('Error syncing cloud to local', e, s);
      return 0;
    }
  }

  /// Clear all cloud data for the current user
  Future<void> clearCloudData() async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('No user profile found, skipping cloud data clear.');
        return;
      }

      WasteAppLogger.info('Clearing all cloud data for user ${userProfile.id}');
      
      // Delete all classifications for this user
      final classificationsQuery = await _firestore
          .collection('users')
          .doc(userProfile.id)
          .collection('classifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in classificationsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      WasteAppLogger.info('Successfully cleared all cloud data for user ${userProfile.id}');
    } catch (e, s) {
      WasteAppLogger.severe('Error clearing cloud data', e, s);
      rethrow;
    }
  }
  /// Save classification feedback to Firestore
  Future<void> saveClassificationFeedbackToCloud(ClassificationFeedback feedback) async {
    try {
      await _firestore
          .collection('classification_feedback')
          .doc(feedback.id)
          .set(feedback.toJson(), SetOptions(merge: true));
    } catch (e) {
      WasteAppLogger.info('Failed to save classification feedback to cloud', e);
      rethrow;
    }
  }

  /// Uploads an image file for batch processing and returns a publicly accessible URL
  /// 
  /// This method:
  /// 1. Uploads image to Firebase Storage
  /// 2. Returns a public download URL that OpenAI Batch API can access
  Future<String> uploadImageForBatchProcessing(File imageFile, String userId) async {
    try {
      WasteAppLogger.info('Uploading image for batch processing', null, null, {
        'service': 'cloud_storage_service',
        'userId': userId,
      });

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Upload to Firebase Storage and get public URL
      final firebaseUrl = await _uploadToFirebaseStorage(imageBytes, userId);
      
      WasteAppLogger.info('Successfully uploaded image for batch processing', null, null, {
        'service': 'cloud_storage_service',
        'userId': userId,
        'firebaseUrl': firebaseUrl,
      });
      
      return firebaseUrl;
    } catch (e) {
      WasteAppLogger.severe('Failed to upload image for batch processing', e, null, {
        'service': 'cloud_storage_service',
        'userId': userId,
      });
      rethrow;
    }
  }

  /// Upload image bytes to Firebase Storage and return public download URL
  Future<String> _uploadToFirebaseStorage(Uint8List imageBytes, String userId) async {
    try {
      final storage = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'batch_image_${timestamp}.jpg';
      final path = 'batch_images/$userId/$fileName';
      
      WasteAppLogger.info('Uploading to Firebase Storage', null, null, {
        'service': 'cloud_storage_service',
        'path': path,
        'size': imageBytes.length,
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
      final uploadTask = ref.putData(imageBytes, metadata);
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      WasteAppLogger.info('Firebase Storage upload completed', null, null, {
        'service': 'cloud_storage_service',
        'downloadUrl': downloadUrl,
        'bytesTransferred': snapshot.bytesTransferred,
      });
      
      return downloadUrl;
    } catch (e) {
      WasteAppLogger.severe('Firebase Storage upload failed', e, null, {
        'service': 'cloud_storage_service',
        'userId': userId,
      });
      rethrow;
    }
  }
} 