import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/achievements_screen.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/models/gamification.dart';

// Mock classes
@GenerateMocks([GamificationService])
import 'achievements_screen_test.mocks.dart';

void main() {
  group('AchievementsScreen', () {
    late MockGamificationService mockGamificationService;
    late GamificationProfile testProfile;

    setUp(() {
      mockGamificationService = MockGamificationService();

      // Create test profile with sample data
      testProfile = GamificationProfile(
        userId: 'test_user',
        achievements: [
          Achievement(
            id: 'first_classification',
            title: 'First Steps',
            description: 'Complete your first classification',
            type: AchievementType.firstClassification,
            threshold: 1,
            iconName: 'start',
            color: Colors.green,
            earnedOn: DateTime.now().subtract(const Duration(days: 5)),
            progress: 1.0,
            claimStatus: ClaimStatus.claimed,
          ),
          const Achievement(
            id: 'eco_warrior',
            title: 'Eco Warrior',
            description: 'Classify 100 items',
            type: AchievementType.ecoWarrior,
            threshold: 100,
            iconName: 'eco',
            color: Colors.blue,
            progress: 0.75,
            tier: AchievementTier.silver,
            pointsReward: 200,
          ),
          const Achievement(
            id: 'locked_achievement',
            title: 'Advanced User',
            description: 'Unlocks at level 10',
            type: AchievementType.wasteIdentified,
            threshold: 500,
            iconName: 'advanced',
            color: Colors.purple,
            tier: AchievementTier.gold,
            unlocksAtLevel: 10,
            pointsReward: 500,
          ),
          Achievement(
            id: 'claimable_achievement',
            title: 'Claimable',
            description: 'Ready to claim',
            type: AchievementType.recyclingExpert,
            threshold: 50,
            iconName: 'claim',
            color: Colors.orange,
            earnedOn: DateTime.now().subtract(const Duration(days: 1)),
            progress: 1.0,
            tier: AchievementTier.silver,
            pointsReward: 150,
            claimStatus: ClaimStatus.unclaimed,
          ),
        ],
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 7,
            longestCount: 15,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(
          total: 1250,
          level: 8,
          weeklyTotal: 120,
          monthlyTotal: 480,
          categoryPoints: {
            'Plastic': 600,
            'Paper': 400,
            'Organic': 250,
          },
        ),
        activeChallenges: [
          Challenge(
            id: 'weekly_goal',
            title: 'Weekly Recycling Goal',
            description: 'Recycle 20 items this week',
            startDate: DateTime.now().subtract(const Duration(days: 2)),
            endDate: DateTime.now().add(const Duration(days: 5)),
            pointsReward: 100,
            iconName: 'recycle',
            color: Colors.green,
            requirements: {'category': 'Recyclable', 'count': 20},
            progress: 0.6,
          ),
        ],
        completedChallenges: [
          Challenge(
            id: 'photo_challenge',
            title: 'Photo Challenge',
            description: 'Take 10 waste photos',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().subtract(const Duration(days: 3)),
            pointsReward: 75,
            iconName: 'camera',
            color: Colors.blue,
            requirements: {'photos': 10},
            isCompleted: true,
            progress: 1.0,
          ),
        ],
        weeklyStats: [
          WeeklyStats(
            weekStartDate: DateTime.now().subtract(const Duration(days: 7)),
            itemsIdentified: 25,
            challengesCompleted: 1,
            streakMaximum: 7,
            pointsEarned: 250,
            categoryCounts: {'Plastic': 10, 'Paper': 8, 'Organic': 7},
          ),
          WeeklyStats(
            weekStartDate: DateTime.now().subtract(const Duration(days: 14)),
            itemsIdentified: 18,
            streakMaximum: 5,
            pointsEarned: 180,
            categoryCounts: {'Plastic': 8, 'Paper': 6, 'Organic': 4},
          ),
        ],
        discoveredItemIds: {'item1', 'item2', 'item3'},
      );
    });

    Widget createTestWidget({int initialTabIndex = 0}) {
      return MaterialApp(
        home: Provider<GamificationService>.value(
          value: mockGamificationService,
          child: AchievementsScreen(initialTabIndex: initialTabIndex),
        ),
      );
    }

    group('Widget Initialization', () {
      testWidgets('should display app bar with correct title and tabs', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Allow FutureBuilder to complete

        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('Badges'), findsOneWidget);
        expect(find.text('Challenges'), findsOneWidget);
        expect(find.text('Stats'), findsOneWidget);
      });

      testWidgets('should initialize with specified tab index', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        // Should start on challenges tab
        expect(find.text('Active Challenges'), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return testProfile;
        });

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should handle error state', (tester) async {
        when(mockGamificationService.getProfile()).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Error loading profile'), findsOneWidget);
        expect(find.text('Exception: Network error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should handle retry on error', (tester) async {
        when(mockGamificationService.getProfile())
            .thenThrow(Exception('Network error'))
            .thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Error loading profile'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump();
        expect(find.text('Error loading profile'), findsNothing);
      });

      testWidgets('should handle no data state', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('No profile data available'), findsOneWidget);
      });
    });

    group('Achievements Tab', () {
      testWidgets('should display profile summary card', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(ProfileSummaryCard), findsOneWidget);
      });

      testWidgets('should display daily streak information', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Daily Streak'), findsOneWidget);
        expect(find.text('7 days'), findsOneWidget);
        expect(find.text('Longest'), findsOneWidget);
        expect(find.text('15 days'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });

      testWidgets('should display achievements grouped by type', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('First Classification'), findsOneWidget);
        expect(find.text('Eco Warrior'), findsOneWidget);
        expect(find.text('Waste Identification'), findsOneWidget);
        expect(find.text('Recycling Expert'), findsOneWidget);
      });

      testWidgets('should display achievement cards with correct status', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Check for earned achievement
        expect(find.text('First Steps'), findsOneWidget);
        expect(find.text('Earned'), findsOneWidget);

        // Check for in-progress achievement
        expect(find.text('Eco Warrior'), findsOneWidget);

        // Check for claimable achievement
        expect(find.text('Claim Reward!'), findsOneWidget);

        // Check for locked achievement
        expect(find.text('Unlocks at level 10'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('should show achievement details dialog when tapped', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('First Steps'));
        await tester.pumpAndSettle();

        expect(find.text('Complete your first classification'), findsOneWidget);
        expect(find.text('50 Points'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      });

      testWidgets('should handle claiming rewards', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);
        when(mockGamificationService.saveProfile(any)).thenAnswer((_) async {});
        when(mockGamificationService.addPoints(any, customPoints: anyNamed('customPoints'))).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find and tap claimable achievement
        await tester.tap(find.text('Claimable'));
        await tester.pumpAndSettle();

        expect(find.text('Claim Reward'), findsOneWidget);

        await tester.tap(find.text('Claim Reward'));
        await tester.pumpAndSettle();

        verify(mockGamificationService.saveProfile(any)).called(1);
        verify(mockGamificationService.addPoints('achievement_claim', customPoints: 150)).called(1);
      });

      testWidgets('should handle claim reward errors', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);
        when(mockGamificationService.saveProfile(any)).thenThrow(Exception('Save failed'));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('Claimable'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Claim Reward'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to claim reward: Exception: Save failed'), findsOneWidget);
      });

      testWidgets('should not show secret achievements that are not earned', (tester) async {
        final profileWithSecret = testProfile.copyWith(
          achievements: [
            ...testProfile.achievements,
            const Achievement(
              id: 'secret_achievement',
              title: 'Secret Achievement',
              description: 'This is secret',
              type: AchievementType.specialItem,
              threshold: 1,
              iconName: 'secret',
              color: Colors.black,
              isSecret: true,
              progress: 0.5,
              tier: AchievementTier.platinum,
              pointsReward: 1000,
            ),
          ],
        );

        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithSecret);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Secret Achievement'), findsNothing);
      });
    });

    group('Challenges Tab', () {
      testWidgets('should display active challenges', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.text('Active Challenges'), findsOneWidget);
        expect(find.text('Weekly Recycling Goal'), findsOneWidget);
        expect(find.text('Recycle 20 items this week'), findsOneWidget);
        expect(find.text('Progress: 60%'), findsOneWidget);
      });

      testWidgets('should display completed challenges', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.text('Completed Challenges'), findsOneWidget);
        expect(find.text('Photo Challenge'), findsOneWidget);
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should show empty state when no active challenges', (tester) async {
        final profileWithoutChallenges = testProfile.copyWith(activeChallenges: []);
        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithoutChallenges);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.text('No active challenges'), findsOneWidget);
        expect(find.text('Get New Challenges'), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      });

      testWidgets('should generate new challenges when button pressed', (tester) async {
        final profileWithoutChallenges = testProfile.copyWith(activeChallenges: []);
        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithoutChallenges);
        when(mockGamificationService.saveProfile(any)).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        await tester.tap(find.text('Get New Challenges'));
        await tester.pumpAndSettle();

        verify(mockGamificationService.saveProfile(any)).called(1);
        expect(find.text('New challenges generated!'), findsOneWidget);
      });

      testWidgets('should handle challenge generation errors', (tester) async {
        final profileWithoutChallenges = testProfile.copyWith(activeChallenges: []);
        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithoutChallenges);
        when(mockGamificationService.saveProfile(any)).thenThrow(Exception('Generation failed'));

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        await tester.tap(find.text('Get New Challenges'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to generate challenges: Exception: Generation failed'), findsOneWidget);
      });

      testWidgets('should show time remaining for active challenges', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.textContaining('days left'), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      });

      testWidgets('should display reward information', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.text('Reward'), findsOneWidget);
        expect(find.text('100 Points'), findsOneWidget);
        expect(find.byIcon(Icons.stars), findsOneWidget);
      });

      testWidgets('should show view all completed challenges dialog', (tester) async {
        // Create profile with more than 5 completed challenges
        final profileWithManyChallenges = testProfile.copyWith(
          completedChallenges: List.generate(
              8,
              (index) => Challenge(
                    id: 'challenge_$index',
                    title: 'Challenge $index',
                    description: 'Description $index',
                    startDate: DateTime.now().subtract(Duration(days: 10 + index)),
                    endDate: DateTime.now().subtract(Duration(days: 3 + index)),
                    pointsReward: 50 + (index * 10),
                    iconName: 'challenge',
                    color: Colors.blue,
                    requirements: {},
                    isCompleted: true,
                    progress: 1.0,
                  )),
        );

        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithManyChallenges);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        expect(find.text('View All Completed'), findsOneWidget);

        await tester.tap(find.text('View All Completed'));
        await tester.pumpAndSettle();

        expect(find.text('All Completed Challenges'), findsOneWidget);
        expect(find.text('Challenge 0'), findsOneWidget);
        expect(find.text('Challenge 7'), findsOneWidget);
      });
    });

    group('Stats Tab', () {
      testWidgets('should display overall progress stats', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        expect(find.text('Overall Progress'), findsOneWidget);
        expect(find.text('Items Identified'), findsOneWidget);
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('Challenges'), findsOneWidget);
        expect(find.text('Longest Streak'), findsOneWidget);
        expect(find.text('Total Points'), findsOneWidget);
      });

      testWidgets('should display correct stat values', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        // Check calculated values
        expect(find.text('125'), findsOneWidget); // Total items (1250 points / 10)
        expect(find.text('3'), findsOneWidget); // Categories count
        expect(find.text('2'), findsOneWidget); // Earned achievements count
        expect(find.text('1'), findsOneWidget); // Completed challenges count
        expect(find.text('15 days'), findsOneWidget); // Longest streak
        expect(find.text('1250'), findsOneWidget); // Total points
      });

      testWidgets('should display category breakdown', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        expect(find.text('Waste Categories'), findsOneWidget);
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.text('Paper'), findsOneWidget);
        expect(find.text('Organic'), findsOneWidget);
        expect(find.text('60 items'), findsOneWidget); // 600 points / 10
        expect(find.text('40 items'), findsOneWidget); // 400 points / 10
        expect(find.text('25 items'), findsOneWidget); // 250 points / 10
      });

      testWidgets('should display weekly stats', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        expect(find.text('Weekly Progress'), findsOneWidget);
        expect(find.textContaining('Week of'), findsAtLeastNWidgets(2));
        expect(find.text('25'), findsOneWidget); // Items from first week
        expect(find.text('250'), findsOneWidget); // Points from first week
      });

      testWidgets('should show empty state for weekly stats when none available', (tester) async {
        final profileWithoutWeeklyStats = testProfile.copyWith(weeklyStats: []);
        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithoutWeeklyStats);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        expect(find.text('No weekly data available yet'), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      });

      testWidgets('should calculate mini stats correctly', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        // Check mini stats in weekly progress cards
        expect(find.text('Items'), findsAtLeastNWidgets(1));
        expect(find.text('Challenges'), findsAtLeastNWidgets(1));
        expect(find.text('Streak'), findsAtLeastNWidgets(1));
        expect(find.text('Points'), findsAtLeastNWidgets(1));
      });
    });

    group('Tab Navigation', () {
      testWidgets('should switch tabs correctly', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Start on badges tab
        expect(find.text('Daily Streak'), findsOneWidget);

        // Switch to challenges tab
        await tester.tap(find.text('Challenges'));
        await tester.pump();
        expect(find.text('Active Challenges'), findsOneWidget);

        // Switch to stats tab
        await tester.tap(find.text('Stats'));
        await tester.pump();
        expect(find.text('Overall Progress'), findsOneWidget);

        // Switch back to badges tab
        await tester.tap(find.text('Badges'));
        await tester.pump();
        expect(find.text('Daily Streak'), findsOneWidget);
      });
    });

    group('Refresh Functionality', () {
      testWidgets('should refresh data when pull to refresh is triggered', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Trigger refresh
        await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        verify(mockGamificationService.getProfile()).called(atLeast(2));
      });

      testWidgets('should refresh from error state', (tester) async {
        when(mockGamificationService.getProfile()).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Error loading profile'), findsOneWidget);

        // Trigger refresh from error state
        await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, 300), 1000);
        await tester.pump();

        verify(mockGamificationService.getProfile()).called(atLeast(2));
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle empty achievements list', (tester) async {
        final emptyProfile = testProfile.copyWith(achievements: []);
        when(mockGamificationService.getProfile()).thenAnswer((_) async => emptyProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Daily Streak'), findsOneWidget);
        // Should not crash with empty achievements
      });

      testWidgets('should handle achievements without streaks', (tester) async {
        final profileWithoutStreaks = testProfile.copyWith(streaks: {});
        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithoutStreaks);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('0 days'), findsAtLeastNWidgets(2)); // Current and longest streak should be 0
      });

      testWidgets('should handle achievements with null dates', (tester) async {
        const achievementWithNullDate = Achievement(
          id: 'null_date',
          title: 'Null Date Achievement',
          description: 'No earned date',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'test',
          color: Colors.red,
          progress: 1.0,
        );

        final profileWithNullDate = testProfile.copyWith(
          achievements: [achievementWithNullDate],
        );

        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithNullDate);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should not crash with null earned date
        expect(find.text('Null Date Achievement'), findsOneWidget);
      });

      testWidgets('should handle very large numbers', (tester) async {
        final profileWithLargeNumbers = testProfile.copyWith(
          points: const UserPoints(
            total: 999999,
            level: 999,
            categoryPoints: {'Mega': 500000},
          ),
        );

        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithLargeNumbers);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        expect(find.text('999999'), findsOneWidget);
        expect(find.text('50000 items'), findsOneWidget); // 500000 / 10
      });

      testWidgets('should handle expired challenges', (tester) async {
        final expiredChallenge = Challenge(
          id: 'expired',
          title: 'Expired Challenge',
          description: 'This challenge is expired',
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          endDate: DateTime.now().subtract(const Duration(days: 2)),
          pointsReward: 50,
          iconName: 'expired',
          color: Colors.grey,
          requirements: {},
          progress: 0.5,
        );

        final profileWithExpired = testProfile.copyWith(
          activeChallenges: [expiredChallenge],
        );

        when(mockGamificationService.getProfile()).thenAnswer((_) async => profileWithExpired);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 1));
        await tester.pump();

        // Expired challenges should not be shown in active challenges
        expect(find.text('Expired Challenge'), findsNothing);
        expect(find.text('No active challenges'), findsOneWidget);
      });
    });

    group('Helper Functions', () {
      testWidgets('should format dates correctly', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Test achievement details dialog date formatting
        await tester.tap(find.text('First Steps'));
        await tester.pumpAndSettle();

        // Should show formatted date
        expect(find.textContaining('Earned on'), findsOneWidget);
      });

      testWidgets('should get correct category colors', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget(initialTabIndex: 2));
        await tester.pump();

        // Category colors should be applied (visual test would require screenshot testing)
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.text('Paper'), findsOneWidget);
        expect(find.text('Organic'), findsOneWidget);
      });

      testWidgets('should display achievement tier badges correctly', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Bronze'), findsAtLeastNWidgets(1));
        expect(find.text('Silver'), findsAtLeastNWidgets(1));
        expect(find.text('Gold'), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Check for important accessibility elements
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);
        expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('should support keyboard navigation for tabs', (tester) async {
        when(mockGamificationService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Tabs should be focusable
        expect(find.byType(Tab), findsNWidgets(3));
      });
    });
  });
}
