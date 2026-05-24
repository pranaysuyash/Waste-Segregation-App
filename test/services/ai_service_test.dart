import 'dart:typed_data'; // Added import
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/cost_guardrail_service.dart';
import 'package:waste_segregation_app/models/token_wallet.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../test_helper.dart';
import 'dart:convert';

// Simple mock for testing without external dependencies
class MockAiService {
  WasteClassification? _mockResult;
  Exception? _mockException;

  void setMockResult(WasteClassification result) {
    _mockResult = result;
    _mockException = null;
  }

  void setMockException(Exception exception) {
    _mockException = exception;
    _mockResult = null;
  }

  Future<WasteClassification> analyzeWebImage(
      Uint8List imageData, String filename) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockResult!;
  }
}

class _FakeGuardrailService extends CostGuardrailService {
  _FakeGuardrailService({
    required bool canUseInstant,
    required AnalysisSpeed recommendedSpeed,
    required bool batchEnforced,
  })  : _canUseInstant = canUseInstant,
        _recommendedSpeed = recommendedSpeed,
        _batchEnforced = batchEnforced;

  final bool _canUseInstant;
  final AnalysisSpeed _recommendedSpeed;
  final bool _batchEnforced;

  @override
  bool canUseInstantAnalysis({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) =>
      _canUseInstant;

  @override
  AnalysisSpeed getRecommendedAnalysisSpeed({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) =>
      _recommendedSpeed;

  @override
  bool get isBatchModeEnforced => _batchEnforced;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordApiSpending({
    required String model,
    required double cost,
    required int inputTokens,
    required int outputTokens,
    bool isBatchMode = false,
  }) async {}

  @override
  void dispose() {
    super.dispose();
  }
}

void main() {
  group('AiService', () {
    late AiService aiService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      aiService = AiService();
    });

    tearDown(() async {
      await TestHelper.cleanupServiceTest();
    });

    group('Image Classification', () {
      test('should handle empty image gracefully', () async {
        final result =
            await aiService.analyzeWebImage(Uint8List(0), 'test.jpg');
        expect(result, isA<WasteClassification>());
        expect(result.clarificationNeeded, isTrue);
        expect(result.itemName, isNotEmpty);
        expect(aiService.webSaveCallCount, equals(0));
        expect(aiService.providerCallCount, equals(0));
      });

      test('should handle null or empty image path', () async {
        final result = await aiService.analyzeWebImage(Uint8List(0), '');
        expect(result, isA<WasteClassification>());
        expect(result.clarificationNeeded, isTrue);
      });

      test('should handle invalid file extension', () async {
        final result =
            await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
        expect(result, isA<WasteClassification>());
        expect(result.clarificationNeeded, isTrue);
      });

      // Test with mock service to avoid real API calls
      test('should return classification result from mock service', () async {
        final mockService = MockAiService();
        final expectedClassification = WasteClassification(
          itemName: 'Plastic Bottle',
          subCategory: 'Plastic',
          category: 'Dry Waste',
          explanation: 'This is a plastic bottle that can be recycled',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean the bottle', 'Remove cap', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle', 'transparent'],
          alternatives: [],
          confidence: 0.95,
        );

        mockService.setMockResult(expectedClassification);

        final result = await mockService.analyzeWebImage(
            Uint8List.fromList([1, 2, 3, 4]), 'test.jpg');

        expect(result, isA<WasteClassification>());
        expect(result.itemName, equals('Plastic Bottle'));
        expect(result.category, equals('Dry Waste'));
        expect(result.confidence, equals(0.95));
      });
    });

    group('Classification Result Validation', () {
      test('WasteClassification should have required fields', () {
        final classification = WasteClassification(
          itemName: 'Test Item',
          subCategory: 'Plastic',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1', 'Step 2'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.85,
        );

        expect(classification.itemName, equals('Test Item'));
        expect(classification.category, equals('Dry Waste'));
        expect(classification.subCategory, equals('Plastic'));
        expect(classification.confidence, equals(0.85));
        expect(classification.disposalInstructions.steps.length, equals(2));
        expect(classification.visualFeatures.length, equals(2));
      });

      test('should validate confidence score range', () {
        final highConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          subCategory: 'Plastic',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
        );

        final lowConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          subCategory: 'Plastic',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.25,
        );

        expect(highConfidenceClassification.confidence, greaterThan(0.8));
        expect(lowConfidenceClassification.confidence, lessThan(0.5));
      });
    });

    group('Category Validation', () {
      test('should recognize valid waste categories', () {
        const validCategories = [
          'Dry Waste',
          'Wet Waste',
          'Hazardous Waste',
          'Medical Waste',
          'Non-Waste'
        ];

        for (final category in validCategories) {
          final classification = WasteClassification(
            itemName: 'Test Item',
            subCategory: 'General',
            category: category,
            explanation: 'Test explanation',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Test method',
              steps: ['Step 1'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now(),
            region: 'Test Region',
            visualFeatures: [],
            alternatives: [],
            confidence: 0.8,
          );

          expect(validCategories.contains(classification.category), isTrue);
        }
      });
    });

    group('Error Handling', () {
      test('web retries preserve original image name', () async {
        final savedNames = <String>[];
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionTimeout,
                    message: 'timeout',
                  ),
                );
              },
            ),
          );
        final service = AiService(
          cachingEnabled: false,
          dioClient: dio,
          openAiApiKey: 'test-openai-key',
          geminiApiKey: 'test-gemini-key',
          saveWebImageOverride: (bytes, imageName) async {
            savedNames.add(imageName);
            return '/saved/$imageName';
          },
        );

        final result = await service.analyzeWebImage(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]),
          'original_name.jpg',
          maxRetries: 1,
        );

        expect(result, isA<WasteClassification>());
        expect(savedNames, equals(['original_name.jpg', 'original_name.jpg']));
      });

      test('should not convert terminal auth failure into fallback', () async {
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'error': 'unauthorized'},
                ));
              },
            ),
          );
        final service = AiService(
          cachingEnabled: false,
          dioClient: dio,
          saveWebImageOverride: (bytes, imageName) async => imageName,
        );

        expect(
          () => service.analyzeWebImage(
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]),
            'auth_test.jpg',
          ),
          throwsA(
            isA<AiFailure>().having(
              (f) => f.kind,
              'kind',
              AiFailureKind.auth,
            ),
          ),
        );
      });

      test('should handle network errors gracefully', () async {
        final result = await aiService.analyzeWebImage(
            Uint8List(0), 'non_existent_file.jpg');
        expect(result, isA<WasteClassification>());
        expect(result.clarificationNeeded, isTrue);
      });

      test('should handle invalid file formats', () async {
        final result =
            await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
        expect(result, isA<WasteClassification>());
        expect(result.clarificationNeeded, isTrue);
      });

      test('should handle mock API errors', () async {
        final mockService = MockAiService();

        mockService.setMockException(Exception('Mock API Error'));

        expect(
          () async => mockService.analyzeWebImage(
              Uint8List.fromList([1, 2, 3, 4]), 'test.jpg'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Service Configuration', () {
      test('should initialize with default configuration', () {
        final service = AiService();
        expect(service, isNotNull);
        expect(service.cachingEnabled, isTrue);
        expect(service.defaultRegion, equals('Bangalore, IN'));
        expect(service.defaultLanguage, equals('en'));
      });

      test('should initialize with custom configuration', () {
        final service = AiService(
          cachingEnabled: false,
          defaultRegion: 'Mumbai, IN',
          defaultLanguage: 'hi',
          openAiBaseUrl: 'https://proxy.example.com/v1',
          openAiApiKey: 'test-openai-key',
        );
        expect(service, isNotNull);
        expect(service.cachingEnabled, isFalse);
        expect(service.defaultRegion, equals('Mumbai, IN'));
        expect(service.defaultLanguage, equals('hi'));
        expect(service.openAiBaseUrl, equals('https://proxy.example.com/v1'));
        expect(service.openAiApiKey, equals('test-openai-key'));
      });

      test('delegates guardrail status and speed recommendations', () {
        final service = AiService(
          guardrailService: _FakeGuardrailService(
            canUseInstant: false,
            recommendedSpeed: AnalysisSpeed.batch,
            batchEnforced: true,
          ),
        );

        expect(service.canUseInstantAnalysis(), isFalse);
        expect(service.getRecommendedAnalysisSpeed(), AnalysisSpeed.batch);
        expect(service.isBatchModeEnforced(), isTrue);
      });

      test('blocks instant provider path when guardrail denies instant mode',
          () async {
        final service = AiService(
          cachingEnabled: false,
          openAiApiKey: 'test-openai-key',
          geminiApiKey: 'test-gemini-key',
          guardrailService: _FakeGuardrailService(
            canUseInstant: false,
            recommendedSpeed: AnalysisSpeed.batch,
            batchEnforced: true,
          ),
          saveWebImageOverride: (bytes, imageName) async => '/tmp/$imageName',
        );

        expect(
          () => service.analyzeWebImage(
            Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]),
            'guardrail_block.jpg',
          ),
          throwsA(
            isA<AiFailure>().having(
              (f) => f.kind,
              'kind',
              AiFailureKind.budgetExceeded,
            ),
          ),
        );
      });

      test('cache key should change across context dimensions', () {
        final k1 = aiService.buildContextualCacheKey(
          imageHash: 'phash_123',
          region: 'Bangalore, IN',
          language: 'en',
          provider: 'openai',
          model: 'gpt-4.1-nano',
        );
        final k2 = aiService.buildContextualCacheKey(
          imageHash: 'phash_123',
          region: 'Mumbai, IN',
          language: 'en',
          provider: 'openai',
          model: 'gpt-4.1-nano',
        );
        final k3 = aiService.buildContextualCacheKey(
          imageHash: 'phash_123',
          region: 'Bangalore, IN',
          language: 'hi',
          provider: 'openai',
          model: 'gpt-4.1-nano',
        );
        expect(k1, isNot(k2));
        expect(k1, isNot(k3));
      });

      test(
          'cache similarity should remain phash-safe with context-aware content hash',
          () async {
        final cache = ClassificationCacheService();
        await cache.initialize();
        final classification = WasteClassification(
          itemName: 'Bottle',
          category: 'Dry Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Step'],
            hasUrgentTimeframe: false,
          ),
          region: 'Bangalore, IN',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.8,
        );

        const cachedHash = 'phash_0000000000000000';
        const similarHash = 'phash_0000000000000001';
        const contextA = 'content-hash::ctxA';
        const contextB = 'content-hash::ctxB';

        await cache.cacheClassification(
          cachedHash,
          classification,
          contentHash: contextA,
          imageSize: 10,
        );

        final hitWithSameContext = await cache.getCachedClassification(
          similarHash,
          contentHash: contextA,
        );
        final missWithDifferentContext = await cache.getCachedClassification(
          similarHash,
          contentHash: contextB,
        );

        expect(hitWithSameContext, isNotNull);
        expect(missWithDifferentContext, isNull);
      });

      test('correction provenance should be explicit for openai and gemini',
          () {
        final original = WasteClassification(
          id: 'fixed-id',
          itemName: 'Original',
          category: 'Dry Waste',
          explanation: 'Original',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Step'],
            hasUrgentTimeframe: false,
          ),
          region: 'Bangalore, IN',
          imageUrl: 'img-path',
          imageHash: 'phash_x',
          visualFeatures: const [],
          alternatives: const [],
        );
        final corrected = WasteClassification(
          id: 'temp-id',
          itemName: 'Corrected',
          category: 'Dry Waste',
          explanation: 'Corrected',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Step'],
            hasUrgentTimeframe: false,
          ),
          region: 'Bangalore, IN',
          visualFeatures: const [],
          alternatives: const [],
        );

        final openAiProvenance = aiService.applyCorrectionProvenance(
          corrected: corrected,
          original: original,
          provider: 'openai',
          model: 'gpt-4.1-nano',
          userCorrection: 'plastic',
        );
        final geminiProvenance = aiService.applyCorrectionProvenance(
          corrected: corrected,
          original: original,
          provider: 'gemini',
          model: 'gemini-2.0-flash',
          userCorrection: 'metal',
        );

        expect(openAiProvenance.source, equals('ai_reanalysis'));
        expect(openAiProvenance.modelSource, equals('openai-gpt-4.1-nano'));
        expect(openAiProvenance.id, equals('fixed-id'));
        expect(geminiProvenance.source, equals('ai_reanalysis'));
        expect(geminiProvenance.modelSource, equals('gemini-gemini-2.0-flash'));
        expect(geminiProvenance.id, equals('fixed-id'));
      });
    });

    group('JSON parsing with comments', () {
      test('should parse JSON with single-line comments', () {
        const jsonWithComments = '''
        {
          "itemName": "Red Pen", // This is a red writing instrument
          "category": "Dry Waste",
          "subcategory": "Plastic", // Made of plastic material
          "explanation": "A red plastic pen used for writing"
        }''';

        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(jsonWithComments);

        expect(() => jsonDecode(cleanedJson), returnsNormally);

        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Red Pen'));
        expect(parsed['category'], equals('Dry Waste'));
        expect(parsed['subcategory'], equals('Plastic'));
      });

      test('should parse JSON with multi-line comments', () {
        const jsonWithComments = '''
        {
          "itemName": "Blue Bottle", /* This is a 
                                        multi-line comment
                                        about the bottle */
          "category": "Dry Waste",
          "explanation": "A blue plastic bottle"
        }''';

        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(jsonWithComments);

        expect(() => jsonDecode(cleanedJson), returnsNormally);

        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Blue Bottle'));
        expect(parsed['category'], equals('Dry Waste'));
      });

      test('should handle JSON without comments', () {
        const normalJson = '''
        {
          "itemName": "Green Can",
          "category": "Dry Waste",
          "subcategory": "Metal"
        }''';

        final aiService = AiService();
        final cleanedJson = aiService.cleanJsonString(normalJson);

        expect(() => jsonDecode(cleanedJson), returnsNormally);

        final parsed = jsonDecode(cleanedJson);
        expect(parsed['itemName'], equals('Green Can'));
        expect(parsed['category'], equals('Dry Waste'));
        expect(parsed['subcategory'], equals('Metal'));
      });
    });
  });
}
