import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/points_engine.dart';
import '../utils/constants.dart';
import '../utils/waste_app_logger.dart';
import 'app_providers.dart'; // Import for profileProvider
import 'points_manager.dart'; // Import for pointsManagerProvider
// Import central providers

/// Provider for GamificationService
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final cloudStorageService = ref.watch(cloudStorageServiceProvider);
  return GamificationService(storageService, cloudStorageService);
});

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for cloud storage service
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return CloudStorageService(storageService);
});

/// AsyncNotifier for gamification profile with proper error handling
class GamificationNotifier extends AsyncNotifier<GamificationProfile> {
  @override
  Future<GamificationProfile> build() async {
    try {
      final service = ref.read(gamificationServiceProvider);
      return await service.getProfile().timeout(
            GamificationConfig.kProfileTimeout,
            onTimeout: () => throw AppException.timeout('Profile loading timed out'),
          );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      } else {
        throw AppException.storage('Failed to load gamification profile: $e');
      }
    }
  }

  /// Refresh the profile with force refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(gamificationServiceProvider);
      final profile = await service.getProfile(forceRefresh: true).timeout(
            GamificationConfig.kProfileTimeout,
            onTimeout: () => throw AppException.timeout('Profile refresh timed out'),
          );
      state = AsyncValue.data(profile);
    } catch (e) {
      final exception = e is AppException ? e : AppException.storage('Failed to refresh profile: $e');
      state = AsyncValue.error(exception, StackTrace.current);
    }
  }

  /// Claim an achievement reward using atomic PointsEngine operations
  Future<Result<bool, AppException>> claimReward(String achievementId) async {
    try {
      // Check current state
      final currentState = state;
      if (currentState is! AsyncData<GamificationProfile>) {
        return Result.failure(AppException.storage('Profile not loaded'));
      }

      final profile = currentState.value;
      final achievement = profile.achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw AppException.storage('Achievement not found'),
      );

      if (!achievement.isClaimable) {
        return Result.failure(AppException.storage('Achievement is not claimable'));
      }

      // RACE CONDITION FIX: Use atomic PointsEngine operation
      final pointsEngine = PointsEngine.getInstance(
        ref.read(storageServiceProvider),
        ref.read(cloudStorageServiceProvider),
      );

      // Perform atomic claim operation
      await pointsEngine.claimAchievementReward(achievementId);

      // RACE CONDITION FIX: Invalidate all related providers to refresh UI
      ref.invalidate(gamificationServiceProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(pointsManagerProvider);

      // Refresh the profile to get updated data from PointsEngine
      await refresh();

      return Result.success(true);
    } catch (e) {
      final exception = e is AppException ? e : AppException.storage('Failed to claim reward: $e');
      return Result.failure(exception);
    }
  }

  /// Update achievement progress
  Future<void> updateProgress(AchievementType type, int increment) async {
    final currentState = state;
    if (currentState is! AsyncData<GamificationProfile>) return;

    try {
      final service = ref.read(gamificationServiceProvider);
      await service.updateAchievementProgress(type, increment);

      // Refresh the profile to get updated achievements
      await refresh();
    } catch (e) {
      // Handle error but don't update state to error since this is a background operation
      if (kDebugMode) {
        WasteAppLogger.severe(
            'Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_provider'});
      }
    }
  }
}

/// Main provider for gamification profile
final gamificationProvider = AsyncNotifierProvider<GamificationNotifier, GamificationProfile>(() {
  return GamificationNotifier();
});

/// Provider for achievements filtered by status
final achievementsByStatusProvider = Provider.family<List<Achievement>, AchievementStatus>((ref, status) {
  final profileAsync = ref.watch(gamificationProvider);

  return profileAsync.when(
    data: (profile) {
      switch (status) {
        case AchievementStatus.earned:
          return profile.achievements.where((a) => a.isEarned).toList();
        case AchievementStatus.claimable:
          return profile.achievements.where((a) => a.isClaimable).toList();
        case AchievementStatus.inProgress:
          return profile.achievements.where((a) => !a.isEarned && a.progress > 0).toList();
        case AchievementStatus.locked:
          return profile.achievements.where((a) => a.isLocked).toList();
        case AchievementStatus.all:
          return profile.achievements;
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for achievement statistics
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  final profileAsync = ref.watch(gamificationProvider);

  return profileAsync.when(
    data: (profile) {
      final achievements = profile.achievements;
      final earned = achievements.where((a) => a.isEarned).length;
      final claimable = achievements.where((a) => a.isClaimable).length;
      final total = achievements.length;
      final totalPoints = profile.points.total;

      return AchievementStats(
        earned: earned,
        claimable: claimable,
        total: total,
        totalPoints: totalPoints,
        completionPercentage: total > 0 ? (earned / total * 100).round() : 0,
      );
    },
    loading: () => const AchievementStats(
      earned: 0,
      claimable: 0,
      total: 0,
      totalPoints: 0,
      completionPercentage: 0,
    ),
    error: (_, __) => const AchievementStats(
      earned: 0,
      claimable: 0,
      total: 0,
      totalPoints: 0,
      completionPercentage: 0,
    ),
  );
});

/// Enum for achievement filtering
enum AchievementStatus {
  earned,
  claimable,
  inProgress,
  locked,
  all,
}

/// Data class for achievement statistics
class AchievementStats {
  const AchievementStats({
    required this.earned,
    required this.claimable,
    required this.total,
    required this.totalPoints,
    required this.completionPercentage,
  });

  final int earned;
  final int claimable;
  final int total;
  final int totalPoints;
  final int completionPercentage;
}

// Using Result class from constants.dart - removed duplicate definition

// REMOVED: Duplicate AppException class - using the one from constants.dart
