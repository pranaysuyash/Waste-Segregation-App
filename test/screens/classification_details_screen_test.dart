import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/classification_details_screen.dart';

SharedWasteClassification _sharedClassification() {
  final classification = WasteClassification(
    id: 'c1',
    itemName: 'Test Item',
    category: 'Dry Waste',
    subcategory: 'Plastic',
    explanation: 'Explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Recycle'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['feature'],
    alternatives: const [],
    confidence: 0.9,
    timestamp: DateTime.now(),
    userId: 'u1',
    imageRelativePath: 'images/test.jpg',
  );

  return SharedWasteClassification(
    id: 's1',
    classification: classification,
    sharedBy: 'u1',
    sharedByDisplayName: 'User',
    sharedAt: DateTime.now(),
    familyId: 'fam1',
  );
}

void main() {
  group('ClassificationDetailsScreen', () {
    testWidgets('renders item name in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ClassificationDetailsScreen(classification: _sharedClassification()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Item'), findsWidgets);
    });
  });
}

