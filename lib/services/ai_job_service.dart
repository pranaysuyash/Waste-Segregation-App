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
       _tokenService = tokenService ?? TokenService(StorageService(), CloudStorageService()),
       _storageService = storageService ?? StorageService();

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
    required String imageName,
    List<Map<String, dynamic>>? segments,
    bool useSegmentation = false,
  }) async {
    try {
      WasteAppLogger.info('Creating batch job for user: $userId', null, null, {
        'service': 'ai_job_service',
        'method': 'createBatchJob',
        'userId': userId,
        'imageName': imageName,
        'useSegmentation': useSegmentation,
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

      // 2. Upload image to storage
      final imageUrl = await _storageService.uploadImage(
        imageFile,
        'batch_jobs/$userId/${DateTime.now().millisecondsSinceEpoch}_$imageName',
      );

      // 3. Create job document
      final jobId = _firestore.collection(_jobsCollection).doc().id;
      final job = AiJob(
        id: jobId,
        userId: userId,
        imageUrl: imageUrl,
        imageName: imageName,
        segments: segments,
        useSegmentation: useSegmentation,
        status: AiJobStatus.pending,
        createdAt: DateTime.now(),
        tokenCost: tokenCost,
      );

      // 4. Create OpenAI batch request
      final batchFileId = await _createOpenAIBatchFile(job);
      final openAIBatchId = await _submitOpenAIBatchJob(batchFileId);

      // 5. Update job with OpenAI batch ID
      final updatedJob = job.copyWith(
        openAIBatchId: openAIBatchId,
        openAIFileId: batchFileId,
        status: AiJobStatus.queued,
      );

      // 6. Save to Firestore
      await _firestore.collection(_jobsCollection).doc(jobId).set(updatedJob.toJson());

      WasteAppLogger.info('Batch job created successfully', null, null, {
        'service': 'ai_job_service',
        'jobId': jobId,
        'openAIBatchId': openAIBatchId,
        'tokenCost': tokenCost,
      });

      return jobId;
    } catch (e) {
      WasteAppLogger.severe('Failed to create batch job', e, null, {
        'service': 'ai_job_service',
        'userId': userId,
        'imageName': imageName,
      });
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
          'model': 'gpt-4o-mini', // Using cost-effective model for batch processing
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(job.useSegmentation),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': job.useSegmentation 
                    ? 'Analyze the selected segments of this waste image for classification.'
                    : 'Classify this waste item for proper disposal.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': job.imageUrl,
                    'detail': 'high', // High detail for better classification
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.1, // Low temperature for consistent classification
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

  /// Gets queue statistics
  Future<QueueStats> getQueueStats() async {
    try {
      final snapshot = await _firestore
          .collection(_jobsCollection)
          .where('status', whereIn: [
            AiJobStatus.pending.name,
            AiJobStatus.queued.name,
            AiJobStatus.processing.name,
          ])
          .get();

      final pendingJobs = snapshot.docs.length;
      
      // Calculate average processing time from completed jobs
      final completedSnapshot = await _firestore
          .collection(_jobsCollection)
          .where('status', isEqualTo: AiJobStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .limit(100)
          .get();

      double averageProcessingTime = 0;
      if (completedSnapshot.docs.isNotEmpty) {
        final processingTimes = completedSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final created = (data['createdAt'] as Timestamp).toDate();
              final completed = (data['completedAt'] as Timestamp).toDate();
              return completed.difference(created).inMinutes.toDouble();
            })
            .toList();

        averageProcessingTime = processingTimes.reduce((a, b) => a + b) / processingTimes.length;
      }

      return QueueStats(
        pendingJobs: pendingJobs,
        averageProcessingTime: averageProcessingTime,
        estimatedWaitTime: pendingJobs * (averageProcessingTime / 60), // Convert to hours
      );
    } catch (e) {
      WasteAppLogger.severe('Failed to get queue stats', e, null, {
        'service': 'ai_job_service',
      });
      return QueueStats(
        pendingJobs: 0,
        averageProcessingTime: 0,
        estimatedWaitTime: 0,
      );
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

      final successRate = totalJobs > 0 ? (completedJobs / totalJobs) * 100 : 100.0;
      final failureRate = totalJobs > 0 ? (failedJobs / totalJobs) * 100 : 0.0;

      return QueueHealth(
        successRate: successRate,
        failureRate: failureRate,
        pendingJobs: jobs.where((job) => 
          job['status'] == AiJobStatus.pending.name ||
          job['status'] == AiJobStatus.queued.name ||
          job['status'] == AiJobStatus.processing.name
        ).length,
      );
    } catch (e) {
      WasteAppLogger.severe('Failed to get queue health', e, null, {
        'service': 'ai_job_service',
      });
      return QueueHealth(
        successRate: 0,
        failureRate: 100,
        pendingJobs: 0,
      );
    }
  }

  /// Gets system prompt for AI analysis
  String _getSystemPrompt(bool useSegmentation) {
    if (useSegmentation) {
      return '''
You are an expert waste classification AI. Analyze the selected segments of the waste image and provide detailed classification information.

Respond with a JSON object containing:
{
  "itemName": "specific name of the waste item",
  "category": "recyclable|organic|hazardous|general",
  "confidence": 0.95,
  "disposalInstructions": "specific disposal instructions",
  "environmentalImpact": "brief environmental impact description",
  "tips": ["tip1", "tip2", "tip3"]
}

Focus on the segmented areas and provide accurate classification based on the visible waste materials.
''';
    } else {
      return '''
You are an expert waste classification AI. Analyze the waste image and provide detailed classification information.

Respond with a JSON object containing:
{
  "itemName": "specific name of the waste item",
  "category": "recyclable|organic|hazardous|general",
  "confidence": 0.95,
  "disposalInstructions": "specific disposal instructions",
  "environmentalImpact": "brief environmental impact description",
  "tips": ["tip1", "tip2", "tip3"]
}

Provide accurate classification based on the visible waste materials and their characteristics.
''';
    }
  }

  /// Gets OpenAI API key from environment or secure storage
  String _getOpenAIApiKey() {
    // TODO: Replace with secure key management
    // In production, this should come from:
    // - Environment variables
    // - Firebase Remote Config
    // - Secure key management service
    return const String.fromEnvironment('OPENAI_API_KEY', 
      defaultValue: 'your-openai-api-key-here');
  }
}