import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ai_job.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

/// Service for managing AI analysis jobs using OpenAI Batch API
///
/// This service handles:
/// - Creating batch jobs for cost-effective AI analysis (50% discount)
/// - Managing job queue and status tracking
/// - Processing results when jobs complete
/// - Integrating with token economy system
class AiJobService {
  AiJobService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestoreOverride = firestore,
        _storageService = storageService ?? StorageService();

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  final StorageService _storageService;

  static const String _jobsCollection = FirestoreCollections.aiJobs;

  /// Creates a new batch job for AI analysis
  ///
  /// This method:
  /// 1. Uploads image to storage
  /// 2. Calls backend callable for authoritative token debit + OpenAI batch submission
  /// 3. Returns created job id
  Future<String> createBatchJob({
    required String userId,
    required File imageFile,
  }) async {
    try {
      WasteAppLogger.info('Creating batch job for user: $userId', context: {
        'service': 'ai_job_service',
        'method': 'createBatchJob',
        'userId': userId,
      });

      // 1. Upload image to Cloud Storage
      final cloudStorageService = CloudStorageService(_storageService);
      final imagePath = await cloudStorageService.uploadImageForBatchProcessing(
        imageFile,
        userId,
      );

      // 2. Delegate authoritative token debit + OpenAI batch submission +
      //    ai_jobs document creation to backend callable.
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

      WasteAppLogger.info('Batch job created successfully', context: {
        'service': 'ai_job_service',
        'jobId': jobId,
        'openAIBatchId': payload['openAIBatchId'],
        'tokensCharged': payload['tokensCharged'],
      });

      return jobId;
    } on FirebaseFunctionsException catch (e) {
      WasteAppLogger.severe('Backend callable failed to create batch job',
          error: e,
          context: {
            'service': 'ai_job_service',
            'userId': userId,
            'code': e.code,
            'message': e.message,
          });
      rethrow;
    } catch (e) {
      WasteAppLogger.severe('Failed to create batch job', error: e, context: {
        'service': 'ai_job_service',
        'userId': userId,
      });
      rethrow;
    }
  }


  /// Updates job status from OpenAI batch status
  Future<void> updateJobStatus({
    required String jobId,
    required AiJobStatus status,
    String? error,
    WasteClassification? result,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (error != null) {
        updates['error'] = error;
      }

      if (result != null) {
        updates['result'] = result.toJson();
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_jobsCollection).doc(jobId).update(updates);

      WasteAppLogger.info('Updated job status', context: {
        'service': 'ai_job_service',
        'jobId': jobId,
        'status': status.name,
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to update job status', error: e, context: {
        'service': 'ai_job_service',
        'jobId': jobId,
      });
      rethrow;
    }
  }

  /// Gets user's job history
  Stream<List<AiJob>> getUserJobs(String userId) {
    return _firestore
        .collection(_jobsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AiJob.fromJson(doc.data())).toList());
  }

  /// Get queue statistics
  Future<QueueStats> getQueueStats() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_jobsCollection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      if (snapshot.docs.isEmpty) {
        return QueueStats(
          totalJobs: 0,
          queuedJobs: 0,
          processingJobs: 0,
          completedToday: 0,
          failedToday: 0,
          averageWaitTime: Duration.zero,
          lastUpdated: DateTime.now(),
          averageProcessingTime: const Duration(seconds: 30),
          estimatedWaitTime: Duration.zero,
          successRate: 1.0,
          failureRate: 0.0,
          pendingJobs: 0,
        );
      }

      final jobs = snapshot.docs.map((doc) => doc.data()).toList();
      final totalJobs = jobs.length;
      final queuedStatuses = {AiJobStatus.queued.name, AiJobStatus.queued.toString()};
      final processingStatuses = {AiJobStatus.processing.name, AiJobStatus.processing.toString()};
      final completedStatuses = {AiJobStatus.completed.name, AiJobStatus.completed.toString()};
      final failedStatuses = {AiJobStatus.failed.name, AiJobStatus.failed.toString()};

      final queuedJobs =
          jobs.where((job) => queuedStatuses.contains(job['status'])).length;
      final processingJobs = jobs
          .where((job) => processingStatuses.contains(job['status']))
          .length;
      final completedJobs = jobs
          .where((job) => completedStatuses.contains(job['status']))
          .length;
      final failedJobs =
          jobs.where((job) => failedStatuses.contains(job['status'])).length;

      // Calculate average processing time from completed jobs
      final completedJobsWithTimes = jobs
          .where((job) =>
              completedStatuses.contains(job['status']) &&
              job['completedAt'] != null &&
              job['createdAt'] != null)
          .toList();

      var averageProcessingTime = const Duration(seconds: 30); // Default
      if (completedJobsWithTimes.isNotEmpty) {
        final totalProcessingTime =
            completedJobsWithTimes.fold<int>(0, (sum, job) {
          final createdAt = (job['createdAt'] as Timestamp).toDate();
          final completedAt = (job['completedAt'] as Timestamp).toDate();
          return sum + completedAt.difference(createdAt).inMilliseconds;
        });
        averageProcessingTime = Duration(
            milliseconds: totalProcessingTime ~/ completedJobsWithTimes.length);
      }

      // Calculate success and failure rates
      final totalProcessedJobs = completedJobs + failedJobs;
      final successRate =
          totalProcessedJobs > 0 ? completedJobs / totalProcessedJobs : 1.0;
      final failureRate =
          totalProcessedJobs > 0 ? failedJobs / totalProcessedJobs : 0.0;

      // Estimate wait time based on queue length and processing time
      final estimatedWaitTime = Duration(
        milliseconds: queuedJobs * averageProcessingTime.inMilliseconds,
      );

      // Calculate average wait time from recently completed jobs
      var averageWaitTime = Duration.zero;
      if (completedJobsWithTimes.isNotEmpty) {
        final totalWaitTime = completedJobsWithTimes.fold<int>(0, (sum, job) {
          final createdAt = (job['createdAt'] as Timestamp).toDate();
          final completedAt = (job['completedAt'] as Timestamp).toDate();
          return sum + completedAt.difference(createdAt).inMilliseconds;
        });
        averageWaitTime = Duration(
            milliseconds: totalWaitTime ~/ completedJobsWithTimes.length);
      }

      return QueueStats(
        totalJobs: totalJobs,
        queuedJobs: queuedJobs,
        processingJobs: processingJobs,
        completedToday: completedJobs,
        failedToday: failedJobs,
        averageWaitTime: averageWaitTime,
        lastUpdated: DateTime.now(),
        averageProcessingTime: averageProcessingTime,
        estimatedWaitTime: estimatedWaitTime,
        successRate: successRate,
        failureRate: failureRate,
        pendingJobs: queuedJobs, // Same as queuedJobs
      );
    } catch (e) {
      WasteAppLogger.severe('Failed to get queue stats', error: e, context: {
        'service': 'ai_job_service',
        'method': 'getQueueStats',
      });

      // Return empty stats on error
      return QueueStats.empty();
    }
  }

  /// Gets system health metrics
  Future<QueueHealth> getQueueHealth() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_jobsCollection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      final jobs = snapshot.docs.map((doc) => doc.data()).toList();
      final totalJobs = jobs.length;
      final queuedStatuses = {AiJobStatus.queued.name, AiJobStatus.queued.toString()};
      final completedStatuses = {AiJobStatus.completed.name, AiJobStatus.completed.toString()};
      final failedStatuses = {AiJobStatus.failed.name, AiJobStatus.failed.toString()};

      final completedJobs =
          jobs.where((job) => completedStatuses.contains(job['status'])).length;
      final failedJobs =
          jobs.where((job) => failedStatuses.contains(job['status'])).length;
      final queuedJobs =
          jobs.where((job) => queuedStatuses.contains(job['status'])).length;

      // Log queue statistics for monitoring
      WasteAppLogger.info('Queue health check', context: {
        'service': 'ai_job_service',
        'total_jobs': totalJobs,
        'completed': completedJobs,
        'failed': failedJobs,
        'queued': queuedJobs,
        'completion_rate': totalJobs > 0
            ? (completedJobs / totalJobs * 100).toStringAsFixed(1)
            : '0',
        'failure_rate': totalJobs > 0
            ? (failedJobs / totalJobs * 100).toStringAsFixed(1)
            : '0',
      });

      // Use the same logic as QueueHealth.get health
      if (queuedJobs > 1000) return QueueHealth.overloaded;
      if (queuedJobs > 500) return QueueHealth.busy;
      if (queuedJobs > 100) return QueueHealth.moderate;
      return QueueHealth.healthy;
    } catch (e) {
      WasteAppLogger.severe('Failed to get queue health', error: e, context: {
        'service': 'ai_job_service',
      });
      return QueueHealth.healthy;
    }
  }
}
