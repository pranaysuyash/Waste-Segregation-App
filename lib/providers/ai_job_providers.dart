import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_job_service.dart';
import '../models/ai_job.dart';

/// Provider for the AI job service
final aiJobServiceProvider = Provider<AiJobService>((ref) {
  return AiJobService();
});

/// Provider for user's AI jobs stream
final userAiJobsProvider = StreamProvider.family<List<AiJob>, String>((ref, userId) {
  final aiJobService = ref.watch(aiJobServiceProvider);
  return aiJobService.getUserJobs(userId);
});

/// Provider for queue statistics
final queueStatsProvider = FutureProvider<QueueStats>((ref) async {
  final aiJobService = ref.watch(aiJobServiceProvider);
  return aiJobService.getQueueStats();
});

/// Provider for queue health metrics
final queueHealthProvider = FutureProvider<QueueHealth>((ref) async {
  final aiJobService = ref.watch(aiJobServiceProvider);
  return aiJobService.getQueueHealth();
});

/// Provider for creating a batch job
final createBatchJobProvider = Provider<AiJobService>((ref) {
  return ref.watch(aiJobServiceProvider);
});

/// State notifier for managing batch job creation
class BatchJobCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  BatchJobCreationNotifier(this._aiJobService) : super(const AsyncValue.data(null));

  final AiJobService _aiJobService;

  /// Creates a new batch job
  Future<String> createJob({
    required String userId,
    required dynamic imageFile, // File for mobile, Uint8List for web
  }) async {
    state = const AsyncValue.loading();

    try {
      final jobId = await _aiJobService.createBatchJob(
        userId: userId,
        imageFile: imageFile,
      );

      state = AsyncValue.data(jobId);
      return jobId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Resets the state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for batch job creation state
final batchJobCreationProvider = StateNotifierProvider<BatchJobCreationNotifier, AsyncValue<String?>>((ref) {
  final aiJobService = ref.watch(aiJobServiceProvider);
  return BatchJobCreationNotifier(aiJobService);
});
