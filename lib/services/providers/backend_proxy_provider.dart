import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:waste_segregation_app/models/waste_classification.dart'
    show WasteClassification;

import '../ai_failure.dart';
import 'ai_provider_response.dart';
import 'classification_provider.dart';

/// Thin callable-function client for the backend classification gateway.
///
/// Responsibilities (only):
/// - Encode [imageBytes] as base64 and attach a client-side hash hint.
/// - Call the `classifyImage` Firebase HTTPS Callable function.
/// - Return a raw [AiProviderResponse] whose [rawResponseMap] is the
///   `classification` sub-object returned by the function, so that
///   [AiService]'s existing parser (`_processAiResponseData`) can parse it
///   into a [WasteClassification] without modification.
/// - Map Firebase function errors to [AiFailure].
///
/// Does NOT build classification prompts, parse [WasteClassification],
/// apply local guidelines, cache, record spending, decide fallback, or
/// compress images — all of those remain in [AiService].
///
/// ## Safety note
///
/// This provider does NOT call [ProductionSafetyConfig.guardClientAiCall]
/// because it routes through the secure backend rather than calling an AI
/// provider directly from the client. The backend enforces App Check,
/// auth, and rate limits.
///
/// ## Usage
///
/// Enable via `--dart-define=USE_BACKEND_AI_IN_RELEASE=true` at build time
/// (canonical flag — same as [ProductionSafetyConfig.useBackendAiInRelease]).
/// [AiService] checks [BackendProxyProvider.isEnabled] and, when true,
/// uses this provider as the primary route before OpenAI/Gemini.
class BackendProxyProvider implements ClassificationProvider {
  BackendProxyProvider({
    required FirebaseFunctions functions,
    String functionName = 'classifyImage',
    String? region,
    Duration timeout = const Duration(seconds: 30),
  })  : _functionName = functionName,
        _region = region,
        _timeout = timeout,
        _functions = functions;

  final FirebaseFunctions _functions;
  final String _functionName;
  final String? _region;
  final Duration _timeout;

  // ---------------------------------------------------------------------------
  // ClassificationProvider interface
  // ---------------------------------------------------------------------------

  @override
  String get providerName => 'backend';

  @override
  String get modelName => _functionName;

  /// Cost is null because all cost tracking is handled server-side in
  /// `ai_cost_events` Firestore collection. The client never sees token counts.
  @override
  double? get estimatedCostPerCall => null;

  // ---------------------------------------------------------------------------

  /// Whether the backend proxy should be used in the current build.
  ///
  /// Canonical dart-define: `--dart-define=USE_BACKEND_AI_IN_RELEASE=true`
  ///
  /// This reads the same flag as [ProductionSafetyConfig.useBackendAiInRelease]
  /// so there is exactly ONE build flag that controls backend routing.
  /// Do not add a separate backend-routing define — use the canonical flag
  /// above.
  static const bool isEnabled =
      bool.fromEnvironment('USE_BACKEND_AI_IN_RELEASE');

  /// Sends a classifyImage request to the backend callable function.
  ///
  /// [imageBytes] should already be compressed — this client does not
  /// perform any compression.
  ///
  /// [clientHash] is an optional deduplication hint computed by the caller
  /// (e.g. via [ImageUtils.generateDualHashes]). The server never trusts it
  /// as a cache key — it computes its own SHA-256 — but it can use it as a
  /// hint to skip re-hashing identical payloads it has already seen.
  ///
  /// [region] and [lang] are forwarded to the server to generate context-
  /// aware prompts and cache keys.
  ///
  /// [requestId] is an optional idempotency key for retry-safe calls.
  /// Not part of the [ClassificationProvider] interface — additional param.
  @override
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    // Prompt is unused here — the backend builds its own prompt.
    // The parameter is retained so this class can be swapped in wherever
    // GeminiProviderClient or OpenAiProviderClient is used, but callers
    // may pass an empty string.
    String prompt = '',
    String? clientHash,
    String? region,
    String? lang,
    String? requestId,
    CancelToken?
        cancelToken, // accepted for interface parity; not enforceable on callable
  }) async {
    final base64Image = base64Encode(imageBytes);

    final callable = _buildCallable();

    late final HttpsCallableResult<dynamic> callResult;
    try {
      callResult = await callable.call<dynamic>({
        'imageBase64': base64Image,
        'mimeType': mimeType,
        if (clientHash != null) 'clientHash': clientHash,
        if (region != null && region.isNotEmpty) 'region': region,
        if (lang != null && lang.isNotEmpty) 'lang': lang,
        if (requestId != null && requestId.isNotEmpty) 'requestId': requestId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e);
    } catch (e) {
      throw AiFailure(
        AiFailureKind.network,
        'BackendProxy unexpected error: $e',
        provider: 'backend',
        model: _functionName,
        cause: e,
      );
    }

    // The function returns:
    //   { classification: { ...WasteClassification fields... }, meta: { ... } }
    final data = callResult.data as Map<Object?, Object?>?;
    if (data == null) {
      throw AiFailure(
        AiFailureKind.malformedProviderResponse,
        'Backend function returned null data.',
        provider: 'backend',
        model: _functionName,
      );
    }

    // Normalise keys to String (Firebase sometimes returns Map<Object?,Object?>).
    final Map<String, dynamic> responseMap =
        _normaliseMap(data.cast<Object?, Object?>());

    final classificationRaw = responseMap['classification'];
    if (classificationRaw == null) {
      throw AiFailure(
        AiFailureKind.malformedProviderResponse,
        'Backend response missing "classification" field.',
        provider: 'backend',
        model: _functionName,
      );
    }

    final classificationMap =
        _normaliseMap((classificationRaw as Map<Object?, Object?>));

    // meta is optional — used for logging / debugging
    final meta = responseMap['meta'] != null
        ? _normaliseMap((responseMap['meta'] as Map<Object?, Object?>))
        : <String, dynamic>{};

    final usedProvider = meta['provider'] as String? ?? 'backend';
    final usedModel = meta['model'] as String? ?? _functionName;

    // AiService's _processAiResponseData expects either:
    //   - OpenAI shape: { choices: [{ message: { content: "<json>" } }] }
    //   - Gemini shape: handled via textContent
    //   - Or: a raw map that is itself the classification JSON (for backend)
    //
    // We return the classificationMap directly as rawResponseMap and also
    // set textContent to the JSON-encoded string of that map. This means:
    //   - If AiService checks textContent first (as it does for Gemini), it
    //     will parse the JSON string correctly.
    //   - If it falls back to rawResponseMap, the map itself is already the
    //     classification object and fromJson() will work directly.
    final textContent = jsonEncode(classificationMap);

    return AiProviderResponse(
      provider: usedProvider,
      model: usedModel,
      rawResponseMap: classificationMap,
      textContent: textContent,
      // Token counts are not surfaced to the client from the backend;
      // cost tracking is handled server-side in ai_cost_events.
      inputTokens: null,
      outputTokens: null,
    );
  }

  HttpsCallable _buildCallable() {
    final region = _region;
    final instance = region != null
        ? FirebaseFunctions.instanceFor(region: region)
        : _functions;
    return instance.httpsCallable(
      _functionName,
      options: HttpsCallableOptions(timeout: _timeout),
    );
  }

  AiFailure _mapFunctionsException(FirebaseFunctionsException e) {
    final code = e.code;
    // Firebase Functions error codes are hyphenated strings (e.g. "unauthenticated")
    switch (code) {
      case 'unauthenticated':
        return AiFailure(
          AiFailureKind.auth,
          'Backend: authentication required. Please sign in and retry.',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      case 'permission-denied':
      case 'failed-precondition':
        return AiFailure(
          AiFailureKind.auth,
          'Backend: App Check or permission failure — ${e.message}',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      case 'resource-exhausted':
        return AiFailure(
          AiFailureKind.rateLimited,
          'Backend rate limit exceeded. ${e.message}',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      case 'invalid-argument':
        return AiFailure(
          AiFailureKind.invalidImage,
          'Backend rejected request: ${e.message}',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      case 'unavailable':
        return AiFailure(
          AiFailureKind.providerUnavailable,
          'Backend classification service unavailable. ${e.message}',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      case 'deadline-exceeded':
        return AiFailure(
          AiFailureKind.network,
          'Backend request timed out after ${_timeout.inSeconds}s.',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
      default:
        return AiFailure(
          AiFailureKind.unknown,
          'Backend error [$code]: ${e.message}',
          provider: 'backend',
          model: _functionName,
          cause: e,
        );
    }
  }

  /// Recursively converts a [Map<Object?, Object?>] (as Firebase Callable
  /// sometimes returns) to a [Map<String, dynamic>] safe for Dart consumers.
  static Map<String, dynamic> _normaliseMap(Map<Object?, Object?> raw) {
    return raw.map((k, v) {
      final key = k?.toString() ?? '';
      dynamic value = v;
      if (v is Map<Object?, Object?>) {
        value = _normaliseMap(v);
      } else if (v is List) {
        value = _normaliseList(v);
      }
      return MapEntry(key, value);
    });
  }

  static List<dynamic> _normaliseList(List<dynamic> raw) {
    return raw.map((item) {
      if (item is Map<Object?, Object?>) {
        return _normaliseMap(item);
      } else if (item is List) {
        return _normaliseList(item);
      }
      return item;
    }).toList();
  }
}
