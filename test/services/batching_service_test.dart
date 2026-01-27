import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/batching_service.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'dart:typed_data';

void main() {
  group('BatchingService', () {
    late BatchingService service;

    setUp(() {
      service = BatchingService(
        config: VisionModelConfig.batchCloud().copyWith(
          batchSize: 3,
          batchTimeoutSeconds: 2,
        ),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with correct configuration', () {
      final status = service.getBatchStatus();

      expect(status['pending_requests'], 0);
      expect(status['batch_size'], 3);
      expect(status['batch_timeout_seconds'], 2);
      expect(status['is_processing'], false);
    });

    test('queues analysis request', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Queue without waiting for result
      final future = service.queueAnalysisBytes(
        imageBytes: imageBytes,
        imagePath: 'test.jpg',
      );

      // Check that request is queued
      final status = service.getBatchStatus();
      expect(status['pending_requests'], 1);

      // Cancel to avoid hanging test
      service.cancelAll();
    });

    test('processes batch when size is reached', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Queue 3 requests (batch size)
      final futures = <Future>[];
      for (var i = 0; i < 3; i++) {
        futures.add(service.queueAnalysisBytes(
          imageBytes: imageBytes,
          imagePath: 'test$i.jpg',
        ));
      }

      // Wait for processing
      await Future.wait(futures);

      // All requests should be processed
      final status = service.getBatchStatus();
      expect(status['pending_requests'], 0);
    });

    test('flush processes pending requests immediately', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Queue 2 requests (less than batch size)
      final futures = <Future>[];
      for (var i = 0; i < 2; i++) {
        futures.add(service.queueAnalysisBytes(
          imageBytes: imageBytes,
          imagePath: 'test$i.jpg',
        ));
      }

      // Flush immediately
      await service.flush();
      await Future.wait(futures);

      // All requests should be processed
      final status = service.getBatchStatus();
      expect(status['pending_requests'], 0);
    });

    test('cancelAll cancels pending requests', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Queue request
      final future = service.queueAnalysisBytes(
        imageBytes: imageBytes,
        imagePath: 'test.jpg',
      );

      // Cancel all
      service.cancelAll();

      // Request should be cancelled with error
      expect(future, throwsA(isA<Exception>()));

      final status = service.getBatchStatus();
      expect(status['pending_requests'], 0);
    });

    test('supports different batch sizes', () {
      final configs = [
        VisionModelConfig.batchCloud().copyWith(batchSize: 5),
        VisionModelConfig.batchCloud().copyWith(batchSize: 10),
        VisionModelConfig.batchCloud().copyWith(batchSize: 20),
      ];

      for (final config in configs) {
        final testService = BatchingService(config: config);
        final status = testService.getBatchStatus();

        expect(status['batch_size'], config.batchSize);

        testService.dispose();
      }
    });

    test('dispose cancels all pending requests', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Queue request
      final future = service.queueAnalysisBytes(
        imageBytes: imageBytes,
        imagePath: 'test.jpg',
      );

      // Dispose service
      service.dispose();

      // Request should be cancelled
      expect(future, throwsA(isA<Exception>()));
    });
  });
}
