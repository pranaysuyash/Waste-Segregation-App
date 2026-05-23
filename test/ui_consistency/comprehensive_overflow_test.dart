import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

import '../helpers/component_test_harness.dart';

void main() {
  group('Comprehensive overflow tests', () {
    testWidgets('FeatureCard survives long copy on a narrow viewport',
        (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 240,
          child: FeatureCard(
            icon: Icons.analytics,
            title:
                'Very Long Analytics Dashboard Title That Should Not Overflow',
            subtitle:
                'Very long subtitle that still needs to fit gracefully inside the card layout.',
            onTap: _noop,
          ),
        ),
        surfaceSize: const Size(240, 400),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.textContaining('Very Long Analytics'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StatsCard row remains stable on small screens', (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 320,
          child: Row(
            children: const [
              Expanded(
                child: StatsCard(
                  title: 'Classifications',
                  value: '999,999',
                  icon: Icons.analytics,
                  trend: Trend.up,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: StatsCard(
                  title: 'Streak',
                  value: '365',
                  subtitle: 'days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(StatsCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PremiumFeatureCard remains stable under text scaling',
        (tester) async {
      await pumpComponent(
        tester,
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.15),
          ),
          child: const PremiumFeatureCard(
            feature: PremiumFeature(
              id: 'advanced_analytics',
              title: 'Advanced Analytics',
              description:
                  'Detailed insights into waste management patterns.',
              icon: 'bar_chart',
              route: '/analytics',
              isEnabled: true,
            ),
            isEnabled: true,
          ),
        ),
        surfaceSize: const Size(360, 360),
      );

      expect(find.byType(PremiumFeatureCard), findsOneWidget);
      expect(find.text('Advanced Analytics'), findsOneWidget);
      expect(
        find.text('Detailed insights into waste management patterns.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ModernButton row stays within bounds on a compact width',
        (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 300,
          child: Row(
            children: const [
              Expanded(
                child: ModernButton(
                  text: 'Save',
                  onPressed: _noop,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ModernButton(
                  text: 'Later',
                  style: ModernButtonStyle.outlined,
                  onPressed: _noop,
                ),
              ),
            ],
          ),
        ),
        surfaceSize: const Size(300, 480),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
