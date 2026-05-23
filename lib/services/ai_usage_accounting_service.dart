import 'package:waste_segregation_app/services/cost_guardrail_service.dart';
import 'package:waste_segregation_app/services/dynamic_pricing_service.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Records AI usage cost and spending for direct provider calls.
///
/// Rules:
///   - `openai` / `gemini` direct  → record client spending
///   - `backend`                   → skip (server tracks cost)
///   - `local_vlm` / future local  → cost 0
class AiUsageAccountingService {
  AiUsageAccountingService({
    required DynamicPricingService pricingService,
    required CostGuardrailService guardrailService,
  })  : _pricingService = pricingService,
        _guardrailService = guardrailService;

  final DynamicPricingService _pricingService;
  final CostGuardrailService _guardrailService;

  /// Record usage from a direct provider call.
  ///
  /// Returns the computed cost, or null when the provider is server-tracked
  /// or local (no client-side cost recording needed).
  Future<double?> recordUsage({
    required AiProviderResponse response,
    required String modelKey,
    required Duration processingTime,
  }) async {
    // Backend tracks cost server-side; local providers are free.
    if (response.provider == 'backend') return null;
    if (response.provider == 'local_vlm') return 0.0;

    final inputTokens = response.inputTokens ?? 1500;
    final outputTokens = response.outputTokens ?? 800;

    final cost = _pricingService.calculateCost(
      model: modelKey,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    await _guardrailService.recordApiSpending(
      model: modelKey,
      cost: cost,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    WasteAppLogger.info('API cost recorded', context: {
      'service': 'ai_usage_accounting',
      'provider': response.provider,
      'model': modelKey,
      'cost': cost,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'processing_time_ms': processingTime.inMilliseconds,
    });

    return cost;
  }
}
