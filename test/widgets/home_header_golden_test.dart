import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/widgets/home_header.dart';

void main() {
  group('HomeHeader Golden Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Mock providers for consistent golden tests
          profileProvider.overrideWith((ref) async {
            return GamificationProfile(
              userId: 'test_user',
              points: const UserPoints(total: 1250),
              streaks: {
                StreakType.dailyClassification.toString(): StreakDetails(
                  type: StreakType.dailyClassification,
                  currentCount: 7,
                  longestCount: 14,
                  lastActivityDate: DateTime.now(),
                ),
              },
              achievements: [],
              discoveredItemIds: {},
              unlockedHiddenContentIds: {},
            );
          }),
          userProfileProvider.overrideWith((ref) async {
            return UserProfile(
              id: 'test_user',
              displayName: 'John Doe',
              email: 'john@example.com',
              createdAt: DateTime.now(),
            );
          }),
          todayGoalProvider.overrideWith((ref) async => (3, 10)),
          unreadNotificationsProvider.overrideWith((ref) async => 2),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testGoldens('HomeHeader - Light Theme - Default State', (tester) async {
      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: container,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(400, 200),
      );

      await screenMatchesGolden(tester, 'home_header_light_default');
    });

    testGoldens('HomeHeader - Dark Theme - Default State', (tester) async {
      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: container,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.dark(),
        ),
        surfaceSize: const Size(400, 200),
      );

      await screenMatchesGolden(tester, 'home_header_dark_default');
    });

    testGoldens('HomeHeader - High Points State', (tester) async {
      final highPointsContainer = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            return GamificationProfile(
              userId: 'test_user',
              points: const UserPoints(total: 25000), // High points for K formatting
              streaks: {
                StreakType.dailyClassification.toString(): StreakDetails(
                  type: StreakType.dailyClassification,
                  currentCount: 30,
                  longestCount: 45,
                  lastActivityDate: DateTime.now(),
                ),
              },
              achievements: [],
              discoveredItemIds: {},
              unlockedHiddenContentIds: {},
            );
          }),
          userProfileProvider.overrideWith((ref) async {
            return UserProfile(
              id: 'test_user',
              displayName: 'Jane Smith',
              email: 'jane@example.com',
              createdAt: DateTime.now(),
            );
          }),
          todayGoalProvider.overrideWith((ref) async => (10, 10)), // Goal completed
          unreadNotificationsProvider.overrideWith((ref) async => 0),
        ],
      );

      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: highPointsContainer,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(400, 200),
      );

      highPointsContainer.dispose();
      await screenMatchesGolden(tester, 'home_header_high_points');
    });

    testGoldens('HomeHeader - Loading State', (tester) async {
      final loadingContainer = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            // Simulate loading by never completing
            return Future.delayed(const Duration(seconds: 10), () => null);
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(400, 200),
      );

      // Pump once to show loading state
      await tester.pump();

      loadingContainer.dispose();
      await screenMatchesGolden(tester, 'home_header_loading');
    });

    testGoldens('HomeHeader - Error State', (tester) async {
      final errorContainer = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            throw Exception('Test error');
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: errorContainer,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(400, 200),
      );

      errorContainer.dispose();
      await screenMatchesGolden(tester, 'home_header_error');
    });

    testGoldens('HomeHeader - No User Profile', (tester) async {
      final noProfileContainer = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            return GamificationProfile(
              userId: 'guest_user',
              points: const UserPoints(total: 0),
              streaks: {},
              achievements: [],
              discoveredItemIds: {},
              unlockedHiddenContentIds: {},
            );
          }),
          userProfileProvider.overrideWith((ref) async => null), // No user profile
          todayGoalProvider.overrideWith((ref) async => (0, 10)),
          unreadNotificationsProvider.overrideWith((ref) async => 0),
        ],
      );

      await tester.pumpWidgetBuilder(
        UncontrolledProviderScope(
          container: noProfileContainer,
          child: const HomeHeader(),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(400, 200),
      );

      noProfileContainer.dispose();
      await screenMatchesGolden(tester, 'home_header_no_profile');
    });

    testGoldens('HomeHeader - Different Device Sizes', (tester) async {
      final deviceSizes = [
        ('small', const Size(320, 150)),
        ('medium', const Size(400, 200)),
        ('large', const Size(600, 250)),
      ];

      for (final (sizeLabel, size) in deviceSizes) {
        await tester.pumpWidgetBuilder(
          UncontrolledProviderScope(
            container: container,
            child: const HomeHeader(),
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData.light(),
          ),
          surfaceSize: size,
        );

        await screenMatchesGolden(tester, 'home_header_${sizeLabel}_device');
      }
    });
  });

  group('HomeHeader Accessibility Tests', () {
    testWidgets('HomeHeader has proper semantic labels', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            return GamificationProfile(
              userId: 'test_user',
              points: const UserPoints(total: 1250),
              streaks: {
                StreakType.dailyClassification.toString(): StreakDetails(
                  type: StreakType.dailyClassification,
                  currentCount: 7,
                  longestCount: 14,
                  lastActivityDate: DateTime.now(),
                ),
              },
              achievements: [],
              discoveredItemIds: {},
              unlockedHiddenContentIds: {},
            );
          }),
          userProfileProvider.overrideWith((ref) async {
            return UserProfile(
              id: 'test_user',
              displayName: 'John Doe',
              email: 'john@example.com',
              createdAt: DateTime.now(),
            );
          }),
          todayGoalProvider.overrideWith((ref) async => (3, 10)),
          unreadNotificationsProvider.overrideWith((ref) async => 2),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UncontrolledProviderScope(
              container: container,
              child: const HomeHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantic labels exist
      expect(find.text('Good morning, John'), findsOneWidget);
      expect(find.text('1.3K'), findsOneWidget); // Points formatted
      expect(find.text('7-day streak'), findsOneWidget);
      expect(find.text('3/10 items'), findsOneWidget);
      expect(find.text("TODAY'S GOAL"), findsOneWidget);

      container.dispose();
    });

    testWidgets('HomeHeader meets accessibility contrast requirements', (tester) async {
      // Test with high contrast theme
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async {
            return GamificationProfile(
              userId: 'test_user',
              points: const UserPoints(total: 1250),
              streaks: {},
              achievements: [],
              discoveredItemIds: {},
              unlockedHiddenContentIds: {},
            );
          }),
          userProfileProvider.overrideWith((ref) async => null),
          todayGoalProvider.overrideWith((ref) async => (3, 10)),
          unreadNotificationsProvider.overrideWith((ref) async => 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            // High contrast theme settings
          ),
          home: Scaffold(
            body: UncontrolledProviderScope(
              container: container,
              child: const HomeHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget renders without overflow or contrast issues
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });
}
