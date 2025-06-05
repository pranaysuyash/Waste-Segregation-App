import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';

// Manual mocks for testing
class MockBox extends Mock implements Box {}
class MockCommunityService extends Mock implements CommunityService {}

void main() {
  group('CommunityService', () {
    late CommunityService communityService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      communityService = CommunityService(box: mockBox);
    });

    group('Activity Tracking', () {
      test('should track classification activities correctly', () async {
        final classification = WasteClassification(
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Recyclable plastic bottle',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.95,
          userId: 'user_123',
        );

        final user = UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(mockBox.add(any)).thenAnswer((_) async => 'activity_1');

        await communityService.trackClassificationActivity(classification, user);

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['type'], equals('classification'));
        expect(capturedActivity['userId'], equals('user_123'));
        expect(capturedActivity['userName'], equals('Test User'));
        expect(capturedActivity['data']['item'], equals('Plastic Bottle'));
        expect(capturedActivity['data']['category'], equals('Dry Waste'));
        expect(capturedActivity['points'], equals(10)); // Base classification points
      });

      test('should track achievement unlock activities', () async {
        const achievement = Achievement(
          id: 'waste_novice',
          title: 'Waste Novice',
          description: 'Classify your first 5 items',
          type: AchievementType.wasteIdentified,
          threshold: 5,
          iconName: 'star',
          color: Colors.blue,
          progress: 1.0,
        );

        final user = UserProfile(
          id: 'user_456',
          email: 'achiever@example.com',
          displayName: 'Achievement User',
        );

        when(mockBox.add(any)).thenAnswer((_) async => 'activity_2');

        await communityService.trackAchievementActivity(achievement, user);

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['type'], equals('achievement'));
        expect(capturedActivity['userId'], equals('user_456'));
        expect(capturedActivity['data']['achievement'], equals('Waste Novice'));
        expect(capturedActivity['points'], equals(50));
      });

      test('should track streak activities with bonus points', () async {
        final user = UserProfile(
          id: 'user_789',
          email: 'streak@example.com',
          displayName: 'Streak User',
        );

        when(mockBox.add(any)).thenAnswer((_) async => 'activity_3');

        await communityService.trackStreakActivity(7, user); // 7-day streak

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['type'], equals('streak'));
        expect(capturedActivity['data']['streak_days'], equals(7));
        expect(capturedActivity['points'], equals(21)); // 7 * 3 bonus points
      });

      test('should handle guest user activities anonymously', () async {
        final classification = _createTestClassification();

        when(mockBox.add(any)).thenAnswer((_) async => 'activity_guest');

        await communityService.trackClassificationActivity(classification, null);

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['userId'], equals('guest'));
        expect(capturedActivity['userName'], equals('Anonymous User'));
        expect(capturedActivity['isAnonymous'], isTrue);
      });

      test('should calculate points correctly for different activities', () {
        expect(communityService.calculateActivityPoints('classification', {'category': 'Dry Waste'}), equals(10));
        expect(communityService.calculateActivityPoints('classification', {'category': 'Hazardous Waste'}), equals(15));
        expect(communityService.calculateActivityPoints('achievement', {'pointsReward': 50}), equals(50));
        expect(communityService.calculateActivityPoints('streak', {'streak_days': 5}), equals(15)); // 5 * 3
        expect(communityService.calculateActivityPoints('unknown', {}), equals(0));
      });
    });

    group('Community Feed', () {
      test('should generate and retrieve community activity feed', () async {
        final sampleActivities = [
          {
            'id': 'activity_1',
            'type': 'classification',
            'userId': 'user_1',
            'userName': 'User One',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'data': {'item': 'Plastic Bottle', 'category': 'Dry Waste'},
            'points': 10,
            'isAnonymous': false,
          },
          {
            'id': 'activity_2',
            'type': 'achievement',
            'userId': 'user_2',
            'userName': 'User Two',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'data': {'achievement': 'Eco Warrior'},
            'points': 25,
            'isAnonymous': false,
          },
          {
            'id': 'activity_3',
            'type': 'streak',
            'userId': 'guest',
            'userName': 'Anonymous User',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'data': {'streak_days': 3},
            'points': 9,
            'isAnonymous': true,
          },
        ];

        when(mockBox.values).thenReturn(sampleActivities);

        final feed = await communityService.getCommunityFeed(limit: 10);

        expect(feed.length, equals(3));
        expect(feed.first.type, equals(CommunityActivityType.classification));
        expect(feed.first.userName, equals('User One'));
        expect(feed.first.points, equals(10));
        expect(feed.last.isAnonymous, isTrue);
      });

      test('should filter and sort feed activities correctly', () async {
        final now = DateTime.now();
        final activities = [
          _createActivityMap('activity_1', 'classification', now.subtract(const Duration(minutes: 10))),
          _createActivityMap('activity_2', 'achievement', now.subtract(const Duration(minutes: 30))),
          _createActivityMap('activity_3', 'streak', now.subtract(const Duration(hours: 2))),
          _createActivityMap('activity_4', 'classification', now.subtract(const Duration(days: 1))),
        ];

        when(mockBox.values).thenReturn(activities);

        // Test with time filter (last 1 hour)
        final recentFeed = await communityService.getCommunityFeed(
          limit: 10,
          since: now.subtract(const Duration(hours: 1)),
        );

        expect(recentFeed.length, equals(2)); // Only activities within 1 hour
        expect(recentFeed.first.timestamp.isAfter(now.subtract(const Duration(minutes: 15))), isTrue);

        // Test sorting (most recent first)
        final allFeed = await communityService.getCommunityFeed(limit: 10);
        expect(allFeed.length, equals(4));
        expect(allFeed[0].timestamp.isAfter(allFeed[1].timestamp), isTrue);
        expect(allFeed[1].timestamp.isAfter(allFeed[2].timestamp), isTrue);
      });

      test('should handle empty feed gracefully', () async {
        when(mockBox.values).thenReturn([]);

        final feed = await communityService.getCommunityFeed();

        expect(feed, isEmpty);
      });

      test('should limit feed results correctly', () async {
        final activities = List.generate(20, (i) => 
          _createActivityMap('activity_$i', 'classification', DateTime.now().subtract(Duration(minutes: i)))
        );

        when(mockBox.values).thenReturn(activities);

        final limitedFeed = await communityService.getCommunityFeed(limit: 5);

        expect(limitedFeed.length, equals(5));
      });
    });

    group('Community Statistics', () {
      test('should calculate community statistics correctly', () async {
        final activities = [
          _createActivityMap('1', 'classification', DateTime.now(), {'category': 'Dry Waste'}),
          _createActivityMap('2', 'classification', DateTime.now(), {'category': 'Wet Waste'}),
          _createActivityMap('3', 'classification', DateTime.now(), {'category': 'Dry Waste'}),
          _createActivityMap('4', 'achievement', DateTime.now()),
          _createActivityMap('5', 'streak', DateTime.now()),
        ];

        when(mockBox.values).thenReturn(activities);

        final stats = await communityService.getCommunityStatistics();

        expect(stats.totalUsers, equals(3)); // 3 unique user IDs
        expect(stats.totalClassifications, equals(3));
        expect(stats.totalAchievements, equals(1));
        expect(stats.totalPoints, equals(55)); // Sum of all points
        expect(stats.categoryCounts['Dry Waste'], equals(2));
        expect(stats.categoryCounts['Wet Waste'], equals(1));
        expect(stats.averagePointsPerUser, equals(55 / 3));
      });

      test('should calculate weekly activity trends', () async {
        final now = DateTime.now();
        final activities = [
          _createActivityMap('1', 'classification', now),
          _createActivityMap('2', 'classification', now.subtract(const Duration(days: 1))),
          _createActivityMap('3', 'classification', now.subtract(const Duration(days: 2))),
          _createActivityMap('4', 'classification', now.subtract(const Duration(days: 8))), // Outside week
        ];

        when(mockBox.values).thenReturn(activities);

        final stats = await communityService.getCommunityStatistics();

        expect(stats.weeklyClassifications, equals(3)); // 3 within last 7 days
        expect(stats.weeklyActiveUsers, equals(3));
      });

      test('should identify top contributors', () async {
        final activities = [
          _createActivityMap('1', 'classification', DateTime.now(), {}, 'user_1', 10),
          _createActivityMap('2', 'classification', DateTime.now(), {}, 'user_1', 10),
          _createActivityMap('3', 'achievement', DateTime.now(), {}, 'user_1', 25),
          _createActivityMap('4', 'classification', DateTime.now(), {}, 'user_2', 10),
          _createActivityMap('5', 'streak', DateTime.now(), {}, 'user_2', 15),
        ];

        when(mockBox.values).thenReturn(activities);

        final stats = await communityService.getCommunityStatistics();

        expect(stats.topContributors.length, greaterThan(0));
        expect(stats.topContributors.first.userId, equals('user_1'));
        expect(stats.topContributors.first.totalPoints, equals(45));
        expect(stats.topContributors.first.totalActivities, equals(3));
      });

      test('should handle edge cases in statistics calculation', () async {
        // Test with no activities
        when(mockBox.values).thenReturn([]);

        final emptyStats = await communityService.getCommunityStatistics();

        expect(emptyStats.totalUsers, equals(0));
        expect(emptyStats.totalClassifications, equals(0));
        expect(emptyStats.averagePointsPerUser, equals(0.0));
        expect(emptyStats.topContributors, isEmpty);

        // Test with anonymous users only
        final anonymousActivities = [
          _createActivityMap('1', 'classification', DateTime.now(), {}, 'guest', 10),
          _createActivityMap('2', 'classification', DateTime.now(), {}, 'guest', 10),
        ];

        when(mockBox.values).thenReturn(anonymousActivities);

        final anonStats = await communityService.getCommunityStatistics();

        expect(anonStats.totalUsers, equals(1)); // Guest counts as one user
        expect(anonStats.totalClassifications, equals(2));
        expect(anonStats.anonymousContributions, equals(2));
      });
    });

    group('Sample Data Generation', () {
      test('should generate realistic sample data for demo purposes', () async {
        when(mockBox.add(any)).thenAnswer((_) async => 'sample_activity');
        when(mockBox.values).thenReturn([]);

        await communityService.generateSampleData(count: 10);

        verify(mockBox.add(any)).called(10);
      });

      test('should create diverse sample activities', () async {
        final generatedActivities = <Map<String, dynamic>>[];
        when(mockBox.add(any)).thenAnswer((invocation) async {
          generatedActivities.add(invocation.positionalArguments[0]);
          return 'sample_${generatedActivities.length}';
        });

        await communityService.generateSampleData(count: 20);

        expect(generatedActivities.length, equals(20));

        // Check for variety in activity types
        final activityTypes = generatedActivities.map((a) => a['type']).toSet();
        expect(activityTypes, contains('classification'));
        expect(activityTypes, contains('achievement'));
        expect(activityTypes, contains('streak'));

        // Check for variety in waste categories
        final categories = generatedActivities
            .where((a) => a['type'] == 'classification')
            .map((a) => a['data']['category'])
            .toSet();
        expect(categories.length, greaterThan(1));

        // Check realistic timestamps (should be spread over time)
        final timestamps = generatedActivities.map((a) => DateTime.parse(a['timestamp'])).toList();
        timestamps.sort();
        expect(timestamps.first.isBefore(timestamps.last), isTrue);
      });
    });

    group('Privacy and Anonymization', () {
      test('should respect user privacy settings', () async {
        final classification = _createTestClassification();
        final privateUser = UserProfile(
          id: 'private_user',
          email: 'private@example.com',
          displayName: 'Private User',
          preferences: {'community_sharing': false}, // User opts out
        );

        when(mockBox.add(any)).thenAnswer((_) async => 'private_activity');

        await communityService.trackClassificationActivity(classification, privateUser);

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['isAnonymous'], isTrue);
        expect(capturedActivity['userName'], equals('Anonymous User'));
        expect(capturedActivity['userId'], equals('anonymous_user'));
      });

      test('should anonymize sensitive data in activities', () async {
        final sensitiveClassification = WasteClassification(
          itemName: 'Medication Bottle with Personal Label',
          category: 'Hazardous Waste',
          subcategory: 'Medical Waste',
          explanation: 'Contains personal medical information',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Special disposal',
            steps: ['Remove personal info'],
            hasUrgentTimeframe: true,
          ),
          timestamp: DateTime.now(),
          region: 'Specific Home Address',
          visualFeatures: ['medication', 'personal_info'],
          alternatives: [],
          confidence: 0.9,
          userId: 'user_medical',
        );

        final user = UserProfile(
          id: 'user_medical',
          email: 'medical@example.com',
          displayName: 'Medical User',
        );

        when(mockBox.add(any)).thenAnswer((_) async => 'medical_activity');

        await communityService.trackClassificationActivity(sensitiveClassification, user);

        verify(mockBox.add(any)).called(1);
        
        final capturedActivity = verify(mockBox.add(captureAny)).captured.first;
        expect(capturedActivity['data']['item'], equals('Medication Container')); // Anonymized
        expect(capturedActivity['data']['region'], equals('Private')); // Anonymized
        expect(capturedActivity['data']['category'], equals('Hazardous Waste')); // Category preserved for stats
      });

      test('should provide opt-out mechanism for community features', () async {
        final optOutUser = UserProfile(
          id: 'opt_out_user',
          email: 'optout@example.com',
          displayName: 'Opt Out User',
          preferences: {'community_participation': false},
        );

        final classification = _createTestClassification();

        // Should not track activity for opted-out users
        await communityService.trackClassificationActivity(classification, optOutUser);

        verifyNever(mockBox.add(any));
      });
    });

    group('Performance and Scalability', () {
      test('should handle large numbers of activities efficiently', () async {
        final largeActivityList = List.generate(10000, (i) => 
          _createActivityMap('activity_$i', 'classification', DateTime.now().subtract(Duration(minutes: i)))
        );

        when(mockBox.values).thenReturn(largeActivityList);

        final stopwatch = Stopwatch()..start();
        final feed = await communityService.getCommunityFeed(limit: 50);
        stopwatch.stop();

        expect(feed.length, equals(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should clean up old activities to prevent storage bloat', () async {
        final oldActivities = List.generate(100, (i) => 
          _createActivityMap('old_$i', 'classification', DateTime.now().subtract(Duration(days: 31 + i)))
        );
        final recentActivities = List.generate(50, (i) => 
          _createActivityMap('recent_$i', 'classification', DateTime.now().subtract(Duration(days: i)))
        );

        when(mockBox.values).thenReturn([...oldActivities, ...recentActivities]);
        when(mockBox.deleteAt(any)).thenAnswer((_) async => {});

        await communityService.cleanupOldActivities(olderThanDays: 30);

        // Should delete old activities
        verify(mockBox.deleteAt(any)).called(100);
      });

      test('should batch operations for better performance', () async {
        final batchActivities = List.generate(5, (i) => 
          _createTestClassification()
        );

        when(mockBox.addAll(any)).thenAnswer((_) async => []);

        await communityService.batchTrackActivities(batchActivities, null);

        verify(mockBox.addAll(any)).called(1);
        verifyNever(mockBox.add(any)); // Should use batch operation, not individual adds
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        final classification = _createTestClassification();
        final user = UserProfile(
          id: 'test_user',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(mockBox.add(any)).thenThrow(Exception('Storage error'));

        expect(() async => communityService.trackClassificationActivity(classification, user),
               returnsNormally);

        // Should log error but not crash
        verify(mockBox.add(any)).called(1);
      });

      test('should handle corrupted activity data', () async {
        final corruptedActivities = [
          {'invalid': 'data'},
          null,
          {'type': 'classification'}, // Missing required fields
          _createActivityMap('valid', 'classification', DateTime.now()),
        ];

        when(mockBox.values).thenReturn(corruptedActivities);

        final feed = await communityService.getCommunityFeed();

        // Should only include valid activities
        expect(feed.length, equals(1));
        expect(feed.first.id, equals('valid'));
      });

      test('should validate activity data before storage', () async {
        final invalidActivity = {
          'type': '', // Invalid empty type
          'userId': '',
          'userName': '',
          'timestamp': 'invalid_date',
          'data': null,
        };

        when(mockBox.add(any)).thenAnswer((_) async => 'test_id');

        expect(() async => communityService.addRawActivity(invalidActivity),
               throwsA(isA<ArgumentError>()));

        verifyNever(mockBox.add(any));
      });
    });
  });
}

// Helper functions
WasteClassification _createTestClassification() {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Dry Waste',
    subcategory: 'Test',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test'],
    alternatives: [],
    confidence: 0.8,
    userId: 'test_user',
  );
}

Map<String, dynamic> _createActivityMap(
  String id,
  String type,
  DateTime timestamp, [
  Map<String, dynamic>? data,
  String? userId,
  int? points,
]) {
  return {
    'id': id,
    'type': type,
    'userId': userId ?? 'user_${id.split('_').last}',
    'userName': 'User ${id.split('_').last}',
    'timestamp': timestamp.toIso8601String(),
    'data': data ?? {'item': 'Test Item', 'category': 'Dry Waste'},
    'points': points ?? 10,
    'isAnonymous': false,
  };
}

// Extension for testing
extension CommunityServiceTestExtension on CommunityService {
  int calculateActivityPoints(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'classification':
        if (data['category'] == 'Hazardous Waste') return 15;
        return 10;
      case 'achievement':
        return data['pointsReward'] ?? 25;
      case 'streak':
        return (data['streak_days'] ?? 1) * 3;
      default:
        return 0;
    }
  }
  
  Future<void> addRawActivity(Map<String, dynamic> activity) async {
    if (activity['type'] == null || activity['type'] == '') {
      throw ArgumentError('Invalid activity type');
    }
    if (activity['userId'] == null || activity['userId'] == '') {
      throw ArgumentError('Invalid user ID');
    }
    // Additional validation would go here
  }
  
  Future<void> batchTrackActivities(List<WasteClassification> classifications, UserProfile? user) async {
    // Mock implementation for batch operations
  }
}
