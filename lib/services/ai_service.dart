import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow, sqrt;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';
import '../services/cache_service.dart';
import 'enhanced_image_service.dart';
import 'package:uuid/uuid.dart';
import '../utils/waste_app_logger.dart';

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
    this.cachingEnabled = true,
    this.defaultRegion = 'Bangalore, IN',
    this.defaultLanguage = 'en',
  })  : openAiBaseUrl = openAiBaseUrl ?? ApiConfig.openAiBaseUrl,
        openAiApiKey = openAiApiKey ?? ApiConfig.openAiApiKey,
        geminiBaseUrl = geminiBaseUrl ?? ApiConfig.geminiBaseUrl,
        geminiApiKey = geminiApiKey ?? ApiConfig.apiKey,
        cacheService = cacheService ?? ClassificationCacheService();
  final String openAiBaseUrl;
  final String openAiApiKey;
  final String geminiBaseUrl;
  final String geminiApiKey;
  final ClassificationCacheService cacheService;

  // ✅ OPTIMIZATION: Add as class field to avoid creating new instances repeatedly
  final EnhancedImageService _imageService = EnhancedImageService();

  // Dio client for HTTP requests with cancellation support
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  // Simple segmentation parameters - can be adjusted based on needs
  static const int segmentGridSize = 3; // 3x3 grid for basic segmentation
  static const double minSegmentArea = 0.05; // Minimum 5% of image area
  static const int objectDetectionSegments = 9; // Maximum number of segments to return

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

    // Configure Dio with default timeouts
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
  }

  /// Prepares a new cancel token for the next analysis operation.
  /// Call this before starting any new analysis to reset cancellation state.
  void prepareCancelToken() {
    _cancelToken?.cancel('New analysis started');
    _cancelToken = CancelToken();
    WasteAppLogger.info('New analysis prepared, cancel token reset.');
  }

  /// Cancels any ongoing analysis operation.
  /// This will immediately abort in-flight HTTP requests.
  void cancelAnalysis() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User requested cancellation');
      WasteAppLogger.warning('Analysis cancelled by user.');
    }
  }

  /// Checks if the current operation has been cancelled.
  bool get isCancelled => _cancelToken?.isCancelled ?? false;

  /// Handles DioException and converts cancellation to a more user-friendly exception
  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      throw Exception('Analysis cancelled by user');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception('Connection timeout - please check your internet connection');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Request timeout - the server took too long to respond');
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw Exception('Upload timeout - failed to send image data');
    } else {
      throw Exception('Network error: ${e.message}');
    }
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

  /// Main classification prompt for analyzing waste items.
  ///
  /// Instructs the AI model to return a comprehensive, strictly formatted JSON object
  /// based on the provided image and context. Details the expected JSON structure
  /// and rules for classification.
  String get _mainClassificationPrompt => '''
Analyze the provided waste item (with optional image context) and return a comprehensive, strictly formatted JSON object matching the data model below.

Classification Hierarchy & Instructions:

1. Main category (exactly one):
   - Wet Waste (organic, compostable)
   - Dry Waste (recyclable)
   - Hazardous Waste (special handling)
   - Medical Waste (potentially contaminated)
   - Non-Waste (reusable, edible, donatable, etc.)

2. Subcategory: Most specific fit, based on local guidelines if available.
3. Material type: E.g., PET plastic, cardboard, metal, glass, food scraps.
4. Recycling code: For plastics (1–7), if identified.
5. Disposal method: Short instruction (e.g., "Rinse and recycle in blue bin").
6. Disposal instructions (object):
   - primaryMethod: Main recommended action
   - steps: Step-by-step list
   - timeframe: If urgent (e.g., "Immediate", "Within 24 hours")
   - location: Drop-off or bin type
   - warnings: Any safety or contamination warnings
   - tips: Helpful tips
   - recyclingInfo: Extra recycling info
   - estimatedTime: Time needed for disposal
   - hasUrgentTimeframe: Boolean

7. Risk & safety:
   - riskLevel: "safe", "caution", "hazardous"
   - requiredPPE: ["gloves", "mask"], if needed

8. Booleans:
   - isRecyclable, isCompostable, requiresSpecialDisposal, isSingleUse

9. Brand/product/barcode: If present/visible
10. Region/locale: City/country string (e.g., "$defaultRegion")
    - localGuidelinesReference: If possible (e.g., "BBMP 2024/5")

11. Visual features: Notable characteristics from the image (e.g., ["broken", "dirty", "label missing"])
12. Explanation: Detailed reasoning for decisions
13. Suggested action: E.g., "Recycle", "Compost", "Donate", etc.
14. Color code: Hex value for UI
15. Confidence: 0.0–1.0, with a brief note if confidence < 0.7
16. clarificationNeeded: Boolean if confidence < 0.7 or item ambiguous
17. Alternatives: Up to 2 alternative category/subcategory suggestions, each with confidence and reason
18. Model info:
    - modelVersion, modelSource, processingTimeMs, analysisSessionId (set to null if not provided)

19. Multilingual support:
    - If instructionsLang provided, output translated disposal instructions as translatedInstructions for ["hi", "kn"] as well as "en".
20. Gamification & Engagement:
    - pointsAwarded: An integer representing the points for this classification (typically 10).
    - environmentalImpact: A short sentence describing the positive or negative environmental impact of this item.
    - relatedItems: A list of up to 3 related items that are often found with this one.
21. User fields:
    - Set isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount to null unless provided in input context.

Rules:
- Reply with only the JSON object (no extra commentary).
- Use null for any unknown fields.
- Strictly match the field names and structure below.
- Do not hallucinate image URLs or user fields unless given.

Format the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, disposalInstructions, region, localGuidelinesReference, imageUrl, imageHash, imageMetrics, visualFeatures, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode, riskLevel, requiredPPE, brand, product, barcode, isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount, clarificationNeeded, confidence, modelVersion, processingTimeMs, modelSource, analysisSessionId, alternatives, suggestedAction, hasUrgentTimeframe, instructionsLang, translatedInstructions, pointsAwarded, isSingleUse, environmentalImpact, relatedItems
''';

  /// Correction/disagreement prompt for handling user feedback.
  ///
  /// Guides the AI to re-analyze an item based on user-provided corrections
  /// or disagreements, updating the classification and explaining changes.
  String _getCorrectionPrompt(Map<String, dynamic> previousClassification, String userCorrection, String? userReason) =>
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
    if (imageBytes.length >= 3 && imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) {
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
  Future<Uint8List> _compressImageForOpenAI(Uint8List imageBytes) async {
    const maxSizeBytes = 20 * 1024 * 1024; // 20MB OpenAI limit
    const preferredSizeBytes = 5 * 1024 * 1024; // 5MB preferred

    WasteAppLogger.info('Original image size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

    // If image is already smaller than preferred size, return as is
    if (imageBytes.length < preferredSizeBytes) {
      WasteAppLogger.info('Image is smaller than preferred size, no compression needed.');
      return imageBytes;
    }

    // Iteratively compress image until it's under the preferred size
    var quality = 95;
    var compressedBytes = imageBytes;
    while (compressedBytes.length > preferredSizeBytes && quality > 10) {
      try {
        final image = img.decodeImage(compressedBytes);
        if (image == null) {
          WasteAppLogger.severe('Failed to decode image for compression.');
          return compressedBytes; // Return original if decoding fails
        }

        compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
        WasteAppLogger.info(
            'Compressed image to ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB with quality $quality');

        quality -= 5;
      } catch (e, s) {
        WasteAppLogger.severe('Error during image compression', e, s);
        break; // Exit loop on error
      }
    }

    // Final check against OpenAI's hard limit
    if (compressedBytes.length > maxSizeBytes) {
      WasteAppLogger.warning('Image size after compression still exceeds 20MB limit. Further reduction needed.');
      // Consider resizing the image here as a fallback
    }

    return compressedBytes;
  }

  /// Compresses image [Uint8List] data for Gemini API if it's excessively large.
  /// Gemini has a more generous limit than OpenAI, so compression is lighter.
  Future<Uint8List> _compressImageForGemini(Uint8List imageBytes) async {
    const maxSizeBytes = 50 * 1024 * 1024; // 50MB for Gemini

    if (imageBytes.length <= maxSizeBytes) {
      return imageBytes; // No compression needed
    }

    WasteAppLogger.warning('Image exceeds Gemini max size, applying compression.');
    var image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Could not decode image for Gemini compression.');
    }

    // Scale down to fit within max size, maintaining aspect ratio
    final scale = sqrt(maxSizeBytes / imageBytes.length); // Approximate scaling factor
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );

    final List<int> compressedBytes = img.encodeJpg(image, quality: 80); // Maintain good quality
    WasteAppLogger.info(
        'Compressed image size for Gemini: ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

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
      WasteAppLogger.severe('Error saving image permanently', e, s);
      return WasteClassification.fallback(imageFile.path, id: currentClassificationId);
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

        if (imageHash == null || contentHash == null) {
          WasteAppLogger.severe('Failed to generate image hashes', null, null, {'hashes': hashes});
          throw Exception('Failed to generate required image hashes');
        }

        WasteAppLogger.info('Generated perceptual hash: $imageHash');
        WasteAppLogger.info('Generated content hash: $contentHash');

        final cachedResult = await cacheService.getCachedClassification(
          imageHash,
          contentHash: contentHash,
        );
        if (cachedResult != null) {
          WasteAppLogger.cacheEvent('cache_operation', 'classification',
              context: {'service': 'ai', 'file': 'ai_service'});
          return cachedResult.classification.copyWith(id: currentClassificationId);
        }

        WasteAppLogger.cacheEvent('cache_operation', 'classification',
            context: {'service': 'ai', 'file': 'ai_service'});
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
        WasteAppLogger.severe('OpenAI analysis failed', openAiError, s);

        // If it's an image size issue or OpenAI fails, try Gemini
        if (openAiError.toString().contains('too large') ||
            openAiError.toString().contains('compression failed') ||
            retryCount >= maxRetries) {
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
          final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          await Future.delayed(waitTime);
          return analyzeImage(
            permanentFile,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            region: region,
            instructionsLang: instructionsLang,
            classificationId: currentClassificationId, // Pass the same ID on retry
          );
        }

        rethrow;
      }
    } catch (e, s) {
      WasteAppLogger.severe('Top-level analysis failed', e, s);
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
      // Ensure WasteClassification.fallback sets clarificationNeeded = true and handles an optional reason.
      // If WasteClassification.fallback doesn't support a 'reason' parameter, it might need adjustment,
      // or this call simplified. For now, assuming it can take it or ignore it.
      final savedImagePath = await _imageService.saveImagePermanently(imageBytes, fileName: imageName);
      return WasteClassification.fallback(
        savedImagePath,
        id: currentClassificationId,
        // reason: 'Input image data was empty.', // Add reason if supported by fallback
      );
    }

    // ✅ OPTIMIZATION: Use singleton instance with error handling
    final String savedImagePath;
    try {
      savedImagePath = await _imageService.saveImagePermanently(imageBytes, fileName: imageName);
    } catch (e, s) {
      WasteAppLogger.severe('Error saving web image permanently', e, s);
      return WasteClassification.fallback(imageName, id: currentClassificationId);
    }

    try {
      // Check cache if enabled with dual-hash verification
      String? contentHash;
      if (cachingEnabled) {
        // Generate both hashes efficiently in isolate to prevent UI lag
        final hashes = await ImageUtils.generateDualHashes(imageBytes);
        imageHash = hashes['perceptualHash'];
        contentHash = hashes['contentHash'];

        if (imageHash == null || contentHash == null) {
          WasteAppLogger.severe('Failed to generate web image hashes', null, null, {'hashes': hashes});
          throw Exception('Failed to generate required image hashes for web image');
        }

        WasteAppLogger.info('Generated perceptual hash for web image: $imageHash');
        WasteAppLogger.info('Generated content hash for web image: $contentHash');

        final cachedResult = await cacheService.getCachedClassification(
          imageHash,
          contentHash: contentHash,
        );
        if (cachedResult != null) {
          WasteAppLogger.cacheEvent('cache_operation', 'classification',
              context: {'service': 'ai', 'file': 'ai_service'});
          return cachedResult.classification.copyWith(id: currentClassificationId);
        }

        WasteAppLogger.cacheEvent('cache_operation', 'classification',
            context: {'service': 'ai', 'file': 'ai_service'});
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
        WasteAppLogger.severe('OpenAI analysis failed for web image', openAiError, s);

        // If it's an image size issue or OpenAI fails, try Gemini
        if (openAiError.toString().contains('too large') ||
            openAiError.toString().contains('compression failed') ||
            retryCount >= maxRetries) {
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
          final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          await Future.delayed(waitTime);
          return analyzeWebImage(
            imageBytes,
            savedImagePath,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            region: region,
            instructionsLang: instructionsLang,
            classificationId: currentClassificationId,
          );
        }

        rethrow;
      }
    } catch (e) {
      WasteAppLogger.severe('Top-level web analysis failed', e);
      // Ensure fallback also uses the consistent ID
      return WasteClassification.fallback(
        imageName,
        id: currentClassificationId,
      );
    }
  }

  /// Analyzes an image by segments using the OpenAI API.
  ///
  /// This method is for mobile platforms and uses image segmentation
  /// to analyze specific parts of an image.
  Future<WasteClassification> analyzeImageSegments(
    File imageFile,
    List<Map<String, dynamic>> segments, {
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    final permanentPath = await _imageService.saveFilePermanently(imageFile);
    final permanentFile = File(permanentPath);
    final imageBytes = await permanentFile.readAsBytes();
    return _analyzeImageSegmentsInternal(
      imageBytes,
      permanentFile.path,
      segments,
      region: region,
      instructionsLang: instructionsLang,
      classificationId: classificationId,
    );
  }

  /// Analyzes a web image by segments using the OpenAI API.
  ///
  /// This method is for web platforms and uses image segmentation
  /// to analyze specific parts of an image.
  Future<WasteClassification> analyzeImageSegmentsWeb(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> segments, {
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    final savedPath = await _imageService.saveImagePermanently(imageBytes, fileName: imageName);
    return _analyzeImageSegmentsInternal(
      imageBytes,
      savedPath,
      segments,
      region: region,
      instructionsLang: instructionsLang,
      classificationId: classificationId,
    );
  }

  /// Internal method for analyzing image segments (used by both mobile and web).
  Future<WasteClassification> _analyzeImageSegmentsInternal(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> segments, {
    int retryCount = 0,
    int maxRetries = 3,
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    final analysisRegion = region ?? defaultRegion;
    final analysisLang = instructionsLang ?? defaultLanguage;

    // Generate a new classification ID if not provided (for initial call)
    final currentClassificationId = classificationId ?? const Uuid().v4();

    // Check cache if enabled (segmentation results might not be cached by hash directly)
    // For simplicity, we skip cache for segmented analysis for now as hashes
    // would be on the full image, not segments.

    // Try OpenAI first with compression
    try {
      final classification = await _analyzeWithOpenAISegments(
        imageBytes,
        imageName,
        segments,
        analysisRegion,
        analysisLang,
        currentClassificationId,
      );
      return classification;
    } on Exception {
      WasteAppLogger.aiEvent('AI operation', context: {'service': 'ai', 'file': 'ai_service'});

      // Fallback for segment analysis failures
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return _analyzeImageSegmentsInternal(
          imageBytes,
          imageName,
          segments,
          retryCount: retryCount + 1,
          maxRetries: maxRetries,
          region: region,
          instructionsLang: instructionsLang,
          classificationId: currentClassificationId,
        );
      }

      // If all segment analysis retries fail, fall back to non-segmented analysis
      WasteAppLogger.severe('Error occurred');
      return analyzeWebImage(
        imageBytes,
        imageName,
        region: analysisRegion,
        instructionsLang: analysisLang,
        classificationId: currentClassificationId,
      );
    }
  }

  /// Analyzes an image using the OpenAI API.
  ///
  /// Compresses the image if necessary, constructs the request,
  /// and processes the response. Caches the result if successful.
  /// Throws specific exceptions for different API error codes.
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
    // Compress image if needed
    final compressedBytes = await _compressImageForOpenAI(imageBytes);
    final base64Image = _bytesToBase64(compressedBytes);
    final mimeType = _detectImageMimeType(compressedBytes);

    WasteAppLogger.info('Sending image to OpenAI for analysis.');
    WasteAppLogger.info('Image size: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
    WasteAppLogger.info('MIME type: $mimeType');
    WasteAppLogger.info('Region: $region');
    WasteAppLogger.info('Language: $language');

    final requestBody = <String, dynamic>{
      'model': ApiConfig.primaryModel,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Instructions language: $language\n- Image source: web upload'
            },
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

    late final Response response;
    try {
      response = await _dio.post(
        '${ApiConfig.openAiBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
          },
        ),
        data: requestBody,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      _handleDioException(e);
      return WasteClassification.fallback(imageName, id: classificationId);
    }

    // Enhanced error handling with detailed logging
    if (response.statusCode == 200) {
      WasteAppLogger.info('Received successful response from OpenAI.');
      final Map<String, dynamic> responseData = response.data;
      final classification = _processAiResponseData(
        responseData,
        imageName,
        region,
        language,
        null,
        classificationId,
        thumbnailPath: thumbnailPath,
      );

      // Cache the result if we have a valid hash
      if (cachingEnabled && imageHash != null) {
        await cacheService.cacheClassification(
          imageHash,
          classification,
          contentHash: contentHash,
          imageSize: imageBytes.length,
        );
      }

      return classification;
    } else {
      // ENHANCED ERROR LOGGING
      WasteAppLogger.severe('OpenAI API request failed.');
      WasteAppLogger.severe('Status code: ${response.statusCode}');
      WasteAppLogger.severe('Response body: ${response.data}');

      // Parse error details if available
      try {
        final errorData = response.data;
        if (errorData['error'] != null) {
          WasteAppLogger.severe('Error message: ${errorData['error']['message']}');
          WasteAppLogger.severe('Error type: ${errorData['error']['type']}');
          if (errorData['error']['code'] != null) {
            WasteAppLogger.severe('Error code: ${errorData['error']['code']}');
          }
        }
      } catch (e, s) {
        WasteAppLogger.severe('Failed to parse OpenAI error response.', e, s);
      }

      // Handle specific error codes
      if (response.statusCode == 400) {
        throw Exception('OpenAI Bad Request - Check image format and prompt: ${response.data}');
      } else if (response.statusCode == 401) {
        throw Exception('OpenAI Unauthorized - Check API key: ${response.data}');
      } else if (response.statusCode == 429) {
        throw Exception('OpenAI Rate limit exceeded: ${response.data}');
      } else if (response.statusCode == 503) {
        throw Exception('OpenAI Service unavailable: ${response.data}');
      } else {
        throw Exception('OpenAI API Error ${response.statusCode}: ${response.data}');
      }
    }
  }

  /// Analyzes an image by segments using the OpenAI API.
  Future<WasteClassification> _analyzeWithOpenAISegments(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> segments,
    String region,
    String language,
    String classificationId,
  ) async {
    // This is a simplified example. Real segmentation would involve
    // sending multiple requests or a more complex prompt.
    // For now, we will simulate by analyzing a cropped image of the first segment.
    if (segments.isEmpty) {
      // Fallback to full image analysis if no segments
      return _analyzeWithOpenAI(imageBytes, imageName, region, language, null, classificationId);
    }

    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image for segmentation.');
    }

    final firstSegment = segments.first;
    final bounds = firstSegment['bounds'] as Map<String, dynamic>;

    // Convert percentage coordinates to pixel coordinates
    final imageWidth = originalImage.width;
    final imageHeight = originalImage.height;

    final x = ((bounds['x'] as num).toDouble() * imageWidth / 100).round();
    final y = ((bounds['y'] as num).toDouble() * imageHeight / 100).round();
    final width = ((bounds['width'] as num).toDouble() * imageWidth / 100).round();
    final height = ((bounds['height'] as num).toDouble() * imageHeight / 100).round();

    // Ensure coordinates are within image bounds
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

    final croppedImageBytes = Uint8List.fromList(img.encodeJpg(croppedImage));

    WasteAppLogger.info('Analyzing cropped segment.');
    WasteAppLogger.info('Cropped image size: ${(croppedImageBytes.length / 1024).toStringAsFixed(2)} KB');
    return _analyzeWithOpenAI(croppedImageBytes, imageName, region, language, null, classificationId);
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
    WasteAppLogger.info('Falling back to Gemini for analysis.');

    // Gemini can handle larger images, but still compress if extremely large
    var processedBytes = imageBytes;
    const geminiMaxSize = 50 * 1024 * 1024; // 50MB for Gemini (more generous)

    if (imageBytes.length > geminiMaxSize) {
      WasteAppLogger.warning('Image exceeds Gemini max size, applying compression.');
      processedBytes = await _compressImageForGemini(imageBytes);
    }

    final base64Image = _bytesToBase64(processedBytes);
    final mimeType = _detectImageMimeType(processedBytes);

    WasteAppLogger.info('Sending image to Gemini. Size: ${(processedBytes.length / 1024).toStringAsFixed(2)} KB');

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
      _handleDioException(e);
      return WasteClassification.fallback(imageName, id: classificationId);
    }

    if (response.statusCode == 200) {
      WasteAppLogger.info('Received successful response from Gemini.');
      final Map<String, dynamic> responseData = response.data;

      // Extract content from Gemini response format
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        final String content = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Convert Gemini response to OpenAI format for processing
        final openAiFormat = <String, dynamic>{
          'choices': [
            {
              'message': {'content': content}
            }
          ]
        };

        final classification = _processAiResponseData(
          openAiFormat,
          imageName,
          region,
          language,
          null,
          classificationId,
          thumbnailPath: thumbnailPath,
        );

        // Cache the result if we have a valid hash
        if (cachingEnabled && imageHash != null) {
          await cacheService.cacheClassification(
            imageHash,
            classification,
            contentHash: contentHash,
            imageSize: imageBytes.length,
          );
        }

        return classification;
      } else {
        throw Exception('Invalid Gemini response format');
      }
    } else {
      WasteAppLogger.severe('Error occurred');
      throw Exception('Gemini API Error ${response.statusCode}: ${response.data}');
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
    WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});

    // Determine which model to use for re-analysis
    final modelToUse = model ??
        (originalClassification.source == 'ai_analysis_gemini'
            ? ApiConfig.tertiaryModel // Use Gemini for re-analysis if it was the original source
            : ApiConfig.primaryModel); // Default to OpenAI

    try {
      final imageUrl = originalClassification.imageUrl;
      Uint8List? imageBytes;

      // If imageUrl is a file path (mobile), read bytes
      if (imageUrl != null && !kIsWeb && File(imageUrl).existsSync()) {
        imageBytes = await File(imageUrl).readAsBytes();
      }
      // If imageUrl is a data URL (web), parse bytes
      else if (imageUrl != null && kIsWeb && imageUrl.startsWith('data:image')) {
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
        WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
      }

      final base64Image = imageBytes != null ? _bytesToBase64(imageBytes) : '';
      final mimeType = imageBytes != null ? _detectImageMimeType(imageBytes) : '';

      final requestBody = <String, dynamic>{
        'model': modelToUse,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': _getCorrectionPrompt(originalClassification.toJson(), userCorrection, userReason)
              },
              if (imageBytes != null)
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

      late final Response response;
      try {
        response = await _dio.post(
          '${ApiConfig.openAiBaseUrl}/chat/completions',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
            },
          ),
          data: requestBody,
          cancelToken: _cancelToken,
        );
      } on DioException catch (e) {
        _handleDioException(e);
        return originalClassification.copyWith(
          userCorrection: userCorrection,
          disagreementReason: 'Analysis cancelled by user',
          clarificationNeeded: true,
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        final correctedClassification = _processAiResponseData(
          responseData,
          originalClassification.imageUrl ?? 'correction_update',
          originalClassification.region,
          originalClassification.instructionsLang,
          reanalysisModelsTried,
          originalClassification.id,
        );

        // Preserve some original metadata
        return correctedClassification.copyWith(
          imageUrl: originalClassification.imageUrl,
          imageHash: originalClassification.imageHash,
          source: originalClassification.source,
          userCorrection: userCorrection,
        );
      } else {
        WasteAppLogger.severe('Error occurred');
        throw Exception('Failed to process correction: ${response.statusCode}');
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      // Return original classification with user correction noted
      return originalClassification.copyWith(
        userCorrection: userCorrection,
        disagreementReason: 'Failed to process correction: $e',
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
    String? thumbnailPath,
  }) {
    try {
      if (responseData['choices'] != null && responseData['choices'].isNotEmpty) {
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
              thumbnailPath: thumbnailPath,
            );
          } catch (jsonError) {
            WasteAppLogger.severe('Error occurred');

            // Try to extract basic info even if full parsing fails
            return _createFallbackClassification(
              content,
              imagePath,
              region,
              classificationId: classificationId,
            );
          }
        }
      }
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
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
    final jsonCodeBlockRegExp = RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true);
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
  DisposalInstructions _parseDisposalInstructions(dynamic jsonDisposalInstructions) {
    if (jsonDisposalInstructions == null) {
      return DisposalInstructions(
        primaryMethod: 'Review required',
        steps: ['Please review manually'],
        hasUrgentTimeframe: false,
      );
    }

    if (jsonDisposalInstructions is Map) {
      try {
        return DisposalInstructions.fromJson(Map<String, dynamic>.from(jsonDisposalInstructions));
      } catch (e) {
        WasteAppLogger.severe('Error occurred');
        // Fallback to basic instructions if map parsing fails
        return DisposalInstructions(
          primaryMethod: jsonDisposalInstructions['primaryMethod']?.toString() ?? 'Review required',
          steps: _parseStepsFromString(jsonDisposalInstructions['steps']?.toString() ?? ''),
          hasUrgentTimeframe: false,
        );
      }
    } else if (jsonDisposalInstructions is String) {
      // If it's a string, try to parse it as simple instructions
      return DisposalInstructions(
        primaryMethod: jsonDisposalInstructions.isNotEmpty ? jsonDisposalInstructions : 'Review required',
        steps: _parseStepsFromString(jsonDisposalInstructions),
        hasUrgentTimeframe: false,
      );
    } else if (jsonDisposalInstructions is List) {
      // If it's a list, treat the first element as primary method and others as steps
      final primaryMethod =
          jsonDisposalInstructions.isNotEmpty ? jsonDisposalInstructions[0].toString() : 'Review required';
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
              return AlternativeClassification.fromJson(alt as Map<String, dynamic>);
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
    String? thumbnailPath,
  }) {
    try {
      final disposalInstructions = _parseDisposalInstructions(jsonContent['disposalInstructions']);
      final alternatives = _parseAlternatives(jsonContent['alternatives']);

      // 🔧 ENHANCED ITEM NAME PARSING: Handle null itemName from AI
      var itemName = _safeStringParse(jsonContent['itemName']) ?? '';

      if (itemName.isEmpty || itemName == 'null') {
        // Try to extract item name from explanation or subcategory
        final explanation = _safeStringParse(jsonContent['explanation']) ?? '';
        final subcategory = _safeStringParse(jsonContent['subcategory']) ?? '';
        final category = _safeStringParse(jsonContent['category']) ?? '';

        WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});

        // Try to extract from explanation first
        if (explanation.isNotEmpty) {
          // Look for patterns like "The image shows [item]" or "This is [item]"
          final patterns = [
            RegExp(r'(?:shows?|depicts?|contains?|is)\s+(?:an?|the)?\s*([^.]+?)(?:\s+(?:which|that|in|on)|\.|$)',
                caseSensitive: false),
            RegExp(
                r'(?:This|It)\s+(?:appears to be|looks like|is)\s+(?:an?|the)?\s*([^.]+?)(?:\s+(?:which|that|in|on)|\.|$)',
                caseSensitive: false),
          ];

          for (final pattern in patterns) {
            final match = pattern.firstMatch(explanation);
            if (match != null && match.group(1) != null) {
              final extractedName = match.group(1)!.trim();
              if (extractedName.isNotEmpty && extractedName.length < 50) {
                itemName = extractedName;
                WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
                break;
              }
            }
          }
        }

        // Fallback to subcategory if still empty
        if (itemName.isEmpty && subcategory.isNotEmpty) {
          itemName = subcategory;
          WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        }

        // Final fallback to category
        if (itemName.isEmpty && category.isNotEmpty) {
          itemName = category;
          WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        }

        // Last resort fallback
        if (itemName.isEmpty) {
          itemName = 'Unidentified Item';
          WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});
        }
      }

      // Extract relative path from absolute image path
      String? imageRelativePath;
      if (imagePath.contains('/images/')) {
        final index = imagePath.indexOf('/images/');
        imageRelativePath = imagePath.substring(index + 1); // Remove leading slash
      } else if (imagePath.contains('\\images\\')) {
        final index = imagePath.indexOf('\\images\\');
        imageRelativePath = imagePath.substring(index + 1).replaceAll('\\', '/');
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
          thumbnailRelativePath = thumbnailPath.substring(index + 1); // Remove leading slash
        } else if (thumbnailPath.contains('\\thumbnails\\')) {
          final index = thumbnailPath.indexOf('\\thumbnails\\');
          thumbnailRelativePath = thumbnailPath.substring(index + 1).replaceAll('\\', '/');
        } else if (thumbnailPath.contains('.jpg') ||
            thumbnailPath.contains('.png') ||
            thumbnailPath.contains('.jpeg') ||
            thumbnailPath.contains('.webp')) {
          final fileName = thumbnailPath.split('/').last.split('\\').last;
          thumbnailRelativePath = 'thumbnails/$fileName';
        }
      }

      return WasteClassification(
        id: classificationId,
        itemName: itemName,
        category: _safeStringParse(jsonContent['category']) ?? 'Requires Manual Review',
        subcategory: _safeStringParse(jsonContent['subcategory']),
        materialType: _safeStringParse(jsonContent['materialType']),
        recyclingCode: _parseRecyclingCode(jsonContent['recyclingCode']),
        explanation: _safeStringParse(jsonContent['explanation']) ?? 'No explanation provided',
        disposalMethod: _safeStringParse(jsonContent['disposalMethod']),
        disposalInstructions: disposalInstructions,
        region: region,
        localGuidelinesReference: _safeStringParse(jsonContent['localGuidelinesReference']),
        imageUrl: imagePath,
        imageRelativePath: imageRelativePath,
        thumbnailRelativePath: thumbnailRelativePath,
        visualFeatures: _parseStringListSafely(jsonContent['visualFeatures']),
        isRecyclable: _parseBool(jsonContent['isRecyclable']),
        isCompostable: _parseBool(jsonContent['isCompostable']),
        requiresSpecialDisposal: _parseBool(jsonContent['requiresSpecialDisposal']),
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
        translatedInstructions: _parseStringMapSafely(jsonContent['translatedInstructions']),
        modelVersion: _safeStringParse(jsonContent['modelVersion']),
        modelSource: _safeStringParse(jsonContent['modelSource']) ?? 'openai-${ApiConfig.primaryModel}',
        processingTimeMs: _parseInt(jsonContent['processingTimeMs']),
        analysisSessionId: _safeStringParse(jsonContent['analysisSessionId']),
        disagreementReason: _safeStringParse(jsonContent['disagreementReason']),
        pointsAwarded: _parseInt(jsonContent['pointsAwarded']) ?? 10, // Standard points for classification
        environmentalImpact: _safeStringParse(jsonContent['environmentalImpact']),
        relatedItems: _parseStringListSafely(jsonContent['relatedItems']),
        source: 'ai_analysis',
        reanalysisModelsTried: reanalysisModelsTried,
      );
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      return _createFallbackClassification(jsonContent.toString(), imagePath, region,
          classificationId: classificationId);
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
      return value.split(RegExp(r'[;,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Safely parses a map of strings from a dynamic input.
  Map<String, String>? _parseStringMapSafely(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, String>.fromEntries(value.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())));
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
      return Map<String, double>.fromEntries(
          value.entries.map((e) => MapEntry(e.key.toString(), _parseDouble(e.value) ?? 0.0)));
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
      steps = stepsString.split('\n').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try comma separation
    else if (stepsString.contains(',')) {
      steps = stepsString.split(',').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try semicolon separation
    else if (stepsString.contains(';')) {
      steps = stepsString.split(';').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try numbered list pattern (1. 2. 3.)
    else if (RegExp(r'\d+\.').hasMatch(stepsString)) {
      steps = stepsString.split(RegExp(r'\d+\.')).map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
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
  WasteClassification _createFallbackClassification(String content, String imagePath, String region,
      {String? classificationId}) {
    WasteAppLogger.info('Operation completed', null, null, {'service': 'ai', 'file': 'ai_service'});

    // Try to extract basic information from the text
    var itemName = 'Unknown Item';
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
          explanation = (explanationMatch.group(1) ?? explanationMatch.group(2)) ?? explanation;
        }
      }
    }

    return WasteClassification.fallback(
      imagePath,
      id: classificationId,
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

      WasteAppLogger.cacheEvent('cache_operation', 'classification', context: {'service': 'ai', 'file': 'ai_service'});

      // Create a simple grid-based segmentation (3x3 grid)
      final segments = <Map<String, dynamic>>[];
      const segmentWidth = 100.0 / segmentGridSize; // Percentage width per segment
      const segmentHeight = 100.0 / segmentGridSize; // Percentage height per segment

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
                (0.2 * (row * segmentGridSize + col) / (segmentGridSize * segmentGridSize)), // Simulated confidence
            'label': 'Object ${row * segmentGridSize + col + 1}',
          };

          segments.add(segment);
        }
      }

      WasteAppLogger.cacheEvent('cache_operation', 'classification', context: {'service': 'ai', 'file': 'ai_service'});
      return segments;
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      rethrow;
    }
  }
}
