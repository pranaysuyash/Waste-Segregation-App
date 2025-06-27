import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/community_screen.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

// Mock classes
@GenerateMocks([CommunityService, StorageService])
import 'community_screen_test.mocks.dart';

void main() {
  group('CommunityScreen', () {
    late MockCommunityService mockCommunityService;
    late MockStorageService mockStorageService;
    late List<CommunityFeedItem> testFeedItems;
    late CommunityStats testStats;
    late UserProfile testUserProfile;

    setUp(() {
      mockCommunityService = MockCommunityService();
      mockStorageService = MockStorageService();

      testUserProfile = const UserProfile(
        id: 'test_user_123',
        displayName: 'Test User',
        email: 'test@example.com',
      );

      testFeedItems = [
        CommunityFeedItem(
          id: 'feed_1',
          userId: 'user_1',
          userName: 'Alice Johnson',
          activityType: CommunityActivityType.classification,
          description: 'Classified a plastic bottle',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          points: 10,
          metadata: {'category': 'Plastic', 'item': 'bottle'},
        ),
        CommunityFeedItem(
          id: 'feed_2',
          userId: 'user_2',
          userName: 'Bob Smith',
          activityType: CommunityActivityType.achievement,
          description: 'Earned "Eco Warrior" achievement',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          points: 100,
          metadata: {'achievement': 'eco_warrior'},
        ),
        CommunityFeedItem(
          id: 'feed_3',
          userId: 'user_3',
          userName: 'Carol Davis',
          activityType: CommunityActivityType.streak,
          description: 'Reached a 7-day streak',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          points: 50,
          metadata: {'streak_days': 7},
        ),
        CommunityFeedItem(
          id: 'feed_4',
          userId: 'user_4',
          userName: 'David Wilson',
          activityType: CommunityActivityType.challenge,
          description: 'Completed weekly recycling challenge',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          points: 75,
          metadata: {'challenge': 'weekly_recycling'},
        ),
        CommunityFeedItem(
          id: 'feed_5',
          userId: 'user_5',
          userName: 'Eva Brown',
          activityType: CommunityActivityType.milestone,
          description: 'Reached 1000 total points',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          points: 200,
          metadata: {'milestone_points': 1000},
        ),
        CommunityFeedItem(
          id: 'feed_6',
          userId: 'user_6',
          userName: 'Frank Miller',
          activityType: CommunityActivityType.educational,
          description: 'Completed recycling basics course',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          points: 25,
          metadata: {'course': 'recycling_basics'},
        ),
      ];

      testStats = const CommunityStats(
        totalUsers: 150,
        totalClassifications: 5420,
        totalPoints: 54200,
        activeToday: 23,
        topCategories: {
          'Plastic': 2100,
          'Paper': 1800,
          'Organic': 1200,
          'Metal': 320,
        },
        weeklyGrowth: 12.5,
        averagePointsPerUser: 361,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<CommunityService>.value(value: mockCommunityService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: const CommunityScreen(),
        ),
      );
    }

    group('Initialization and Loading', () {
      testWidgets('should display app bar with correct title and tabs', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Allow FutureBuilder to complete

        expect(find.text('Community'), findsOneWidget);
        expect(find.byIcon(Icons.feed), findsOneWidget);
        expect(find.text('Feed'), findsOneWidget);
        expect(find.byIcon(Icons.leaderboard), findsOneWidget);
        expect(find.text('Stats'), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
        expect(find.text('Members'), findsOneWidget);
      });

      testWidgets('should show loading indicator initially', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return testUserProfile;
        });
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should load community data on initialization', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verify(mockCommunityService.initCommunity()).called(1);
        verify(mockCommunityService.getFeedItems()).called(1);
        verify(mockCommunityService.getStats()).called(1);
      });

      testWidgets('should generate sample data when feed is empty', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => []);
        when(mockCommunityService.generateSampleCommunityData()).thenAnswer((_) async {});
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        verify(mockCommunityService.generateSampleCommunityData()).called(1);
      });

      testWidgets('should handle loading errors gracefully', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenThrow(Exception('Storage error'));
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => []);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should not crash on error
        expect(find.byType(CommunityScreen), findsOneWidget);
      });

      testWidgets('should use guest user when profile is null', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => null);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should still load data with guest user
        verify(mockCommunityService.getFeedItems()).called(1);
      });
    });

    group('Feed Tab', () {
      testWidgets('should display feed items correctly', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Alice Johnson'), findsOneWidget);
        expect(find.text('Classified a plastic bottle'), findsOneWidget);
        expect(find.text('Bob Smith'), findsOneWidget);
        expect(find.text('Earned "Eco Warrior" achievement'), findsOneWidget);
        expect(find.text('Carol Davis'), findsOneWidget);
        expect(find.text('Reached a 7-day streak'), findsOneWidget);
      });

      testWidgets('should display correct activity icons for different types', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Classification
        expect(find.byIcon(Icons.emoji_events), findsOneWidget); // Achievement
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget); // Streak
        expect(find.byIcon(Icons.flag), findsOneWidget); // Challenge
        expect(find.byIcon(Icons.star), findsOneWidget); // Milestone
        expect(find.byIcon(Icons.school), findsOneWidget); // Educational
      });

      testWidgets('should display points correctly', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('+10 pts'), findsOneWidget);
        expect(find.text('+100 pts'), findsOneWidget);
        expect(find.text('+50 pts'), findsOneWidget);
        expect(find.text('+75 pts'), findsOneWidget);
        expect(find.text('+200 pts'), findsOneWidget);
        expect(find.text('+25 pts'), findsOneWidget);
      });

      testWidgets('should display relative time correctly', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.textContaining('minutes ago'), findsOneWidget);
        expect(find.textContaining('hours ago'), findsAtLeastNWidgets(1));
        expect(find.textContaining('days ago'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show empty state when no feed items', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => []);
        when(mockCommunityService.generateSampleCommunityData()).thenAnswer((_) async {});
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('No community activity yet'), findsOneWidget);
        expect(find.text('Start classifying items to see community activity!'), findsOneWidget);
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });

      testWidgets('should support pull to refresh', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(RefreshIndicator), findsOneWidget);

        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Should call load data again
        verify(mockCommunityService.getFeedItems()).called(atLeast(2));
      });

      testWidgets('should handle items with zero points', (tester) async {
        final itemsWithZeroPoints = [
          CommunityFeedItem(
            id: 'feed_zero',
            userId: 'user_zero',
            userName: 'Zero User',
            activityType: CommunityActivityType.classification,
            description: 'Started using the app',
            timestamp: DateTime.now(),
            metadata: {},
          ),
        ];

        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => itemsWithZeroPoints);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Zero User'), findsOneWidget);
        expect(find.text('Started using the app'), findsOneWidget);
        expect(find.textContaining('+0 pts'), findsNothing); // Should not show 0 points
      });
    });

    group('Stats Tab', () {
      testWidgets('should display community overview stats', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Switch to stats tab
        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('Community Overview'), findsOneWidget);
        expect(find.text('Total Members'), findsOneWidget);
        expect(find.text('150'), findsOneWidget);
        expect(find.text('Total Classifications'), findsOneWidget);
        expect(find.text('5420'), findsOneWidget);
        expect(find.text('Total Points Earned'), findsOneWidget);
        expect(find.text('54200'), findsOneWidget);
        expect(find.text('Active Today'), findsOneWidget);
        expect(find.text('23'), findsOneWidget);
      });

      testWidgets('should display popular categories', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('Popular Categories'), findsOneWidget);
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.text('2100 items'), findsOneWidget);
        expect(find.text('Paper'), findsOneWidget);
        expect(find.text('1800 items'), findsOneWidget);
        expect(find.text('Organic'), findsOneWidget);
        expect(find.text('1200 items'), findsOneWidget);
        expect(find.text('Metal'), findsOneWidget);
        expect(find.text('320 items'), findsOneWidget);
      });

      testWidgets('should handle null stats gracefully', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('No stats available'), findsOneWidget);
      });

      testWidgets('should handle empty categories gracefully', (tester) async {
        const statsWithEmptyCategories = CommunityStats(
          totalUsers: 10,
          totalClassifications: 50,
          totalPoints: 500,
          activeToday: 2,
          topCategories: {},
          weeklyGrowth: 0,
          averagePointsPerUser: 50,
        );

        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => statsWithEmptyCategories);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('Popular Categories'), findsOneWidget);
        // Should not crash with empty categories
      });
    });

    group('Members Tab', () {
      testWidgets('should display coming soon message', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Members'));
        await tester.pump();

        expect(find.text('Members Directory'), findsOneWidget);
        expect(find.text('Coming soon! View and connect with other community members.'), findsOneWidget);
        expect(find.byIcon(Icons.construction), findsOneWidget);
      });
    });

    group('Tab Navigation', () {
      testWidgets('should switch between tabs correctly', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Start on feed tab
        expect(find.text('Alice Johnson'), findsOneWidget);

        // Switch to stats tab
        await tester.tap(find.text('Stats'));
        await tester.pump();
        expect(find.text('Community Overview'), findsOneWidget);

        // Switch to members tab
        await tester.tap(find.text('Members'));
        await tester.pump();
        expect(find.text('Members Directory'), findsOneWidget);

        // Switch back to feed tab
        await tester.tap(find.text('Feed'));
        await tester.pump();
        expect(find.text('Alice Johnson'), findsOneWidget);
      });
    });

    group('Time Formatting', () {
      testWidgets('should format relative time correctly for various durations', (tester) async {
        final now = DateTime.now();
        final timeTestItems = [
          CommunityFeedItem(
            id: 'just_now',
            userId: 'user_1',
            userName: 'Just Now User',
            activityType: CommunityActivityType.classification,
            description: 'Just now activity',
            timestamp: now,
            points: 10,
            metadata: {},
          ),
          CommunityFeedItem(
            id: 'minutes_ago',
            userId: 'user_2',
            userName: 'Minutes User',
            activityType: CommunityActivityType.classification,
            description: 'Minutes ago activity',
            timestamp: now.subtract(const Duration(minutes: 5)),
            points: 10,
            metadata: {},
          ),
          CommunityFeedItem(
            id: 'hour_ago',
            userId: 'user_3',
            userName: 'Hour User',
            activityType: CommunityActivityType.classification,
            description: 'Hour ago activity',
            timestamp: now.subtract(const Duration(hours: 1)),
            points: 10,
            metadata: {},
          ),
          CommunityFeedItem(
            id: 'day_ago',
            userId: 'user_4',
            userName: 'Day User',
            activityType: CommunityActivityType.classification,
            description: 'Day ago activity',
            timestamp: now.subtract(const Duration(days: 1)),
            points: 10,
            metadata: {},
          ),
          CommunityFeedItem(
            id: 'days_ago',
            userId: 'user_5',
            userName: 'Days User',
            activityType: CommunityActivityType.classification,
            description: 'Days ago activity',
            timestamp: now.subtract(const Duration(days: 3)),
            points: 10,
            metadata: {},
          ),
        ];

        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => timeTestItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Just now'), findsOneWidget);
        expect(find.text('5 minutes ago'), findsOneWidget);
        expect(find.text('1 hour ago'), findsOneWidget);
        expect(find.text('1 day ago'), findsOneWidget);
        expect(find.text('3 days ago'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle community service errors gracefully', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenThrow(Exception('Community init failed'));
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => []);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should not crash on service error
        expect(find.byType(CommunityScreen), findsOneWidget);
      });

      testWidgets('should handle feed loading errors', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenThrow(Exception('Feed load failed'));
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show empty state or error state gracefully
        expect(find.byType(CommunityScreen), findsOneWidget);
      });

      testWidgets('should handle stats loading errors', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenThrow(Exception('Stats load failed'));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('No stats available'), findsOneWidget);
      });
    });

    group('Activity Colors and Icons', () {
      testWidgets('should display correct colors for different activity types', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // We can't easily test colors in widget tests, but we can verify that
        // the CircleAvatar widgets are present for each activity type
        expect(find.byType(CircleAvatar), findsNWidgets(testFeedItems.length));
      });
    });

    group('Large Data Sets', () {
      testWidgets('should handle large feed efficiently', (tester) async {
        final largeFeedItems = List.generate(
            100,
            (index) => CommunityFeedItem(
                  id: 'feed_$index',
                  userId: 'user_$index',
                  userName: 'User $index',
                  activityType: CommunityActivityType.values[index % CommunityActivityType.values.length],
                  description: 'Activity $index',
                  timestamp: DateTime.now().subtract(Duration(minutes: index)),
                  points: index * 5,
                  metadata: {},
                ));

        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => largeFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('User 0'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // Should be able to scroll through large list
        await tester.scrollUntilVisible(
          find.text('User 50'),
          100.0,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('User 50'), findsOneWidget);
      });

      testWidgets('should handle large stats efficiently', (tester) async {
        final largeStats = CommunityStats(
          totalUsers: 999999,
          totalClassifications: 5000000,
          totalPoints: 50000000,
          activeToday: 10000,
          topCategories: Map.fromEntries(List.generate(50, (index) => MapEntry('Category $index', 1000 - index))),
          weeklyGrowth: 25.7,
          averagePointsPerUser: 5000,
        );

        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => largeStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Stats'));
        await tester.pump();

        expect(find.text('999999'), findsOneWidget);
        expect(find.text('5000000'), findsOneWidget);
        expect(find.text('50000000'), findsOneWidget);
        expect(find.text('10000'), findsOneWidget);
      });
    });

    group('Widget Disposal', () {
      testWidgets('should dispose tab controller properly', (tester) async {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockCommunityService.initCommunity()).thenAnswer((_) async {});
        when(mockCommunityService.getFeedItems()).thenAnswer((_) async => testFeedItems);
        when(mockCommunityService.getStats()).thenAnswer((_) async => testStats);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(CommunityScreen), findsOneWidget);

        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Other Screen'))));

        // Should not crash during disposal
        expect(find.text('Other Screen'), findsOneWidget);
      });
    });
  });
}
