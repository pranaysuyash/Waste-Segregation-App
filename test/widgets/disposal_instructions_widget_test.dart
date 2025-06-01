import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart'; // For DisposalInstructions
import 'package:waste_segregation_app/widgets/disposal_instructions_widget.dart';

// Helper to create DisposalInstructions with varying text lengths
DisposalInstructions createMockDisposalInstructions({
  String primaryMethod = 'Default Primary Method.',
  List<String> warnings = const ['Default warning.'],
  List<String> steps = const ['Default step 1.'],
  List<String> tips = const ['Default tip.'],
  String? recyclingInfo, // Nullable as per model
  String? location,      // Nullable as per model
  bool hasUrgentTimeframe = false,
  String? timeframe,
  String? estimatedTime,
}) {
  return DisposalInstructions(
    primaryMethod: primaryMethod,
    warnings: warnings,
    steps: steps,
    tips: tips,
    recyclingInfo: recyclingInfo,
    location: location,
    hasUrgentTimeframe: hasUrgentTimeframe,
    timeframe: timeframe,
    estimatedTime: estimatedTime,
  );
}

void main() {
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)), // Added SingleChildScrollView for long content
    );
  }

  group('DisposalInstructionsWidget Text Overflow Tests', () {
    testWidgets('Long primary disposal method uses ellipsis', (WidgetTester tester) async {
      final longText = 'This is an extremely long primary disposal method that should definitely overflow the available space and demonstrate the ellipsis truncation at the end of the text block.';
      final instructions = createMockDisposalInstructions(primaryMethod: longText);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longText));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 2); // As per implementation in previous subtask
    });

    testWidgets('Long warning text uses ellipsis', (WidgetTester tester) async {
      final longWarning = 'This is a very very long safety warning that must be displayed to the user, and it is crucial that it truncates properly with an ellipsis if it cannot fit in the allocated space for a single warning item.';
      final instructions = createMockDisposalInstructions(warnings: [longWarning, 'Short warning.']);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longWarning));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3); // As per implementation
    });

    testWidgets('Long step text uses ellipsis', (WidgetTester tester) async {
      final longStep = 'This describes a very detailed and extremely long step-by-step instruction for waste disposal that will certainly exceed the typical line limits and thus should be truncated using an ellipsis to maintain UI consistency.';
      final instructions = createMockDisposalInstructions(steps: [longStep, 'Short step.']);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longStep));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3); // As per implementation
    });

    testWidgets('Long tip text uses ellipsis', (WidgetTester tester) async {
      final longTip = 'Here is an exceptionally long and helpful tip regarding waste management and recycling practices that might not fit into the designated area, therefore it should gracefully truncate with an ellipsis.';
      final instructions = createMockDisposalInstructions(tips: [longTip, 'Short tip.']);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longTip));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3); // As per implementation
    });

    testWidgets('Long recycling info text uses ellipsis', (WidgetTester tester) async {
      final longRecyclingInfo = 'This section contains extraordinarily detailed recycling information, including material specifics, preparation guidelines, and facility locations, which is so extensive that it will require truncation with an ellipsis.';
      final instructions = createMockDisposalInstructions(recyclingInfo: longRecyclingInfo);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longRecyclingInfo));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3); // As per implementation
    });

    testWidgets('Long location info text uses ellipsis', (WidgetTester tester) async {
      final longLocationInfo = 'The specific location for disposing of this type of waste is at the following address: Plot 123, Industrial Area, Phase 4, Near the very big landmark that everyone knows, Anytown, State, Country, Postal Code XXXXXX, and this text is designed to overflow.';
      final instructions = createMockDisposalInstructions(location: longLocationInfo);

      await tester.pumpWidget(createTestableWidget(DisposalInstructionsWidget(instructions: instructions)));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longLocationInfo));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3); // As per implementation
    });
  });
}
