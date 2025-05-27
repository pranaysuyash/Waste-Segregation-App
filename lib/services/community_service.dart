import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/community_feed.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../utils/constants.dart';

/// Service for managing community feed and social features
class CommunityService {
  static const String _communityBox = 'communityBox';
  static const String _feedKey = 'communityFeed';
  static const String _statsKey = 'communityStats';
  static const String _userActivityKey = 'userActivity';
  
  // Initialize Hive box
  Future<void> initCommunity() async {
    await Hive.openBox(_communityBox);
    
    // Create initial stats if they don't exist
    final box = Hive.box(_communityBox);
    final statsJson = box.get(_statsKey);
    
    if (statsJson == null) {
      final initialStats = CommunityStats(
        totalUsers: 1, // Start with current user
        totalClassifications: 0,
        totalAchievements: 0,
        activeToday: 1,
        categoryBreakdown: {},
        lastUpdated: DateTime.now(),
      );
      
      await box.put(_statsKey, jsonEncode(initialStats.toJson()));
    }
  }
  
  /// Add a community feed item for user activity
  Future<void> addFeedItem(CommunityFeedItem item) async {
    try {
      final box = Hive.box(_communityBox);
      final feedJson = box.get(_feedKey, defaultValue: '[]');
      final List<dynamic> feedList = jsonDecode(feedJson);
      
      // Add new item to the beginning of the list
      feedList.insert(0, item.toJson());
      
      // Keep only the last 100 items to prevent storage bloat
      if (feedList.length > 100) {
        feedList.removeRange(100, feedList.length);
      }
      
      await box.put(_feedKey, jsonEncode(feedList));
      
      // Update community stats
      await _updateCommunityStats(item);
      
      debugPrint('🌍 Community feed item added: ${item.title}');
    } catch (e) {
      debugPrint('❌ Error adding community feed item: $e');
    }
  }
  
  /// Get community feed items
  Future<List<CommunityFeedItem>> getFeedItems({int limit = 20}) async {
    try {
      final box = Hive.box(_communityBox);
      final feedJson = box.get(_feedKey, defaultValue: '[]');
      final List<dynamic> feedList = jsonDecode(feedJson);
      
      final items = feedList
          .take(limit)
          .map((json) => CommunityFeedItem.fromJson(json))
          .toList();
      
      return items;
    } catch (e) {
      debugPrint('❌ Error getting community feed: $e');
      return [];
    }
  }
  
  /// Get community statistics
  Future<CommunityStats> getCommunityStats() async {
    try {
      final box = Hive.box(_communityBox);
      final statsJson = box.get(_statsKey);
      
      if (statsJson == null) {
        return CommunityStats(
          totalUsers: 1,
          totalClassifications: 0,
          totalAchievements: 0,
          activeToday: 1,
          categoryBreakdown: {},
          lastUpdated: DateTime.now(),
        );
      }
      
      return CommunityStats.fromJson(jsonDecode(statsJson));
    } catch (e) {
      debugPrint('❌ Error getting community stats: $e');
      return CommunityStats(
        totalUsers: 1,
        totalClassifications: 0,
        totalAchievements: 0,
        activeToday: 1,
        categoryBreakdown: {},
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Record user classification activity
  Future<void> recordClassification(WasteClassification classification, String userName) async {
    final feedItem = CommunityFeedItem(
      id: 'class_${DateTime.now().millisecondsSinceEpoch}',
      userId: classification.userId ?? 'unknown',
      userName: _sanitizeUserName(userName),
      activityType: CommunityActivityType.classification,
      title: 'Classified ${classification.category}',
      description: 'Identified ${classification.itemName} as ${classification.category}',
      timestamp: classification.timestamp,
      metadata: {
        'category': classification.category,
        'subcategory': classification.subcategory,
        'confidence': classification.confidence,
        'itemName': classification.itemName,
      },
      isAnonymous: _shouldBeAnonymous(classification.userId),
    );
    
    await addFeedItem(feedItem);
  }
  
  /// Record achievement earned
  Future<void> recordAchievement(Achievement achievement, String userName, String userId) async {
    final feedItem = CommunityFeedItem(
      id: 'achieve_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: _sanitizeUserName(userName),
      activityType: CommunityActivityType.achievement,
      title: 'Earned ${achievement.title}',
      description: achievement.description,
      timestamp: achievement.earnedOn ?? DateTime.now(),
      metadata: {
        'achievementId': achievement.id,
        'tier': achievement.tier.name,
        'pointsReward': achievement.pointsReward,
      },
      isAnonymous: _shouldBeAnonymous(userId),
    );
    
    await addFeedItem(feedItem);
  }
  
  /// Record streak milestone
  Future<void> recordStreakMilestone(int streakDays, String userName, String userId) async {
    if (streakDays < 3) return; // Only record significant streaks
    
    String title;
    if (streakDays == 3) {
      title = 'Started a 3-day streak! 🔥';
    } else if (streakDays == 7) {
      title = 'Achieved a week-long streak! 🔥🔥';
    } else if (streakDays == 30) {
      title = 'Incredible 30-day streak! 🔥🔥🔥';
    } else if (streakDays % 10 == 0) {
      title = 'Amazing ${streakDays}-day streak! 🔥';
    } else {
      return; // Don't record every single day
    }
    
    final feedItem = CommunityFeedItem(
      id: 'streak_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: _sanitizeUserName(userName),
      activityType: CommunityActivityType.streak,
      title: title,
      description: 'Maintained daily app usage for $streakDays consecutive days',
      timestamp: DateTime.now(),
      metadata: {
        'streakDays': streakDays,
      },
      isAnonymous: _shouldBeAnonymous(userId),
    );
    
    await addFeedItem(feedItem);
  }
  
  /// Record challenge completion
  Future<void> recordChallengeCompletion(Challenge challenge, String userName, String userId) async {
    final feedItem = CommunityFeedItem(
      id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: _sanitizeUserName(userName),
      activityType: CommunityActivityType.challenge,
      title: 'Completed "${challenge.title}"',
      description: challenge.description,
      timestamp: DateTime.now(),
      metadata: {
        'challengeId': challenge.id,
        'pointsReward': challenge.pointsReward,
      },
      isAnonymous: _shouldBeAnonymous(userId),
    );
    
    await addFeedItem(feedItem);
  }
  
  /// Generate sample community data to make the feed feel active
  Future<void> generateSampleCommunityData() async {
    final sampleUsers = [
      'EcoWarrior',
      'GreenThumb',
      'RecycleHero',
      'WasteWise',
      'EarthGuardian',
      'CleanLiving',
      'SustainableSoul',
      'ZeroWasteZen',
    ];
    
    final sampleActivities = [
      {
        'type': CommunityActivityType.classification,
        'titles': [
          'Classified Plastic Bottle',
          'Identified Food Waste',
          'Sorted Paper Waste',
          'Recognized Glass Container',
          'Categorized Metal Can',
        ],
        'descriptions': [
          'Correctly identified a plastic water bottle as recyclable',
          'Properly sorted organic food waste for composting',
          'Classified newspaper as recyclable paper',
          'Identified glass jar for proper recycling',
          'Sorted aluminum can for metal recycling',
        ],
      },
      {
        'type': CommunityActivityType.achievement,
        'titles': [
          'Earned Waste Novice',
          'Achieved Category Explorer',
          'Unlocked Streak Starter',
          'Completed Challenge Taker',
        ],
        'descriptions': [
          'Successfully identified first 5 waste items',
          'Explored 3 different waste categories',
          'Maintained 3-day usage streak',
          'Completed first community challenge',
        ],
      },
    ];
    
    final random = Random();
    final now = DateTime.now();
    
    // Generate 10-15 sample activities from the past week
    for (int i = 0; i < 12; i++) {
      final activityGroup = sampleActivities[random.nextInt(sampleActivities.length)];
      final titles = activityGroup['titles'] as List<String>;
      final descriptions = activityGroup['descriptions'] as List<String>;
      final type = activityGroup['type'] as CommunityActivityType;
      
      final titleIndex = random.nextInt(titles.length);
      
      final feedItem = CommunityFeedItem(
        id: 'sample_${now.millisecondsSinceEpoch}_$i',
        userId: 'sample_user_$i',
        userName: sampleUsers[random.nextInt(sampleUsers.length)],
        activityType: type,
        title: titles[titleIndex],
        description: descriptions[titleIndex],
        timestamp: now.subtract(Duration(
          hours: random.nextInt(168), // Random time in past week
          minutes: random.nextInt(60),
        )),
        metadata: {
          'isSample': true,
          'category': ['Plastic', 'Food Waste', 'Paper', 'Glass', 'Metal'][random.nextInt(5)],
        },
        isAnonymous: random.nextBool(),
      );
      
      await addFeedItem(feedItem);
    }
    
    debugPrint('🌍 Generated sample community data');
  }
  
  /// Update community statistics
  Future<void> _updateCommunityStats(CommunityFeedItem item) async {
    try {
      final currentStats = await getCommunityStats();
      final today = DateTime.now();
      final isToday = item.timestamp.day == today.day &&
                     item.timestamp.month == today.month &&
                     item.timestamp.year == today.year;
      
      // Update category breakdown if it's a classification
      final newCategoryBreakdown = Map<String, int>.from(currentStats.categoryBreakdown);
      if (item.activityType == CommunityActivityType.classification) {
        final category = item.metadata['category'] as String?;
        if (category != null) {
          newCategoryBreakdown[category] = (newCategoryBreakdown[category] ?? 0) + 1;
        }
      }
      
      final updatedStats = CommunityStats(
        totalUsers: currentStats.totalUsers,
        totalClassifications: item.activityType == CommunityActivityType.classification
            ? currentStats.totalClassifications + 1
            : currentStats.totalClassifications,
        totalAchievements: item.activityType == CommunityActivityType.achievement
            ? currentStats.totalAchievements + 1
            : currentStats.totalAchievements,
        activeToday: isToday ? currentStats.activeToday + 1 : currentStats.activeToday,
        categoryBreakdown: newCategoryBreakdown,
        lastUpdated: DateTime.now(),
      );
      
      final box = Hive.box(_communityBox);
      await box.put(_statsKey, jsonEncode(updatedStats.toJson()));
    } catch (e) {
      debugPrint('❌ Error updating community stats: $e');
    }
  }
  
  /// Sanitize user name for display
  String _sanitizeUserName(String userName) {
    if (userName.isEmpty) return 'User';
    
    // Remove email domain if it's an email
    if (userName.contains('@')) {
      return userName.split('@').first;
    }
    
    // Limit length
    if (userName.length > 20) {
      return userName.substring(0, 20);
    }
    
    return userName;
  }
  
  /// Determine if user should be anonymous (guest users)
  bool _shouldBeAnonymous(String? userId) {
    if (userId == null) return true;
    return userId.startsWith('guest_') || userId == 'guest_user';
  }
  
  /// Clear all community data
  Future<void> clearCommunityData() async {
    try {
      final box = Hive.box(_communityBox);
      await box.clear();
      debugPrint('✅ Community data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing community data: $e');
    }
  }
} 