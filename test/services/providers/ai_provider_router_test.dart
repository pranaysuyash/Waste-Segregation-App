import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/utils/production_safety_config.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_router.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';

AiProviderResponse _response({String content = '', String provider = 'test'}) {
  return AiProviderResponse(
    provider: provider,
    model: 'test-model',
    rawResponseMap: {
      'choices': [
        {'message': {'content': content}}
      ]
    },
    textContent: content,
  );
}

final _successResponse = _response(content: 'classify this');

void main() {
  late AiProviderRouter router;

  setUp(() {
    router = AiProviderRouter();
  });

  group('backend routing', () {
    test('backend success returns immediately', () async {
      final result = await router.orchestrate(
        backendCall: () async => _successResponse,
        openAiCall: () async => _response(),
        geminiCall: () async => _response(),
      );

      expect(result.providerUsed, 'backend');
      expect(result.response.textContent, 'classify this');
    });

    test('backend terminal failure rethrows', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async =>
              throw AiFailure(AiFailureKind.auth, 'auth error'),
          openAiCall: () async => _response(),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('backend non-terminal failure falls through to OpenAI', () async {
      final result = await router.orchestrate(
        backendCall: () async =>
            throw AiFailure(AiFailureKind.providerUnavailable, 'down'),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
      );

      expect(result.providerUsed, 'openai');
      expect(result.attemptedProviders, contains('backend'));
    });
  });

  group('OpenAI routing', () {
    test('OpenAI success returns directly', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
      );

      expect(result.providerUsed, 'openai');
      expect(result.response.textContent, 'classify this');
    });

    test('OpenAI terminal failure rethrows', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw AiFailure(AiFailureKind.unsafeClientAiBlocked, 'blocked'),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI ProductionSafetyException rethrows', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw const ProductionSafetyException('blocked by safety'),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<ProductionSafetyException>()),
      );
    });

    test('OpenAI non-AI exception falls to unknown kind and may fallback',
        () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async => throw Exception('weird error'),
        geminiCall: () async => _successResponse,
      );

      expect(result.providerUsed, 'gemini');
    });
  });

  group('Gemini fallback', () {
    test('Gemini fallback success returns Gemini result', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async =>
            throw AiFailure(AiFailureKind.invalidImageTooLarge, 'too large'),
        geminiCall: () async => _successResponse,
      );

      expect(result.providerUsed, 'gemini');
      expect(result.attemptedProviders, contains('openai'));
      expect(result.attemptedProviders, contains('gemini'));
    });

    test('Gemini fallback failure rethrows', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw AiFailure(AiFailureKind.invalidImageTooLarge, 'too large'),
          geminiCall: () async =>
              throw AiFailure(AiFailureKind.providerUnavailable, 'down'),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI rateLimited does not fallback to Gemini', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw AiFailure(AiFailureKind.rateLimited, 'rate limited'),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI network does not fallback to Gemini', () async {
      expect(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw AiFailure(AiFailureKind.network, 'network error'),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });
  });
}
