/// Raw provider response with usage metadata.
///
/// Carries the full wire response (raw map + pre-extracted text content)
/// and usage metadata back to the orchestration layer. Prompt construction,
/// cost tracking, caching, and parsing are owned by the caller.
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
  /// The orchestration layer uses this for response parsing, error
  /// diagnostics, and debugging.
  final Map<String, dynamic> rawResponseMap;

  /// Pre-extracted text content, primarily for Gemini which nests the
  /// classification text inside candidates[0].content.parts[0].text.
  ///
  /// For OpenAI this is null because the parser expects the full
  /// `choices[0].message.content` path inside [rawResponseMap].
  final String? textContent;

  /// Estimated prompt (input) tokens from the provider, or null when
  /// the response does not include usage metadata.
  final int? inputTokens;

  /// Estimated completion (output) tokens from the provider.
  final int? outputTokens;
}
