import 'dart:convert';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/ai_failure.dart';
import '../utils/production_safety_config.dart';
import '../utils/waste_app_logger.dart';
import '../utils/constants.dart';
import 'api_client_factory.dart';
import 'providers/backend_proxy_provider.dart';
import 'providers/classification_provider.dart';
import 'unified_api_client.dart';

/// Enhanced AI API service using the unified API client
///
/// Features:
/// - Unified API management for OpenAI and Gemini
/// - Automatic fallback between models
/// - Cost optimization and rate limiting
/// - Comprehensive error handling
/// - Request deduplication
/// - Performance monitoring
class EnhancedAiApiService {
  EnhancedAiApiService({
    this.enableCostOptimization = true,
    this.enableFallback = true,
    this.defaultRegion = 'Bangalore, IN',
    this.defaultLanguage = 'en',

    /// Optional injectable [ClassificationProvider] for the backend path.
    ///
    /// When null (the default), [_analyzeWithBackend] creates a
    /// [BackendProxyProvider] bound to [FirebaseFunctions.instance]. Pass a
    /// test double to intercept backend calls without a live Firebase instance.
    ClassificationProvider? backendProxy,
  }) : _backendProxy = backendProxy;

  final bool enableCostOptimization;
  final bool enableFallback;
  final String defaultRegion;
  final String defaultLanguage;

  /// Injectable backend proxy — null means use [BackendProxyProvider] lazily.
  final ClassificationProvider? _backendProxy;

  // A/B routing for race-based analysis (0.0 - 1.0)
  static final Random _random = Random();
  double _racePercentage = 0.0;

  /// Set the fraction of requests that are routed to the race method (0.0 - 1.0)
  void setRacePercentage(double p) {
    _racePercentage = p.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Routing flags
  // ---------------------------------------------------------------------------

  bool? _backendRoutingOverride;

  /// Override backend routing for unit tests without needing dart-defines.
  ///
  /// Call `service.overrideBackendRoutingForTest(true)` to force the backend
  /// path; call with `null` to restore production behaviour.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void overrideBackendRoutingForTest(bool? value) {
    _backendRoutingOverride = value;
  }

  bool get _backendRoutingEnabled {
    if (_backendRoutingOverride != null) return _backendRoutingOverride!;
    return kReleaseMode ||
        ProductionSafetyConfig.useBackendAiInRelease ||
        BackendProxyProvider.isEnabled;
  }

  bool get _backendRoutingFailClosed {
    return kReleaseMode || ProductionSafetyConfig.useBackendAiInRelease;
  }

  bool _isTerminalFailureKind(AiFailureKind kind) {
    return kind == AiFailureKind.cancelled ||
        kind == AiFailureKind.unsafeClientAiBlocked ||
        kind == AiFailureKind.auth ||
        kind == AiFailureKind.budgetExceeded;
  }

  // ---------------------------------------------------------------------------
  // Provider call telemetry (mirrors AiService.providerCallCount)
  // ---------------------------------------------------------------------------

  int _providerCallCount = 0;

  /// Number of times a provider (backend, OpenAI, or Gemini) was called.
  /// Resets on [resetStatistics].
  @visibleForTesting
  int get providerCallCount => _providerCallCount;

  // API clients
  late final UnifiedApiClient _openAiClient;
  late final UnifiedApiClient _geminiClient;

  // Service state
  bool _initialized = false;
  final Map<String, int> _modelUsageCount = {};
  final Map<String, double> _modelCosts = {};

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kReleaseMode) {
        _initialized = true;
        WasteAppLogger.info(
            'Enhanced AI API service initialized in backend-proxy mode',
            context: {
              'cost_optimization_enabled': enableCostOptimization,
              'fallback_enabled': enableFallback,
              'default_region': defaultRegion,
              'default_language': defaultLanguage,
              'backend_routing': true,
            });
        return;
      }

      _openAiClient = ApiClientFactory.getOpenAIClient();
      _geminiClient = ApiClientFactory.getGeminiClient();

      _initialized = true;

      WasteAppLogger.info('Enhanced AI API service initialized', context: {
        'cost_optimization_enabled': enableCostOptimization,
        'fallback_enabled': enableFallback,
        'default_region': defaultRegion,
        'default_language': defaultLanguage,
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to initialize Enhanced AI API service',
          error: e,
          context: {
            'error_type': e.runtimeType.toString(),
          });
      rethrow;
    }
  }

  /// Analyze waste image using AI with automatic model selection and fallback
  Future<WasteClassification> analyzeWasteImage({
    required Uint8List imageBytes,
    required String imageName,
    String? region,
    String? language,
    String? preferredModel,
    bool enableSegmentation = false,
  }) async {
    final effectiveRegion = region ?? defaultRegion;
    final effectiveLanguage = language ?? defaultLanguage;

    if (_backendRoutingEnabled) {
      try {
        return await _analyzeWithBackend(
          imageBytes: imageBytes,
          imageName: imageName,
          region: effectiveRegion,
          language: effectiveLanguage,
          enableSegmentation: enableSegmentation,
        );
      } on AiFailure catch (e) {
        if (_backendRoutingFailClosed || _isTerminalFailureKind(e.kind)) {
          rethrow;
        }

        WasteAppLogger.warning(
          'Backend proxy failed; falling back to direct client route',
          error: e,
          context: {
            'image_name': imageName,
            'region': effectiveRegion,
            'language': effectiveLanguage,
          },
        );
      }
    }

    await initialize();

    // A/B experiment: if configured, route a fraction of requests to the new race-based method
    if (_racePercentage > 0.0 && _random.nextDouble() < _racePercentage) {
      WasteAppLogger.info('A/B routing: using race-based analysis', context: {
        'race_percentage': _racePercentage,
        'image_name': imageName,
      });

      return analyzeWithRace(
        imageBytes: imageBytes,
        imageName: imageName,
        region: region,
        language: language,
        preferredModel: preferredModel,
        enableSegmentation: enableSegmentation,
      );
    }

    // Determine optimal model based on cost and performance
    final selectedModel = _selectOptimalModel(
      preferredModel: preferredModel,
      imageSize: imageBytes.length,
      enableSegmentation: enableSegmentation,
    );

    WasteAppLogger.info('Starting waste image analysis', context: {
      'image_name': imageName,
      'image_size_bytes': imageBytes.length,
      'selected_model': selectedModel,
      'region': effectiveRegion,
      'language': effectiveLanguage,
      'segmentation_enabled': enableSegmentation,
    });

    try {
      // Try primary model
      final result = await _analyzeWithModel(
        model: selectedModel,
        imageBytes: imageBytes,
        imageName: imageName,
        region: effectiveRegion,
        language: effectiveLanguage,
        enableSegmentation: enableSegmentation,
      );

      _recordModelUsage(selectedModel, success: true);
      return result;
    } catch (e) {
      _recordModelUsage(selectedModel, success: false);

      if (!enableFallback) {
        rethrow;
      }

      WasteAppLogger.warning('Primary model failed, trying fallback', error: e);

      // Try fallback model
      final fallbackModel = _getFallbackModel(selectedModel);
      if (fallbackModel != null) {
        try {
          final result = await _analyzeWithModel(
            model: fallbackModel,
            imageBytes: imageBytes,
            imageName: imageName,
            region: effectiveRegion,
            language: effectiveLanguage,
            enableSegmentation: enableSegmentation,
          );

          _recordModelUsage(fallbackModel, success: true);
          return result;
        } catch (fallbackError) {
          _recordModelUsage(fallbackModel, success: false);

          WasteAppLogger.severe('All models failed for image analysis',
              error: fallbackError,
              context: {
                'primary_model': selectedModel,
                'fallback_model': fallbackModel,
                'image_name': imageName,
              });

          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Analyze image by racing OpenAI and Gemini in parallel (non-breaking opt-in)
  Future<WasteClassification> analyzeWithRace({
    required Uint8List imageBytes,
    required String imageName,
    String? region,
    String? language,
    String? preferredModel,
    bool enableSegmentation = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final effectiveRegion = region ?? defaultRegion;
    final effectiveLanguage = language ?? defaultLanguage;

    if (_backendRoutingEnabled) {
      try {
        return await _analyzeWithBackend(
          imageBytes: imageBytes,
          imageName: imageName,
          region: effectiveRegion,
          language: effectiveLanguage,
          enableSegmentation: enableSegmentation,
        );
      } on AiFailure catch (e) {
        if (_backendRoutingFailClosed || _isTerminalFailureKind(e.kind)) {
          rethrow;
        }

        WasteAppLogger.warning(
          'Backend proxy failed; falling through to race route',
          error: e,
          context: {
            'image_name': imageName,
            'region': effectiveRegion,
            'language': effectiveLanguage,
          },
        );
      }
    }

    await initialize();

    final compressedBytes = await _compressImage(imageBytes);

    final openModel = (preferredModel != null && _isOpenAIModel(preferredModel))
        ? preferredModel
        : 'gpt-4o-mini';
    const geminiModel = ApiConfig.tertiaryModel;

    final openFuture = _analyzeWithOpenAI(
      model: openModel,
      imageBytes: compressedBytes,
      imageName: imageName,
      region: effectiveRegion,
      language: effectiveLanguage,
      enableSegmentation: enableSegmentation,
    ).timeout(timeout);

    final geminiFuture = _analyzeWithGemini(
      model: geminiModel,
      imageBytes: compressedBytes,
      imageName: imageName,
      region: effectiveRegion,
      language: effectiveLanguage,
      enableSegmentation: enableSegmentation,
    ).timeout(timeout);

    try {
      final result = await Future.any([openFuture, geminiFuture]);

      // Record success for whichever model produced the result
      _recordModelUsage(result.modelVersion ?? 'unknown', success: true);

      WasteAppLogger.info('Race analysis completed', context: {
        'winner_model': result.modelVersion,
        'image_name': imageName,
      });

      return result;
    } catch (e) {
      WasteAppLogger.warning('Race analysis: both services failed', error: e);

      // Mark both as failures for telemetry
      _recordModelUsage(openModel, success: false);
      _recordModelUsage(geminiModel, success: false);

      if (!enableFallback) {
        rethrow;
      }

      return WasteClassification.fallback(imageName);
    }
  }

  /// Compress image to reduce API costs and latency
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    if (bytes.length < 200 * 1024) return bytes;

    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      WasteAppLogger.info('Image compressed', context: {
        'original_kb': (bytes.length / 1024).toStringAsFixed(1),
        'compressed_kb': (result.length / 1024).toStringAsFixed(1),
        'reduction':
            '${((1 - result.length / bytes.length) * 100).toStringAsFixed(0)}%',
      });

      return result;
    } catch (e) {
      WasteAppLogger.warning('Image compression failed, using original',
          error: e);
      return bytes;
    }
  }

  /// Analyze image with specific model
  Future<WasteClassification> _analyzeWithModel({
    required String model,
    required Uint8List imageBytes,
    required String imageName,
    required String region,
    required String language,
    bool enableSegmentation = false,
  }) async {
    final compressedBytes = await _compressImage(imageBytes);

    if (_isOpenAIModel(model)) {
      return _analyzeWithOpenAI(
        model: model,
        imageBytes: compressedBytes,
        imageName: imageName,
        region: region,
        language: language,
        enableSegmentation: enableSegmentation,
      );
    } else if (_isGeminiModel(model)) {
      return _analyzeWithGemini(
        model: model,
        imageBytes: compressedBytes,
        imageName: imageName,
        region: region,
        language: language,
        enableSegmentation: enableSegmentation,
      );
    } else {
      throw ArgumentError('Unsupported model: $model');
    }
  }

  /// Analyze with OpenAI
  Future<WasteClassification> _analyzeWithOpenAI({
    required String model,
    required Uint8List imageBytes,
    required String imageName,
    required String region,
    required String language,
    bool enableSegmentation = false,
  }) async {
    ProductionSafetyConfig.guardClientAiCall('OpenAI');
    _providerCallCount++;
    final base64Image = base64Encode(imageBytes);

    final requestData = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _buildSystemPrompt(region, language),
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _buildAnalysisPrompt(enableSegmentation),
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': enableSegmentation ? 'high' : 'auto',
              },
            },
          ],
        },
      ],
      'max_tokens': enableSegmentation ? 2000 : 500,
      'temperature': 0.0,
      'response_format': {'type': 'json_object'},
    };

    final response = await _openAiClient.post<Map<String, dynamic>>(
      endpoint: 'chat/completions',
      data: requestData,
      operationId: 'openai_waste_analysis',
      timeout: const Duration(minutes: 2),
    );

    // Track actual cost (gpt-4o-mini pricing)
    try {
      final usage = response.data['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        final promptTokens = usage['prompt_tokens'] as int? ?? 0;
        final completionTokens = usage['completion_tokens'] as int? ?? 0;
        final cost = (promptTokens * 0.15 + completionTokens * 0.60) / 1000000;
        _modelCosts[model] = (_modelCosts[model] ?? 0) + cost;
        WasteAppLogger.info('OpenAI cost tracked', context: {
          'model': model,
          'prompt_tokens': promptTokens,
          'completion_tokens': completionTokens,
          'cost_usd': cost.toStringAsFixed(6),
        });
      }
    } catch (e) {
      WasteAppLogger.warning('Cost tracking failed', error: e);
    }

    if (!response.isSuccessful) {
      throw Exception('OpenAI API request failed: ${response.statusCode}');
    }

    return _parseOpenAIResponse(response.data, imageName, model);
  }

  /// Analyze through the secure Firebase backend proxy.
  Future<WasteClassification> _analyzeWithBackend({
    required Uint8List imageBytes,
    required String imageName,
    required String region,
    required String language,
    bool enableSegmentation = false,
  }) async {
    final compressedBytes = await _compressImage(imageBytes);
    final proxy = _backendProxy ??
        BackendProxyProvider(
          functions: FirebaseFunctions.instance,
        );
    _providerCallCount++;

    final response = await proxy.analyze(
      imageBytes: compressedBytes,
      mimeType: 'image/jpeg',
      region: region,
      lang: language,
      requestId: imageName,
    );

    final backendPayload = <String, dynamic>{
      'choices': [
        {
          'message': {
            'content':
                response.textContent ?? jsonEncode(response.rawResponseMap),
          },
        },
      ],
    };

    final model = response.model;
    final classification = _parseBackendResponse(
      backendPayload,
      imageName,
      model,
    );

    _recordModelUsage(model, success: true);
    _modelCosts[model] = _modelCosts[model] ?? 0;
    WasteAppLogger.info('Backend proxy analysis completed', context: {
      'image_name': imageName,
      'region': region,
      'language': language,
      'backend_model': model,
      'segmentation_enabled': enableSegmentation,
    });

    return classification;
  }

  /// Analyze with Gemini
  Future<WasteClassification> _analyzeWithGemini({
    required String model,
    required Uint8List imageBytes,
    required String imageName,
    required String region,
    required String language,
    bool enableSegmentation = false,
  }) async {
    ProductionSafetyConfig.guardClientAiCall('Gemini');
    _providerCallCount++;
    final base64Image = base64Encode(imageBytes);

    final requestData = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  '${_buildSystemPrompt(region, language)}\n\n${_buildAnalysisPrompt(enableSegmentation)}',
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.0,
        'maxOutputTokens': enableSegmentation ? 2000 : 500,
        'responseMimeType': 'application/json',
      },
    };

    final response = await _geminiClient.post<Map<String, dynamic>>(
      endpoint: 'models/$model:generateContent',
      data: requestData,
      queryParameters: {'key': ApiConfig.apiKey},
      operationId: 'gemini_waste_analysis',
      timeout: const Duration(minutes: 2),
    );

    if (!response.isSuccessful) {
      throw Exception('Gemini API request failed: ${response.statusCode}');
    }

    return _parseGeminiResponse(response.data, imageName, model);
  }

  /// Select optimal model based on various factors
  String _selectOptimalModel({
    String? preferredModel,
    required int imageSize,
    bool enableSegmentation = false,
  }) {
    // Use preferred model if specified and valid
    if (preferredModel != null && _isValidModel(preferredModel)) {
      return preferredModel;
    }

    // Cost optimization logic - compressed images by default
    if (enableCostOptimization) {
      if (enableSegmentation) {
        return ApiConfig.primaryModel; // More capable for segmentation
      }

      return 'gpt-4o-mini';
    }

    return 'gpt-4o-mini';
  }

  /// Get fallback model for a given primary model
  String? _getFallbackModel(String primaryModel) {
    if (primaryModel == ApiConfig.primaryModel) {
      return ApiConfig.secondaryModel1;
    } else if (primaryModel == ApiConfig.secondaryModel1) {
      return ApiConfig.tertiaryModel; // Gemini
    } else if (primaryModel == ApiConfig.tertiaryModel) {
      return ApiConfig.secondaryModel2;
    }
    return null;
  }

  /// Check if model is OpenAI model
  bool _isOpenAIModel(String model) {
    return model.startsWith('gpt-') ||
        model == ApiConfig.primaryModel ||
        model == ApiConfig.secondaryModel1 ||
        model == ApiConfig.secondaryModel2;
  }

  /// Check if model is Gemini model
  bool _isGeminiModel(String model) {
    return model.startsWith('gemini-') || model == ApiConfig.tertiaryModel;
  }

  /// Check if model is valid
  bool _isValidModel(String model) {
    return _isOpenAIModel(model) || _isGeminiModel(model);
  }

  /// Build system prompt
  String _buildSystemPrompt(String region, String language) {
    return '''
You are a waste classification API for $region. Output valid JSON only.
{
  "item_name": "specific name",
  "category": "Recyclable|Organic|Hazardous|E-Waste|Reject",
  "subcategory": "material type",
  "confidence": 0.0-1.0,
  "disposal_bin": "Blue|Green|Red|Black",
  "recyclable": boolean,
  "steps": ["max 3 steps"],
  "requires_special_dropoff": boolean,
  "explanation": "one sentence"
}
Rules for $region: Pizza boxes with grease=Organic(Green), Styrofoam=Reject(Black), Batteries=Hazardous(Red)+special dropoff.
Language: $language
''';
  }

  /// Build analysis prompt
  String _buildAnalysisPrompt(bool enableSegmentation) {
    const basePrompt = '''
Analyze this waste item image and provide a JSON response with:
- category: main waste category
- subcategory: specific subcategory
- confidence: confidence score (0-1)
- explanation: brief explanation
- disposal_instructions: how to dispose properly
- environmental_impact: brief impact description
''';

    if (enableSegmentation) {
      return '''$basePrompt
- segments: array of detected waste items with bounding boxes
- item_count: number of distinct waste items detected
''';
    }

    return basePrompt;
  }

  /// Parse OpenAI response
  WasteClassification _parseOpenAIResponse(
    Map<String, dynamic> responseData,
    String imageName,
    String model,
  ) {
    try {
      final choices = responseData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No choices in OpenAI response');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null) {
        throw Exception('No content in OpenAI response');
      }

      // Parse JSON directly (JSON mode enforced in request)
      final jsonData = json.decode(content) as Map<String, dynamic>;

      // Build a complete classification JSON for fromJson factory
      final classificationJson = {
        'itemName':
            jsonData['item_name'] ?? jsonData['itemName'] ?? 'Unknown Item',
        'category': jsonData['category'] ?? 'Unknown',
        'subcategory': jsonData['subcategory'],
        'confidence': jsonData['confidence'],
        'explanation': jsonData['explanation'] ?? '',
        'disposalInstructions': jsonData['disposal_instructions'] ??
            jsonData['disposalInstructions'],
        'environmentalImpact':
            jsonData['environmental_impact'] ?? jsonData['environmentalImpact'],
        'imageUrl': imageName,
        'region': jsonData['region'] ?? 'Unknown',
        'visualFeatures':
            jsonData['visual_features'] ?? jsonData['visualFeatures'] ?? [],
        'alternatives': jsonData['alternatives'] ?? [],
        'source': 'ai_analysis_openai_$model',
        'processingTimeMs': 0, // Will be set by caller
        'modelVersion': model,
      };

      return WasteClassification.fromJson(classificationJson);
    } catch (e) {
      WasteAppLogger.severe('Failed to parse OpenAI response',
          error: e,
          context: {
            'response_data': responseData.toString(),
            'model': model,
          });
      rethrow;
    }
  }

  /// Parse Gemini response
  WasteClassification _parseGeminiResponse(
    Map<String, dynamic> responseData,
    String imageName,
    String model,
  ) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;

      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in Gemini response');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        throw Exception('No text in Gemini response');
      }

      // Parse JSON directly (JSON mode enforced in request)
      final jsonData = json.decode(text) as Map<String, dynamic>;

      // Build a complete classification JSON for fromJson factory
      final classificationJson = {
        'itemName':
            jsonData['item_name'] ?? jsonData['itemName'] ?? 'Unknown Item',
        'category': jsonData['category'] ?? 'Unknown',
        'subcategory': jsonData['subcategory'],
        'confidence': jsonData['confidence'],
        'explanation': jsonData['explanation'] ?? '',
        'disposalInstructions': jsonData['disposal_instructions'] ??
            jsonData['disposalInstructions'],
        'environmentalImpact':
            jsonData['environmental_impact'] ?? jsonData['environmentalImpact'],
        'imageUrl': imageName,
        'region': jsonData['region'] ?? 'Unknown',
        'visualFeatures':
            jsonData['visual_features'] ?? jsonData['visualFeatures'] ?? [],
        'alternatives': jsonData['alternatives'] ?? [],
        'source': 'ai_analysis_gemini_$model',
        'processingTimeMs': 0, // Will be set by caller
        'modelVersion': model,
      };

      return WasteClassification.fromJson(classificationJson);
    } catch (e) {
      WasteAppLogger.severe('Failed to parse Gemini response',
          error: e,
          context: {
            'response_data': responseData.toString(),
            'model': model,
          });
      rethrow;
    }
  }

  /// Parse backend proxy response
  WasteClassification _parseBackendResponse(
    Map<String, dynamic> responseData,
    String imageName,
    String model,
  ) {
    try {
      final choices = responseData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No choices in backend response');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null) {
        throw Exception('No content in backend response');
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      final classificationJson = {
        'itemName':
            jsonData['item_name'] ?? jsonData['itemName'] ?? 'Unknown Item',
        'category': jsonData['category'] ?? 'Unknown',
        'subcategory': jsonData['subcategory'],
        'confidence': jsonData['confidence'],
        'explanation': jsonData['explanation'] ?? '',
        'disposalInstructions': jsonData['disposal_instructions'] ??
            jsonData['disposalInstructions'],
        'environmentalImpact':
            jsonData['environmental_impact'] ?? jsonData['environmentalImpact'],
        'imageUrl': imageName,
        'region': jsonData['region'] ?? 'Unknown',
        'visualFeatures':
            jsonData['visual_features'] ?? jsonData['visualFeatures'] ?? [],
        'alternatives': jsonData['alternatives'] ?? [],
        'source': 'ai_analysis_backend_$model',
        'processingTimeMs': 0,
        'modelVersion': model,
      };

      return WasteClassification.fromJson(classificationJson);
    } catch (e) {
      WasteAppLogger.severe('Failed to parse backend proxy response',
          error: e,
          context: {
            'response_data': responseData.toString(),
            'model': model,
          });
      rethrow;
    }
  }

  /// Record model usage statistics
  void _recordModelUsage(String model, {required bool success}) {
    final key = '${model}_${success ? 'success' : 'failure'}';
    _modelUsageCount[key] = (_modelUsageCount[key] ?? 0) + 1;

    WasteAppLogger.fine('Model usage recorded', context: {
      'model': model,
      'success': success,
      'total_usage': _modelUsageCount[key],
    });
  }

  /// Get service statistics
  Map<String, dynamic> getStatistics() {
    const backendProxyMode = kReleaseMode;
    final openAiStats = (backendProxyMode || !_initialized)
        ? {'backend_proxy_mode': backendProxyMode, 'initialized': _initialized}
        : _openAiClient.getStatistics();
    final geminiStats = (backendProxyMode || !_initialized)
        ? {'backend_proxy_mode': backendProxyMode, 'initialized': _initialized}
        : _geminiClient.getStatistics();

    return {
      'initialized': _initialized,
      'cost_optimization_enabled': enableCostOptimization,
      'fallback_enabled': enableFallback,
      'backend_proxy_mode': backendProxyMode,
      'model_usage': _modelUsageCount,
      'model_costs': _modelCosts,
      'openai_client': openAiStats,
      'gemini_client': geminiStats,
      'total_requests':
          _modelUsageCount.values.fold<int>(0, (sum, count) => sum + count),
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _modelUsageCount.clear();
    _modelCosts.clear();
    _providerCallCount = 0;

    WasteAppLogger.info('Enhanced AI API service statistics reset', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dispose resources
  void dispose() {
    // Clients are managed by the factory, so we don't dispose them here
    _modelUsageCount.clear();
    _modelCosts.clear();
    _initialized = false;

    WasteAppLogger.info('Enhanced AI API service disposed', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
