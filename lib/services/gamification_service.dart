import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/gamification.dart';
import '../models/waste_classification.dart';
import '../models/educational_content.dart';
import '../utils/constants.dart';
import 'community_service.dart';
import 'storage_service.dart';
import 'cloud_storage_service.dart';
import 'points_engine.dart';
import 'hive_manager.dart';
import '../utils/waste_app_logger.dart';

/// Service for managing gamification features
class GamificationService extends ChangeNotifier {

  GamificationService(this._storageService, this._cloudStorageService) {
    _pointsEngine = PointsEngine.getInstance(_storageService, _cloudStorageService);
  }
  
  // Dependencies
  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;
  late final PointsEngine _pointsEngine;

  GamificationProfile? _cachedProfile;
  bool _isUpdatingStreak = false; // Lock to prevent concurrent streak updates

  /// Latest gamification profile cached in memory - Uses Points Engine as source of truth
  GamificationProfile? get currentProfile {
    // Always return from Points Engine if available
    final engineProfile = _pointsEngine.currentProfile;
    if (engineProfile != null) {
      _cachedProfile = engineProfile;
      return engineProfile;
    }
    return _cachedProfile;
  }

  // Hive constants (may be partially deprecated for authenticated users)
  static const String _gamificationBoxName = 'gamificationBox'; // Renamed for clarity
  static const String _legacyProfileKey = 'userGamificationProfile'; // Renamed for clarity
  static const String _defaultChallengesKey = 'defaultChallenges';
  static const String _weeklyStatsKey = 'weeklyStats';
  
  // Points earned for various actions
  static const Map<String, int> _pointValues = {
    'classification': 10,      // Points for identifying an item
    'daily_streak': 5,         // Points for maintaining streak
    'challenge_complete': 25,  // Points for completing a challenge
    'badge_earned': 20,        // Points for earning a badge/achievement
    'achievement_claim': 0,    // Points for claiming achievement rewards (customPoints used)
    'quiz_completed': 15,      // Points for completing a quiz
    'educational_content': 5,  // Points for viewing educational content
    'perfect_week': 50,        // Points for using app every day in a week
    'community_challenge': 30, // Points for participating in community challenge
  }; // Updated constructor
  
  // Initialize Hive box (primarily for challenges, weekly stats if still used this way)
  Future<void> initGamification() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Ensure Hive box is opened using HiveManager
      if (!HiveManager.isBoxOpen(_gamificationBoxName)) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        await HiveManager.openDynamicBox(_gamificationBoxName);
      } else {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      final box = Hive.box(_gamificationBoxName);
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Initialize default challenges if they don't exist
      final challengesJson = box.get(_defaultChallengesKey);
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      if (challengesJson == null || challengesJson is! String || challengesJson.isEmpty) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        try {
          final defaultChallenges = _getDefaultChallenges();
          final encodedChallenges = jsonEncode(defaultChallenges);
          await box.put(_defaultChallengesKey, encodedChallenges);
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          
          // Verify the data was stored correctly
          final verifyData = box.get(_defaultChallengesKey);
          WasteAppLogger.cacheEvent('cache_operation', 'classification', context: {'service': 'gamification', 'file': 'gamification_service'});
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      } else {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Don't rethrow - we want the app to continue even if gamification fails
    }
    // Note: Legacy default profile creation is removed from here.
    // GamificationProfile will be created on-demand via getProfile() if needed.
  }
  
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Always initialize PointsEngine first
      await _pointsEngine.initialize();
      
      // Check if PointsEngine has a profile and use it as source of truth
      final engineProfile = _pointsEngine.currentProfile;
      if (engineProfile != null && !forceRefresh) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        _cachedProfile = engineProfile;
        notifyListeners();
        return engineProfile;
      }
      
      if (!forceRefresh && _cachedProfile != null) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        return _cachedProfile!;
      }
      
      // Ensure Hive box is open before proceeding
      if (!HiveManager.isBoxOpen(_gamificationBoxName)) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        await HiveManager.openDynamicBox(_gamificationBoxName);
      }
      
      final currentUserProfile = await _storageService.getCurrentUserProfile();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});

      if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
        WasteAppLogger.warning('Warning occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        // Fallback for guest or unauthenticated state (reads from old Hive key)
        // This part might need further refinement based on how guests are handled.
        final box = Hive.box(_gamificationBoxName);
        final legacyProfileJson = box.get(_legacyProfileKey);
        if (legacyProfileJson != null) {
          try {
            _cachedProfile = GamificationProfile.fromJson(jsonDecode(legacyProfileJson));
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
            notifyListeners(); // Notify listeners when profile is loaded
            return _cachedProfile!;
          } catch (e) {
            WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          }
        }
        // Return a very basic, non-savable guest profile if no legacy one
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        _cachedProfile = GamificationProfile(
          userId: 'guest_user_${DateTime.now().millisecondsSinceEpoch}',
          streaks: {
            StreakType.dailyClassification.toString(): StreakDetails(
              type: StreakType.dailyClassification,
              currentCount: 1, // Start guest with streak of 1
              longestCount: 1,
              lastActivityDate: DateTime.now(),
            ),
          },
          points: const UserPoints(),
          achievements: getDefaultAchievements(), // Provide default achievements
          discoveredItemIds: {},
          unlockedHiddenContentIds: {},
        );
        notifyListeners(); // Notify listeners when profile is created
        return _cachedProfile!;
      }

      if (currentUserProfile.gamificationProfile != null) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        _cachedProfile = currentUserProfile.gamificationProfile!;
        notifyListeners(); // Notify listeners when profile is loaded
        return _cachedProfile!;
      } else {
        // Logged-in user, but no gamification profile exists yet. Create one.
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        
        // Load default challenges safely
        var activeChallenges = <Challenge>[];
        try {
          activeChallenges = await _loadDefaultChallengesFromHive();
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          // Continue with empty challenges list
        }
        
        final newGamificationProfile = GamificationProfile(
          userId: currentUserProfile.id, // Crucial: Use the actual user ID
          streaks: {
            StreakType.dailyClassification.toString(): StreakDetails(
              type: StreakType.dailyClassification,
              lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
          },
          points: const UserPoints(),
          achievements: getDefaultAchievements(), // Provide default achievements
          activeChallenges: activeChallenges, // Use safely loaded challenges
          discoveredItemIds: {},
          unlockedHiddenContentIds: {},
        );

        // Save this new gamification profile as part of the UserProfile
        try {
          await saveProfile(newGamificationProfile); // This will save UserProfile locally and to Firestore
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          // Return the profile anyway, even if saving failed
        }
        
        _cachedProfile = newGamificationProfile;
        notifyListeners(); // Notify listeners when profile is created
        return _cachedProfile!;
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Create a fallback profile to prevent the app from hanging
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      _cachedProfile = GamificationProfile(
        userId: 'emergency_user_${DateTime.now().millisecondsSinceEpoch}',
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(),
        achievements: [], // Empty achievements to prevent further errors
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      );
      notifyListeners();
      return _cachedProfile!;
    }
  }
  
  Future<List<Challenge>> _loadDefaultChallengesFromHive() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      final box = Hive.box(_gamificationBoxName);
      final challengesJson = box.get(_defaultChallengesKey);
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      if (challengesJson != null && challengesJson is String && challengesJson.isNotEmpty) {
        try {
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          final List<dynamic> decoded = jsonDecode(challengesJson);
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          final challenges = decoded.map((data) => Challenge.fromJson(Map<String, dynamic>.from(data))).toList();
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          return challenges;
        } catch (decodeError) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      } else {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        // Initialize challenges if they don't exist or are invalid
        try {
          await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        } catch (putError) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
    
    // Always return a fallback list using the fresh challenge templates
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    try {
      final fallbackChallenges = _getDefaultChallenges().map((c) => Challenge.fromJson(c)).toList();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      return fallbackChallenges;
    } catch (fallbackError) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Return empty list as absolute last resort
      return [];
    }
  }

  Future<void> saveProfile(GamificationProfile gamificationProfileToSave) async {
    final currentUserProfile = await _storageService.getCurrentUserProfile();

    if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Save to legacy Hive for guest state
      final box = Hive.box(_gamificationBoxName);
      await box.put(_legacyProfileKey, jsonEncode(gamificationProfileToSave.toJson()));
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      _cachedProfile = gamificationProfileToSave;
      notifyListeners();
      return;
    }

    // Ensure the gamification profile's user ID matches the current user's ID
    if (gamificationProfileToSave.userId != currentUserProfile.id) {
      WasteAppLogger.warning('Warning occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      gamificationProfileToSave = gamificationProfileToSave.copyWith(userId: currentUserProfile.id);
    }
    
    final updatedUserProfile = currentUserProfile.copyWith(
      gamificationProfile: gamificationProfileToSave,
      lastActive: DateTime.now(), // Also update lastActive timestamp on the main profile
    );

    try {
      await _storageService.saveUserProfile(updatedUserProfile);
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});

      await _cloudStorageService.saveUserProfileToFirestore(updatedUserProfile);
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      _cachedProfile = gamificationProfileToSave;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Decide on error handling strategy. For now, just logging.
      rethrow;
    }
  }
  
  // Update streak when the app is used
  Future<Streak> updateStreak() async {
    if (_isUpdatingStreak) {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      final profile = await getProfile();
      final dailyStreakKey = StreakType.dailyClassification.toString();
      final currentStreak = profile.streaks[dailyStreakKey];
      
      return Streak(
        current: currentStreak?.currentCount ?? 0,
        longest: currentStreak?.longestCount ?? 0,
        lastUsageDate: currentStreak?.lastActivityDate ?? DateTime.now(),
      );
    }

    _isUpdatingStreak = true;
    try {
      final profile = await getProfile();
      final now = DateTime.now();
      
      // Get the daily classification streak
      final dailyStreakKey = StreakType.dailyClassification.toString();
      final currentStreak = profile.streaks[dailyStreakKey];
      
      if (currentStreak == null) {
        // Initialize streak if it doesn't exist
        final newStreakDetails = StreakDetails(
          type: StreakType.dailyClassification,
          currentCount: 1,
          longestCount: 1,
          lastActivityDate: now,
        );
        
        final updatedStreaks = Map<String, StreakDetails>.from(profile.streaks);
        updatedStreaks[dailyStreakKey] = newStreakDetails;
        
        await saveProfile(profile.copyWith(streaks: updatedStreaks));
        
        // Return legacy Streak format for compatibility
        return Streak(
          current: 1,
          longest: 1,
          lastUsageDate: now,
        );
      }
      
      final lastUsage = currentStreak.lastActivityDate;
      
      // Create date objects for comparison (time-agnostic)
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final lastUsageDay = DateTime(lastUsage.year, lastUsage.month, lastUsage.day);
      
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      var newCurrent = currentStreak.currentCount;
      var shouldSave = false;
      
      if (lastUsageDay.isAtSameMomentAs(today)) {
        // Already used today, keep current streak (but ensure it's at least 1)
        if (currentStreak.currentCount == 0) {
          newCurrent = 1;
          shouldSave = true;
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        } else {
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          // Return legacy Streak format for compatibility
          return Streak(
            current: currentStreak.currentCount,
            longest: currentStreak.longestCount,
            lastUsageDate: currentStreak.lastActivityDate,
          );
        }
      } else if (lastUsageDay.isAtSameMomentAs(yesterday)) {
        // Last used yesterday, increment streak
        newCurrent = currentStreak.currentCount + 1;
        shouldSave = true;
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      } else {
        // Last used before yesterday or never, start new streak
        newCurrent = 1;
        shouldSave = true;
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      if (!shouldSave) {
        return Streak(
          current: currentStreak.currentCount,
          longest: currentStreak.longestCount,
          lastUsageDate: currentStreak.lastActivityDate,
        );
      }
      
      // Update longest streak if needed
      final newLongest = newCurrent > currentStreak.longestCount 
          ? newCurrent 
          : currentStreak.longestCount;
      
      final newStreakDetails = currentStreak.copyWith(
        currentCount: newCurrent,
        longestCount: newLongest,
        lastActivityDate: now,
      );
      
      // Update the profile with the new streak
      final updatedStreaks = Map<String, StreakDetails>.from(profile.streaks);
      updatedStreaks[dailyStreakKey] = newStreakDetails;
      
      await saveProfile(profile.copyWith(streaks: updatedStreaks));
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Award points for streak (only if streak increased)
      if (newCurrent > currentStreak.currentCount) {
        await addPoints('daily_streak');
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        
        // Record streak activity in community feed
        try {
          final communityService = CommunityService();
          await communityService.initCommunity();
          final userProfile = await _storageService.getCurrentUserProfile();
          if (userProfile != null) {
            await communityService.recordStreak(newCurrent, userProfile);
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          }
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      }
      
      // Check for streak achievements
      if (newCurrent >= 3) {
        await updateAchievementProgress(AchievementType.streakMaintained, newCurrent);
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      // Check for perfect week
      if (newCurrent % 7 == 0 && newCurrent > 0) {
        await updateAchievementProgress(AchievementType.perfectWeek, newCurrent ~/ 7);
        await addPoints('perfect_week');
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      // Return legacy Streak format for compatibility
      return Streak(
        current: newCurrent,
        longest: newLongest,
        lastUsageDate: now,
      );
    } finally {
      _isUpdatingStreak = false;
    }
  }
  
  // Add points for an action - Delegates to Points Engine
  Future<UserPoints> addPoints(String action, {String? category, int? customPoints}) async {
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    
    // Initialize Points Engine if needed
    await _pointsEngine.initialize();
    
    // Delegate to Points Engine
    final points = await _pointsEngine.addPoints(
      action,
      category: category,
      customPoints: customPoints,
      metadata: {
        'source': 'GamificationService',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Update cached profile from Points Engine
    _cachedProfile = _pointsEngine.currentProfile;
    notifyListeners();
    
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    return points;
  }
  
  Future<UserPoints> _addPointsInternal(String action, {String? category, int? customPoints}) async {
    final profile = await getProfile();
    final points = profile.points;
    
    final pointsToAdd = customPoints ?? _pointValues[action] ?? 0;
    if (pointsToAdd == 0 && customPoints == null) {
       WasteAppLogger.warning('Warning occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      return points; // Return early if no points to add
     }
    
    final newTotal = points.total + pointsToAdd;
    final newWeekly = points.weeklyTotal + pointsToAdd;
    final newMonthly = points.monthlyTotal + pointsToAdd;
    final newLevel = (newTotal / 100).floor() + 1; // Level is 1-indexed: 0-99 pts = level 1, 100-199 pts = level 2
    
    final newCategoryPoints = Map<String, int>.from(points.categoryPoints);
    if (category != null && category.isNotEmpty) {
      newCategoryPoints[category] = (newCategoryPoints[category] ?? 0) + pointsToAdd;
    }
    
    final newPoints = UserPoints(
      total: newTotal,
      weeklyTotal: newWeekly,
      monthlyTotal: newMonthly,
      level: newLevel,
      categoryPoints: newCategoryPoints,
    );
    
    // This will call the new saveProfile, which updates UserProfile and syncs
    await saveProfile(profile.copyWith(points: newPoints)); 
    
    // NOTE: Weekly stats are now synced via syncWeeklyStatsWithClassifications()
    // which recalculates from actual classification data, no need for incremental updates
    
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    return newPoints;
  }

  /// Ensure points reflect the number of classifications recorded.
  /// If classifications exceed points earned, award the missing points.
  Future<void> syncClassificationPoints() async {
    try {
      // Get all classifications for the current user
      final classifications = await _storageService.getAllClassifications();
      final expected = classifications.length * (_pointValues['classification'] ?? 10);

      final profile = await getProfile();
      if (profile.points.total < expected) {
        final diff = expected - profile.points.total;
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        await _addPointsInternal('classification_sync', customPoints: diff);
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
  }

  /// Ensure achievement progress reflects all stored classifications.
  /// Useful when classifications were imported or processed offline.
  Future<void> syncAchievementProgressFromClassifications() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      final classifications = await _storageService.getAllClassifications();
      final profile = await getProfile();

      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});

      // Calculate total classifications and unique categories
      final total = classifications.length;
      final categories = classifications.map((c) => c.category).toSet();
      final categoriesCount = categories.length;
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});

      final updatedAchievements = profile.achievements.map((achievement) {
        var wasUpdated = false;
        var newAchievement = achievement;
        
        if (achievement.type == AchievementType.wasteIdentified) {
          final progress = (total / achievement.threshold).clamp(0.0, 1.0);
          final isLevelUnlocked = achievement.unlocksAtLevel == null || 
                                 profile.points.level >= achievement.unlocksAtLevel!;
          
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          
          if (progress >= 1.0 && isLevelUnlocked && !achievement.isEarned) {
            final claimStatus = achievement.tier == AchievementTier.bronze
                ? ClaimStatus.claimed
                : ClaimStatus.unclaimed;
            newAchievement = achievement.copyWith(
              progress: 1.0,
              earnedOn: DateTime.now(),
              claimStatus: claimStatus,
            );
            wasUpdated = true;
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          } else if (achievement.progress != progress) {
            newAchievement = achievement.copyWith(progress: progress);
            wasUpdated = true;
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          }
        } else if (achievement.type == AchievementType.categoriesIdentified) {
          final progress = (categoriesCount / achievement.threshold).clamp(0.0, 1.0);
          final isLevelUnlocked = achievement.unlocksAtLevel == null || 
                                 profile.points.level >= achievement.unlocksAtLevel!;
          
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          
          if (progress >= 1.0 && isLevelUnlocked && !achievement.isEarned) {
            final claimStatus = achievement.tier == AchievementTier.bronze
                ? ClaimStatus.claimed
                : ClaimStatus.unclaimed;
            newAchievement = achievement.copyWith(
              progress: 1.0,
              earnedOn: DateTime.now(),
              claimStatus: claimStatus,
            );
            wasUpdated = true;
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          } else if (achievement.progress != progress) {
            newAchievement = achievement.copyWith(progress: progress);
            wasUpdated = true;
            WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          }
        }
        
        return newAchievement;
      }).toList();

      await saveProfile(profile.copyWith(achievements: updatedAchievements));
      
      final earnedCount = updatedAchievements.where((a) => a.isEarned).length;
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      rethrow;
    }
  }
  
  // Process a waste classification for gamification
  // Returns a list of completed challenges
  Future<List<Challenge>> processClassification(WasteClassification classification) async {
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    
    // Get profile before making changes to detect newly earned achievements
    final profileBefore = await getProfile();
    final oldEarnedIds = profileBefore.achievements
        .where((a) => a.isEarned)
        .map((a) => a.id)
        .toSet();
    
    await addPoints('classification', category: classification.category);
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    
    final categoriesBeforeCount = profileBefore.points.categoryPoints.keys.length;
    
    // Update waste identification achievements
    await updateAchievementProgress(AchievementType.wasteIdentified, 1);
    
    // Get updated profile to check categories
    final profileAfter = await getProfile();
    final categoriesAfterCount = profileAfter.points.categoryPoints.keys.length;
    
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    
    // Check if this is a new category
    if (categoriesAfterCount > categoriesBeforeCount) {
      // This is a new category! Update categories achievement
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      await updateAchievementProgress(
        AchievementType.categoriesIdentified, 
        categoriesAfterCount
      );
    } else {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
    
    // NEW: Check for newly earned achievements and emit them
    final finalProfile = await getProfile();
    final newlyEarned = finalProfile.achievements
        .where((a) => a.isEarned && !oldEarnedIds.contains(a.id))
        .toList();
    
    if (newlyEarned.isNotEmpty) {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Emit the first newly earned achievement through PointsEngine
      _pointsEngine.achievementController.add(newlyEarned.first);
    }
    
    // Update active challenges
    final completedChallenges = await updateChallengeProgress(classification);
    
    // Record classification activity in community feed
    try {
      final communityService = CommunityService();
      await communityService.initCommunity();
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile != null) {
        await communityService.recordClassification(classification, userProfile);
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
    
    return completedChallenges;
  }
  
  // Process educational content interaction
  Future<void> processEducationalContent(EducationalContent content) async {
    // Add points for viewing educational content
    await addPoints('educational_content');
    
    // Update educational achievements
    await updateAchievementProgress(AchievementType.knowledgeMaster, 1);
    
    // If it's a quiz, add additional points when completed
    if (content.type == ContentType.quiz) {
      await addPoints('quiz_completed');
      await updateAchievementProgress(AchievementType.quizCompleted, 1);
    }
  }
  
  // Update achievement progress
  Future<List<Achievement>> updateAchievementProgress(
    AchievementType type, 
    int increment
  ) async {
    final profile = await getProfile();
    final achievements = List<Achievement>.from(profile.achievements);
    final newlyEarned = <Achievement>[];
    
    // Find all achievements of this type
    for (var i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      
      // Process achievements of the correct type that haven't been earned yet
      if (achievement.type == type && !achievement.isEarned) {
        
        // Calculate new progress
        double newProgress;
        
        if (achievement.type == AchievementType.categoriesIdentified) {
          // For categories, use the actual count as progress
          newProgress = increment / achievement.threshold;
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        } else {
          // For other achievements, use incremental progress
          final currentProgress = achievement.progress * achievement.threshold;
          final newRawProgress = currentProgress + increment;
          newProgress = newRawProgress / achievement.threshold;
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
        
        // Check if achievement is now earned (requires both progress AND level unlock)
        final isLevelUnlocked = achievement.unlocksAtLevel == null || profile.points.level >= achievement.unlocksAtLevel!;
        
        // DEBUGGING: Log achievement progress for "Waste Apprentice"
        if (achievement.id == 'waste_apprentice') {
          WasteAppLogger.cacheEvent('cache_operation', 'classification', context: {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
        
        if (newProgress >= 1.0 && isLevelUnlocked) {
          // Achievement earned!
          final ClaimStatus claimStatus;
          
          // Determine if the achievement should be auto-claimed or requires manual claiming
          if (achievement.tier == AchievementTier.bronze) {
            // Auto-claim bronze achievements
            claimStatus = ClaimStatus.claimed;
            // Award points immediately
            await addPoints('badge_earned', customPoints: achievement.pointsReward);
          } else {
            // Higher tier achievements require manual claiming
            claimStatus = ClaimStatus.unclaimed;
          }
          
          achievements[i] = achievement.copyWith(
            progress: 1.0,
            earnedOn: DateTime.now(),
            claimStatus: claimStatus,
          );
          
          // Add to newly earned list
          newlyEarned.add(achievements[i]);
          
          // Record achievement activity in community feed
          try {
            final communityService = CommunityService();
            await communityService.initCommunity();
            final userProfile = await _storageService.getCurrentUserProfile();
            if (userProfile != null) {
              await communityService.recordAchievement(achievement, userProfile);
              WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
            }
          } catch (e) {
            WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          }
          
          // For auto-claimed achievements, points are already added above
          // No additional points needed for bronze tier achievements
          
          // Check for meta-achievements (achievements for earning other achievements)
          await _checkMetaAchievements(achievements);
          
        } else {
          // Update progress (even for locked achievements so they can track progress)
          achievements[i] = achievement.copyWith(
            progress: newProgress > 1.0 ? 1.0 : newProgress,
          );
        }
      }
    }
    
    // Save updated achievements
    await saveProfile(profile.copyWith(achievements: achievements));
    
    return newlyEarned;
  }
  
  // Check and update meta-achievements progress
  Future<void> _checkMetaAchievements(List<Achievement> achievements) async {
    // Count earned achievements
    final earnedCount = achievements.where((a) => a.isEarned).length;
    
    // Update meta-achievements based on total achievements earned
    for (var i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      
      if (achievement.type == AchievementType.metaAchievement && !achievement.isEarned) {
        // Calculate progress based on total achievements earned vs threshold
        final newProgress = earnedCount / achievement.threshold;
        
        // Update the meta-achievement progress
        achievements[i] = achievement.copyWith(
          progress: newProgress > 1.0 ? 1.0 : newProgress,
          earnedOn: newProgress >= 1.0 ? DateTime.now() : null,
          claimStatus: newProgress >= 1.0 ? ClaimStatus.unclaimed : ClaimStatus.ineligible,
        );
        
        // If meta-achievement is newly earned, award points
        if (newProgress >= 1.0 && !achievement.isEarned) {
          await addPoints('badge_earned');
        }
      }
    }
  }
  
  // Get active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    final profile = await getProfile();
    
    // Filter out expired challenges and add new ones if needed
    final active = profile.activeChallenges
        .where((challenge) => !challenge.isExpired)
        .toList();
    
    // If we have fewer than 3 active challenges, add new ones
    if (active.length < 3) {
      final additionalChallenges = await _generateNewChallenges(3 - active.length);
      active.addAll(additionalChallenges);
      
      // Save the updated challenges
      await saveProfile(profile.copyWith(activeChallenges: active));
    }
    
    return active;
  }
  
  // Update challenge progress based on a classification
  Future<List<Challenge>> updateChallengeProgress(WasteClassification classification) async {
    final profile = await getProfile();
    final activeChallenges = List<Challenge>.from(profile.activeChallenges);
    final completedChallenges = List<Challenge>.from(profile.completedChallenges);
    final newlyCompleted = <Challenge>[];
    
    for (var i = 0; i < activeChallenges.length; i++) {
      final challenge = activeChallenges[i];
      
      if (!challenge.isExpired && !challenge.isCompleted) {
        // Check if this classification helps with the challenge
        final reqs = challenge.requirements;
        
        var updated = false;
        var newProgress = challenge.progress;
        
        // Handle different challenge types
        if (reqs.containsKey('category') && 
            reqs['category'] == classification.category) {
          // Category-specific challenge
          final int count = reqs['count'] ?? 1;
          final current = (challenge.progress * count).round();
          final newValue = current + 1;
          newProgress = newValue / count;
          updated = true;
        } else if (reqs.containsKey('subcategory') && 
                  classification.subcategory == reqs['subcategory']) {
          // Subcategory-specific challenge
          final int count = reqs['count'] ?? 1;
          final current = (challenge.progress * count).round();
          final newValue = current + 1;
          newProgress = newValue / count;
          updated = true;
        } else if (reqs.containsKey('any_item') && reqs['any_item'] == true) {
          // Any item identified challenge
          final int count = reqs['count'] ?? 1;
          final current = (challenge.progress * count).round();
          final newValue = current + 1;
          newProgress = newValue / count;
          updated = true;
        }
        
        // Update challenge if needed
        if (updated) {
          // Cap progress at 1.0
          newProgress = newProgress > 1.0 ? 1.0 : newProgress;
          
          // Check if challenge is now completed
          final isNowCompleted = newProgress >= 1.0;
          
          activeChallenges[i] = challenge.copyWith(
            progress: newProgress,
            isCompleted: isNowCompleted,
          );
          
          // If completed, move to completed challenges and award points
          if (isNowCompleted) {
            final completedChallenge = activeChallenges[i];
            completedChallenges.add(completedChallenge);
            newlyCompleted.add(completedChallenge);
            
            // Award points
            await addPoints('challenge_complete', customPoints: completedChallenge.pointsReward);
            
            // Update achievement
            await updateAchievementProgress(AchievementType.challengesCompleted, 1);
          }
        }
      }
    }
    
    // Remove completed challenges from active list
    activeChallenges.removeWhere((c) => c.isCompleted || c.isExpired);
    
    // Save updated challenges
    await saveProfile(
      profile.copyWith(
        activeChallenges: activeChallenges,
        completedChallenges: completedChallenges,
      )
    );
    
    // Return newly completed challenges
    return newlyCompleted;
  }
  
  // Get weekly stats for leaderboards
  Future<List<WeeklyStats>> getWeeklyStats() async {
    final box = Hive.box(_gamificationBoxName);
    final statsJson = box.get(_weeklyStatsKey);
    
    if (statsJson == null) {
      return [];
    }
    
    final List<dynamic> jsonList = jsonDecode(statsJson);
    return jsonList
        .map((json) => WeeklyStats.fromJson(json))
        .toList();
  }
  
  // Update weekly stats
  Future<void> _updateWeeklyStats(String action, String? category, int pointsEarned) async {
    final box = Hive.box(_gamificationBoxName);
    final now = DateTime.now();
    
    // Get the start of the current week (Sunday)
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    // Get existing stats
    final allStats = await getWeeklyStats();
    
    // Find or create current week's stats
    WeeklyStats currentWeekStats;
    var currentWeekIndex = allStats.indexWhere(
      (stats) => stats.weekStartDate.isAtSameMomentAs(weekStartDate)
    );
    
    if (currentWeekIndex >= 0) {
      currentWeekStats = allStats[currentWeekIndex];
    } else {
      currentWeekStats = WeeklyStats(weekStartDate: weekStartDate);
      currentWeekIndex = -1;
    }
    
    // Update stats based on action
    var newItemsIdentified = currentWeekStats.itemsIdentified;
    var newChallengesCompleted = currentWeekStats.challengesCompleted;
    final newPointsEarned = currentWeekStats.pointsEarned + pointsEarned;
    final newCategoryCounts = Map<String, int>.from(currentWeekStats.categoryCounts);
    
    // Update specific stats based on action
    if (action == 'classification') {
      newItemsIdentified++;
      if (category != null) {
        newCategoryCounts[category] = (newCategoryCounts[category] ?? 0) + 1;
      }
    } else if (action == 'challenge_complete') {
      newChallengesCompleted++;
    }
    
    // Get streak from profile
    final profile = await getProfile();
    final dailyStreak = profile.streaks[StreakType.dailyClassification.toString()];
    final streakValue = dailyStreak?.currentCount ?? 0;
    
    // Create updated stats
    final updatedStats = currentWeekStats.copyWith(
      itemsIdentified: newItemsIdentified,
      challengesCompleted: newChallengesCompleted,
      pointsEarned: newPointsEarned,
      streakMaximum: streakValue > currentWeekStats.streakMaximum 
          ? streakValue 
          : currentWeekStats.streakMaximum,
      categoryCounts: newCategoryCounts,
    );
    
    // Update list of all stats
    if (currentWeekIndex >= 0) {
      allStats[currentWeekIndex] = updatedStats;
    } else {
      allStats.add(updatedStats);
    }
    
    // Keep only the last 12 weeks of stats
    final limitedStats = allStats.length > 12 
        ? allStats.sublist(allStats.length - 12) 
        : allStats;
    
    // Save updated stats to local storage
    await box.put(
      _weeklyStatsKey,
      jsonEncode(limitedStats.map((s) => s.toJson()).toList()),
    );

    // Also persist the stats on the gamification profile so that UI widgets
    // using the profile data reflect the latest numbers immediately.
    // We reuse the fetched profile from above to avoid another read.
    await saveProfile(profile.copyWith(weeklyStats: limitedStats));
  }
  
  // Generate new challenges
  Future<List<Challenge>> _generateNewChallenges(int count) async {
    final box = Hive.box(_gamificationBoxName);
    final defaultChallengesJson = box.get(_defaultChallengesKey);
    
    if (defaultChallengesJson == null) {
      return [];
    }
    
    final List<dynamic> templates = jsonDecode(defaultChallengesJson);
    final now = DateTime.now();
    final challenges = <Challenge>[];
    
    // Get random templates
    templates.shuffle();
    final selectedTemplates = templates.take(count).toList();
    
    for (final template in selectedTemplates) {
      final Map<String, dynamic> templateData = template;
      
      // Create a challenge with a one-week duration
      final challenge = Challenge(
        id: 'challenge_${now.millisecondsSinceEpoch}_${challenges.length}',
        title: templateData['title'],
        description: templateData['description'],
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        pointsReward: templateData['pointsReward'] ?? 25,
        iconName: templateData['iconName'] ?? 'task_alt',
        color: templateData['color'] != null ? Color(templateData['color']) : AppTheme.secondaryColor,
        requirements: templateData['requirements'] ?? {'any_item': true, 'count': 5},
      );
      
      challenges.add(challenge);
    }
    
    return challenges;
  }
  
  // Generate default achievement templates
  List<Achievement> getDefaultAchievements() {
    return [
      // Waste identification achievements - TIERED FAMILY
      const Achievement(
        id: 'waste_novice',
        title: 'Waste Novice',
        description: 'Identify your first 5 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 5,
        iconName: 'emoji_objects',
        color: AppTheme.primaryColor,
        achievementFamilyId: 'Waste Identifier',
      ),
      const Achievement(
        id: 'waste_apprentice',
        title: 'Waste Apprentice',
        description: 'Identify 15 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 15,
        iconName: 'recycling',
        color: AppTheme.primaryColor,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 100,
        unlocksAtLevel: 2,
      ),
      const Achievement(
        id: 'waste_expert',
        title: 'Waste Expert',
        description: 'Identify 100 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 100,
        iconName: 'workspace_premium',
        color: AppTheme.primaryColor,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 200,
        unlocksAtLevel: 5,
      ),
      const Achievement(
        id: 'waste_master',
        title: 'Waste Master',
        description: 'Identify 500 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 500,
        iconName: 'military_tech',
        color: AppTheme.primaryColor,
        tier: AchievementTier.platinum,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 500,
        unlocksAtLevel: 10,
      ),
      
      // Categories achievements - TIERED FAMILY
      const Achievement(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Identify items from 3 different waste categories',
        type: AchievementType.categoriesIdentified,
        threshold: 3,
        iconName: 'category',
        color: AppTheme.secondaryColor,
        achievementFamilyId: 'Category Expert',
        pointsReward: 75,
      ),
      const Achievement(
        id: 'category_master',
        title: 'Category Master',
        description: 'Identify items from all 5 waste categories',
        type: AchievementType.categoriesIdentified,
        threshold: 5,
        iconName: 'category',
        color: AppTheme.secondaryColor,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Category Expert',
        pointsReward: 150,
      ),
      const Achievement(
        id: 'category_collector',
        title: 'Category Collector',
        description: 'Identify 10 items from each waste category',
        type: AchievementType.categoriesIdentified,
        threshold: 50, // 10 items × 5 categories
        iconName: 'category',
        color: AppTheme.secondaryColor,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Category Expert',
        pointsReward: 250,
        unlocksAtLevel: 7,
      ),
      
      // Streak achievements - TIERED FAMILY
      const Achievement(
        id: 'streak_starter',
        title: 'Streak Starter',
        description: 'Use the app for 3 days in a row',
        type: AchievementType.streakMaintained,
        threshold: 3,
        iconName: 'local_fire_department',
        color: Colors.orange,
        achievementFamilyId: 'Streak Maintainer',
      ),
      const Achievement(
        id: 'streak_warrior',
        title: 'Streak Warrior',
        description: 'Use the app for 7 days in a row',
        type: AchievementType.streakMaintained,
        threshold: 7,
        iconName: 'local_fire_department',
        color: Colors.orange,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Streak Maintainer',
        pointsReward: 100,
      ),
      const Achievement(
        id: 'streak_master',
        title: 'Streak Master',
        description: 'Use the app for 30 days in a row',
        type: AchievementType.streakMaintained,
        threshold: 30,
        iconName: 'local_fire_department',
        color: Colors.orange,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Streak Maintainer',
        pointsReward: 300,
        unlocksAtLevel: 4,
      ),
      const Achievement(
        id: 'streak_legend',
        title: 'Streak Legend',
        description: 'Use the app for 100 days in a row',
        type: AchievementType.streakMaintained,
        threshold: 100,
        iconName: 'local_fire_department',
        color: Colors.orange,
        tier: AchievementTier.platinum,
        achievementFamilyId: 'Streak Maintainer',
        pointsReward: 1000,
        unlocksAtLevel: 8,
      ),
      
      // Perfect week achievements - TIERED FAMILY
      const Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: 'Use the app every day for a full week',
        type: AchievementType.perfectWeek,
        threshold: 1,
        iconName: 'event_available',
        color: Colors.teal,
        achievementFamilyId: 'Perfect Record',
        pointsReward: 75,
      ),
      const Achievement(
        id: 'perfect_month',
        title: 'Perfect Month',
        description: 'Complete 4 perfect weeks',
        type: AchievementType.perfectWeek,
        threshold: 4,
        iconName: 'event_available',
        color: Colors.teal,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Perfect Record',
        pointsReward: 150,
        unlocksAtLevel: 3,
      ),
      const Achievement(
        id: 'perfect_quarter',
        title: 'Perfect Quarter',
        description: 'Complete 12 perfect weeks',
        type: AchievementType.perfectWeek,
        threshold: 12,
        iconName: 'event_available',
        color: Colors.teal,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Perfect Record',
        pointsReward: 300,
        unlocksAtLevel: 6,
      ),
      
      // Challenge achievements - TIERED FAMILY
      const Achievement(
        id: 'challenge_taker',
        title: 'Challenge Taker',
        description: 'Complete your first challenge',
        type: AchievementType.challengesCompleted,
        threshold: 1,
        iconName: 'emoji_events',
        color: Colors.amber,
        achievementFamilyId: 'Challenge Conqueror',
      ),
      const Achievement(
        id: 'challenge_champion',
        title: 'Challenge Champion',
        description: 'Complete 5 challenges',
        type: AchievementType.challengesCompleted,
        threshold: 5,
        iconName: 'emoji_events',
        color: Colors.amber,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Challenge Conqueror',
        pointsReward: 100,
      ),
      const Achievement(
        id: 'challenge_master',
        title: 'Challenge Master',
        description: 'Complete 20 challenges',
        type: AchievementType.challengesCompleted,
        threshold: 20,
        iconName: 'emoji_events',
        color: Colors.amber,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Challenge Conqueror',
        pointsReward: 200,
        unlocksAtLevel: 5,
      ),
      const Achievement(
        id: 'challenge_legend',
        title: 'Challenge Legend',
        description: 'Complete 50 challenges',
        type: AchievementType.challengesCompleted,
        threshold: 50,
        iconName: 'emoji_events',
        color: Colors.amber,
        tier: AchievementTier.platinum,
        achievementFamilyId: 'Challenge Conqueror',
        pointsReward: 500,
        unlocksAtLevel: 10,
      ),
      
      // Knowledge achievements - TIERED FAMILY
      const Achievement(
        id: 'knowledge_seeker',
        title: 'Knowledge Seeker',
        description: 'View 5 educational content items',
        type: AchievementType.knowledgeMaster,
        threshold: 5,
        iconName: 'school',
        color: Colors.purple,
        achievementFamilyId: 'Knowledge Explorer',
      ),
      const Achievement(
        id: 'knowledge_adept',
        title: 'Knowledge Adept',
        description: 'View 20 educational content items',
        type: AchievementType.knowledgeMaster,
        threshold: 20,
        iconName: 'school',
        color: Colors.purple,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Knowledge Explorer',
        pointsReward: 100,
      ),
      const Achievement(
        id: 'knowledge_expert',
        title: 'Knowledge Expert',
        description: 'View 50 educational content items',
        type: AchievementType.knowledgeMaster,
        threshold: 50,
        iconName: 'school',
        color: Colors.purple,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Knowledge Explorer',
        pointsReward: 200,
        unlocksAtLevel: 3,
      ),
      
      // Quiz achievements - TIERED FAMILY
      const Achievement(
        id: 'quiz_taker',
        title: 'Quiz Taker',
        description: 'Complete your first quiz',
        type: AchievementType.quizCompleted,
        threshold: 1,
        iconName: 'quiz',
        color: Colors.indigo,
        achievementFamilyId: 'Quiz Champion',
      ),
      const Achievement(
        id: 'quiz_enthusiast',
        title: 'Quiz Enthusiast',
        description: 'Complete 5 quizzes',
        type: AchievementType.quizCompleted,
        threshold: 5,
        iconName: 'quiz',
        color: Colors.indigo,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Quiz Champion',
        pointsReward: 100,
      ),
      const Achievement(
        id: 'quiz_master',
        title: 'Quiz Master',
        description: 'Complete 10 quizzes',
        type: AchievementType.quizCompleted,
        threshold: 10,
        iconName: 'quiz',
        color: Colors.indigo,
        tier: AchievementTier.gold,
        achievementFamilyId: 'Quiz Champion',
        pointsReward: 200,
        unlocksAtLevel: 2,
      ),
      
      // Special achievements
      const Achievement(
        id: 'eco_warrior',
        title: 'Eco Warrior',
        description: 'Special achievement for dedicated users',
        type: AchievementType.specialItem,
        threshold: 1,
        iconName: 'eco',
        color: AppTheme.primaryColor,
        isSecret: true,
        tier: AchievementTier.gold,
        pointsReward: 250,
        metadata: {
          'requirements': 'Complete various environmental actions',
          'rarity': 'Very Rare'
        },
      ),
      
      // Meta-achievement
      const Achievement(
        id: 'achievement_hunter',
        title: 'Achievement Hunter',
        description: 'Earn 10 other achievements',
        type: AchievementType.metaAchievement,
        threshold: 10,
        iconName: 'auto_awesome',
        color: Colors.deepPurple,
        tier: AchievementTier.gold,
        pointsReward: 300,
        unlocksAtLevel: 4,
        metadata: {
          'requirements': 'Earn any 10 achievements',
          'rarity': 'Uncommon'
        },
      ),
    ];
  }
  
  // Default challenge templates
  List<Map<String, dynamic>> _getDefaultChallenges() {
    return [
      {
        'title': 'Plastic Hunter',
        'description': 'Identify 5 plastic items',
        'pointsReward': 25,
        'iconName': 'shopping_bag',
        'color': AppTheme.dryWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Plastic',
          'count': 5,
        },
      },
      {
        'title': 'Food Waste Warrior',
        'description': 'Identify 3 food waste items',
        'pointsReward': 20,
        'iconName': 'restaurant',
        'color': AppTheme.wetWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Food Waste',
          'count': 3,
        },
      },
      {
        'title': 'Recycling Champion',
        'description': 'Identify 5 recyclable items',
        'pointsReward': 25,
        'iconName': 'recycling',
        'color': AppTheme.dryWasteColor.toARGB32(),
        'requirements': {
          'category': 'Dry Waste',
          'count': 5,
        },
      },
      {
        'title': 'Compost Collector',
        'description': 'Identify 4 compostable items',
        'pointsReward': 20,
        'iconName': 'compost',
        'color': AppTheme.wetWasteColor.toARGB32(),
        'requirements': {
          'category': 'Wet Waste',
          'count': 4,
        },
      },
      {
        'title': 'Hazard Handler',
        'description': 'Identify 2 hazardous waste items',
        'pointsReward': 30,
        'iconName': 'warning',
        'color': AppTheme.hazardousWasteColor.toARGB32(),
        'requirements': {
          'category': 'Hazardous Waste',
          'count': 2,
        },
      },
      {
        'title': 'Medical Material Monitor',
        'description': 'Identify 2 medical waste items',
        'pointsReward': 30,
        'iconName': 'medical_services',
        'color': AppTheme.medicalWasteColor.toARGB32(),
        'requirements': {
          'category': 'Medical Waste',
          'count': 2,
        },
      },
      {
        'title': 'Reuse Revolutionary',
        'description': 'Identify 3 reusable items',
        'pointsReward': 25,
        'iconName': 'autorenew',
        'color': AppTheme.nonWasteColor.toARGB32(),
        'requirements': {
          'category': 'Non-Waste',
          'count': 3,
        },
      },
      {
        'title': 'Paper Pursuer',
        'description': 'Identify 4 paper items',
        'pointsReward': 20,
        'iconName': 'description',
        'color': AppTheme.dryWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Paper',
          'count': 4,
        },
      },
      {
        'title': 'Glass Gatherer',
        'description': 'Identify 3 glass items',
        'pointsReward': 25,
        'iconName': 'water_drop',
        'color': AppTheme.dryWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Glass',
          'count': 3,
        },
      },
      {
        'title': 'Metal Magnet',
        'description': 'Identify 3 metal items',
        'pointsReward': 25,
        'iconName': 'hardware',
        'color': AppTheme.dryWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Metal',
          'count': 3,
        },
      },
      {
        'title': 'Electronic Explorer',
        'description': 'Identify 2 electronic waste items',
        'pointsReward': 30,
        'iconName': 'devices',
        'color': AppTheme.hazardousWasteColor.toARGB32(),
        'requirements': {
          'subcategory': 'Electronic Waste',
          'count': 2,
        },
      },
      {
        'title': 'Waste Wizard',
        'description': 'Identify 10 waste items of any type',
        'pointsReward': 40,
        'iconName': 'auto_awesome',
        'color': Colors.amber.toARGB32(),
        'requirements': {
          'any_item': true,
          'count': 10,
        },
      },
    ];
  }
  
  /// Clear all gamification data and reset to default state
  Future<void> clearGamificationData() async {
    try {
      final box = Hive.box(_gamificationBoxName);
      
      // Get existing profile to archive points
      final existingProfileJson = box.get(_legacyProfileKey);
      if (existingProfileJson != null) {
        final existingProfile = GamificationProfile.fromJson(jsonDecode(existingProfileJson));
        
        // Archive current points if they exist
        if (existingProfile.points.total > 0) {
          await _archivePoints(existingProfile.points);
        }
      }
      
      // Clear all gamification data
      await box.clear();
      
      // Force recreation of fresh default profile with archived points reference
      final freshProfile = GamificationProfile(
        userId: 'default',
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(), // This ensures 0 current points
        achievements: getDefaultAchievements(),
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      );
      
      await box.put(_legacyProfileKey, jsonEncode(freshProfile.toJson()));
      
      // Reset default challenges
      await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      rethrow;
    }
  }
  
  /// Archive points when data is cleared
  Future<void> _archivePoints(UserPoints points) async {
    try {
      final box = Hive.box(_gamificationBoxName);
      
      final archiveEntry = {
        'points': points.toJson(),
        'archivedAt': DateTime.now().toIso8601String(),
        'reason': 'user_data_clear',
        'totalLifetimePoints': points.total,
      };
      
      // Store in a list of archived entries
      final existingArchives = box.get('archived_points_list', defaultValue: <String>[]);
      final archivesList = List<String>.from(existingArchives);
      archivesList.add(jsonEncode(archiveEntry));
      
      await box.put('archived_points_list', archivesList);
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      // Don't rethrow - archiving failure shouldn't block data clearing
    }
  }
  
  /// Get total lifetime points including archived points
  Future<int> getTotalLifetimePoints() async {
    try {
      final box = Hive.box(_gamificationBoxName);
      final profile = await getProfile();
      var totalLifetime = profile.points.total;
      
      // Add archived points
      final archivedList = box.get('archived_points_list', defaultValue: <String>[]);
      for (final archivedJson in archivedList) {
        try {
          final archived = jsonDecode(archivedJson);
          totalLifetime += archived['totalLifetimePoints'] as int? ?? 0;
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      }
      
      return totalLifetime;
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      final profile = await getProfile();
      return profile.points.total; // Fallback to current points only
    }
  }
  
  /// Get archived points history
  Future<List<Map<String, dynamic>>> getArchivedPointsHistory() async {
    try {
      final box = Hive.box(_gamificationBoxName);
      final archivedList = box.get('archived_points_list', defaultValue: <String>[]);
      
      final history = <Map<String, dynamic>>[];
      for (final archivedJson in archivedList) {
        try {
          final archived = jsonDecode(archivedJson);
          history.add(archived);
        } catch (e) {
          WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        }
      }
      
      // Sort by archived date (newest first)
      history.sort((a, b) {
        final dateA = DateTime.tryParse(a['archivedAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['archivedAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      
      return history;
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      return [];
    }
  }
  
  /// Reset streak to yesterday for testing (simulates missing a day)
  Future<void> resetStreakToYesterday() async {
    try {
      final profile = await getProfile();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final dailyStreakKey = StreakType.dailyClassification.toString();
      final currentStreak = profile.streaks[dailyStreakKey];
      
      if (currentStreak != null) {
        final updatedStreak = currentStreak.copyWith(
          lastActivityDate: yesterday,
        );
        
        final updatedStreaks = Map<String, StreakDetails>.from(profile.streaks);
        updatedStreaks[dailyStreakKey] = updatedStreak;
        
        await saveProfile(profile.copyWith(streaks: updatedStreaks));
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
  }

  /// Force refresh gamification profile from storage
  Future<GamificationProfile> forceRefreshProfile() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // Clear any cached data and reload from storage
      final currentUserProfile = await _storageService.getCurrentUserProfile();
      
      if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
        WasteAppLogger.warning('Warning occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        return await getProfile(); // Fallback to regular getProfile
      }
      
      // Reload user profile from storage to get latest data
      try {
        final refreshedProfile = await _storageService.getCurrentUserProfile();
        if (refreshedProfile != null && refreshedProfile.gamificationProfile != null) {
          WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
          return refreshedProfile.gamificationProfile!;
        }
      } catch (e) {
        WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      }
      
      // Fallback to creating new profile if none exists
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      return await getProfile();
      
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      return getProfile(); // Fallback to regular getProfile
    }
  }

  /// Force a complete gamification data refresh and sync
  Future<void> forceCompleteSyncAndRefresh() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 1. Sync classification points
      await syncClassificationPoints();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 2. Sync achievement progress
      await syncAchievementProgressFromClassifications();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 3. Update streak for today
      await updateStreak();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 4. Initialize community service
      final communityService = CommunityService();
      await communityService.initCommunity();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 5. Force refresh profile
      final profile = await forceRefreshProfile();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      // 6. Log final achievement status
      final earnedAchievements = profile.achievements.where((a) => a.isEarned).toList();
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      rethrow;
    }
  }

  /// Sync gamification data across all app components
  Future<void> syncGamificationData() async {
    try {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});

      // Ensure points accurately reflect all stored classifications
      await syncClassificationPoints();

      // Force refresh profile
      final profile = await forceRefreshProfile();
      
      // Update streak for today if needed
      await updateStreak();

      // Ensure achievements are properly initialized
      if (profile.achievements.isEmpty) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        final updatedProfile = profile.copyWith(achievements: getDefaultAchievements());
        await saveProfile(updatedProfile);
      }

      // Recalculate achievement progress from stored classifications
      await syncAchievementProgressFromClassifications();
      
      // Ensure challenges are loaded
      if (profile.activeChallenges.isEmpty) {
        WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
        final challenges = await _loadDefaultChallengesFromHive();
        if (challenges.isNotEmpty) {
          final updatedProfile = profile.copyWith(activeChallenges: challenges);
          await saveProfile(updatedProfile);
        }
      }
      
      WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    }
  }

  /// Sync weekly stats with actual classification data from storage service
  /// This fixes the mismatch between weekly progress and daily analytics
  Future<void> syncWeeklyStatsWithClassifications() async {
    try {
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
      
      // Get all classifications from storage service
      final classifications = await _storageService.getAllClassifications();
      if (classifications.isEmpty) {
        WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
        return;
      }
      
      // Group classifications by week
      final weeklyClassifications = <DateTime, List<WasteClassification>>{};
      
      for (final classification in classifications) {
        // Calculate week start (Monday)
        final date = classification.timestamp;
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        
        weeklyClassifications.putIfAbsent(weekStartDate, () => []).add(classification);
      }
      
      // Generate weekly stats from actual data
      final updatedWeeklyStats = <WeeklyStats>[];
      
      for (final entry in weeklyClassifications.entries) {
        final weekStart = entry.key;
        final weekClassifications = entry.value;
        
        // Calculate category counts
        final categoryCounts = <String, int>{};
        for (final classification in weekClassifications) {
          categoryCounts.update(
            classification.category,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
        
        // Calculate points from actual classifications or default to 10 per item
        var pointsEarned = 0;
        for (final classification in weekClassifications) {
          pointsEarned += classification.pointsAwarded ?? 10;
        }
        
        // Calculate streak for this week (simplified - max consecutive days)
        final weekDays = <DateTime>{};
        for (final classification in weekClassifications) {
          final day = DateTime(
            classification.timestamp.year,
            classification.timestamp.month,
            classification.timestamp.day,
          );
          weekDays.add(day);
        }
        
        final weeklyStats = WeeklyStats(
          weekStartDate: weekStart,
          itemsIdentified: weekClassifications.length,
          streakMaximum: weekDays.length, // Number of unique days with activity
          pointsEarned: pointsEarned,
          categoryCounts: categoryCounts,
        );
        
        updatedWeeklyStats.add(weeklyStats);
      }
      
      // Sort by week start date (newest first)
      updatedWeeklyStats.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
      
      // Update the profile with synced weekly stats
      final currentProfile = await getProfile();
      final updatedProfile = currentProfile.copyWith(weeklyStats: updatedWeeklyStats);
      
      await saveProfile(updatedProfile);
      
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
      
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
      WasteAppLogger.performanceLog('gamification', 0, context: {'service': 'gamification', 'file': 'gamification_service'});
    }
  }

  /// Clear cached profile (useful for logout/reset scenarios)
  void clearCache() {
    WasteAppLogger.info('Operation completed', null, null, {'service': 'gamification', 'file': 'gamification_service'});
    _cachedProfile = null;
    notifyListeners();
  }
}