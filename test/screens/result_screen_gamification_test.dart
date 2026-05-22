import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/result_screen/points_popup.dart';

void main() {
  group('PointsEarnedPopup', () {
    testWidgets('renders current gamification copy and icon', (
      WidgetTester tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointsEarnedPopup(
              points: 42,
              actionLabel: 'Recycle completed',
              impactLabel: '1 bottle saved',
              duration: const Duration(seconds: 5),
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('+42'), findsOneWidget);
      expect(find.text('Eco Points Earned!'), findsOneWidget);
      expect(find.text('Recycle completed • 1 bottle saved'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.recycling &&
              widget.size == 32,
        ),
        findsOneWidget,
      );
      expect(dismissed, isFalse);
    });

    testWidgets('auto dismisses after the configured duration', (
      WidgetTester tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointsEarnedPopup(
              points: 10,
              duration: const Duration(milliseconds: 150),
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
