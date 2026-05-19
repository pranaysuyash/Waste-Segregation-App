import 'package:flutter/foundation.dart';
import 'waste_app_logger.dart';
import 'constants.dart';

class ProductionSafetyConfig {
  ProductionSafetyConfig._();

  /// When true, client-side AI calls (OpenAI/Gemini direct HTTP) are allowed
  /// in release builds.  Defaults to false — release builds MUST NOT call AI
  /// providers directly unless explicitly opted in for private/internal testing.
  ///
  /// Usage (private testing only):
  ///   --dart-define=ALLOW_CLIENT_AI_IN_RELEASE=true
  static const bool _allowClientAiInRelease =
      bool.fromEnvironment('ALLOW_CLIENT_AI_IN_RELEASE');

  /// Whether client-side AI is permitted in the current build mode.
  /// - debug / profile: always allowed (unchanged behaviour)
  /// - release:          allowed only when ALLOW_CLIENT_AI_IN_RELEASE=true
  static bool get isClientAiAllowed {
    if (!kReleaseMode) return true;
    return _allowClientAiInRelease;
  }

  /// When true, the app will attempt to use a backend classification endpoint
  /// in release builds.  The backend adapter is not yet implemented; this flag
  /// exists for forward compatibility.
  static const bool useBackendAiInRelease =
      bool.fromEnvironment('USE_BACKEND_AI_IN_RELEASE');

  /// Detects placeholder / example API key values so they don't accidentally
  /// get sent to a real provider endpoint.
  static bool hasPlaceholderKey(String key) {
    if (key.isEmpty) return true;
    final lowered = key.toLowerCase();
    return lowered == 'your-openai-api-key-here' ||
        lowered == 'your-gemini-api-key-here' ||
        lowered == 'your-api-key-here' ||
        lowered.startsWith('your-');
  }

  /// Logs a safety notice about a key's configuration status.
  static void logKeyConfigStatus(String label, String key) {
    final configured =
        key.isNotEmpty && !hasPlaceholderKey(key);
    WasteAppLogger.info(
      '[PRODUCTION_SAFETY] $label configured: $configured | '
      '${kReleaseMode ? "BLOCKED in release build" : "active in debug build"}',
    );
  }

  /// Guard that must be called before any client-side AI request.
  /// Throws a [ProductionSafetyException] if the request is not allowed.
  static void guardClientAiCall(String providerLabel) {
    if (isClientAiAllowed) return;

    const openAiKey = ApiConfig.openAiApiKey;
    const geminiKey = ApiConfig.apiKey;

    logKeyConfigStatus('OPENAI_API_KEY', openAiKey);
    logKeyConfigStatus('GEMINI_API_KEY', geminiKey);

    throw const ProductionSafetyException(
      'Client-side AI call blocked in release build.',
    );
  }
}

class ProductionSafetyException implements Exception {
  const ProductionSafetyException(this.message);
  final String message;

  @override
  String toString() => 'ProductionSafetyException: $message';
}
