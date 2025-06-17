import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/constants.dart';
import 'gamification_provider.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Repository that provides a single source of truth for gamification data
/// Handles Hive ↔ Firestore sync with conflict resolution
class GamificationRepository {
  GamificationRepository(this._storageService, this._cloudStorageService);

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;
  
  static const String _cacheKey = 'gamification_profile_cache';
  static const String _offlineQueueKey = 'gamification_offline_queue';
  
  /// Get profile with smart caching and conflict resolution
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) async {
    try {
      // 1. Try to get from local cache first (fastest)
      if (!forceRefresh) {
        final cached = await _getCachedProfile();
        if (cached != null) {
          // Start background sync but return cached immediately
          unawaited(_backgroundSync(cached));
          return cached;
        }
      }
      
      // 2. Get current user profile
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile == null) {
        return _createGuestProfile();
      }
      
      // 3. Try cloud first, fallback to local
      GamificationProfile? cloudProfile;
      GamificationProfile? localProfile;
      
      try {
        // Get from cloud with timeout
        cloudProfile = userProfile.gamificationProfile;
      } catch (e) {
        if (kDebugMode) {
          WasteAppLogger.severe('🔥 Failed to get cloud profile: $e');
        }
      }
      
      try {
        // Get from local storage
        localProfile = await _getLocalProfile(userProfile.id);
      } catch (e) {
        if (kDebugMode) {
          WasteAppLogger.severe('🔥 Failed to get local profile: $e');
        }
      }
      
      // 4. Resolve conflicts and return best profile
      final resolvedProfile = _resolveConflicts(cloudProfile, localProfile, userProfile.id);
      
      // 5. Cache the resolved profile
      await _cacheProfile(resolvedProfile);
      
      // 6. Process offline queue
      unawaited(_processOfflineQueue());
      
      return resolvedProfile;
      
    } catch (e) {
      throw AppException.storage('Failed to load gamification profile: $e');
    }
  }
  
  /// Save profile with optimistic updates and offline queueing
  Future<void> saveProfile(GamificationProfile profile) async {
    try {
      // 1. Save to cache immediately (optimistic update)
      await _cacheProfile(profile);
      
      // 2. Save to local storage
      await _saveLocalProfile(profile);
      
      // 3. Try to save to cloud, queue if offline
      try {
        await _saveCloudProfile(profile);
      } catch (e) {
        if (kDebugMode) {
          WasteAppLogger.severe('🔄 Cloud save failed, queueing for later: $e');
        }
        await _queueOfflineOperation('save_profile', profile.toJson());
      }
      
    } catch (e) {
      throw AppException.storage('Failed to save gamification profile: $e');
    }
  }
  
  /// Claim achievement reward with validation
  Future<Achievement> claimReward(String achievementId, GamificationProfile currentProfile) async {
    final achievementIndex = currentProfile.achievements.indexWhere((a) => a.id == achievementId);
    
    if (achievementIndex == -1) {
      throw AppException.storage('Achievement not found');
    }
    
    final achievement = currentProfile.achievements[achievementIndex];
    
    if (!achievement.isClaimable) {
      throw AppException.storage('Achievement is not claimable');
    }
    
    // Validate claim is legitimate (prevent double-claiming)
    if (achievement.claimStatus == ClaimStatus.claimed) {
      throw AppException.storage('Achievement already claimed');
    }
    
    // Create updated achievement
    final updatedAchievement = achievement.copyWith(
      claimStatus: ClaimStatus.claimed,
      earnedOn: achievement.earnedOn ?? DateTime.now(),
    );
    
    // Update profile with new points and achievement status
    final updatedAchievements = List<Achievement>.from(currentProfile.achievements);
    updatedAchievements[achievementIndex] = updatedAchievement;
    
    final updatedPoints = currentProfile.points.copyWith(
      total: currentProfile.points.total + achievement.pointsReward,
    );
    
    final updatedProfile = currentProfile.copyWith(
      achievements: updatedAchievements,
      points: updatedPoints,
    );
    
    // Save the updated profile
    await saveProfile(updatedProfile);
    
    return updatedAchievement;
  }
  
  /// Process offline operations queue
  Future<void> _processOfflineQueue() async {
    try {
      final box = await Hive.openBox('gamification_cache');
      final queueJson = box.get(_offlineQueueKey) as String?;
      
      if (queueJson == null) return;
      
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
      final processedOperations = <Map<String, dynamic>>[];
      
      for (final operation in queue) {
        try {
          await _processOfflineOperation(operation);
          processedOperations.add(operation);
        } catch (e) {
          if (kDebugMode) {
            WasteAppLogger.severe('🔄 Failed to process offline operation: $e');
          }
          // Keep failed operations in queue for retry
        }
      }
      
      // Remove processed operations from queue
      final remainingQueue = queue.where((op) => !processedOperations.contains(op)).toList();
      
      if (remainingQueue.isEmpty) {
        await box.delete(_offlineQueueKey);
      } else {
        await box.put(_offlineQueueKey, jsonEncode(remainingQueue));
      }
      
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error processing offline queue: $e');
      }
    }
  }
  
  /// Background sync to keep data fresh
  Future<void> _backgroundSync(GamificationProfile cachedProfile) async {
    try {
      final freshProfile = await getProfile(forceRefresh: true);
      
      // If there are differences, the cache will be updated automatically
      if (freshProfile != cachedProfile) {
        if (kDebugMode) {
          WasteAppLogger.info('🔄 Background sync updated profile');
        }
      }
    } catch (e) {
      // Silent failure for background sync
      if (kDebugMode) {
        WasteAppLogger.severe('🔄 Background sync failed: $e');
      }
    }
  }
  
  /// Resolve conflicts between cloud and local profiles
  GamificationProfile _resolveConflicts(
    GamificationProfile? cloudProfile,
    GamificationProfile? localProfile,
    String userId,
  ) {
    // If only one exists, use it
    if (cloudProfile == null && localProfile == null) {
      return _createDefaultProfile(userId);
    }
    
    if (cloudProfile == null) return localProfile!;
    if (localProfile == null) return cloudProfile;
    
    // Both exist - use conflict resolution strategy
    // Strategy: Use the profile with the highest total points (most recent activity)
    if (cloudProfile.points.total >= localProfile.points.total) {
      return cloudProfile;
    } else {
      // Local is newer, schedule cloud update
      unawaited(_saveCloudProfile(localProfile));
      return localProfile;
    }
  }
  
  /// Get cached profile from Hive
  Future<GamificationProfile?> _getCachedProfile() async {
    try {
      final box = await Hive.openBox('gamification_cache');
      final profileJson = box.get(_cacheKey) as String?;
      
      if (profileJson == null) return null;
      
      return GamificationProfile.fromJson(jsonDecode(profileJson));
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error getting cached profile: $e');
      }
      return null;
    }
  }
  
  /// Cache profile to Hive
  Future<void> _cacheProfile(GamificationProfile profile) async {
    try {
      final box = await Hive.openBox('gamification_cache');
      await box.put(_cacheKey, jsonEncode(profile.toJson()));
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error caching profile: $e');
      }
    }
  }
  
  /// Get profile from local storage
  Future<GamificationProfile?> _getLocalProfile(String userId) async {
    final userProfile = await _storageService.getCurrentUserProfile();
    return userProfile?.gamificationProfile;
  }
  
  /// Save profile to local storage
  Future<void> _saveLocalProfile(GamificationProfile profile) async {
    final userProfile = await _storageService.getCurrentUserProfile();
    if (userProfile != null) {
      final updatedProfile = userProfile.copyWith(
        gamificationProfile: profile,
        lastActive: DateTime.now(),
      );
      await _storageService.saveUserProfile(updatedProfile);
    }
  }
  
  /// Save profile to cloud storage
  Future<void> _saveCloudProfile(GamificationProfile profile) async {
    final userProfile = await _storageService.getCurrentUserProfile();
    if (userProfile != null) {
      final updatedProfile = userProfile.copyWith(
        gamificationProfile: profile,
        lastActive: DateTime.now(),
      );
      await _cloudStorageService.saveUserProfileToFirestore(updatedProfile);
    }
  }
  
  /// Queue operation for offline processing
  Future<void> _queueOfflineOperation(String type, Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox('gamification_cache');
      final queueJson = box.get(_offlineQueueKey) as String?;
      
      final queue = queueJson != null 
          ? List<Map<String, dynamic>>.from(jsonDecode(queueJson))
          : <Map<String, dynamic>>[];
      
      queue.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await box.put(_offlineQueueKey, jsonEncode(queue));
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error queueing offline operation: $e');
      }
    }
  }
  
  /// Process a single offline operation
  Future<void> _processOfflineOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;
    
    switch (type) {
      case 'save_profile':
        final profile = GamificationProfile.fromJson(data);
        await _saveCloudProfile(profile);
        break;
      default:
        if (kDebugMode) {
          WasteAppLogger.info('🔥 Unknown offline operation type: $type');
        }
    }
  }
  
  /// Create a guest profile for unauthenticated users
  GamificationProfile _createGuestProfile() {
    return GamificationProfile(
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      streaks: {
        StreakType.dailyClassification.toString(): StreakDetails(
          type: StreakType.dailyClassification,
          currentCount: 1,
          longestCount: 1,
          lastActivityDate: DateTime.now(),
        ),
      },
      points: const UserPoints(),
      achievements: _getDefaultAchievements(),
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }
  
  /// Create a default profile for authenticated users
  GamificationProfile _createDefaultProfile(String userId) {
    return GamificationProfile(
      userId: userId,
      streaks: {
        StreakType.dailyClassification.toString(): StreakDetails(
          type: StreakType.dailyClassification,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
      points: const UserPoints(),
      achievements: _getDefaultAchievements(),
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }
  
  /// Get default achievements (placeholder - should come from service)
  List<Achievement> _getDefaultAchievements() {
    // This should be moved to a proper service or configuration
    return [
      const Achievement(
        id: 'first_classification',
        title: 'First Steps',
        description: 'Complete your first waste classification',
        type: AchievementType.firstClassification,
        threshold: 1,
        iconName: 'eco',
        color: Color(0xFF4CAF50),
        pointsReward: GamificationConfig.kPointsPerItem,
      ),
      // Add more default achievements...
    ];
  }
}

/// Provider for the gamification repository
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final cloudStorageService = ref.watch(cloudStorageServiceProvider);
  return GamificationRepository(storageService, cloudStorageService);
}); 