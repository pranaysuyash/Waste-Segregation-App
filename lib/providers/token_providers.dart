import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token_wallet.dart';
import '../models/ai_job.dart';
import '../services/token_service.dart';
import 'app_providers.dart';
import '../utils/firebase_gate.dart';
import '../services/firestore_schema_registry.dart';

/// Provider for the TokenService
final tokenServiceProvider = Provider<TokenService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final cloudStorageService = ref.watch(cloudStorageServiceProvider);
  return TokenService(storageService, cloudStorageService);
});

/// Provider for the current token wallet
final tokenWalletProvider = FutureProvider<TokenWallet?>((ref) async {
  final tokenService = ref.watch(tokenServiceProvider);
  await tokenService.initialize();
  return tokenService.currentWallet;
});

/// Provider for token transaction history
final tokenTransactionsProvider =
    FutureProvider<List<TokenTransaction>>((ref) async {
  final tokenService = ref.watch(tokenServiceProvider);
  return tokenService.getTransactionHistory();
});

/// Provider for wallet statistics
final walletStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tokenService = ref.watch(tokenServiceProvider);
  return tokenService.getWalletStats();
});

/// Provider for checking if user can afford a specific cost
final canAffordProvider = Provider.family<bool, int>((ref, cost) {
  final walletAsync = ref.watch(tokenWalletProvider);
  return walletAsync.when(
    data: (wallet) => wallet?.canAfford(cost) ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for remaining daily conversions
final remainingConversionsProvider = Provider<int>((ref) {
  final walletAsync = ref.watch(tokenWalletProvider);
  return walletAsync.when(
    data: (wallet) =>
        wallet?.remainingConversions(TokenService.maxDailyConversions) ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for analysis speed selection state
final analysisSpeedProvider = StateProvider<AnalysisSpeed>((ref) {
  // Default to batch mode for new users
  return AnalysisSpeed.batch;
});

/// Provider for checking if instant analysis is affordable
final instantAnalysisAffordableProvider = Provider<bool>((ref) {
  return ref.watch(canAffordProvider(AnalysisSpeed.instant.cost));
});

/// Provider for AI job queue - queries all active jobs from Firestore
final aiJobQueueProvider = FutureProvider<List<AiJob>>((ref) async {
  if (!isFirebaseEnabled) {
    return [];
  }
  final firestore = FirebaseFirestore.instance;
  final activeStatuses = [
    AiJobStatus.queued.toString(),
    AiJobStatus.processing.toString(),
  ];
  final snapshot = await firestore
      .collection(FirestoreCollections.aiJobs)
      .where('status', whereIn: activeStatuses)
      .orderBy('createdAt', descending: false)
      .get();
  return snapshot.docs.map((doc) => AiJob.fromJson(doc.data())).toList();
});

/// Provider for token queue statistics from Firestore
final tokenQueueStatsProvider = FutureProvider<QueueStats>((ref) async {
  if (!isFirebaseEnabled) {
    return QueueStats.empty();
  }
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final oneDayAgo = now.subtract(const Duration(days: 1));
  final snapshot = await firestore
      .collection(FirestoreCollections.aiJobs)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
      .get();

  if (snapshot.docs.isEmpty) return QueueStats.empty();

  final jobs = snapshot.docs.map((doc) => doc.data()).toList();
  final queuedStatus = AiJobStatus.queued.toString();
  final processingStatus = AiJobStatus.processing.toString();
  final completedStatus = AiJobStatus.completed.toString();
  final failedStatus = AiJobStatus.failed.toString();
  final queuedJobs = jobs.where((j) => j['status'] == queuedStatus).length;
  final processingJobs =
      jobs.where((j) => j['status'] == processingStatus).length;
  final completedJobs =
      jobs.where((j) => j['status'] == completedStatus).length;
  final failedJobs = jobs.where((j) => j['status'] == failedStatus).length;
  final total = jobs.length;

  return QueueStats(
    totalJobs: total,
    queuedJobs: queuedJobs,
    processingJobs: processingJobs,
    completedToday: completedJobs,
    failedToday: failedJobs,
    averageWaitTime: Duration(minutes: queuedJobs * 5),
    lastUpdated: DateTime.now(),
    averageProcessingTime: const Duration(seconds: 30),
    estimatedWaitTime: Duration(minutes: queuedJobs * 5),
    successRate: total > 0 ? completedJobs / total : 1.0,
    failureRate: total > 0 ? failedJobs / total : 0.0,
    pendingJobs: queuedJobs,
  );
});

/// Provider for user's pending jobs from Firestore
final userJobsProvider =
    FutureProvider.family<List<AiJob>, String>((ref, userId) async {
  if (!isFirebaseEnabled) {
    return [];
  }
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore
      .collection(FirestoreCollections.aiJobs)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .get();
  return snapshot.docs.map((doc) => AiJob.fromJson(doc.data())).toList();
});

/// Provider for converting points to tokens
final convertPointsProvider =
    FutureProvider.family<TokenWallet, ConvertPointsParams>(
        (ref, params) async {
  final tokenService = ref.watch(tokenServiceProvider);
  return tokenService.convertPointsToTokens(
      params.pointsToConvert, params.currentUserPoints);
});

/// Parameters for point conversion
class ConvertPointsParams {
  const ConvertPointsParams({
    required this.pointsToConvert,
    required this.currentUserPoints,
  });

  final int pointsToConvert;
  final int currentUserPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConvertPointsParams &&
          runtimeType == other.runtimeType &&
          pointsToConvert == other.pointsToConvert &&
          currentUserPoints == other.currentUserPoints;

  @override
  int get hashCode => pointsToConvert.hashCode ^ currentUserPoints.hashCode;
}
