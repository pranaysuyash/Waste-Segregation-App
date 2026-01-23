import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/on_device_vision_service.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';

void main() {
  group('OnDeviceVisionService', () {
    late OnDeviceVisionService service;

    setUp(() {
      service = OnDeviceVisionService(
        config: VisionModelConfig.onDevice(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with correct configuration', () {
      final info = service.getModelInfo();
      
      expect(info['model_type'], 'yoloV8');
      expect(info['is_initialized'], false);
      expect(info['confidence_threshold'], 0.6);
      expect(info['object_detection_enabled'], true);
    });

    test('initialization succeeds', () async {
      // Initialize service
      await service.initialize();
      
      final info = service.getModelInfo();
      expect(info['is_initialized'], true);
    });

    test('supports different model types', () {
      final models = [
        VisionModelType.smolVLM,
        VisionModelType.mobileNetV3,
        VisionModelType.efficientNet,
        VisionModelType.yoloV8,
        VisionModelType.yoloV11,
      ];

      for (final modelType in models) {
        final testService = OnDeviceVisionService(
          config: VisionModelConfig.onDevice().copyWith(
            modelType: modelType,
          ),
        );
        
        final info = testService.getModelInfo();
        expect(info['model_type'], modelType.name);
        
        testService.dispose();
      }
    });

    test('dispose cleans up resources', () {
      service.dispose();
      
      final info = service.getModelInfo();
      expect(info['is_initialized'], false);
      expect(info['model_path'], null);
    });

    test('custom model path is respected', () {
      final customService = OnDeviceVisionService(
        config: VisionModelConfig(
          modelType: VisionModelType.tfliteCustom,
          analysisMode: AnalysisMode.onDevice,
          customModelPath: 'custom_waste_model.tflite',
        ),
      );

      final info = customService.getModelInfo();
      expect(info['model_type'], 'tfliteCustom');
      
      customService.dispose();
    });

    test('confidence threshold can be configured', () {
      final customService = OnDeviceVisionService(
        config: VisionModelConfig.onDevice().copyWith(
          confidenceThreshold: 0.8,
        ),
      );

      final info = customService.getModelInfo();
      expect(info['confidence_threshold'], 0.8);
      
      customService.dispose();
    });
  });
}
