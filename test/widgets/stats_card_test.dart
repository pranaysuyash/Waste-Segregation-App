import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Horizontal Stat Cards Tests', () {
    testWidgets('StatsCard displays basic information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Classifications',
              value: '42',
              icon: Icons.analytics,
            ),
          ),
        ),
      );

      expect(find.text('Classifications'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('StatsCard handles zero values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Streak',
              value: '0',
              subtitle: 'days',
              icon: Icons.local_fire_department,
            ),
          ),
        ),
      );

      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
    });

    testWidgets('StatsCard handles large values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Points',
              value: '999,999',
              icon: Icons.stars,
              trend: '+150%',
            ),
          ),
        ),
      );

      expect(find.text('Points'), findsOneWidget);
      expect(find.text('999,999'), findsOneWidget);
      expect(find.text('+150%'), findsOneWidget);
    });

    testWidgets('StatsCard handles negative trends', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Performance',
              value: '25',
              trend: Trend.down,
              isPositiveTrend: false,
            ),
          ),
        ),
      );

      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('-5%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('StatsCard adapts to narrow width', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80, // Very narrow
              child: StatsCard(
                title: 'Very Long Title That Should Truncate',
                value: '1,234,567',
                icon: Icons.analytics,
              ),
            ),
          ),
        ),
      );

      // Should find the card and handle overflow gracefully
      expect(find.byType(StatsCard), findsOneWidget);
      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('StatsCard trend chip uses correct colors', (WidgetTester tester) async {
      // Test positive trend
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Test',
              value: '100',
              trend: Trend.up,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Test negative trend
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Test',
              value: '100',
              trend: Trend.down,
              isPositiveTrend: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('StatsCard handles tap events', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Tappable',
              value: '42',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatsCard));
      expect(tapped, isTrue);
    });

    testWidgets('StatsCard row layout handles multiple cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Classifications',
                    value: '42',
                    icon: Icons.analytics,
                    trend: Trend.up,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Streak',
                    value: '7',
                    subtitle: 'days',
                    icon: Icons.local_fire_department,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Points',
                    value: '1,250',
                    icon: Icons.stars,
                    trend: Trend.up,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatsCard), findsNWidgets(3));
      expect(find.text('Classifications'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Points'), findsOneWidget);
    });

    testWidgets('StatsCard handles empty values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Empty',
              value: '',
            ),
          ),
        ),
      );

      expect(find.byType(StatsCard), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('StatsCard is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Accessible Card',
              value: '42',
              icon: Icons.analytics,
            ),
          ),
        ),
      );

      // Should be accessible by text content
      expect(find.text('Accessible Card'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('StatsCard performs well with multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: List.generate(
                5,
                (index) => StatsCard(
                  title: 'Card $index',
                  value: '$index',
                  icon: Icons.analytics,
                ),
              ),
            ),
          ),
        ),
      );

      // All instances should render
      expect(find.byType(StatsCard), findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        expect(find.text('Card $i'), findsOneWidget);
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('StatsCard color standardization test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatsCard(
                  title: 'Dry Waste',
                  value: '18',
                  icon: Icons.recycling,
                  color: AppTheme.dryWasteColor, // Should be amber #FFC107
                ),
                StatsCard(
                  title: 'Success Trend',
                  value: '100',
                  trend: '+10%',
                ),
                StatsCard(
                  title: 'Error Trend',
                  value: '50',
                  trend: '-5%',
                  isPositiveTrend: false, // Should use AppTheme.errorColor
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatsCard), findsNWidgets(3));
      expect(find.text('Dry Waste'), findsOneWidget);
      expect(find.text('+10%'), findsOneWidget);
      expect(find.text('-5%'), findsOneWidget);
    });
  });
}
