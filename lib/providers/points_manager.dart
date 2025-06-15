import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../models/action_points.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/points_engine.dart';

/// Single source of truth for all points operations
/// Eliminates race conditions and ensures consistency across all screens
class PointsManager extends AsyncNotifier<UserPoints> {
  late final PointsEngine _pointsEngine;
  late final StorageService _storageService;
  late final CloudStorageService _cloudStorageService;

  @override
  Future<UserPoints> build() async {
    // Get dependencies from ref
    _storageService = ref.read(storageServiceProvider);
    _cloudStorageService = ref.read(cloudStorageServiceProvider);
    
    // Initialize Points Engine
    _pointsEngine = PointsEngine(_storageService, _cloudStorageService);
    await _pointsEngine.initialize();
    
    // Listen to Points Engine changes
    _pointsEngine.addListener(_onPointsEngineChanged);
    
    // Return current points
    final profile = _pointsEngine.currentProfile;
    return profile?.points ?? const UserPoints();
  }

  /// Handle Points Engine changes and update state
  void _onPointsEngineChanged() {
    final profile = _pointsEngine.currentProfile;
    if (profile != null) {
      state = AsyncValue.data(profile.points);
    }
  }

  /// Add points for an action with atomic operation
  Future<UserPoints> addPoints(
    PointableAction action, {
    String? category,
    int? customPoints,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate custom points usage
      if (customPoints != null && !action.supportsCustomPoints) {
        debugPrint('⚠️ PointsManager: Custom points not supported for ${action.key}');
      }
      
      final newPoints = await _pointsEngine.addPoints(
        action.key,
        category: category ?? action.category,
        customPoints: customPoints,
        metadata: {
          'source': 'PointsManager',
          'action_category': action.category,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      // Update state immediately
      state = AsyncValue.data(newPoints);
      
      // Validate points consistency
      await _validatePointsConsistency();
      
      return newPoints;
    } catch (e, stackTrace) {
      debugPrint('🔥 PointsManager: Failed to add points: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Add points for an action using string key (backwards compatibility)
  @Deprecated('Use addPoints with PointableAction enum instead')
  Future<UserPoints> addPointsLegacy(
    String actionKey, {
    String? category,
    int? customPoints,
    Map<String, dynamic>? metadata,
  }) async {
    final action = PointableAction.fromKey(actionKey);
    if (action == null) {
      throw ArgumentError('Invalid action key: $actionKey');
    }
    
    return addPoints(
      action,
      category: category,
      customPoints: customPoints,
      metadata: metadata,
    );
  }

  /// Update streak and award points
  Future<StreakDetails> updateStreak(StreakType type) async {
    try {
      final newStreak = await _pointsEngine.updateStreak(type);
      
      // Update points state after streak update
      final profile = _pointsEngine.currentProfile;
      if (profile != null) {
        state = AsyncValue.data(profile.points);
      }
      
      return newStreak;
    } catch (e, stackTrace) {
      debugPrint('🔥 PointsManager: Failed to update streak: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Claim achievement reward
  Future<Achievement> claimAchievementReward(String achievementId) async {
    try {
      final achievement = await _pointsEngine.claimAchievementReward(achievementId);
      
      // Update points state after claiming reward
      final profile = _pointsEngine.currentProfile;
      if (profile != null) {
        state = AsyncValue.data(profile.points);
      }
      
      return achievement;
    } catch (e, stackTrace) {
      debugPrint('🔥 PointsManager: Failed to claim achievement: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Sync points with classifications (retroactive correction)
  Future<void> syncWithClassifications() async {
    try {
      await _pointsEngine.syncWithClassifications();
      
      // Update state after sync
      final profile = _pointsEngine.currentProfile;
      if (profile != null) {
        state = AsyncValue.data(profile.points);
      }
    } catch (e, stackTrace) {
      debugPrint('🔥 PointsManager: Failed to sync with classifications: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Refresh points data
  Future<void> refresh() async {
    try {
      await _pointsEngine.refresh();
      
      final profile = _pointsEngine.currentProfile;
      if (profile != null) {
        state = AsyncValue.data(profile.points);
      } else {
        state = const AsyncValue.data(UserPoints());
      }
    } catch (e, stackTrace) {
      debugPrint('🔥 PointsManager: Failed to refresh: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Validate points consistency (total == sum of category points)
  Future<void> _validatePointsConsistency() async {
    try {
      final currentState = state;
      if (!currentState.hasValue) return;
      
      final points = currentState.value!;
      final categorySum = points.categoryPoints.values.fold<int>(0, (sum, value) => sum + value);
      
      // Allow some tolerance for legacy data
      const tolerance = 10;
      final difference = (points.total - categorySum).abs();
      
      if (difference > tolerance) {
        debugPrint('⚠️ PointsManager: Points inconsistency detected!');
        debugPrint('   Total: ${points.total}');
        debugPrint('   Category sum: $categorySum');
        debugPrint('   Difference: $difference');
        
        // Log for analytics but don't fail the operation
        // In production, this could trigger a background sync
      }
    } catch (e) {
      debugPrint('🔥 PointsManager: Error validating points consistency: $e');
    }
  }

  /// Get current points (convenience getter)
  int get currentPoints => _pointsEngine.currentPoints;

  /// Get current level (convenience getter)
  int get currentLevel => _pointsEngine.currentLevel;

  /// Get current profile (convenience getter)
  GamificationProfile? get currentProfile => _pointsEngine.currentProfile;
}

/// Provider for the unified PointsManager
final pointsManagerProvider = AsyncNotifierProvider<PointsManager, UserPoints>(() {
  return PointsManager();
});

/// Convenience provider for current points value
final currentPointsProvider = Provider<int>((ref) {
  final pointsAsync = ref.watch(pointsManagerProvider);
  return pointsAsync.when(
    data: (points) => points.total,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Convenience provider for current level
final currentLevelProvider = Provider<int>((ref) {
  final pointsAsync = ref.watch(pointsManagerProvider);
  return pointsAsync.when(
    data: (points) => points.level,
    loading: () => 1,
    error: (_, __) => 1,
  );
});

/// Provider dependencies (these should be defined elsewhere in your app)
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService provider must be overridden');
});

final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  throw UnimplementedError('CloudStorageService provider must be overridden');
}); 