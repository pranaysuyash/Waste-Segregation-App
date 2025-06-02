import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/waste_classification.dart';
import 'storage_service.dart';

/// Service for syncing classifications to Firestore cloud storage
class CloudStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _localStorageService;

  CloudStorageService(this._localStorageService);

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
    } catch (e) {
      debugPrint('☁️ ❌ Failed to sync classification to cloud: $e');
      // Don't throw error - local save was successful
    }
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
    final Map<String, WasteClassification> mergedMap = {};
    
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
      
      int syncedCount = 0;
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