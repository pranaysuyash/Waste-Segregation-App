import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/face_detection_service.dart';

void main() {
  group('FaceDetectionService', () {
    late FaceDetectionService service;

    setUp(() {
      service = FaceDetectionService();
    });

    test('detectFaces returns empty list (Phase 1 stub)', () async {
      final bytes = Uint8List.fromList(List.filled(100, 0));
      final faces = await service.detectFaces(bytes);
      expect(faces, isEmpty);
    });

    test('blurFaces returns original bytes when no faces detected', () async {
      final bytes = Uint8List.fromList(List.filled(100, 0));
      final result = await service.blurFaces(bytes);

      expect(result.processedImageBytes, equals(bytes));
      expect(result.facesDetected, equals(0));
      expect(result.facesBlurred, equals(0));
    });

    test('FaceDetectionResult stores correct data', () {
      final result = FaceDetectionResult(
        processedImageBytes: Uint8List.fromList([1, 2, 3]),
        facesDetected: 2,
        facesBlurred: 2,
      );

      expect(result.facesDetected, equals(2));
      expect(result.facesBlurred, equals(2));
      expect(result.processedImageBytes.length, equals(3));
    });
  });
}
