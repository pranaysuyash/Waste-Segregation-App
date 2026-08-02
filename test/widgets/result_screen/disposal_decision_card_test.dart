import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/result_screen/disposal_decision_card.dart';

WasteClassification _classification({
  double confidence = 0.92,
  Map<String, String>? localRegulations,
  String? taxonomySource,
  String? taxonomyMethod,
  bool? clarificationNeeded,
}) {
  return WasteClassification(
    id: 'decision-card-test',
    itemName: 'Aluminum can',
    category: 'Dry Waste',
    explanation: 'Metal container',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Empty and rinse', 'Place in the dry-waste stream'],
      hasUrgentTimeframe: false,
    ),
    region: 'Bengaluru',
    visualFeatures: const ['metal'],
    alternatives: const [],
    confidence: confidence,
    clarificationNeeded: clarificationNeeded,
    localRegulations: localRegulations,
    taxonomySource: taxonomySource,
    taxonomyMethod: taxonomyMethod,
    timestamp: DateTime(2026, 8, 2),
  );
}

void main() {
  testWidgets('shows actionable local recommendation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisposalDecisionCard(
            classification: _classification(
              localRegulations: const {
                'policy_rule_pack_id': 'bbmp-v1',
                'policy_local_name': 'BBMP local rules',
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended next step'), findsOneWidget);
    expect(find.text('Recycle'), findsOneWidget);
    expect(find.text('Actionable'), findsOneWidget);
    expect(find.text('BBMP local rules'), findsOneWidget);
    expect(find.text('Empty and rinse'), findsOneWidget);
    expect(find.text('Review first'), findsNothing);
  });

  testWidgets('labels general guidance as requiring local verification', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisposalDecisionCard(
            classification: _classification(),
          ),
        ),
      ),
    );

    expect(find.text('Review first'), findsOneWidget);
    expect(find.text('General disposal guidance'), findsOneWidget);
    expect(
        find.textContaining('No local rule pack was applied'), findsOneWidget);
  });

  testWidgets('fails safe when taxonomy is unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisposalDecisionCard(
            classification: _classification(
              taxonomySource: 'taxonomy_unavailable',
              taxonomyMethod: 'asset_missing',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Review first'), findsOneWidget);
    expect(
      find.textContaining('taxonomy could not be resolved'),
      findsOneWidget,
    );
  });

  testWidgets('exposes the existing correction loop', (tester) async {
    var corrected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisposalDecisionCard(
            classification: _classification(confidence: 0.45),
            onCorrect: () => corrected = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Correct this result'));
    expect(corrected, isTrue);
  });
}
