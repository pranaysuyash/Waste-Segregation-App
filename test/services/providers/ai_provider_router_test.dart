import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/utils/production_safety_config.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_router.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';

AiProviderResponse _response({String textContent = ''}) {
  return AiProviderResponse(
    provider: 'test',
    model: 'test-model',
    textContent: textContent,
    rawResponseMap: {
      'choices': [
        {'message': {'content': textContent}}
      ]
    },
  );
}

final _successResponse = _response(textContent: 'plastic bottle');

AiFailure _fail(AiFailureKind kind, [String msg = 'test error']) =>
    AiFailure(kind, msg);

void main() {
  late AiProviderRouter router;

  setUp(() {
    router = const AiProviderRouter();
  });

  // ── Backend routing ─────────────────────────────────────────────────────────

  group('backend routing', () {
    test('backend disabled → OpenAI used', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(textContent: 'should not appear'),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
        backendRoutingEnabled: false,
      );

      expect(result.providerUsed, 'openai');
      expect(result.attemptedProviders, equals(['openai']));
    });

    test('backend enabled → backend used on success', () async {
      final result = await router.orchestrate(
        backendCall: () async => _successResponse,
        openAiCall: () async => _response(),
        geminiCall: () async => _response(),
        backendRoutingEnabled: true,
      );

      expect(result.providerUsed, 'backend');
      expect(result.response.textContent, 'plastic bottle');
      expect(result.attemptedProviders, equals(['backend']));
    });

    test('backend terminal: auth → rethrows, no OpenAI', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => throw _fail(AiFailureKind.auth),
          openAiCall: () async => _successResponse,
          geminiCall: () async => _response(),
          backendRoutingEnabled: true,
        ),
        throwsA(isA<AiFailure>().having((e) => e.kind, 'kind', AiFailureKind.auth)),
      );
    });

    test('backend terminal: cancelled → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => throw _fail(AiFailureKind.cancelled),
          openAiCall: () async => _successResponse,
          geminiCall: () async => _response(),
          backendRoutingEnabled: true,
        ),
        throwsA(isA<AiFailure>().having((e) => e.kind, 'kind', AiFailureKind.cancelled)),
      );
    });

    test('backend terminal: budgetExceeded → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => throw _fail(AiFailureKind.budgetExceeded),
          openAiCall: () async => _successResponse,
          geminiCall: () async => _response(),
          backendRoutingEnabled: true,
        ),
        throwsA(isA<AiFailure>().having((e) => e.kind, 'kind', AiFailureKind.budgetExceeded)),
      );
    });

    test('backend terminal: unsafeClientAiBlocked → rethrows, no OpenAI', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async =>
              throw _fail(AiFailureKind.unsafeClientAiBlocked),
          openAiCall: () async => _successResponse,
          geminiCall: () async => _response(),
          backendRoutingEnabled: true,
        ),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.unsafeClientAiBlocked,
          ),
        ),
      );
    });

    test('backend fail-closed + providerUnavailable → rethrows, no OpenAI',
        () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async =>
              throw _fail(AiFailureKind.providerUnavailable),
          openAiCall: () async => _successResponse,
          geminiCall: () async => _response(),
          backendRoutingEnabled: true,
          backendRoutingFailClosed: true,
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('backend non-fail-closed + providerUnavailable → falls through to OpenAI',
        () async {
      final result = await router.orchestrate(
        backendCall: () async =>
            throw _fail(AiFailureKind.providerUnavailable, 'down'),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
        backendRoutingEnabled: true,
        backendRoutingFailClosed: false,
      );

      expect(result.providerUsed, 'openai');
      expect(result.attemptedProviders, containsAll(['backend', 'openai']));
    });
  });

  // ── OpenAI routing ──────────────────────────────────────────────────────────

  group('OpenAI routing', () {
    test('OpenAI success → returns directly, no Gemini', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async => _successResponse,
        geminiCall: () async => throw StateError('Gemini must not be called'),
      );

      expect(result.providerUsed, 'openai');
      expect(result.response.textContent, 'plastic bottle');
    });

    test('OpenAI terminal: unsafeClientAiBlocked → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw _fail(AiFailureKind.unsafeClientAiBlocked, 'blocked'),
          geminiCall: () async => _response(),
        ),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.unsafeClientAiBlocked,
          ),
        ),
      );
    });

    test('OpenAI terminal: auth → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw _fail(AiFailureKind.auth),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>().having((e) => e.kind, 'kind', AiFailureKind.auth)),
      );
    });

    test('OpenAI terminal: budgetExceeded → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw _fail(AiFailureKind.budgetExceeded),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI terminal: cancelled → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw _fail(AiFailureKind.cancelled),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI ProductionSafetyException → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw const ProductionSafetyException('blocked by safety'),
          geminiCall: () async => _response(),
        ),
        throwsA(isA<ProductionSafetyException>()),
      );
    });

    test('OpenAI rateLimited → rethrows, no Gemini fallback', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw _fail(AiFailureKind.rateLimited),
          geminiCall: () async =>
              throw StateError('Gemini must not be called'),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI network error → rethrows, no Gemini fallback', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw _fail(AiFailureKind.network),
          geminiCall: () async =>
              throw StateError('Gemini must not be called'),
        ),
        throwsA(isA<AiFailure>()),
      );
    });

    test('OpenAI unknown generic Exception → rethrows, no Gemini fallback',
        () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async => throw Exception('weird error'),
          geminiCall: () async =>
              throw StateError('Gemini must not be called'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── Gemini fallback ─────────────────────────────────────────────────────────

  group('Gemini fallback', () {
    test('OpenAI invalidImageTooLarge → Gemini used', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async =>
            throw _fail(AiFailureKind.invalidImageTooLarge, 'too large'),
        geminiCall: () async => _successResponse,
      );

      expect(result.providerUsed, 'gemini');
      expect(result.attemptedProviders, containsAll(['openai', 'gemini']));
    });

    test('OpenAI providerUnavailable → Gemini used', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async =>
            throw _fail(AiFailureKind.providerUnavailable, 'down'),
        geminiCall: () async => _successResponse,
      );

      expect(result.providerUsed, 'gemini');
      expect(result.attemptedProviders, containsAll(['openai', 'gemini']));
    });

    test('Gemini failure after fallback → rethrows', () async {
      await expectLater(
        () => router.orchestrate(
          backendCall: () async => _response(),
          openAiCall: () async =>
              throw _fail(AiFailureKind.invalidImageTooLarge),
          geminiCall: () async =>
              throw _fail(AiFailureKind.providerUnavailable, 'also down'),
        ),
        throwsA(isA<AiFailure>()),
      );
    });
  });

  // ── attemptedProviders ordering ─────────────────────────────────────────────

  group('attemptedProviders ordering', () {
    test('backend only path: [backend]', () async {
      final result = await router.orchestrate(
        backendCall: () async => _successResponse,
        openAiCall: () async => _response(),
        geminiCall: () async => _response(),
        backendRoutingEnabled: true,
      );
      expect(result.attemptedProviders, equals(['backend']));
    });

    test('backend fail → openai success path: [backend, openai]', () async {
      final result = await router.orchestrate(
        backendCall: () async =>
            throw _fail(AiFailureKind.providerUnavailable),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
        backendRoutingEnabled: true,
        backendRoutingFailClosed: false,
      );
      expect(result.attemptedProviders, equals(['backend', 'openai']));
    });

    test('openai fail → gemini success path: [openai, gemini]', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async =>
            throw _fail(AiFailureKind.invalidImageTooLarge),
        geminiCall: () async => _successResponse,
      );
      expect(result.attemptedProviders, equals(['openai', 'gemini']));
    });

    test('full fallback path: [backend, openai, gemini]', () async {
      final result = await router.orchestrate(
        backendCall: () async =>
            throw _fail(AiFailureKind.providerUnavailable),
        openAiCall: () async =>
            throw _fail(AiFailureKind.invalidImageTooLarge),
        geminiCall: () async => _successResponse,
        backendRoutingEnabled: true,
        backendRoutingFailClosed: false,
      );
      expect(result.attemptedProviders, equals(['backend', 'openai', 'gemini']));
    });
  });

  // ── providerDuration ────────────────────────────────────────────────────────

  group('providerDuration', () {
    test('duration is non-negative', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async => _successResponse,
        geminiCall: () async => _response(),
      );
      expect(result.providerDuration.isNegative, isFalse);
    });

    test('duration reflects actual wait for slow provider', () async {
      final result = await router.orchestrate(
        backendCall: () async => _response(),
        openAiCall: () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _successResponse;
        },
        geminiCall: () async => _response(),
      );
      expect(result.providerDuration.inMilliseconds, greaterThanOrEqualTo(50));
    });
  });

  // ── shouldFallbackToGemini predicate ────────────────────────────────────────

  group('shouldFallbackToGemini predicate', () {
    test('true for invalidImageTooLarge', () {
      expect(
        AiProviderRouter.shouldFallbackToGemini(AiFailureKind.invalidImageTooLarge),
        isTrue,
      );
    });

    test('true for providerUnavailable', () {
      expect(
        AiProviderRouter.shouldFallbackToGemini(AiFailureKind.providerUnavailable),
        isTrue,
      );
    });

    test('false for all other kinds', () {
      const otherKinds = [
        AiFailureKind.cancelled,
        AiFailureKind.auth,
        AiFailureKind.budgetExceeded,
        AiFailureKind.unsafeClientAiBlocked,
        AiFailureKind.rateLimited,
        AiFailureKind.network,
        AiFailureKind.unknown,
        AiFailureKind.invalidImage,
      ];
      for (final kind in otherKinds) {
        expect(
          AiProviderRouter.shouldFallbackToGemini(kind),
          isFalse,
          reason: '$kind should not fall back to Gemini',
        );
      }
    });
  });

  // ── isTerminalFailureKind predicate ─────────────────────────────────────────

  group('isTerminalFailureKind predicate', () {
    const terminalKinds = [
      AiFailureKind.cancelled,
      AiFailureKind.unsafeClientAiBlocked,
      AiFailureKind.auth,
      AiFailureKind.budgetExceeded,
    ];

    const nonTerminalKinds = [
      AiFailureKind.invalidImage,
      AiFailureKind.invalidImageTooLarge,
      AiFailureKind.rateLimited,
      AiFailureKind.providerUnavailable,
      AiFailureKind.network,
      AiFailureKind.unknown,
    ];

    for (final kind in terminalKinds) {
      test('$kind is terminal', () {
        expect(AiProviderRouter.isTerminalFailureKind(kind), isTrue);
      });
    }

    for (final kind in nonTerminalKinds) {
      test('$kind is not terminal', () {
        expect(AiProviderRouter.isTerminalFailureKind(kind), isFalse);
      });
    }
  });
}
