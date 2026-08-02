import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'package:waste_segregation_app/services/batching_service.dart';

Uint8List _imageBytes([int seed = 1]) =>
    Uint8List.fromList([seed, seed + 1, seed + 2]);

Map<String, dynamic> _completedResultJson() => <String, dynamic>{
      'itemName': 'PET Bottle',
      'category': 'Dry Waste',
      'explanation': 'Plastic bottle detected',
      'disposalInstructions': <String, dynamic>{
        'primaryMethod': 'Recycle',
        'steps': <String>['Rinse', 'Flatten', 'Place in dry waste bin'],
        'hasUrgentTimeframe': false,
      },
      'region': 'IN',
      'visualFeatures': <String>['plastic', 'bottle'],
      'alternatives': <Map<String, dynamic>>[
        <String, dynamic>{
          'category': 'Reject Waste',
          'confidence': 0.1,
          'reason': 'if heavily contaminated',
        }
      ],
      'modelSource': 'openai-gpt-4.1-nano',
      'processingTimeMs': 220,
      'confidence': 0.92,
    };

void main() {
  group('BatchingService', () {
    late Map<String, StreamController<Map<String, dynamic>?>> jobStreams;
    late List<String> uploadedImagePaths;
    late List<String> callableInputs;

    late BatchingService service;

    setUp(() {
      jobStreams = <String, StreamController<Map<String, dynamic>?>>{};
      uploadedImagePaths = <String>[];
      callableInputs = <String>[];

      service = BatchingService(
        config: VisionModelConfig(
          modelType: VisionModelType.openAI,
          analysisMode: AnalysisMode.batch,
          batchSize: 2,
          batchTimeoutSeconds: 60,
          preferOnDevice: false,
        ),
        imageUploadOverride: (request, _) async {
          final path = 'gs://bucket/batch_images/${request.userId}/${request.id}.jpg';
          uploadedImagePaths.add(path);
          return path;
        },
        callableOverride: (imagePath) async {
          callableInputs.add(imagePath);
          return <String, dynamic>{
            'success': true,
            'jobId': 'job_123',
            'status': 'queued',
            'tokensCharged': 1,
            'walletBalance': 49,
            'ledgerId': 'ledger_123',
          };
        },
        jobUpdatesOverride: (jobId) {
          // ignore: close_sinks
          final controller = StreamController<Map<String, dynamic>?>.broadcast();
          jobStreams[jobId] = controller;
          return controller.stream;
        },
      );
    });

    tearDown(() async {
      service.dispose();
      for (final controller in jobStreams.values) {
        await controller.close();
      }
    });

    test('submits real batch callable path and completes from ai_jobs result',
        () async {
      final future = service.queueAnalysisBytes(
        imageBytes: _imageBytes(),
        imagePath: 'queued.jpg',
        userId: 'user_1',
        region: 'IN',
      );

      await service.flush();
      expect(uploadedImagePaths, hasLength(1));
      expect(callableInputs, hasLength(1));
      expect(callableInputs.first, contains('/user_1/'));

      final controller = jobStreams['job_123'];
      expect(controller, isNotNull);
      controller!.add(<String, dynamic>{
        'status': 'completed',
        'result': _completedResultJson(),
      });

      final result = await future;
      expect(result.itemName, 'PET Bottle');
      expect(result.category, 'Dry Waste');
      expect(result.modelSource, 'openai-gpt-4.1-nano');
      expect(result.processingTimeMs, 220);

      final statusAfterFlush = service.getBatchStatus();
      expect(statusAfterFlush['pending_requests'], 0);
      expect(statusAfterFlush['is_processing'], isFalse);
    });

    test('surfaces callable auth and App Check contract errors', () async {
      service.dispose();
      service = BatchingService(
        config: VisionModelConfig.batchCloud(),
        imageUploadOverride: (request, _) async =>
            'gs://bucket/batch_images/${request.userId}/${request.id}.jpg',
        callableOverride: (_) async {
          throw Exception(
            'createBatchAiJob failed (failed-precondition): App Check token required for createBatchAiJob.',
          );
        },
        jobUpdatesOverride: (_) =>
            const Stream<Map<String, dynamic>?>.empty(),
      );

      final future = service.queueAnalysisBytes(
        imageBytes: _imageBytes(10),
        imagePath: 'guardrail.jpg',
        userId: 'user_1',
      );
      await service.flush();

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('failed-precondition'), contains('App Check')),
          ),
        ),
      );
    });

    test('cancelAll completes pending requests with a cancellation error',
        () async {
      final future = service.queueAnalysisBytes(
        imageBytes: _imageBytes(10),
        imagePath: 'cancelled.jpg',
        userId: 'user_1',
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
