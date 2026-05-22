import 'package:waste_segregation_app/models/waste_classification.dart'
    show WasteClassification;
import 'package:waste_segregation_app/services/ai_service.dart' show AiService;

/// Raw provider response with usage metadata.
///
/// Carries the full wire response back to [AiService] so that prompt
/// construction, cost tracking, caching, and parsing all remain
/// in the caller. This is *not* a [WasteClassification].
class AiProviderResponse {
  const AiProviderResponse({
    required this.provider,
    required this.model,
    required this.rawResponseMap,
    this.textContent,
    this.inputTokens,
    this.outputTokens,
  });

  /// Canonical provider name (e.g. 'openai', 'gemini').
  final String provider;

  /// The model identifier used for this request.
  final String model;

  /// Full response map returned by the provider wire API.
  ///
  /// The caller (AiService) uses this for response parsing via
  /// `_processAiResponseData`, error diagnostics, and debugging.
  final Map<String, dynamic> rawResponseMap;

  /// Pre-extracted text content, primarily for Gemini which nests the
  /// classification text inside candidates[0].content.parts[0].text.
  ///
  /// For OpenAI this is null because AiService's parser expects the
  /// full `choices[0].message.content` path inside [rawResponseMap].
  final String? textContent;

  /// Estimated prompt (input) tokens from the provider, or null when
  /// the response does not include usage metadata.
  final int? inputTokens;

  /// Estimated completion (output) tokens from the provider.
  final int? outputTokens;
}
