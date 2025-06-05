import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('WasteClassification Model Tests', () {
    group('WasteClassification Model', () {
      test('should create WasteClassification with all required properties', () {
        final classification = WasteClassification(
          id: 'class_001',
          imagePath: '/path/to/image.jpg',
          category: 'plastic',
          confidence: 0.95,
          disposalInstructions: 'Place in recycling bin',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        expect(classification.id, 'class_001');
        expect(classification.imagePath, '/path/to/image.jpg');
        expect(classification.category, 'plastic');
        expect(classification.confidence, 0.95);
        expect(classification.disposalInstructions, 'Place in recycling bin');
        expect(classification.timestamp, DateTime(2024, 1, 15, 10, 30));
      });

      test('should create WasteClassification with optional properties', () {
        final classification = WasteClassification(
          id: 'class_002',
          imagePath: '/path/to/image.jpg',
          category: 'paper',
          confidence: 0.88,
          disposalInstructions: 'Place in paper recycling',
          timestamp: DateTime(2024, 1, 15, 10, 30),
          subcategory: 'newspaper',
          location: 'Living Room',
          notes: 'Clean and dry',
          isRecyclable: true,
          isBiodegradable: false,
          environmentalImpact: EnvironmentalImpact.low,
          tags: ['clean', 'dry', 'newspaper'],
          userConfirmed: true,
          correctCategory: 'paper',
          processingTime: 250,
          aiModel: 'waste_classifier_v2',
          deviceInfo: 'iPhone 12',
          imageSize: 1024000,
          imageFormat: 'JPEG',
        );

        expect(classification.subcategory, 'newspaper');
        expect(classification.location, 'Living Room');
        expect(classification.notes, 'Clean and dry');
        expect(classification.isRecyclable, true);
        expect(classification.isBiodegradable, false);
        expect(classification.environmentalImpact, EnvironmentalImpact.low);
        expect(classification.tags, ['clean', 'dry', 'newspaper']);
        expect(classification.userConfirmed, true);
        expect(classification.correctCategory, 'paper');
        expect(classification.processingTime, 250);
        expect(classification.aiModel, 'waste_classifier_v2');
        expect(classification.deviceInfo, 'iPhone 12');
        expect(classification.imageSize, 1024000);
        expect(classification.imageFormat, 'JPEG');
      });

      test('should serialize WasteClassification to JSON correctly', () {
        final classification = WasteClassification(
          id: 'class_003',
          imagePath: '/path/to/image.jpg',
          category: 'glass',
          confidence: 0.92,
          disposalInstructions: 'Place in glass recycling bin',
          timestamp: DateTime(2024, 1, 15, 10, 30),
          subcategory: 'bottle',
          location: 'Kitchen',
          isRecyclable: true,
          environmentalImpact: EnvironmentalImpact.medium,
          tags: ['bottle', 'clear'],
        );

        final json = classification.toJson();

        expect(json['id'], 'class_003');
        expect(json['imagePath'], '/path/to/image.jpg');
        expect(json['category'], 'glass');
        expect(json['confidence'], 0.92);
        expect(json['disposalInstructions'], 'Place in glass recycling bin');
        expect(json['timestamp'], isA<String>());
        expect(json['subcategory'], 'bottle');
        expect(json['location'], 'Kitchen');
        expect(json['isRecyclable'], true);
        expect(json['environmentalImpact'], 'medium');
        expect(json['tags'], ['bottle', 'clear']);
      });

      test('should deserialize WasteClassification from JSON correctly', () {
        final json = {
          'id': 'class_004',
          'imagePath': '/path/to/image.jpg',
          'category': 'organic',
          'confidence': 0.89,
          'disposalInstructions': 'Place in compost bin',
          'timestamp': '2024-01-15T10:30:00.000',
          'subcategory': 'food_waste',
          'location': 'Kitchen',
          'notes': 'Fruit peels',
          'isRecyclable': false,
          'isBiodegradable': true,
          'environmentalImpact': 'high',
          'tags': ['fruit', 'compost'],
          'userConfirmed': true,
          'correctCategory': 'organic',
          'processingTime': 180,
          'aiModel': 'waste_classifier_v2',
        };

        final classification = WasteClassification.fromJson(json);

        expect(classification.id, 'class_004');
        expect(classification.imagePath, '/path/to/image.jpg');
        expect(classification.category, 'organic');
        expect(classification.confidence, 0.89);
        expect(classification.disposalInstructions, 'Place in compost bin');
        expect(classification.timestamp, DateTime(2024, 1, 15, 10, 30));
        expect(classification.subcategory, 'food_waste');
        expect(classification.location, 'Kitchen');
        expect(classification.notes, 'Fruit peels');
        expect(classification.isRecyclable, false);
        expect(classification.isBiodegradable, true);
        expect(classification.environmentalImpact, EnvironmentalImpact.high);
        expect(classification.tags, ['fruit', 'compost']);
        expect(classification.userConfirmed, true);
        expect(classification.correctCategory, 'organic');
        expect(classification.processingTime, 180);
        expect(classification.aiModel, 'waste_classifier_v2');
      });

      test('should calculate confidence level correctly', () {
        final highConfidence = WasteClassification(
          id: 'high', imagePath: '/path', category: 'plastic',
          confidence: 0.95, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        );

        final mediumConfidence = WasteClassification(
          id: 'medium', imagePath: '/path', category: 'plastic',
          confidence: 0.75, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        );

        final lowConfidence = WasteClassification(
          id: 'low', imagePath: '/path', category: 'plastic',
          confidence: 0.45, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        );

        expect(highConfidence.confidenceLevel, ConfidenceLevel.high);
        expect(mediumConfidence.confidenceLevel, ConfidenceLevel.medium);
        expect(lowConfidence.confidenceLevel, ConfidenceLevel.low);
      });

      test('should determine if classification needs verification', () {
        final highConfidenceClassification = WasteClassification(
          id: 'high_conf', imagePath: '/path', category: 'plastic',
          confidence: 0.95, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        );

        final lowConfidenceClassification = WasteClassification(
          id: 'low_conf', imagePath: '/path', category: 'plastic',
          confidence: 0.45, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        );

        expect(highConfidenceClassification.needsVerification, false);
        expect(lowConfidenceClassification.needsVerification, true);
      });

      test('should check if classification is accurate', () {
        final accurateClassification = WasteClassification(
          id: 'accurate', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
          userConfirmed: true,
          correctCategory: 'plastic',
        );

        final inaccurateClassification = WasteClassification(
          id: 'inaccurate', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
          userConfirmed: true,
          correctCategory: 'paper',
        );

        final unconfirmedClassification = WasteClassification(
          id: 'unconfirmed', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
          userConfirmed: false,
        );

        expect(accurateClassification.isAccurate, true);
        expect(inaccurateClassification.isAccurate, false);
        expect(unconfirmedClassification.isAccurate, null);
      });

      test('should calculate age of classification', () {
        final recentClassification = WasteClassification(
          id: 'recent', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        );

        final oldClassification = WasteClassification(
          id: 'old', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
        );

        expect(recentClassification.ageInHours, 2);
        expect(recentClassification.ageInDays, 0);
        expect(recentClassification.isRecent, true);

        expect(oldClassification.ageInDays, 30);
        expect(oldClassification.isRecent, false);
      });

      test('should determine if classification can be shared', () {
        final shareableClassification = WasteClassification(
          id: 'shareable', imagePath: '/path', category: 'plastic',
          confidence: 0.95, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
          userConfirmed: true,
        );

        final unconfirmedClassification = WasteClassification(
          id: 'unconfirmed', imagePath: '/path', category: 'plastic',
          confidence: 0.45, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
          userConfirmed: false,
        );

        expect(shareableClassification.canBeShared, true);
        expect(unconfirmedClassification.canBeShared, false);
      });

      test('should get environmental impact score', () {
        expect(EnvironmentalImpact.low.score, 1);
        expect(EnvironmentalImpact.medium.score, 2);
        expect(EnvironmentalImpact.high.score, 3);
        expect(EnvironmentalImpact.critical.score, 4);
      });

      test('should get environmental impact color', () {
        expect(EnvironmentalImpact.low.color, 'green');
        expect(EnvironmentalImpact.medium.color, 'yellow');
        expect(EnvironmentalImpact.high.color, 'orange');
        expect(EnvironmentalImpact.critical.color, 'red');
      });

      test('should get environmental impact description', () {
        expect(EnvironmentalImpact.low.description, contains('Low'));
        expect(EnvironmentalImpact.medium.description, contains('Medium'));
        expect(EnvironmentalImpact.high.description, contains('High'));
        expect(EnvironmentalImpact.critical.description, contains('Critical'));
      });
    });

    group('Classification Categories', () {
      test('should handle all waste categories', () {
        final categories = [
          WasteCategory.plastic,
          WasteCategory.paper,
          WasteCategory.glass,
          WasteCategory.metal,
          WasteCategory.organic,
          WasteCategory.electronic,
          WasteCategory.hazardous,
          WasteCategory.textile,
          WasteCategory.other,
        ];

        for (final category in categories) {
          expect(category.displayName, isNotEmpty);
          expect(category.description, isNotEmpty);
          expect(category.icon, isNotEmpty);
        }
      });

      test('should provide category disposal instructions', () {
        expect(WasteCategory.plastic.defaultDisposalInstructions, contains('recycling'));
        expect(WasteCategory.paper.defaultDisposalInstructions, contains('paper'));
        expect(WasteCategory.glass.defaultDisposalInstructions, contains('glass'));
        expect(WasteCategory.organic.defaultDisposalInstructions, contains('compost'));
        expect(WasteCategory.hazardous.defaultDisposalInstructions, contains('hazardous'));
      });

      test('should indicate if category is recyclable', () {
        expect(WasteCategory.plastic.isGenerallyRecyclable, true);
        expect(WasteCategory.paper.isGenerallyRecyclable, true);
        expect(WasteCategory.glass.isGenerallyRecyclable, true);
        expect(WasteCategory.metal.isGenerallyRecyclable, true);
        expect(WasteCategory.organic.isGenerallyRecyclable, false);
        expect(WasteCategory.hazardous.isGenerallyRecyclable, false);
      });

      test('should indicate if category is biodegradable', () {
        expect(WasteCategory.organic.isGenerallyBiodegradable, true);
        expect(WasteCategory.paper.isGenerallyBiodegradable, true);
        expect(WasteCategory.plastic.isGenerallyBiodegradable, false);
        expect(WasteCategory.glass.isGenerallyBiodegradable, false);
        expect(WasteCategory.metal.isGenerallyBiodegradable, false);
      });

      test('should get category environmental impact', () {
        expect(WasteCategory.organic.typicalEnvironmentalImpact, EnvironmentalImpact.low);
        expect(WasteCategory.paper.typicalEnvironmentalImpact, EnvironmentalImpact.low);
        expect(WasteCategory.plastic.typicalEnvironmentalImpact, EnvironmentalImpact.medium);
        expect(WasteCategory.electronic.typicalEnvironmentalImpact, EnvironmentalImpact.high);
        expect(WasteCategory.hazardous.typicalEnvironmentalImpact, EnvironmentalImpact.critical);
      });
    });

    group('Classification Statistics', () {
      test('should calculate accuracy from multiple classifications', () {
        final classifications = [
          WasteClassification(
            id: '1', imagePath: '/path1', category: 'plastic',
            confidence: 0.9, disposalInstructions: 'Recycle',
            timestamp: DateTime.now(), userConfirmed: true, correctCategory: 'plastic',
          ),
          WasteClassification(
            id: '2', imagePath: '/path2', category: 'paper',
            confidence: 0.8, disposalInstructions: 'Recycle',
            timestamp: DateTime.now(), userConfirmed: true, correctCategory: 'paper',
          ),
          WasteClassification(
            id: '3', imagePath: '/path3', category: 'glass',
            confidence: 0.7, disposalInstructions: 'Recycle',
            timestamp: DateTime.now(), userConfirmed: true, correctCategory: 'plastic', // Wrong!
          ),
        ];

        final accurateCount = classifications.where((c) => c.isAccurate == true).length;
        final totalConfirmed = classifications.where((c) => c.userConfirmed == true).length;
        final accuracy = accurateCount / totalConfirmed;

        expect(accuracy, closeTo(0.667, 0.01));
      });

      test('should calculate average confidence', () {
        final classifications = [
          WasteClassification(
            id: '1', imagePath: '/path1', category: 'plastic',
            confidence: 0.9, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
          WasteClassification(
            id: '2', imagePath: '/path2', category: 'paper',
            confidence: 0.8, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
          WasteClassification(
            id: '3', imagePath: '/path3', category: 'glass',
            confidence: 0.7, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
        ];

        final totalConfidence = classifications.fold<double>(
          0.0, (sum, c) => sum + c.confidence
        );
        final averageConfidence = totalConfidence / classifications.length;

        expect(averageConfidence, closeTo(0.8, 0.01));
      });

      test('should count classifications by category', () {
        final classifications = [
          WasteClassification(
            id: '1', imagePath: '/path1', category: 'plastic',
            confidence: 0.9, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
          WasteClassification(
            id: '2', imagePath: '/path2', category: 'plastic',
            confidence: 0.8, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
          WasteClassification(
            id: '3', imagePath: '/path3', category: 'paper',
            confidence: 0.7, disposalInstructions: 'Recycle', timestamp: DateTime.now(),
          ),
        ];

        final categoryCount = <String, int>{};
        for (final classification in classifications) {
          categoryCount[classification.category] = 
            (categoryCount[classification.category] ?? 0) + 1;
        }

        expect(categoryCount['plastic'], 2);
        expect(categoryCount['paper'], 1);
      });
    });

    group('Classification Validation', () {
      test('should validate confidence range', () {
        expect(() => WasteClassification(
          id: 'invalid', imagePath: '/path', category: 'plastic',
          confidence: 1.5, // Invalid: > 1.0
          disposalInstructions: 'Recycle', timestamp: DateTime.now(),
        ), throwsArgumentError);

        expect(() => WasteClassification(
          id: 'invalid', imagePath: '/path', category: 'plastic',
          confidence: -0.1, // Invalid: < 0.0
          disposalInstructions: 'Recycle', timestamp: DateTime.now(),
        ), throwsArgumentError);
      });

      test('should validate required fields', () {
        expect(() => WasteClassification(
          id: '', // Empty ID
          imagePath: '/path', category: 'plastic',
          confidence: 0.8, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        ), throwsArgumentError);

        expect(() => WasteClassification(
          id: 'valid', imagePath: '', // Empty image path
          category: 'plastic', confidence: 0.8,
          disposalInstructions: 'Recycle', timestamp: DateTime.now(),
        ), throwsArgumentError);

        expect(() => WasteClassification(
          id: 'valid', imagePath: '/path',
          category: '', // Empty category
          confidence: 0.8, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(),
        ), throwsArgumentError);
      });

      test('should validate processing time', () {
        expect(() => WasteClassification(
          id: 'valid', imagePath: '/path', category: 'plastic',
          confidence: 0.8, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(), processingTime: -100, // Negative time
        ), throwsArgumentError);
      });

      test('should validate image size', () {
        expect(() => WasteClassification(
          id: 'valid', imagePath: '/path', category: 'plastic',
          confidence: 0.8, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(), imageSize: -1000, // Negative size
        ), throwsArgumentError);
      });
    });

    group('Copy and Update', () {
      test('should create copy with updated properties', () {
        final original = WasteClassification(
          id: 'original', imagePath: '/path', category: 'plastic',
          confidence: 0.8, disposalInstructions: 'Recycle',
          timestamp: DateTime.now(), userConfirmed: false,
        );

        final updated = original.copyWith(
          userConfirmed: true,
          correctCategory: 'paper',
          notes: 'User correction',
        );

        expect(updated.id, original.id);
        expect(updated.category, original.category);
        expect(updated.userConfirmed, true);
        expect(updated.correctCategory, 'paper');
        expect(updated.notes, 'User correction');
        expect(original.userConfirmed, false); // Original unchanged
      });
    });

    group('Equality and Comparison', () {
      test('should compare WasteClassification for equality', () {
        final classification1 = WasteClassification(
          id: 'class_001', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final classification2 = WasteClassification(
          id: 'class_001', imagePath: '/path', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Recycle',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final classification3 = WasteClassification(
          id: 'class_002', imagePath: '/path2', category: 'paper',
          confidence: 0.90, disposalInstructions: 'Recycle paper',
          timestamp: DateTime(2024, 1, 16, 11, 30),
        );

        expect(classification1 == classification2, true);
        expect(classification1 == classification3, false);
        expect(classification1.hashCode == classification2.hashCode, true);
      });

      test('should sort classifications by timestamp', () {
        final classifications = [
          WasteClassification(
            id: 'class_3', imagePath: '/path3', category: 'glass',
            confidence: 0.7, disposalInstructions: 'Recycle',
            timestamp: DateTime(2024, 1, 17, 12),
          ),
          WasteClassification(
            id: 'class_1', imagePath: '/path1', category: 'plastic',
            confidence: 0.9, disposalInstructions: 'Recycle',
            timestamp: DateTime(2024, 1, 15, 10),
          ),
          WasteClassification(
            id: 'class_2', imagePath: '/path2', category: 'paper',
            confidence: 0.8, disposalInstructions: 'Recycle',
            timestamp: DateTime(2024, 1, 16, 11),
          ),
        ];

        // Sort by timestamp (newest first)
        classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        expect(classifications[0].id, 'class_3');
        expect(classifications[1].id, 'class_2');
        expect(classifications[2].id, 'class_1');
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final classification = WasteClassification(
          id: 'class_001', imagePath: '/path/image.jpg', category: 'plastic',
          confidence: 0.85, disposalInstructions: 'Place in recycling bin',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final stringRepresentation = classification.toString();

        expect(stringRepresentation, contains('class_001'));
        expect(stringRepresentation, contains('plastic'));
        expect(stringRepresentation, contains('0.85'));
      });
    });
  });
}
