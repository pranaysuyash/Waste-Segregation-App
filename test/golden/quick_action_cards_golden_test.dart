import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Quick-action Cards Golden Tests', () {
    testWidgets('FeatureCard basic layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FeatureCard(
                    icon: Icons.analytics,
                    title: 'Analytics Dashboard',
                    subtitle: 'View detailed insights and statistics',
                    iconColor: AppTheme.infoColor,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    icon: Icons.school,
                    title: 'Learn About Waste',
                    subtitle: 'Educational content and tips',
                    iconColor: AppTheme.successColor,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('quick_action_cards_basic.png'),
      );
    });

    testWidgets('FeatureCard overflow handling golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: FeatureCard(
                      icon: Icons.analytics,
                      title: 'Very Long Analytics Dashboard Title That Should Not Overflow',
                      subtitle: 'Very long subtitle that describes detailed insights and statistics with comprehensive data analysis and reporting features',
                      iconColor: AppTheme.infoColor,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: FeatureCard(
                      icon: Icons.school,
                      title: 'Learn About Waste Management',
                      subtitle: 'Educational content',
                      iconColor: AppTheme.successColor,
                      onTap: () {},
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
        matchesGoldenFile('quick_action_cards_overflow.png'),
      );
    });

    testWidgets('FeatureCard theme variations golden test', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: FeatureCard(
                icon: Icons.analytics,
                title: 'Analytics Dashboard',
                subtitle: 'View detailed insights and statistics',
                iconColor: AppTheme.infoColor,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('quick_action_cards_light_theme.png'),
      );

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: FeatureCard(
                icon: Icons.analytics,
                title: 'Analytics Dashboard',
                subtitle: 'View detailed insights and statistics',
                iconColor: AppTheme.infoColor,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('quick_action_cards_dark_theme.png'),
      );
    });
  });
} 