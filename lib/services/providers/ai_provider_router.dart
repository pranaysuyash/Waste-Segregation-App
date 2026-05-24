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
  });

  final AiProviderResponse response;
  final String providerUsed;
  final List<String> attemptedProviders;
}

class AiProviderRouter {
  AiProviderRouter({this.maxRetries = 3});

  final int maxRetries;

  bool get _backendRoutingEnabled {
    return kReleaseMode ||
        ProductionSafetyConfig.useBackendAiInRelease ||
        BackendProxyProvider.isEnabled;
  }

  bool get _backendRoutingFailClosed {
    return kReleaseMode || ProductionSafetyConfig.useBackendAiInRelease;
  }

  bool _shouldFallbackToGemini(AiFailureKind kind, int retryCount) {
    if (retryCount >= maxRetries) return true;
    return kind == AiFailureKind.invalidImageTooLarge ||
        kind == AiFailureKind.providerUnavailable;
  }

  static bool isTerminalFailureKind(AiFailureKind kind) {
    return kind == AiFailureKind.cancelled ||
        kind == AiFailureKind.unsafeClientAiBlocked ||
        kind == AiFailureKind.auth ||
        kind == AiFailureKind.budgetExceeded;
  }

  bool _isTerminalFailureKind(AiFailureKind kind) =>
      AiProviderRouter.isTerminalFailureKind(kind);

  Future<ProviderRouterResult> orchestrate({
    required ProviderCall backendCall,
    required ProviderCall openAiCall,
    required ProviderCall geminiCall,
    bool? backendRoutingEnabled,
    bool? backendRoutingFailClosed,
  }) async {
    final attempted = <String>[];

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
        );
      } on AiFailure catch (e) {
        if (effectiveBackendFailClosed ||
            e.kind == AiFailureKind.cancelled ||
            e.kind == AiFailureKind.auth ||
            e.kind == AiFailureKind.budgetExceeded) {
          rethrow;
        }
      }
    }

    attempted.add('openai');
    try {
      final response = await openAiCall();
      return ProviderRouterResult(
        response: response,
        providerUsed: 'openai',
        attemptedProviders: List.unmodifiable(attempted),
      );
    } on Exception catch (e) {
      if (e is ProductionSafetyException) {
        rethrow;
      }

      final kind = e is AiFailure ? e.kind : AiFailureKind.unknown;

      if (_isTerminalFailureKind(kind)) {
        rethrow;
      }

      if (_shouldFallbackToGemini(kind, attempted.length)) {
        attempted.add('gemini');
        try {
          final response = await geminiCall();
          return ProviderRouterResult(
            response: response,
            providerUsed: 'gemini',
            attemptedProviders: List.unmodifiable(attempted),
          );
        } on Exception catch (_) {
          rethrow;
        }
      }

      rethrow;
    }
  }
}
