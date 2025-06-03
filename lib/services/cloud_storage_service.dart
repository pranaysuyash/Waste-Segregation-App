import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/waste_classification.dart';
import '../models/user_profile.dart';
import '../models/gamification.dart';
import 'storage_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for syncing classifications to Firestore cloud storage
/// Also handles admin data collection for ML training and data recovery
class CloudStorageService {

  CloudStorageService(this._localStorageService);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _localStorageService;

  /// Saves or updates the user's profile in Firestore and updates the all-time leaderboard.
  Future<void> saveUserProfileToFirestore(UserProfile userProfile) async {
    if (userProfile.id.isEmpty) {
      debugPrint('🚫 Cannot save user profile to Firestore: User ID is empty');
      return;
    }

    try {
      debugPrint('☁️ Saving user profile to Firestore for user: ${userProfile.id}');
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .set(userProfile.toJson(), SetOptions(merge: true));
      debugPrint('☁️ ✅ Successfully saved user profile to Firestore: ${userProfile.id}');

      // After successfully saving the profile, update the leaderboard
      if (userProfile.gamificationProfile != null) {
        await _updateLeaderboardEntry(userProfile);
      }
    } catch (e) {
      debugPrint('☁️ ❌ Failed to save user profile to Firestore: $e');
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
    // Category breakdown can be added if needed, from userProfile.gamificationProfile.points.categoryPoints

    try {
      debugPrint('🏆 Updating leaderboard for user: $userId with $points points');
      await _firestore.collection('leaderboard_allTime').doc(userId).set({
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'points': points,
        // 'categoryBreakdown': userProfile.gamificationProfile!.points.categoryPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('🏆 ✅ Successfully updated leaderboard for user: $userId');
    } catch (e) {
      debugPrint('🏆 ❌ Failed to update leaderboard for user $userId: $e');
      // Not rethrowing, as primary operation (profile save) succeeded.
      // Consider a more robust error handling/retry mechanism for leaderboard updates if critical.
    }
  }

  /// Save classification to both local and cloud storage
  Future<void> saveClassificationWithSync(
    WasteClassification classification,
    bool isGoogleSyncEnabled,
  ) async {
    // Always save locally first
    await _localStorageService.saveClassification(classification);
    
    // If Google sync is enabled and user is signed in, also save to cloud
    if (isGoogleSyncEnabled) {
      await _syncClassificationToCloud(classification);
    }
  }

  /// Sync a single classification to Firestore
  Future<void> _syncClassificationToCloud(WasteClassification classification) async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        debugPrint('🚫 Cannot sync to cloud: User not signed in');
        return;
      }

      debugPrint('☁️ Syncing classification to cloud for user: ${userProfile.id}');
      
      // Create a unique document ID using timestamp and user ID
      final docId = '${userProfile.id}_${DateTime.now().millisecondsSinceEpoch}';
      
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
      });

      debugPrint('☁️ ✅ Successfully synced classification: ${classification.itemName}');

      // 2. Save anonymized version to admin collection for ML training and data recovery
      await _saveToAdminCollection(cloudClassification);

    } catch (e) {
      debugPrint('☁️ ❌ Failed to sync classification to cloud: $e');
      // Don't throw error - local save was successful
    }
  }

  /// Save anonymized classification to admin collection for ML training and data recovery
  Future<void> _saveToAdminCollection(WasteClassification classification) async {
    try {
      if (classification.userId == null || classification.userId!.isEmpty) {
        debugPrint('🚫 Cannot save to admin collection: No user ID');
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
        'appVersion': '0.1.5+97', // Current app version
        'hashedUserId': _hashUserId(classification.userId!), // One-way hash for privacy
        'region': 'India', // General location for regional insights
        'language': 'en', // App language used
        'mlTrainingData': true, // Flag for ML pipeline
        // NO personal information, email, or identifiable data
      };

      await _firestore
          .collection('admin_classifications')
          .add(adminData);

      debugPrint('🔬 ✅ Admin data collection: Classification saved for ML training');

      // Also update recovery metadata
      await _updateRecoveryMetadata(classification.userId!);

    } catch (e) {
      debugPrint('🔬 ❌ Admin data collection failed: $e');
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
        'appVersion': '0.1.5+97',
      }, SetOptions(merge: true));

      debugPrint('🔄 ✅ Recovery metadata updated for user');
    } catch (e) {
      debugPrint('🔄 ❌ Recovery metadata update failed: $e');
    }
  }

  /// One-way hash for privacy-preserving user identification
  String _hashUserId(String userId) {
    const salt = 'waste_segregation_app_salt_2024'; // App-specific salt
    final bytes = utf8.encode(userId + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Load classifications from cloud and merge with local
  Future<List<WasteClassification>> getAllClassificationsWithCloudSync(
    bool isGoogleSyncEnabled,
  ) async {
    // Get local classifications
    final localClassifications = await _localStorageService.getAllClassifications();
    
    if (!isGoogleSyncEnabled) {
      debugPrint('🔄 Google sync disabled, returning local classifications only');
      return localClassifications;
    }

    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        debugPrint('🔄 User not signed in, returning local classifications only');
        return localClassifications;
      }

      debugPrint('🔄 Loading classifications from cloud for user: ${userProfile.id}');
      
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
            } catch (e) {
              debugPrint('🔄 ❌ Error parsing cloud classification: $e');
              return null;
            }
          })
          .where((classification) => classification != null)
          .cast<WasteClassification>()
          .toList();

      debugPrint('🔄 ✅ Loaded ${cloudClassifications.length} classifications from cloud');
      
      // Merge and deduplicate (cloud takes precedence for same timestamps)
      final merged = _mergeClassifications(localClassifications, cloudClassifications);
      
      // Update local storage with any new cloud classifications
      await _syncNewCloudClassificationsLocally(localClassifications, cloudClassifications);
      
      return merged;
    } catch (e) {
      debugPrint('🔄 ❌ Failed to load from cloud, returning local only: $e');
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
      final key = '${classification.itemName}_${classification.timestamp.millisecondsSinceEpoch}';
      mergedMap[key] = classification;
    }
    
    // Add cloud classifications (will overwrite local if same key)
    for (final classification in cloud) {
      final key = '${classification.itemName}_${classification.timestamp.millisecondsSinceEpoch}';
      mergedMap[key] = classification;
    }
    
    // Convert back to list and sort by timestamp
    final result = mergedMap.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    debugPrint('🔄 Merged ${local.length} local + ${cloud.length} cloud = ${result.length} total classifications');
    return result;
  }

  /// Save new cloud classifications to local storage
  Future<void> _syncNewCloudClassificationsLocally(
    List<WasteClassification> local,
    List<WasteClassification> cloud,
  ) async {
    try {
      // Find cloud classifications that don't exist locally
      final localTimestamps = local.map((c) => c.timestamp.millisecondsSinceEpoch).toSet();
      
      final newCloudClassifications = cloud.where((cloudClassification) {
        return !localTimestamps.contains(cloudClassification.timestamp.millisecondsSinceEpoch);
      }).toList();

      if (newCloudClassifications.isNotEmpty) {
        debugPrint('🔄 Syncing ${newCloudClassifications.length} new cloud classifications to local storage');
        
        for (final classification in newCloudClassifications) {
          await _localStorageService.saveClassification(classification);
        }
        
        debugPrint('🔄 ✅ Successfully synced new cloud classifications locally');
      }
    } catch (e) {
      debugPrint('🔄 ❌ Failed to sync cloud classifications locally: $e');
    }
  }

  /// Sync all local classifications to cloud (one-time sync)
  Future<int> syncAllLocalClassificationsToCloud() async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        debugPrint('🚫 Cannot sync to cloud: User not signed in');
        return 0;
      }

      final localClassifications = await _localStorageService.getAllClassifications();
      
      debugPrint('🔄 Starting full sync of ${localClassifications.length} local classifications to cloud');
      
      var syncedCount = 0;
      for (final classification in localClassifications) {
        try {
          await _syncClassificationToCloud(classification);
          syncedCount++;
        } catch (e) {
          debugPrint('🔄 ❌ Failed to sync classification ${classification.itemName}: $e');
        }
      }
      
      debugPrint('🔄 ✅ Successfully synced $syncedCount/${localClassifications.length} classifications to cloud');
      return syncedCount;
    } catch (e) {
      debugPrint('🔄 ❌ Failed to sync local classifications to cloud: $e');
      return 0;
    }
  }

  /// Clear all cloud data for the current user
  Future<void> clearCloudData() async {
    try {
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        debugPrint('🚫 Cannot clear cloud data: User not signed in');
        return;
      }

      debugPrint('🗑️ Clearing cloud data for user: ${userProfile.id}');
      
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
      
      debugPrint('🗑️ ✅ Successfully cleared ${classificationsQuery.docs.length} cloud classifications');
    } catch (e) {
      debugPrint('🗑️ ❌ Failed to clear cloud data: $e');
      rethrow;
    }
  }
} 