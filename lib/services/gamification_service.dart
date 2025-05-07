import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/gamification.dart';
import '../models/waste_classification.dart';
import '../models/educational_content.dart';
import '../utils/constants.dart';

/// Service for managing gamification features
class GamificationService {
  static const String _gamificationBox = 'gamificationBox';
  static const String _profileKey = 'userGamificationProfile';
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
  };
  
  // Initialize Hive box
  Future<void> initGamification() async {
    await Hive.openBox(_gamificationBox);
    
    // Create default profile if it doesn't exist
    final box = Hive.box(_gamificationBox);
    final profileJson = box.get(_profileKey);
    
    if (profileJson == null) {
      final defaultProfile = GamificationProfile(
        userId: 'default',
        streak: Streak(lastUsageDate: DateTime.now()),
        points: const UserPoints(),
        achievements: _getDefaultAchievements(),
      );
      
      await box.put(_profileKey, jsonEncode(defaultProfile.toJson()));
    }
    
    // Create default challenges if they don't exist
    final challengesJson = box.get(_defaultChallengesKey);
    if (challengesJson == null) {
      await box.put(_defaultChallengesKey, jsonEncode(_getDefaultChallenges()));
    }
  }
  
  // Get the user's gamification profile
  Future<GamificationProfile> getProfile() async {
    final box = Hive.box(_gamificationBox);
    final profileJson = box.get(_profileKey);
    
    if (profileJson == null) {
      // Create a new profile if none exists
      final newProfile = GamificationProfile(
        userId: 'default',
        streak: Streak(lastUsageDate: DateTime.now()),
        points: const UserPoints(),
        achievements: _getDefaultAchievements(),
      );
      
      await box.put(_profileKey, jsonEncode(newProfile.toJson()));
      return newProfile;
    }
    
    return GamificationProfile.fromJson(jsonDecode(profileJson));
  }
  
  // Save the user's gamification profile
  Future<void> saveProfile(GamificationProfile profile) async {
    final box = Hive.box(_gamificationBox);
    await box.put(_profileKey, jsonEncode(profile.toJson()));
  }
  
  // Update streak when the app is used
  Future<Streak> updateStreak() async {
    final profile = await getProfile();
    final now = DateTime.now();
    final lastUsage = profile.streak.lastUsageDate;
    
    // Check if last usage was yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastUsageDay = DateTime(lastUsage.year, lastUsage.month, lastUsage.day);
    
    // If last usage was yesterday, increment streak
    // If it was today, keep streak the same
    // If it was before yesterday, reset streak to 1
    int newCurrent = profile.streak.current;
    
    if (lastUsageDay.isAtSameMomentAs(yesterday)) {
      // Increment streak if last usage was yesterday
      newCurrent = profile.streak.current + 1;
    } else if (!lastUsageDay.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
      // Reset streak if last usage was before yesterday
      newCurrent = 1;
    }
    
    // Update longest streak if needed
    final newLongest = newCurrent > profile.streak.longest 
        ? newCurrent 
        : profile.streak.longest;
    
    final newStreak = Streak(
      current: newCurrent,
      longest: newLongest,
      lastUsageDate: now,
    );
    
    // Update the profile with the new streak
    await saveProfile(profile.copyWith(streak: newStreak));
    
    // Award points for streak
    if (newCurrent > 1) {
      await addPoints('daily_streak');
    }
    
    // Check for streak achievements
    if (newCurrent >= 7) {
      await updateAchievementProgress(AchievementType.streakMaintained, newCurrent);
    }
    
    // Check for perfect week
    if (newCurrent % 7 == 0) {
      await updateAchievementProgress(AchievementType.perfectWeek, newCurrent ~/ 7);
      await addPoints('perfect_week');
    }
    
    return newStreak;
  }
  
  // Add points for an action
  Future<UserPoints> addPoints(String action, {String? category, int? customPoints}) async {
    final profile = await getProfile();
    final points = profile.points;
    
    // Get point value for the action, or use custom points if provided
    final pointsToAdd = customPoints ?? _pointValues[action] ?? 0;
    
    // Calculate new totals
    final newTotal = points.total + pointsToAdd;
    final newWeekly = points.weeklyTotal + pointsToAdd;
    final newMonthly = points.monthlyTotal + pointsToAdd;
    
    // Calculate new level (every 100 points = 1 level)
    final newLevel = (newTotal / 100).floor() + 1;
    
    // Update category points if category is provided
    final newCategoryPoints = Map<String, int>.from(points.categoryPoints);
    if (category != null) {
      newCategoryPoints[category] = (newCategoryPoints[category] ?? 0) + pointsToAdd;
    }
    
    final newPoints = UserPoints(
      total: newTotal,
      weeklyTotal: newWeekly,
      monthlyTotal: newMonthly,
      level: newLevel,
      categoryPoints: newCategoryPoints,
    );
    
    // Update the profile with the new points
    await saveProfile(profile.copyWith(points: newPoints));
    
    // Update weekly stats
    await _updateWeeklyStats(action, category, pointsToAdd);
    
    return newPoints;
  }
  
  // Process a waste classification for gamification
  Future<void> processClassification(WasteClassification classification) async {
    // Add points for classifying an item
    await addPoints('classification', category: classification.category);
    
    // Update waste identification achievements
    await updateAchievementProgress(AchievementType.wasteIdentified, 1);
    
    // Track unique categories identified
    final profile = await getProfile();
    final categoriesIdentified = profile.points.categoryPoints.keys.toList();
    
    if (!categoriesIdentified.contains(classification.category)) {
      // Update categories achievement if this is a new category
      await updateAchievementProgress(
        AchievementType.categoriesIdentified, 
        categoriesIdentified.length + 1
      );
    }
    
    // Update active challenges
    await updateChallengeProgress(classification);
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
    for (int i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      
      // Skip if achievement is already earned or is locked by level
      if (achievement.type == type && 
          !achievement.isEarned && 
          (!achievement.isLocked || profile.points.level >= achievement.unlocksAtLevel!)) {
        
        // Calculate new progress
        final currentProgress = achievement.progress * achievement.threshold;
        final newRawProgress = currentProgress + increment;
        final newProgress = newRawProgress / achievement.threshold;
        
        // Check if achievement is now earned
        if (newProgress >= 1.0) {
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
          
          // For auto-claimed achievements, points are already added above
          if (claimStatus == ClaimStatus.claimed) {
            // Just award the standard badge_earned points (no custom points)
            await addPoints('badge_earned');
          }
          
          // Check for meta-achievements (achievements for earning other achievements)
          await _checkMetaAchievements(achievements);
          
        } else {
          // Update progress
          achievements[i] = achievement.copyWith(
            progress: newProgress,
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
    for (int i = 0; i < achievements.length; i++) {
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
    final now = DateTime.now();
    List<Challenge> active = profile.activeChallenges
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
    
    for (int i = 0; i < activeChallenges.length; i++) {
      final challenge = activeChallenges[i];
      
      if (!challenge.isExpired && !challenge.isCompleted) {
        // Check if this classification helps with the challenge
        final reqs = challenge.requirements;
        
        bool updated = false;
        double newProgress = challenge.progress;
        
        // Handle different challenge types
        if (reqs.containsKey('category') && 
            reqs['category'] == classification.category) {
          // Category-specific challenge
          final int count = reqs['count'] ?? 1;
          final int current = (challenge.progress * count).round();
          final newValue = current + 1;
          newProgress = newValue / count;
          updated = true;
        } else if (reqs.containsKey('subcategory') && 
                  classification.subcategory == reqs['subcategory']) {
          // Subcategory-specific challenge
          final int count = reqs['count'] ?? 1;
          final int current = (challenge.progress * count).round();
          final newValue = current + 1;
          newProgress = newValue / count;
          updated = true;
        } else if (reqs.containsKey('any_item') && reqs['any_item'] == true) {
          // Any item identified challenge
          final int count = reqs['count'] ?? 1;
          final int current = (challenge.progress * count).round();
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
    final box = Hive.box(_gamificationBox);
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
    final box = Hive.box(_gamificationBox);
    final now = DateTime.now();
    
    // Get the start of the current week (Sunday)
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    // Get existing stats
    final List<WeeklyStats> allStats = await getWeeklyStats();
    
    // Find or create current week's stats
    WeeklyStats currentWeekStats;
    int currentWeekIndex = allStats.indexWhere(
      (stats) => stats.weekStartDate.isAtSameMomentAs(weekStartDate)
    );
    
    if (currentWeekIndex >= 0) {
      currentWeekStats = allStats[currentWeekIndex];
    } else {
      currentWeekStats = WeeklyStats(weekStartDate: weekStartDate);
      currentWeekIndex = -1;
    }
    
    // Update stats based on action
    int newItemsIdentified = currentWeekStats.itemsIdentified;
    int newChallengesCompleted = currentWeekStats.challengesCompleted;
    int newPointsEarned = currentWeekStats.pointsEarned + pointsEarned;
    Map<String, int> newCategoryCounts = Map<String, int>.from(currentWeekStats.categoryCounts);
    
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
    final streakValue = profile.streak.current;
    
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
    final box = Hive.box(_gamificationBox);
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
      final Challenge challenge = Challenge(
        id: 'challenge_${now.millisecondsSinceEpoch}_${challenges.length}',
        title: templateData['title'],
        description: templateData['description'],
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        pointsReward: templateData['pointsReward'] ?? 25,
        iconName: templateData['iconName'] ?? 'task_alt',
        color: Color(templateData['color'] ?? AppTheme.accentColor.value),
        requirements: templateData['requirements'] ?? {'any_item': true, 'count': 5},
        isCompleted: false,
        progress: 0.0,
      );
      
      challenges.add(challenge);
    }
    
    return challenges;
  }
  
  // Generate default achievement templates
  List<Achievement> _getDefaultAchievements() {
    return [
      // Waste identification achievements - TIERED FAMILY
      Achievement(
        id: 'waste_novice',
        title: 'Waste Novice',
        description: 'Identify your first 5 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 5,
        iconName: 'emoji_objects',
        color: AppTheme.primaryColor,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 50,
      ),
      Achievement(
        id: 'waste_apprentice',
        title: 'Waste Apprentice',
        description: 'Identify 25 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 25,
        iconName: 'recycling',
        color: AppTheme.primaryColor,
        tier: AchievementTier.silver,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 100,
        unlocksAtLevel: 2,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Identify items from 3 different waste categories',
        type: AchievementType.categoriesIdentified,
        threshold: 3,
        iconName: 'category',
        color: AppTheme.secondaryColor,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Category Expert',
        pointsReward: 75,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'streak_starter',
        title: 'Streak Starter',
        description: 'Use the app for 3 days in a row',
        type: AchievementType.streakMaintained,
        threshold: 3,
        iconName: 'local_fire_department',
        color: Colors.orange,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Streak Maintainer',
        pointsReward: 50,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: 'Use the app every day for a full week',
        type: AchievementType.perfectWeek,
        threshold: 1,
        iconName: 'event_available',
        color: Colors.teal,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Perfect Record',
        pointsReward: 75,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'challenge_taker',
        title: 'Challenge Taker',
        description: 'Complete your first challenge',
        type: AchievementType.challengesCompleted,
        threshold: 1,
        iconName: 'emoji_events',
        color: Colors.amber,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Challenge Conqueror',
        pointsReward: 50,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'knowledge_seeker',
        title: 'Knowledge Seeker',
        description: 'View 5 educational content items',
        type: AchievementType.knowledgeMaster,
        threshold: 5,
        iconName: 'school',
        color: Colors.purple,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Knowledge Explorer',
        pointsReward: 50,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
        id: 'quiz_taker',
        title: 'Quiz Taker',
        description: 'Complete your first quiz',
        type: AchievementType.quizCompleted,
        threshold: 1,
        iconName: 'quiz',
        color: Colors.indigo,
        tier: AchievementTier.bronze,
        achievementFamilyId: 'Quiz Champion',
        pointsReward: 50,
      ),
      Achievement(
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
      Achievement(
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
      Achievement(
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
      Achievement(
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
}