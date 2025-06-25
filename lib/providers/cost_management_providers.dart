import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dynamic_pricing_service.dart';
import '../services/cost_guardrail_service.dart';
import '../services/enhanced_api_error_handler.dart';
import '../services/ai_cost_tracker.dart';
import '../services/remote_config_service.dart';
import '../models/token_wallet.dart';

/// Provider for the DynamicPricingService
final dynamicPricingServiceProvider = Provider<DynamicPricingService>((ref) {
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);
  return DynamicPricingService(remoteConfigService: remoteConfigService);
});

/// Provider for the RemoteConfigService
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Provider for the CostGuardrailService
final costGuardrailServiceProvider = Provider<CostGuardrailService>((ref) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);
  return CostGuardrailService(
    pricingService: pricingService,
    remoteConfigService: remoteConfigService,
  );
});

/// Provider for the EnhancedApiErrorHandler
final enhancedApiErrorHandlerProvider = Provider<EnhancedApiErrorHandler>((ref) {
  return EnhancedApiErrorHandler();
});

/// Provider for the AiCostTracker
final aiCostTrackerProvider = Provider<AiCostTracker>((ref) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return AiCostTracker(
    pricingService: pricingService,
    guardrailService: guardrailService,
  );
});

/// Provider for current pricing information
final currentPricingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  await pricingService.initialize();
  return pricingService.getPricingSummary();
});

/// Provider for budget utilization
final budgetUtilizationProvider = StreamProvider<Map<String, double>>((ref) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.budgetUtilization;
});

/// Provider for batch mode enforcement status
final batchModeEnforcedProvider = StreamProvider<bool>((ref) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.batchModeEnforced;
});

/// Provider for cost alerts
final costAlertsProvider = StreamProvider<CostAlert>((ref) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.costAlerts;
});

/// Provider for checking if instant analysis is affordable
final instantAnalysisAffordableProvider = Provider.family<bool, AnalysisSpeedCheckParams>((ref, params) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.canUseInstantAnalysis(
    model: params.model,
    estimatedInputTokens: params.estimatedInputTokens,
    estimatedOutputTokens: params.estimatedOutputTokens,
  );
});

/// Provider for recommended analysis speed
final recommendedAnalysisSpeedProvider = Provider.family<AnalysisSpeed, AnalysisSpeedCheckParams>((ref, params) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.getRecommendedAnalysisSpeed(
    model: params.model,
    estimatedInputTokens: params.estimatedInputTokens,
    estimatedOutputTokens: params.estimatedOutputTokens,
  );
});

/// Provider for daily spending
final dailySpendingProvider = Provider<double>((ref) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  return pricingService.getDailySpending();
});

/// Provider for weekly spending
final weeklySpendingProvider = Provider<double>((ref) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  return pricingService.getWeeklySpending();
});

/// Provider for monthly spending
final monthlySpendingProvider = Provider<double>((ref) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  return pricingService.getMonthlySpending();
});

/// Provider for spending breakdown by model
final spendingBreakdownProvider = Provider.family<Map<String, double>, String>((ref, period) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  return pricingService.getSpendingBreakdown(period);
});

/// Provider for cost estimate
final costEstimateProvider = FutureProvider.family<CostEstimate, CostEstimateParams>((ref, params) async {
  final costTracker = ref.watch(aiCostTrackerProvider);
  return costTracker.estimateCost(
    model: params.model,
    estimatedInputTokens: params.estimatedInputTokens,
    estimatedOutputTokens: params.estimatedOutputTokens,
    isBatchMode: params.isBatchMode,
  );
});

/// Provider for operation decision
final operationDecisionProvider = Provider.family<OperationDecision, OperationDecisionParams>((ref, params) {
  final costTracker = ref.watch(aiCostTrackerProvider);
  return costTracker.shouldProceedWithOperation(
    model: params.model,
    estimatedInputTokens: params.estimatedInputTokens,
    estimatedOutputTokens: params.estimatedOutputTokens,
    userRequestedInstant: params.userRequestedInstant,
  );
});

/// Provider for recent cost alerts
final recentCostAlertsProvider = Provider<List<CostAlert>>((ref) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.getRecentAlerts();
});

/// Provider for circuit breaker status
final circuitBreakerStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final errorHandler = ref.watch(enhancedApiErrorHandlerProvider);
  return errorHandler.getCircuitBreakerStatus();
});

/// Provider for cost analytics summary
final costAnalyticsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final guardrailService = ref.watch(costGuardrailServiceProvider);
  return guardrailService.getCostAnalyticsSummary();
});

/// Provider for batch savings estimate
final batchSavingsEstimateProvider = Provider.family<double, BatchSavingsParams>((ref, params) {
  final pricingService = ref.watch(dynamicPricingServiceProvider);
  return pricingService.getEstimatedBatchSavings(
    model: params.model,
    estimatedInputTokens: params.estimatedInputTokens,
    estimatedOutputTokens: params.estimatedOutputTokens,
  );
});

/// Parameters for analysis speed checking
class AnalysisSpeedCheckParams {
  const AnalysisSpeedCheckParams({
    required this.model,
    this.estimatedInputTokens,
    this.estimatedOutputTokens,
  });

  final String model;
  final int? estimatedInputTokens;
  final int? estimatedOutputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisSpeedCheckParams &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          estimatedInputTokens == other.estimatedInputTokens &&
          estimatedOutputTokens == other.estimatedOutputTokens;

  @override
  int get hashCode => model.hashCode ^ estimatedInputTokens.hashCode ^ estimatedOutputTokens.hashCode;
}

/// Parameters for cost estimation
class CostEstimateParams {
  const CostEstimateParams({
    required this.model,
    required this.estimatedInputTokens,
    required this.estimatedOutputTokens,
    required this.isBatchMode,
  });

  final String model;
  final int estimatedInputTokens;
  final int estimatedOutputTokens;
  final bool isBatchMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CostEstimateParams &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          estimatedInputTokens == other.estimatedInputTokens &&
          estimatedOutputTokens == other.estimatedOutputTokens &&
          isBatchMode == other.isBatchMode;

  @override
  int get hashCode =>
      model.hashCode ^ estimatedInputTokens.hashCode ^ estimatedOutputTokens.hashCode ^ isBatchMode.hashCode;
}

/// Parameters for operation decision
class OperationDecisionParams {
  const OperationDecisionParams({
    required this.model,
    required this.userRequestedInstant,
    this.estimatedInputTokens,
    this.estimatedOutputTokens,
  });

  final String model;
  final bool userRequestedInstant;
  final int? estimatedInputTokens;
  final int? estimatedOutputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationDecisionParams &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          userRequestedInstant == other.userRequestedInstant &&
          estimatedInputTokens == other.estimatedInputTokens &&
          estimatedOutputTokens == other.estimatedOutputTokens;

  @override
  int get hashCode =>
      model.hashCode ^ userRequestedInstant.hashCode ^ estimatedInputTokens.hashCode ^ estimatedOutputTokens.hashCode;
}

/// Parameters for batch savings calculation
class BatchSavingsParams {
  const BatchSavingsParams({
    required this.model,
    this.estimatedInputTokens,
    this.estimatedOutputTokens,
  });

  final String model;
  final int? estimatedInputTokens;
  final int? estimatedOutputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchSavingsParams &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          estimatedInputTokens == other.estimatedInputTokens &&
          estimatedOutputTokens == other.estimatedOutputTokens;

  @override
  int get hashCode => model.hashCode ^ estimatedInputTokens.hashCode ^ estimatedOutputTokens.hashCode;
}

// Re-export types for convenience
export '../services/cost_guardrail_service.dart' show CostAlert, CostAlertType, CostAlertSeverity;
export '../services/ai_cost_tracker.dart' show CostEstimate, TokenCounts, OperationDecision;