import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/waste_app_logger.dart';

/// Centralized Points Engine - Single Source of Truth for all point operations
/// Eliminates race conditions and inconsistencies between multiple providers
class PointsEngine extends ChangeNotifier {
  PointsEngine(this._storageService, this._cloudStorageService);

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;

  // Single cached profile instance
  GamificationProfile? _cachedProfile;
  
  // Synchronization locks
  bool _isUpdating = false;
  final List<Completer<void>> _pendingOperations = [];

  // NEW: Streams for real-time events
  final _earnedController = StreamController<int>.broadcast();
  final _achievementController = StreamController<Achievement>.broadcast();
  
  Stream<int> get earnedStream => _earnedController.stream;
  Stream<Achievement> get achievementStream => _achievementController.stream;
  
  /// Internal access to achievement controller for GamificationService
  StreamController<Achievement> get achievementController => _achievementController;

  /// Get current profile (cached or fresh)
  GamificationProfile? get currentProfile => _cachedProfile;

  /// Initialize the engine and load profile
  Future<void> initialize() async {
    if (_cachedProfile != null) return;
    
    try {
      await _loadProfile();
    } catch (e) {
      WasteAppLogger.severe('PointsEngine initialization failed', e, null, {
        'component': 'points_engine',
        'operation': 'initialize'
      });
      // Create emergency fallback profile
      _cachedProfile = _createEmergencyProfile();
    }
  }

  /// Load profile from storage with caching
  Future<GamificationProfile> _loadProfile() async {
    final userProfile = await _storageService.getCurrentUserProfile();
    
    if (userProfile?.gamificationProfile != null) {
      _cachedProfile = userProfile!.gamificationProfile!;
      notifyListeners();
      return _cachedProfile!;
    }
    
    // Create new profile if none exists
    final newProfile = _createDefaultProfile(userProfile?.id ?? 'guest');
    await _saveProfile(newProfile);
    return newProfile;
  }

  /// Add points with atomic operation and conflict resolution
  Future<UserPoints> addPoints(String action, {
    String? category,
    int? customPoints,
    Map<String, dynamic>? metadata,
  }) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final profile = _cachedProfile!;
      final pointsToAdd = customPoints ?? _getPointsForAction(action);
      
      if (pointsToAdd <= 0) {
        WasteAppLogger.warning('No points to add for action', null, null, {
          'component': 'points_engine',
          'action': action,
          'points_to_add': pointsToAdd
        });
        return profile.points;
      }

      // Calculate new points with validation
      final newPoints = _calculateNewPoints(profile.points, pointsToAdd, category);
      
      // Update profile
      final updatedProfile = profile.copyWith(points: newPoints);
      await _saveProfile(updatedProfile);
      
      // NEW: Emit earned points event for popups
      _earnedController.add(pointsToAdd);
      
      // Log the operation
      WasteAppLogger.gamificationEvent('points_earned', 
        pointsEarned: pointsToAdd, 
        context: {
          'action': action,
          'category': category,
          'total_points': newPoints.total,
          'user_level': newPoints.level,
          'metadata': metadata
        }
      );
      
      // Track analytics if metadata provided
      if (metadata != null) {
        _trackPointsAnalytics(action, pointsToAdd, newPoints, metadata);
      }
      
      return newPoints;
    });
  }

  /// Update streak with points calculation
  Future<StreakDetails> updateStreak(StreakType type) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final profile = _cachedProfile!;
      final streakKey = type.toString();
      final currentStreak = profile.streaks[streakKey];
      
      final now = DateTime.now();
      final newStreak = _calculateNewStreak(currentStreak, now, type);
      
      // Calculate streak bonus points
      final streakPoints = _calculateStreakPoints(newStreak, currentStreak);
      
      // Update profile with new streak and points
      final updatedStreaks = Map<String, StreakDetails>.from(profile.streaks);
      updatedStreaks[streakKey] = newStreak;
      
      var updatedProfile = profile.copyWith(streaks: updatedStreaks);
      
      // Add streak points if earned
      if (streakPoints > 0) {
        final newPoints = _calculateNewPoints(profile.points, streakPoints, 'streak');
        updatedProfile = updatedProfile.copyWith(points: newPoints);
        WasteAppLogger.gamificationEvent('streak_bonus', 
          pointsEarned: streakPoints,
          context: {
            'streak_type': type.toString(),
            'streak_current': newStreak.currentCount,
            'streak_longest': newStreak.longestCount,
            'total_points': newPoints.total
          }
        );
      }
      
      await _saveProfile(updatedProfile);
      return newStreak;
    });
  }

  /// Claim achievement reward
  Future<Achievement> claimAchievementReward(String achievementId) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final profile = _cachedProfile!;
      final achievementIndex = profile.achievements.indexWhere((a) => a.id == achievementId);
      
      if (achievementIndex == -1) {
        throw Exception('Achievement not found: $achievementId');
      }
      
      final achievement = profile.achievements[achievementIndex];
      
      if (!achievement.isClaimable || achievement.claimStatus == ClaimStatus.claimed) {
        throw Exception('Achievement not claimable: $achievementId');
      }
      
      // Update achievement status
      final updatedAchievement = achievement.copyWith(
        claimStatus: ClaimStatus.claimed,
        earnedOn: achievement.earnedOn ?? DateTime.now(),
      );
      
      final updatedAchievements = List<Achievement>.from(profile.achievements);
      updatedAchievements[achievementIndex] = updatedAchievement;
      
      // Add reward points
      final newPoints = _calculateNewPoints(
        profile.points, 
        achievement.pointsReward, 
        'achievement'
      );
      
      final updatedProfile = profile.copyWith(
        achievements: updatedAchievements,
        points: newPoints,
      );
      
      await _saveProfile(updatedProfile);
      
      WasteAppLogger.gamificationEvent('achievement_claimed', 
        pointsEarned: achievement.pointsReward,
        achievementId: achievement.id,
        context: {
          'achievement_title': achievement.title,
          'total_points': newPoints.total
        }
      );
      return updatedAchievement;
    });
  }

  /// Sync points with classifications (retroactive correction)
  Future<void> syncWithClassifications() async {
    await _executeAtomicOperation(() async {
      await initialize();
      
      final classifications = await _storageService.getAllClassifications();
      final expectedPoints = classifications.length * _getPointsForAction('classification');
      
      final profile = _cachedProfile!;
      if (profile.points.total < expectedPoints) {
        final missingPoints = expectedPoints - profile.points.total;
        WasteAppLogger.gamificationEvent('points_sync', 
          pointsEarned: missingPoints,
          context: {
            'expected_points': expectedPoints,
            'current_points': profile.points.total,
            'missing_points': missingPoints,
            'total_classifications': classifications.length
          }
        );
        
        final newPoints = _calculateNewPoints(profile.points, missingPoints, 'sync');
        final updatedProfile = profile.copyWith(points: newPoints);
        await _saveProfile(updatedProfile);
      }
    });
  }

  /// Execute operation atomically with lock
  Future<T> _executeAtomicOperation<T>(Future<T> Function() operation) async {
    // Wait for any pending operations
    while (_isUpdating) {
      final completer = Completer<void>();
      _pendingOperations.add(completer);
      await completer.future;
    }
    
    _isUpdating = true;
    
    try {
      final result = await operation();
      return result;
    } finally {
      _isUpdating = false;
      
      // Complete all pending operations
      final pending = List<Completer<void>>.from(_pendingOperations);
      _pendingOperations.clear();
      for (final completer in pending) {
        completer.complete();
      }
    }
  }

  /// Save profile with optimistic updates
  Future<void> _saveProfile(GamificationProfile profile) async {
    _cachedProfile = profile;
    notifyListeners();
    
    // Save to local storage
    final userProfile = await _storageService.getCurrentUserProfile();
    if (userProfile != null) {
      final updatedUserProfile = userProfile.copyWith(
        gamificationProfile: profile,
        lastActive: DateTime.now(),
      );
      
      await _storageService.saveUserProfile(updatedUserProfile);
      
      // Try cloud sync (non-blocking)
      unawaited(_cloudStorageService.saveUserProfileToFirestore(updatedUserProfile));
    }
  }

  /// Calculate new points with validation
  UserPoints _calculateNewPoints(UserPoints currentPoints, int pointsToAdd, String? category) {
    final newTotal = currentPoints.total + pointsToAdd;
    final newWeekly = currentPoints.weeklyTotal + pointsToAdd;
    final newMonthly = currentPoints.monthlyTotal + pointsToAdd;
    final newLevel = (newTotal / 100).floor() + 1;
    
    final newCategoryPoints = Map<String, int>.from(currentPoints.categoryPoints);
    if (category != null && category.isNotEmpty) {
      newCategoryPoints[category] = (newCategoryPoints[category] ?? 0) + pointsToAdd;
    }
    
    return UserPoints(
      total: newTotal,
      weeklyTotal: newWeekly,
      monthlyTotal: newMonthly,
      level: newLevel,
      categoryPoints: newCategoryPoints,
    );
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

    final daysSinceLastActivity = now.difference(currentStreak.lastActivityDate).inDays;

    if (daysSinceLastActivity == 0) {
      return currentStreak; // Same day, no change
    } else if (daysSinceLastActivity == 1) {
      // Continue streak
      final newCount = currentStreak.currentCount + 1;
      return currentStreak.copyWith(
        currentCount: newCount,
        longestCount: newCount > currentStreak.longestCount ? newCount : currentStreak.longestCount,
        lastActivityDate: now,
      );
    } else {
      // Streak broken, start new
      return currentStreak.copyWith(
        currentCount: 1,
        lastActivityDate: now,
      );
    }
  }

  /// Calculate streak bonus points
  int _calculateStreakPoints(StreakDetails newStreak, StreakDetails? oldStreak) {
    if (oldStreak == null || newStreak.currentCount <= oldStreak.currentCount) {
      return 0; // No streak increase
    }
    
    // Award bonus points for streak milestones
    switch (newStreak.currentCount) {
      case 3: return 15;  // 3-day streak bonus
      case 7: return 35;  // Week streak bonus
      case 14: return 70; // 2-week streak bonus
      case 30: return 150; // Month streak bonus
      default: return 5;  // Daily streak maintenance
    }
  }

  /// Get points for action
  int _getPointsForAction(String action) {
    const pointValues = {
      'classification': 10,
      'daily_streak': 5,
      'challenge_complete': 25,
      'badge_earned': 20,
      'quiz_completed': 15,
      'educational_content': 5,
      'perfect_week': 50,
      'community_challenge': 30,
    };
    
    return pointValues[action] ?? 0;
  }

  /// Create default profile
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
      achievements: [], // Will be populated by GamificationService
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }

  /// Create emergency fallback profile
  GamificationProfile _createEmergencyProfile() {
    return GamificationProfile(
      userId: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      streaks: {},
      points: const UserPoints(),
      achievements: [],
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }

  /// Track analytics for points operations
  void _trackPointsAnalytics(String action, int points, UserPoints newPoints, Map<String, dynamic> metadata) {
    WasteAppLogger.performanceLog('points_operation', points, context: {
      'action': action,
      'points_added': points,
      'total_points': newPoints.total,
      'user_level': newPoints.level,
      'weekly_points': newPoints.weeklyTotal,
      'monthly_points': newPoints.monthlyTotal,
      ...metadata
    });
  }

  /// Clear cache and force reload
  Future<void> refresh() async {
    _cachedProfile = null;
    await initialize();
  }

  /// Get current points (convenience method)
  int get currentPoints => _cachedProfile?.points.total ?? 0;

  /// Get current level (convenience method)
  int get currentLevel => _cachedProfile?.points.level ?? 1;

  /// Dispose of resources
  @override
  void dispose() {
    _earnedController.close();
    _achievementController.close();
    super.dispose();
  }
} 