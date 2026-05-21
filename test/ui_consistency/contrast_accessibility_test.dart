import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/widgets/home_header.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

import '../helpers/component_test_harness.dart';

void main() {
  group('Contrast and accessibility tests', () {
    testWidgets('HomeHeader exposes the expected semantics labels',
        (tester) async {
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
              achievements: const [],
              discoveredItemIds: const [],
              unlockedHiddenContentIds: const [],
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
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(480, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: HomeHeader()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.bySemanticsLabel('User avatar for John Doe'), findsOneWidget);
      expect(find.bySemanticsLabel('Current points: 1250'), findsOneWidget);
      expect(find.bySemanticsLabel('2 unread notifications'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Current streak: 7 days'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Today\'s goal progress: 3 out of 10 items completed',
        ),
        findsOneWidget,
      );
    });

    testWidgets('HomeHeader chip colors clear the WCAG AA threshold',
        (tester) async {
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
              achievements: const [],
              discoveredItemIds: const [],
              unlockedHiddenContentIds: const [],
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
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(480, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: HomeHeader()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final context = tester.element(find.byType(HomeHeader));
      final theme = Theme.of(context);

      final goalLabel = tester.widget<Text>(find.text("TODAY'S GOAL"));
      final goalValue = tester.widget<Text>(find.text('3/10 items'));
      final streakLabel = tester.widget<Text>(find.text('7-day streak'));

      final goalLabelColor = goalLabel.style?.color ?? theme.colorScheme.onSurfaceVariant;
      final goalValueColor = goalValue.style?.color ?? theme.colorScheme.onSurface;
      final streakColor = streakLabel.style?.color ?? Colors.grey.shade700;

      final cardBackground = Color.alphaBlend(
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        theme.colorScheme.surface,
      );

      expect(
        _contrastRatio(goalLabelColor, cardBackground),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'Goal label should stay readable against the home card surface',
      );
      expect(
        _contrastRatio(goalValueColor, cardBackground),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'Goal progress value should stay readable against the card surface',
      );
      expect(
        _contrastRatio(streakColor, const Color(0xFFFFF2E5)),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'Streak chip text should remain readable against its badge color',
      );
    });

    testWidgets('ModernButton filled style keeps accessible contrast',
        (tester) async {
      await pumpComponent(
        tester,
        const ModernButton(
          text: 'Scan now',
          onPressed: _noop,
        ),
        surfaceSize: const Size(360, 240),
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Scan now'),
      );
      final theme = Theme.of(tester.element(find.byType(ModernButton)));
      final background = button.style?.backgroundColor?.resolve(<WidgetState>{}) ??
          theme.colorScheme.primary;
      final foreground = button.style?.foregroundColor?.resolve(<WidgetState>{}) ??
          Colors.white;

      expect(
        _contrastRatio(foreground, background),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'Filled buttons should keep WCAG AA contrast by default',
      );
    });

    testWidgets('PremiumFeatureCard disabled state remains legible',
        (tester) async {
      const feature = PremiumFeature(
        id: 'advanced_analytics',
        title: 'Advanced Analytics',
        description: 'Detailed insights into waste management patterns.',
        icon: 'bar_chart',
        route: '/analytics',
        isEnabled: false,
      );

      await pumpComponent(
        tester,
        PremiumFeatureCard(
          feature: feature,
          isEnabled: false,
        ),
        surfaceSize: const Size(360, 240),
      );

      final titleText = tester.widget<Text>(find.text('Advanced Analytics'));
      final descriptionText = tester.widget<Text>(
        find.text('Detailed insights into waste management patterns.'),
      );

      expect(
        titleText.style?.color,
        isNotNull,
        reason: 'Disabled feature titles should still have a visible text color',
      );
      expect(
        descriptionText.style?.color,
        isNotNull,
        reason:
            'Disabled feature descriptions should still have a visible text color',
      );
      expect(tester.takeException(), isNull);
    });
  });
}

double _contrastRatio(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  return (lighter + 0.05) / (darker + 0.05);
}

void _noop() {}
