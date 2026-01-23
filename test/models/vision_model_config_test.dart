import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';

void main() {
  group('VisionModelConfig', () {
    test('creates default on-device config', () {
      final config = VisionModelConfig.onDevice();
      
      expect(config.modelType, VisionModelType.yoloV8);
      expect(config.analysisMode, AnalysisMode.onDevice);
      expect(config.confidenceThreshold, 0.6);
      expect(config.enableObjectDetection, true);
      expect(config.preferOnDevice, true);
    });

    test('creates hybrid config', () {
      final config = VisionModelConfig.hybrid();
      
      expect(config.modelType, VisionModelType.yoloV8);
      expect(config.analysisMode, AnalysisMode.hybrid);
      expect(config.confidenceThreshold, 0.7);
      expect(config.enableObjectDetection, true);
      expect(config.preferOnDevice, true);
    });

    test('creates batch cloud config', () {
      final config = VisionModelConfig.batchCloud();
      
      expect(config.modelType, VisionModelType.openAI);
      expect(config.analysisMode, AnalysisMode.batch);
      expect(config.batchSize, 10);
      expect(config.batchTimeoutSeconds, 60);
      expect(config.preferOnDevice, false);
    });

    test('copyWith creates modified config', () {
      final config = VisionModelConfig.onDevice();
      final modified = config.copyWith(
        confidenceThreshold: 0.8,
        enableSegmentation: true,
      );
      
      expect(modified.confidenceThreshold, 0.8);
      expect(modified.enableSegmentation, true);
      expect(modified.modelType, config.modelType); // Unchanged
      expect(modified.analysisMode, config.analysisMode); // Unchanged
    });

    test('supports all model types', () {
      expect(VisionModelType.values.length, 9);
      expect(VisionModelType.values.contains(VisionModelType.smolVLM), true);
      expect(VisionModelType.values.contains(VisionModelType.yoloV8), true);
      expect(VisionModelType.values.contains(VisionModelType.openAI), true);
    });

    test('supports all analysis modes', () {
      expect(AnalysisMode.values.length, 4);
      expect(AnalysisMode.values.contains(AnalysisMode.instant), true);
      expect(AnalysisMode.values.contains(AnalysisMode.batch), true);
      expect(AnalysisMode.values.contains(AnalysisMode.onDevice), true);
      expect(AnalysisMode.values.contains(AnalysisMode.hybrid), true);
    });
  });

  group('ModelPerformanceMetrics', () {
    test('creates metrics instance', () {
      final metrics = ModelPerformanceMetrics(
        modelType: VisionModelType.yoloV8,
        totalInferences: 100,
        averageLatencyMs: 120.5,
        averageConfidence: 0.85,
        successRate: 0.95,
        totalCost: 0.0,
        lastUpdated: DateTime.now(),
      );
      
      expect(metrics.modelType, VisionModelType.yoloV8);
      expect(metrics.totalInferences, 100);
      expect(metrics.averageLatencyMs, 120.5);
      expect(metrics.averageConfidence, 0.85);
      expect(metrics.successRate, 0.95);
      expect(metrics.totalCost, 0.0);
    });
  });
}
