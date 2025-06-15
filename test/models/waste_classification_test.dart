import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('WasteClassification', () {
    test('should create a WasteClassification with all fields', () {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test_123',
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        materialType: 'PET',
        recyclingCode: 1,
        explanation: 'This is a recyclable plastic bottle made of PET plastic.',
        disposalMethod: 'Recycling',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Place in recycling bin',
          steps: ['Remove cap and label', 'Rinse clean', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        userId: 'user123',
        region: 'North America',
        imageUrl: '/path/to/image.jpg',
        visualFeatures: ['cylindrical', 'transparent', 'plastic'],
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        colorCode: '#00FF00',
        riskLevel: 'low',
        brand: 'EcoBrand',
        product: 'Water Bottle',
        barcode: '123456789012',
        isSaved: false,
        userConfirmed: true,
          confidence: 0.95,
        modelVersion: 'v2.1',
        processingTimeMs: 180,
        modelSource: 'waste_classifier_v2',
        alternatives: [],
        suggestedAction: 'Recycle in appropriate bin',
        hasUrgentTimeframe: false,
        instructionsLang: 'en',
        source: 'ai_classification',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

      expect(classification.id, 'test_123');
      expect(classification.itemName, 'Plastic Bottle');
      expect(classification.category, 'Dry Waste');
      expect(classification.subcategory, 'Plastic');
      expect(classification.materialType, 'PET');
      expect(classification.recyclingCode, 1);
      expect(classification.explanation, contains('recyclable'));
      expect(classification.disposalMethod, 'Recycling');
      expect(classification.userId, 'user123');
      expect(classification.region, 'North America');
      expect(classification.imageUrl, '/path/to/image.jpg');
      expect(classification.visualFeatures, contains('plastic'));
      expect(classification.isRecyclable, true);
      expect(classification.isCompostable, false);
      expect(classification.requiresSpecialDisposal, false);
      expect(classification.colorCode, '#00FF00');
      expect(classification.riskLevel, 'low');
      expect(classification.brand, 'EcoBrand');
      expect(classification.product, 'Water Bottle');
      expect(classification.barcode, '123456789012');
      expect(classification.isSaved, false);
      expect(classification.userConfirmed, true);
        expect(classification.confidence, 0.95);
      expect(classification.modelVersion, 'v2.1');
      expect(classification.processingTimeMs, 180);
      expect(classification.modelSource, 'waste_classifier_v2');
      expect(classification.alternatives, isEmpty);
      expect(classification.suggestedAction, 'Recycle in appropriate bin');
      expect(classification.hasUrgentTimeframe, false);
      expect(classification.instructionsLang, 'en');
      expect(classification.source, 'ai_classification');
        expect(classification.timestamp, DateTime(2024, 1, 15, 10, 30));
      });

    test('should create a minimal WasteClassification with required fields only', () {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Unknown Item',
        category: 'Dry Waste',
        explanation: 'Basic classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'General waste',
          steps: ['Dispose in general waste bin'],
          hasUrgentTimeframe: false,
        ),
        region: 'Unknown',
        visualFeatures: [],
        alternatives: [],
      );

      expect(classification.itemName, 'Unknown Item');
      expect(classification.category, 'Dry Waste');
      expect(classification.explanation, 'Basic classification');
      expect(classification.region, 'Unknown');
      expect(classification.visualFeatures, isEmpty);
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

    test('should handle confidence levels correctly', () {
        final highConfidence = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'high',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
        );

        final mediumConfidence = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'medium',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.75,
        );

        final lowConfidence = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'low',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.45,
      );

      expect(highConfidence.confidence, 0.95);
      expect(mediumConfidence.confidence, 0.75);
      expect(lowConfidence.confidence, 0.45);
    });

    test('should handle user confirmation states', () {
      final accurate = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'accurate',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
          userConfirmed: true,
      );

      final inaccurate = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'inaccurate',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        userConfirmed: false,
        userCorrection: 'Wet Waste',
      );

      final unconfirmed = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'unconfirmed',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
      );

      expect(accurate.userConfirmed, true);
      expect(inaccurate.userConfirmed, false);
      expect(inaccurate.userCorrection, 'Wet Waste');
      expect(unconfirmed.userConfirmed, isNull);
    });

    test('should handle timestamps correctly', () {
      final recent = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'recent',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        timestamp: DateTime.now(),
      );

      final old = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'old',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
        );

      expect(recent.timestamp.isAfter(old.timestamp), true);
      expect(old.timestamp.isBefore(DateTime.now()), true);
    });

    test('should handle sharing and confirmation states', () {
      final shareable = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'shareable',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
          userConfirmed: true,
        confidence: 0.9,
      );

      final unconfirmed = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'unconfirmed',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        clarificationNeeded: true,
      );

      expect(shareable.userConfirmed, true);
      expect(shareable.confidence, 0.9);
      expect(unconfirmed.clarificationNeeded, true);
    });

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

    test('should convert WasteClassification to JSON', () {
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test_to_json',
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: ['feature1'],
        alternatives: [],
        confidence: 0.9,
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

      final json = classification.toJson();

      expect(json['id'], 'test_to_json');
      expect(json['itemName'], 'Test Item');
      expect(json['category'], 'Dry Waste');
      expect(json['explanation'], 'Test explanation');
      expect(json['region'], 'Test Region');
      expect(json['visualFeatures'], ['feature1']);
      expect(json['confidence'], 0.9);
      expect(json['timestamp'], '2024-01-15T10:30:00.000');
    });

    test('should handle validation edge cases', () {
      // Test with empty required fields
      expect(() => WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: '',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
      ), returnsNormally); // Should not throw

      // Test with null confidence
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
      );

      expect(classification.confidence, isNull);
    });

    test('should handle complex disposal instructions', () {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'complex_disposal',
        itemName: 'Electronic Device',
        category: 'Hazardous Waste',
        explanation: 'Electronic waste requires special handling',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'E-waste recycling center',
          steps: [
            'Remove batteries if possible',
            'Wipe personal data',
            'Take to certified e-waste facility',
          ],
          hasUrgentTimeframe: true,
          warnings: ['Contains hazardous materials'],
          tips: ['Check manufacturer take-back programs'],
        ),
        region: 'North America',
        visualFeatures: ['electronic', 'plastic', 'metal'],
        alternatives: [],
        requiresSpecialDisposal: true,
        riskLevel: 'high',
      );

      expect(classification.disposalInstructions.primaryMethod, 'E-waste recycling center');
      expect(classification.disposalInstructions.steps, hasLength(3));
      expect(classification.disposalInstructions.hasUrgentTimeframe, true);
      expect(classification.requiresSpecialDisposal, true);
      expect(classification.riskLevel, 'high');
    });
  });
}
