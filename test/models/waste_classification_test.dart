import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('WasteClassification', () {
    test('should create a WasteClassification with all required fields', () {
      final classification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: ['test feature'],
        alternatives: [],
      );

      expect(classification.itemName, 'Test Item');
      expect(classification.category, 'Dry Waste');
      expect(classification.explanation, 'Test explanation');
      expect(classification.region, 'Test Region');
      expect(classification.visualFeatures, hasLength(1));
      expect(classification.alternatives, isEmpty);
      expect(classification.id, isNotEmpty); // Auto-generated
      expect(classification.timestamp, isA<DateTime>()); // Auto-generated
    });

    test('should create fallback classification', () {
      final classification = WasteClassification.fallback('/path/to/image.jpg');

      expect(classification.itemName, 'Unidentified Item');
      expect(classification.category, 'Requires Manual Review');
      expect(classification.subcategory, 'Classification Needed');
      expect(classification.explanation, contains('unable to automatically identify'));
      expect(classification.imageUrl, '/path/to/image.jpg');
      expect(classification.confidence, 0.0);
      expect(classification.clarificationNeeded, true);
      expect(classification.riskLevel, 'unknown');
      expect(classification.alternatives, hasLength(3));
    });

    test('should create WasteClassification from JSON', () {
      final json = {
        'id': 'test_json',
        'itemName': 'Test Item',
        'category': 'Dry Waste',
        'explanation': 'Test explanation',
        'region': 'Test Region',
        'visualFeatures': ['feature1', 'feature2'],
        'alternatives': [],
        'confidence': 0.85,
        'timestamp': '2024-01-15T10:30:00.000Z',
      };

      final classification = WasteClassification.fromJson(json);

      expect(classification.id, 'test_json');
      expect(classification.itemName, 'Test Item');
      expect(classification.category, 'Dry Waste');
      expect(classification.explanation, 'Test explanation');
      expect(classification.region, 'Test Region');
      expect(classification.visualFeatures, ['feature1', 'feature2']);
      expect(classification.confidence, 0.85);
      expect(classification.timestamp, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('should handle copyWith correctly', () {
      final original = WasteClassification(
        itemName: 'Original Item',
        category: 'Dry Waste',
        explanation: 'Original explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Original method',
          steps: ['Original step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Original Region',
        visualFeatures: ['original'],
        alternatives: [],
        confidence: 0.5,
      );

      final updated = original.copyWith(
        itemName: 'Updated Item',
        confidence: 0.9,
      );

      expect(updated.itemName, 'Updated Item');
      expect(updated.confidence, 0.9);
      expect(updated.category, 'Dry Waste'); // Should remain unchanged
      expect(updated.region, 'Original Region'); // Should remain unchanged
      expect(updated.id, original.id); // Should remain unchanged
    });
  });

  group('AlternativeClassification', () {
    test('should create AlternativeClassification correctly', () {
      final alternative = AlternativeClassification(
        category: 'Wet Waste',
        subcategory: 'Food Waste',
        confidence: 0.7,
        reason: 'Could be organic material',
      );

      expect(alternative.category, 'Wet Waste');
      expect(alternative.subcategory, 'Food Waste');
      expect(alternative.confidence, 0.7);
      expect(alternative.reason, 'Could be organic material');
    });

    test('should create AlternativeClassification from JSON', () {
      final json = {
        'category': 'Hazardous Waste',
        'subcategory': 'Electronic',
        'confidence': 0.8,
        'reason': 'Contains electronic components',
      };

      final alternative = AlternativeClassification.fromJson(json);

      expect(alternative.category, 'Hazardous Waste');
      expect(alternative.subcategory, 'Electronic');
      expect(alternative.confidence, 0.8);
      expect(alternative.reason, 'Contains electronic components');
    });
  });

  group('DisposalInstructions', () {
    test('should create DisposalInstructions correctly', () {
      final instructions = DisposalInstructions(
        primaryMethod: 'Recycling bin',
        steps: ['Clean the item', 'Remove labels', 'Place in blue bin'],
        hasUrgentTimeframe: false,
        warnings: ['Ensure item is clean'],
        tips: ['Check local recycling guidelines'],
        timeframe: 'Next collection day',
        location: 'Curbside recycling',
        recyclingInfo: 'Can be recycled into new products',
        estimatedTime: '2 minutes',
      );

      expect(instructions.primaryMethod, 'Recycling bin');
      expect(instructions.steps, hasLength(3));
      expect(instructions.hasUrgentTimeframe, false);
      expect(instructions.warnings, contains('Ensure item is clean'));
      expect(instructions.tips, contains('Check local recycling guidelines'));
      expect(instructions.timeframe, 'Next collection day');
      expect(instructions.location, 'Curbside recycling');
      expect(instructions.recyclingInfo, 'Can be recycled into new products');
      expect(instructions.estimatedTime, '2 minutes');
    });

    test('should create DisposalInstructions from JSON', () {
      final json = {
        'primaryMethod': 'Compost bin',
        'steps': ['Remove any stickers', 'Cut into smaller pieces', 'Add to compost'],
        'hasUrgentTimeframe': true,
        'warnings': ['Do not include meat scraps'],
        'tips': ['Mix with brown materials'],
      };

      final instructions = DisposalInstructions.fromJson(json);

      expect(instructions.primaryMethod, 'Compost bin');
      expect(instructions.steps, hasLength(3));
      expect(instructions.hasUrgentTimeframe, true);
      expect(instructions.warnings, hasLength(1));
      expect(instructions.tips, hasLength(1));
    });

    test('should parse steps from string with various separators', () {
      // Test comma separation
      final commaSteps = DisposalInstructions.fromJson({
        'primaryMethod': 'Test',
        'steps': 'Step 1, Step 2, Step 3',
        'hasUrgentTimeframe': false,
      });
      expect(commaSteps.steps, ['Step 1', 'Step 2', 'Step 3']);

      // Test semicolon separation
      final semicolonSteps = DisposalInstructions.fromJson({
        'primaryMethod': 'Test',
        'steps': 'Step 1; Step 2; Step 3',
        'hasUrgentTimeframe': false,
      });
      expect(semicolonSteps.steps, ['Step 1', 'Step 2', 'Step 3']);
    });

    test('should handle invalid or empty steps gracefully', () {
      final emptySteps = DisposalInstructions.fromJson({
        'primaryMethod': 'Test',
        'steps': '',
        'hasUrgentTimeframe': false,
      });
      expect(emptySteps.steps, ['Please review manually']);

      final nullSteps = DisposalInstructions.fromJson({
        'primaryMethod': 'Test',
        'steps': null,
        'hasUrgentTimeframe': false,
      });
      expect(nullSteps.steps, ['Please review manually']);
    });
  });

  group('WasteCategory Extensions', () {
    test('should handle WasteCategory enum values', () {
      final categories = [
        WasteCategory.wet,
        WasteCategory.dry,
        WasteCategory.hazardous,
        WasteCategory.medical,
        WasteCategory.nonWaste,
      ];

      for (final category in categories) {
        expect(category.name, isNotEmpty);
        expect(category.description, isNotEmpty);
        expect(category.color, isNotEmpty);
      }
    });

    test('should handle WasteCategory properties', () {
      expect(WasteCategory.wet.name, 'Wet Waste');
      expect(WasteCategory.dry.name, 'Dry Waste');
      expect(WasteCategory.hazardous.name, 'Hazardous Waste');
      expect(WasteCategory.medical.name, 'Medical Waste');
      expect(WasteCategory.nonWaste.name, 'Non-Waste');
    });

    test('should handle WasteCategory descriptions', () {
      expect(WasteCategory.wet.description, contains('Biodegradable'));
      expect(WasteCategory.dry.description, contains('Recyclable'));
      expect(WasteCategory.hazardous.description, contains('dangerous'));
      expect(WasteCategory.medical.description, contains('medical'));
      expect(WasteCategory.nonWaste.description, contains('reused'));
    });

    test('should handle WasteCategory colors', () {
      expect(WasteCategory.wet.color, '#4CAF50'); // Green
      expect(WasteCategory.dry.color, '#FFC107'); // Amber
      expect(WasteCategory.hazardous.color, '#FF5722'); // Deep Orange
      expect(WasteCategory.medical.color, '#F44336'); // Red
      expect(WasteCategory.nonWaste.color, '#9C27B0'); // Purple
    });
  });
}
