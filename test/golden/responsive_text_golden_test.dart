import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/responsive_text.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('ResponsiveText Golden Tests', () {
    testWidgets('AppBar title golden test - normal width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(
                title: 'Waste Segregation',
              ),
            ),
            body: const Center(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/appbar_title_normal.png'),
      );
    });

    testWidgets('AppBar title golden test - long title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(
                title: 'Waste Segregation Pro Edition with Advanced Features',
              ),
            ),
            body: const Center(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/appbar_title_long.png'),
      );
    });

    testWidgets('AppBar title golden test - narrow screen', (WidgetTester tester) async {
      // Set a narrow screen size
      await tester.binding.setSurfaceSize(const Size(300, 600));
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(
                title: 'Waste Segregation Application',
              ),
            ),
            body: const Center(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/appbar_title_narrow.png'),
      );
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Greeting card golden test - normal username', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: GreetingText(
                          greeting: 'Good Morning',
                          userName: 'John',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'What waste would you like to identify today?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container),
        matchesGoldenFile('golden/greeting_card_normal.png'),
      );
    });

    testWidgets('Greeting card golden test - long username', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.nights_stay, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: GreetingText(
                          greeting: 'Good Evening',
                          userName: 'AVeryLongUserNameThatShouldWrapOrResize',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'What waste would you like to identify today?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container),
        matchesGoldenFile('golden/greeting_card_long_username.png'),
      );
    });

    testWidgets('Greeting card golden test - narrow width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 200, // Narrow width
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: GreetingText(
                          greeting: 'Good Afternoon',
                          userName: 'TestUser',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'What waste would you like to identify today?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container),
        matchesGoldenFile('golden/greeting_card_narrow.png'),
      );
    });

    testWidgets('Multiple screen sizes comparison', (WidgetTester tester) async {
      // Test different screen sizes
      final screenSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
      ];

      for (int i = 0; i < screenSizes.length; i++) {
        await tester.binding.setSurfaceSize(screenSizes[i]);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const ResponsiveAppBarTitle(
                  title: 'Waste Segregation App',
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: GreetingText(
                                  greeting: 'Good Morning',
                                  userName: 'TestUser',
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'What waste would you like to identify today?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('golden/screen_size_${i}_${screenSizes[i].width.toInt()}x${screenSizes[i].height.toInt()}.png'),
        );
      }
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Dark theme golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(
                title: 'Waste Segregation',
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.nights_stay, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: GreetingText(
                            greeting: 'Good Evening',
                            userName: 'DarkThemeUser',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'What waste would you like to identify today?',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/dark_theme_responsive_text.png'),
      );
    });
  });

  group('Horizontal Stat Cards Golden Tests', () {
    testWidgets('StatsCard golden test - zero values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
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
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '5',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: '+2',
                      isPositiveTrend: true,
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
                      trend: '+10',
                      isPositiveTrend: true,
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
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '1,234',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: '+150%',
                      isPositiveTrend: true,
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
                      trend: '+500',
                      isPositiveTrend: true,
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
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '42',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: '-5%',
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
                      trend: '-50',
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
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '1,234,567',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: '+12%',
                      isPositiveTrend: true,
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
                      trend: '+999%',
                      isPositiveTrend: true,
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
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Expanded(
                    child: StatsCard(
                      title: 'Classifications',
                      value: '42',
                      icon: Icons.analytics,
                      color: AppTheme.infoColor,
                      trend: '+12%',
                      isPositiveTrend: true,
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
                      trend: '+24',
                      isPositiveTrend: true,
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
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Test standardized accent colors
                  Row(
                    children: const [
                      Expanded(
                        child: StatsCard(
                          title: 'Wet Waste',
                          value: '25',
                          icon: Icons.eco,
                          color: AppTheme.wetWasteColor,
                          trend: '+5%',
                          isPositiveTrend: true,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: 'Dry Waste',
                          value: '18',
                          icon: Icons.recycling,
                          color: AppTheme.dryWasteColor, // Should be amber now
                          trend: '+3%',
                          isPositiveTrend: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child: StatsCard(
                          title: 'Hazardous',
                          value: '2',
                          icon: Icons.warning,
                          color: AppTheme.hazardousWasteColor,
                          trend: '-1',
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
                          trend: '0%',
                          isPositiveTrend: true,
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