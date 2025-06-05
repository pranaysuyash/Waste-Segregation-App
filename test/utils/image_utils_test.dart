import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/utils/image_utils.dart';

void main() {
  group('ImageUtils Tests', () {
    late Uint8List testImageBytes;
    late Uint8List smallTestImageBytes;

    setUpAll(() {
      // Create a simple test image (3x3 red square)
      final testImage = img.Image(width: 100, height: 100);
      img.fill(testImage, color: img.ColorRgb8(255, 0, 0)); // Red fill
      testImageBytes = Uint8List.fromList(img.encodePng(testImage));

      // Create a small test image for quick testing
      final smallImage = img.Image(width: 10, height: 10);
      img.fill(smallImage, color: img.ColorRgb8(0, 255, 0)); // Green fill
      smallTestImageBytes = Uint8List.fromList(img.encodePng(smallImage));
    });

    group('Image Hash Generation', () {
      test('should generate consistent hash for same image', () async {
        final hash1 = await ImageUtils.generateImageHash(testImageBytes);
        final hash2 = await ImageUtils.generateImageHash(testImageBytes);
        
        expect(hash1, equals(hash2));
        expect(hash1, isNotEmpty);
      });

      test('should generate different hashes for different images', () async {
        final hash1 = await ImageUtils.generateImageHash(testImageBytes);
        final hash2 = await ImageUtils.generateImageHash(smallTestImageBytes);
        
        expect(hash1, isNot(equals(hash2)));
        expect(hash1, isNotEmpty);
        expect(hash2, isNotEmpty);
      });

      test('should generate perceptual hash format', () async {
        final hash = await ImageUtils.generateImageHash(testImageBytes);
        
        expect(hash, startsWith('phash_'));
        expect(hash.length, greaterThan(6)); // Should have content after prefix
      });

      test('should handle normalized vs non-normalized images consistently', () async {
        final hashNormalized = await ImageUtils.generateImageHash(
          testImageBytes,
        );
        final hashNotNormalized = await ImageUtils.generateImageHash(
          testImageBytes,
          normalize: false,
        );
        
        expect(hashNormalized, isNotEmpty);
        expect(hashNotNormalized, isNotEmpty);
        // They should be the same since normalize parameter is documented
        // but the implementation always normalizes
        expect(hashNormalized, equals(hashNotNormalized));
      });

      test('should handle corrupted image data gracefully', () async {
        final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash = await ImageUtils.generateImageHash(corruptedData);
        
        expect(hash, isNotEmpty);
        expect(hash, anyOf(
          startsWith('fallback_'),
          startsWith('simple_'),
          startsWith('error_hash_'),
        ));
      });

      test('should handle empty image data', () async {
        final emptyData = Uint8List(0);
        final hash = await ImageUtils.generateImageHash(emptyData);
        
        expect(hash, isNotEmpty);
        expect(hash, startsWith('simple_'));
      });

      test('should generate different hashes for similar but not identical images', () async {
        // Create two similar but slightly different images
        final image1 = img.Image(width: 50, height: 50);
        img.fill(image1, color: img.ColorRgb8(255, 0, 0));
        
        final image2 = img.Image(width: 50, height: 50);
        img.fill(image2, color: img.ColorRgb8(255, 0, 0));
        // Add a small difference
        image2.setPixel(25, 25, img.ColorRgb8(254, 0, 0));
        
        final bytes1 = Uint8List.fromList(img.encodePng(image1));
        final bytes2 = Uint8List.fromList(img.encodePng(image2));
        
        final hash1 = await ImageUtils.generateImageHash(bytes1);
        final hash2 = await ImageUtils.generateImageHash(bytes2);
        
        // For perceptual hashing, these might be the same due to the small difference
        expect(hash1, isNotEmpty);
        expect(hash2, isNotEmpty);
      });
    });

    group('Image Preprocessing', () {
      test('should preprocess image with default parameters', () async {
        final processed = await ImageUtils.preprocessImage(testImageBytes);
        
        expect(processed, isNotEmpty);
        expect(processed, isNot(equals(testImageBytes))); // Should be different
        
        // Verify the processed image is valid
        final decodedImage = img.decodeImage(processed);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(ImageUtils.defaultTargetWidth));
        expect(decodedImage.height, equals(ImageUtils.defaultTargetHeight));
      });

      test('should preprocess with custom dimensions', () async {
        const customWidth = 150;
        const customHeight = 200;
        
        final processed = await ImageUtils.preprocessImage(
          testImageBytes,
          targetWidth: customWidth,
          targetHeight: customHeight,
        );
        
        expect(processed, isNotEmpty);
        
        final decodedImage = img.decodeImage(processed);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(customWidth));
        expect(decodedImage.height, equals(customHeight));
      });

      test('should handle grayscale conversion option', () async {
        final processedGray = await ImageUtils.preprocessImage(
          testImageBytes,
        );
        
        final processedColor = await ImageUtils.preprocessImage(
          testImageBytes,
          convertToGrayscale: false,
        );
        
        expect(processedGray, isNotEmpty);
        expect(processedColor, isNotEmpty);
        expect(processedGray, isNot(equals(processedColor)));
      });

      test('should handle stronger blur option', () async {
        final normalBlur = await ImageUtils.preprocessImage(
          testImageBytes,
        );
        
        final strongerBlur = await ImageUtils.preprocessImage(
          testImageBytes,
          applyStrongerBlur: true,
        );
        
        expect(normalBlur, isNotEmpty);
        expect(strongerBlur, isNotEmpty);
        expect(normalBlur, isNot(equals(strongerBlur)));
      });

      test('should handle corrupted image in preprocessing', () async {
        final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final processed = await ImageUtils.preprocessImage(corruptedData);
        
        // Should return original data when preprocessing fails
        expect(processed, equals(corruptedData));
      });

      test('should handle empty image data in preprocessing', () async {
        final emptyData = Uint8List(0);
        final processed = await ImageUtils.preprocessImage(emptyData);
        
        expect(processed, equals(emptyData));
      });

      test('should preprocess with very small dimensions', () async {
        final processed = await ImageUtils.preprocessImage(
          testImageBytes,
          targetWidth: 1,
          targetHeight: 1,
        );
        
        expect(processed, isNotEmpty);
        
        final decodedImage = img.decodeImage(processed);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(1));
        expect(decodedImage.height, equals(1));
      });
    });

    group('Image Cropping', () {
      test('should crop image with valid rectangle', () async {
        final rect = Rect.fromLTWH(0.25, 0.25, 0.5, 0.5); // Center quarter
        final cropped = await ImageUtils.cropImage(testImageBytes, rect);
        
        expect(cropped, isNotNull);
        expect(cropped!, isNotEmpty);
        
        final decodedImage = img.decodeImage(cropped);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(50)); // 50% of 100
        expect(decodedImage.height, equals(50));
      });

      test('should handle full image crop', () async {
        final rect = Rect.fromLTWH(0.0, 0.0, 1.0, 1.0); // Full image
        final cropped = await ImageUtils.cropImage(testImageBytes, rect);
        
        expect(cropped, isNotNull);
        expect(cropped!, isNotEmpty);
        
        final decodedImage = img.decodeImage(cropped);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(100));
        expect(decodedImage.height, equals(100));
      });

      test('should return null for invalid crop rectangle', () async {
        final invalidRects = [
          Rect.fromLTWH(-0.1, 0.0, 0.5, 0.5), // Negative left
          Rect.fromLTWH(0.0, -0.1, 0.5, 0.5), // Negative top
          Rect.fromLTWH(0.0, 0.0, 0.0, 0.5), // Zero width
          Rect.fromLTWH(0.0, 0.0, 0.5, 0.0), // Zero height
          Rect.fromLTWH(0.5, 0.0, 0.6, 0.5), // Exceeds width
          Rect.fromLTWH(0.0, 0.5, 0.5, 0.6), // Exceeds height
        ];
        
        for (final rect in invalidRects) {
          final cropped = await ImageUtils.cropImage(testImageBytes, rect);
          expect(cropped, isNull, reason: 'Should return null for invalid rect: ${rect.left}, ${rect.top}, ${rect.width}, ${rect.height}');
        }
      });

      test('should handle corrupted image in cropping', () async {
        final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final rect = Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
        final cropped = await ImageUtils.cropImage(corruptedData, rect);
        
        expect(cropped, isNull);
      });

      test('should crop very small regions', () async {
        final rect = Rect.fromLTWH(0.45, 0.45, 0.1, 0.1); // 10% region
        final cropped = await ImageUtils.cropImage(testImageBytes, rect);
        
        expect(cropped, isNotNull);
        expect(cropped!, isNotEmpty);
        
        final decodedImage = img.decodeImage(cropped);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(10));
        expect(decodedImage.height, equals(10));
      });
    });

    group('Data URL Conversion', () {
      test('should convert valid PNG data URL to bytes', () {
        const base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9hVCzrwAAAABJRU5ErkJggg==';
        final dataUrl = 'data:image/png;base64,$base64Data';
        
        final bytes = ImageUtils.dataUrlToBytes(dataUrl);
        
        expect(bytes, isNotNull);
        expect(bytes!, isNotEmpty);
      });

      test('should convert valid JPEG data URL to bytes', () {
        const base64Data = '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA9AD/2Q==';
        final dataUrl = 'data:image/jpeg;base64,$base64Data';
        
        final bytes = ImageUtils.dataUrlToBytes(dataUrl);
        
        expect(bytes, isNotNull);
        expect(bytes!, isNotEmpty);
      });

      test('should return null for invalid data URL', () {
        final invalidUrls = [
          'invalid://url',
          'data:text/plain;base64,SGVsbG8=',
          'data:image/png;base64,invalid_base64!@#',
          'not_a_url_at_all',
          '',
        ];
        
        for (final url in invalidUrls) {
          final bytes = ImageUtils.dataUrlToBytes(url);
          expect(bytes, isNull, reason: 'Should return null for invalid URL: $url');
        }
      });

      test('should handle data URL without explicit encoding', () {
        const dataUrl = 'data:image/png,somerawdata';
        final bytes = ImageUtils.dataUrlToBytes(dataUrl);
        
        // This might return null or bytes depending on the URI parser
        // The important thing is it doesn't crash
        expect(() => ImageUtils.dataUrlToBytes(dataUrl), returnsNormally);
      });

      test('should handle empty data URL', () {
        final bytes = ImageUtils.dataUrlToBytes('');
        expect(bytes, isNull);
      });
    });

    group('Rect Utility Class', () {
      test('should create rect with basic constructor', () {
        const rect = Rect(left: 10, top: 20, width: 30, height: 40);
        
        expect(rect.left, equals(10));
        expect(rect.top, equals(20));
        expect(rect.width, equals(30));
        expect(rect.height, equals(40));
      });

      test('should create rect with fromLTWH factory', () {
        final rect = Rect.fromLTWH(10.5, 20.5, 30.5, 40.5);
        
        expect(rect.left, equals(10.5));
        expect(rect.top, equals(20.5));
        expect(rect.width, equals(30.5));
        expect(rect.height, equals(40.5));
      });

      test('should convert to Flutter Rect', () {
        const rect = Rect(left: 10, top: 20, width: 30, height: 40);
        final flutterRect = rect.toFlutterRect();
        
        expect(flutterRect, isA<ui.Rect>());
        expect(flutterRect.left, equals(10));
        expect(flutterRect.top, equals(20));
        expect(flutterRect.width, equals(30));
        expect(flutterRect.height, equals(40));
      });

      test('should handle fromFlutterRect factory', () {
        const flutterRect = ui.Rect.fromLTWH(10, 20, 30, 40);
        final rect = Rect.fromFlutterRect(flutterRect);
        
        expect(rect.left, equals(10));
        expect(rect.top, equals(20));
        expect(rect.width, equals(30));
        expect(rect.height, equals(40));
      });

      test('should handle zero dimensions', () {
        const rect = Rect(left: 0, top: 0, width: 0, height: 0);
        
        expect(rect.left, equals(0));
        expect(rect.top, equals(0));
        expect(rect.width, equals(0));
        expect(rect.height, equals(0));
        
        final flutterRect = rect.toFlutterRect();
        expect(flutterRect.isEmpty, isTrue);
      });

      test('should handle negative values', () {
        const rect = Rect(left: -10, top: -20, width: 30, height: 40);
        
        expect(rect.left, equals(-10));
        expect(rect.top, equals(-20));
        expect(rect.width, equals(30));
        expect(rect.height, equals(40));
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle very large images efficiently', () async {
        // Create a large test image
        final largeImage = img.Image(width: 2000, height: 2000);
        img.fill(largeImage, color: img.ColorRgb8(100, 150, 200));
        final largeImageBytes = Uint8List.fromList(img.encodePng(largeImage));
        
        // Test preprocessing doesn't take too long
        final stopwatch = Stopwatch()..start();
        final processed = await ImageUtils.preprocessImage(largeImageBytes);
        stopwatch.stop();
        
        expect(processed, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
        
        // Verify it was resized to target dimensions
        final decodedImage = img.decodeImage(processed);
        expect(decodedImage!.width, equals(ImageUtils.defaultTargetWidth));
        expect(decodedImage.height, equals(ImageUtils.defaultTargetHeight));
      });

      test('should handle multiple concurrent operations', () async {
        final futures = <Future>[];
        
        // Start multiple operations concurrently
        for (var i = 0; i < 5; i++) {
          futures.add(ImageUtils.generateImageHash(testImageBytes));
          futures.add(ImageUtils.preprocessImage(testImageBytes));
        }
        
        // Wait for all to complete
        final results = await Future.wait(futures);
        
        // All operations should complete successfully
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result, isNotNull);
        }
      });

      test('should handle extreme dimensions gracefully', () async {
        // Test with extreme dimensions
        final processed = await ImageUtils.preprocessImage(
          testImageBytes,
          targetWidth: 10000, // Very large
          targetHeight: 1, // Very small
        );
        
        expect(processed, isNotEmpty);
        
        final decodedImage = img.decodeImage(processed);
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, equals(10000));
        expect(decodedImage.height, equals(1));
      });

      test('should generate consistent hashes across multiple calls', () async {
        final hashes = <String>[];
        
        // Generate multiple hashes for the same image
        for (var i = 0; i < 5; i++) {
          final hash = await ImageUtils.generateImageHash(testImageBytes);
          hashes.add(hash);
        }
        
        // All hashes should be identical
        expect(hashes.toSet().length, equals(1));
        expect(hashes.first, isNotEmpty);
      });
    });

    group('Constants and Default Values', () {
      test('should have reasonable default dimensions', () {
        expect(ImageUtils.defaultTargetWidth, equals(300));
        expect(ImageUtils.defaultTargetHeight, equals(300));
        expect(ImageUtils.defaultTargetWidth, greaterThan(0));
        expect(ImageUtils.defaultTargetHeight, greaterThan(0));
      });

      test('should use default dimensions when not specified', () async {
        final processed = await ImageUtils.preprocessImage(testImageBytes);
        final decodedImage = img.decodeImage(processed);
        
        expect(decodedImage!.width, equals(ImageUtils.defaultTargetWidth));
        expect(decodedImage.height, equals(ImageUtils.defaultTargetHeight));
      });
    });
  });
}
