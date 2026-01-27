/// Gamification widget tests for ResultScreen
/// 
/// Tests points popup, achievement celebration, and haptic feedback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/result_screen/points_popup.dart';
import 'package:waste_segregation_app/widgets/result_screen/achievement_wrapper.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('Points Popup', () {
    testWidgets('shows points earned with animation', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointsEarnedPopup(
              points: 50,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Should show points
      expect(find.text('+50'), findsOneWidget);
      expect(find.text('Points Earned!'), findsOneWidget);

      // Should have sparkle icon
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Wait for animation
      await tester.pump(const Duration(seconds: 3));

      // Should auto-dismiss
      expect(dismissed, true);
    });

    testWidgets('does not show for zero points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointsPopupOverlay(
              points: 0,
              isVisible: true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should be empty
      expect(find.byType(PointsEarnedPopup), findsNothing);
    });

    testWidgets('respects visibility flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointsPopupOverlay(
              points: 100,
              isVisible: false,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byType(PointsEarnedPopup), findsNothing);
    });
  });

  group('Achievement Celebration Wrapper', () {
    testWidgets('shows celebration for major achievement', (tester) async {
      final achievement = Achievement(
        id: 'test-achievement',
        name: 'Test Achievement',
        description: 'Test description',
        iconName: 'star',
        tier: AchievementTier.gold,
        pointsReward: 100,
        isEarned: true,
        earnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementCelebrationWrapper(
            child: Container(),
          ),
        ),
      );

      // Initial state - no celebration
      expect(find.byType(AchievementCelebration), findsNothing);

      // TODO: Mock pipeline state to trigger celebration
      // This requires Riverpod test setup
    });

    testWidgets('prevents duplicate celebrations', (tester) async {
      // TODO: Test that celebration only shows once per achievement
    });
  });

  group('Gamification Integration', () {
    testWidgets('haptic feedback triggers on save', (tester) async {
      // TODO: Mock HapticSettingsService and verify haptic is called
    });

    testWidgets('analytics events fire correctly', (tester) async {
      // TODO: Verify analytics events are logged
      // - achievement_celebration_shown
      // - points_popup_shown
    });
  });
}

/// Mock achievement for testing
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final AchievementTier tier;
  final int pointsReward;
  final bool isEarned;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.tier,
    required this.pointsReward,
    required this.isEarned,
    this.earnedAt,
  });
}

enum AchievementTier { bronze, silver, gold, platinum }

/// Mock widget - replace with actual import
class AchievementCelebration extends StatelessWidget {
  final dynamic achievement;
  final VoidCallback onDismiss;

  const AchievementCelebration({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
