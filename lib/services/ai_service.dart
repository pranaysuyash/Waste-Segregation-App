import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow, sqrt;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/token_wallet.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/image_utils.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/enhanced_image_service.dart';
import 'package:waste_segregation_app/services/dynamic_pricing_service.dart';
import 'package:waste_segregation_app/services/cost_guardrail_service.dart';
import 'package:waste_segregation_app/services/enhanced_api_error_handler.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/classification_cache_key.dart';
import 'package:uuid/uuid.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';
import 'package:waste_segregation_app/utils/production_safety_config.dart';

/// Service for analyzing waste items using AI models (OpenAI and Gemini).
///
/// This service handles image processing, API requests, response parsing,
/// and caching of classification results. It includes fallback mechanisms
/// to ensure robustness and provides methods for analyzing images from
/// both web (Uint8List) and mobile (File) sources.
///
/// Key features:
/// - Image compression for OpenAI and Gemini APIs.
/// - Perceptual hashing and caching of classification results.
/// - Multi-model fallback (OpenAI primary, secondary models, and Gemini tertiary).
/// - Robust JSON parsing with cleanup and fallback for malformed AI responses.
/// - User correction handling to refine classifications.
/// - Placeholder for image segmentation.
///
/// Recent updates:
/// - Fixed regex syntax errors in `_createFallbackClassification` related to parsing
///   single-quoted strings in AI responses. The patterns now use string
///   concatenation (`RegExp(r'"([^"]+)"|' + r"'([^']+)'")`) to correctly
///   handle both double and single-quoted values.
class AiService {

  /// Constructs an [AiService].
  ///
  /// Initializes API configurations and the [ClassificationCacheService].
  /// Uses values from [ApiConfig] if specific URLs/keys are not provided.
  /// [cachingEnabled] defaults to true.
  /// [defaultRegion] defaults to 'Bangalore, IN'.
  /// [defaultLanguage] defaults to 'en'.
  AiService({
    String? openAiBaseUrl,
    String? openAiApiKey,
    String? geminiBaseUrl,
    String? geminiApiKey,
    ClassificationCacheService? cacheService,
    DynamicPricingService? pricingService,
    CostGuardrailService? guardrailService,
    EnhancedApiErrorHandler? errorHandler,
    EnhancedImageService? imageService,
    LocalPolicyEngine? localPolicyEngine,
    Dio? dioClient,
    Future<String> Function(Uint8List bytes, String imageName)?
        saveWebImageOverride,
    this.cachingEnabled = true,
    this.defaultRegion = 'Bangalore, IN',
    this.defaultLanguage = 'en',
  })  : openAiBaseUrl = openAiBaseUrl ?? ApiConfig.openAiBaseUrl,
        openAiApiKey = openAiApiKey ?? ApiConfig.openAiApiKey,
        geminiBaseUrl = geminiBaseUrl ?? ApiConfig.geminiBaseUrl,
        geminiApiKey = geminiApiKey ?? ApiConfig.apiKey,
        cacheService = cacheService ?? ClassificationCacheService(),
        pricingService = pricingService ?? DynamicPricingService(),
        guardrailService = guardrailService ?? CostGuardrailService(),
        errorHandler = errorHandler ?? EnhancedApiErrorHandler(),
        _imageService = imageService ?? EnhancedImageService(),
        localPolicyEngine = localPolicyEngine ?? const LocalPolicyEngine(),
        _dio = dioClient ?? Dio(),
        _saveWebImageOverride = saveWebImageOverride;
  static const String promptVersion = 'waste-classification-v2';
  static const String schemaVersion = 'waste-classification-schema-v2';
  static const String localGuidelinesVersion = 'bbmp-2024';
  static const bool enableDebugGridSegmentation =
      bool.fromEnvironment('ENABLE_DEBUG_GRID_SEGMENTATION');
  final String openAiBaseUrl;
  final String openAiApiKey;
  final String geminiBaseUrl;
  final String geminiApiKey;
  final ClassificationCacheService cacheService;
  final DynamicPricingService pricingService;
  final CostGuardrailService guardrailService;
  final EnhancedApiErrorHandler errorHandler;
  final LocalPolicyEngine localPolicyEngine;

  // ✅ OPTIMIZATION: Add as class field to avoid creating new instances repeatedly
  final EnhancedImageService _imageService;

  // Dio client for HTTP requests with cancellation support
  final Dio _dio;
  final Future<String> Function(Uint8List bytes, String imageName)?
      _saveWebImageOverride;
  CancelToken? _cancelToken;
  int _providerCallCount = 0;
  int _webSaveCallCount = 0;

  @visibleForTesting
  int get providerCallCount => _providerCallCount;

  @visibleForTesting
  int get webSaveCallCount => _webSaveCallCount;

  // Simple segmentation parameters - can be adjusted based on needs
  static const int segmentGridSize = 3; // 3x3 grid for basic segmentation
  static const double minSegmentArea = 0.05; // Minimum 5% of image area
  static const int objectDetectionSegments =
      9; // Maximum number of segments to return

  // Enable/disable caching (for testing or fallback)
  final bool cachingEnabled;

  // Default region for classifications
  final String defaultRegion;
  final String defaultLanguage;

  /// Initialize the service and its dependencies
  Future<void> initialize() async {
    // Initialize the cache service if caching is enabled
    if (cachingEnabled) {
      await cacheService.initialize();
    }

    // Initialize pricing and guardrail services
    await pricingService.initialize();
    await guardrailService.initialize();

    // Configure Dio with default timeouts
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);

    _logAiConfigState();

    WasteAppLogger.info(
        'AiService initialized with enhanced pricing and error handling',
        context: {
          'service': 'ai_service',
          'caching_enabled': cachingEnabled,
          'pricing_service_initialized': true,
          'guardrail_service_initialized': true,
          'error_handler_configured': true,
        });
  }

  void _logAiConfigState() {
    final provider = ProductionSafetyConfig.isClientAiAllowed
        ? 'CLIENT-SIDE (allowed)'
        : 'CLIENT-SIDE (BLOCKED in release)';
    final openAiConfigured = openAiApiKey.isNotEmpty &&
        !ProductionSafetyConfig.hasPlaceholderKey(openAiApiKey);
    final geminiConfigured = geminiApiKey.isNotEmpty &&
        !ProductionSafetyConfig.hasPlaceholderKey(geminiApiKey);

    WasteAppLogger.info(
      '[AI CONFIG] Provider: $provider | '
      'OpenAI configured: $openAiConfigured | '
      'Gemini configured: $geminiConfigured | '
      'Release guard: ${kReleaseMode ? "ACTIVE" : "disabled (debug)"}',
    );
  }

  /// Prepares a new cancel token for the next analysis operation.
  /// Call this before starting any new analysis to reset cancellation state.
  void prepareCancelToken() {
    _cancelToken?.cancel('New analysis started');
    _cancelToken = CancelToken();
    WasteAppLogger.info('New analysis prepared, error: cancel token reset.');
  }

  /// Cancels any ongoing analysis operation.
  /// This will immediately abort in-flight HTTP requests.
  void cancelAnalysis() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User requested cancellation');
      WasteAppLogger.warning('Analysis cancelled by user.');
    }
  }

  /// Check if instant analysis is available based on current budget
  bool canUseInstantAnalysis({String? model}) {
    final modelKey = model ??
        ApiConfig.primaryModel.replaceAll('-', '_').replaceAll('.', '_');
    return guardrailService.canUseInstantAnalysis(model: modelKey);
  }

  /// Get recommended analysis speed based on current budget and cost constraints
  AnalysisSpeed getRecommendedAnalysisSpeed({String? model}) {
    final modelKey = model ??
        ApiConfig.primaryModel.replaceAll('-', '_').replaceAll('.', '_');
    return guardrailService.getRecommendedAnalysisSpeed(model: modelKey);
  }

  /// Check if batch mode is currently enforced due to budget constraints
  bool isBatchModeEnforced() {
    return guardrailService.isBatchModeEnforced;
  }

  /// Get current budget utilization for displaying to user
  Map<String, double> getBudgetUtilization() {
    return pricingService.getBudgetUtilization();
  }

  /// Get estimated cost for an analysis operation
  double getEstimatedCost({
    String? model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
    bool isBatchMode = false,
  }) {
    final modelKey = model ??
        ApiConfig.primaryModel.replaceAll('-', '_').replaceAll('.', '_');
    return pricingService.calculateCost(
      model: modelKey,
      inputTokens: estimatedInputTokens ?? 1500,
      outputTokens: estimatedOutputTokens ?? 800,
      isBatchMode: isBatchMode,
    );
  }

  /// Get estimated cost savings from using batch mode
  double getEstimatedBatchSavings({String? model}) {
    final modelKey = model ??
        ApiConfig.primaryModel.replaceAll('-', '_').replaceAll('.', '_');
    return pricingService.getEstimatedBatchSavings(model: modelKey);
  }

  /// Checks if the current operation has been cancelled.
  bool get isCancelled => _cancelToken?.isCancelled ?? false;

  /// Handles DioException and converts cancellation to a more user-friendly exception
  void _handleDioException(DioException e, {String? provider, String? model}) {
    if (e.type == DioExceptionType.cancel) {
      throw AiFailure(
        AiFailureKind.cancelled,
        'Analysis cancelled by user',
        provider: provider,
        model: model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      throw AiFailure(
        _failureKindFromStatus(statusCode),
        'Provider HTTP error $statusCode: ${e.response?.data}',
        provider: provider,
        model: model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Connection timeout - please check your internet connection',
        provider: provider,
        model: model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Request timeout - the server took too long to respond',
        provider: provider,
        model: model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Upload timeout - failed to send image data',
        provider: provider,
        model: model,
        cause: e,
      );
    } else {
      throw AiFailure(
        AiFailureKind.network,
        'Network error: ${e.message}',
        provider: provider,
        model: model,
        cause: e,
      );
    }
  }

  AiFailureKind _failureKindFromStatus(int statusCode) {
    if (statusCode == 400) return AiFailureKind.invalidImage;
    if (statusCode == 401 || statusCode == 403) return AiFailureKind.auth;
    if (statusCode == 429) return AiFailureKind.rateLimited;
    if (statusCode == 503 || statusCode == 502) {
      return AiFailureKind.providerUnavailable;
    }
    return AiFailureKind.unknown;
  }

  bool _shouldFallbackToGemini(
      AiFailureKind kind, int retryCount, int maxRetries) {
    if (retryCount >= maxRetries) return true;
    return kind == AiFailureKind.invalidImageTooLarge ||
        kind == AiFailureKind.providerUnavailable;
  }

  bool _isTerminalFailureKind(AiFailureKind kind) {
    return kind == AiFailureKind.cancelled ||
        kind == AiFailureKind.unsafeClientAiBlocked ||
        kind == AiFailureKind.auth ||
        kind == AiFailureKind.budgetExceeded;
  }

  String _buildContextSignature({
    required String region,
    required String language,
    required String provider,
    required String model,
  }) {
    return ClassificationCacheKey.build(
      imageHash: 'ctx',
      region: region,
      language: language,
      promptVersion: promptVersion,
      schemaVersion: schemaVersion,
      localGuidelinesVersion: localGuidelinesVersion,
      provider: provider,
      model: model,
    );
  }

  String? _buildContextAwareContentHash(
    String? rawContentHash, {
    required String region,
    required String language,
    required String provider,
    required String model,
  }) {
    if (rawContentHash == null) return null;
    return '$rawContentHash::${_buildContextSignature(region: region, language: language, provider: provider, model: model)}';
  }

  @visibleForTesting
  String buildContextualCacheKey({
    required String imageHash,
    required String region,
    required String language,
    required String provider,
    required String model,
  }) {
    return ClassificationCacheKey.build(
      imageHash: imageHash,
      region: region,
      language: language,
      promptVersion: promptVersion,
      schemaVersion: schemaVersion,
      localGuidelinesVersion: localGuidelinesVersion,
      provider: provider,
      model: model,
    );
  }

  @visibleForTesting
  WasteClassification applyCorrectionProvenance({
    required WasteClassification corrected,
    required WasteClassification original,
    required String provider,
    required String model,
    required String userCorrection,
  }) {
    final providerModelLabel = '$provider-$model';
    final mergedReanalysisModels = <String>[
      ...?original.reanalysisModelsTried,
      providerModelLabel,
    ];
    return corrected.copyWith(
      imageUrl: original.imageUrl,
      imageHash: original.imageHash,
      source: 'ai_reanalysis',
      modelSource: providerModelLabel,
      reanalysisModelsTried: mergedReanalysisModels,
      userCorrection: userCorrection,
      id: original.id,
    );
  }

  /// System prompt for waste classification expert.
  ///
  /// Defines the persona and general instructions for the AI model.
  /// It emphasizes expertise in international waste classification,
  /// local guidelines (for [defaultRegion]), recycling codes, and safety.
  String get _systemPrompt => '''
You are an expert in international waste classification, recycling, and proper disposal practices. 
You are familiar with global and local waste management rules (including $defaultRegion), brand-specific packaging, and recycling codes. 
Your goal is to provide accurate, actionable, and safe waste sorting guidance based on the latest environmental standards.
''';

  /// Enhanced AI Analysis v2.0 - Main classification prompt for comprehensive environmental analysis
  ///
  /// Instructs the AI model to return a comprehensive, strictly formatted JSON object
  /// with 21+ data points including environmental impact, CO2 footprint, and local guidelines.
  String get _mainClassificationPrompt => '''
Analyze the provided waste item and return a comprehensive JSON object with detailed environmental analysis. Use your knowledge of materials science, environmental impact, and waste management to provide accurate assessments.

Classification Hierarchy & Instructions:

1. BASIC CLASSIFICATION:
   - Main category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, Non-Waste
   - Subcategory: Most specific classification (e.g., "PET Plastic", "Food Scraps", "E-waste")
   - Material type: Primary material composition
   - Recycling code: For plastics (1-7), if identifiable

2. ENVIRONMENTAL IMPACT ANALYSIS (Enhanced v2.0):
   - recyclability: "fully recyclable", "partially recyclable", "not recyclable"
   - hazardLevel: Integer 1-5 (1=safe, 5=extremely hazardous)
   - co2Impact: CO2 equivalent in kg (estimate lifecycle impact)
   - decompositionTime: Natural decomposition timeline (e.g., "6 months", "500 years")
   - waterPollutionLevel: Integer 1-5 (potential for water contamination)
   - soilContaminationRisk: Integer 1-5 (soil pollution risk)
   - biodegradabilityDays: Integer days for natural breakdown
   - recyclingEfficiency: Percentage 0-100 (how much can actually be recycled)
   - manufacturingEnergyFootprint: Energy in kWh to produce this item
   - transportationFootprint: CO2 kg for typical transport to disposal
   - endOfLifeCost: Environmental cost description (e.g., "landfill space", "toxic leachate")
   - generatesMicroplastics: Boolean (does this create microplastic pollution?)
   - humanToxicityLevel: Integer 1-5 (health risk to humans)
   - wildlifeImpactSeverity: Integer 1-5 (impact on animals/ecosystems)
   - resourceScarcity: "common", "uncommon", "rare" (how scarce are source materials?)
   - disposalCostEstimate: Estimated cost in INR for proper disposal

3. CIRCULAR ECONOMY ANALYSIS:
   - circularEconomyPotential: List of reuse/repurpose opportunities
   - materials: List of component materials for better sorting
   - commonUses: List of typical uses for this item
   - alternativeOptions: List of eco-friendly alternatives

4. LOCAL GUIDELINES (BANGALORE BBMP FOCUS):
   - bbmpComplianceStatus: "compliant", "requires_attention", "violation" (BBMP regulations)
   - localGuidelinesVersion: "BBMP 2024" or relevant local authority
   - localRegulations: Key-value pairs of local rules (e.g., {"color_coding": "green_bin", "collection_day": "tuesday"})

5. SAFETY & HANDLING:
   - properEquipment: List of required PPE (e.g., ["gloves", "mask", "eye_protection"])
   - requiredPPE: Safety equipment needed for handling
   - riskLevel: "safe", "caution", "hazardous"

6. STANDARD FIELDS:
   - Disposal instructions with primaryMethod, steps, timeframe, location, warnings, tips
   - Visual features, brand, product, barcode (if visible)
   - Confidence score (0.0-1.0), clarificationNeeded boolean
   - Alternative classifications with reasoning
   - Multi-language support (hi, kn, en)

7. DYNAMIC POINTS CALCULATION:
   Instead of fixed pointsAwarded, use calculatePoints() method which considers:
   - Data richness (more detailed analysis = more points)
   - Environmental complexity (hazardous items = bonus points)
   - Local compliance (BBMP compliance = bonus points)
   - Confidence level (high confidence = bonus points)
   Range: 5-50 points based on analysis quality

SPECIAL INSTRUCTIONS FOR BANGALORE:
- Reference BBMP waste segregation rules where applicable
- Consider monsoon disposal challenges (May-October)
- Include color-coded bin recommendations (Green/Brown/Red)
- Factor in apartment vs independent house disposal differences
- Consider local recycling market rates for valuable materials

Rules:
- Return ONLY the JSON object
- Include all environmental analysis fields
- Use scientific estimates for environmental impacts
- Reference actual BBMP guidelines when possible
- Set pointsAwarded to null (will be calculated dynamically)

JSON STRUCTURE with ALL fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, disposalInstructions, region, localGuidelinesReference, imageUrl, imageHash, imageMetrics, visualFeatures, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode, riskLevel, requiredPPE, brand, product, barcode, isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount, clarificationNeeded, confidence, modelVersion, processingTimeMs, modelSource, analysisSessionId, alternatives, suggestedAction, hasUrgentTimeframe, instructionsLang, translatedInstructions, pointsAwarded, isSingleUse, environmentalImpact, relatedItems, recyclability, hazardLevel, co2Impact, decompositionTime, properEquipment, materials, subCategory, commonUses, alternativeOptions, localRegulations, waterPollutionLevel, soilContaminationRisk, biodegradabilityDays, recyclingEfficiency, manufacturingEnergyFootprint, transportationFootprint, endOfLifeCost, circularEconomyPotential, generatesMicroplastics, humanToxicityLevel, wildlifeImpactSeverity, resourceScarcity, disposalCostEstimate, bbmpComplianceStatus, localGuidelinesVersion
''';

  /// Correction/disagreement prompt for handling user feedback.
  ///
  /// Guides the AI to re-analyze an item based on user-provided corrections
  /// or disagreements, updating the classification and explaining changes.
  String _getCorrectionPrompt(Map<String, dynamic> previousClassification,
          String userCorrection, String? userReason) =>
      '''
A user has reviewed the waste item classification and provided feedback or a correction.  
Please re-analyze the item and return an updated JSON response, as per the data model, with special attention to:

- Areas of disagreement: Update the classification or reasoning as needed.
- clarificationNeeded: Set to true if ambiguity remains or confidence is low.
- disagreementReason: Explain why the original classification may have been incorrect, and how the user correction changes the analysis.

Input Context:
- Previous classification: ${jsonEncode(previousClassification)}
- User correction: "$userCorrection"
- Reason (if provided): "${userReason ?? 'Not provided'}"

Instructions:
- Update all relevant fields, especially category, subcategory, materialType, and explanation.
- Add a disagreementReason field, explaining the change or clarification.
- Use the same JSON model as before; fill all fields as per updated analysis.

Output:
- Only the updated JSON object.
''';

  // Convert image to base64 for API request
  Future<String> _imageToBase64(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  /// Converts [Uint8List] image data to a base64 encoded string.
  /// Suitable for web environments where [File] objects are not available.
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Detects the image format from [Uint8List] data and returns an appropriate MIME type.
  ///
  /// Supports PNG, JPEG, and WebP. Defaults to 'image/jpeg' if the format is unknown.
  String _detectImageMimeType(Uint8List imageBytes) {
    // Check PNG signature
    if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'image/png';
    }

    // Check JPEG signature
    if (imageBytes.length >= 3 &&
        imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // Check WebP signature
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'image/webp';
    }

    // Default to JPEG if unknown
    return 'image/jpeg';
  }

  /// Compresses image [Uint8List] data if it's too large for the OpenAI API (20MB limit, 5MB preferred).
  ///
  /// Applies aggressive compression (scaling and quality reduction) if the image exceeds
  /// the maximum size, or moderate compression if it exceeds the preferred size.
  /// Throws an exception if the image remains too large after compression,
  /// which can trigger a fallback to the Gemini API.
  /// OPTIMIZATION: Compresses image for OpenAI API with quality control using compute isolate
  /// This moves the CPU-intensive image processing off the main thread for better UI responsiveness
  Future<Uint8List> _compressImageForOpenAI(Uint8List imageBytes) async {
    const maxSizeBytes = 20 * 1024 * 1024; // 20MB OpenAI limit
    const preferredSizeBytes = 5 * 1024 * 1024; // 5MB preferred

    WasteAppLogger.info(
        'Original image size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

    // If image is already smaller than preferred size, return as is
    if (imageBytes.length < preferredSizeBytes) {
      WasteAppLogger.info(
          'Image is smaller than preferred size, error: no compression needed.');
      return imageBytes;
    }

    // OPTIMIZATION: Use compute() to run compression in isolate (off main thread)
    try {
      final compressedBytes = await compute(
        _compressImageIsolate,
        {
          'imageBytes': imageBytes,
          'preferredSizeBytes': preferredSizeBytes,
          'maxSizeBytes': maxSizeBytes,
        },
      );

      WasteAppLogger.info(
          'Compressed image in isolate to ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      return compressedBytes;
    } catch (e, s) {
      WasteAppLogger.severe('Error during isolate image compression',
          error: e, stackTrace: s);
      // Fallback to synchronous compression if isolate fails
      return _compressImageSync(imageBytes, preferredSizeBytes, maxSizeBytes);
    }
  }

  /// Static method for isolate execution - compresses image bytes
  static Uint8List _compressImageIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final preferredSizeBytes = params['preferredSizeBytes'] as int;
    final maxSizeBytes = params['maxSizeBytes'] as int;

    return _compressImageSync(imageBytes, preferredSizeBytes, maxSizeBytes);
  }

  /// Synchronous compression logic (used by both isolate and fallback)
  static Uint8List _compressImageSync(
    Uint8List imageBytes,
    int preferredSizeBytes,
    int maxSizeBytes,
  ) {
    // Iteratively compress image until it's under the preferred size
    var quality = 95;
    var compressedBytes = imageBytes;

    while (compressedBytes.length > preferredSizeBytes && quality > 10) {
      try {
        final image = img.decodeImage(compressedBytes);
        if (image == null) {
          return compressedBytes; // Return current if decoding fails
        }

        compressedBytes =
            Uint8List.fromList(img.encodeJpg(image, quality: quality));
        quality -= 5;
      } catch (e) {
        break; // Exit loop on error
      }
    }

    if (compressedBytes.length > maxSizeBytes) {
      throw AiFailure(
        AiFailureKind.invalidImageTooLarge,
        'Image is still too large after compression.',
      );
    }

    return compressedBytes;
  }

  /// OPTIMIZATION: Compresses image for Gemini API using compute isolate
  /// Gemini has a more generous limit than OpenAI, so compression is lighter.
  Future<Uint8List> _compressImageForGemini(Uint8List imageBytes) async {
    const maxSizeBytes = 50 * 1024 * 1024; // 50MB for Gemini

    if (imageBytes.length <= maxSizeBytes) {
      return imageBytes; // No compression needed
    }

    WasteAppLogger.warning(
        'Image exceeds Gemini max size, error: applying compression.');

    // OPTIMIZATION: Use compute() to run compression in isolate (off main thread)
    try {
      final compressedBytes = await compute(
        _compressImageForGeminiIsolate,
        {
          'imageBytes': imageBytes,
          'maxSizeBytes': maxSizeBytes,
        },
      );

      WasteAppLogger.info(
          'Compressed image in isolate for Gemini: ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      return compressedBytes;
    } catch (e, s) {
      WasteAppLogger.severe('Error during Gemini isolate compression',
          error: e, stackTrace: s);
      // Fallback to synchronous compression
      return _compressImageForGeminiSync(imageBytes, maxSizeBytes);
    }
  }

  /// Static method for isolate execution - compresses image for Gemini
  static Uint8List _compressImageForGeminiIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final maxSizeBytes = params['maxSizeBytes'] as int;

    return _compressImageForGeminiSync(imageBytes, maxSizeBytes);
  }

  /// Synchronous Gemini compression logic
  static Uint8List _compressImageForGeminiSync(
      Uint8List imageBytes, int maxSizeBytes) {
    var image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Could not decode image for Gemini compression.');
    }

    // Scale down to fit within max size, maintaining aspect ratio
    final scale =
        sqrt(maxSizeBytes / imageBytes.length); // Approximate scaling factor
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );

    final List<int> compressedBytes =
        img.encodeJpg(image, quality: 80); // Maintain good quality

    if (compressedBytes.length > maxSizeBytes) {
      throw Exception(
          'Image still too large after Gemini compression (${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB). Max allowed is ${maxSizeBytes / 1024 / 1024} MB.');
    }

    return Uint8List.fromList(compressedBytes);
  }

  /// Analyzes a mobile image (File) for waste classification.
  ///
  /// This is the primary entry point for mobile platforms.
  /// It generates a perceptual hash, checks the cache, and then
  /// calls the appropriate AI model (OpenAI or Gemini) for analysis.
  Future<WasteClassification> analyzeImage(
    File imageFile, {
    int retryCount = 0,
    int maxRetries = 3,
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    String? imageHash;
    final analysisRegion = region ?? defaultRegion;
    final analysisLang = instructionsLang ?? defaultLanguage;

    // Generate a new classification ID if not provided (for initial call)
    final currentClassificationId = classificationId ?? const Uuid().v4();

    // Prepare cancel token for new analysis (only on initial call, not retries)
    if (retryCount == 0) {
      prepareCancelToken();
    }

    // ✅ OPTIMIZATION: Use singleton instance with error handling
    final File permanentFile;
    String? thumbnailPath;
    try {
      final permanentPath = await _imageService.saveFilePermanently(imageFile);
      permanentFile = File(permanentPath);

      // Generate and save thumbnail
      final imageBytes = await permanentFile.readAsBytes();
      thumbnailPath = await _imageService.saveThumbnail(imageBytes);
    } catch (e, s) {
      WasteAppLogger.severe('Error saving image permanently',
          error: e, stackTrace: s);
      return WasteClassification.fallback(imageFile.path,
          id: currentClassificationId);
    }

    try {
      // Check cache if enabled with dual-hash verification
      String? contentHash;
      if (cachingEnabled) {
        final imageBytes = permanentFile.readAsBytesSync();

        // Generate both hashes efficiently in isolate to prevent UI lag
        final hashes = await ImageUtils.generateDualHashes(imageBytes);
        imageHash = hashes['perceptualHash'];
        contentHash = hashes['contentHash'];

        WasteAppLogger.info('Generated perceptual hash: $imageHash');
        WasteAppLogger.info('Generated content hash: $contentHash');

        if (imageHash != null) {
          final perceptualHash = imageHash;
          final contextAwareContentHash = _buildContextAwareContentHash(
            contentHash,
            region: analysisRegion,
            language: analysisLang,
            provider: 'openai',
            model: ApiConfig.primaryModel,
          );
          final contextAwareCacheKey = buildContextualCacheKey(
            imageHash: perceptualHash,
            region: analysisRegion,
            language: analysisLang,
            provider: 'openai',
            model: ApiConfig.primaryModel,
          );
          final cachedResult = await cacheService.getCachedClassification(
            contextAwareCacheKey,
            contentHash: contextAwareContentHash,
          );
          if (cachedResult != null) {
            return Future.value(cachedResult.classification
                .copyWith(id: currentClassificationId));
          }
        }
      }

      // Try OpenAI first with compression
      try {
        final result = await _analyzeWithOpenAI(
          await permanentFile.readAsBytes(), // Read bytes here
          permanentFile.path, // Use permanent path
          analysisRegion,
          analysisLang,
          imageHash,
          currentClassificationId, // Pass the new ID
          contentHash: contentHash, // Pass content hash for caching
          thumbnailPath: thumbnailPath, // Pass thumbnail path
        );
        return result;
      } on Exception catch (openAiError, s) {
        // Short-circuit on production safety — no retry or Gemini fallback.
        if (openAiError is ProductionSafetyException) {
          WasteAppLogger.warning(
              '[AI SAFETY] Client-side AI blocked in release build.');
          rethrow;
        }

        WasteAppLogger.severe('OpenAI analysis failed',
            error: openAiError, stackTrace: s);

        final failureKind =
            openAiError is AiFailure ? openAiError.kind : AiFailureKind.unknown;

        if (failureKind == AiFailureKind.cancelled ||
            failureKind == AiFailureKind.unsafeClientAiBlocked ||
            failureKind == AiFailureKind.auth ||
            failureKind == AiFailureKind.budgetExceeded) {
          rethrow;
        }

        if (_shouldFallbackToGemini(failureKind, retryCount, maxRetries)) {
          WasteAppLogger.info('Falling back to Gemini analysis.');
          final result = await _analyzeWithGemini(
            await permanentFile.readAsBytes(), // Read bytes here
            permanentFile.path, // Use permanent path
            analysisRegion,
            analysisLang,
            imageHash,
            currentClassificationId, // Pass the new ID
            contentHash: contentHash, // Pass content hash for caching
            thumbnailPath: thumbnailPath, // Pass thumbnail path
          );
          return result;
        }

        // For other errors, retry with OpenAI
        if (retryCount < maxRetries) {
          final waitTime =
              Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          await Future.delayed(waitTime);
          return analyzeImage(
            permanentFile,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            region: region,
            instructionsLang: instructionsLang,
            classificationId:
                currentClassificationId, // Pass the same ID on retry
          );
        }

        rethrow;
      }
    } catch (e, s) {
      if (e is ProductionSafetyException) rethrow;
      if (e is AiFailure && _isTerminalFailureKind(e.kind)) rethrow;
      WasteAppLogger.severe('Top-level analysis failed',
          error: e, stackTrace: s);
      // Ensure fallback also uses the consistent ID
      return WasteClassification.fallback(
        permanentFile.path,
        id: currentClassificationId,
      );
    }
  }

  /// Analyzes a web image (Uint8List) for waste classification.
  ///
  /// This is the primary entry point for web platforms.
  /// It generates a perceptual hash, checks the cache, and then
  /// calls the appropriate AI model (OpenAI or Gemini) for analysis.
  Future<WasteClassification> analyzeWebImage(
    Uint8List imageBytes,
    String imageName, {
    int retryCount = 0,
    int maxRetries = 3,
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    String? imageHash;
    final analysisRegion = region ?? defaultRegion;
    final analysisLang = instructionsLang ?? defaultLanguage;

    // Generate a new classification ID if not provided (for initial call)
    final currentClassificationId = classificationId ?? const Uuid().v4();

    // Prepare cancel token for new analysis (only on initial call, not retries)
    if (retryCount == 0) {
      prepareCancelToken();
    }

    // Early exit for empty image data to prevent processing errors and unnecessary API calls
    if (imageBytes.isEmpty) {
      WasteAppLogger.warning('analyzeWebImage called with empty image data.');
      return WasteClassification.fallback(
        imageName.isEmpty ? 'invalid_empty_web_image' : imageName,
        id: currentClassificationId,
      );
    }

    // ✅ OPTIMIZATION: Use singleton instance with error handling
    final String savedImagePath;
    try {
      _webSaveCallCount++;
      if (_saveWebImageOverride != null) {
        savedImagePath = await _saveWebImageOverride(imageBytes, imageName);
      } else {
        savedImagePath = await _imageService.saveImagePermanently(imageBytes,
            fileName: imageName);
      }
    } catch (e, s) {
      WasteAppLogger.severe('Error saving web image permanently',
          error: e, stackTrace: s);
      return WasteClassification.fallback(imageName,
          id: currentClassificationId);
    }

    try {
      // Check cache if enabled with dual-hash verification
      String? contentHash;
      if (cachingEnabled) {
        // Generate both hashes efficiently in isolate to prevent UI lag
        final hashes = await ImageUtils.generateDualHashes(imageBytes);
        imageHash = hashes['perceptualHash'];
        contentHash = hashes['contentHash'];

        WasteAppLogger.info(
            'Generated perceptual hash for web image: $imageHash');
        WasteAppLogger.info(
            'Generated content hash for web image: $contentHash');

        if (imageHash != null) {
          final perceptualHash = imageHash;
          final contextAwareContentHash = _buildContextAwareContentHash(
            contentHash,
            region: analysisRegion,
            language: analysisLang,
            provider: 'openai',
            model: ApiConfig.primaryModel,
          );
          final contextAwareCacheKey = buildContextualCacheKey(
            imageHash: perceptualHash,
            region: analysisRegion,
            language: analysisLang,
            provider: 'openai',
            model: ApiConfig.primaryModel,
          );
          final cachedResult = await cacheService.getCachedClassification(
            contextAwareCacheKey,
            contentHash: contextAwareContentHash,
          );
          if (cachedResult != null) {
            return Future.value(cachedResult.classification
                .copyWith(id: currentClassificationId));
          }
        }
      }

      // Try OpenAI first with compression
      try {
        final result = await _analyzeWithOpenAI(
          imageBytes,
          savedImagePath,
          analysisRegion,
          analysisLang,
          imageHash,
          currentClassificationId,
          contentHash: contentHash,
        );
        return result;
      } on Exception catch (openAiError, s) {
        // Short-circuit on production safety — no retry or Gemini fallback.
        if (openAiError is ProductionSafetyException) {
          WasteAppLogger.warning(
              '[AI SAFETY] Client-side AI blocked in release build (web).');
          rethrow;
        }

        WasteAppLogger.severe('OpenAI analysis failed for web image',
            error: openAiError, stackTrace: s);

        final failureKind =
            openAiError is AiFailure ? openAiError.kind : AiFailureKind.unknown;

        if (failureKind == AiFailureKind.cancelled ||
            failureKind == AiFailureKind.unsafeClientAiBlocked ||
            failureKind == AiFailureKind.auth ||
            failureKind == AiFailureKind.budgetExceeded) {
          rethrow;
        }

        if (_shouldFallbackToGemini(failureKind, retryCount, maxRetries)) {
          WasteAppLogger.info('Falling back to Gemini analysis for web image.');
          final result = await _analyzeWithGemini(
            imageBytes,
            savedImagePath,
            analysisRegion,
            analysisLang,
            imageHash,
            currentClassificationId,
            contentHash: contentHash,
          );
          return result;
        }

        // For other errors, retry with OpenAI
        if (retryCount < maxRetries) {
          final waitTime =
              Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          await Future.delayed(waitTime);
          return analyzeWebImage(
            imageBytes,
            imageName,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            region: region,
            instructionsLang: instructionsLang,
            classificationId: currentClassificationId,
          );
        }

        rethrow;
      }
    } catch (e, s) {
      if (e is ProductionSafetyException) rethrow;
      if (e is AiFailure && _isTerminalFailureKind(e.kind)) rethrow;
      WasteAppLogger.severe('Top-level web analysis failed',
          error: e, stackTrace: s);
      // Ensure fallback also uses the consistent ID
      return WasteClassification.fallback(
        imageName,
        id: currentClassificationId,
      );
    }
  }

  /// Analyzes multiple manually selected rectangular regions from an image.
  /// Each region is cropped and analyzed sequentially.
  /// Returns a list of [WasteClassification] results, one per region.
  Future<List<WasteClassification>> analyzeImageRegions(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> regionBounds, {
    String? region,
    String? instructionsLang,
  }) async {
    final results = <WasteClassification>[];
    for (var i = 0; i < regionBounds.length; i++) {
      final bounds = regionBounds[i];
      try {
        final classification = await _analyzeSingleRegion(
          imageBytes,
          imageName,
          bounds,
          region: region,
          instructionsLang: instructionsLang,
        );
        results.add(classification);
      } catch (e, s) {
        WasteAppLogger.warning(
          'Region analysis failed; returning fallback for region',
          error: e,
          stackTrace: s,
          context: {'region_index': i, 'image': imageName},
        );
        final fallback = WasteClassification.fallback(imageName);
        results.add(
          fallback.copyWith(
            suggestedAction:
                'Could not classify selected region ${i + 1}. Please retake a clearer image or manually review.',
          ),
        );
      }
    }
    return results;
  }

  /// Analyzes a single cropped region from a mobile [File].
  Future<WasteClassification> analyzeImageRegion(
    File imageFile,
    Map<String, dynamic> regionBounds, {
    String? region,
    String? instructionsLang,
  }) async {
    final permanentPath = await _imageService.saveFilePermanently(imageFile);
    final permanentFile = File(permanentPath);
    final imageBytes = await permanentFile.readAsBytes();
    return _analyzeSingleRegion(
      imageBytes,
      permanentFile.path,
      regionBounds,
      region: region,
      instructionsLang: instructionsLang,
    );
  }

  /// Analyzes a single cropped region from web [Uint8List].
  Future<WasteClassification> analyzeWebImageRegion(
    Uint8List imageBytes,
    String imageName,
    Map<String, dynamic> regionBounds, {
    String? region,
    String? instructionsLang,
  }) async {
    return _analyzeSingleRegion(
      imageBytes,
      imageName,
      regionBounds,
      region: region,
      instructionsLang: instructionsLang,
    );
  }

  /// Internal: crops a single region and analyzes it with OpenAI.
  Future<WasteClassification> _analyzeSingleRegion(
    Uint8List imageBytes,
    String imageName,
    Map<String, dynamic> bounds, {
    String? region,
    String? instructionsLang,
  }) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image for region analysis.');
    }

    final imageWidth = originalImage.width;
    final imageHeight = originalImage.height;

    final x = ((bounds['x'] as num).toDouble() * imageWidth / 100).round();
    final y = ((bounds['y'] as num).toDouble() * imageHeight / 100).round();
    final width =
        ((bounds['width'] as num).toDouble() * imageWidth / 100).round();
    final height =
        ((bounds['height'] as num).toDouble() * imageHeight / 100).round();

    final clampedX = x.clamp(0, imageWidth - 1);
    final clampedY = y.clamp(0, imageHeight - 1);
    final clampedWidth = width.clamp(1, imageWidth - clampedX);
    final clampedHeight = height.clamp(1, imageHeight - clampedY);

    final croppedImage = img.copyCrop(
      originalImage,
      x: clampedX,
      y: clampedY,
      width: clampedWidth,
      height: clampedHeight,
    );

    final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));

    WasteAppLogger.info('Analyzing single cropped region.');
    WasteAppLogger.info(
        'Cropped image size: ${(croppedBytes.length / 1024).toStringAsFixed(2)} KB');

    return _analyzeWithOpenAI(
      croppedBytes,
      imageName,
      region ?? defaultRegion,
      instructionsLang ?? defaultLanguage,
      null,
      const Uuid().v4(),
    );
  }

  /// Analyzes an image using the OpenAI API.
  ///
  /// Compresses the image if necessary, constructs the request,
  /// and processes the response. Caches the result if successful.
  /// Includes cost tracking and enhanced error handling.
  Future<WasteClassification> _analyzeWithOpenAI(
    Uint8List imageBytes,
    String imageName,
    String region,
    String language,
    String? imageHash,
    String classificationId, {
    String? contentHash,
    String? thumbnailPath,
  }) async {
    _providerCallCount++;
    ProductionSafetyConfig.guardClientAiCall('OpenAI');
    const providerName = 'openai';
    const modelName = ApiConfig.primaryModel;
    final modelKey =
        ApiConfig.primaryModel.replaceAll('-', '_').replaceAll('.', '_');
    final startTime = DateTime.now();

    final canAffordInstant =
        guardrailService.canUseInstantAnalysis(model: modelKey);
    if (!canAffordInstant) {
      throw AiFailure(
        AiFailureKind.budgetExceeded,
        'Budget exceeded - instant analysis not available. Please use batch mode.',
        provider: providerName,
        model: modelName,
      );
    }

    final compressedBytes = await _compressImageForOpenAI(imageBytes);
    final mimeType = _detectImageMimeType(compressedBytes);

    if (ProductionSafetyConfig.hasPlaceholderKey(openAiApiKey)) {
      throw AiFailure(
        AiFailureKind.auth,
        'OpenAI analysis blocked: placeholder/missing API key.',
        provider: providerName,
        model: modelName,
      );
    }

    final openAiBody = <String, dynamic>{
      'model': modelName,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Instructions language: $language\n- Image source: web upload',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url':
                    'data:$mimeType;base64,${_bytesToBase64(compressedBytes)}'
              }
            }
          ]
        }
      ],
      'max_tokens': 1500,
      'temperature': 0.1,
    };

    late final Response providerResponse;
    try {
      providerResponse = await _dio.post(
        '$openAiBaseUrl/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiApiKey',
          },
        ),
        data: openAiBody,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      _handleDioException(e, provider: providerName, model: modelName);
      rethrow;
    }

    if (providerResponse.statusCode != 200) {
      throw AiFailure(
        AiFailureKind.provider,
        'OpenAI response failed with status ${providerResponse.statusCode}',
        provider: providerName,
        model: modelName,
      );
    }

    final processingTime = DateTime.now().difference(startTime);
    final responseData = providerResponse.data as Map<String, dynamic>;
    final usage = responseData['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['prompt_tokens'] as int? ?? 1500;
    final outputTokens = usage?['completion_tokens'] as int? ?? 800;

    final cost = pricingService.calculateCost(
      model: modelKey,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    await guardrailService.recordApiSpending(
      model: modelKey,
      cost: cost,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    WasteAppLogger.info('API cost recorded', context: {
      'service': 'ai_service',
      'model': modelKey,
      'cost': cost,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'processing_time_ms': processingTime.inMilliseconds,
    });

    var classification = _processAiResponseData(
      responseData,
      imageName,
      region,
      language,
      null,
      classificationId,
      provider: providerName,
      model: modelName,
      thumbnailPath: thumbnailPath,
    );

    final policyDecision = await localPolicyEngine.applyPolicy(
      classification: classification,
      region: region,
    );
    classification = _attachPolicyDecisionMetadata(
      policyDecision.classification,
      policyDecision,
    );

    if (cachingEnabled && imageHash != null) {
      final contextAwareContentHash = _buildContextAwareContentHash(
        contentHash,
        region: region,
        language: language,
        provider: providerName,
        model: modelName,
      );
      final contextAwareCacheKey = buildContextualCacheKey(
        imageHash: imageHash,
        region: region,
        language: language,
        provider: providerName,
        model: modelName,
      );
      await cacheService.cacheClassification(
        contextAwareCacheKey,
        classification,
        contentHash: contextAwareContentHash,
        imageSize: imageBytes.length,
        entryImageHash: imageHash,
      );
    }

    return classification;
  }

  /// Analyzes an image using the Gemini API.
  ///
  /// Used as a fallback if OpenAI fails or the image is too large.
  /// Applies light compression if the image is excessively large even for Gemini.
  /// Converts Gemini's response format to the standard [WasteClassification] model.
  /// Caches the result if successful.
  Future<WasteClassification> _analyzeWithGemini(
    Uint8List imageBytes,
    String imageName,
    String region,
    String language,
    String? imageHash,
    String classificationId, {
    String? contentHash,
    String? thumbnailPath,
  }) async {
    _providerCallCount++;
    ProductionSafetyConfig.guardClientAiCall('Gemini');
    const providerName = 'gemini';
    const modelName = ApiConfig.tertiaryModel;
    final startTime = DateTime.now();
    WasteAppLogger.info('Falling back to Gemini for analysis.');

    // Gemini can handle larger images, but still compress if extremely large
    var processedBytes = imageBytes;
    const geminiMaxSize = 50 * 1024 * 1024; // 50MB for Gemini (more generous)

    if (imageBytes.length > geminiMaxSize) {
      WasteAppLogger.warning(
          'Image exceeds Gemini max size, error: applying compression.');
      processedBytes = await _compressImageForGemini(imageBytes);
    }

    final base64Image = _bytesToBase64(processedBytes);
    final mimeType = _detectImageMimeType(processedBytes);

    if (ProductionSafetyConfig.hasPlaceholderKey(geminiApiKey)) {
      throw AiFailure(
        AiFailureKind.auth,
        'Gemini analysis blocked: placeholder/missing API key.',
        provider: providerName,
        model: modelName,
      );
    }

    WasteAppLogger.info(
        'Sending image to Gemini. Size: ${(processedBytes.length / 1024).toStringAsFixed(2)} KB');

    final requestBody = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {
              'text':
                  '$_systemPrompt\n\n$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Instructions language: $language\n- Image source: Gemini analysis (OpenAI fallback)'
            },
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image}
            }
          ]
        }
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1500}
    };

    late final Response response;
    try {
      response = await _dio.post(
        '$geminiBaseUrl/models/${ApiConfig.tertiaryModel}:generateContent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiApiKey,
          },
        ),
        data: requestBody,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      _handleDioException(e, provider: providerName, model: modelName);
      rethrow;
    }

    if (response.statusCode == 200) {
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      WasteAppLogger.info('Received successful response from Gemini.');
      final Map<String, dynamic> responseData = response.data;

      // Extract content from Gemini response format
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        final String content =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Extract token usage from Gemini response (if available)
        final usage = responseData['usageMetadata'] as Map<String, dynamic>?;
        final inputTokens =
            usage?['promptTokenCount'] ?? 1500; // Fallback estimate
        final outputTokens =
            usage?['candidatesTokenCount'] ?? 800; // Fallback estimate

        // Calculate and record cost for Gemini
        const modelKey = 'gemini_2_0_flash';
        final cost = pricingService.calculateCost(
          model: modelKey,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );

        // Record spending in guardrail service
        await guardrailService.recordApiSpending(
          model: modelKey,
          cost: cost,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );

        WasteAppLogger.info('Gemini API cost recorded', context: {
          'service': 'ai_service',
          'model': modelKey,
          'cost': cost,
          'input_tokens': inputTokens,
          'output_tokens': outputTokens,
          'processing_time_ms': processingTime.inMilliseconds,
        });

        // Convert Gemini response to OpenAI format for processing
        final openAiFormat = <String, dynamic>{
          'choices': [
            {
              'message': {'content': content}
            }
          ]
        };

        var classification = _processAiResponseData(
          openAiFormat,
          imageName,
          region,
          language,
          null,
          classificationId,
          provider: providerName,
          model: modelName,
          thumbnailPath: thumbnailPath,
        );

        // Apply Enhanced AI Analysis v2.0 - Local Guidelines
        final policyDecision = await localPolicyEngine.applyPolicy(
          classification: classification,
          region: region,
        );
        classification = _attachPolicyDecisionMetadata(
          policyDecision.classification,
          policyDecision,
        );

        // Cache the result if we have a valid hash
        if (cachingEnabled && imageHash != null) {
          final contextAwareContentHash = _buildContextAwareContentHash(
            contentHash,
            region: region,
            language: language,
            provider: providerName,
            model: modelName,
          );
          final contextAwareCacheKey = buildContextualCacheKey(
            imageHash: imageHash,
            region: region,
            language: language,
            provider: providerName,
            model: modelName,
          );
          await cacheService.cacheClassification(
            contextAwareCacheKey,
            classification,
            contentHash: contextAwareContentHash,
            imageSize: imageBytes.length,
            entryImageHash: imageHash,
          );
        }

        return classification;
      } else {
        throw AiFailure(
          AiFailureKind.malformedProviderResponse,
          'Invalid Gemini response format',
          provider: providerName,
          model: modelName,
        );
      }
    } else {
      throw AiFailure(
        _failureKindFromStatus(response.statusCode ?? 0),
        'Gemini API Error ${response.statusCode}: ${response.data}',
        provider: providerName,
        model: modelName,
      );
    }
  }

  /// Handles user corrections/disagreements by re-analyzing the item.
  ///
  /// This method is designed to take a user's feedback (correction or reason
  /// for disagreement) and use it to prompt the AI for a refined classification.
  /// It preserves the original classification details and updates only what's
  /// necessary based on the AI's re-analysis.
  Future<WasteClassification> handleUserCorrection(
    WasteClassification originalClassification,
    String userCorrection,
    String? userReason, {
    String? model,
    List<String>? reanalysisModelsTried,
  }) async {
    ProductionSafetyConfig.guardClientAiCall('AI correction');

    WasteAppLogger.info('Operation completed',
        context: {'service': 'ai', 'file': 'ai_service'});

    // Determine which model to use for re-analysis
    final sourceValue = (originalClassification.source ?? '').toLowerCase();
    final modelSourceValue =
        (originalClassification.modelSource ?? '').toLowerCase();
    final useGeminiProvider = sourceValue.startsWith('ai_analysis_gemini') ||
        modelSourceValue.contains('gemini');
    final modelToUse = model ??
        (useGeminiProvider ? ApiConfig.tertiaryModel : ApiConfig.primaryModel);

    try {
      final imageUrl = originalClassification.imageUrl;
      Uint8List? imageBytes;

      // If imageUrl is a file path (mobile), read bytes
      if (imageUrl != null && !kIsWeb) {
        final safeLocalPath =
            await _imageService.resolveTrustedLocalPath(imageUrl);
        if (safeLocalPath != null && File(safeLocalPath).existsSync()) {
          imageBytes = await File(safeLocalPath).readAsBytes();
        }
      }
      // If imageUrl is a data URL (web), parse bytes
      else if (imageUrl != null &&
          kIsWeb &&
          imageUrl.startsWith('data:image')) {
        imageBytes = ImageUtils.dataUrlToBytes(imageUrl);
      }
      // If no image bytes, try to fetch from web if it's a standard URL
      else if (imageUrl != null && (imageUrl.startsWith('http'))) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        } else {
          WasteAppLogger.severe('Error occurred');
        }
      }

      if (imageBytes == null) {
        WasteAppLogger.info('Operation completed',
            context: {'service': 'ai', 'file': 'ai_service'});
        throw ArgumentError('No trusted image source available for correction');
      }

      final base64Image = _bytesToBase64(imageBytes);
      final mimeType = _detectImageMimeType(imageBytes);

      final correctionPrompt = _getCorrectionPrompt(
          originalClassification.toJson(), userCorrection, userReason);

      late final Response response;
      try {
        if (useGeminiProvider) {
          if (ProductionSafetyConfig.hasPlaceholderKey(geminiApiKey)) {
            throw AiFailure(
              AiFailureKind.auth,
              'Gemini correction blocked: placeholder/missing API key.',
              provider: 'gemini',
              model: modelToUse,
            );
          }
          final geminiBody = <String, dynamic>{
            'contents': [
              {
                'parts': [
                  {'text': '$_systemPrompt\n\n$correctionPrompt'},
                  {
                    'inline_data': {'mime_type': mimeType, 'data': base64Image}
                  }
                ]
              }
            ],
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1500}
          };
          response = await _dio.post(
            '$geminiBaseUrl/models/$modelToUse:generateContent',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': geminiApiKey,
              },
            ),
            data: geminiBody,
            cancelToken: _cancelToken,
          );
        } else {
          if (ProductionSafetyConfig.hasPlaceholderKey(openAiApiKey)) {
            throw AiFailure(
              AiFailureKind.auth,
              'OpenAI correction blocked: placeholder/missing API key.',
              provider: 'openai',
              model: modelToUse,
            );
          }
          final openAiBody = <String, dynamic>{
            'model': modelToUse,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': correctionPrompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
                  }
                ]
              }
            ],
            'max_tokens': 1500,
            'temperature': 0.1
          };
          response = await _dio.post(
            '$openAiBaseUrl/chat/completions',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $openAiApiKey',
              },
            ),
            data: openAiBody,
            cancelToken: _cancelToken,
          );
        }
      } on DioException catch (e) {
        _handleDioException(
          e,
          provider: useGeminiProvider ? 'gemini' : 'openai',
          model: modelToUse,
        );
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;
        if (useGeminiProvider) {
          final candidates = responseData['candidates'] as List<dynamic>?;
          final content = candidates != null &&
                  candidates.isNotEmpty &&
                  candidates.first['content'] != null &&
                  candidates.first['content']['parts'] != null &&
                  (candidates.first['content']['parts'] as List).isNotEmpty
              ? candidates.first['content']['parts'][0]['text'] as String?
              : null;
          if (content == null || content.isEmpty) {
            throw AiFailure(
              AiFailureKind.malformedProviderResponse,
              'Gemini correction response missing content',
              provider: 'gemini',
              model: modelToUse,
            );
          }
          responseData = {
            'choices': [
              {
                'message': {'content': content}
              }
            ]
          };
        }
        final correctedClassification = _processAiResponseData(
          responseData,
          originalClassification.imageUrl ?? 'correction_update',
          originalClassification.region,
          originalClassification.instructionsLang,
          reanalysisModelsTried,
          originalClassification.id,
          provider: useGeminiProvider ? 'gemini' : 'openai',
          model: modelToUse,
        );

        return applyCorrectionProvenance(
          corrected: correctedClassification,
          original: originalClassification,
          provider: useGeminiProvider ? 'gemini' : 'openai',
          model: modelToUse,
          userCorrection: userCorrection,
        );
      } else {
        throw AiFailure(
          _failureKindFromStatus(response.statusCode ?? 0),
          'Failed to process correction: ${response.statusCode}',
          provider: useGeminiProvider ? 'gemini' : 'openai',
          model: modelToUse,
        );
      }
    } catch (e, s) {
      if (e is ProductionSafetyException) rethrow;
      if (e is AiFailure && _isTerminalFailureKind(e.kind)) rethrow;
      WasteAppLogger.severe('Correction flow failed',
          error: e,
          stackTrace: s,
          context: {
            'model': modelToUse,
            'provider': useGeminiProvider ? 'gemini' : 'openai',
            'classification_id': originalClassification.id,
          });
      // Return original classification with user correction noted
      return originalClassification.copyWith(
        userCorrection: userCorrection,
        disagreementReason: 'Failed to process correction.',
        clarificationNeeded: true,
      );
    }
  }

  /// Processes the raw AI response data (from OpenAI or Gemini) to extract a [WasteClassification].
  ///
  /// Attempts to parse the JSON content from the AI's response.
  /// Includes logic to remove markdown formatting and extract the JSON object
  /// if it's embedded in other text. Uses [cleanJsonString] for preprocessing.
  /// If direct parsing fails, it attempts a fallback partial extraction via [_createFallbackClassification].
  WasteClassification _processAiResponseData(
    Map<String, dynamic> responseData,
    String imagePath,
    String region,
    String? instructionsLang,
    List<String>? reanalysisModelsTried,
    String? classificationId, {
    required String provider,
    required String model,
    String? thumbnailPath,
  }) {
    try {
      if (responseData['choices'] != null &&
          responseData['choices'].isNotEmpty) {
        final choice = responseData['choices'][0];
        if (choice['message'] != null && choice['message']['content'] != null) {
          final String content = choice['message']['content'];

          final jsonString = cleanJsonString(content);

          Map<String, dynamic> jsonContent;
          try {
            jsonContent = jsonDecode(jsonString);

            return _createClassificationFromJsonContent(
              jsonContent,
              imagePath,
              region,
              instructionsLang,
              reanalysisModelsTried,
              classificationId,
              provider: provider,
              model: model,
              thumbnailPath: thumbnailPath,
            );
          } catch (jsonError) {
            WasteAppLogger.severe(
              'Failed to decode provider response JSON',
              error: jsonError,
              context: {
                'provider': provider,
                'model': model,
                'classification_id': classificationId,
              },
            );

            // Try to extract basic info even if full parsing fails
            return _createFallbackClassification(
              content,
              imagePath,
              region,
              provider: provider,
              model: model,
              classificationId: classificationId,
            );
          }
        }
      }
    } catch (e, s) {
      WasteAppLogger.severe('AI response processing failed',
          error: e,
          stackTrace: s,
          context: {
            'provider': provider,
            'model': model,
            'classification_id': classificationId,
          });
      // Ensure fallback also uses the consistent ID
      return WasteClassification.fallback(imagePath, id: classificationId);
    }

    // Fallback for unexpected response structure
    WasteAppLogger.severe('Error occurred');
    return WasteClassification.fallback(imagePath, id: classificationId);
  }

  /// Extracts potential JSON content from a raw AI response string.
  ///
  /// This handles cases where the AI might embed the JSON within markdown code blocks
  /// (e.g., ```json ... ```) or include extraneous text before or after the JSON.
  /// Also strips C/C++ style comments that can cause JSON parsing to fail.
  @visibleForTesting
  String cleanJsonString(String rawContent) {
    // Attempt to find content within a JSON markdown block
    final jsonCodeBlockRegExp =
        RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true);
    final Match? match = jsonCodeBlockRegExp.firstMatch(rawContent);

    String jsonString;
    if (match != null && match.group(1) != null) {
      jsonString = match.group(1)!.trim();
    } else {
      // Fallback: Try to find the first and last curly braces to extract a JSON object
      final firstCurly = rawContent.indexOf('{');
      final lastCurly = rawContent.lastIndexOf('}');

      if (firstCurly != -1 && lastCurly != -1 && lastCurly > firstCurly) {
        jsonString = rawContent.substring(firstCurly, lastCurly + 1).trim();
      } else {
        // If no JSON-like structure is found, return the original content (may lead to parsing error)
        jsonString = rawContent;
      }
    }

    // Strip C/C++ style comments that can cause JSON parsing to fail
    // Remove single-line comments (// comment)
    jsonString = jsonString.replaceAll(RegExp(r'//.*'), '');

    // Remove multi-line comments (/* comment */)
    jsonString = jsonString.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    return jsonString.trim();
  }

  /// Parses disposal instructions safely from dynamic input.
  /// Handles various formats including maps, strings, and lists.
  DisposalInstructions _parseDisposalInstructions(
      dynamic jsonDisposalInstructions) {
    if (jsonDisposalInstructions == null) {
      return DisposalInstructions(
        primaryMethod: 'Review required',
        steps: ['Please review manually'],
        hasUrgentTimeframe: false,
      );
    }

    if (jsonDisposalInstructions is Map) {
      try {
        return DisposalInstructions.fromJson(
            Map<String, dynamic>.from(jsonDisposalInstructions));
      } catch (e) {
        WasteAppLogger.severe('Error occurred');
        // Fallback to basic instructions if map parsing fails
        return DisposalInstructions(
          primaryMethod:
              jsonDisposalInstructions['primaryMethod']?.toString() ??
                  'Review required',
          steps: _parseStepsFromString(
              jsonDisposalInstructions['steps']?.toString() ?? ''),
          hasUrgentTimeframe: false,
        );
      }
    } else if (jsonDisposalInstructions is String) {
      // If it's a string, try to parse it as simple instructions
      return DisposalInstructions(
        primaryMethod: jsonDisposalInstructions.isNotEmpty
            ? jsonDisposalInstructions
            : 'Review required',
        steps: _parseStepsFromString(jsonDisposalInstructions),
        hasUrgentTimeframe: false,
      );
    } else if (jsonDisposalInstructions is List) {
      // If it's a list, treat the first element as primary method and others as steps
      final primaryMethod = jsonDisposalInstructions.isNotEmpty
          ? jsonDisposalInstructions[0].toString()
          : 'Review required';
      final steps = jsonDisposalInstructions.map((e) => e.toString()).toList();
      return DisposalInstructions(
        primaryMethod: primaryMethod,
        steps: steps,
        hasUrgentTimeframe: false,
      );
    }

    // Default fallback
    return DisposalInstructions(
      primaryMethod: 'Review required',
      steps: ['Please review manually'],
      hasUrgentTimeframe: false,
    );
  }

  /// Parses alternative classifications safely from dynamic input.
  List<AlternativeClassification> _parseAlternatives(dynamic alternativesJson) {
    if (alternativesJson == null) return [];
    if (alternativesJson is List) {
      return alternativesJson
          .map((alt) {
            try {
              return AlternativeClassification.fromJson(
                  alt as Map<String, dynamic>);
            } catch (e) {
              WasteAppLogger.severe('Error occurred');
              return null; // Return null for invalid entries
            }
          })
          .whereType<AlternativeClassification>() // Filter out nulls
          .toList();
    }
    return [];
  }

  /// Creates a [WasteClassification] object from a parsed JSON map.
  ///
  /// This method uses several safe parsing helpers (e.g., [_safeStringParse],
  /// [_parseRecyclingCode], [_parseBool]) to robustly handle potentially
  /// malformed or missing fields in the AI's JSON response.
  /// It defaults to sensible values if parsing fails for specific fields.
  WasteClassification _createClassificationFromJsonContent(
    Map<String, dynamic> jsonContent,
    String imagePath,
    String region,
    String? instructionsLang,
    List<String>? reanalysisModelsTried,
    String? classificationId, {
    required String provider,
    required String model,
    String? thumbnailPath,
  }) {
    try {
      final disposalInstructions =
          _parseDisposalInstructions(jsonContent['disposalInstructions']);
      final alternatives = _parseAlternatives(jsonContent['alternatives']);

      // 🔧 ENHANCED ITEM NAME PARSING: Handle null itemName from AI
      var itemName = _safeStringParse(jsonContent['itemName']) ?? '';

      if (itemName.isEmpty || itemName == 'null') {
        WasteAppLogger.info(
            'AI response contained empty or null itemName. Attempting extraction from other fields.',
            context: {'jsonContent': jsonContent});
        // Try to extract item name from explanation or subcategory
        final explanation = _safeStringParse(jsonContent['explanation']) ?? '';
        final subcategory = _safeStringParse(jsonContent['subcategory']) ?? '';
        final category = _safeStringParse(jsonContent['category']) ?? '';

        // Try to extract from explanation first
        if (explanation.isNotEmpty) {
          // Look for patterns like "The image shows [item]" or "This is [item]"
          final patterns = [
            RegExp(
                r'(?:shows?|depicts?|contains?|is)\s+(?:an?|the)?\s*([^.]+?)(?:\\s+(?:which|that|in|on)|\\.|$)',
                caseSensitive: false),
            RegExp(
                r'(?:This|It)\\s+(?:appears to be|looks like|is)\\s+(?:an?|the)?\\s*([^.]+?)(?:\\s+(?:which|that|in|on)|\\.|$)',
                caseSensitive: false),
          ];

          for (final pattern in patterns) {
            final match = pattern.firstMatch(explanation);
            if (match != null && match.group(1) != null) {
              final extractedName = match.group(1)!.trim();
              if (extractedName.isNotEmpty && extractedName.length < 50) {
                itemName = extractedName;
                WasteAppLogger.info('Extracted itemName from explanation.',
                    context: {
                      'extractedName': itemName,
                      'explanation': explanation
                    });
                break;
              }
            }
          }
        }

        // Fallback to subcategory if still empty
        if (itemName.isEmpty && subcategory.isNotEmpty) {
          itemName = subcategory;
          WasteAppLogger.info('Falling back to subcategory for itemName.',
              context: {'subcategory': itemName});
        }

        // Final fallback to category
        if (itemName.isEmpty && category.isNotEmpty) {
          itemName = category;
          WasteAppLogger.info('Falling back to category for itemName.',
              context: {'category': itemName});
        }

        // Last resort fallback
        if (itemName.isEmpty) {
          itemName = 'Unidentified Item - Fallback';
          WasteAppLogger.warning(
              'Could not extract itemName from AI response; defaulting to "Unidentified Item - Fallback".',
              context: {'jsonContent': jsonContent});
        }
      }

      // Extract relative path from absolute image path
      String? imageRelativePath;
      if (imagePath.contains('/images/')) {
        final index = imagePath.indexOf('/images/');
        imageRelativePath =
            imagePath.substring(index + 1); // Remove leading slash
      } else if (imagePath.contains('\\images\\')) {
        final index = imagePath.indexOf('\\images\\');
        imageRelativePath =
            imagePath.substring(index + 1).replaceAll('\\', '/');
      } else if (imagePath.contains('.jpg') ||
          imagePath.contains('.png') ||
          imagePath.contains('.jpeg') ||
          imagePath.contains('.webp')) {
        final fileName = imagePath.split('/').last.split('\\').last;
        imageRelativePath = 'images/$fileName';
      }

      // Extract thumbnail relative path from absolute thumbnail path
      String? thumbnailRelativePath;
      if (thumbnailPath != null) {
        if (thumbnailPath.contains('/thumbnails/')) {
          final index = thumbnailPath.indexOf('/thumbnails/');
          thumbnailRelativePath =
              thumbnailPath.substring(index + 1); // Remove leading slash
        } else if (thumbnailPath.contains('\\thumbnails\\')) {
          final index = thumbnailPath.indexOf('\\thumbnails\\');
          thumbnailRelativePath =
              thumbnailPath.substring(index + 1).replaceAll('\\', '/');
        } else if (thumbnailPath.contains('.jpg') ||
            thumbnailPath.contains('.png') ||
            thumbnailPath.contains('.jpeg') ||
            thumbnailPath.contains('.webp')) {
          final fileName = thumbnailPath.split('/').last.split('\\').last;
          thumbnailRelativePath = 'thumbnails/$fileName';
        }
      }

      // Create the classification with all fields
      final classification = WasteClassification(
        id: classificationId,
        itemName: itemName,
        category: _safeStringParse(jsonContent['category']) ??
            'Requires Manual Review',
        subcategory: _safeStringParse(jsonContent['subcategory']),
        materialType: _safeStringParse(jsonContent['materialType']),
        recyclingCode: _parseRecyclingCode(jsonContent['recyclingCode']),
        explanation: _safeStringParse(jsonContent['explanation']) ??
            'No explanation provided',
        disposalMethod: _safeStringParse(jsonContent['disposalMethod']),
        disposalInstructions: disposalInstructions,
        region: region,
        localGuidelinesReference:
            _safeStringParse(jsonContent['localGuidelinesReference']),
        imageUrl: imagePath,
        imageRelativePath: imageRelativePath,
        thumbnailRelativePath: thumbnailRelativePath,
        visualFeatures: _parseStringListSafely(jsonContent['visualFeatures']),
        isRecyclable: _parseBool(jsonContent['isRecyclable']),
        isCompostable: _parseBool(jsonContent['isCompostable']),
        requiresSpecialDisposal:
            _parseBool(jsonContent['requiresSpecialDisposal']),
        isSingleUse: _parseBool(jsonContent['isSingleUse']),
        colorCode: _safeStringParse(jsonContent['colorCode']),
        riskLevel: _safeStringParse(jsonContent['riskLevel']),
        requiredPPE: _parseStringListSafely(jsonContent['requiredPPE']),
        brand: _safeStringParse(jsonContent['brand']),
        product: _safeStringParse(jsonContent['product']),
        barcode: _safeStringParse(jsonContent['barcode']),
        confidence: _parseDouble(jsonContent['confidence']),
        clarificationNeeded: _parseBool(jsonContent['clarificationNeeded']),
        alternatives: alternatives,
        suggestedAction: _safeStringParse(jsonContent['suggestedAction']),
        hasUrgentTimeframe: _parseBool(jsonContent['hasUrgentTimeframe']),
        instructionsLang: _safeStringParse(jsonContent['instructionsLang']),
        translatedInstructions:
            _parseStringMapSafely(jsonContent['translatedInstructions']),
        modelVersion: _safeStringParse(jsonContent['modelVersion']),
        modelSource:
            _safeStringParse(jsonContent['modelSource']) ?? '$provider-$model',
        processingTimeMs: _parseInt(jsonContent['processingTimeMs']),
        analysisSessionId: _safeStringParse(jsonContent['analysisSessionId']),
        disagreementReason: _safeStringParse(jsonContent['disagreementReason']),
        environmentalImpact:
            _safeStringParse(jsonContent['environmentalImpact']),
        relatedItems: _parseStringListSafely(jsonContent['relatedItems']),
        source: 'ai_analysis_$provider',
        reanalysisModelsTried: reanalysisModelsTried,
        // Enhanced AI Analysis v2.0 fields
        recyclability: _safeStringParse(jsonContent['recyclability']),
        hazardLevel: _parseInt(jsonContent['hazardLevel']),
        co2Impact: _parseDouble(jsonContent['co2Impact']),
        decompositionTime: _safeStringParse(jsonContent['decompositionTime']),
        properEquipment: _parseStringListSafely(jsonContent['properEquipment']),
        materials: _parseStringListSafely(jsonContent['materials']),
        subCategory: _safeStringParse(jsonContent['subCategory']),
        commonUses: _parseStringListSafely(jsonContent['commonUses']),
        alternativeOptions:
            _parseStringListSafely(jsonContent['alternativeOptions']),
        localRegulations:
            _parseStringMapSafely(jsonContent['localRegulations']),
        waterPollutionLevel: _parseInt(jsonContent['waterPollutionLevel']),
        soilContaminationRisk: _parseInt(jsonContent['soilContaminationRisk']),
        biodegradabilityDays: _parseInt(jsonContent['biodegradabilityDays']),
        recyclingEfficiency: _parseInt(jsonContent['recyclingEfficiency']),
        manufacturingEnergyFootprint:
            _parseDouble(jsonContent['manufacturingEnergyFootprint']),
        transportationFootprint:
            _parseDouble(jsonContent['transportationFootprint']),
        endOfLifeCost: _safeStringParse(jsonContent['endOfLifeCost']),
        circularEconomyPotential:
            _parseStringListSafely(jsonContent['circularEconomyPotential']),
        generatesMicroplastics:
            _parseBool(jsonContent['generatesMicroplastics']),
        humanToxicityLevel: _parseInt(jsonContent['humanToxicityLevel']),
        wildlifeImpactSeverity:
            _parseInt(jsonContent['wildlifeImpactSeverity']),
        resourceScarcity: _safeStringParse(jsonContent['resourceScarcity']),
        disposalCostEstimate: _parseDouble(jsonContent['disposalCostEstimate']),
        bbmpComplianceStatus:
            _safeStringParse(jsonContent['bbmpComplianceStatus']),
        localGuidelinesVersion:
            _safeStringParse(jsonContent['localGuidelinesVersion']),
      );

      // Note: Local guidelines will be applied in the calling method since this is not async
      // The classification will be enhanced with local guidelines after creation

      // Calculate dynamic points based on classification richness
      final calculatedPoints = classification.calculatePoints();

      // Return classification with calculated points
      return classification.copyWith(pointsAwarded: calculatedPoints);
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      return _createFallbackClassification(
          jsonContent.toString(), imagePath, region,
          provider: provider, model: model, classificationId: classificationId);
    }
  }

  /// Safely parses a string value from a dynamic input.
  ///
  /// Returns null if the value is null or an empty/whitespace string.
  /// Otherwise, trims the string representation of the value.
  String? _safeStringParse(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  WasteClassification _attachPolicyDecisionMetadata(
    WasteClassification classification,
    LocalPolicyDecision decision,
  ) {
    if (!decision.policyApplied) {
      return classification;
    }

    final baseRegulations = Map<String, String>.from(
      classification.localRegulations ?? const <String, String>{},
    );

    if (decision.rulePackId != null) {
      baseRegulations['policy_rule_pack_id'] = decision.rulePackId!;
    }
    if (decision.pluginId != null) {
      baseRegulations['policy_plugin_id'] = decision.pluginId!;
    }
    if (decision.complianceStatus != null) {
      baseRegulations['policy_compliance_status'] = decision.complianceStatus!;
    }
    if (decision.warnings.isNotEmpty) {
      baseRegulations['policy_warning_count'] =
          decision.warnings.length.toString();
    }
    if (decision.violations.isNotEmpty) {
      baseRegulations['policy_violation_count'] =
          decision.violations.length.toString();
    }
    if (decision.recommendations.isNotEmpty) {
      baseRegulations['policy_recommendations'] =
          decision.recommendations.take(3).join(' | ');
    }
    baseRegulations['policy_evaluated_at'] =
        decision.evaluatedAt.toIso8601String();

    return classification.copyWith(
      localRegulations: baseRegulations,
      bbmpComplianceStatus:
          decision.complianceStatus ?? classification.bbmpComplianceStatus,
      localGuidelinesVersion:
          decision.guidelinesVersion ?? classification.localGuidelinesVersion,
    );
  }

  /// Safely parses a list of strings from a dynamic input.
  ///
  /// Handles nulls, single strings (comma-separated or not),
  /// JSON array strings, and actual lists. Returns an empty list on failure.
  List<String> _parseStringListSafely(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // Fallback to comma/semicolon split if JSON parsing fails
        }
      }
      return value
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Safely parses a map of strings from a dynamic input.
  Map<String, String>? _parseStringMapSafely(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, String>.fromEntries(value.entries
          .map((e) => MapEntry(e.key.toString(), e.value.toString())));
    }
    return null;
  }

  /// Safely parses a boolean value from dynamic input.
  ///
  /// Handles various representations of true/false (e.g., 1, 0, "true", "false").
  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  /// Safely parses an integer value from dynamic input.
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely parses a double value from dynamic input.
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely parses a recycling code from dynamic input.
  int? _parseRecyclingCode(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Extract digits from string (e.g., "PET (1)" -> 1)
      final numRegExp = RegExp(r'\d+');
      final Match? match = numRegExp.firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(0)!);
      }
    }
    return null;
  }

  /// Safely parses image metrics from a dynamic input.
  Map<String, double>? _parseImageMetrics(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, double>.fromEntries(value.entries.map(
          (e) => MapEntry(e.key.toString(), _parseDouble(e.value) ?? 0.0)));
    }
    return null;
  }

  /// Helper to parse steps from a string, handling various delimiters.
  static List<String> _parseStepsFromString(String stepsString) {
    if (stepsString.trim().isEmpty) {
      return ['Please review manually'];
    }

    var steps = <String>[];

    // Try newline separation first
    if (stepsString.contains('\n')) {
      steps = stepsString
          .split('\n')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    }
    // Try comma separation
    else if (stepsString.contains(',')) {
      steps = stepsString
          .split(',')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    }
    // Try semicolon separation
    else if (stepsString.contains(';')) {
      steps = stepsString
          .split(';')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    }
    // Try numbered list pattern (1. 2. 3.)
    else if (RegExp(r'\d+\.').hasMatch(stepsString)) {
      steps = stepsString
          .split(RegExp(r'\d+\.'))
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    }
    // Single step
    else {
      steps = [stepsString.trim()];
    }

    return steps.isNotEmpty ? steps : ['Please review manually'];
  }

  /// Creates a fallback [WasteClassification] when full JSON parsing fails.
  ///
  /// Attempts to extract basic information (itemName, category, explanation)
  /// from the raw content string using simple keyword matching and regex.
  /// Assigns moderate confidence and marks clarification as needed.
  WasteClassification _createFallbackClassification(
      String content, String imagePath, String region,
      {required String provider,
      required String model,
      String? classificationId}) {
    WasteAppLogger.severe(
        'Creating fallback classification due to JSON parsing error.',
        context: {
          'rawContent': content,
          'imagePath': imagePath,
          'region': region
        });

    // Try to extract basic information from the text
    var itemName = 'Unknown Item - Fallback';
    var category = 'Dry Waste';
    var explanation = 'Classification extracted from partial AI response.';

    // Basic text extraction
    final lines = content.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('itemname') || lowerLine.contains('item_name')) {
        final itemPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final itemMatch = itemPattern.firstMatch(line);
        if (itemMatch != null) {
          itemName = (itemMatch.group(1) ?? itemMatch.group(2)) ?? itemName;
        }
      } else if (lowerLine.contains('category')) {
        if (lowerLine.contains('wet')) {
          category = 'Wet Waste';
        } else if (lowerLine.contains('dry')) {
          category = 'Dry Waste';
        } else if (lowerLine.contains('hazardous')) {
          category = 'Hazardous Waste';
        } else if (lowerLine.contains('medical')) {
          category = 'Medical Waste';
        }
      } else if (lowerLine.contains('explanation')) {
        final explanationPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final explanationMatch = explanationPattern.firstMatch(line);
        if (explanationMatch != null) {
          explanation =
              (explanationMatch.group(1) ?? explanationMatch.group(2)) ??
                  explanation;
        }
      }
    }

    return WasteClassification.fallback(
      imagePath,
      id: classificationId,
    ).copyWith(
      itemName: itemName,
      category: category,
      explanation: explanation,
      source: 'ai_analysis_${provider}_fallback',
      modelSource: '$provider-$model',
      clarificationNeeded: true,
    );
  }

  /// Segment an image into regions for object detection
  ///
  /// This is a placeholder implementation that creates a simple grid-based segmentation.
  /// In a real implementation, this would use computer vision algorithms like:
  /// - Watershed segmentation
  /// - GrabCut algorithm
  /// - Deep learning models for semantic segmentation
  ///
  /// For now, it creates a 3x3 grid of segments to demonstrate the functionality.
  Future<List<Map<String, dynamic>>> segmentImage(dynamic imageSource) async {
    if (!enableDebugGridSegmentation) {
      throw UnsupportedError(
          'Segmentation is disabled in production. Enable debug grid segmentation explicitly for demo/testing.');
    }
    try {
      Uint8List imageBytes;

      // Handle different input types
      if (imageSource is File) {
        imageBytes = await imageSource.readAsBytes();
      } else if (imageSource is Uint8List) {
        imageBytes = imageSource;
      } else {
        throw Exception('Unsupported image source type');
      }

      // Decode the image to get dimensions
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image for segmentation');
      }

      WasteAppLogger.info(
        'Generating debug grid segments (not model-based segmentation)',
      );

      // Create a simple grid-based segmentation (3x3 grid)
      final segments = <Map<String, dynamic>>[];
      const segmentWidth =
          100.0 / segmentGridSize; // Percentage width per segment
      const segmentHeight =
          100.0 / segmentGridSize; // Percentage height per segment

      for (var row = 0; row < segmentGridSize; row++) {
        for (var col = 0; col < segmentGridSize; col++) {
          final x = col * segmentWidth;
          final y = row * segmentHeight;

          // Create segment data as Map<String, dynamic>
          final segment = <String, dynamic>{
            'id': row * segmentGridSize + col,
            'bounds': <String, dynamic>{
              'x': x,
              'y': y,
              'width': segmentWidth,
              'height': segmentHeight,
            },
            'confidence': 0.8 +
                (0.2 *
                    (row * segmentGridSize + col) /
                    (segmentGridSize *
                        segmentGridSize)), // Simulated confidence
            'label': 'Object ${row * segmentGridSize + col + 1}',
          };

          segments.add(segment);
        }
      }

      WasteAppLogger.cacheEvent('cache_operation', 'classification',
          context: {'service': 'ai', 'file': 'ai_service'});
      return segments;
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      rethrow;
    }
  }

  /// OPTIMIZATION: Dispose of resources to prevent memory leaks
  /// Should be called when the service is no longer needed
  void dispose() {
    _cancelToken?.cancel('Service disposed');
    _dio.close(force: true);
    pricingService.dispose();
    guardrailService.dispose();
    WasteAppLogger.info('AiService disposed: all resources released');
  }
}
