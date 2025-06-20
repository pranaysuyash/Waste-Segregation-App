import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_job.dart';
import '../models/token_wallet.dart';
import '../models/waste_classification.dart';
import '../services/token_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/waste_app_logger.dart';

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
    TokenService? tokenService,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageService = storageService ?? StorageService(),
       _tokenService = tokenService ?? TokenService(storageService ?? StorageService(), CloudStorageService(storageService ?? StorageService()));

  final FirebaseFirestore _firestore;
  final TokenService _tokenService;
  final StorageService _storageService;

  static const String _jobsCollection = 'ai_jobs';
  static const String _openaiApiBase = 'https://api.openai.com/v1';

  /// Creates a new batch job for AI analysis
  /// 
  /// This method:
  /// 1. Deducts tokens from user's wallet
  /// 2. Uploads image to storage
  /// 3. Creates JSONL batch file
  /// 4. Submits to OpenAI Batch API
  /// 5. Stores job metadata in Firestore
  Future<String> createBatchJob({
    required String userId,
    required File imageFile,
  }) async {
    try {
      WasteAppLogger.info('Creating batch job for user: $userId', null, null, {
        'service': 'ai_job_service',
        'method': 'createBatchJob',
        'userId': userId,
      });

      // 1. Check and deduct tokens
      final tokenCost = AnalysisSpeed.batch.cost;
      try {
        await _tokenService.spendTokens(
          tokenCost,
          'Batch AI analysis',
          reference: 'batch_analysis',
        );
      } catch (e) {
        throw Exception('Insufficient tokens for batch analysis: $e');
      }

      // 2. Upload image to Cloud Storage
      final cloudStorageService = CloudStorageService(_storageService);
      final imagePath = await cloudStorageService.uploadImageForBatchProcessing(
        imageFile,
        userId,
      );

      // 3. Create job document
      final jobId = _firestore.collection(_jobsCollection).doc().id;
      final job = AiJob(
        id: jobId,
        userId: userId,
        imagePath: imagePath,
        speed: AnalysisSpeed.batch,
        status: AiJobStatus.queued,
        createdAt: DateTime.now(),
        tokensSpent: tokenCost,
      );

      // 4. Create OpenAI batch request
      final batchFileId = await _createOpenAIBatchFile(job);
      
      // 5. Submit batch job to OpenAI
      final openAIBatchId = await _submitOpenAIBatchJob(batchFileId);
      
      // 6. Update job with OpenAI batch ID
      final updatedJob = job.copyWith(
        metadata: {
          'openAIBatchId': openAIBatchId,
          'batchFileId': batchFileId,
        },
      );

      // 7. Save to Firestore
      await _firestore.collection(_jobsCollection).doc(jobId).set(updatedJob.toJson());

      WasteAppLogger.info('Batch job created successfully', null, null, {
        'service': 'ai_job_service',
        'jobId': jobId,
        'tokenCost': tokenCost,
        'openAIBatchId': openAIBatchId,
      });

      return jobId;
    } catch (e) {
      WasteAppLogger.severe('Failed to create batch job', e, null, {
        'service': 'ai_job_service',
        'userId': userId,
      });
      
      // Refund tokens on failure
      try {
        await _tokenService.earnTokens(
          AnalysisSpeed.batch.cost,
          TokenTransactionType.refund,
          'Batch job creation failed - token refund',
          reference: 'batch_job_refund',
        );
      } catch (refundError) {
        WasteAppLogger.severe('Failed to refund tokens after batch job failure', refundError, null, {
          'service': 'ai_job_service',
          'userId': userId,
        });
      }
      
      rethrow;
    }
  }

  /// Creates a JSONL file for OpenAI Batch API
  Future<String> _createOpenAIBatchFile(AiJob job) async {
    try {
      // Create batch request in OpenAI format
      final batchRequest = {
        'custom_id': 'job-${job.id}',
        'method': 'POST',
        'url': '/v1/chat/completions',
        'body': {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(false),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Classify this waste item for proper disposal.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': job.imagePath,
                    'detail': 'high',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.1,
          'response_format': {
            'type': 'json_object',
          },
        },
      };

      // Convert to JSONL format
      final jsonlContent = json.encode(batchRequest);

      // Upload to OpenAI Files API
      final fileId = await _uploadToOpenAI(jsonlContent, 'batch_${job.id}.jsonl');
      
      WasteAppLogger.info('Created OpenAI batch file', null, null, {
        'service': 'ai_job_service',
        'jobId': job.id,
        'fileId': fileId,
      });

      return fileId;
    } catch (e) {
      WasteAppLogger.severe('Failed to create OpenAI batch file', e, null, {
        'service': 'ai_job_service',
        'jobId': job.id,
      });
      rethrow;
    }
  }

  /// Uploads JSONL content to OpenAI Files API
  Future<String> _uploadToOpenAI(String jsonlContent, String filename) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_openaiApiBase/files'),
      );

      request.headers['Authorization'] = 'Bearer ${_getOpenAIApiKey()}';
      request.fields['purpose'] = 'batch';
      
      request.files.add(http.MultipartFile.fromString(
        'file',
        jsonlContent,
        filename: filename,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['id'];
      } else {
        throw Exception('Failed to upload file to OpenAI: $responseBody');
      }
    } catch (e) {
      WasteAppLogger.severe('Failed to upload to OpenAI', e, null, {
        'service': 'ai_job_service',
        'filename': filename,
      });
      rethrow;
    }
  }

  /// Submits batch job to OpenAI Batch API
  Future<String> _submitOpenAIBatchJob(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('$_openaiApiBase/batches'),
        headers: {
          'Authorization': 'Bearer ${_getOpenAIApiKey()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'input_file_id': fileId,
          'endpoint': '/v1/chat/completions',
          'completion_window': '24h', // OpenAI requires 24h window
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        throw Exception('Failed to submit batch job: ${response.body}');
      }
    } catch (e) {
      WasteAppLogger.severe('Failed to submit OpenAI batch job', e, null, {
        'service': 'ai_job_service',
        'fileId': fileId,
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

      WasteAppLogger.info('Updated job status', null, null, {
        'service': 'ai_job_service',
        'jobId': jobId,
        'status': status.name,
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to update job status', e, null, {
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
        .map((snapshot) => snapshot.docs
            .map((doc) => AiJob.fromJson(doc.data()))
            .toList());
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
      final queuedJobs = jobs.where((job) => job['status'] == AiJobStatus.queued.name).length;
      final processingJobs = jobs.where((job) => job['status'] == AiJobStatus.processing.name).length;
      final completedJobs = jobs.where((job) => job['status'] == AiJobStatus.completed.name).length;
      final failedJobs = jobs.where((job) => job['status'] == AiJobStatus.failed.name).length;

      // Calculate average processing time from completed jobs
      final completedJobsWithTimes = jobs.where((job) => 
        job['status'] == AiJobStatus.completed.name && 
        job['completedAt'] != null &&
        job['createdAt'] != null
      ).toList();

      var averageProcessingTime = const Duration(seconds: 30); // Default
      if (completedJobsWithTimes.isNotEmpty) {
        final totalProcessingTime = completedJobsWithTimes.fold<int>(0, (sum, job) {
          final createdAt = (job['createdAt'] as Timestamp).toDate();
          final completedAt = (job['completedAt'] as Timestamp).toDate();
          return sum + completedAt.difference(createdAt).inMilliseconds;
        });
        averageProcessingTime = Duration(milliseconds: totalProcessingTime ~/ completedJobsWithTimes.length);
      }

      // Calculate success and failure rates
      final totalProcessedJobs = completedJobs + failedJobs;
      final successRate = totalProcessedJobs > 0 ? completedJobs / totalProcessedJobs : 1.0;
      final failureRate = totalProcessedJobs > 0 ? failedJobs / totalProcessedJobs : 0.0;

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
        averageWaitTime = Duration(milliseconds: totalWaitTime ~/ completedJobsWithTimes.length);
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
      WasteAppLogger.severe('Failed to get queue stats', e, null, {
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
      final completedJobs = jobs.where((job) => job['status'] == AiJobStatus.completed.name).length;
      final failedJobs = jobs.where((job) => job['status'] == AiJobStatus.failed.name).length;
      final queuedJobs = jobs.where((job) => job['status'] == AiJobStatus.queued.name).length;

      // Use the same logic as QueueHealth.get health
      if (queuedJobs > 1000) return QueueHealth.overloaded;
      if (queuedJobs > 500) return QueueHealth.busy;
      if (queuedJobs > 100) return QueueHealth.moderate;
      return QueueHealth.healthy;
    } catch (e) {
      WasteAppLogger.severe('Failed to get queue health', e, null, {
        'service': 'ai_job_service',
      });
      return QueueHealth.healthy;
    }
  }

  /// Get the system prompt for waste classification
  String _getSystemPrompt(bool useSegmentation) {
    return '''You are an expert waste classification AI. Analyze the provided image and classify the waste item for proper disposal.

IMPORTANT: Your response must be valid JSON with the following structure:
{
  "itemName": "string - name of the waste item",
  "category": "string - waste category (recyclable, organic, hazardous, general)",
  "confidence": number - confidence score 0-1,
  "disposalInstructions": "string - how to dispose of this item",
  "environmentalImpact": "string - environmental impact if disposed incorrectly",
  "alternativeUses": "string - potential reuse or recycling options",
  "location": "string - where to dispose (recycling center, compost, etc.)"
}

Focus on accuracy and provide clear, actionable disposal instructions. Consider local waste management practices and environmental impact.''';
  }

  /// Get the OpenAI API key from environment or configuration
  String _getOpenAIApiKey() {
    // In production, this would come from secure environment variables
    // For now, return a placeholder that indicates missing configuration
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    
    if (apiKey.isEmpty) {
      WasteAppLogger.severe('OpenAI API key not configured', null, null, {
        'service': 'ai_job_service',
        'method': '_getOpenAIApiKey',
      });
      throw Exception('OpenAI API key not configured. Please set OPENAI_API_KEY environment variable.');
    }
    
    return apiKey;
  }
}