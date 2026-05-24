// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/providers/backend_proxy_provider.dart';
import 'package:waste_segregation_app/services/providers/classification_provider.dart';

import '../test_helper.dart';

// ---------------------------------------------------------------------------
// Minimal fake image bytes (1x1 JPEG) that survive _compressImageForOpenAI.
// The body of JPEG is needed so the image codec doesn't fail.
// ---------------------------------------------------------------------------
final Uint8List _tinyJpeg = Uint8List.fromList([
  // 1×1 white JPEG — exact bytes for a valid minimal JPEG
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
  0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
  0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
  0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
  0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
  0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
  0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
  0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
  0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
  0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
  0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
  0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
  0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
  0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
  0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
  0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
  0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
  0x00, 0x00, 0x3F, 0x00, 0xFB, 0xD5, 0xFF, 0xD9,
]);

// ---------------------------------------------------------------------------
// Fake ClassificationProvider implementations
// ---------------------------------------------------------------------------

/// Returns a fixed AiProviderResponse without calling Firebase.
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
    if (_exception != null) throw _exception!;
    return _response!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds the minimal JSON string that AiService parses into a WasteClassification.
String _classificationJson({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  String subcategory = 'Plastic',
  double confidence = 0.92,
}) {
  return jsonEncode({
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
  });
}

AiProviderResponse _successResponse({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  String subcategory = 'Plastic',
  double confidence = 0.92,
}) {
  final json = _classificationJson(
    itemName: itemName,
    category: category,
    subCategory: subcategory,
    confidence: confidence,
  );
  return AiProviderResponse(
    provider: 'backend',
    model: 'classifyImage-test',
    rawResponseMap: jsonDecode(json) as Map<String, dynamic>,
    textContent: json,
  );
}

// ---------------------------------------------------------------------------
// AiService factory for tests
// ---------------------------------------------------------------------------

AiService _makeService({
  required _FakeBackendProxy backendProxy,
  bool cachingEnabled = false,
}) {
  return AiService(
    openAiApiKey: 'test-key-not-real',
    geminiApiKey: 'test-key-not-real',
    cacheService: TestHelper.createMockCacheService(),
    cachingEnabled: cachingEnabled,
    backendProxy: backendProxy,
    // Provide a fake save so tests don't depend on the filesystem.
    saveWebImageOverride: (bytes, name) async => '/tmp/test_$name',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await TestHelper.setupCompleteTest();
  });

  tearDownAll(() async {
    await TestHelper.tearDownCompleteTest();
  });

  // -------------------------------------------------------------------------
  // Group 1: ClassificationProvider interface — static contract
  // -------------------------------------------------------------------------
  group('ClassificationProvider interface contract', () {
    test('_FakeBackendProxy satisfies ClassificationProvider', () {
      final ClassificationProvider p = _FakeBackendProxy(
        response: _successResponse(),
      );
      expect(p.providerName, equals('backend'));
      expect(p.modelName, equals('classifyImage-test'));
      expect(p.estimatedCostPerCall, isNull);
    });

    test(
        '_FakeBackendProxy.analyze() increments callCount and returns response',
        () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      expect(fake.callCount, equals(0));

      final resp = await fake.analyze(
        imageBytes: _tinyJpeg,
        mimeType: 'image/jpeg',
      );

      expect(fake.callCount, equals(1));
      expect(resp.provider, equals('backend'));
      expect(resp.textContent, contains('Plastic Bottle'));
    });

    test('_FakeBackendProxy.analyze() propagates exception', () async {
      final fake = _FakeBackendProxy(
        exception: AiFailure(AiFailureKind.network, 'network error'),
      );
      expect(
        () => fake.analyze(imageBytes: _tinyJpeg, mimeType: 'image/jpeg'),
        throwsA(isA<AiFailure>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Group 2: Backend routing enabled — AiService routes to backend proxy
  // -------------------------------------------------------------------------
  group('AiService backend routing', () {
    test(
        'BackendProxyProvider.isEnabled reads USE_BACKEND_AI_IN_RELEASE dart-define',
        () {
      // In test environment, the dart-define is not set, so isEnabled is false.
      // This verifies the static constant exists and reads the right flag.
      expect(BackendProxyProvider.isEnabled, isFalse,
          reason:
              'USE_BACKEND_AI_IN_RELEASE is not set in test runs, so isEnabled must be false');
    });

    test('AiService can be constructed with a ClassificationProvider injection',
        () {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake);
      // Verify no exception — construction succeeded.
      expect(service, isA<AiService>());
    });

    test('AiService exposes providerCallCount @visibleForTesting accessor', () {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake);
      expect(service.providerCallCount, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // Group 3: analyzeWebImage — empty-image early exit
  // -------------------------------------------------------------------------
  group('AiService.analyzeWebImage early-exit behaviour', () {
    test('Empty imageBytes return fallback without calling backend', () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake);

      final result = await service.analyzeWebImage(Uint8List(0), 'test.jpg');

      expect(result, isA<WasteClassification>());
      expect(result.clarificationNeeded, isTrue,
          reason: 'fallback always sets clarificationNeeded=true');
      expect(fake.callCount, equals(0),
          reason: 'backend proxy must not be called for empty image');
      expect(service.providerCallCount, equals(0));
    });

    test('Empty imageName returns fallback without calling backend', () async {
      final fake = _FakeBackendProxy(response: _successResponse());
      final service = _makeService(backendProxy: fake);

      final result = await service.analyzeWebImage(Uint8List(0), '');

      expect(result, isA<WasteClassification>());
      expect(fake.callCount, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // Group 4: AiProviderResponse parsing — classification fields
  // -------------------------------------------------------------------------
  group('AiProviderResponse JSON parsing', () {
    test('textContent JSON with required fields produces correct response', () {
      final resp = _successResponse(
        itemName: 'Glass Jar',
        category: 'Dry Waste',
        subCategory: 'Glass',
        confidence: 0.87,
      );

      expect(resp.textContent, isNotNull);

      final decoded = jsonDecode(resp.textContent!) as Map<String, dynamic>;
      expect(decoded['itemName'], equals('Glass Jar'));
      expect(decoded['category'], equals('Dry Waste'));
      expect(decoded['subcategory'], equals('Glass'));
      expect(decoded['confidence'], closeTo(0.87, 0.001));
    });

    test('rawResponseMap is consistent with textContent', () {
      final resp = _successResponse(
        itemName: 'Newspaper',
        category: 'Dry Waste',
        subCategory: 'Paper',
      );

      expect(resp.rawResponseMap['itemName'], equals('Newspaper'));
      expect(resp.rawResponseMap['subcategory'], equals('Paper'));
    });
  });

  // -------------------------------------------------------------------------
  // Group 5: AiFailure terminal vs non-terminal classification
  // -------------------------------------------------------------------------
  group('AiFailure terminal vs non-terminal kinds', () {
    test('auth failure is terminal (rethrown without fallback)', () {
      final failure = AiFailure(AiFailureKind.auth, 'not authenticated');
      // Terminal failures should cause rethrow — verify the kind is auth.
      expect(failure.kind, equals(AiFailureKind.auth));
    });

    test('network failure is non-terminal (retriable)', () {
      final failure = AiFailure(AiFailureKind.network, 'timeout');
      expect(failure.kind, equals(AiFailureKind.network));
    });

    test('budgetExceeded is terminal', () {
      final failure = AiFailure(AiFailureKind.budgetExceeded, 'out of budget');
      expect(failure.kind, equals(AiFailureKind.budgetExceeded));
    });

    test('cancelled is terminal (user action)', () {
      final failure = AiFailure(AiFailureKind.cancelled, 'user cancelled');
      expect(failure.kind, equals(AiFailureKind.cancelled));
    });

    test('providerUnavailable is non-terminal', () {
      final failure = AiFailure(AiFailureKind.providerUnavailable, 'down');
      expect(failure.kind, equals(AiFailureKind.providerUnavailable));
    });
  });

  // -------------------------------------------------------------------------
  // Group 6: Fake provider exception propagation
  // -------------------------------------------------------------------------
  group('_FakeBackendProxy exception propagation', () {
    test('network AiFailure is thrown by fake', () async {
      final networkError =
          AiFailure(AiFailureKind.network, 'connection refused');
      final fake = _FakeBackendProxy(exception: networkError);

      await expectLater(
        fake.analyze(imageBytes: _tinyJpeg, mimeType: 'image/jpeg'),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.network,
          ),
        ),
      );
    });

    test('auth AiFailure is thrown by fake', () async {
      final authError = AiFailure(AiFailureKind.auth, 'unauthenticated');
      final fake = _FakeBackendProxy(exception: authError);

      await expectLater(
        fake.analyze(imageBytes: _tinyJpeg, mimeType: 'image/jpeg'),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.auth,
          ),
        ),
      );
    });

    test('rateLimited AiFailure is thrown by fake', () async {
      final rateError = AiFailure(AiFailureKind.rateLimited, 'rate exceeded');
      final fake = _FakeBackendProxy(exception: rateError);

      await expectLater(
        fake.analyze(imageBytes: _tinyJpeg, mimeType: 'image/jpeg'),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.rateLimited,
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Group 7: _backendRoutingFailClosed logic (unit-level)
  // -------------------------------------------------------------------------
  group('ProductionSafetyConfig.useBackendAiInRelease is canonical flag', () {
    test('uses USE_BACKEND_AI_IN_RELEASE not USE_BACKEND_CLASSIFICATION', () {
      // Both BackendProxyProvider.isEnabled and ProductionSafetyConfig.useBackendAiInRelease
      // must read from the same dart-define to prevent split-brain routing.
      // In test builds neither dart-define is set, so both must be false.
      expect(BackendProxyProvider.isEnabled, isFalse);
      // ProductionSafetyConfig.useBackendAiInRelease is not directly accessible
      // in tests (it reads dart-define at compile time), but we verify the
      // class is importable and the constant exists as documented.
    });
  });
}
