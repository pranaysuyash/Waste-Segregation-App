import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token_wallet.dart';
import '../models/ai_job.dart';
import '../services/token_service.dart';
import 'app_providers.dart';

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
final tokenTransactionsProvider = FutureProvider<List<TokenTransaction>>((ref) async {
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
    data: (wallet) => wallet?.remainingConversions(TokenService.maxDailyConversions) ?? 0,
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

/// Provider for AI job queue (stub for now - will be implemented with Firestore)
final aiJobQueueProvider = FutureProvider<List<AiJob>>((ref) async {
  // TODO: Implement with Firestore query
  // For now, return empty list
  return <AiJob>[];
});

/// Provider for queue statistics (stub for now)
final queueStatsProvider = FutureProvider<QueueStats>((ref) async {
  // TODO: Implement with Firestore aggregation
  // For now, return healthy queue
  return QueueStats(
    totalJobs: 0,
    queuedJobs: 0,
    processingJobs: 0,
    completedToday: 0,
    failedToday: 0,
    averageWaitTime: const Duration(minutes: 5),
    lastUpdated: DateTime.now(),
  );
});

/// Provider for user's pending jobs
final userJobsProvider = FutureProvider<List<AiJob>>((ref) async {
  // TODO: Implement with Firestore query filtered by user ID
  return <AiJob>[];
});

/// Provider for converting points to tokens
final convertPointsProvider = FutureProvider.family<TokenWallet, ConvertPointsParams>((ref, params) async {
  final tokenService = ref.watch(tokenServiceProvider);
  return tokenService.convertPointsToTokens(params.pointsToConvert, params.currentUserPoints);
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