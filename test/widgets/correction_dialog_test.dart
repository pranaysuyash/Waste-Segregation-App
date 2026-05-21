import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/correction_dialog.dart';

void main() {
  WasteClassification buildClassification() {
    return WasteClassification(
      itemName: 'Plastic Bottle',
      category: 'Dry Waste',
      explanation: 'Test explanation',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Recycle',
        steps: const ['Rinse', 'Dry', 'Recycle'],
        hasUrgentTimeframe: false,
      ),
      region: 'Bangalore, IN',
      visualFeatures: const ['plastic', 'bottle'],
      alternatives: const [],
      confidence: 0.9,
    );
  }

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => CorrectionDialog(
                        classification: buildClassification(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('wrong feedback requires at least one correction field', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('correction_submit_button'));
    expect(submitButton, findsOneWidget);
    final filledButton = tester.widget<FilledButton>(submitButton);
    expect(filledButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'material is HDPE');
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<FilledButton>(submitButton);
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('barcode field is visible in correction dialog', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.qr_code), findsOneWidget);
    expect(find.text('Barcode / Product code'), findsOneWidget);
    expect(find.text('Product lookup coming later'), findsOneWidget);
  });

  testWidgets('barcode alone enables submit for wrong feedback',
      (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('correction_submit_button'));
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);

    // Find the barcode text field by label and enter a value
    final barcodeField =
        find.widgetWithText(TextField, 'Barcode / Product code');
    await tester.enterText(barcodeField, '8901234567890');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
  });
}
