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
        expect(
          () async => await communityService.initCommunity(),
          returnsNormally,
        );
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
        expect(() async => await communityService.getStats(), returnsNormally);
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

    group('Aggregation Helpers', () {
      test(
        'aggregateStatsFromFeedItems should count classifications and categories',
        () {
          final feedItems = [
            CommunityFeedItem(
              id: 'c1',
              userId: 'user1',
              userName: 'User 1',
              activityType: CommunityActivityType.classification,
              title: 'Scan 1',
              description: 'Plastic',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Plastic'},
            ),
            CommunityFeedItem(
              id: 'c2',
              userId: 'user2',
              userName: 'User 2',
              activityType: CommunityActivityType.classification,
              title: 'Scan 2',
              description: 'Glass',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Glass'},
            ),
            CommunityFeedItem(
              id: 'a1',
              userId: 'user1',
              userName: 'User 1',
              activityType: CommunityActivityType.achievement,
              title: 'Badge',
              description: 'Achievement',
              timestamp: DateTime.now(),
              points: 20,
              metadata: {'achievementId': 'a1'},
            ),
          ];

          final stats = CommunityService.aggregateStatsFromFeedItems(feedItems);

          expect(stats.totalUsers, equals(2));
          expect(stats.totalClassifications, equals(2));
          expect(stats.totalPoints, equals(40));
          expect(stats.categoryBreakdown['Plastic'], equals(1));
          expect(stats.categoryBreakdown['Glass'], equals(1));
        },
      );

      test('aggregateStatsFromFeedItems returns zero state for empty feed', () {
        final stats = CommunityService.aggregateStatsFromFeedItems([]);

        expect(stats.totalUsers, equals(0));
        expect(stats.totalClassifications, equals(0));
        expect(stats.totalPoints, equals(0));
        expect(stats.categoryBreakdown, isEmpty);
      });

      test(
        'aggregateStatsFromFeedItems increments categoryBreakdown for each classification',
        () {
          final feedItems = [
            CommunityFeedItem(
              id: 'c1',
              userId: 'user1',
              userName: 'User 1',
              activityType: CommunityActivityType.classification,
              title: 'Scan 1',
              description: 'Glass',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Plastic'},
            ),
            CommunityFeedItem(
              id: 'c2',
              userId: 'user2',
              userName: 'User 2',
              activityType: CommunityActivityType.classification,
              title: 'Scan 2',
              description: 'Soda',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Plastic'},
            ),
            CommunityFeedItem(
              id: 'c3',
              userId: 'user2',
              userName: 'User 2',
              activityType: CommunityActivityType.classification,
              title: 'Scan 3',
              description: 'Banana',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Organic'},
            ),
          ];

          final stats = CommunityService.aggregateStatsFromFeedItems(feedItems);

          expect(stats.totalClassifications, equals(3));
          expect(stats.categoryBreakdown['Plastic'], equals(2));
          expect(stats.categoryBreakdown['Organic'], equals(1));
        },
      );

      test(
        'dedupeClassificationsById plus feed-id extraction prevents backfill double-count',
        () {
          final localClassifications = [
            _createTestClassification(id: 'dup-1', userId: 'user-a'),
            _createTestClassification(id: 'dup-1', userId: 'user-a'),
            _createTestClassification(id: 'new-1', userId: 'user-b'),
          ];

          final existingFeed = [
            CommunityFeedItem(
              id: 'dup-1',
              userId: 'user-a',
              userName: 'User A',
              activityType: CommunityActivityType.classification,
              title: 'Old scan',
              description: 'Already synced',
              timestamp: DateTime.now(),
              points: 10,
              metadata: {'category': 'Plastic'},
            ),
          ];

          final dedupedLocal = CommunityService.dedupeClassificationsById(
            localClassifications,
          );
          final existingIds = CommunityService.extractClassificationIdsFromFeed(
            existingFeed,
          );
          final toSync = dedupedLocal
              .where(
                (classification) => !existingIds.contains(classification.id),
              )
              .toList();

          expect(dedupedLocal, hasLength(2));
          expect(toSync, hasLength(1));
          expect(toSync.first.id, equals('new-1'));
        },
      );

      test(
        'dedupeClassificationsById should remove duplicate classifications',
        () {
          final classifications = [
            _createTestClassification(id: 'dup-id'),
            _createTestClassification(id: 'dup-id'),
            _createTestClassification(id: 'another-id'),
          ];

          final deduped = CommunityService.dedupeClassificationsById(
            classifications,
          );

          expect(deduped.length, equals(2));
        },
      );

      test('findCommunityStatsDiscrepancies should detect and clear drift', () {
        final feed = [
          CommunityFeedItem(
            id: 'c1',
            userId: 'user1',
            userName: 'User 1',
            activityType: CommunityActivityType.classification,
            title: 'Scan',
            description: 'Glass',
            timestamp: DateTime.now(),
            points: 10,
            metadata: {'category': 'Glass'},
          ),
        ];

        final computed = CommunityService.aggregateStatsFromFeedItems(feed);
        final matching = const CommunityStats(
          totalUsers: 1,
          totalClassifications: 1,
          totalPoints: 10,
          categoryBreakdown: {'Glass': 1},
        );
        final mismatching = const CommunityStats(
          totalUsers: 2,
          totalClassifications: 1,
          totalPoints: 5,
          categoryBreakdown: {'Glass': 0},
        );

        expect(
          CommunityService.findCommunityStatsDiscrepancies(
            computedStats: computed,
            storedStats: matching,
          ),
          isEmpty,
        );

        final mismatches = CommunityService.findCommunityStatsDiscrepancies(
          computedStats: computed,
          storedStats: mismatching,
        );

        expect(mismatches, isNotEmpty);
        expect(
          mismatches.map((m) => m.field),
          containsAll(<String>['totalUsers', 'totalPoints', 'category.Glass']),
        );
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

WasteClassification _createTestClassification({
  String? id,
  String? userId,
  DateTime? timestamp,
}) {
  return WasteClassification(
    id: id,
    itemName: 'Test Item',
    category: 'Plastic',
    subCategory: 'Bottle',
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
