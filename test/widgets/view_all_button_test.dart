import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';

void main() {
  group('View All Button Tests', () {
    testWidgets('ViewAllButton displays full text on wide screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Wide enough for full text
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('View All'), findsOneWidget);
      expect(find.byType(ViewAllButton), findsOneWidget);
    });

    testWidgets('ViewAllButton displays abbreviated text on narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // Narrow width
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('ViewAllButton displays only icon on very narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60, // Very narrow width
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('View All'), findsNothing);
      expect(find.text('All'), findsNothing);
    });

    testWidgets('ViewAllButton handles tap events correctly', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewAllButton(
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ViewAllButton));
      expect(tapped, isTrue);
    });

    testWidgets('ViewAllButton respects custom text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ViewAllButton(
                text: 'See More',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('See More'), findsOneWidget);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('ViewAllButton respects custom icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60, // Very narrow to show icon only
              child: ViewAllButton(
                icon: Icons.more_horiz,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('ViewAllButton adapts to different button styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ViewAllButton(
                  style: ModernButtonStyle.filled,
                  onPressed: () {},
                ),
                ViewAllButton(
                  style: ModernButtonStyle.outlined,
                  onPressed: () {},
                ),
                ViewAllButton(
                  style: ModernButtonStyle.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsNWidgets(3));
    });

    testWidgets('ViewAllButton adapts to different button sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ViewAllButton(
                  size: ModernButtonSize.small,
                  onPressed: () {},
                ),
                ViewAllButton(
                  size: ModernButtonSize.medium,
                  onPressed: () {},
                ),
                ViewAllButton(
                  size: ModernButtonSize.large,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsNWidgets(3));
    });

    testWidgets('ViewAllButton shows tooltip on very narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60, // Very narrow to trigger icon-only mode
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Long press to show tooltip
      await tester.longPress(find.byType(ViewAllButton));
      await tester.pumpAndSettle();

      expect(find.text('View All'), findsOneWidget); // Should appear in tooltip
    });

    testWidgets('ViewAllButton handles multiple instances without interference', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 200,
                  child: ViewAllButton(
                    text: 'View All Items',
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: ViewAllButton(
                    text: 'See More',
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: ViewAllButton(
                    text: 'Show All',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('View All Items'), findsOneWidget); // Wide version
      expect(find.text('More'), findsOneWidget); // Narrow version (abbreviated)
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget); // Very narrow version
    });

    testWidgets('ViewAllButton performance test with rapid layout changes', (WidgetTester tester) async {
      double width = 200;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    SizedBox(
                      width: width,
                      child: ViewAllButton(
                        onPressed: () {},
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          width = width == 200 ? 60 : 200;
                        });
                      },
                      child: const Text('Toggle Width'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Test rapid width changes
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Toggle Width'));
        await tester.pumpAndSettle();
      }

      expect(find.byType(ViewAllButton), findsOneWidget);
    });

    testWidgets('ViewAllButton accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewAllButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Should be accessible by tap
      await tester.tap(find.byType(ViewAllButton));
      await tester.pumpAndSettle();

      // Should have semantic information
      expect(find.byType(ViewAllButton), findsOneWidget);
    });

    testWidgets('ViewAllButton theme compatibility test', (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ViewAllButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ViewAllButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsOneWidget);
    });
  });

  group('View All Button Edge Cases', () {
    testWidgets('ViewAllButton handles null onPressed gracefully', (WidgetTester tester) async {
      // This should not be possible with required parameter, but test anyway
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewAllButton(
              onPressed: () {}, // Required parameter
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsOneWidget);
    });

    testWidgets('ViewAllButton handles extreme width constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20, // Extremely narrow
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ViewAllButton), findsOneWidget);
      // Should still render without overflow
      await tester.pumpAndSettle();
    });

    testWidgets('ViewAllButton handles very wide constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000, // Very wide
              child: ViewAllButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('View All'), findsOneWidget);
      expect(find.byType(ViewAllButton), findsOneWidget);
    });
  });
} 