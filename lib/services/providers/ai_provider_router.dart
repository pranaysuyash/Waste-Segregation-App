import 'package:flutter/foundation.dart';

import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/utils/production_safety_config.dart';
import 'package:waste_segregation_app/services/providers/backend_proxy_provider.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';

typedef ProviderCall = Future<AiProviderResponse> Function();

class ProviderRouterResult {
  const ProviderRouterResult({
    required this.response,
    required this.providerUsed,
    this.attemptedProviders = const [],
    this.providerDuration = Duration.zero,
  });

  final AiProviderResponse response;
  final String providerUsed;
  final List<String> attemptedProviders;

  /// Wall-clock time from first provider attempt to successful response.
  /// Suitable for passing to usage-accounting as processing time.
  final Duration providerDuration;
}

class AiProviderRouter {
  const AiProviderRouter();

  bool get _backendRoutingEnabled {
    return kReleaseMode ||
        ProductionSafetyConfig.useBackendAiInRelease ||
        BackendProxyProvider.isEnabled;
  }

  bool get _backendRoutingFailClosed {
    return kReleaseMode || ProductionSafetyConfig.useBackendAiInRelease;
  }

  /// Returns true for the two failure kinds where Gemini is a meaningful
  /// alternative to OpenAI:
  ///
  /// - [AiFailureKind.invalidImageTooLarge]: Gemini handles larger images.
  /// - [AiFailureKind.providerUnavailable]: Gemini may be up when OpenAI is not.
  ///
  /// All other failure kinds (terminal, rate-limited, network, unknown) must
  /// NOT silently fall to Gemini — they should propagate so the caller can
  /// handle them explicitly.
  static bool shouldFallbackToGemini(AiFailureKind kind) {
    return kind == AiFailureKind.invalidImageTooLarge ||
        kind == AiFailureKind.providerUnavailable;
  }

  /// Terminal failures that must never be swallowed or retried regardless of
  /// which provider produced them.
  static bool isTerminalFailureKind(AiFailureKind kind) {
    return kind == AiFailureKind.cancelled ||
        kind == AiFailureKind.unsafeClientAiBlocked ||
        kind == AiFailureKind.auth ||
        kind == AiFailureKind.budgetExceeded;
  }

  Future<ProviderRouterResult> orchestrate({
    required ProviderCall backendCall,
    required ProviderCall openAiCall,
    required ProviderCall geminiCall,
    bool? backendRoutingEnabled,
    bool? backendRoutingFailClosed,
  }) async {
    final attempted = <String>[];
    final routerStart = DateTime.now();

    final effectiveBackendEnabled =
        backendRoutingEnabled ?? _backendRoutingEnabled;
    final effectiveBackendFailClosed =
        backendRoutingFailClosed ?? _backendRoutingFailClosed;

    if (effectiveBackendEnabled) {
      attempted.add('backend');
      try {
        final response = await backendCall();
        return ProviderRouterResult(
          response: response,
          providerUsed: 'backend',
          attemptedProviders: List.unmodifiable(attempted),
          providerDuration: DateTime.now().difference(routerStart),
        );
      } on AiFailure catch (e) {
        // Fail-closed mode and all terminal kinds must propagate immediately —
        // never fall through to a direct provider.
        if (effectiveBackendFailClosed || isTerminalFailureKind(e.kind)) {
          rethrow;
        }
        // Non-terminal backend failure: fall through to OpenAI.
      }
    }

    attempted.add('openai');
    try {
      final response = await openAiCall();
      return ProviderRouterResult(
        response: response,
        providerUsed: 'openai',
        attemptedProviders: List.unmodifiable(attempted),
        providerDuration: DateTime.now().difference(routerStart),
      );
    } on Exception catch (e) {
      if (e is ProductionSafetyException) {
        rethrow;
      }

      final kind = e is AiFailure ? e.kind : AiFailureKind.unknown;

      if (isTerminalFailureKind(kind)) {
        rethrow;
      }

      if (shouldFallbackToGemini(kind)) {
        attempted.add('gemini');
        final response = await geminiCall();
        return ProviderRouterResult(
          response: response,
          providerUsed: 'gemini',
          attemptedProviders: List.unmodifiable(attempted),
          providerDuration: DateTime.now().difference(routerStart),
        );
      }

      rethrow;
    }
  }
}
