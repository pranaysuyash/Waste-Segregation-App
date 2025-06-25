import '../utils/waste_app_logger.dart';
import '../models/token_wallet.dart';
import 'dynamic_pricing_service.dart';
import 'cost_guardrail_service.dart';

/// Utility class for tracking AI API costs in analysis operations
///
/// Provides simple methods to estimate, track, and log costs for AI operations
/// with integration to dynamic pricing and guardrail services.
class AiCostTracker {
  AiCostTracker({
    required this.pricingService,
    required this.guardrailService,
  });

  final DynamicPricingService pricingService;
  final CostGuardrailService guardrailService;

  /// Estimate cost for an analysis operation
  Future<CostEstimate> estimateCost({
    required String model,
    required int estimatedInputTokens,
    required int estimatedOutputTokens,
    bool isBatchMode = false,
  }) async {
    final cost = pricingService.calculateCost(
      model: model,
      inputTokens: estimatedInputTokens,
      outputTokens: estimatedOutputTokens,
      isBatchMode: isBatchMode,
    );

    final batchSavings = isBatchMode 
        ? 0.0 
        : pricingService.getEstimatedBatchSavings(
            model: model,
            estimatedInputTokens: estimatedInputTokens,
            estimatedOutputTokens: estimatedOutputTokens,
          );

    final canAffordInstant = guardrailService.canUseInstantAnalysis(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    );

    final recommendedSpeed = guardrailService.getRecommendedAnalysisSpeed(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    );

    return CostEstimate(
      model: model,
      inputTokens: estimatedInputTokens,
      outputTokens: estimatedOutputTokens,
      estimatedCost: cost,
      isBatchMode: isBatchMode,
      potentialBatchSavings: batchSavings,
      canAffordInstant: canAffordInstant,
      recommendedSpeed: recommendedSpeed,
      budgetUtilization: pricingService.getBudgetUtilization(),
    );
  }

  /// Record actual cost after API operation
  Future<void> recordActualCost({
    required String model,
    required int actualInputTokens,
    required int actualOutputTokens,
    required bool isBatchMode,
    required String operationId,
    String? classificationId,
    Duration? processingTime,
  }) async {
    final actualCost = pricingService.calculateCost(
      model: model,
      inputTokens: actualInputTokens,
      outputTokens: actualOutputTokens,
      isBatchMode: isBatchMode,
    );

    // Record in both services
    await pricingService.recordSpending(
      model: model,
      cost: actualCost,
      inputTokens: actualInputTokens,
      outputTokens: actualOutputTokens,
      isBatchMode: isBatchMode,
    );

    await guardrailService.recordApiSpending(
      model: model,
      cost: actualCost,
      inputTokens: actualInputTokens,
      outputTokens: actualOutputTokens,
      isBatchMode: isBatchMode,
    );

    // Comprehensive logging
    WasteAppLogger.info('AI cost recorded', null, null, {
      'service': 'ai_cost_tracker',
      'operation_id': operationId,
      'classification_id': classificationId,
      'model': model,
      'actual_cost': actualCost,
      'input_tokens': actualInputTokens,
      'output_tokens': actualOutputTokens,
      'total_tokens': actualInputTokens + actualOutputTokens,
      'is_batch_mode': isBatchMode,
      'processing_time_ms': processingTime?.inMilliseconds,
      'cost_per_token': actualCost / (actualInputTokens + actualOutputTokens),
      'daily_spending': pricingService.getDailySpending(),
      'budget_utilization': pricingService.getBudgetUtilization(),
      'batch_mode_enforced': guardrailService.isBatchModeEnforced,
    });
  }

  /// Extract token counts from OpenAI response
  TokenCounts? extractTokenCountsFromResponse(Map<String, dynamic> responseData) {
    try {
      final usage = responseData['usage'];
      if (usage != null) {
        return TokenCounts(
          inputTokens: usage['prompt_tokens'] ?? 0,
          outputTokens: usage['completion_tokens'] ?? 0,
          totalTokens: usage['total_tokens'] ?? 0,
        );
      }
    } catch (e) {
      WasteAppLogger.warning('Failed to extract token counts from response', e, null, {
        'service': 'ai_cost_tracker',
        'error': 'token_extraction_failed',
      });
    }
    return null;
  }

  /// Extract token counts from Gemini response
  TokenCounts? extractTokenCountsFromGeminiResponse(Map<String, dynamic> responseData) {
    try {
      final usageMetadata = responseData['usageMetadata'];
      if (usageMetadata != null) {
        return TokenCounts(
          inputTokens: usageMetadata['promptTokenCount'] ?? 0,
          outputTokens: usageMetadata['candidatesTokenCount'] ?? 0,
          totalTokens: usageMetadata['totalTokenCount'] ?? 0,
        );
      }
    } catch (e) {
      WasteAppLogger.warning('Failed to extract token counts from Gemini response', e, null, {
        'service': 'ai_cost_tracker',
        'error': 'gemini_token_extraction_failed',
      });
    }
    return null;
  }

  /// Estimate token count from text (rough approximation)
  int estimateTokenCount(String text) {
    // Very rough estimation: 1 token ≈ 4 characters for English text
    // This is a fallback when actual token counts aren't available
    return (text.length / 4).ceil();
  }

  /// Get cost summary for reporting
  Map<String, dynamic> getCostSummary() {
    return {
      'pricing': pricingService.getPricingSummary(),
      'guardrails': guardrailService.getCostAnalyticsSummary(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if operation should be performed based on cost constraints
  OperationDecision shouldProceedWithOperation({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
    required bool userRequestedInstant,
  }) {
    final batchModeEnforced = guardrailService.isBatchModeEnforced;
    final canAffordInstant = guardrailService.canUseInstantAnalysis(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    );

    if (userRequestedInstant && batchModeEnforced) {
      return OperationDecision(
        shouldProceed: true,
        forceAnalysisSpeed: AnalysisSpeed.batch,
        reason: 'Batch mode enforced due to budget constraints',
        recommendedMessage: 'Budget limit reached. Analysis will be processed in batch mode (2-6 hours).',
      );
    }

    if (userRequestedInstant && !canAffordInstant) {
      return OperationDecision(
        shouldProceed: true,
        forceAnalysisSpeed: AnalysisSpeed.batch,
        reason: 'Insufficient budget for instant analysis',
        recommendedMessage: 'Switching to batch mode to stay within budget limits.',
      );
    }

    final recommendedSpeed = guardrailService.getRecommendedAnalysisSpeed(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    );

    return OperationDecision(
      shouldProceed: true,
      forceAnalysisSpeed: null,
      recommendedSpeed: recommendedSpeed,
      reason: 'Normal operation',
      recommendedMessage: null,
    );
  }
}

/// Cost estimate for an AI operation
class CostEstimate {
  const CostEstimate({
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCost,
    required this.isBatchMode,
    required this.potentialBatchSavings,
    required this.canAffordInstant,
    required this.recommendedSpeed,
    required this.budgetUtilization,
  });

  final String model;
  final int inputTokens;
  final int outputTokens;
  final double estimatedCost;
  final bool isBatchMode;
  final double potentialBatchSavings;
  final bool canAffordInstant;
  final AnalysisSpeed recommendedSpeed;
  final Map<String, double> budgetUtilization;

  int get totalTokens => inputTokens + outputTokens;
  double get costPerToken => totalTokens > 0 ? estimatedCost / totalTokens : 0.0;
  double get savingsPercentage => estimatedCost > 0 ? (potentialBatchSavings / estimatedCost) * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'total_tokens': totalTokens,
      'estimated_cost': estimatedCost,
      'cost_per_token': costPerToken,
      'is_batch_mode': isBatchMode,
      'potential_batch_savings': potentialBatchSavings,
      'savings_percentage': savingsPercentage,
      'can_afford_instant': canAffordInstant,
      'recommended_speed': recommendedSpeed.name,
      'budget_utilization': budgetUtilization,
    };
  }
}

/// Token counts from API response
class TokenCounts {
  const TokenCounts({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  @override
  String toString() {
    return 'TokenCounts(input: $inputTokens, output: $outputTokens, total: $totalTokens)';
  }
}

/// Decision about whether to proceed with an operation
class OperationDecision {
  const OperationDecision({
    required this.shouldProceed,
    this.forceAnalysisSpeed,
    this.recommendedSpeed,
    required this.reason,
    this.recommendedMessage,
  });

  final bool shouldProceed;
  final AnalysisSpeed? forceAnalysisSpeed;
  final AnalysisSpeed? recommendedSpeed;
  final String reason;
  final String? recommendedMessage;

  AnalysisSpeed get effectiveSpeed => 
      forceAnalysisSpeed ?? recommendedSpeed ?? AnalysisSpeed.instant;

  Map<String, dynamic> toJson() {
    return {
      'should_proceed': shouldProceed,
      'force_analysis_speed': forceAnalysisSpeed?.name,
      'recommended_speed': recommendedSpeed?.name,
      'effective_speed': effectiveSpeed.name,
      'reason': reason,
      'recommended_message': recommendedMessage,
    };
  }
}

