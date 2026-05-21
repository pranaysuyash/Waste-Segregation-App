import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/result_screen/points_popup.dart';

void main() {
  group('Points Popup', () {
    testWidgets('shows points earned and auto-dismisses', (tester) async {
      var dismissed = false;

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

      expect(find.text('+50'), findsOneWidget);
      expect(find.text('Eco Points Earned!'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsOneWidget);

      // Animation (1.5s) + auto-dismiss delay (2s).
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(seconds: 3));

      expect(dismissed, isTrue);
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
}
