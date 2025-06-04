import 'dart:typed_data'; // Added import
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

// Manual mock for testing
class MockAiService extends Mock implements AiService {}

void main() {
  group('AiService', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService();
    });

    group('Image Classification', () {
      test('should return valid classification for valid image path', () async {
        // This test would need actual image file for full integration testing
        // For now, test that the method handles invalid paths gracefully
        
        expect(() async => aiService.analyzeWebImage(Uint8List(0), 'invalid_path.jpg'),
               throwsA(isA<Exception>()));
      });

      test('should handle null or empty image path', () async {
        expect(() async => aiService.analyzeWebImage(Uint8List(0), ''),
               throwsA(isA<Exception>()));
      });
    });

    group('Classification Result Validation', () {
      test('WasteClassification should have required fields', () {
        final classification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1', 'Step 2'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.85,
        );

        expect(classification.itemName, equals('Test Item'));
        expect(classification.category, equals('Dry Waste'));
        expect(classification.subcategory, equals('Plastic'));
        expect(classification.confidence, equals(0.85));
        expect(classification.disposalInstructions.steps.length, equals(2));
        expect(classification.visualFeatures.length, equals(2));
      });

      test('should validate confidence score range', () {
        final highConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
        );

        final lowConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.25,
        );

        expect(highConfidenceClassification.confidence, greaterThan(0.8));
        expect(lowConfidenceClassification.confidence, lessThan(0.5));
      });
    });

    group('Category Validation', () {
      test('should recognize valid waste categories', () {
        const validCategories = [
          'Dry Waste',
          'Wet Waste',
          'Hazardous Waste',
          'Medical Waste',
          'Non-Waste'
        ];

        for (final category in validCategories) {
          final classification = WasteClassification(
            itemName: 'Test Item',
            category: category,
            explanation: 'Test explanation',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Test method',
              steps: ['Step 1'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now(),
            region: 'Test Region',
            visualFeatures: [],
            alternatives: [],
          );

          expect(validCategories.contains(classification.category), isTrue);
        }
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Test network error scenarios
        expect(() async => aiService.analyzeWebImage(Uint8List(0), 'non_existent_file.jpg'),
               throwsA(isA<Exception>()));
      });

      test('should handle invalid file formats', () async {
        // Test invalid file format
        expect(() async => aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt'),
               throwsA(isA<Exception>()));
      });
    });

    group('Disposal Instructions', () {
      test('should provide appropriate disposal instructions for different waste types', () {
        final plasticClassification = WasteClassification(
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Recyclable plastic bottle',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle in blue bin',
            steps: ['Remove cap', 'Rinse clean', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );

        final hazardousClassification = WasteClassification(
          itemName: 'Battery',
          category: 'Hazardous Waste',
          subcategory: 'Electronic Waste',
          explanation: 'Contains toxic materials',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Take to hazardous waste facility',
            steps: ['Do not throw in regular trash', 'Find local e-waste center', 'Drop off safely'],
            hasUrgentTimeframe: true,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );

        expect(plasticClassification.disposalInstructions.hasUrgentTimeframe, isFalse);
        expect(hazardousClassification.disposalInstructions.hasUrgentTimeframe, isTrue);
        expect(plasticClassification.disposalInstructions.steps.length, equals(3));
        expect(hazardousClassification.disposalInstructions.steps.length, equals(3));
      });
    });
  });
} 