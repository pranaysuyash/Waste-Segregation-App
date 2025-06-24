import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Quick-action Cards Tests', () {
    testWidgets('FeatureCard displays basic information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View detailed insights and statistics',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('View detailed insights and statistics'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('FeatureCard handles long titles without overflow', (WidgetTester tester) async {
      const longTitle = 'Very Long Analytics Dashboard Title That Should Not Overflow';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Constrained width
              child: FeatureCard(
                icon: Icons.analytics,
                title: longTitle,
                subtitle: 'Short subtitle',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.textContaining('Very Long'), findsOneWidget);

      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard handles long subtitles without overflow', (WidgetTester tester) async {
      const longSubtitle =
          'Very long subtitle that describes detailed insights and statistics with comprehensive data analysis and reporting features';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Constrained width
              child: FeatureCard(
                icon: Icons.school,
                title: 'Learn About Waste',
                subtitle: longSubtitle,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.text('Learn About Waste'), findsOneWidget);
      expect(find.textContaining('Very long subtitle'), findsOneWidget);

      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard adapts to narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very narrow width
              child: FeatureCard(
                icon: Icons.analytics,
                title: 'Analytics Dashboard',
                subtitle: 'View detailed insights',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('View detailed insights'), findsOneWidget);

      // Should handle narrow width gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard handles tap events correctly', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FeatureCard));
      expect(tapped, isTrue);
    });

    testWidgets('FeatureCard shows custom trailing widget when provided', (WidgetTester tester) async {
      const customTrailing = Icon(Icons.star, key: Key('custom_trailing'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              trailing: customTrailing,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_trailing')), findsOneWidget);
      expect(
          find.byIcon(Icons.chevron_right), findsNothing); // Should not show chevron when custom trailing is provided
    });

    testWidgets('FeatureCard hides chevron when showChevron is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              showChevron: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('FeatureCard uses custom icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              iconColor: Colors.red,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.analytics));
      expect(iconWidget.color, Colors.red);
    });

    testWidgets('FeatureCard uses custom icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              iconSize: 40.0,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.analytics));
      expect(iconWidget.size, 40.0);
    });

    testWidgets('FeatureCard handles missing subtitle gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('FeatureCard responsive padding works correctly', (WidgetTester tester) async {
      // Test narrow screen (should use smaller padding)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250, // Narrow width
              child: FeatureCard(
                icon: Icons.analytics,
                title: 'Analytics Dashboard',
                subtitle: 'View insights',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      await tester.pumpAndSettle();

      // Test wide screen (should use standard padding)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Wide width
              child: FeatureCard(
                icon: Icons.analytics,
                title: 'Analytics Dashboard',
                subtitle: 'View insights',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard handles extremely long text gracefully', (WidgetTester tester) async {
      const extremelyLongTitle =
          'This is an extremely long title that should definitely cause overflow issues if not handled properly by the responsive text system';
      const extremelyLongSubtitle =
          'This is an extremely long subtitle that contains a lot of detailed information about the feature and should also be handled gracefully without causing any layout issues or overflow problems';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very narrow to force overflow
              child: FeatureCard(
                icon: Icons.analytics,
                title: extremelyLongTitle,
                subtitle: extremelyLongSubtitle,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);

      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View detailed insights and statistics',
              onTap: () {},
            ),
          ),
        ),
      );

      // Should be accessible by text content
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('View detailed insights and statistics'), findsOneWidget);

      // Should be tappable
      await tester.tap(find.byType(FeatureCard));
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard performance test with multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: List.generate(
                5,
                (index) => FeatureCard(
                  icon: Icons.analytics,
                  title: 'Feature Card $index',
                  subtitle: 'Subtitle for card $index',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // All instances should render
      expect(find.byType(FeatureCard), findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        expect(find.text('Feature Card $i'), findsOneWidget);
        expect(find.text('Subtitle for card $i'), findsOneWidget);
      }
    });
  });

  group('Quick-action Cards Navigation Tests', () {
    testWidgets('Analytics card navigation test', (WidgetTester tester) async {
      var navigatedToAnalytics = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View detailed insights and statistics',
              onTap: () => navigatedToAnalytics = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FeatureCard));
      expect(navigatedToAnalytics, isTrue);
    });

    testWidgets('Learn About Waste card navigation test', (WidgetTester tester) async {
      var navigatedToEducation = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.school,
              title: 'Learn About Waste',
              subtitle: 'Educational content and tips',
              onTap: () => navigatedToEducation = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FeatureCard));
      expect(navigatedToEducation, isTrue);
    });

    testWidgets('Quick-action cards tap area coverage test', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Test tapping on different parts of the card
      final cardFinder = find.byType(FeatureCard);
      expect(cardFinder, findsOneWidget);

      // Tap on the card
      await tester.tap(cardFinder);
      expect(tapped, isTrue);

      // Reset and test tapping on the icon area
      tapped = false;
      await tester.tap(find.byIcon(Icons.analytics));
      expect(tapped, isTrue);

      // Reset and test tapping on the text area
      tapped = false;
      await tester.tap(find.text('Analytics Dashboard'));
      expect(tapped, isTrue);
    });
  });

  group('Quick-action Cards Color and Theme Tests', () {
    testWidgets('FeatureCard respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      await tester.pumpAndSettle();

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'View insights',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('FeatureCard uses standardized colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FeatureCard(
                  icon: Icons.analytics,
                  title: 'Analytics Dashboard',
                  subtitle: 'View insights',
                  iconColor: AppTheme.infoColor,
                  onTap: () {},
                ),
                FeatureCard(
                  icon: Icons.school,
                  title: 'Learn About Waste',
                  subtitle: 'Educational content',
                  iconColor: AppTheme.successColor,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FeatureCard), findsNWidgets(2));

      // Verify icons use the specified colors
      final analyticsIcon = tester.widget<Icon>(find.byIcon(Icons.analytics));
      expect(analyticsIcon.color, AppTheme.infoColor);

      final schoolIcon = tester.widget<Icon>(find.byIcon(Icons.school));
      expect(schoolIcon.color, AppTheme.successColor);
    });
  });
}
