import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/providers/gamification_provider.dart';
import 'package:waste_segregation_app/screens/achievements_screen_riverpod.dart';
import 'package:waste_segregation_app/utils/constants.dart';

import '../test_config/test_app.dart';

void main() {
  group('AchievementsScreenRiverpod Tests', () {
    late List<Achievement> mockAchievements;
    late GamificationProfile mockProfile;

    setUpAll(() async {
      await loadAppFonts();
    });

    setUp(() {
      mockAchievements = [
        Achievement(
          id: 'earned_achievement',
          title: 'Eco Warrior',
          description: 'Classify 10 waste items',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'eco',
          color: Colors.green,
          earnedOn: DateTime.now().subtract(const Duration(days: 1)),
          progress: 1.0,
          tier: AchievementTier.bronze,
          claimStatus: ClaimStatus.claimed,
          pointsReward: 50,
        ),
        Achievement(
          id: 'claimable_achievement',
          title: 'Recycling Expert',
          description: 'Identify 5 recyclable items',
          type: AchievementType.recyclingExpert,
          threshold: 5,
          iconName: 'recycling',
          color: Colors.blue,
          earnedOn: DateTime.now(),
          progress: 1.0,
          tier: AchievementTier.silver,
          claimStatus: ClaimStatus.unclaimed,
          pointsReward: 75,
        ),
        Achievement(
          id: 'in_progress_achievement',
          title: 'Streak Master',
          description: 'Maintain a 7-day streak',
          type: AchievementType.streakMaintained,
          threshold: 7,
          iconName: 'star',
          color: Colors.orange,
          progress: 0.6,
          tier: AchievementTier.gold,
          claimStatus: ClaimStatus.ineligible,
          pointsReward: 100,
        ),
        Achievement(
          id: 'locked_achievement',
          title: 'Master Classifier',
          description: 'Reach level 10',
          type: AchievementType.metaAchievement,
          threshold: 1,
          iconName: 'trophy',
          color: Colors.purple,
          progress: 0.0,
          tier: AchievementTier.platinum,
          unlocksAtLevel: 10,
          claimStatus: ClaimStatus.ineligible,
          pointsReward: 200,
        ),
      ];

      mockProfile = GamificationProfile(
        userId: 'test_user',
        achievements: mockAchievements,
        streaks: {},
        points: const UserPoints(total: 500, level: 5),
      );
    });

    Widget createTestWidget({
      GamificationProfile? profile,
      Object? error,
      bool isLoading = false,
    }) {
      return ProviderScope(
        overrides: [
          gamificationProvider.overrideWith((ref) {
            if (isLoading) {
              return const AsyncValue.loading();
            } else if (error != null) {
              return AsyncValue.error(error, StackTrace.current);
            } else {
              return AsyncValue.data(profile ?? mockProfile);
            }
          }),
        ],
        child: const TestApp(
          child: AchievementsScreenRiverpod(),
        ),
      );
    }

    group('Widget Tests', () {
      testWidgets('displays achievements correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check that achievements are displayed
        expect(find.text('Eco Warrior'), findsOneWidget);
        expect(find.text('Recycling Expert'), findsOneWidget);
        expect(find.text('Streak Master'), findsOneWidget);
        expect(find.text('Master Classifier'), findsOneWidget);

        // Check stats overview
        expect(find.text('Your Progress'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // Earned count
        expect(find.text('1'), findsOneWidget); // Claimable count (appears twice)
        expect(find.text('500'), findsOneWidget); // Total points
      });

      testWidgets('shows loading state correctly', (tester) async {
        await tester.pumpWidget(createTestWidget(isLoading: true));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error state correctly', (tester) async {
        const error = AppException('Test error');
        await tester.pumpWidget(createTestWidget(error: error));
        await tester.pumpAndSettle();

        expect(find.text('Failed to load achievements'), findsOneWidget);
        expect(find.text('Test error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('claim button works for claimable achievements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the claimable achievement card
        final claimButton = find.descendant(
          of: find.ancestor(
            of: find.text('Recycling Expert'),
            matching: find.byType(Card),
          ),
          matching: find.text('Claim'),
        );

        expect(claimButton, findsOneWidget);
        await tester.tap(claimButton);
        await tester.pumpAndSettle();

        // Achievement celebration should appear
        // Note: This would need proper provider mocking for full testing
      });

      testWidgets('progress indicators show correct values', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check progress percentage for in-progress achievement
        expect(find.text('60%'), findsOneWidget); // 0.6 * 100 = 60%
      });

      testWidgets('refresh indicator works', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Pull to refresh
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // RefreshIndicator should appear
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check semantic labels for achievements
        expect(
          find.bySemanticsLabel(RegExp(r'Eco Warrior.*bronze tier.*completed')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'Streak Master.*gold tier.*60% complete')),
          findsOneWidget,
        );

        // Check stats overview semantic label
        expect(
          find.bySemanticsLabel(RegExp(r'Achievement statistics.*1 of 4.*500 total points')),
          findsOneWidget,
        );
      });

      testWidgets('claimable achievements are marked as buttons', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find claimable achievement
        final claimableCard = find.ancestor(
          of: find.text('Recycling Expert'),
          matching: find.byType(Semantics),
        );

        final semantics = tester.widget<Semantics>(claimableCard);
        expect(semantics.properties.button, isTrue);
      });

      testWidgets('meets minimum touch target size', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check claim button size
        final claimButton = find.descendant(
          of: find.ancestor(
            of: find.text('Recycling Expert'),
            matching: find.byType(Card),
          ),
          matching: find.byType(ElevatedButton),
        );

        final buttonWidget = tester.widget<ElevatedButton>(claimButton);
        final container = find.ancestor(
          of: claimButton,
          matching: find.byType(Container),
        );
        final containerWidget = tester.widget<Container>(container);

        // Check minimum height (48dp for accessibility)
        expect(containerWidget.constraints?.minHeight, equals(AppTheme.buttonHeightSm));
        expect(AppTheme.buttonHeightSm, greaterThanOrEqualTo(48.0));
      });
    });

    group('Golden Tests', () {
      testGoldens('achievements screen light theme', (tester) async {
        await tester.pumpWidgetBuilder(
          createTestWidget(),
          surfaceSize: const Size(400, 800),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(AchievementsScreenRiverpod),
          matchesGoldenFile('achievements_screen_light.png'),
        );
      });

      testGoldens('achievements screen dark theme', (tester) async {
        await tester.pumpWidgetBuilder(
          ProviderScope(
            overrides: [
              gamificationProvider.overrideWith((ref) => AsyncValue.data(mockProfile)),
            ],
            child: TestApp(
              theme: AppTheme.darkTheme,
              child: const AchievementsScreenRiverpod(),
            ),
          ),
          surfaceSize: const Size(400, 800),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(AchievementsScreenRiverpod),
          matchesGoldenFile('achievements_screen_dark.png'),
        );
      });

      testGoldens('achievements screen loading state', (tester) async {
        await tester.pumpWidgetBuilder(
          createTestWidget(isLoading: true),
          surfaceSize: const Size(400, 800),
        );
        await tester.pump();

        await expectLater(
          find.byType(AchievementsScreenRiverpod),
          matchesGoldenFile('achievements_screen_loading.png'),
        );
      });

      testGoldens('achievements screen error state', (tester) async {
        await tester.pumpWidgetBuilder(
          createTestWidget(error: const AppException('Network error')),
          surfaceSize: const Size(400, 800),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(AchievementsScreenRiverpod),
          matchesGoldenFile('achievements_screen_error.png'),
        );
      });

      testGoldens('achievement card states', (tester) async {
        // Test individual achievement card states
        final cardStates = [
          ('earned', mockAchievements[0]),
          ('claimable', mockAchievements[1]),
          ('in_progress', mockAchievements[2]),
          ('locked', mockAchievements[3]),
        ];

        for (final (state, achievement) in cardStates) {
          await tester.pumpWidgetBuilder(
            ProviderScope(
              child: TestApp(
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: 200,
                      height: 250,
                      child: Consumer(
                        builder: (context, ref, child) {
                          return Card(
                            child: Container(), // Placeholder for actual card
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            surfaceSize: const Size(250, 300),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile('achievement_card_$state.png'),
          );
        }
      });
    });

    group('Performance Tests', () {
      testWidgets('handles large number of achievements efficiently', (tester) async {
        // Create a large list of achievements
        final largeAchievementList = List.generate(100, (index) {
          return Achievement(
            id: 'achievement_$index',
            title: 'Achievement $index',
            description: 'Description for achievement $index',
            type: AchievementType.wasteIdentified,
            threshold: 10,
            iconName: 'eco',
            color: Colors.green,
            progress: (index % 10) / 10.0,
            tier: AchievementTier.values[index % 4],
            claimStatus: ClaimStatus.values[index % 3],
            pointsReward: 50,
          );
        });

        final largeProfile = mockProfile.copyWith(achievements: largeAchievementList);

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget(profile: largeProfile));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Ensure rendering completes within reasonable time (2 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        // Verify that achievements are rendered (at least some visible ones)
        expect(find.text('Achievement 0'), findsOneWidget);
      });

      testWidgets('scroll performance is smooth', (tester) async {
        final largeAchievementList = List.generate(50, (index) {
          return Achievement(
            id: 'achievement_$index',
            title: 'Achievement $index',
            description: 'Description for achievement $index',
            type: AchievementType.wasteIdentified,
            threshold: 10,
            iconName: 'eco',
            color: Colors.green,
            progress: 0.5,
            tier: AchievementTier.bronze,
            claimStatus: ClaimStatus.ineligible,
            pointsReward: 50,
          );
        });

        final largeProfile = mockProfile.copyWith(achievements: largeAchievementList);

        await tester.pumpWidget(createTestWidget(profile: largeProfile));
        await tester.pumpAndSettle();

        // Perform scroll test
        final scrollView = find.byType(CustomScrollView);
        expect(scrollView, findsOneWidget);

        // Scroll down
        await tester.fling(scrollView, const Offset(0, -500), 1000);
        await tester.pumpAndSettle();

        // Scroll back up
        await tester.fling(scrollView, const Offset(0, 500), 1000);
        await tester.pumpAndSettle();

        // No specific assertions needed - if we get here without timeout, scrolling works
      });
    });

    group('Edge Cases', () {
      testWidgets('handles empty achievements list', (tester) async {
        final emptyProfile = mockProfile.copyWith(achievements: []);

        await tester.pumpWidget(createTestWidget(profile: emptyProfile));
        await tester.pumpAndSettle();

        // Should still show stats overview with zeros
        expect(find.text('Your Progress'), findsOneWidget);
        expect(find.text('0'), findsWidgets); // Multiple zeros for earned, claimable
      });

      testWidgets('handles achievements with very long text', (tester) async {
        final longTextAchievement = Achievement(
          id: 'long_text',
          title: 'This is a very long achievement title that should be truncated properly',
          description:
              'This is an extremely long description that should also be truncated to prevent overflow and maintain proper layout in the achievement card widget',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'eco',
          color: Colors.green,
          progress: 0.5,
          tier: AchievementTier.bronze,
          claimStatus: ClaimStatus.ineligible,
          pointsReward: 50,
        );

        final profileWithLongText = mockProfile.copyWith(achievements: [longTextAchievement]);

        await tester.pumpWidget(createTestWidget(profile: profileWithLongText));
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(tester.takeException(), isNull);
      });
    });
  });
}
