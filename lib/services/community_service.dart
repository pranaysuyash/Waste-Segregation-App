import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/community_feed.dart';
import '../models/waste_classification.dart';
import '../models/user_profile.dart';
import '../models/gamification.dart';

/// Service for managing community feed and social features
class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _feedCollection = 'community_feed';
  static const String _statsCollection = 'community_stats';
  static const String _mainStatsDoc = 'main';

  // Initialize with Firestore
  Future<void> initCommunity() async {
    // No more Hive initialization needed
    // The stats document will be created on-the-fly if it doesn't exist
    debugPrint('CommunityService initialized with Firestore.');
  }

  // Add a feed item to Firestore
  Future<void> addFeedItem(CommunityFeedItem item) async {
    try {
      await _firestore.collection(_feedCollection).add(item.toJson());
      await _updateCommunityStatsOnActivity(item);
      debugPrint('🌍 Firestore: Community feed item added: ${item.title}');
    } catch (e) {
      debugPrint('❌ Error adding Firestore feed item: $e');
    }
  }

  // Get feed items from Firestore
  Future<List<CommunityFeedItem>> getFeedItems({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_feedCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityFeedItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting Firestore feed: $e');
      return [];
    }
  }

  // Get stats calculated from actual feed data (more accurate than incremental stats)
  Future<CommunityStats> getStats() async {
    try {
      // Get all feed items to calculate accurate stats
      final feedItems = await getFeedItems(limit: 10000); // Get a large number to ensure we get all
      
      // Calculate stats from actual feed data
      var totalClassifications = 0;
      var totalPoints = 0;
      final categoryBreakdown = <String, int>{};
      final userIds = <String>{};
      
      for (final item in feedItems) {
        userIds.add(item.userId);
        totalPoints += item.points;
        
        if (item.activityType == CommunityActivityType.classification) {
          totalClassifications++;
          final category = item.metadata['category'] as String?;
          if (category != null) {
            categoryBreakdown.update(category, (value) => value + 1, ifAbsent: () => 1);
          }
        }
      }
      
      return CommunityStats(
        totalUsers: userIds.length,
        totalClassifications: totalClassifications,
        totalPoints: totalPoints,
        categoryBreakdown: categoryBreakdown,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error calculating community stats: $e');
      return const CommunityStats(totalUsers: 0, totalClassifications: 0, totalPoints: 0);
    }
  }
  
  // Transactionally update stats
  Future<void> _updateCommunityStatsOnActivity(CommunityFeedItem item) async {
    final statsRef = _firestore.collection(_statsCollection).doc(_mainStatsDoc);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);
      
      if (!snapshot.exists) {
        transaction.set(statsRef, {
          'totalClassifications': item.activityType == CommunityActivityType.classification ? 1 : 0,
          'totalPoints': item.points,
          'categoryBreakdown': {
            if (item.metadata['category'] != null) item.metadata['category']: 1
          },
          'lastUpdated': FieldValue.serverTimestamp(),
          'totalUsers': 1,
        });
      } else {
        final classificationIncrement = item.activityType == CommunityActivityType.classification ? 1 : 0;
        final categoryKey = item.metadata['category'] as String?;

        transaction.update(statsRef, {
          'totalClassifications': FieldValue.increment(classificationIncrement),
          'totalPoints': FieldValue.increment(item.points),
          if (categoryKey != null) 'categoryBreakdown.$categoryKey': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Record classification - now writes to Firestore
  Future<void> recordClassification(WasteClassification classification, UserProfile user) async {
    // Use consistent points from PointsEngine standard (10 per classification)
    const standardClassificationPoints = 10;
    
    final item = CommunityFeedItem(
      id: classification.id,
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.classification,
      title: 'New Scan!',
      description: 'Scanned a ${classification.itemName} (${classification.category})',
      timestamp: classification.timestamp,
      points: classification.pointsAwarded ?? standardClassificationPoints,
      metadata: {'category': classification.category},
    );
    await addFeedItem(item);
  }

  // Record achievement - now writes to Firestore
  Future<void> recordAchievement(Achievement achievement, UserProfile user) async {
    final item = CommunityFeedItem(
      id: 'ach_${user.id}_${achievement.id}',
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.achievement,
      title: 'Achievement Unlocked!',
      description: 'Unlocked "${achievement.title}"',
      timestamp: DateTime.now(),
      points: achievement.pointsReward,
      metadata: {'achievementId': achievement.id},
    );
    await addFeedItem(item);
  }

  // Record a streak event - now writes to Firestore
  Future<void> recordStreak(int streakDays, UserProfile user) async {
    final item = CommunityFeedItem(
      id: 'str_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.streak,
      title: 'Kept the fire going!',
      description: 'Maintained a $streakDays-day streak!',
      timestamp: DateTime.now(),
      points: 5, // Standard points for a streak
      metadata: {'streakDays': streakDays},
    );
    await addFeedItem(item);
  }

  // Sync user data to community feed - backfill historical data
  Future<void> syncWithUserData(
    List<WasteClassification> classifications,
    UserProfile? user,
  ) async {
    if (user == null) return;
    
    debugPrint('🔄 SYNC: Starting community feed sync for user ${user.id}');
    debugPrint('🔄 SYNC: Found ${classifications.length} classifications to potentially sync');
    
    try {
      // Get existing feed items to avoid duplicates
      final existingItems = await getFeedItems(limit: 1000);
      final existingClassificationIds = existingItems
          .where((item) => item.activityType == CommunityActivityType.classification)
          .map((item) => item.id)
          .toSet();
      
      debugPrint('🔄 SYNC: Found ${existingClassificationIds.length} existing classification feed items');
      
      // Backfill missing classifications
      var syncedCount = 0;
      for (final classification in classifications) {
        if (!existingClassificationIds.contains(classification.id)) {
          await recordClassification(classification, user);
          syncedCount++;
          
          // Add small delay to avoid overwhelming Firestore
          if (syncedCount % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      }
      
      debugPrint('🔄 SYNC: Backfilled $syncedCount classification activities to community feed');
      
      // Sync achievements if user has gamification profile
      if (user.gamificationProfile != null) {
        final achievements = user.gamificationProfile!.achievements;
        final unlockedAchievements = achievements.where((a) => a.isEarned).toList();
        
        final existingAchievementIds = existingItems
            .where((item) => item.activityType == CommunityActivityType.achievement)
            .map((item) => item.metadata['achievementId'] as String?)
            .where((id) => id != null)
            .toSet();
        
        var achievementsSynced = 0;
        for (final achievement in unlockedAchievements) {
          if (!existingAchievementIds.contains(achievement.id)) {
            await recordAchievement(achievement, user);
            achievementsSynced++;
          }
        }
        
        debugPrint('🔄 SYNC: Backfilled $achievementsSynced achievement activities to community feed');
      }
      
      debugPrint('✅ SYNC: Community feed sync completed successfully');
      
    } catch (e) {
      debugPrint('❌ SYNC ERROR: Failed to sync community feed: $e');
    }
  }
}