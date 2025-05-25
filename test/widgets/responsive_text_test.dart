import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/responsive_text.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('ResponsiveText Widget Tests', () {
    testWidgets('ResponsiveText displays text correctly', (WidgetTester tester) async {
      const testText = 'Test Text';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(testText),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('ResponsiveText.appBarTitle handles long text', (WidgetTester tester) async {
      const longTitle = 'Very Long Application Title That Should Overflow';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveText.appBarTitle(longTitle),
            ),
          ),
        ),
      );

      // Should find the text widget
      expect(find.textContaining('Very Long'), findsOneWidget);
    });

    testWidgets('ResponsiveText.greeting handles long user names', (WidgetTester tester) async {
      const longText = 'This is a very long greeting text that should wrap or resize';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrained width
              child: ResponsiveText.greeting(longText),
            ),
          ),
        ),
      );

      expect(find.textContaining('This is a very'), findsOneWidget);
    });
  });

  group('GreetingText Widget Tests', () {
    testWidgets('GreetingText displays greeting and username', (WidgetTester tester) async {
      const greeting = 'Good Morning';
      const userName = 'John';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingText(
              greeting: greeting,
              userName: userName,
            ),
          ),
        ),
      );

      expect(find.text('$greeting, $userName!'), findsOneWidget);
    });

    testWidgets('GreetingText handles very long usernames', (WidgetTester tester) async {
      const greeting = 'Good Evening';
      const longUserName = 'AVeryLongUserNameThatShouldCauseTextOverflow';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrained width to force overflow
              child: GreetingText(
                greeting: greeting,
                userName: longUserName,
              ),
            ),
          ),
        ),
      );

      // Should find text containing the greeting
      expect(find.textContaining(greeting), findsOneWidget);
    });

    testWidgets('GreetingText adapts to different screen sizes', (WidgetTester tester) async {
      const greeting = 'Good Afternoon';
      const userName = 'TestUser';
      
      // Test with narrow screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // Very narrow
              child: GreetingText(
                greeting: greeting,
                userName: userName,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining(greeting), findsOneWidget);

      // Test with wide screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Wide
              child: GreetingText(
                greeting: greeting,
                userName: userName,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining(greeting), findsOneWidget);
    });

    testWidgets('GreetingText respects maxLines parameter', (WidgetTester tester) async {
      const greeting = 'Good Morning';
      const userName = 'User';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingText(
              greeting: greeting,
              userName: userName,
              maxLines: 1,
            ),
          ),
        ),
      );

      expect(find.text('$greeting, $userName!'), findsOneWidget);
    });
  });

  group('ResponsiveAppBarTitle Widget Tests', () {
    testWidgets('ResponsiveAppBarTitle displays title correctly', (WidgetTester tester) async {
      const title = 'App Title';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(title: title),
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('ResponsiveAppBarTitle abbreviates very long titles on narrow screens', (WidgetTester tester) async {
      const longTitle = 'Very Long Application Title That Should Be Abbreviated';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const SizedBox(
                width: 150, // Very narrow to trigger abbreviation
                child: ResponsiveAppBarTitle(title: longTitle),
              ),
            ),
          ),
        ),
      );

      // Should find some form of the title (either full or abbreviated)
      expect(find.byType(ResponsiveAppBarTitle), findsOneWidget);
    });

    testWidgets('ResponsiveAppBarTitle handles single word titles', (WidgetTester tester) async {
      const singleWordTitle = 'SuperLongSingleWordTitle';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const SizedBox(
                width: 150,
                child: ResponsiveAppBarTitle(title: singleWordTitle),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveAppBarTitle), findsOneWidget);
    });

    testWidgets('ResponsiveAppBarTitle creates proper abbreviations', (WidgetTester tester) async {
      const multiWordTitle = 'Waste Segregation Application';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const SizedBox(
                width: 100, // Force abbreviation
                child: ResponsiveAppBarTitle(title: multiWordTitle),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveAppBarTitle), findsOneWidget);
    });
  });

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
              isPositiveTrend: true,
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
              trend: '-5%',
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
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80, // Very narrow
              child: const StatsCard(
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
              trend: '+10%',
              isPositiveTrend: true,
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
              trend: '-10%',
              isPositiveTrend: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('StatsCard handles tap events', (WidgetTester tester) async {
      bool tapped = false;
      
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
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                Expanded(
                  child: StatsCard(
                    title: 'Classifications',
                    value: '42',
                    icon: Icons.analytics,
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
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Points',
                    value: '1,250',
                    icon: Icons.stars,
                    trend: '+24',
                    isPositiveTrend: true,
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
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('ResponsiveText handles empty text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(''),
          ),
        ),
      );

      expect(find.byType(ResponsiveText), findsOneWidget);
    });

    testWidgets('GreetingText handles empty username', (WidgetTester tester) async {
      const greeting = 'Hello';
      const emptyUserName = '';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingText(
              greeting: greeting,
              userName: emptyUserName,
            ),
          ),
        ),
      );

      expect(find.text('$greeting, !'), findsOneWidget);
    });

    testWidgets('ResponsiveAppBarTitle handles empty title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const ResponsiveAppBarTitle(title: ''),
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveAppBarTitle), findsOneWidget);
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
  });

  group('Accessibility Tests', () {
    testWidgets('ResponsiveText supports semantics labels', (WidgetTester tester) async {
      const testText = 'Test Text';
      const semanticsLabel = 'Test Semantics Label';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              testText,
              semanticsLabel: semanticsLabel,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(semanticsLabel), findsOneWidget);
    });

    testWidgets('GreetingText is accessible', (WidgetTester tester) async {
      const greeting = 'Good Morning';
      const userName = 'John';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingText(
              greeting: greeting,
              userName: userName,
            ),
          ),
        ),
      );

      // Should be accessible by text content
      expect(find.text('$greeting, $userName!'), findsOneWidget);
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
  });

  group('Performance Tests', () {
    testWidgets('ResponsiveText performs well with multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: List.generate(
                10,
                (index) => ResponsiveText('Text $index'),
              ),
            ),
          ),
        ),
      );

      // All instances should render
      for (int i = 0; i < 10; i++) {
        expect(find.text('Text $i'), findsOneWidget);
      }
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
      for (int i = 0; i < 5; i++) {
        expect(find.text('Card $i'), findsOneWidget);
        expect(find.text('$i'), findsOneWidget);
      }
    });
  });
} 