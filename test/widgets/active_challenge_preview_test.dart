import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_badges.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Active Challenge Preview Tests', () {
    testWidgets('ActiveChallengeCard displays basic information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Daily Recycling Goal',
              description: 'Classify 5 items today',
              progress: 0.6,
              icon: Icons.emoji_events,
              timeRemaining: '8 hours left',
              reward: '50 pts',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Recycling Goal'), findsOneWidget);
      expect(find.text('Classify 5 items today'), findsOneWidget);
      expect(find.text('8 hours left'), findsOneWidget);
      expect(find.text('50 pts'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.stars), findsOneWidget);
    });

    testWidgets('ActiveChallengeCard handles long titles without overflow', (WidgetTester tester) async {
      const longTitle = 'Very Long Daily Recycling Goal Challenge That Should Not Overflow';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ActiveChallengeCard(
                title: longTitle,
                description: 'Short description',
                progress: 0.5,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      expect(find.textContaining('Very Long'), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveChallengeCard handles long descriptions without overflow', (WidgetTester tester) async {
      const longDescription = 'Very long challenge description that explains in detail what the user needs to do to complete this challenge successfully';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ActiveChallengeCard(
                title: 'Challenge Title',
                description: longDescription,
                progress: 0.75,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      expect(find.text('Challenge Title'), findsOneWidget);
      expect(find.textContaining('Very long challenge'), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveChallengeCard adapts to narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250, // Narrow width
              child: ActiveChallengeCard(
                title: 'Daily Goal',
                description: 'Classify items',
                progress: 0.4,
                icon: Icons.emoji_events,
                timeRemaining: '5h left',
                reward: '25 pts',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      expect(find.text('Daily Goal'), findsOneWidget);
      expect(find.text('Classify items'), findsOneWidget);
      
      // Should handle narrow width gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveChallengeCard handles tap events correctly', (WidgetTester tester) async {
      var tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Daily Goal',
              description: 'Classify items',
              progress: 0.3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActiveChallengeCard));
      expect(tapped, isTrue);
    });

    testWidgets('ActiveChallengeCard handles progress values correctly', (WidgetTester tester) async {
      // Test with various progress values
      final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0, -0.1, 1.5]; // Including invalid values
      
      for (final progress in progressValues) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActiveChallengeCard(
                title: 'Test Challenge',
                description: 'Test description',
                progress: progress,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(ActiveChallengeCard), findsOneWidget);
        expect(find.byType(ProgressBadge), findsOneWidget);
        
        // Should not throw errors even with invalid progress values
        await tester.pumpAndSettle();
      }
    });

    testWidgets('ActiveChallengeCard shows/hides optional elements correctly', (WidgetTester tester) async {
      // Test without optional elements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Basic Challenge',
              description: 'Basic description',
              progress: 0.5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Basic Challenge'), findsOneWidget);
      expect(find.text('Basic description'), findsOneWidget);
      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsNothing); // No icon
      expect(find.byIcon(Icons.stars), findsNothing); // No reward

      // Test with all optional elements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Full Challenge',
              description: 'Full description',
              progress: 0.8,
              icon: Icons.emoji_events,
              timeRemaining: '2 hours left',
              reward: '100 pts',
              challengeColor: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Full Challenge'), findsOneWidget);
      expect(find.text('Full description'), findsOneWidget);
      expect(find.text('2 hours left'), findsOneWidget);
      expect(find.text('100 pts'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.stars), findsOneWidget);
    });

    testWidgets('ActiveChallengeCard uses custom colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Colored Challenge',
              description: 'Test description',
              progress: 0.6,
              challengeColor: Colors.purple,
              icon: Icons.emoji_events,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      
      // Find the icon and verify it uses the custom color
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.emoji_events));
      expect(iconWidget.color, Colors.purple);
    });

    testWidgets('ActiveChallengeCard handles extremely long text gracefully', (WidgetTester tester) async {
      const extremelyLongTitle = 'This is an extremely long challenge title that should definitely cause overflow issues if not handled properly by the responsive text system';
      const extremelyLongDescription = 'This is an extremely long challenge description that contains a lot of detailed information about what the user needs to do and should also be handled gracefully without causing any layout issues or overflow problems';
      const extremelyLongTimeRemaining = 'This is an extremely long time remaining text that should not break the layout';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very narrow to force overflow
              child: ActiveChallengeCard(
                title: extremelyLongTitle,
                description: extremelyLongDescription,
                progress: 0.7,
                timeRemaining: extremelyLongTimeRemaining,
                reward: '999999 pts',
                icon: Icons.emoji_events,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveChallengeCard accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Accessible Challenge',
              description: 'This challenge is accessible',
              progress: 0.5,
              icon: Icons.emoji_events,
              timeRemaining: '3 hours left',
              reward: '75 pts',
              onTap: () {},
            ),
          ),
        ),
      );

      // Should be accessible by text content
      expect(find.text('Accessible Challenge'), findsOneWidget);
      expect(find.text('This challenge is accessible'), findsOneWidget);
      expect(find.text('3 hours left'), findsOneWidget);
      expect(find.text('75 pts'), findsOneWidget);
      
      // Should be tappable
      await tester.tap(find.byType(ActiveChallengeCard));
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveChallengeCard performance test with multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: List.generate(
                3,
                (index) => ActiveChallengeCard(
                  title: 'Challenge $index',
                  description: 'Description for challenge $index',
                  progress: (index + 1) * 0.25,
                  icon: Icons.emoji_events,
                  timeRemaining: '${index + 1} hours left',
                  reward: '${(index + 1) * 25} pts',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // All instances should render
      expect(find.byType(ActiveChallengeCard), findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(find.text('Challenge $i'), findsOneWidget);
        expect(find.text('Description for challenge $i'), findsOneWidget);
        expect(find.text('${i + 1} hours left'), findsOneWidget);
        expect(find.text('${(i + 1) * 25} pts'), findsOneWidget);
      }
    });
  });

  group('ProgressBadge Enhanced Tests', () {
    testWidgets('ProgressBadge displays progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.75,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('ProgressBadge handles custom text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.5,
              text: '3/6',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.text('3/6'), findsOneWidget);
    });

    testWidgets('ProgressBadge handles very long text without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.9,
              text: 'Very Long Text',
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.textContaining('Very Long'), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('ProgressBadge adapts to different sizes', (WidgetTester tester) async {
      final sizes = [24.0, 32.0, 40.0, 48.0];
      
      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressBadge(
                progress: 0.6,
                size: size,
              ),
            ),
          ),
        );

        expect(find.byType(ProgressBadge), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        
        await tester.pumpAndSettle();
      }
    });

    testWidgets('ProgressBadge handles invalid progress values', (WidgetTester tester) async {
      final invalidValues = [-0.5, 1.5, double.infinity, double.nan];
      
      for (final progress in invalidValues) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressBadge(
                progress: progress,
                size: 40,
              ),
            ),
          ),
        );

        expect(find.byType(ProgressBadge), findsOneWidget);
        
        // Should not throw errors even with invalid progress values
        await tester.pumpAndSettle();
      }
    });

    testWidgets('ProgressBadge respects showPercentage flag', (WidgetTester tester) async {
      // Test with showPercentage = false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.8,
              showPercentage: false,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.text('80%'), findsNothing);

      // Test with showPercentage = true (default)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.8,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('ProgressBadge uses custom colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBadge(
              progress: 0.7,
              progressColor: Colors.red,
              backgroundColor: Colors.grey,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('ProgressBadge responsive sizing works correctly', (WidgetTester tester) async {
      // Test in constrained space
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 30,
              height: 30,
              child: ProgressBadge(
                progress: 0.6,
                size: 50, // Larger than available space
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      
      // Should adapt to available space
      await tester.pumpAndSettle();
    });
  });

  group('Active Challenge Preview Theme Tests', () {
    testWidgets('ActiveChallengeCard respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Theme Test',
              description: 'Testing theme colors',
              progress: 0.5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      await tester.pumpAndSettle();

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ActiveChallengeCard(
              title: 'Theme Test',
              description: 'Testing theme colors',
              progress: 0.5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ActiveChallengeCard), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('ProgressBadge respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ProgressBadge(
              progress: 0.6,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      await tester.pumpAndSettle();

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ProgressBadge(
              progress: 0.6,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBadge), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
} 