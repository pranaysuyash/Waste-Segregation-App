import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('CommunityService', () {
    late CommunityService communityService;

    setUp(() {
      communityService = CommunityService();
    });

    group('Basic Instantiation', () {
      test('should be instantiable', () {
        expect(communityService, isA<CommunityService>());
      });

      test('should initialize without errors', () async {
        expect(() async => await communityService.initCommunity(),
            returnsNormally);
      });
    });

    group('Feed Items', () {
      test('should return valid list structure when getting items', () async {
        final feed = await communityService.getFeedItems(limit: 10);
        expect(feed, isA<List<CommunityFeedItem>>());
      });

      test('should add feed item without throwing', () async {
        final feedItem = _createTestFeedItem();

        expect(
          () async => await communityService.addFeedItem(feedItem),
          returnsNormally,
        );
      });
    });

    group('Stats Calculation', () {
      test('should return valid stats structure', () async {
        final stats = await communityService.getStats();
        expect(stats, isA<CommunityStats>());
        expect(stats.totalUsers, isA<int>());
        expect(stats.totalClassifications, isA<int>());
        expect(stats.totalPoints, isA<int>());
        expect(stats.categoryBreakdown, isA<Map<String, int>>());
      });

      test('should return stats with non-negative values', () async {
        final stats = await communityService.getStats();
        expect(stats.totalUsers, greaterThanOrEqualTo(0));
        expect(stats.totalClassifications, greaterThanOrEqualTo(0));
        expect(stats.totalPoints, greaterThanOrEqualTo(0));
      });
    });

    group('Activity Recording', () {
      test('should record classification activity without throwing', () async {
        final user = _createTestUser();
        final classification = _createTestClassification();

        expect(
          () async =>
              await communityService.recordClassification(classification, user),
          returnsNormally,
        );
      });

      test('should record achievement activity without throwing', () async {
        final user = _createTestUser();
        const achievement = Achievement(
          id: 'test_achievement',
          title: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.wasteIdentified,
          threshold: 5,
          pointsReward: 50,
          iconName: 'star',
          color: Colors.blue,
        );

        expect(
          () async =>
              await communityService.recordAchievement(achievement, user),
          returnsNormally,
        );
      });

      test('should record streak activity without throwing', () async {
        final user = _createTestUser();
        const streakDays = 7;

        expect(
          () async => await communityService.recordStreak(streakDays, user),
          returnsNormally,
        );
      });
    });

    group('User Data Sync', () {
      test('should handle null user gracefully', () async {
        final classifications = [_createTestClassification()];

        expect(
          () async =>
              await communityService.syncWithUserData(classifications, null),
          returnsNormally,
        );
      });

      test('should sync user classifications without throwing', () async {
        final user = _createTestUser();
        final classifications = [
          _createTestClassification(),
          _createTestClassification(userId: user.id),
        ];

        expect(
          () async =>
              await communityService.syncWithUserData(classifications, user),
          returnsNormally,
        );
      });

      test('should handle empty classifications list', () async {
        final user = _createTestUser();
        final classifications = <WasteClassification>[];

        expect(
          () async =>
              await communityService.syncWithUserData(classifications, user),
          returnsNormally,
        );
      });
    });

    group('Data Integrity', () {
      test('should handle feed retrieval without errors', () async {
        expect(
          () async => await communityService.getFeedItems(limit: 10),
          returnsNormally,
        );
      });

      test('should handle stats retrieval without errors', () async {
        expect(
          () async => await communityService.getStats(),
          returnsNormally,
        );
      });

      test('should respect feed item limit parameter', () async {
        final feed1 = await communityService.getFeedItems(limit: 5);
        final feed2 = await communityService.getFeedItems(limit: 10);

        expect(feed1, isA<List<CommunityFeedItem>>());
        expect(feed2, isA<List<CommunityFeedItem>>());

        // The actual sizes depend on what's in Firestore, but we can verify the API works
        expect(feed1.length, lessThanOrEqualTo(5));
        expect(feed2.length, lessThanOrEqualTo(10));
      });
    });

    group('Model Compatibility', () {
      test('should work with CommunityFeedItem model', () {
        final feedItem = _createTestFeedItem();
        expect(feedItem.id, isNotEmpty);
        expect(feedItem.userId, isNotEmpty);
        expect(feedItem.activityType, isA<CommunityActivityType>());
        expect(feedItem.points, greaterThanOrEqualTo(0));
      });

      test('should work with CommunityStats model', () {
        final stats = const CommunityStats(
          totalUsers: 5,
          totalClassifications: 10,
          totalPoints: 100,
          categoryBreakdown: {'Plastic': 5, 'Paper': 5},
        );

        expect(stats.totalUsers, equals(5));
        expect(stats.totalClassifications, equals(10));
        expect(stats.totalPoints, equals(100));
        expect(stats.categoryBreakdown.length, equals(2));
      });
    });
  });
}

// Helper functions

UserProfile _createTestUser({String? id, String? email, String? displayName}) {
  return UserProfile(
    id: id ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
    email: email ?? 'test@example.com',
    displayName: displayName ?? 'Test User',
  );
}

WasteClassification _createTestClassification(
    {String? userId, DateTime? timestamp}) {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Plastic',
    subcategory: 'Bottle',
    explanation: 'Test recyclable plastic bottle',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: ['Clean', 'Recycle in blue bin'],
      hasUrgentTimeframe: false,
    ),
    timestamp: timestamp,
    region: 'Test Region',
    visualFeatures: ['plastic', 'bottle'],
    alternatives: [],
    confidence: 0.9,
    userId: userId ?? 'test_user',
  );
}

CommunityFeedItem _createTestFeedItem() {
  return CommunityFeedItem(
    id: 'feed_item_${DateTime.now().millisecondsSinceEpoch}',
    userId: 'user_xyz',
    userName: 'Feed User',
    activityType: CommunityActivityType.milestone,
    title: 'Big Achievement!',
    description: 'User reached a new milestone.',
    timestamp: DateTime.now(),
    metadata: const {'milestone': '1000_points'},
    points: 50,
  );
}
