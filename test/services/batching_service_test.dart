import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'package:waste_segregation_app/services/batching_service.dart';

Uint8List _imageBytes([int seed = 1]) => Uint8List.fromList([seed, seed + 1, seed + 2]);

void main() {
  group('BatchingService', () {
    late BatchingService service;

    setUp(() {
      service = BatchingService(
        config: VisionModelConfig(
          modelType: VisionModelType.openAI,
          analysisMode: AnalysisMode.batch,
          batchSize: 2,
          batchTimeoutSeconds: 60,
          preferOnDevice: false,
        ),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('queues requests, exposes status, and flushes a placeholder result', () async {
      final future = service.queueAnalysisBytes(
        imageBytes: _imageBytes(),
        imagePath: 'queued.jpg',
        region: 'IN',
      );

      final statusBeforeFlush = service.getBatchStatus();
      expect(statusBeforeFlush['pending_requests'], 1);
      expect(statusBeforeFlush['batch_size'], 2);
      expect(statusBeforeFlush['is_processing'], isFalse);

      await service.flush();

      final result = await future;
      expect(result.itemName, 'Batch Analysis Pending');
      expect(result.category, 'Batch Mode');
      expect(result.modelSource, 'batch-api-placeholder');
      expect(result.processingTimeMs, 500);

      final statusAfterFlush = service.getBatchStatus();
      expect(statusAfterFlush['pending_requests'], 0);
      expect(statusAfterFlush['is_processing'], isFalse);
    });

    test('cancelAll completes pending requests with a cancellation error', () async {
      final future = service.queueAnalysisBytes(
        imageBytes: _imageBytes(10),
        imagePath: 'cancelled.jpg',
      );

      expect(service.getBatchStatus()['pending_requests'], 1);

      service.cancelAll();

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Request cancelled'),
          ),
        ),
      );

      expect(service.getBatchStatus()['pending_requests'], 0);
      expect(service.getBatchStatus()['timer_active'], isFalse);
    });
  });
}
