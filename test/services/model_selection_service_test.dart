import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/batching_service.dart';
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
  });
}
