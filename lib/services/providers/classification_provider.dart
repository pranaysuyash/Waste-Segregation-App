import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_provider_response.dart';

/// Minimum contract every classification provider must satisfy.
///
/// Implementors:
///   - `BackendProxyProvider`  — Firebase Callable gateway (backend, server-managed keys)
///   - `GeminiProviderClient`  — direct Gemini Vision HTTP client
///   - `OpenAiProviderClient`  — direct OpenAI Vision HTTP client
///   - `LocalVlmProvider`      — on-device VLM stub (UnimplementedError until bundled)
///
/// The interface intentionally uses a single `prompt` parameter rather than
/// OpenAI's separate `systemPrompt`/`userPrompt` pair — each concrete class
/// splits or ignores it as appropriate for its wire protocol.
abstract interface class ClassificationProvider {
  /// Human-readable provider identifier (e.g. 'backend', 'gemini', 'openai', 'local_vlm').
  String get providerName;

  /// Model identifier used for calls (e.g. 'gpt-4.1-nano', 'gemini-2.0-flash').
  String get modelName;

  /// Estimated USD cost per call, or null when unknown or server-tracked.
  ///
  /// Use `0.0` for free/on-device providers. Use `null` when cost is opaque
  /// (e.g. backend-routed calls where cost is tracked in `ai_cost_events`).
  double? get estimatedCostPerCall;

  /// Classify [imageBytes] and return a raw [AiProviderResponse].
  ///
  /// [imageBytes]  — pre-compressed image bytes; no compression is performed here.
  /// [mimeType]    — validated MIME type ('image/jpeg', 'image/png', 'image/webp').
  /// [prompt]      — combined classification prompt. Backend providers may ignore
  ///                 this and build their own server-side prompt.
  /// [clientHash]  — optional deduplication hint for cache backends.
  /// [region]      — user region (e.g. 'Bangalore, IN') for local guidelines.
  /// [lang]        — BCP-47 language code (e.g. 'en', 'hi').
  /// [requestId]   — optional idempotency key; backend providers use this to
  ///                 make retries safe. Local/direct providers ignore it.
  /// [cancelToken] — Dio cancel token for in-flight request cancellation.
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    String? clientHash,
    String? region,
    String? lang,
    String? requestId,
    CancelToken? cancelToken,
  });
}
