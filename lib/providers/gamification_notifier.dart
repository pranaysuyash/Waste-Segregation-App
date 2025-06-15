import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../utils/constants.dart';
import 'gamification_repository.dart';

/// Modern Riverpod-based gamification state management
/// Eliminates mounted checks, provides proper error handling, and uses repository pattern
class GamificationNotifier extends AsyncNotifier<GamificationProfile> {
  GamificationRepository get _repository => ref.read(gamificationRepositoryProvider);

  @override
  Future<GamificationProfile> build() async {
    // Initial load with proper error handling
    try {
      return await _repository.getProfile();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔥 Failed to load gamification profile: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      throw AppException.storage('Failed to load gamification profile: $e');
    }
  }

  /// Refresh profile data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(forceRefresh: true);
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔥 Failed to refresh gamification profile: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Claim achievement reward with optimistic updates
  Future<void> claimReward(String achievementId) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentProfile = currentState.value!;
    
    try {
      // Optimistic update - immediately show claimed state
      final achievementIndex = currentProfile.achievements.indexWhere((a) => a.id == achievementId);
      if (achievementIndex == -1) {
        throw AppException.storage('Achievement not found');
      }

      final achievement = currentProfile.achievements[achievementIndex];
      if (!achievement.isClaimable || achievement.claimStatus == ClaimStatus.claimed) {
        throw AppException.storage('Achievement is not claimable');
      }

      // Create optimistic update
      final updatedAchievement = achievement.copyWith(
        claimStatus: ClaimStatus.claimed,
        earnedOn: achievement.earnedOn ?? DateTime.now(),
      );

      final updatedAchievements = List<Achievement>.from(currentProfile.achievements);
      updatedAchievements[achievementIndex] = updatedAchievement;

      final updatedPoints = currentProfile.points.copyWith(
        total: currentProfile.points.total + achievement.pointsReward,
      );

      final optimisticProfile = currentProfile.copyWith(
        achievements: updatedAchievements,
        points: updatedPoints,
      );

      // Update UI immediately
      state = AsyncValue.data(optimisticProfile);

      // Perform actual claim operation
      await _repository.claimReward(achievementId, currentProfile);
      
      // Refresh to ensure consistency
      await refresh();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 Failed to claim reward: $e');
      }
      
      // Revert optimistic update on error
      state = currentState;
      
      // Re-throw for UI error handling
      throw AppException.storage('Failed to claim reward: $e');
    }
  }

  /// Update streak with validation
  Future<void> updateStreak(StreakType type) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentProfile = currentState.value!;
    
    try {
      final now = DateTime.now();
      final streakKey = type.toString();
      final currentStreak = currentProfile.streaks[streakKey];

      // Validate streak update timing
      if (currentStreak != null) {
        final daysSinceLastActivity = now.difference(currentStreak.lastActivityDate).inDays;
        
        // Prevent multiple updates on same day
        if (daysSinceLastActivity == 0) {
          if (kDebugMode) {
            debugPrint('🔄 Streak already updated today for $type');
          }
          return;
        }
      }

      // Calculate new streak
      final newStreak = _calculateNewStreak(currentStreak, now, type);
      
      // Update profile
      final updatedStreaks = Map<String, StreakDetails>.from(currentProfile.streaks);
      updatedStreaks[streakKey] = newStreak;

      // Calculate points for streak
      final streakPoints = _calculateStreakPoints(newStreak);
      final updatedPoints = currentProfile.points.copyWith(
        total: currentProfile.points.total + streakPoints,
      );

      final updatedProfile = currentProfile.copyWith(
        streaks: updatedStreaks,
        points: updatedPoints,
      );

      // Save and update state
      await _repository.saveProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 Failed to update streak: $e');
      }
      throw AppException.storage('Failed to update streak: $e');
    }
  }

  /// Add classification points
  Future<void> addClassificationPoints(String category, String subcategory) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentProfile = currentState.value!;
    
    try {
      // Calculate points based on category
      const points = GamificationConfig.kPointsPerItem;
      
      // Update points
      final updatedPoints = currentProfile.points.copyWith(
        total: currentProfile.points.total + points,
      );

      // Update achievements progress
      final updatedAchievements = _updateAchievementProgress(
        currentProfile.achievements,
        category,
        subcategory,
      );

      final updatedProfile = currentProfile.copyWith(
        points: updatedPoints,
        achievements: updatedAchievements,
      );

      // Save and update state
      await _repository.saveProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 Failed to add classification points: $e');
      }
      throw AppException.storage('Failed to add classification points: $e');
    }
  }

  /// Calculate new streak details
  StreakDetails _calculateNewStreak(StreakDetails? currentStreak, DateTime now, StreakType type) {
    if (currentStreak == null) {
      return StreakDetails(
        type: type,
        currentCount: 1,
        longestCount: 1,
        lastActivityDate: now,
      );
    }

    final daysSinceLastActivity = currentStreak.lastActivityDate != null
        ? now.difference(currentStreak.lastActivityDate).inDays
        : 1;

    if (daysSinceLastActivity == 1) {
      // Continue streak
      final newCount = currentStreak.currentCount + 1;
      return currentStreak.copyWith(
        currentCount: newCount,
        longestCount: newCount > currentStreak.longestCount ? newCount : currentStreak.longestCount,
        lastActivityDate: now,
      );
    } else if (daysSinceLastActivity > 1) {
      // Streak broken, start new
      return currentStreak.copyWith(
        currentCount: 1,
        lastActivityDate: now,
      );
    } else {
      // Same day, no change
      return currentStreak;
    }
  }

  /// Calculate points for streak milestones
  int _calculateStreakPoints(StreakDetails streak) {
    // Award bonus points for streak milestones
    switch (streak.currentCount) {
      case 3:
        return GamificationConfig.kPointsPerStreak * 2;
      case 7:
        return GamificationConfig.kPointsPerStreak * 4;
      case 30:
        return GamificationConfig.kPointsPerStreak * 10;
      default:
        return 0;
    }
  }

  /// Update achievement progress based on classification
  List<Achievement> _updateAchievementProgress(
    List<Achievement> achievements,
    String category,
    String subcategory,
  ) {
    return achievements.map((achievement) {
      // Skip already claimed achievements
      if (achievement.claimStatus == ClaimStatus.claimed) {
        return achievement;
      }

      // Check if this classification contributes to the achievement
      if (_doesClassificationContribute(achievement, category, subcategory)) {
        final newProgress = achievement.progress + 1;
        final isCompleted = newProgress >= achievement.threshold;

        return achievement.copyWith(
          progress: newProgress,
          claimStatus: isCompleted ? ClaimStatus.unclaimed : ClaimStatus.ineligible,
          earnedOn: isCompleted ? DateTime.now() : null,
        );
      }

      return achievement;
    }).toList();
  }

  /// Check if classification contributes to achievement
  bool _doesClassificationContribute(Achievement achievement, String category, String subcategory) {
    switch (achievement.type) {
      case AchievementType.firstClassification:
        return true; // Any classification counts
      case AchievementType.wasteIdentified:
        return true; // Any waste identification counts
      case AchievementType.categoriesIdentified:
        // Check if achievement is for this specific category
        return achievement.title.toLowerCase().contains(category.toLowerCase());
      case AchievementType.streakMaintained:
        return false; // Handled separately in updateStreak
      case AchievementType.collectionMilestone:
        return true; // Any classification counts for collection
      default:
        return false;
    }
  }
}

/// Provider for the gamification notifier
final gamificationNotifierProvider = AsyncNotifierProvider<GamificationNotifier, GamificationProfile>(
  () => GamificationNotifier(),
);

/// Convenience providers for specific data
final gamificationPointsProvider = Provider<int>((ref) {
  final gamificationState = ref.watch(gamificationNotifierProvider);
  return gamificationState.when(
    data: (profile) => profile.points.total,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final gamificationAchievementsProvider = Provider<List<Achievement>>((ref) {
  final gamificationState = ref.watch(gamificationNotifierProvider);
  return gamificationState.when(
    data: (profile) => profile.achievements,
    loading: () => [],
    error: (_, __) => [],
  );
});

final claimableAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievements = ref.watch(gamificationAchievementsProvider);
  return achievements.where((a) => a.claimStatus == ClaimStatus.unclaimed).toList();
});

final gamificationStreaksProvider = Provider<Map<String, StreakDetails>>((ref) {
  final gamificationState = ref.watch(gamificationNotifierProvider);
  return gamificationState.when(
    data: (profile) => profile.streaks,
    loading: () => {},
    error: (_, __) => {},
  );
}); 