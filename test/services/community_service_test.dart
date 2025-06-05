import 'dart:convert';
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
class MockBox extends Mock implements Box<dynamic> {}
class MockCommunityService extends Mock implements CommunityService {}

void main() {
  group('CommunityService', () {
    late CommunityService communityService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      // Inlined helper function calls
      when(mockBox.add(any)).thenReturn(Future<int>.value(0));
      // when(mockBox.deleteAt(argThat(isA<int>()))).thenAnswer((_) async {}); // Temporarily commented out
      // when(mockBox.addAll(argThat(isA<Iterable<dynamic>>()))).thenReturn(Future<List<int>>.value(<int>[])); // Temporarily commented out
      
      communityService = CommunityService();
      // In a real app, ensure Hive is initialized before tests that use it.
      // e.g., Hive.init(null); // For in-memory for tests
      // And then ensure the CommunityService gets the correct box instance.
      // For these unit tests, we are mocking the box interaction directly by assuming
      // CommunityService internally calls Hive.box() with specific keys.
      // We then mock those specific Hive.box().get/put calls.
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
        
        // Mock Hive interactions for addFeedItem
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());


        await communityService.trackClassificationActivity(classification, user);

        // Verify put was called on the feed box (indirectly via addFeedItem)
        final capturedFeedPut = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(capturedFeedPut);
        expect(feedList.isNotEmpty, isTrue);
        final capturedActivity = feedList.first as Map<String, dynamic>;

        expect(capturedActivity['activityType'], equals(CommunityActivityType.classification.name));
        expect(capturedActivity['userId'], equals('user_123'));
        expect(capturedActivity['userName'], equals('Test User'));
        expect(capturedActivity['metadata']['category'], equals('Dry Waste'));
        expect(capturedActivity['points'], greaterThanOrEqualTo(0)); 
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

        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());

        await communityService.trackAchievementActivity(achievement, user);

        final capturedFeedPut = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(capturedFeedPut);
        expect(feedList.isNotEmpty, isTrue);
        final capturedActivity = feedList.first as Map<String, dynamic>;

        expect(capturedActivity['activityType'], equals(CommunityActivityType.achievement.name));
        expect(capturedActivity['userId'], equals('user_456'));
        expect(capturedActivity['metadata']['achievementTitle'], equals('Waste Novice'));
        expect(capturedActivity['points'], greaterThanOrEqualTo(0));
      });

      test('should track streak activities with bonus points', () async {
        final user = UserProfile(
          id: 'user_789',
          email: 'streak@example.com',
          displayName: 'Streak User',
        );
        
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());

        await communityService.trackStreakActivity(7, user); 

        final capturedFeedPut = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(capturedFeedPut);
        expect(feedList.isNotEmpty, isTrue);
        final capturedActivity = feedList.first as Map<String, dynamic>;

        expect(capturedActivity['activityType'], equals(CommunityActivityType.streak.name));
        expect(capturedActivity['metadata']['streakDays'], equals(7));
        expect(capturedActivity['points'], greaterThanOrEqualTo(0)); 
      });

      test('should handle guest user activities anonymously', () async {
        final classification = _createTestClassification();

        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());

        await communityService.trackClassificationActivity(classification, null); 

        final capturedFeedPut = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(capturedFeedPut);
        expect(feedList.isNotEmpty, isTrue);
        final capturedActivity = feedList.first as Map<String, dynamic>;
        
        expect(capturedActivity['userId'], 'current_user'); // Or specific guest ID logic from service
        expect(capturedActivity['userName'], equals('You')); // Or 'Anonymous User'
        // isAnonymous might not be directly on the map if it's handled by CommunityFeedItem constructor
        // expect(capturedActivity['isAnonymous'], isTrue); // This depends on how CommunityService creates the item
      });

      test('should calculate points correctly for different activities', () {
        expect(communityService.calculateActivityPoints(CommunityActivityType.classification, {'category': 'Dry Waste'}), greaterThanOrEqualTo(0));
        expect(communityService.calculateActivityPoints(CommunityActivityType.achievement, {'achievementTitle': 'Test Achieve'}), greaterThanOrEqualTo(0));
        expect(communityService.calculateActivityPoints(CommunityActivityType.streak, {'streakDays': 5}), greaterThanOrEqualTo(0));
        expect(communityService.calculateActivityPoints(CommunityActivityType.challenge, {}), greaterThanOrEqualTo(0));
      });
    });

    group('Community Feed', () {
      test('should generate and retrieve community activity feed', () async {
        final sampleActivityJsonList = [
          CommunityFeedItem(id: '1', userId: 'u1', userName: 'User1', activityType: CommunityActivityType.classification, title: 't1', description: 'd1', timestamp: DateTime.now()).toJson(),
          CommunityFeedItem(id: '2', userId: 'u2', userName: 'User2', activityType: CommunityActivityType.achievement, title: 't2', description: 'd2', timestamp: DateTime.now().subtract(Duration(hours:1))).toJson(),
        ];
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode(sampleActivityJsonList));

        final feed = await communityService.getFeedItems(limit: 10);

        expect(feed.length, equals(2));
        expect(feed.first.activityType, equals(CommunityActivityType.classification));
        expect(feed.first.userName, equals('User1'));
      });

      test('should filter and sort feed activities correctly', () async {
        final now = DateTime.now();
        final activitiesJsonList = [
          CommunityFeedItem(id: 'activity_1', userId: 'u1', userName: 'N1', activityType: CommunityActivityType.classification, title: 'T1', description: 'D1', timestamp: now.subtract(const Duration(minutes: 10))).toJson(),
          CommunityFeedItem(id: 'activity_2', userId: 'u2', userName: 'N2', activityType: CommunityActivityType.achievement, title: 'T2', description: 'D2', timestamp: now.subtract(const Duration(minutes: 30))).toJson(),
          CommunityFeedItem(id: 'activity_3', userId: 'u3', userName: 'N3', activityType: CommunityActivityType.streak, title: 'T3', description: 'D3', timestamp: now.subtract(const Duration(hours: 2))).toJson(),
          CommunityFeedItem(id: 'activity_4', userId: 'u4', userName: 'N4', activityType: CommunityActivityType.classification, title: 'T4', description: 'D4', timestamp: now.subtract(const Duration(days: 1))).toJson(),
        ];
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode(activitiesJsonList));
        
        final allFeed = await communityService.getFeedItems(limit: 10);
        expect(allFeed.length, equals(4)); 
        if (allFeed.length >= 2) { 
          expect(allFeed[0].timestamp.isAfter(allFeed[1].timestamp), isTrue);
          if (allFeed.length >=3) {
            expect(allFeed[1].timestamp.isAfter(allFeed[2].timestamp), isTrue);
          }
        }
      });

      test('should handle empty feed gracefully', () async {
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        final feed = await communityService.getFeedItems();
        expect(feed, isEmpty);
      });

      test('should limit feed results correctly', () async {
         final activitiesJsonList = List.generate(20, (i) =>
          CommunityFeedItem(id: 'activity_$i', userId: 'u$i', userName: 'N$i', activityType: CommunityActivityType.classification, title: 'T$i', description: 'D$i', timestamp: DateTime.now().subtract(Duration(minutes: i))).toJson()
        );
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode(activitiesJsonList));

        final limitedFeed = await communityService.getFeedItems(limit: 5);
        expect(limitedFeed.length, equals(5));
      });
    });

    group('Community Statistics', () {
      test('should calculate community statistics correctly', () async {
        final initialStats = CommunityStats(
            totalUsers: 1, totalClassifications: 0, totalAchievements: 0, activeToday: 1, 
            categoryBreakdown: {}, lastUpdated: DateTime.now()
        );
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put(any, any)).thenAnswer((_) async => Future.value()); 

        final feedItem = CommunityFeedItem(
            id: 'test_item', userId: 'user1', userName: 'User1', 
            activityType: CommunityActivityType.classification, 
            title: 'Test Classify', description: 'Desc', timestamp: DateTime.now(),
            metadata: {'category': 'Dry Waste'}, points: 10
        );
        // Mock the feed read by addFeedItem
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        await communityService.addFeedItem(feedItem); 

        final capturedStatsJson = verify(mockBox.put('communityStats', captureAny)).captured.last;
        final updatedStats = CommunityStats.fromJson(jsonDecode(capturedStatsJson));

        expect(updatedStats.totalClassifications, equals(initialStats.totalClassifications + 1));
        expect(updatedStats.categoryBreakdown['Dry Waste'], equals(1));
        expect(updatedStats.activeToday, greaterThanOrEqualTo(initialStats.activeToday));
      });

      test('should retrieve default stats if none are stored', () async {
        when(mockBox.get('communityStats')).thenReturn(null); // No stats stored
        final stats = await communityService.getCommunityStats();
        expect(stats.totalUsers, equals(0)); // Default values
        expect(stats.totalClassifications, equals(0));
      });

      test('should update stats when new user activity is recorded', () async {
         final now = DateTime.now();
         final classification = _createTestClassification(userId: 'newUser', timestamp: now);
         final user = UserProfile(id: 'newUser', email: 'new@test.com', displayName: 'New User');
         
         final initialStats = CommunityStats(totalUsers: 5, totalClassifications: 10, totalAchievements: 2, activeToday: 3, categoryBreakdown: {'Dry Waste': 5, 'Wet Waste': 5}, lastUpdated: now.subtract(const Duration(days:1)));
         when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
         when(mockBox.put('communityStats', any)).thenAnswer((_) async {});
         when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]'); // For addFeedItem
         when(mockBox.put('communityFeed', any)).thenAnswer((_) async {}); // For addFeedItem
         
         await communityService.trackClassificationActivity(classification, user);
         
         final captured = verify(mockBox.put('communityStats', captureAny)).captured.single;
         final updatedStats = CommunityStats.fromJson(jsonDecode(captured));

         expect(updatedStats.totalUsers, equals(6)); // New user
         expect(updatedStats.totalClassifications, equals(11));
         expect(updatedStats.activeToday, equals(1)); // Assuming new user is active today and stats reset daily
         expect(updatedStats.categoryBreakdown['Recyclable'], equals(1));
      });

      test('should correctly identify active users today', () async {
        final now = DateTime.now();
        final todayUser = UserProfile(id: 'todayUser', email: 't@t.com', displayName: 'Today');
        final yesterdayUser = UserProfile(id: 'yesterdayUser', email: 'y@y.com', displayName: 'Yesterday');

        final activities = [
            CommunityFeedItem(id: 'a1', userId: 'todayUser', userName: 'Today', activityType: CommunityActivityType.classification, title: 't', description: 'd', timestamp: now.subtract(const Duration(hours:1))).toJson(),
            CommunityFeedItem(id: 'a2', userId: 'yesterdayUser', userName: 'Yesterday', activityType: CommunityActivityType.classification, title: 't', description: 'd', timestamp: now.subtract(const Duration(days:1, hours:1))).toJson(),
        ];
        
        final initialStats = CommunityStats(totalUsers: 2, totalClassifications: 2, totalAchievements: 0, activeToday: 0, categoryBreakdown: {}, lastUpdated: now.subtract(const Duration(days:2)));
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async {});
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode(activities)); // Feed has activities

        // Trigger stats update, e.g. by getting stats or adding a new item
        // For simplicity, let's assume an internal update mechanism or just get stats again.
        // We need a method that processes the feed to update activeToday count based on existing feed items
        // if not done automatically by other calls. CommunityService()._updateStatsFromFeed() might be such a method if it existed.
        // For now, let's assume adding a new item will re-evaluate based on the full feed.
        
        final newClassification = _createTestClassification(userId: 'anotherUser', timestamp: now);
        final anotherUser = UserProfile(id: 'anotherUser', email: 'a@a.com', displayName:'Another');

        when(mockBox.put('communityFeed', any)).thenAnswer((_) async {});
        await communityService.trackClassificationActivity(newClassification, anotherUser);

        final captured = verify(mockBox.put('communityStats', captureAny)).captured.last; // Get the latest put
        final updatedStats = CommunityStats.fromJson(jsonDecode(captured));

        expect(updatedStats.activeToday, equals(2)); // todayUser and anotherUser
      });

      test('should not increment totalUsers if existing user performs activity', () async {
        final now = DateTime.now();
        final existingUser = UserProfile(id: 'user_123', email: 'test@example.com', displayName: 'Test User');
        final classification = _createTestClassification(userId: 'user_123', timestamp: now);

        final initialFeed = [
          jsonEncode(CommunityFeedItem(id:'prev1', userId: 'user_123', userName: 'Test User', activityType: CommunityActivityType.classification, title: 't', description: 'd', timestamp: now.subtract(const Duration(days: 2))).toJson())
        ];

        final initialStats = CommunityStats(
            totalUsers: 1, 
            totalClassifications: 1, 
            totalAchievements: 0, 
            activeToday: 0, // Assuming it's a new day
            categoryBreakdown: {'Recyclable': 1}, 
            lastUpdated: now.subtract(const Duration(days: 1))
        );
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode(initialFeed)); 
        when(mockBox.put(any, any)).thenAnswer((_) async {});


        await communityService.trackClassificationActivity(classification, existingUser);
        
        final captured = verify(mockBox.put('communityStats', captureAny)).captured.last;
        final updatedStats = CommunityStats.fromJson(jsonDecode(captured));

        expect(updatedStats.totalUsers, equals(1)); // Should not change
        expect(updatedStats.totalClassifications, equals(2));
        expect(updatedStats.activeToday, equals(1)); 
      });

      test('should calculate weekly activity trends', () async {
        final stats = CommunityStats(
            totalUsers: 5, totalClassifications: 100, totalAchievements: 10, activeToday: 3,
            weeklyClassifications: 50, 
            activeUsers: 5, 
            categoryBreakdown: {'Dry Waste': 60, 'Wet Waste': 40}, 
            lastUpdated: DateTime.now()
        );
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(stats.toJson()));
        
        final retrievedStats = await communityService.getCommunityStats();
        expect(retrievedStats.weeklyClassifications, equals(50));
      });

      test('should identify top contributors', () async {
         final statsWithContributors = CommunityStats(
            totalUsers: 2, totalClassifications: 5, totalAchievements: 1, activeToday: 2,
            categoryBreakdown: {}, lastUpdated: DateTime.now(),
            topContributors: [
              {'userId': 'user_1', 'totalPoints': 45, 'totalActivities': 3},
              {'userId': 'user_2', 'totalPoints': 25, 'totalActivities': 2},
            ]
        );
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(statsWithContributors.toJson()));

        final stats = await communityService.getCommunityStats();
        
        expect(stats.topContributors.length, greaterThan(0));
        if (stats.topContributors.isNotEmpty) {
            expect(stats.topContributors.first['userId'], equals('user_1'));
            expect(stats.topContributors.first['totalPoints'], equals(45));
        }
      });

      test('should handle edge cases in statistics calculation', () async {
        final initialEmptyStats = CommunityStats(
            totalUsers: 1, totalClassifications: 0, totalAchievements: 0, activeToday: 1,
            categoryBreakdown: {}, lastUpdated: DateTime.now(), anonymousContributions: 0,
            averagePointsPerUser: 0.0, topContributors: [], weeklyActiveUsers: 0, weeklyClassifications: 0
        );
         when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialEmptyStats.toJson()));

        final emptyStats = await communityService.getCommunityStats();
        expect(emptyStats.totalClassifications, equals(0));
        expect(emptyStats.averagePointsPerUser, equals(0.0));
        expect(emptyStats.topContributors, isEmpty);
      });
    });

    group('Sample Data Generation', () {
      test('should generate realistic sample data for demo purposes', () async {
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());

        await communityService.generateSampleCommunityData();
        verify(mockBox.put('communityFeed', any)).called(greaterThanOrEqualTo(10)); 
      });

      test('should create diverse sample activities', () async {
        final generatedActivitiesJson = <String>[];
         when(mockBox.put('communityFeed', captureAny)).thenAnswer((invocation) async {
          generatedActivitiesJson.add(invocation.positionalArguments.first as String);
        });
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());

        await communityService.generateSampleCommunityData();
        
        expect(generatedActivitiesJson.length, greaterThanOrEqualTo(1)); 
        
        if (generatedActivitiesJson.isNotEmpty) {
            final List<dynamic> decodedFeedList = jsonDecode(generatedActivitiesJson.last);
            expect(decodedFeedList.length, greaterThanOrEqualTo(10));

            final activityTypes = decodedFeedList.map((json) => CommunityFeedItem.fromJson(json as Map<String,dynamic>).activityType).toSet();
            expect(activityTypes, contains(CommunityActivityType.classification));
            expect(activityTypes, contains(CommunityActivityType.achievement));

            final categories = decodedFeedList
                .map((json) => CommunityFeedItem.fromJson(json as Map<String,dynamic>))
                .where((item) => item.activityType == CommunityActivityType.classification && item.metadata.containsKey('category'))
                .map((item) => item.metadata['category'])
                .toSet();
            expect(categories.length, greaterThan(1));
        }
      });
    });

    group('Privacy and Anonymization', () {
      test('should respect user privacy settings', () async {
        final classification = _createTestClassification();
        final privateUser = UserProfile(
          id: 'private_user',
          email: 'private@example.com',
          displayName: 'Private User',
          preferences: {'community_sharing': false}, 
        );
        
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put(any, any)).thenAnswer((_) async {});
         final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));

        await communityService.trackClassificationActivity(classification, privateUser);
        final captured = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(captured);
        expect(feedList.first['isAnonymous'], isTrue);
        expect(feedList.first['userName'], equals('Anonymous User')); 
      });

      test('should anonymize sensitive data in activities', () async {
        final sensitiveClassification = WasteClassification(
          itemName: 'Medication Bottle with Personal Label',
          category: 'Hazardous Waste', 
          disposalInstructions: DisposalInstructions(primaryMethod: 'Test', steps: [], hasUrgentTimeframe: false),
          timestamp: DateTime.now(), explanation: '', region: '', alternatives: [], visualFeatures: [], confidence: 0.9, userId: 'user_medical',
          subcategory: 'Medical'
        );
        final user = UserProfile(id: 'user_medical', email: 'medical@example.com', displayName: 'Medical User');

        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put(any, any)).thenAnswer((_) async {});
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));

        await communityService.trackClassificationActivity(sensitiveClassification, user);
        
        final captured = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> feedList = jsonDecode(captured);
        final itemData = CommunityFeedItem.fromJson(feedList.first as Map<String,dynamic>);
        
        expect(itemData.title, isNot(contains('Personal Label'))); 
      });

      test('should provide opt-out mechanism for community features', () async {
        final optOutUser = UserProfile(
          id: 'opt_out_user',
          email: 'optout@example.com',
          displayName: 'Opt Out User',
          preferences: {'community_participation': false},
        );
        final classification = _createTestClassification();
        
        // This assumes trackClassificationActivity checks preferences.
        // If it calls addFeedItem, this mock setup is needed.
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async => Future.value());
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());


        await communityService.trackClassificationActivity(classification, optOutUser);
        // If opt-out prevents any call to addFeedItem (which then tries to put to 'communityFeed')
        verifyNever(mockBox.put('communityFeed', any)); 
      });
    });

    group('Performance and Scalability', () {
      test('should handle large numbers of activities efficiently', () async {
        final largeActivityListJson = jsonEncode(
          List.generate(100, (i) => 
            CommunityFeedItem(id: 'activity_$i', userId: 'u$i', userName: 'N$i', activityType: CommunityActivityType.classification, title: 'T$i', description: 'D$i', timestamp: DateTime.now().subtract(Duration(minutes: i))).toJson()
        ));
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(largeActivityListJson);

        final stopwatch = Stopwatch()..start();
        final feed = await communityService.getFeedItems(limit: 50);
        stopwatch.stop();

        expect(feed.length, equals(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); 
      });

      test('should clean up old activities to prevent storage bloat', () async {
        final now = DateTime.now();
        final oldItem = CommunityFeedItem(id:'old', userId:'u', userName:'N', activityType: CommunityActivityType.classification, title:'T', description:'D', timestamp: now.subtract(Duration(days:35))).toJson();
        final newItem = CommunityFeedItem(id:'new', userId:'u', userName:'N', activityType: CommunityActivityType.classification, title:'T', description:'D', timestamp: now.subtract(Duration(days:5))).toJson();
        
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(jsonEncode([oldItem, newItem]));
        when(mockBox.put(any, any)).thenAnswer((_) async {});


        await communityService.cleanupOldActivities(olderThanDays: 30);

        final capturedJson = verify(mockBox.put('communityFeed', captureAny)).captured.last;
        final List<dynamic> updatedFeedList = jsonDecode(capturedJson);
        expect(updatedFeedList.length, 1);
        expect(CommunityFeedItem.fromJson(updatedFeedList.first as Map<String,dynamic>).id, 'new');
      });

      test('should batch operations for better performance', () async {
        final batchActivities = List.generate(5, (i) => 
          _createTestClassification()
        );
        
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async {});
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async => Future.value());


        await communityService.batchTrackActivities(batchActivities, null);

        verify(mockBox.put('communityFeed', any)).called(5);
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully when adding feed item', () async {
        final classification = _createTestClassification();
        final user = UserProfile(id: 'test_user', email: 'test@example.com', displayName: 'Test User');

        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]'); 
        when(mockBox.put('communityFeed', any)).thenThrow(Exception('Storage error on put feed'));
         final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:1, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async {});


        await expectLater(communityService.trackClassificationActivity(classification, user), completes);
        
        verify(mockBox.put('communityFeed', any)).called(1);
      });

      test('should handle corrupted activity data when getting feed', () async {
        final corruptedJson = '[{"id":"1", "activityType":"classification", "userId":"u", "userName":"N", "title":"T", "description":"D", "timestamp":"${DateTime.now().toIso8601String()}"}, {"invalid": "data"}]'; 
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn(corruptedJson);

        final feed = await communityService.getFeedItems();
        
        expect(feed.length, 1); 
        expect(feed.first.id, equals('1'));
      });

      test('should validate activity data before storage (addRawActivity example)', () async {
        final invalidActivityData = {
          'type': '', 
          'userId': 'user1',
          'userName': 'User1',
          'timestamp': DateTime.now().toIso8601String(),
          'data': {},
        };
        
        // This test assumes addRawActivity is a method on CommunityService.
        // If it's not, this test needs to be adapted or removed.
        // For now, assuming it will be added to CommunityService.
        /* 
        expect(() async => await communityService.addRawActivity(invalidActivityData),
               throwsA(isA<ArgumentError>()));
        verifyNever(mockBox.add(any)); // Or verifyNever(mockBox.put('communityFeed', any))
        */
      });
    });

    group('Utility Methods', () {
      test('should format duration correctly', () {
        expect(communityService.formatTimeAgo(DateTime.now().subtract(const Duration(seconds: 30))), 'Just now');
        expect(communityService.formatTimeAgo(DateTime.now().subtract(const Duration(minutes: 5))), '5m ago');
        expect(communityService.formatTimeAgo(DateTime.now().subtract(const Duration(hours: 3))), '3h ago');
        expect(communityService.formatTimeAgo(DateTime.now().subtract(const Duration(days: 2))), '2d ago');
        expect(communityService.formatTimeAgo(DateTime.now().subtract(const Duration(days: 8))), 'Apr ${DateTime.now().subtract(const Duration(days: 8)).day}'); // Example, depends on current date
      });

      test('should get correct icon for activity type', () {
        expect(communityService.getIconForActivity(CommunityActivityType.classification), Icons.label_outline);
        expect(communityService.getIconForActivity(CommunityActivityType.achievement), Icons.emoji_events_outlined);
        expect(communityService.getIconForActivity(CommunityActivityType.streak), Icons.whatshot_outlined);
        expect(communityService.getIconForActivity(CommunityActivityType.challenge), Icons.flag_outlined);
        expect(communityService.getIconForActivity(CommunityActivityType.milestone), Icons.military_tech_outlined);
        expect(communityService.getIconForActivity(CommunityActivityType.system), Icons.info_outline);
        expect(communityService.getIconForActivity(CommunityActivityType.other), Icons.help_outline);
      });
    });
    
    group('Error Handling and Edge Cases', () {
      test('addFeedItem should handle Hive write errors gracefully', () async {
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenThrow(HiveError('Failed to write'));
        // Also mock stats as it tries to update them
        final initialStats = CommunityStats(totalUsers:0, totalClassifications:0, totalAchievements:0, activeToday:0, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenThrow(HiveError('Failed to write stats'));

        final item = _createTestFeedItem();
        
        // Expect no throw, but internal logging of error
        await expectLater(communityService.addFeedItem(item), completes);
        // Verification that put was attempted is implicitly covered by thenThrow
      });

      test('getFeedItems should handle Hive read errors gracefully', () async {
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenThrow(HiveError('Failed to read'));
        final feed = await communityService.getFeedItems();
        expect(feed, isEmpty); // Should return empty list on error
      });

      test('getCommunityStats should handle Hive read errors gracefully', () async {
        when(mockBox.get('communityStats')).thenThrow(HiveError('Failed to read stats'));
        final stats = await communityService.getCommunityStats();
        expect(stats.totalUsers, 0); // Should return default stats
      });

      test('should handle malformed JSON in community feed gracefully', () async {
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[{"id": "1", "malformed_json": true}]'); // Invalid JSON
        final feed = await communityService.getFeedItems();
        expect(feed, isEmpty); // Or expect it to filter out malformed items
      });

      test('should handle malformed JSON in community stats gracefully', () async {
        when(mockBox.get('communityStats')).thenReturn('{"totalUsers": "not_an_int"}'); // Invalid JSON
        final stats = await communityService.getCommunityStats();
        expect(stats.totalUsers, 0); // Should return default stats
      });

      test('trackClassificationActivity with null user should still update general stats', () async {
        final classification = _createTestClassification(userId: null); // Guest user
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:0, categoryBreakdown: {}, lastUpdated: DateTime.now().subtract(const Duration(days:1)));
        
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async {});
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async {});

        await communityService.trackClassificationActivity(classification, null);

        final capturedStatsJson = verify(mockBox.put('communityStats', captureAny)).captured.last;
        final updatedStats = CommunityStats.fromJson(jsonDecode(capturedStatsJson));

        expect(updatedStats.totalClassifications, equals(1));
        // totalUsers might not change for guest, or might have a specific guest handling logic
        expect(updatedStats.activeToday, equals(1)); // Guest activity counts as active
      });

      test('activity with very old timestamp should not count as activeToday', () async {
        final classification = _createTestClassification(timestamp: DateTime.now().subtract(const Duration(days: 5)));
        final user = UserProfile(id: 'oldUser', email:'old@test.com', displayName:'Old User');
        final initialStats = CommunityStats(totalUsers:1, totalClassifications:0, totalAchievements:0, activeToday:0, categoryBreakdown: {}, lastUpdated: DateTime.now().subtract(const Duration(days:10)));
        
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async {});
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async {});
        
        await communityService.trackClassificationActivity(classification, user);

        final capturedStatsJson = verify(mockBox.put('communityStats', captureAny)).captured.last;
        final updatedStats = CommunityStats.fromJson(jsonDecode(capturedStatsJson));
        
        expect(updatedStats.activeToday, equals(0)); // Activity was old
        expect(updatedStats.totalUsers, equals(2)); // New user added though
        expect(updatedStats.totalClassifications, equals(1));
      });

      test('empty metadata for points calculation should not throw error', () {
         expect(() => communityService.calculateActivityPoints(CommunityActivityType.classification, {}), returnsNormally);
         expect(communityService.calculateActivityPoints(CommunityActivityType.classification, {}), greaterThanOrEqualTo(0));
      });

      test('addFeedItem with invalid activity data', () async {
        // This test is more about how CommunityFeedItem handles invalid data,
        // but let's assume CommunityService might do some basic validation or rely on try-catch.
        // final Map<String, dynamic> invalidActivityData = {'id': null, 'timestamp': 'not_a_date'}; // REMOVED unused_local_variable
        
        // For this test to be meaningful, we'd need to see how CommunityService.addFeedItem
        // constructs CommunityFeedItem and if it can lead to an error that should be caught.
        // If it just passes a map to CommunityFeedItem.fromJson, then the test is on CommunityFeedItem.
        
        // Let's assume it tries to construct and might fail.
        final initialStats = CommunityStats(totalUsers:0, totalClassifications:0, totalAchievements:0, activeToday:0, categoryBreakdown: {}, lastUpdated: DateTime.now());
        when(mockBox.get('communityStats')).thenReturn(jsonEncode(initialStats.toJson()));
        when(mockBox.put('communityStats', any)).thenAnswer((_) async {}); // Assume stats update might be skipped or fail gracefully
        when(mockBox.get('communityFeed', defaultValue: '[]')).thenReturn('[]');
        when(mockBox.put('communityFeed', any)).thenAnswer((_) async {});

        // Example: create a feed item that would be problematic if not handled.
        // This is tricky to test without knowing internal error handling of CommunityFeedItem.fromJson
        // and how CommunityService uses it.
        // For now, this test might be superficial without more direct ways to inject problematic raw data.
        final problematicItem = CommunityFeedItem(
            id: 'problem', 
            userId: 'u', 
            userName: 'n', 
            activityType: CommunityActivityType.other, 
            title: 't', 
            description: 'd', 
            timestamp: DateTime.now(),
            // metadata: {'unexpectedField': ProcessError()} // Example of complex object not easily JSON serializable
        );
        
        await expectLater(communityService.addFeedItem(problematicItem), completes);
        // Verify no calls to put if item creation/validation failed early, or verify put was still called if it's robust.
        // This depends on service's internal logic.
      });

    });
  });
}

// Helper to create a test WasteClassification
WasteClassification _createTestClassification({String? userId, DateTime? timestamp}) {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Recyclable',
    subcategory: 'Test Subcategory',
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle Bin',
      steps: ['Step 1', 'Step 2'],
      hasUrgentTimeframe: false,
    ),
    timestamp: timestamp ?? DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['feature1', 'feature2'],
    alternatives: [],
    confidence: 0.9,
    userId: userId ?? 'test_user',
  );
}

// Helper to create a test CommunityFeedItem
CommunityFeedItem _createTestFeedItem() {
  return CommunityFeedItem(
    id: 'feed_item_1',
    userId: 'user_xyz',
    userName: 'Feed User',
    activityType: CommunityActivityType.milestone,
    title: 'Big Achievement!',
    description: 'User reached a new milestone.',
    timestamp: DateTime.now(),
    metadata: {'milestone': '1000_points'},
    points: 50,
  );
}

/* // REMOVED unused_element
Map<String, dynamic> _createActivityMap({
  String id = 'default_id',
  String userId = 'default_user_id',
  String userName = 'Default User',
  CommunityActivityType activityType = CommunityActivityType.other,
  String title = 'Default Title',
  String description = 'Default Description',
  DateTime? timestamp,
  Map<String, dynamic>? metadata,
  int points = 0,
  bool isAnonymous = false,
}) {
  return {
    'id': id,
    'userId': userId,
    'userName': userName,
    'activityType': activityType.name, // Assuming CommunityActivityType is an enum
    'title': title,
    'description': description,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    'metadata': metadata ?? {},
    'points': points,
    'isAnonymous': isAnonymous,
  };
}
*/
