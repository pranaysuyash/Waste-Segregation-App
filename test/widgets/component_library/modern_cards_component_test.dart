import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';

import '../../helpers/component_test_harness.dart';

void main() {
  group('Modern cards component library', () {
    testWidgets('renders FeatureCard with overflow-safe text', (tester) async {
      await pumpComponent(
        tester,
        const SizedBox(
          width: 260,
          child: FeatureCard(
            icon: Icons.recycling,
            title: 'Very Long Waste Classification Card Title',
            subtitle:
                'Long subtitle for overflow handling and wrapping checks.',
            onTap: _noop,
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders StatsCard trend states', (tester) async {
      await pumpComponent(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            StatsCard(
              title: 'Impact',
              value: '99',
              subtitle: 'week',
              trend: Trend.up,
              isPositiveTrend: true,
            ),
            StatsCard(
              title: 'Missed',
              value: '3',
              subtitle: 'days',
              trend: Trend.down,
              isPositiveTrend: false,
            ),
          ],
        ),
      );

      expect(find.byType(StatsCard), findsNWidgets(2));
      expect(find.text('Impact'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
    });
  });
}

void _noop() {}
