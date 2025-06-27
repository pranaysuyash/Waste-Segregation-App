import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import '../test_helper.dart';

void main() {
  group('CommunityFeed Model Tests', () {
    late DateTime testTimestamp;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      testTimestamp = DateTime.parse('2024-01-15T10:30:00Z');
    });

    group('CommunityFeedItem Constructor Tests', () {
      test('should create CommunityFeedItem with all required fields', () {
        final feedItem = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          userAvatar: 'https://example.com/avatar.jpg',
          activityType: CommunityActivityType.classification,
          title: 'Classified a plastic bottle',
          description: 'Successfully identified and classified a recyclable plastic bottle',
          timestamp: testTimestamp,
          metadata: {'category': 'Dry Waste', 'confidence': 0.95},
          likes: 5,
          likedBy: ['user_789', 'user_012'],
          points: 10,
        );

        expect(feedItem.id, equals('feed_item_123'));
        expect(feedItem.userId, equals('user_456'));
        expect(feedItem.userName, equals('John Doe'));
        expect(feedItem.userAvatar, equals('https://example.com/avatar.jpg'));
        expect(feedItem.activityType, equals(CommunityActivityType.classification));
        expect(feedItem.title, equals('Classified a plastic bottle'));
        expect(feedItem.description, equals('Successfully identified and classified a recyclable plastic bottle'));
        expect(feedItem.timestamp, equals(testTimestamp));
        expect(feedItem.metadata['category'], equals('Dry Waste'));
        expect(feedItem.metadata['confidence'], equals(0.95));
        expect(feedItem.likes, equals(5));
        expect(feedItem.likedBy.length, equals(2));
        expect(feedItem.isAnonymous, isFalse);
        expect(feedItem.points, equals(10));
      });

      test('should create CommunityFeedItem with default values', () {
        final feedItem = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          activityType: CommunityActivityType.achievement,
          title: 'Earned an achievement',
          description: 'Unlocked the Waste Master badge',
          timestamp: testTimestamp,
        );

        expect(feedItem.userAvatar, isNull);
        expect(feedItem.metadata, isEmpty);
        expect(feedItem.likes, equals(0));
        expect(feedItem.likedBy, isEmpty);
        expect(feedItem.isAnonymous, isFalse);
        expect(feedItem.points, equals(0));
      });
    });

    group('CommunityFeedItem Serialization Tests', () {
      test('should serialize and deserialize correctly with toJson/fromJson', () {
        final original = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'Jane Smith',
          userAvatar: 'https://example.com/avatar.jpg',
          activityType: CommunityActivityType.streak,
          title: 'Maintained 7-day streak',
          description: 'Successfully maintained classification streak for 7 days',
          timestamp: testTimestamp,
          metadata: {'streakDays': 7, 'category': 'consistency'},
          likes: 12,
          likedBy: ['user_789', 'user_012', 'user_345'],
          points: 25,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['id'], equals('feed_item_123'));
        expect(json['userId'], equals('user_456'));
        expect(json['userName'], equals('Jane Smith'));
        expect(json['userAvatar'], equals('https://example.com/avatar.jpg'));
        expect(json['activityType'], equals('streak'));
        expect(json['title'], equals('Maintained 7-day streak'));
        expect(json['timestamp'], equals(testTimestamp.toIso8601String()));
        expect(json['metadata'], isA<Map<String, dynamic>>());
        expect(json['likes'], equals(12));
        expect(json['likedBy'], isA<List>());
        expect(json['isAnonymous'], isFalse);
        expect(json['points'], equals(25));

        // Test fromJson
        final recreated = CommunityFeedItem.fromJson(json);
        expect(recreated.id, equals(original.id));
        expect(recreated.userId, equals(original.userId));
        expect(recreated.userName, equals(original.userName));
        expect(recreated.userAvatar, equals(original.userAvatar));
        expect(recreated.activityType, equals(original.activityType));
        expect(recreated.title, equals(original.title));
        expect(recreated.description, equals(original.description));
        expect(recreated.timestamp, equals(original.timestamp));
        expect(recreated.metadata, equals(original.metadata));
        expect(recreated.likes, equals(original.likes));
        expect(recreated.likedBy, equals(original.likedBy));
        expect(recreated.isAnonymous, equals(original.isAnonymous));
        expect(recreated.points, equals(original.points));
      });

      test('should handle null and missing fields in fromJson', () {
        final json = {
          'id': 'feed_item_123',
          'userId': 'user_456',
          'activityType': 'classification',
          'title': 'Test title',
          'description': 'Test description',
        };

        final feedItem = CommunityFeedItem.fromJson(json);

        expect(feedItem.id, equals('feed_item_123'));
        expect(feedItem.userId, equals('user_456'));
        expect(feedItem.userName, equals('Anonymous User')); // Default value
        expect(feedItem.userAvatar, isNull);
        expect(feedItem.activityType, equals(CommunityActivityType.classification));
        expect(feedItem.title, equals('Test title'));
        expect(feedItem.description, equals('Test description'));
        expect(feedItem.timestamp, isA<DateTime>());
        expect(feedItem.metadata, isEmpty);
        expect(feedItem.likes, equals(0));
        expect(feedItem.likedBy, isEmpty);
        expect(feedItem.isAnonymous, isFalse);
        expect(feedItem.points, equals(0));
      });

      test('should handle invalid activity type in fromJson', () {
        final json = {
          'id': 'feed_item_123',
          'userId': 'user_456',
          'userName': 'Test User',
          'activityType': 'invalid_type',
          'title': 'Test title',
          'description': 'Test description',
          'timestamp': testTimestamp.toIso8601String(),
        };

        final feedItem = CommunityFeedItem.fromJson(json);

        // Should default to classification for invalid activity type
        expect(feedItem.activityType, equals(CommunityActivityType.classification));
      });

      test('should handle invalid timestamp in fromJson', () {
        final json = {
          'id': 'feed_item_123',
          'userId': 'user_456',
          'userName': 'Test User',
          'activityType': 'achievement',
          'title': 'Test title',
          'description': 'Test description',
          'timestamp': 'invalid_timestamp',
        };

        final feedItem = CommunityFeedItem.fromJson(json);

        // Should use current time for invalid timestamp
        expect(feedItem.timestamp, isA<DateTime>());
        expect(feedItem.timestamp.difference(DateTime.now()).inMinutes, lessThan(1));
      });
    });

    group('CommunityFeedItem copyWith Tests', () {
      test('should create copy with updated fields', () {
        final original = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          activityType: CommunityActivityType.classification,
          title: 'Original title',
          description: 'Original description',
          timestamp: testTimestamp,
          likes: 5,
          points: 10,
        );

        final updated = original.copyWith(
          title: 'Updated title',
          likes: 8,
          isAnonymous: true,
        );

        expect(updated.id, equals(original.id));
        expect(updated.userId, equals(original.userId));
        expect(updated.userName, equals(original.userName));
        expect(updated.title, equals('Updated title'));
        expect(updated.description, equals(original.description));
        expect(updated.likes, equals(8));
        expect(updated.isAnonymous, isTrue);
        expect(updated.points, equals(original.points));
      });

      test('should preserve original values when no updates provided', () {
        final original = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          activityType: CommunityActivityType.achievement,
          title: 'Achievement earned',
          description: 'Earned a badge',
          timestamp: testTimestamp,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.userName, equals(original.userName));
        expect(copy.activityType, equals(original.activityType));
        expect(copy.title, equals(original.title));
        expect(copy.description, equals(original.description));
        expect(copy.timestamp, equals(original.timestamp));
      });
    });

    group('CommunityFeedItem Display Properties Tests', () {
      test('should return correct display name for normal user', () {
        final feedItem = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: testTimestamp,
        );

        expect(feedItem.displayName, equals('John Doe'));
      });

      test('should return anonymous for anonymous user', () {
        final feedItem = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: 'John Doe',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: testTimestamp,
          isAnonymous: true,
        );

        expect(feedItem.displayName, equals('Anonymous User'));
      });

      test('should return default name for empty username', () {
        final feedItem = CommunityFeedItem(
          id: 'feed_item_123',
          userId: 'user_456',
          userName: '',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: testTimestamp,
        );

        expect(feedItem.displayName, equals('User'));
      });

      test('should return correct relative time strings', () {
        final now = DateTime.now();

        // Just now
        final justNow = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: now.subtract(const Duration(seconds: 30)),
        );
        expect(justNow.relativeTime, equals('Just now'));

        // Minutes ago
        final minutesAgo = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: now.subtract(const Duration(minutes: 15)),
        );
        expect(minutesAgo.relativeTime, equals('15m ago'));

        // Hours ago
        final hoursAgo = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: now.subtract(const Duration(hours: 3)),
        );
        expect(hoursAgo.relativeTime, equals('3h ago'));

        // Days ago
        final daysAgo = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: now.subtract(const Duration(days: 2)),
        );
        expect(daysAgo.relativeTime, equals('2d ago'));

        // Weeks ago
        final weeksAgo = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: now.subtract(const Duration(days: 14)),
        );
        expect(weeksAgo.relativeTime, equals('2w ago'));
      });

      test('should return correct activity icons', () {
        final activityTypes = [
          CommunityActivityType.classification,
          CommunityActivityType.achievement,
          CommunityActivityType.streak,
          CommunityActivityType.challenge,
          CommunityActivityType.milestone,
          CommunityActivityType.educational,
        ];

        final expectedIcons = [
          Icons.camera_alt,
          Icons.emoji_events,
          Icons.local_fire_department,
          Icons.task_alt,
          Icons.star,
          Icons.school,
        ];

        for (var i = 0; i < activityTypes.length; i++) {
          final feedItem = CommunityFeedItem(
            id: 'test_$i',
            userId: 'user',
            userName: 'User',
            activityType: activityTypes[i],
            title: 'Test',
            description: 'Test',
            timestamp: testTimestamp,
          );

          expect(feedItem.activityIcon, equals(expectedIcons[i]));
        }
      });

      test('should return correct activity colors', () {
        final activityTypes = [
          CommunityActivityType.classification,
          CommunityActivityType.achievement,
          CommunityActivityType.streak,
          CommunityActivityType.challenge,
          CommunityActivityType.milestone,
          CommunityActivityType.educational,
        ];

        final expectedColors = [
          Colors.blue,
          Colors.amber,
          Colors.orange,
          Colors.green,
          Colors.purple,
          Colors.indigo,
        ];

        for (var i = 0; i < activityTypes.length; i++) {
          final feedItem = CommunityFeedItem(
            id: 'test_$i',
            userId: 'user',
            userName: 'User',
            activityType: activityTypes[i],
            title: 'Test',
            description: 'Test',
            timestamp: testTimestamp,
          );

          expect(feedItem.activityColor, equals(expectedColors[i]));
        }
      });
    });

    group('CommunityStats Tests', () {
      test('should create CommunityStats with all fields', () {
        final stats = CommunityStats(
          totalUsers: 1000,
          totalClassifications: 5000,
          totalAchievements: 200,
          totalPoints: 25000,
          activeToday: 150,
          activeUsers: 800,
          weeklyClassifications: 1200,
          categoryBreakdown: {
            'Dry Waste': 2000,
            'Wet Waste': 1500,
            'Hazardous Waste': 800,
            'Medical Waste': 400,
            'E-Waste': 300,
          },
          lastUpdated: testTimestamp,
        );

        expect(stats.totalUsers, equals(1000));
        expect(stats.totalClassifications, equals(5000));
        expect(stats.totalAchievements, equals(200));
        expect(stats.totalPoints, equals(25000));
        expect(stats.activeToday, equals(150));
        expect(stats.activeUsers, equals(800));
        expect(stats.weeklyClassifications, equals(1200));
        expect(stats.categoryBreakdown.length, equals(5));
        expect(stats.lastUpdated, equals(testTimestamp));
      });

      test('should serialize and deserialize CommunityStats correctly', () {
        final original = CommunityStats(
          totalUsers: 500,
          totalClassifications: 2500,
          totalAchievements: 100,
          totalPoints: 12500,
          activeToday: 75,
          activeUsers: 400,
          weeklyClassifications: 600,
          categoryBreakdown: {
            'Dry Waste': 1000,
            'Wet Waste': 800,
            'Hazardous Waste': 400,
          },
          lastUpdated: testTimestamp,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['totalUsers'], equals(500));
        expect(json['totalClassifications'], equals(2500));
        expect(json['categoryBreakdown'], isA<Map<String, int>>());
        expect(json['lastUpdated'], equals(testTimestamp.toIso8601String()));

        // Test fromJson
        final recreated = CommunityStats.fromJson(json);
        expect(recreated.totalUsers, equals(original.totalUsers));
        expect(recreated.totalClassifications, equals(original.totalClassifications));
        expect(recreated.totalAchievements, equals(original.totalAchievements));
        expect(recreated.categoryBreakdown, equals(original.categoryBreakdown));
        expect(recreated.lastUpdated, equals(original.lastUpdated));
      });

      test('should handle missing fields in CommunityStats fromJson', () {
        final json = {
          'totalUsers': 100,
          'totalClassifications': 500,
          'totalAchievements': 50,
          'activeToday': 25,
        };

        final stats = CommunityStats.fromJson(json);

        expect(stats.totalUsers, equals(100));
        expect(stats.totalClassifications, equals(500));
        expect(stats.totalPoints, equals(0)); // Default value
        expect(stats.activeUsers, equals(0)); // Default value
        expect(stats.weeklyClassifications, equals(0)); // Default value
        expect(stats.categoryBreakdown, isEmpty); // Default empty map
        expect(stats.lastUpdated, isA<DateTime>());
      });

      test('should return top categories correctly sorted', () {
        final stats = CommunityStats(
          totalUsers: 100,
          totalClassifications: 1000,
          totalAchievements: 50,
          activeToday: 25,
          categoryBreakdown: {
            'Dry Waste': 400,
            'Wet Waste': 300,
            'Hazardous Waste': 150,
            'Medical Waste': 100,
            'E-Waste': 50,
            'Other': 20,
          },
          lastUpdated: testTimestamp,
        );

        final topCategories = stats.topCategories;

        expect(topCategories.length, equals(5)); // Top 5 categories

        final categories = topCategories.keys.toList();
        final values = topCategories.values.toList();

        // Should be sorted in descending order
        expect(categories[0], equals('Dry Waste'));
        expect(values[0], equals(400));
        expect(categories[1], equals('Wet Waste'));
        expect(values[1], equals(300));
        expect(categories[2], equals('Hazardous Waste'));
        expect(values[2], equals(150));
        expect(categories[3], equals('Medical Waste'));
        expect(values[3], equals(100));
        expect(categories[4], equals('E-Waste'));
        expect(values[4], equals(50));

        // 'Other' should not be included as it's 6th
        expect(categories.contains('Other'), isFalse);
      });

      test('should handle empty category breakdown', () {
        final stats = CommunityStats(
          totalUsers: 100,
          totalClassifications: 1000,
          totalAchievements: 50,
          activeToday: 25,
          categoryBreakdown: {},
          lastUpdated: testTimestamp,
        );

        final topCategories = stats.topCategories;
        expect(topCategories, isEmpty);
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('should handle empty strings in feed item', () {
        final feedItem = CommunityFeedItem(
          id: '',
          userId: '',
          userName: '',
          activityType: CommunityActivityType.classification,
          title: '',
          description: '',
          timestamp: testTimestamp,
        );

        expect(feedItem.id, equals(''));
        expect(feedItem.userId, equals(''));
        expect(feedItem.displayName, equals('User')); // Default for empty username
        expect(feedItem.title, equals(''));
        expect(feedItem.description, equals(''));
      });

      test('should handle very large numbers in stats', () {
        final stats = CommunityStats(
          totalUsers: 1000000,
          totalClassifications: 10000000,
          totalAchievements: 100000,
          totalPoints: 1000000000,
          activeToday: 50000,
          categoryBreakdown: {
            'Dry Waste': 5000000,
            'Wet Waste': 3000000,
          },
          lastUpdated: testTimestamp,
        );

        expect(stats.totalUsers, equals(1000000));
        expect(stats.totalClassifications, equals(10000000));
        expect(stats.totalPoints, equals(1000000000));
      });

      test('should handle negative numbers gracefully', () {
        final feedItem = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Test',
          description: 'Test',
          timestamp: testTimestamp,
          likes: -5, // Negative likes
          points: -10, // Negative points
        );

        expect(feedItem.likes, equals(-5));
        expect(feedItem.points, equals(-10));
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;

        final feedItem = CommunityFeedItem(
          id: longString,
          userId: longString,
          userName: longString,
          activityType: CommunityActivityType.classification,
          title: longString,
          description: longString,
          timestamp: testTimestamp,
        );

        expect(feedItem.id.length, equals(1000));
        expect(feedItem.userName.length, equals(1000));
        expect(feedItem.title.length, equals(1000));
        expect(feedItem.description.length, equals(1000));
      });

      test('should handle future timestamps', () {
        final futureDate = DateTime.now().add(const Duration(days: 365));

        final feedItem = CommunityFeedItem(
          id: 'test',
          userId: 'user',
          userName: 'User',
          activityType: CommunityActivityType.classification,
          title: 'Future item',
          description: 'From the future',
          timestamp: futureDate,
        );

        expect(feedItem.timestamp.isAfter(DateTime.now()), isTrue);
        // Relative time for future items might be negative or show as "just now"
        expect(feedItem.relativeTime, isA<String>());
      });
    });
  });
}
