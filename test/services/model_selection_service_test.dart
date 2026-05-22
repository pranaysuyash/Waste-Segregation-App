import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/batching_service.dart';
import 'package:waste_segregation_app/services/on_device_vision_service.dart';
import 'package:waste_segregation_app/services/model_selection_service.dart';

import '../mocks/mock_services.dart';

class _ThrowingBatchingService extends BatchingService {
  _ThrowingBatchingService();

  @override
  Future<WasteClassification> queueAnalysis({
    required File imageFile,
    String? region,
    String? instructionsLang,
  }) {
    throw StateError('BatchingService should not be called from sync path');
  }
}

class _StubOnDeviceVisionService extends OnDeviceVisionService {
  _StubOnDeviceVisionService(this.result, {this.throwOnAnalyze = false});

  final WasteClassification result;
  final bool throwOnAnalyze;

  @override
  Future<void> initialize() async {}

  @override
  Future<WasteClassification> analyzeImage(
    File imageFile, {
    String? region,
    String? classificationId,
  }) async {
    if (throwOnAnalyze) {
      throw StateError('Simulated local inference failure');
    }
    return result;
  }

  @override
  Future<WasteClassification> analyzeWebImage(
    Uint8List imageBytes, {
    String? region,
    String? classificationId,
  }) async {
    if (throwOnAnalyze) {
      throw StateError('Simulated local inference failure');
    }
    return result;
  }
}

WasteClassification _classification({
  double confidence = 0.95,
  String? analysisSource,
  String? analysisFallbackReason,
}) {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Dry Waste',
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Recycle'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['test'],
    alternatives: [
      AlternativeClassification(
        category: 'Wet Waste',
        confidence: 0.1,
        reason: 'fallback',
      ),
    ],
    confidence: confidence,
    analysisSource: analysisSource,
    analysisFallbackReason: analysisFallbackReason,
  );
}

void main() {
  group('ModelSelectionService batch strategy', () {
    test('batchMode does not route sync analyzeImage into BatchingService',
        () async {
      final aiService = MockAiService();
      final service = ModelSelectionService(
        aiService: aiService,
        batchingService: _ThrowingBatchingService(),
        strategy: ModelSelectionStrategy.batchMode,
      );

      final file = File(
        '${Directory.systemTemp.path}/model_selection_service_batch_test.jpg',
      )..writeAsBytesSync(<int>[0, 1, 2, 3, 4], flush: true);

      try {
        final result = await service.analyzeImage(file);
        expect(result.itemName, isNotEmpty);
      } finally {
        if (file.existsSync()) {
          file.deleteSync();
        }
        service.dispose();
      }
    });

    test('marks local results as experimental', () async {
      final aiService = MockAiService();
      final localService = _StubOnDeviceVisionService(
        _classification(),
      );
      final service = ModelSelectionService(
        aiService: aiService,
        onDeviceService: localService,
        strategy: ModelSelectionStrategy.hybrid,
      );

      final file = File(
        '${Directory.systemTemp.path}/model_selection_service_local_test.jpg',
      )..writeAsBytesSync(<int>[0, 1, 2, 3, 4], flush: true);

      try {
        final result = await service.analyzeImage(file);
        expect(
          result.analysisSource,
          WasteClassification.analysisSourceLocalExperimental,
        );
      } finally {
        if (file.existsSync()) {
          file.deleteSync();
        }
        service.dispose();
      }
    });

    test('marks cloud fallback after local failure', () async {
      final aiService = MockAiService();
      final localService = _StubOnDeviceVisionService(
        _classification(confidence: 0.2),
      );
      final service = ModelSelectionService(
        aiService: aiService,
        onDeviceService: localService,
        strategy: ModelSelectionStrategy.hybrid,
      );

      final file = File(
        '${Directory.systemTemp.path}/model_selection_service_local_fallback_test.jpg',
      )..writeAsBytesSync(<int>[4, 3, 2, 1, 0], flush: true);

      try {
        final result = await service.analyzeImage(file);
        expect(
          result.analysisSource,
          WasteClassification.analysisSourceLocalFailedFallbackCloud,
        );
        expect(result.analysisFallbackReason, contains('low_confidence'));
      } finally {
        if (file.existsSync()) {
          file.deleteSync();
        }
        service.dispose();
      }
    });
  });
}
