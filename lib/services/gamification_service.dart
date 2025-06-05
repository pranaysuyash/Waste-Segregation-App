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

/// Service for managing gamification features
class GamificationService {
  
  GamificationService(this._storageService, this._cloudStorageService);
  // Dependencies
  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;

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
      debugPrint('🚀 Initializing GamificationService...');
      
      // Ensure Hive box is opened
      if (!Hive.isBoxOpen(_gamificationBoxName)) {
        debugPrint('📦 Opening Hive box: $_gamificationBoxName');
        await Hive.openBox(_gamificationBoxName);
      } else {
        debugPrint('📦 Hive box already open: $_gamificationBoxName');
      }
      
      final box = Hive.box(_gamificationBoxName);
      debugPrint('📦 Hive box obtained successfully');
      
      // Initialize default challenges if they don't exist
      final challengesJson = box.get(_defaultChallengesKey);
      debugPrint('🔧 Existing challenges in box: $challengesJson (type: ${challengesJson.runtimeType})');
      
      if (challengesJson == null || challengesJson is! String || challengesJson.isEmpty) {
        debugPrint('🔧 Initializing default challenges...');
        try {
          final defaultChallenges = _getDefaultChallenges();
          final encodedChallenges = jsonEncode(defaultChallenges);
          await box.put(_defaultChallengesKey, encodedChallenges);
          debugPrint('✅ Default challenges initialized successfully');
          
          // Verify the data was stored correctly
          final verifyData = box.get(_defaultChallengesKey);
          debugPrint('🔍 Verification - stored data type: ${verifyData.runtimeType}');
        } catch (e) {
          debugPrint('🔥 Error initializing default challenges: $e');
        }
      } else {
        debugPrint('✅ Default challenges already exist in Hive');
      }
      
      debugPrint('✅ GamificationService initialization complete');
    } catch (e) {
      debugPrint('🔥 Error during GamificationService initialization: $e');
      debugPrint('🔧 Stack trace: ${StackTrace.current}');
      // Don't rethrow - we want the app to continue even if gamification fails
    }
    // Note: Legacy default profile creation is removed from here.
    // GamificationProfile will be created on-demand via getProfile() if needed.
  }
  
  Future<GamificationProfile> getProfile() async {
    final currentUserProfile = await _storageService.getCurrentUserProfile();

    if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
      debugPrint('⚠️ GamificationService: No authenticated user profile found. Falling back to legacy local profile (if any).');
      // Fallback for guest or unauthenticated state (reads from old Hive key)
      // This part might need further refinement based on how guests are handled.
      final box = Hive.box(_gamificationBoxName);
      final legacyProfileJson = box.get(_legacyProfileKey);
      if (legacyProfileJson != null) {
        try {
          return GamificationProfile.fromJson(jsonDecode(legacyProfileJson));
        } catch (e) {
          debugPrint('🔥 Error decoding legacy gamification profile: $e. Creating a temporary guest profile.');
        }
      }
      // Return a very basic, non-savable guest profile if no legacy one
      return GamificationProfile(
        userId: 'guest_user_${DateTime.now().millisecondsSinceEpoch}',
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 0,
            longestCount: 0,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(),
        achievements: getDefaultAchievements(), // Provide default achievements
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      );
    }

    if (currentUserProfile.gamificationProfile != null) {
      debugPrint('✅ GamificationService: Found existing gamification profile for user ${currentUserProfile.id}');
      return currentUserProfile.gamificationProfile!;
    } else {
      // Logged-in user, but no gamification profile exists yet. Create one.
      debugPrint('✨ GamificationService: No gamification profile found for user ${currentUserProfile.id}. Creating a new one.');
      
      // Load default challenges safely
      var activeChallenges = <Challenge>[];
      try {
        activeChallenges = await _loadDefaultChallengesFromHive();
        debugPrint('🎯 Loaded ${activeChallenges.length} active challenges for new profile');
      } catch (e) {
        debugPrint('🔥 Failed to load challenges for new profile: $e');
        debugPrint('🔧 Creating profile without active challenges');
        // Continue with empty challenges list
      }
      
      final newGamificationProfile = GamificationProfile(
        userId: currentUserProfile.id, // Crucial: Use the actual user ID
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 0,
            longestCount: 0,
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
        debugPrint('💾 New gamification profile saved successfully');
        debugPrint('📊 Profile initialized with ${newGamificationProfile.achievements.length} achievements and ${newGamificationProfile.activeChallenges.length} challenges');
      } catch (e) {
        debugPrint('🔥 Failed to save new gamification profile: $e');
        // Return the profile anyway, even if saving failed
      }
      
      return newGamificationProfile;
    }
  }
  
  Future<List<Challenge>> _loadDefaultChallengesFromHive() async {
    try {
      debugPrint('🔧 Loading default challenges from Hive...');
      final box = Hive.box(_gamificationBoxName);
      final challengesJson = box.get(_defaultChallengesKey);
      
      debugPrint('🔧 Retrieved challenges data: $challengesJson (type: ${challengesJson.runtimeType})');
      
      if (challengesJson != null && challengesJson is String && challengesJson.isNotEmpty) {
        try {
          debugPrint('🔧 Attempting to decode JSON...');
          final List<dynamic> decoded = jsonDecode(challengesJson);
          debugPrint('🔧 JSON decoded successfully, creating Challenge objects...');
          final challenges = decoded.map((data) => Challenge.fromJson(Map<String, dynamic>.from(data))).toList();
          debugPrint('✅ Successfully loaded ${challenges.length} challenges from Hive');
          return challenges;
        } catch (decodeError) {
          debugPrint('🔥 Error decoding challenges JSON: $decodeError');
          debugPrint('🔧 Reinitializing challenges with fresh data...');
          await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
          debugPrint('✅ Challenges reinitialized');
        }
      } else {
        debugPrint('🔧 Challenges not found or invalid in Hive (${challengesJson?.runtimeType}), initializing...');
        // Initialize challenges if they don't exist or are invalid
        try {
          await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
          debugPrint('✅ Challenges initialized successfully');
        } catch (putError) {
          debugPrint('🔥 Error putting challenges to Hive: $putError');
        }
      }
    } catch (e) {
      debugPrint('🔥 Error in _loadDefaultChallengesFromHive: $e');
      debugPrint('🔧 Stack trace: ${StackTrace.current}');
    }
    
    // Always return a fallback list using the fresh challenge templates
    debugPrint('🔧 Returning fallback challenge list...');
    try {
      final fallbackChallenges = _getDefaultChallenges().map((c) => Challenge.fromJson(c)).toList();
      debugPrint('✅ Created ${fallbackChallenges.length} fallback challenges');
      return fallbackChallenges;
    } catch (fallbackError) {
      debugPrint('🔥 Error creating fallback challenges: $fallbackError');
      // Return empty list as absolute last resort
      return [];
    }
  }

  Future<void> saveProfile(GamificationProfile gamificationProfileToSave) async {
    final currentUserProfile = await _storageService.getCurrentUserProfile();

    if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
      debugPrint('🚫 GamificationService: No authenticated user profile found. Saving to legacy Hive for guest session.');
      // Save to legacy Hive for guest state
      final box = Hive.box(_gamificationBoxName);
      await box.put(_legacyProfileKey, jsonEncode(gamificationProfileToSave.toJson()));
      debugPrint('✅ Saved gamification profile to legacy local storage for guest session.');
      return;
    }

    // Ensure the gamification profile's user ID matches the current user's ID
    if (gamificationProfileToSave.userId != currentUserProfile.id) {
      debugPrint('⚠️ GamificationService: Mismatched user IDs. GP UserID: ${gamificationProfileToSave.userId} vs UserProfile ID: ${currentUserProfile.id}. Correcting GP userId.');
      gamificationProfileToSave = gamificationProfileToSave.copyWith(userId: currentUserProfile.id);
    }
    
    final updatedUserProfile = currentUserProfile.copyWith(
      gamificationProfile: gamificationProfileToSave,
      lastActive: DateTime.now(), // Also update lastActive timestamp on the main profile
    );

    try {
      await _storageService.saveUserProfile(updatedUserProfile);
      debugPrint('💾 GamificationService: UserProfile with updated gamification data saved locally.');
      debugPrint('📊 Updated profile - Points: ${gamificationProfileToSave.points.total}, Level: ${gamificationProfileToSave.points.level}, Achievements: ${gamificationProfileToSave.achievements.where((a) => a.isEarned).length}/${gamificationProfileToSave.achievements.length}');

      await _cloudStorageService.saveUserProfileToFirestore(updatedUserProfile);
      debugPrint('☁️ GamificationService: UserProfile with updated gamification data synced to Firestore (triggers leaderboard update).');
    } catch (e) {
      debugPrint('🔥 GamificationService: Error saving user profile (local or cloud): $e');
      debugPrint('🔧 Stack trace: ${StackTrace.current}');
      // Decide on error handling strategy. For now, just logging.
      rethrow;
    }
  }
  
  // Update streak when the app is used
  Future<Streak> updateStreak() async {
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
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastUsageDay = DateTime(lastUsage.year, lastUsage.month, lastUsage.day);
    
    debugPrint('🔥 STREAK DEBUG:');
    debugPrint('  - Today: $today');
    debugPrint('  - Yesterday: $yesterday');
    debugPrint('  - Last usage day: $lastUsageDay');
    debugPrint('  - Current streak: ${currentStreak.currentCount}');
    
    var newCurrent = currentStreak.currentCount;
    var shouldSave = false;
    
    if (lastUsageDay.isAtSameMomentAs(today)) {
      // Already used today, keep current streak (but ensure it's at least 1)
      if (currentStreak.currentCount == 0) {
        newCurrent = 1;
        shouldSave = true;
        debugPrint('  - First use today, setting streak to 1');
      } else {
        debugPrint('  - Already used today, keeping streak: ${currentStreak.currentCount}');
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
      debugPrint('  - Used yesterday, incrementing streak to: $newCurrent');
    } else {
      // Last used before yesterday or never, start new streak
      newCurrent = 1;
      shouldSave = true;
      debugPrint('  - Starting new streak: $newCurrent');
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
    
    debugPrint('  - New streak saved: current=$newCurrent, longest=$newLongest');
    
    // Award points for streak (only if streak increased)
    if (newCurrent > currentStreak.currentCount) {
      await addPoints('daily_streak');
      debugPrint('  - Awarded daily streak points');
      
      // Record streak activity in community feed
      try {
        final communityService = CommunityService();
        await communityService.initCommunity();
        await communityService.recordStreak(newCurrent, 5); // 5 points for daily streak
        debugPrint('🌍 COMMUNITY: Recorded streak activity');
      } catch (e) {
        debugPrint('🌍 COMMUNITY ERROR: Failed to record streak: $e');
      }
    }
    
    // Check for streak achievements
    if (newCurrent >= 3) {
      await updateAchievementProgress(AchievementType.streakMaintained, newCurrent);
      debugPrint('  - Updated streak achievements for $newCurrent days');
    }
    
    // Check for perfect week
    if (newCurrent % 7 == 0 && newCurrent > 0) {
      await updateAchievementProgress(AchievementType.perfectWeek, newCurrent ~/ 7);
      await addPoints('perfect_week');
      debugPrint('  - Perfect week achieved! ${newCurrent ~/ 7} weeks');
    }
    
    // Return legacy Streak format for compatibility
    return Streak(
      current: newCurrent,
      longest: newLongest,
      lastUsageDate: now,
    );
  }
  
  // Add points for an action
  Future<UserPoints> addPoints(String action, {String? category, int? customPoints}) async {
    debugPrint('🎮 [DEBUG] addPoints called: action=$action, category=$category, customPoints=$customPoints');
    final points = await _addPointsInternal(action, category: category, customPoints: customPoints);
    debugPrint('🎮 [DEBUG] Points after add: total=${points.total}, categoryPoints=${points.categoryPoints}');
    return points;
  }
  
  Future<UserPoints> _addPointsInternal(String action, {String? category, int? customPoints}) async {
    final profile = await getProfile();
    final points = profile.points;
    
    final pointsToAdd = customPoints ?? _pointValues[action] ?? 0;
    if (pointsToAdd == 0 && customPoints == null) {
       debugPrint("⚠️ GamificationService: Attempted to add 0 points for action '$action' and no custom points provided.");
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
    
    // Update weekly stats (if this logic is still separate)
    await _updateWeeklyStats(action, category, pointsToAdd);
    
    debugPrint('✨ Points added: $pointsToAdd for $action. New total: $newTotal. Level: $newLevel');
    return newPoints;
  }
  
  // Process a waste classification for gamification
  // Returns a list of completed challenges
  Future<List<Challenge>> processClassification(WasteClassification classification) async {
    debugPrint('🎮 [DEBUG] processClassification called for: \\${classification.itemName}');
    await addPoints('classification', category: classification.category);
    debugPrint('🎮 [DEBUG] processClassification complete');
    
    // Get profile before making changes
    final profileBefore = await getProfile();
    final categoriesBeforeCount = profileBefore.points.categoryPoints.keys.length;
    
    // Update waste identification achievements
    await updateAchievementProgress(AchievementType.wasteIdentified, 1);
    
    // Get updated profile to check categories
    final profileAfter = await getProfile();
    final categoriesAfterCount = profileAfter.points.categoryPoints.keys.length;
    
    debugPrint('🎮 CATEGORIES: Before=$categoriesBeforeCount, After=$categoriesAfterCount');
    debugPrint('🎮 CATEGORIES: ${profileAfter.points.categoryPoints.keys.toList()}');
    
    // Check if this is a new category
    if (categoriesAfterCount > categoriesBeforeCount) {
      // This is a new category! Update categories achievement
      debugPrint('🎮 NEW CATEGORY DETECTED! Updating categoriesIdentified achievement');
      await updateAchievementProgress(
        AchievementType.categoriesIdentified, 
        categoriesAfterCount
      );
    } else {
      debugPrint('🎮 EXISTING CATEGORY: ${classification.category}');
    }
    
    // Update active challenges
    final completedChallenges = await updateChallengeProgress(classification);
    
    // Record classification activity in community feed
    try {
      final communityService = CommunityService();
      await communityService.initCommunity();
      await communityService.recordClassification(
        classification.category,
        classification.subcategory ?? '',
        10, // Points earned for classification
      );
      debugPrint('🌍 COMMUNITY: Recorded classification activity');
    } catch (e) {
      debugPrint('🌍 COMMUNITY ERROR: Failed to record classification: $e');
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
          debugPrint('🏆 CATEGORY ACHIEVEMENT: ${achievement.id} - progress: $increment/${achievement.threshold} = ${(newProgress * 100).round()}%');
        } else {
          // For other achievements, use incremental progress
          final currentProgress = achievement.progress * achievement.threshold;
          final newRawProgress = currentProgress + increment;
          newProgress = newRawProgress / achievement.threshold;
          debugPrint('🏆 ACHIEVEMENT: ${achievement.id} - progress: $newRawProgress/${achievement.threshold} = ${(newProgress * 100).round()}%');
        }
        
        // Check if achievement is now earned (requires both progress AND level unlock)
        final isLevelUnlocked = achievement.unlocksAtLevel == null || profile.points.level >= achievement.unlocksAtLevel!;
        
        // DEBUGGING: Log achievement progress for "Waste Apprentice"
        if (achievement.id == 'waste_apprentice') {
          debugPrint('🔍 ACHIEVEMENT DEBUG - Waste Apprentice:');
          debugPrint('  - Current progress: ${(achievement.progress * 100).round()}%');
          debugPrint('  - New progress: ${(newProgress * 100).round()}%');
          debugPrint('  - User level: ${profile.points.level}');
          debugPrint('  - Unlocks at level: ${achievement.unlocksAtLevel}');
          debugPrint('  - Is level unlocked: $isLevelUnlocked');
          debugPrint('  - Is earned: ${achievement.isEarned}');
          debugPrint('  - Progress >= 1.0: ${newProgress >= 1.0}');
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
            await communityService.recordAchievement(
              achievement.title,
              achievement.pointsReward,
            );
            debugPrint('🌍 COMMUNITY: Recorded achievement activity');
          } catch (e) {
            debugPrint('🌍 COMMUNITY ERROR: Failed to record achievement: $e');
          }
          
          // For auto-claimed achievements, points are already added above
          if (claimStatus == ClaimStatus.claimed) {
            // Just award the standard badge_earned points (no custom points)
            await addPoints('badge_earned');
          }
          
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
    
    // Save updated stats
    await box.put(_weeklyStatsKey, jsonEncode(limitedStats.map((s) => s.toJson()).toList()));
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
        color: Color(templateData['color'] ?? AppTheme.secondaryColor.value),
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
        'color': AppTheme.dryWasteColor.value,
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
        'color': AppTheme.wetWasteColor.value,
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
        'color': AppTheme.dryWasteColor.value,
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
        'color': AppTheme.wetWasteColor.value,
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
        'color': AppTheme.hazardousWasteColor.value,
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
        'color': AppTheme.medicalWasteColor.value,
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
        'color': AppTheme.nonWasteColor.value,
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
        'color': AppTheme.dryWasteColor.value,
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
        'color': AppTheme.dryWasteColor.value,
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
        'color': AppTheme.dryWasteColor.value,
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
        'color': AppTheme.hazardousWasteColor.value,
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
        'color': Colors.amber.value,
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
            currentCount: 0,
            longestCount: 0,
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
      
      debugPrint('✅ Gamification data cleared and reset successfully with points archived');
    } catch (e) {
      debugPrint('❌ Error clearing gamification data: $e');
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
      
      debugPrint('📦 Archived ${points.total} points from previous session');
    } catch (e) {
      debugPrint('❌ Error archiving points: $e');
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
          debugPrint('Error parsing archived points: $e');
        }
      }
      
      return totalLifetime;
    } catch (e) {
      debugPrint('Error calculating lifetime points: $e');
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
          debugPrint('Error parsing archived entry: $e');
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
      debugPrint('Error getting archived points history: $e');
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
        debugPrint('🔄 Streak reset to yesterday for testing');
      }
    } catch (e) {
      debugPrint('❌ Error resetting streak: $e');
    }
  }

  /// Force refresh gamification profile from storage
  Future<GamificationProfile> forceRefreshProfile() async {
    try {
      debugPrint('🔄 Force refreshing gamification profile...');
      
      // Clear any cached data and reload from storage
      final currentUserProfile = await _storageService.getCurrentUserProfile();
      
      if (currentUserProfile == null || currentUserProfile.id.isEmpty) {
        debugPrint('⚠️ No user profile found during force refresh');
        return await getProfile(); // Fallback to regular getProfile
      }
      
      // Reload user profile from storage to get latest data
      try {
        final refreshedProfile = await _storageService.getCurrentUserProfile();
        if (refreshedProfile != null && refreshedProfile.gamificationProfile != null) {
          debugPrint('💾 Loaded refreshed gamification profile from local storage');
          return refreshedProfile.gamificationProfile!;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to refresh from local storage: $e');
      }
      
      // Fallback to creating new profile if none exists
      debugPrint('🆕 Creating new gamification profile during force refresh');
      return await getProfile();
      
    } catch (e) {
      debugPrint('🔥 Error during force refresh: $e');
      return getProfile(); // Fallback to regular getProfile
    }
  }

  /// Sync gamification data across all app components
  Future<void> syncGamificationData() async {
    try {
      debugPrint('🔄 Syncing gamification data across app components...');
      
      // Force refresh profile
      final profile = await forceRefreshProfile();
      
      // Update streak for today if needed
      await updateStreak();
      
      // Ensure achievements are properly initialized
      if (profile.achievements.isEmpty) {
        debugPrint('🏆 Initializing default achievements');
        final updatedProfile = profile.copyWith(achievements: getDefaultAchievements());
        await saveProfile(updatedProfile);
      }
      
      // Ensure challenges are loaded
      if (profile.activeChallenges.isEmpty) {
        debugPrint('🎯 Loading default challenges');
        final challenges = await _loadDefaultChallengesFromHive();
        if (challenges.isNotEmpty) {
          final updatedProfile = profile.copyWith(activeChallenges: challenges);
          await saveProfile(updatedProfile);
        }
      }
      
      debugPrint('✅ Gamification data sync completed');
      
    } catch (e) {
      debugPrint('🔥 Error syncing gamification data: $e');
    }
  }
}