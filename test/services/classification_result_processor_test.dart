import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/classification_result_processor.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/cache_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake [LocalPolicyEngine] that returns a controlled decision without
/// depending on plugin registration.
class _FakePolicyEngine extends LocalPolicyEngine {
  _FakePolicyEngine({
    this.policyApplied = false,
    this.complianceStatus,
    this.pluginId,
    this.warnings = const [],
    this.violations = const [],
    this.recommendations = const [],
  });

  final bool policyApplied;
  final String? complianceStatus;
  final String? pluginId;
  final List<String> warnings;
  final List<String> violations;
  final List<String> recommendations;

  @override
  Future<LocalPolicyDecision> applyPolicy({
    required WasteClassification classification,
    required String region,
    String? societyId,
  }) async {
    if (!policyApplied) {
      return LocalPolicyDecision(
        classification: classification,
        policyApplied: false,
        evaluatedAt: DateTime.now(),
      );
    }

    final baseRegulations =
        Map<String, String>.from(classification.localRegulations ?? {});
    baseRegulations['policy_applied'] = 'true';

    return LocalPolicyDecision(
      classification: classification.copyWith(
        localRegulations: baseRegulations,
        bbmpComplianceStatus: complianceStatus,
        localGuidelinesVersion: 'test-v1',
      ),
      policyApplied: true,
      evaluatedAt: DateTime.now(),
      pluginId: pluginId,
      authorityName: 'Test Authority',
      guidelinesVersion: 'test-v1',
      rulePackId: 'test:test-v1',
      complianceStatus: complianceStatus ?? 'compliant',
      rulePack: null,
      violations: violations,
      warnings: warnings,
      recommendations: recommendations,
      sourceUrl: 'https://example.com/guidelines',
      helpline: '1800-TEST',
      lastVerified: '2026-01-01',
      confidenceGated: false,
    );
  }
}

/// Fake [ClassificationCacheService] that operates entirely in memory with
/// no Hive dependency.
class _FakeCacheService extends ClassificationCacheService {
  final Map<String, CachedClassification> _store = {};
  final List<String> _cacheKeys = [];

  /// Keys passed to [cacheClassification], in order.
  List<String> get cachedKeys => List.unmodifiable(_cacheKeys);

  /// Whether [initialize] was called.
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<CachedClassification?> getCachedClassification(
    String cacheKey, {
    String? contentHash,
    int similarityThreshold = 6,
  }) async {
    return _store[cacheKey];
  }

  @override
  Future<void> cacheClassification(
    String cacheKey,
    WasteClassification classification, {
    String? contentHash,
    int? imageSize,
    String? entryImageHash,
  }) async {
    _cacheKeys.add(cacheKey);
    _store[cacheKey] = CachedClassification.fromClassification(
      entryImageHash ?? cacheKey,
      classification,
      contentHash: contentHash,
      imageSize: imageSize,
    );
  }

  /// Number of stored entries.
  int get storedCount => _store.length;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _testImagePath = '/test/image.jpg';
const _testRegion = 'Test Region';
const _testLanguage = 'en';
const _testPromptVersion = 'prompt-v1';
const _testSchemaVersion = 'schema-v1';
const _testGuidelinesVersion = 'guidelines-v1';

/// Build a valid classification JSON string that represents a typical
/// AI provider response.
String _validClassificationJson({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  String subCategory = 'Plastic',
  double confidence = 0.95,
}) {
  return jsonEncode({
    'itemName': itemName,
    'category': category,
    'subCategory': subCategory,
    'explanation': 'This is a plastic bottle.',
    'disposalInstructions': {
      'primaryMethod': 'Recycle',
      'steps': ['Clean the bottle', 'Remove the cap', 'Place in recycling bin'],
      'hasUrgentTimeframe': false,
    },
    'alternatives': [
      {'itemName': 'PET Bottle', 'reason': 'If made of PET'},
    ],
    'visualFeatures': ['plastic', 'bottle', 'transparent'],
    'confidence': confidence,
  });
}

/// Build an OpenAI-style rawResponseMap.
Map<String, dynamic> _openAiRawResponse({
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  double confidence = 0.95,
}) {
  return {
    'choices': [
      {
        'message': {
          'content': _validClassificationJson(
            itemName: itemName,
            category: category,
            confidence: confidence,
          ),
        },
      },
    ],
  };
}

/// Build an [AiProviderResponse] simulating OpenAI.
AiProviderResponse _openAiResponse({
  String provider = 'openai',
  String model = 'gpt-4.1-nano',
  String itemName = 'Plastic Bottle',
  String category = 'Dry Waste',
  double confidence = 0.95,
}) {
  return AiProviderResponse(
    provider: provider,
    model: model,
    rawResponseMap: _openAiRawResponse(
      itemName: itemName,
      category: category,
      confidence: confidence,
    ),
    inputTokens: 100,
    outputTokens: 50,
  );
}

/// Build an [AiProviderResponse] simulating Gemini or backend (textContent).
AiProviderResponse _geminiResponse({
  String provider = 'gemini',
  String model = 'gemini-2.0-flash',
  String itemName = 'Aluminum Can',
  String category = 'Dry Waste',
  double confidence = 0.90,
}) {
  return AiProviderResponse(
    provider: provider,
    model: model,
    rawResponseMap: {},
    textContent: _validClassificationJson(
      itemName: itemName,
      category: category,
      confidence: confidence,
    ),
    inputTokens: 80,
    outputTokens: 40,
  );
}

/// Default processor that uses fakes and typical config.
ClassificationResultProcessor _defaultProcessor({
  bool cachingEnabled = false,
  bool policyApplied = false,
  _FakeCacheService? cacheService,
}) {
  return ClassificationResultProcessor(
    policyEngine: _FakePolicyEngine(policyApplied: policyApplied),
    cacheService: cacheService ?? _FakeCacheService(),
    cachingEnabled: cachingEnabled,
    promptVersion: _testPromptVersion,
    schemaVersion: _testSchemaVersion,
    localGuidelinesVersion: _testGuidelinesVersion,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ClassificationResultProcessor', () {
    group('process() — basic flow', () {
      test('processes OpenAI-style response into WasteClassification', () async {
        final processor = _defaultProcessor();
        final response = _openAiResponse();

        final result = await processor.process(
          providerResponse: response,
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(result, isA<WasteClassification>());
        expect(result.itemName, equals('Plastic Bottle'));
        expect(result.category, equals('Dry Waste'));
        expect(result.confidence, equals(0.95));
        expect(result.modelSource, contains('openai'));
      });

      test('processes Gemini-style response into WasteClassification', () async {
        final processor = _defaultProcessor();
        final response = _geminiResponse();

        final result = await processor.process(
          providerResponse: response,
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(result, isA<WasteClassification>());
        expect(result.itemName, equals('Aluminum Can'));
        expect(result.category, equals('Dry Waste'));
        expect(result.confidence, equals(0.90));
        expect(result.modelSource, contains('gemini'));
      });

      test('preserves provider and model in modelSource', () async {
        final processor = _defaultProcessor();
        final response = _openAiResponse(
          provider: 'openai',
          model: 'gpt-4.1-nano',
        );

        final result = await processor.process(
          providerResponse: response,
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(result.modelSource, equals('openai-gpt-4.1-nano'));
      });

      test('returns non-null classification for every valid input', () async {
        final processor = _defaultProcessor();

        for (final response in [
          _openAiResponse(),
          _geminiResponse(),
        ]) {
          final result = await processor.process(
            providerResponse: response,
            imagePath: _testImagePath,
            region: _testRegion,
            language: _testLanguage,
            imageSize: 1024,
          );
          expect(result, isNotNull);
        }
      });
    });

    group('process() — caching behavior', () {
      test('caches classification when cachingEnabled and imageHash provided',
          () async {
        final cacheService = _FakeCacheService();
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(),
          cacheService: cacheService,
          cachingEnabled: true,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
          imageHash: 'phash_test123',
        );

        expect(cacheService.storedCount, equals(1));
      });

      test('does NOT cache when cachingEnabled but no imageHash', () async {
        final cacheService = _FakeCacheService();
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(),
          cacheService: cacheService,
          cachingEnabled: true,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(cacheService.storedCount, equals(0));
      });

      test('does NOT cache when cachingEnabled is false', () async {
        final cacheService = _FakeCacheService();
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(),
          cacheService: cacheService,
          cachingEnabled: false,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
          imageHash: 'phash_test123',
        );

        expect(cacheService.storedCount, equals(0));
      });

      test('cache key includes region, language, provider, model', () async {
        final cacheService = _FakeCacheService();
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(),
          cacheService: cacheService,
          cachingEnabled: true,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: 'Mumbai, IN',
          language: 'hi',
          imageSize: 1024,
          imageHash: 'phash_mumbai',
        );

        expect(cacheService.cachedKeys, hasLength(1));
        final key = cacheService.cachedKeys.first;
        expect(key, contains('mumbai'));
        expect(key, contains('hi'));
        expect(key, contains('openai'));
        expect(key, contains('gpt-4.1-nano'));
      });
    });

    group('process() — policy integration', () {
      test(
          'passes through classification unchanged when policy is not applied',
          () async {
        final processor = _defaultProcessor(policyApplied: false);
        final response = _openAiResponse();

        final result = await processor.process(
          providerResponse: response,
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        // No policy metadata should be attached
        expect(result.bbmpComplianceStatus, isNull);
        expect(result.localGuidelinesVersion, isNull);
      });

      test('attaches policy metadata when policy is applied', () async {
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(
            policyApplied: true,
            complianceStatus: 'compliant',
            pluginId: 'test_plugin',
          ),
          cacheService: _FakeCacheService(),
          cachingEnabled: false,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        final result = await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: 'Bangalore, IN',
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(result.bbmpComplianceStatus, equals('compliant'));
        expect(result.localGuidelinesVersion, equals('test-v1'));
        expect(
          result.localRegulations?['policy_applied'],
          equals('true'),
        );
      });

      test('attaches compliance violations and warnings as regulation metadata',
          () async {
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(
            policyApplied: true,
            complianceStatus: 'violation',
            warnings: ['Dirty item'],
            violations: ['No special disposal'],
            recommendations: ['Clean before disposal'],
          ),
          cacheService: _FakeCacheService(),
          cachingEnabled: false,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        final result = await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        expect(result.localRegulations?['policy_compliance_status'],
            equals('violation'));
        expect(result.localRegulations?['policy_warning_count'], equals('1'));
        expect(result.localRegulations?['policy_violation_count'], equals('1'));
        expect(result.localRegulations?['policy_recommendations'],
            contains('Clean'));
      });
    });

    group('process() — image path handling', () {
      test('works with web-style image paths', () async {
        final processor = _defaultProcessor();
        final result = await processor.process(
          providerResponse: _openAiResponse(),
          imagePath: _testImagePath,
          region: _testRegion,
          language: _testLanguage,
          imageSize: 1024,
        );

        // Should produce a non-null image URL
        expect(result.imageUrl, equals(_testImagePath));
      });
    });

    group('constructor defaults', () {
      test('can be constructed with required dependencies', () {
        final processor = ClassificationResultProcessor(
          policyEngine: _FakePolicyEngine(),
          cacheService: _FakeCacheService(),
          cachingEnabled: true,
          promptVersion: _testPromptVersion,
          schemaVersion: _testSchemaVersion,
          localGuidelinesVersion: _testGuidelinesVersion,
        );

        expect(processor, isNotNull);
      });
    });
  });
}
