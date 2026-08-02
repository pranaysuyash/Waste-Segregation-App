import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/result_screen/local_rules_card.dart';

WasteClassification _classification({
  required Map<String, String> localRegulations,
  String? localGuidelinesReference,
}) {
  return WasteClassification(
    id: 'local-rules-test',
    itemName: 'Bottle',
    category: 'Dry Waste',
    explanation: 'Test',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse'],
      hasUrgentTimeframe: false,
    ),
    region: 'Bengaluru',
    visualFeatures: const [],
    alternatives: const [],
    localRegulations: localRegulations,
    localGuidelinesReference: localGuidelinesReference,
    timestamp: DateTime(2026, 8, 2),
  );
}

void main() {
  test('does not classify taxonomy metadata as local rules', () {
    final classification = _classification(
      localRegulations: const {
        'taxonomy_version': 'recycling-taxonomy-v1',
        'taxonomy_category_id': 'metal.aluminum',
      },
    );

    expect(LocalRulesCard.hasLocalRules(classification), isFalse);
  });

  testWidgets('renders policy fields but hides taxonomy internals', (
    tester,
  ) async {
    final classification = _classification(
      localRegulations: const {
        'policy_rule_pack_id': 'bbmp-v1',
        'taxonomy_category_id': 'metal.aluminum',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LocalRulesCard(classification: classification)),
      ),
    );

    expect(find.text('Local Rules & Compliance'), findsOneWidget);
    expect(find.text('Policy Pack:'), findsOneWidget);
    expect(find.text('metal.aluminum'), findsNothing);
  });
}
