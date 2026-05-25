import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import '../models/vision_model_config.dart';
import '../services/storage_service.dart';
import '../utils/waste_app_logger.dart';
import 'package:uuid/uuid.dart';
import 'firestore_schema_registry.dart';

/// Represents a queued image analysis request
class BatchAnalysisRequest {
  BatchAnalysisRequest({
    required this.id,
    required this.imageBytes,
    required this.imagePath,
    required this.completer,
    this.userId,
    this.region,
    this.instructionsLang,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final Uint8List imageBytes;
  final String imagePath;
  final Completer<WasteClassification> completer;
  final String? userId;
  final String? region;
  final String? instructionsLang;
  final DateTime timestamp;
}

/// Service for batching multiple image analyses via Firebase Batch API
///
/// Benefits:
/// - 50% cost reduction via OpenAI batch API
/// - Reduced rate limit impact
/// - Better resource utilization
///
/// Trade-offs:
/// - Slight delay (results delivered asynchronously, minutes to hours)
/// - Requires Firebase Auth and Storage
///
/// Use cases:
/// - Bulk image uploads
/// - Background processing
/// - Non-urgent classifications
/// - Cost-sensitive operations
class BatchingService {
  BatchingService({
    VisionModelConfig? config,
    CloudStorageService? cloudStorageService,
    StorageService? storageService,
  })  : _config = config ?? VisionModelConfig.batchCloud(),
        _pendingRequests = <BatchAnalysisRequest>[],
        _processingTimer = null,
        _cloudStorageService = cloudStorageService,
        _storageService = storageService ?? StorageService();

  final VisionModelConfig _config;
  final List<BatchAnalysisRequest> _pendingRequests;
  Timer? _processingTimer;
  bool _isProcessing = false;
  final CloudStorageService? _cloudStorageService;
  final StorageService _storageService;
  final Map<String, StreamSubscription<DocumentSnapshot>> _jobSubscriptions = {};

  /// Queue an image for batch analysis
  ///
  /// Returns a Future that completes when the analysis is done.
  /// The analysis will be performed when either:
  /// 1. Batch size is reached (default: 5)
  /// 2. Timeout is reached (default: 30 seconds)
  Future<WasteClassification> queueAnalysis({
    required File imageFile,
    String? userId,
    String? region,
    String? instructionsLang,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      return queueAnalysisBytes(
        imageBytes: imageBytes,
        imagePath: imageFile.path,
        userId: userId,
        region: region,
        instructionsLang: instructionsLang,
      );
    } catch (e, s) {
      WasteAppLogger.severe('Failed to queue analysis from file',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Queue image bytes for batch analysis
  Future<WasteClassification> queueAnalysisBytes({
    required Uint8List imageBytes,
    required String imagePath,
    String? userId,
    String? region,
    String? instructionsLang,
  }) async {
    final effectiveUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    final request = BatchAnalysisRequest(
      id: const Uuid().v4(),
      imageBytes: imageBytes,
      imagePath: imagePath,
      completer: Completer<WasteClassification>(),
      userId: effectiveUserId,
      region: region,
      instructionsLang: instructionsLang,
    );

    _pendingRequests.add(request);

    WasteAppLogger.info('Queued analysis request ${request.id}. '
        'Pending: ${_pendingRequests.length}/${_config.batchSize}');

    _startProcessingTimer();

    if (_pendingRequests.length >= _config.batchSize) {
      WasteAppLogger.info('Batch size reached, processing immediately');
      await _processBatch();
    }

    return request.completer.future;
  }

  void _startProcessingTimer() {
    if (_processingTimer != null && _processingTimer!.isActive) {
      return;
    }

    final timeout = Duration(seconds: _config.batchTimeoutSeconds);
    _processingTimer = Timer(timeout, () {
      WasteAppLogger.info(
          'Batch timeout reached, processing pending requests');
      _processBatch();
    });
  }

  Future<void> _processBatch() async {
    if (_isProcessing || _pendingRequests.isEmpty) {
      return;
    }

    _isProcessing = true;
    _processingTimer?.cancel();
    _processingTimer = null;

    final batchToProcess = List<BatchAnalysisRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    WasteAppLogger.info(
        'Processing batch of ${batchToProcess.length} requests via Firebase batch API');

    try {
      await _processBatchViaFirebase(batchToProcess);
    } catch (e, s) {
      WasteAppLogger.severe('Batch processing failed', error: e, stackTrace: s);
      _completeAllWithError(batchToProcess, e, s);
    } finally {
      _isProcessing = false;

      if (_pendingRequests.isNotEmpty) {
        _startProcessingTimer();
      }
    }
  }

  /// Processes a batch of requests via Firebase Batch API.
  ///
  /// For each request:
  /// 1. Writes image bytes to a temp file
  /// 2. Uploads to Firebase Storage
  /// 3. Calls createBatchAiJob Firebase callable
  /// 4. Subscribes to the ai_jobs Firestore document for completion
  Future<void> _processBatchViaFirebase(
      List<BatchAnalysisRequest> batch) async {
    final cloudStorage = _cloudStorageService ??
        CloudStorageService(_storageService);

    for (final request in batch) {
      if (request.userId == null || request.userId!.isEmpty) {
        WasteAppLogger.warning(
            'Skipping batch request ${request.id}: no userId');
        if (!request.completer.isCompleted) {
          request.completer.completeError(
            Exception('User authentication required for batch analysis'),
          );
        }
        continue;
      }

      try {
        final jobId = await _submitBatchJob(
          request: request,
          cloudStorage: cloudStorage,
        );

        _listenForJobResult(request, jobId);
      } catch (e, s) {
        WasteAppLogger.severe(
            'Failed to submit batch job for ${request.id}',
            error: e, stackTrace: s);
        if (!request.completer.isCompleted) {
          request.completer.completeError(e, s);
        }
      }
    }
  }

  /// Submits a single image as a batch job via Firebase
  Future<String> _submitBatchJob({
    required BatchAnalysisRequest request,
    required CloudStorageService cloudStorage,
  }) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${request.id}.jpg');
    await tempFile.writeAsBytes(request.imageBytes);

    try {
      final imagePath = await cloudStorage.uploadImageForBatchProcessing(
        tempFile,
        request.userId!,
      );

      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('createBatchAiJob');
      final response = await callable.call(<String, dynamic>{
        'imageUrl': imagePath,
      });

      final payload = Map<String, dynamic>.from(response.data as Map);
      final success = payload['success'] == true;
      final jobId = (payload['jobId'] as String?)?.trim() ?? '';

      if (!success || jobId.isEmpty) {
        throw Exception(payload['error'] ?? 'Failed to create batch job');
      }

      WasteAppLogger.info('Batch job submitted', context: {
        'jobId': jobId,
        'requestId': request.id,
      });

      return jobId;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Listens on Firestore ai_jobs/{jobId} for the analysis result
  void _listenForJobResult(
      BatchAnalysisRequest request, String jobId) {
    final subscription = FirebaseFirestore.instance
        .collection(FirestoreCollections.aiJobs)
        .doc(jobId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final status = (data['status'] as String?) ?? '';

      if (status == 'completed') {
        _subscriptionCleanup(jobId);

        if (request.completer.isCompleted) return;

        final resultData = data['result'] as Map<String, dynamic>?;
        if (resultData != null) {
          try {
            final result = WasteClassification.fromJson(resultData);
            request.completer.complete(result);
            WasteAppLogger.info('Batch job completed', context: {
              'jobId': jobId,
              'requestId': request.id,
            });
          } catch (e) {
            WasteAppLogger.severe('Failed to parse batch result', error: e);
            request.completer.completeError(e);
          }
        } else {
          request.completer.completeError(
            Exception('Batch job completed but no result data found'),
          );
        }
      } else if (status == 'failed') {
        _subscriptionCleanup(jobId);

        if (!request.completer.isCompleted) {
          final errorMessage =
              data['errorMessage'] as String? ?? 'Batch job failed';
          request.completer.completeError(Exception(errorMessage));
        }
      } else if (status == 'cancelled') {
        _subscriptionCleanup(jobId);

        if (!request.completer.isCompleted) {
          request.completer.completeError(Exception('Batch job was cancelled'));
        }
      }
    }, onError: (error) {
      _subscriptionCleanup(jobId);
      if (!request.completer.isCompleted) {
        request.completer.completeError(error);
      }
    });

    _jobSubscriptions[jobId] = subscription;
  }



  void _subscriptionCleanup(String jobId) {
    final sub = _jobSubscriptions.remove(jobId);
    sub?.cancel();
  }

  void _completeAllWithError(
      List<BatchAnalysisRequest> requests, Object error, StackTrace stack) {
    for (final request in requests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(error, stack);
      }
    }
  }

  Map<String, dynamic> getBatchStatus() {
    return {
      'pending_requests': _pendingRequests.length,
      'batch_size': _config.batchSize,
      'batch_timeout_seconds': _config.batchTimeoutSeconds,
      'is_processing': _isProcessing,
      'timer_active': _processingTimer?.isActive ?? false,
      'active_job_listeners': _jobSubscriptions.length,
    };
  }

  Future<void> flush() async {
    WasteAppLogger.info('Flushing batch service');
    await _processBatch();
  }

  void cancelAll() {
    WasteAppLogger.info('Cancelling all pending requests');

    _processingTimer?.cancel();
    _processingTimer = null;

    for (final sub in _jobSubscriptions.values) {
      sub.cancel();
    }
    _jobSubscriptions.clear();

    for (final request in _pendingRequests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          Exception('Request cancelled'),
        );
      }
    }

    _pendingRequests.clear();
  }

  void dispose() {
    cancelAll();
    WasteAppLogger.info('Batching service disposed');
  }
}
