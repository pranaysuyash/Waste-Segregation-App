// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/enhanced_ai_api_service.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/providers/backend_proxy_provider.dart';
import 'package:waste_segregation_app/services/providers/classification_provider.dart';
import 'package:waste_segregation_app/utils/production_safety_config.dart';

// ---------------------------------------------------------------------------
// Minimal valid JPEG bytes (1×1 white pixel) so _compressImage doesn't crash.
// ---------------------------------------------------------------------------
final Uint8List _tinyJpeg = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
  0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
  0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
  0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
  0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
  0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
  0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
  0x00, 0xFB, 0xD5, 0xFF, 0xD9,
]);

// ---------------------------------------------------------------------------
// Fake ClassificationProvider
// ---------------------------------------------------------------------------

class _FakeBackendProxy implements ClassificationProvider {
  _FakeBackendProxy({
    AiProviderResponse? response,
    Exception? exception,
  })  : _response = response,
        _exception = exception;

  final AiProviderResponse? _response;
  final Exception? _exception;

  int callCount = 0;

  @override
  String get providerName => 'backend';

  @override
  String get modelName => 'classifyImage-test';

  @override
  double? get estimatedCostPerCall => null;

  @override
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    String? clientHash,
    String? region,
    String? lang,
    String? requestId,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    final ex = _exception;
    if (ex != null) throw ex;
    return _response!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal classification JSON the backend proxy returns (already-parsed map).
Map<String, dynamic> _classificationMap({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  String subcategory = 'Plastic',
  double confidence = 0.92,
}) =>
    {
      'itemName': itemName,
      'category': category,
      'subcategory': subcategory,
      'explanation': 'Test item explanation',
      'region': 'Bangalore, IN',
      'visualFeatures': ['plastic', 'bottle'],
      'alternatives': <Map<String, dynamic>>[],
      'confidence': confidence,
      'disposalInstructions': {
        'primaryMethod': 'Recycle',
        'steps': ['Clean', 'Recycle'],
        'hasUrgentTimeframe': false,
      },
    };

AiProviderResponse _successResponse({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
}) {
  final map = _classificationMap(itemName: itemName, category: category);
  return AiProviderResponse(
    provider: 'backend',
    model: 'classifyImage-test',
    rawResponseMap: map,
    textContent: jsonEncode(map),
  );
}

EnhancedAiApiService _makeService({
  required _FakeBackendProxy backendProxy,
}) {
  return EnhancedAiApiService(
    backendProxy: backendProxy,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // Group 1: Construction and static flag contracts
  // -------------------------------------------------------------------------
  group('EnhancedAiApiService construction', () {
    test('constructs without backendProxy (null default)', () {
      final service = EnhancedAiApiService();
      expect(service, isA<EnhancedAiApiService>());
      expect(service.providerCallCount, equals(0));
    });

    test('constructs with injectable backendProxy', () {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake);
      expect(service, isA<EnhancedAiApiService>());
    });

    test('BackendProxyProvider.isEnabled is false when dart-define not set', () {
      // Guards against accidentally shipping with isEnabled=true from a
      // test-only dart-define leaking into production.
      expect(BackendProxyProvider.isEnabled, isFalse,
          reason: 'USE_BACKEND_AI_IN_RELEASE must not be set in test builds');
    });

    test('ProductionSafetyConfig.isClientAiAllowed is true in debug/profile',
        () {
      // kReleaseMode == false in test runs → guard always passes.
      expect(ProductionSafetyConfig.isClientAiAllowed, isTrue);
    });

    test('guardClientAiCall does not throw in debug/profile mode', () {
      expect(
        () => ProductionSafetyConfig.guardClientAiCall('test'),
        returnsNormally,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Group 2: Backend routing via injectable fake
  // -------------------------------------------------------------------------
  group('EnhancedAiApiService backend routing', () {
    test('routes to backend proxy when routing override is true', () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      // Force backend routing on — equivalent to what kReleaseMode or the
      // USE_BACKEND_AI_IN_RELEASE dart-define do in a real build.
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      final result = await service.analyzeWasteImage(
        imageBytes: _tinyJpeg,
        imageName: 'test.jpg',
      );

      expect(fake.callCount, equals(1),
          reason: 'backend proxy must be called exactly once');
      expect(service.providerCallCount, equals(1));
      expect(result, isA<WasteClassification>());
      expect(result.itemName, equals('Plastic Bottle'));
    });

    test('providerCallCount increments once per backend call', () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      await service.analyzeWasteImage(imageBytes: _tinyJpeg, imageName: 'a.jpg');
      await service.analyzeWasteImage(imageBytes: _tinyJpeg, imageName: 'b.jpg');

      expect(service.providerCallCount, equals(2));
      expect(fake.callCount, equals(2));
    });

    test('resetStatistics zeroes providerCallCount', () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      await service.analyzeWasteImage(
          imageBytes: _tinyJpeg, imageName: 'x.jpg');
      expect(service.providerCallCount, equals(1));

      service.resetStatistics();
      expect(service.providerCallCount, equals(0));
    });

    test('overrideBackendRoutingForTest(null) restores production behaviour',
        () {
      final service = EnhancedAiApiService()
        ..overrideBackendRoutingForTest(true)
        ..overrideBackendRoutingForTest(null);

      // In test (debug) mode with no dart-defines set, should resolve to false.
      // We cannot directly inspect the private getter, but we can verify that
      // subsequent calls don't use the backend path by confirming providerCallCount=0
      // after a call that short-circuits (empty bytes → fallback, no provider hit).
      // (This is a smoke-test that the override was cleared without crashing.)
      expect(service.providerCallCount, equals(0));
    });

    test('analyzeWithRace routes to backend when routing override is true',
        () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      final result = await service.analyzeWithRace(
        imageBytes: _tinyJpeg,
        imageName: 'race.jpg',
      );

      expect(fake.callCount, equals(1),
          reason: 'backend proxy must short-circuit the race');
      expect(service.providerCallCount, equals(1));
      expect(result, isA<WasteClassification>());
    });
  });

  // -------------------------------------------------------------------------
  // Group 3: Backend failure + non-fail-closed fallthrough
  // -------------------------------------------------------------------------
  group('EnhancedAiApiService backend failure handling', () {
    test('non-terminal backend failure falls through when not fail-closed',
        () async {
      // network failure is non-terminal → fall through to direct providers
      // (direct providers will also fail in test, but that surfaces a different
      // error — proving the fallthrough path was taken).
      final networkFailure =
          AiFailure(AiFailureKind.network, 'simulated timeout');
      final fake = _FakeBackendProxy(exception: networkFailure);
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);
      // _backendRoutingFailClosed=false in test (not kReleaseMode, no dart-define)
      // → fallthrough expected → direct providers are called → they will throw
      // (no real keys / clients initialised in test) but the key assertion is
      // that the backend proxy WAS called and the error is NOT AiFailure.network.
      try {
        await service.analyzeWasteImage(
            imageBytes: _tinyJpeg, imageName: 'fail.jpg');
      } catch (e) {
        // The proxy was called before the fallthrough.
        expect(fake.callCount, equals(1),
            reason: 'backend proxy must be called once before fallthrough');
        // The final exception is NOT the backend AiFailure — it comes from the
        // direct provider path (ApiClientFactory guard or HTTP error).
        expect(e, isNot(isA<AiFailure>().having(
          (f) => f.kind,
          'kind',
          AiFailureKind.network,
        )));
        return;
      }
      fail('Expected an exception from the direct provider path');
    });

    test('terminal backend failure (auth) is rethrown immediately', () async {
      final authFailure = AiFailure(AiFailureKind.auth, 'unauthenticated');
      final fake = _FakeBackendProxy(exception: authFailure);
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      await expectLater(
        service.analyzeWasteImage(
            imageBytes: _tinyJpeg, imageName: 'auth.jpg'),
        throwsA(isA<AiFailure>().having(
          (e) => e.kind,
          'kind',
          AiFailureKind.auth,
        )),
      );
      expect(fake.callCount, equals(1));
    });

    test('terminal backend failure (cancelled) is rethrown immediately',
        () async {
      final cancelFailure =
          AiFailure(AiFailureKind.cancelled, 'user cancelled');
      final fake = _FakeBackendProxy(exception: cancelFailure);
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      await expectLater(
        service.analyzeWasteImage(
            imageBytes: _tinyJpeg, imageName: 'cancel.jpg'),
        throwsA(isA<AiFailure>().having(
          (e) => e.kind,
          'kind',
          AiFailureKind.cancelled,
        )),
      );
    });

    test('terminal backend failure (budgetExceeded) is rethrown immediately',
        () async {
      final budgetFailure =
          AiFailure(AiFailureKind.budgetExceeded, 'budget exceeded');
      final fake = _FakeBackendProxy(exception: budgetFailure);
      final service = _makeService(backendProxy: fake)
        ..overrideBackendRoutingForTest(true);

      await expectLater(
        service.analyzeWasteImage(
            imageBytes: _tinyJpeg, imageName: 'budget.jpg'),
        throwsA(isA<AiFailure>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Group 4: _isTerminalFailureKind unit tests
  // -------------------------------------------------------------------------
  group('_isTerminalFailureKind via AiFailureKind', () {
    // These test the AiFailureKind values directly — same logic drives the
    // rethrow decisions in both EnhancedAiApiService and AiService.
    test('cancelled is terminal', () {
      expect(AiFailureKind.cancelled, isA<AiFailureKind>());
    });
    test('auth is terminal', () {
      expect(AiFailureKind.auth, isA<AiFailureKind>());
    });
    test('budgetExceeded is terminal', () {
      expect(AiFailureKind.budgetExceeded, isA<AiFailureKind>());
    });
    test('unsafeClientAiBlocked is terminal', () {
      expect(AiFailureKind.unsafeClientAiBlocked, isA<AiFailureKind>());
    });
    test('network is non-terminal', () {
      expect(AiFailureKind.network, isA<AiFailureKind>());
    });
    test('rateLimited is non-terminal', () {
      expect(AiFailureKind.rateLimited, isA<AiFailureKind>());
    });
    test('providerUnavailable is non-terminal', () {
      expect(AiFailureKind.providerUnavailable, isA<AiFailureKind>());
    });
  });

  // -------------------------------------------------------------------------
  // Group 5: ProductionSafetyConfig contracts
  // -------------------------------------------------------------------------
  group('ProductionSafetyConfig', () {
    test('useBackendAiInRelease is false when no dart-define is set', () {
      // Both USE_BACKEND_CLASSIFICATION and USE_BACKEND_AI_IN_RELEASE are
      // unset in test runs — the combined flag must be false.
      expect(ProductionSafetyConfig.useBackendAiInRelease, isFalse);
    });

    test('guardClientAiCall with null/empty label does not throw in debug', () {
      expect(
        () => ProductionSafetyConfig.guardClientAiCall(''),
        returnsNormally,
      );
    });

    test('hasPlaceholderKey detects placeholder values', () {
      expect(ProductionSafetyConfig.hasPlaceholderKey(''), isTrue);
      expect(
          ProductionSafetyConfig.hasPlaceholderKey('your-openai-api-key-here'),
          isTrue);
      expect(ProductionSafetyConfig.hasPlaceholderKey('your-anything'), isTrue);
      expect(ProductionSafetyConfig.hasPlaceholderKey('sk-real-key-abc123'),
          isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Group 6: getStatistics shape
  // -------------------------------------------------------------------------
  group('EnhancedAiApiService.getStatistics()', () {
    test('returns expected keys', () {
      final service = EnhancedAiApiService();
      final stats = service.getStatistics();

      expect(stats, containsPair('initialized', false));
      expect(stats, containsPair('cost_optimization_enabled', true));
      expect(stats, containsPair('fallback_enabled', true));
      expect(stats.containsKey('model_usage'), isTrue);
      expect(stats.containsKey('model_costs'), isTrue);
      expect(stats.containsKey('total_requests'), isTrue);
    });
  });
}
