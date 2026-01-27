import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/model_download_service.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';

void main() {
  group('ModelDownloadService', () {
    late ModelDownloadService service;

    setUp(() {
      service = ModelDownloadService(
        baseUrl: 'https://test.example.com/models',
        requireWifi: false,
      );
    });

    test('has correct model metadata', () {
      final metadata = ModelDownloadService.modelMetadata;

      expect(metadata.length, 5);
      expect(metadata.containsKey(VisionModelType.smolVLM), true);
      expect(metadata.containsKey(VisionModelType.yoloV8), true);
    });

    test('model metadata has correct properties', () {
      final smolVLMMetadata =
          ModelDownloadService.modelMetadata[VisionModelType.smolVLM];

      expect(smolVLMMetadata?.fileName, 'smolvlm_waste_classifier.tflite');
      expect(smolVLMMetadata?.version, '1.0.0');
      expect(smolVLMMetadata?.sizeBytes, 200 * 1024 * 1024);
      expect(smolVLMMetadata?.description, isNotEmpty);
    });

    test('formats size string correctly', () {
      final metadata =
          ModelDownloadService.modelMetadata[VisionModelType.mobileNetV3];

      expect(metadata?.sizeString, '20.0 MB');
    });

    test('yoloV8 metadata is correct', () {
      final metadata =
          ModelDownloadService.modelMetadata[VisionModelType.yoloV8];

      expect(metadata?.fileName, 'yolov8_waste_detector.tflite');
      expect(metadata?.sizeBytes, 50 * 1024 * 1024);
    });

    test('efficientNet metadata is correct', () {
      final metadata =
          ModelDownloadService.modelMetadata[VisionModelType.efficientNet];

      expect(metadata?.fileName, 'efficientnet_waste_classifier.tflite');
      expect(metadata?.sizeString, '50.0 MB');
    });

    test('returns null for unsupported model types', () async {
      final isDownloaded =
          await service.isModelDownloaded(VisionModelType.openAI);
      expect(isDownloaded, false);
    });

    test('model status includes metadata', () async {
      final allStatus = await service.getAllModelStatus();

      expect(allStatus.length, 5);

      for (final status in allStatus.values) {
        expect(status.modelType, isNotNull);
        expect(status.metadata, isNotNull);
        expect(status.metadata.fileName, isNotEmpty);
      }
    });
  });

  group('ModelMetadata', () {
    test('creates instance correctly', () {
      const metadata = ModelMetadata(
        fileName: 'test.tflite',
        version: '1.0.0',
        sizeBytes: 1024 * 1024,
        description: 'Test model',
      );

      expect(metadata.fileName, 'test.tflite');
      expect(metadata.version, '1.0.0');
      expect(metadata.sizeBytes, 1024 * 1024);
      expect(metadata.sizeString, '1.0 MB');
    });

    test('formats large sizes correctly', () {
      const metadata = ModelMetadata(
        fileName: 'large.tflite',
        version: '1.0.0',
        sizeBytes: 250 * 1024 * 1024,
        description: 'Large model',
      );

      expect(metadata.sizeString, '250.0 MB');
    });

    test('formats small sizes correctly', () {
      const metadata = ModelMetadata(
        fileName: 'small.tflite',
        version: '1.0.0',
        sizeBytes: 15 * 1024 * 1024,
        description: 'Small model',
      );

      expect(metadata.sizeString, '15.0 MB');
    });
  });

  group('ModelStatus', () {
    test('creates status correctly', () {
      const metadata = ModelMetadata(
        fileName: 'test.tflite',
        version: '1.0.0',
        sizeBytes: 1024 * 1024,
        description: 'Test',
      );

      const status = ModelStatus(
        modelType: VisionModelType.yoloV8,
        metadata: metadata,
        isDownloaded: true,
      );

      expect(status.modelType, VisionModelType.yoloV8);
      expect(status.isDownloaded, true);
      expect(status.metadata.fileName, 'test.tflite');
    });
  });
}
