import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/constants.dart';

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

  /// Claim an achievement reward
  Future<Result<bool, AppException>> claimReward(String achievementId) async {
    try {
      // For now, we'll implement the claim logic here since the service doesn't have this method yet
      final currentState = state;
      if (currentState is! AsyncData<GamificationProfile>) {
        return Result.failure(AppException.storage('Profile not loaded'));
      }
      
      final profile = currentState.value;
      final achievementIndex = profile.achievements.indexWhere((a) => a.id == achievementId);
      
      if (achievementIndex == -1) {
        return Result.failure(AppException.storage('Achievement not found'));
      }
      
      final achievement = profile.achievements[achievementIndex];
      if (!achievement.isClaimable) {
        return Result.failure(AppException.storage('Achievement is not claimable'));
      }
      
      // Update the achievement to claimed status
      final updatedAchievement = achievement.copyWith(
        claimStatus: ClaimStatus.claimed,
      );
      
      final updatedAchievements = List<Achievement>.from(profile.achievements);
      updatedAchievements[achievementIndex] = updatedAchievement;
      
      // Update points
      final updatedPoints = profile.points.copyWith(
        total: profile.points.total + achievement.pointsReward,
      );
      
      final updatedProfile = profile.copyWith(
        achievements: updatedAchievements,
        points: updatedPoints,
      );
      
      // Save the updated profile
      final service = ref.read(gamificationServiceProvider);
      await service.saveProfile(updatedProfile);
      
      // Update the state
      state = AsyncValue.data(updatedProfile);
      
      return Result.success(true);
    } catch (e) {
      final exception = e is AppException ? e : AppException.storage('Failed to claim reward: $e');
      return Result.failure(exception);
    }
  }

  /// Update achievement progress
  Future<void> updateProgress(String achievementId, double progress) async {
    try {
      // Update the state optimistically
      state.whenData((profile) {
        final updatedAchievements = profile.achievements.map((achievement) {
          if (achievement.id == achievementId) {
            return achievement.copyWith(progress: progress);
          }
          return achievement;
        }).toList();
        
        final updatedProfile = profile.copyWith(achievements: updatedAchievements);
        state = AsyncValue.data(updatedProfile);
        
        // Save the updated profile
        final service = ref.read(gamificationServiceProvider);
        service.saveProfile(updatedProfile).catchError((e) {
          // If save fails, refresh from source
          refresh();
        });
      });
    } catch (e) {
      // If optimistic update fails, refresh from source
      await refresh();
    }
  }
}

/// Provider for the gamification profile
final gamificationProvider = AsyncNotifierProvider<GamificationNotifier, GamificationProfile>(() {
  return GamificationNotifier();
});

/// Provider for filtered achievements by status
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
  all,
  earned,
  claimable,
  inProgress,
  locked,
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