import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/services/tflite_preprocessing_helper.dart';

void main() {
  group('TFLitePreprocessingHelper', () {
    late img.Image testImage;

    setUp(() {
      // Create a test image: 100x100 RGB
      testImage = img.Image(width: 100, height: 100);
      
      // Fill with test pattern (red pixels)
      for (int y = 0; y < testImage.height; y++) {
        for (int x = 0; x < testImage.width; x++) {
          testImage.setPixelRgba(x, y, 255, 0, 0, 255); // Red
        }
      }
    });

    group('preprocessImageForInference', () {
      test('resizes image to specified dimensions', () async {
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: testImage,
          inputWidth: 224,
          inputHeight: 224,
          normalize: false,
        );

        expect(result, isNotNull);
        expect(result, isNotEmpty);
        expect(result[0].length, equals(224 * 224 * 3));
      });

      test('normalizes pixel values correctly', () async {
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: testImage,
          inputWidth: 10,
          inputHeight: 10,
          normalize: true,
          normalizeMin: -1.0,
          normalizeMax: 1.0,
        );

        expect(result, isNotEmpty);
        final float32List = result[0];
        
        // Check normalized values are in expected range
        for (final value in float32List) {
          expect(value, greaterThanOrEqualTo(-1.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('handles different normalization ranges', () async {
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: testImage,
          inputWidth: 10,
          inputHeight: 10,
          normalize: true,
          normalizeMin: 0.0,
          normalizeMax: 1.0,
        );

        expect(result, isNotEmpty);
        final float32List = result[0];
        
        for (final value in float32List) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('returns Float32List with correct size', () async {
        const width = 128;
        const height = 128;
        
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: testImage,
          inputWidth: width,
          inputHeight: height,
          normalize: false,
        );

        expect(result[0].length, equals(width * height * 3));
      });
    });

    group('postprocessProbabilities', () {
      test('filters by confidence threshold', () {
        final predictions = [0.1, 0.5, 0.9, 0.3];
        final labels = ['class_a', 'class_b', 'class_c', 'class_d'];

        final result = TFLitePreprocessingHelper.postprocessProbabilities(
          predictions: predictions,
          labels: labels,
          confidenceThreshold: 0.6,
        );

        expect(result.length, equals(1));
        expect(result['class_c'], equals(0.9));
      });

      test('returns all predictions with zero threshold', () {
        final predictions = [0.1, 0.5, 0.9, 0.3];
        final labels = ['class_a', 'class_b', 'class_c', 'class_d'];

        final result = TFLitePreprocessingHelper.postprocessProbabilities(
          predictions: predictions,
          labels: labels,
          confidenceThreshold: 0.0,
        );

        expect(result.length, equals(4));
      });

      test('throws error on mismatched lengths', () {
        expect(
          () => TFLitePreprocessingHelper.postprocessProbabilities(
            predictions: [0.1, 0.5],
            labels: ['a', 'b', 'c'],
            confidenceThreshold: 0.5,
          ),
          throwsArgumentError,
        );
      });
    });

    group('getTopPredictions', () {
      test('returns top N predictions sorted by confidence', () {
        final predictions = [0.1, 0.95, 0.5, 0.85, 0.3];
        final labels = ['a', 'b', 'c', 'd', 'e'];

        final result = TFLitePreprocessingHelper.getTopPredictions(
          predictions: predictions,
          labels: labels,
          topN: 3,
        );

        expect(result.length, equals(3));
        expect(result[0].key, equals('b')); // 0.95
        expect(result[0].value, equals(0.95));
        expect(result[1].key, equals('d')); // 0.85
        expect(result[2].key, equals('c')); // 0.5
      });

      test('returns fewer items if N is larger than predictions', () {
        final predictions = [0.1, 0.5];
        final labels = ['a', 'b'];

        final result = TFLitePreprocessingHelper.getTopPredictions(
          predictions: predictions,
          labels: labels,
          topN: 10,
        );

        expect(result.length, equals(2));
      });

      test('throws error on mismatched lengths', () {
        expect(
          () => TFLitePreprocessingHelper.getTopPredictions(
            predictions: [0.1, 0.5],
            labels: ['a', 'b', 'c'],
            topN: 2,
          ),
          throwsArgumentError,
        );
      });
    });

    group('decodeImageBytes', () {
      test('decodes valid PNG image bytes', () {
        // Create a simple test PNG
        final testImage = img.Image(width: 10, height: 10);
        final pngBytes = img.encodePng(testImage);

        final decoded = TFLitePreprocessingHelper.decodeImageBytes(pngBytes);

        expect(decoded, isNotNull);
        expect(decoded.width, equals(10));
        expect(decoded.height, equals(10));
      });
    });

    group('batchPreprocessImages', () {
      test('processes multiple images correctly', () async {
        final images = [testImage, testImage, testImage];

        final results = await TFLitePreprocessingHelper.batchPreprocessImages(
          images: images,
          inputWidth: 64,
          inputHeight: 64,
          normalize: false,
        );

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result.length, equals(1));
          expect(result[0].length, equals(64 * 64 * 3));
        }
      });

      test('handles empty image list', () async {
        final results = await TFLitePreprocessingHelper.batchPreprocessImages(
          images: [],
          inputWidth: 64,
          inputHeight: 64,
        );

        expect(results, isEmpty);
      });
    });

    group('edge cases', () {
      test('handles very small image input', () async {
        final tinyImage = img.Image(width: 2, height: 2);
        
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: tinyImage,
          inputWidth: 224,
          inputHeight: 224,
          normalize: false,
        );

        expect(result, isNotEmpty);
        expect(result[0].length, equals(224 * 224 * 3));
      });

      test('handles very large output dimensions', () async {
        final result = await TFLitePreprocessingHelper.preprocessImageForInference(
          image: testImage,
          inputWidth: 512,
          inputHeight: 512,
          normalize: false,
        );

        expect(result[0].length, equals(512 * 512 * 3));
      });
    });
  });
}
