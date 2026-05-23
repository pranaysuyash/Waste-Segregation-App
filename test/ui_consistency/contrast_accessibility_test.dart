import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

import '../helpers/component_test_harness.dart';

void main() {
  group('Contrast and accessibility tests', () {
    testWidgets('StatsCard stays readable on the light theme',
        (tester) async {
      await pumpComponent(
        tester,
        const StatsCard(
          title: 'Classifications',
          value: '1,234,567',
          subtitle: 'items',
          icon: Icons.analytics,
          trend: Trend.up,
        ),
        theme: ThemeData.light(),
        surfaceSize: const Size(320, 240),
      );

      final context = tester.element(find.byType(StatsCard));
      final theme = Theme.of(context);
      final titleText = tester.widget<Text>(find.text('Classifications'));
      final valueText = tester.widget<Text>(find.text('1,234,567'));
      final titleColor =
          titleText.style?.color ?? theme.colorScheme.onSurfaceVariant;
      final valueColor = valueText.style?.color ?? theme.colorScheme.onSurface;
      final background = theme.colorScheme.surface;

      expect(
        _contrastRatio(titleColor, background),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'StatsCard title should remain readable on the light theme',
      );
      expect(
        _contrastRatio(valueColor, background),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'StatsCard value should remain readable on the light theme',
      );
    });

    testWidgets('StatsCard stays readable on the dark theme',
        (tester) async {
      await pumpComponent(
        tester,
        const StatsCard(
          title: 'Streak',
          value: '365',
          subtitle: 'days',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        theme: ThemeData.dark(),
        surfaceSize: const Size(320, 240),
      );

      final context = tester.element(find.byType(StatsCard));
      final theme = Theme.of(context);
      final titleText = tester.widget<Text>(find.text('Streak'));
      final valueText = tester.widget<Text>(find.text('365'));
      final titleColor =
          titleText.style?.color ?? theme.colorScheme.onSurfaceVariant;
      final valueColor = valueText.style?.color ?? theme.colorScheme.onSurface;
      final background = theme.colorScheme.surface;

      expect(
        _contrastRatio(titleColor, background),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'StatsCard title should remain readable on the dark theme',
      );
      expect(
        _contrastRatio(valueColor, background),
        greaterThanOrEqualTo(GamificationConfig.kMinContrastRatio),
        reason: 'StatsCard value should remain readable on the dark theme',
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

      // Card title is 18px; PremiumLockWrapper overlay badge is 12px — target card title by size.
      final titleText = tester.widget<Text>(find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Advanced Analytics' && w.style?.fontSize == 18,
      ));
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
