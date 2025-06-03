import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_badges.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Active Challenge Preview Golden Tests', () {
    testWidgets('ActiveChallengeCard basic layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ActiveChallengeCard(
                    title: 'Daily Recycling Goal',
                    description: 'Classify 5 items today to earn points',
                    progress: 0.6,
                    icon: Icons.emoji_events,
                    timeRemaining: '8 hours left',
                    reward: '50 pts',
                    challengeColor: Colors.green,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  ActiveChallengeCard(
                    title: 'Weekly Streak',
                    description: 'Maintain your classification streak',
                    progress: 0.85,
                    icon: Icons.local_fire_department,
                    timeRemaining: '2 days left',
                    reward: '100 pts',
                    challengeColor: Colors.orange,
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
        matchesGoldenFile('active_challenge_preview_basic.png'),
      );
    });

    testWidgets('ActiveChallengeCard overflow handling golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: ActiveChallengeCard(
                      title: 'Very Long Challenge Title That Should Not Overflow',
                      description: 'Very long challenge description that explains in detail what the user needs to do to complete this challenge successfully',
                      progress: 0.45,
                      icon: Icons.emoji_events,
                      timeRemaining: 'Very long time remaining text',
                      reward: '999999 pts',
                      challengeColor: Colors.purple,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: ActiveChallengeCard(
                      title: 'Narrow Screen Challenge',
                      description: 'Short description for narrow screen',
                      progress: 0.75,
                      icon: Icons.recycling,
                      timeRemaining: '1h left',
                      reward: '25 pts',
                      challengeColor: Colors.blue,
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
        matchesGoldenFile('active_challenge_preview_overflow.png'),
      );
    });

    testWidgets('ActiveChallengeCard progress variations golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ActiveChallengeCard(
                    title: 'Just Started',
                    description: 'Beginning of challenge',
                    progress: 0.1,
                    icon: Icons.play_arrow,
                    timeRemaining: '23 hours left',
                    reward: '30 pts',
                    challengeColor: Colors.red,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  ActiveChallengeCard(
                    title: 'Half Way There',
                    description: 'Making good progress',
                    progress: 0.5,
                    icon: Icons.trending_up,
                    timeRemaining: '12 hours left',
                    reward: '60 pts',
                    challengeColor: Colors.amber,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  ActiveChallengeCard(
                    title: 'Almost Complete',
                    description: 'Nearly finished!',
                    progress: 0.9,
                    icon: Icons.check_circle_outline,
                    timeRemaining: '2 hours left',
                    reward: '90 pts',
                    challengeColor: Colors.green,
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
        matchesGoldenFile('active_challenge_preview_progress_variations.png'),
      );
    });

    testWidgets('ProgressBadge variations golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProgressBadge(
                        progress: 0.25,
                        progressColor: Colors.red,
                      ),
                      ProgressBadge(
                        progress: 0.5,
                        size: 36,
                        progressColor: Colors.orange,
                      ),
                      ProgressBadge(
                        progress: 0.75,
                        size: 40,
                        progressColor: Colors.green,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProgressBadge(
                        progress: 0.3,
                        text: '3/10',
                        size: 36,
                        progressColor: Colors.blue,
                      ),
                      ProgressBadge(
                        progress: 0.8,
                        text: 'High',
                        size: 36,
                        progressColor: Colors.purple,
                      ),
                      ProgressBadge(
                        progress: 1.0,
                        text: 'Done',
                        size: 36,
                        progressColor: Colors.green,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 30,
                        child: ProgressBadge(
                          progress: 0.6,
                          size: 50, // Larger than container
                          progressColor: Colors.teal,
                        ),
                      ),
                      ProgressBadge(
                        progress: 0.9,
                        text: 'Very Long Text',
                        progressColor: Colors.indigo,
                      ),
                      ProgressBadge(
                        progress: 0.4,
                        showPercentage: false,
                        size: 36,
                        progressColor: Colors.brown,
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
        matchesGoldenFile('progress_badge_variations.png'),
      );
    });

    testWidgets('ActiveChallengeCard minimal layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ActiveChallengeCard(
                    title: 'Basic Challenge',
                    description: 'Simple challenge without extras',
                    progress: 0.4,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  ActiveChallengeCard(
                    title: 'With Icon Only',
                    description: 'Challenge with just an icon',
                    progress: 0.7,
                    icon: Icons.star,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  ActiveChallengeCard(
                    title: 'With Reward Only',
                    description: 'Challenge with just a reward',
                    progress: 0.3,
                    reward: '40 pts',
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
        matchesGoldenFile('active_challenge_preview_minimal.png'),
      );
    });
  });
} 