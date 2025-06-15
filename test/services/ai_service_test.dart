import 'dart:typed_data'; // Added import
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../test_helper.dart';
import 'dart:convert';

// Simple mock for testing without external dependencies
class MockAiService {
  WasteClassification? _mockResult;
  Exception? _mockException;
  
  void setMockResult(WasteClassification result) {
    _mockResult = result;
    _mockException = null;
  }
  
  void setMockException(Exception exception) {
    _mockException = exception;
    _mockResult = null;
  }
  
  Future<WasteClassification> analyzeWebImage(Uint8List imageData, String filename) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockResult!;
  }
}

void main() {
  group('AiService', () {
    late AiService aiService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      aiService = AiService();
    });

    tearDown(() async {
      await TestHelper.cleanupServiceTest();
    });

    group('Image Classification', () {
      test('should handle empty image gracefully', () async {
        // Test that the service handles empty image data appropriately
        // This should either throw an exception or return a fallback classification
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'test.jpg');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for empty image data
          expect(e, isA<Exception>());
        }
      });

      test('should handle null or empty image path', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), '');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for null/empty image path
          expect(e, isA<Exception>());
        }
      });

      test('should handle invalid file extension', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for invalid file extensions
          expect(e, isA<Exception>());
        }
      });

      // Test with mock service to avoid real API calls
      test('should return classification result from mock service', () async {
        final mockService = MockAiService();
        final expectedClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'This is a plastic bottle that can be recycled',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean the bottle', 'Remove cap', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle', 'transparent'],
          alternatives: [],
          confidence: 0.95,
        );

        mockService.setMockResult(expectedClassification);

        final result = await mockService.analyzeWebImage(
          Uint8List.fromList([1, 2, 3, 4]), 
          'test.jpg'
        );

        expect(result, isA<WasteClassification>());
        expect(result.itemName, equals('Plastic Bottle'));
        expect(result.category, equals('Dry Waste'));
        expect(result.confidence, equals(0.95));
      });
    });

    group('Classification Result Validation', () {
      test('WasteClassification should have required fields', () {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
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
        final highConfidenceClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
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

        final lowConfidenceClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
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
          final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
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
        // Test that the service handles network errors appropriately
        // This should either throw an exception or return a fallback classification
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'non_existent_file.jpg');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for network errors
          expect(e, isA<Exception>());
        }
      });

      test('should handle invalid file formats', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for invalid file formats
          expect(e, isA<Exception>());
        }
      });

      test('should handle mock API errors', () async {
        final mockService = MockAiService();
        
        mockService.setMockException(Exception('Mock API Error'));

        expect(
          () async => mockService.analyzeWebImage(
            Uint8List.fromList([1, 2, 3, 4]), 
            'test.jpg'
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Service Configuration', () {
      test('should initialize with default configuration', () {
        final service = AiService();
        expect(service, isNotNull);
        expect(service.cachingEnabled, isTrue);
        expect(service.defaultRegion, equals('Bangalore, IN'));
        expect(service.defaultLanguage, equals('en'));
      });

      test('should initialize with custom configuration', () {
        final service = AiService(
          cachingEnabled: false,
          defaultRegion: 'Mumbai, IN',
          defaultLanguage: 'hi',
        );
        expect(service, isNotNull);
        expect(service.cachingEnabled, isFalse);
        expect(service.defaultRegion, equals('Mumbai, IN'));
        expect(service.defaultLanguage, equals('hi'));
      });
    });

    group('JSON parsing with comments', () {
      test('should parse JSON with single-line comments', () {
        const jsonWithComments = '''
        {
          "itemName": "Red Pen", // This is a red writing instrument
          "category": "Dry Waste",
          "subcategory": "Plastic", // Made of plastic material
          "explanation": "A red plastic pen used for writing"
        }''';
        
        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(jsonWithComments);
        
        expect(() => jsonDecode(cleanedJson), returnsNormally);
        
        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Red Pen'));
        expect(parsed['category'], equals('Dry Waste'));
        expect(parsed['subcategory'], equals('Plastic'));
      });

      test('should parse JSON with multi-line comments', () {
        const jsonWithComments = '''
        {
          "itemName": "Blue Bottle", /* This is a 
                                        multi-line comment
                                        about the bottle */
          "category": "Dry Waste",
          "explanation": "A blue plastic bottle"
        }''';
        
        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(jsonWithComments);
        
        expect(() => jsonDecode(cleanedJson), returnsNormally);
        
        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Blue Bottle'));
        expect(parsed['category'], equals('Dry Waste'));
      });

      test('should handle JSON without comments', () {
        const normalJson = '''
        {
          "itemName": "Green Can",
          "category": "Dry Waste",
          "subcategory": "Metal"
        }''';
        
        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(normalJson);
        
        expect(() => jsonDecode(cleanedJson), returnsNormally);
        
        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Green Can'));
        expect(parsed['category'], equals('Dry Waste'));
        expect(parsed['subcategory'], equals('Metal'));
      });
    });
  });
} 