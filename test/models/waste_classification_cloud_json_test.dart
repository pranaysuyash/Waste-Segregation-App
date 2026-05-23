import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

WasteClassification _testClassification({String? imageUrl, double? confidence}) {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Dry Waste',
    region: 'Bangalore',
    explanation: 'Test',
    imageUrl: imageUrl,
    confidence: confidence,
    visualFeatures: [],
    alternatives: [],
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: [],
      hasUrgentTimeframe: false,
    ),
  );
}

void main() {
  group('WasteClassification.toCloudJson', () {
    test('strips local file paths from imageUrl', () {
      final classification = _testClassification(
        imageUrl: '/Users/pranay/Library/images/abc123.jpg',
      );
      expect(classification.toCloudJson()['imageUrl'], isNull);
    });

    test('preserves https URLs in imageUrl', () {
      final classification = _testClassification(
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/abc.jpg',
      );
      expect(classification.toCloudJson()['imageUrl'], contains('https://'));
    });

    test('preserves http URLs in imageUrl', () {
      final classification = _testClassification(
        imageUrl: 'http://example.com/image.jpg',
      );
      expect(classification.toCloudJson()['imageUrl'], equals('http://example.com/image.jpg'));
    });

    test('preserves web_image data URLs', () {
      final classification = _testClassification(
        imageUrl: 'web_image:data:image/jpeg;base64,/9j/4AAQ',
      );
      expect(classification.toCloudJson()['imageUrl'], startsWith('web_image:'));
    });

    test('strips Android device paths', () {
      final classification = _testClassification(
        imageUrl: '/data/user/0/com.example.waste_app/app_flutter/images/xyz.jpg',
      );
      expect(classification.toCloudJson()['imageUrl'], isNull);
    });

    test('null imageUrl stays null', () {
      final classification = _testClassification();
      expect(classification.toCloudJson()['imageUrl'], isNull);
    });

    test('calculatePoints includes batch bonus', () {
      final classification = _testClassification(confidence: 0.95);
      final normalPoints = classification.calculatePoints();
      final batchPoints = classification.calculatePoints(isBatch: true);
      expect(batchPoints, equals(normalPoints + 5));
    });
  });
}
