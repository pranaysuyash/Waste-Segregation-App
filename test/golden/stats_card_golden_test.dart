import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Horizontal Stat Cards Golden Tests', () {
    testWidgets('StatsCard golden test - zero values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '0',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Streak',
                      value: '0',
                      subtitle: 'days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '0',
                      icon: Icons.stars,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_zero_values.png'),
      );
    });

    testWidgets('StatsCard golden test - small values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '5',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: Trend.up,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Streak',
                      value: '3',
                      subtitle: 'days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '50',
                      icon: Icons.stars,
                      color: Colors.amber,
                      trend: Trend.up,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_small_values.png'),
      );
    });

    testWidgets('StatsCard golden test - large values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '1,234',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: Trend.up,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Streak',
                      value: '365',
                      subtitle: 'days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '99,999',
                      icon: Icons.stars,
                      color: Colors.amber,
                      trend: Trend.up,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_large_values.png'),
      );
    });

    testWidgets('StatsCard golden test - negative trends', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '42',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: Trend.down,
                      isPositiveTrend: false,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Streak',
                      value: '2',
                      subtitle: 'days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '850',
                      icon: Icons.stars,
                      color: Colors.amber,
                      trend: Trend.down,
                      isPositiveTrend: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_negative_trends.png'),
      );
    });

    testWidgets('StatsCard golden test - narrow screen', (WidgetTester tester) async {
      // Set a narrow screen size
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '1,234,567',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: Trend.up,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatsCard(
                      title: 'Very Long Streak Title',
                      value: '999',
                      subtitle: 'days',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '999,999',
                      icon: Icons.stars,
                      color: Colors.amber,
                      trend: Trend.up,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_narrow_screen.png'),
      );

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('StatsCard golden test - dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '42',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
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
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Points',
                      value: '1,250',
                      icon: Icons.stars,
                      color: Colors.amber,
                      trend: Trend.up,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_dark_theme.png'),
      );
    });

    testWidgets('StatsCard golden test - color standardization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Test standardized accent colors
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Wet Waste',
                          value: '25',
                          icon: Icons.eco,
                          color: AppTheme.wetWasteColor,
                          trend: Trend.up,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: 'Dry Waste',
                          value: '18',
                          icon: Icons.recycling,
                          color: AppTheme.dryWasteColor, // Should be amber now
                          trend: Trend.up,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Hazardous',
                          value: '2',
                          icon: Icons.warning,
                          color: AppTheme.hazardousWasteColor,
                          trend: Trend.down,
                          isPositiveTrend: false,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: 'Medical',
                          value: '1',
                          icon: Icons.medical_services,
                          color: AppTheme.medicalWasteColor,
                          trend: Trend.flat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/stats_cards_color_standardization.png'),
      );
    });
  });
}
