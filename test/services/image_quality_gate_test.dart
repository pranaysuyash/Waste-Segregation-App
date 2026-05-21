import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/services/image_quality_gate.dart';

Uint8List _jpgFromImage(img.Image image) => Uint8List.fromList(img.encodeJpg(image));

img.Image _checkerboard({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final on = ((x ~/ 8) + (y ~/ 8)) % 2 == 0;
      image.setPixelRgb(x, y, on ? 240 : 20, on ? 240 : 20, on ? 240 : 20);
    }
  }
  return image;
}

void main() {
  late int oldMinDimension;
  late double oldMinVariance;
  late int oldMinBrightness;
  late int oldMaxBrightness;

  setUp(() {
    oldMinDimension = ImageQualityGate.minDimension;
    oldMinVariance = ImageQualityGate.minVariance;
    oldMinBrightness = ImageQualityGate.minBrightness;
    oldMaxBrightness = ImageQualityGate.maxBrightness;
  });

  tearDown(() {
    ImageQualityGate.minDimension = oldMinDimension;
    ImageQualityGate.minVariance = oldMinVariance;
    ImageQualityGate.minBrightness = oldMinBrightness;
    ImageQualityGate.maxBrightness = oldMaxBrightness;
  });

  group('ImageQualityGate', () {
    test('returns decodeError for invalid image bytes', () async {
      final result = await ImageQualityGate.check(Uint8List.fromList([1, 2, 3, 4, 5]));

      expect(result.isValid, isFalse);
      expect(result.failureType, QualityFailureType.decodeError);
      expect(result.reason, contains('Invalid image format'));
    });

    test('fails resolution check for small images', () async {
      final bytes = _jpgFromImage(img.Image(width: 120, height: 120));

      final result = await ImageQualityGate.check(bytes);

      expect(result.isValid, isFalse);
      expect(result.failureType, QualityFailureType.resolution);
      expect(result.reason, contains('Image too small'));
    });

    test('passes for acceptable resolution, sharpness, and brightness', () async {
      ImageQualityGate.minVariance = 0.0;
      final bytes = _jpgFromImage(_checkerboard(width: 320, height: 320));

      final result = await ImageQualityGate.check(bytes);

      expect(result.isValid, isTrue, reason: result.reason);
      expect(result.failureType, isNull);
      expect(result.reason, contains('acceptable'));
    });

    test('fails too-dark branch when blur gate is relaxed', () async {
      ImageQualityGate.minVariance = 0.0;
      final dark = img.Image(width: 320, height: 320);
      img.fill(dark, color: img.ColorRgb8(0, 0, 0));

      final result = await ImageQualityGate.check(_jpgFromImage(dark));

      expect(result.isValid, isFalse);
      expect(result.failureType, QualityFailureType.tooDark);
    });

    test('fails overexposed branch when blur gate is relaxed', () async {
      ImageQualityGate.minVariance = 0.0;
      final bright = img.Image(width: 320, height: 320);
      img.fill(bright, color: img.ColorRgb8(255, 255, 255));

      final result = await ImageQualityGate.check(_jpgFromImage(bright));

      expect(result.isValid, isFalse);
      expect(result.failureType, QualityFailureType.overexposed);
    });
  });
}
