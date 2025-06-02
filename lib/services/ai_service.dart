import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';
import '../services/cache_service.dart';

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
  final String openAiBaseUrl;
  final String openAiApiKey;
  final String geminiBaseUrl;
  final String geminiApiKey;
  final ClassificationCacheService cacheService;
  
  // Simple segmentation parameters - can be adjusted based on needs
  static const int segmentGridSize = 3; // 3x3 grid for basic segmentation
  static const double minSegmentArea = 0.05; // Minimum 5% of image area
  static const int objectDetectionSegments = 9; // Maximum number of segments to return
  
  // Enable/disable caching (for testing or fallback)
  final bool cachingEnabled;

  // Default region for classifications
  final String defaultRegion;
  final String defaultLanguage;

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
        
  /// Initialize the service and its dependencies
  Future<void> initialize() async {
    // Initialize the cache service if caching is enabled
    if (cachingEnabled) {
      await cacheService.initialize();
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
   - isRecyclable, isCompostable, requiresSpecialDisposal

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
20. User fields:
    - Set isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount to null unless provided in input context.

Rules:
- Reply with only the JSON object (no extra commentary).
- Use null for any unknown fields.
- Strictly match the field names and structure below.
- Do not hallucinate image URLs or user fields unless given.

Format the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, disposalInstructions, region, localGuidelinesReference, imageUrl, imageHash, imageMetrics, visualFeatures, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode, riskLevel, requiredPPE, brand, product, barcode, isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount, clarificationNeeded, confidence, modelVersion, processingTimeMs, modelSource, analysisSessionId, alternatives, suggestedAction, hasUrgentTimeframe, instructionsLang, translatedInstructions
''';

  /// Correction/disagreement prompt for handling user feedback.
  ///
  /// Guides the AI to re-analyze an item based on user-provided corrections
  /// or disagreements, updating the classification and explaining changes.
  String _getCorrectionPrompt(Map<String, dynamic> previousClassification, String userCorrection, String? userReason) => '''
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
    List<int> imageBytes = await imageFile.readAsBytes();
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
  Future<Uint8List> _compressImageForOpenAI(Uint8List imageBytes) async {
    const int maxSizeBytes = 20 * 1024 * 1024; // 20MB OpenAI limit
    const int preferredSizeBytes = 5 * 1024 * 1024; // 5MB preferred
    
    debugPrint('Original image size: ${imageBytes.length} bytes (${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
    
    // If image is within preferred size, return as-is
    if (imageBytes.length <= preferredSizeBytes) {
      debugPrint('✅ Image size acceptable for OpenAI');
      return imageBytes;
    }
    
    // If image exceeds OpenAI limit, we must compress or switch to Gemini
    if (imageBytes.length > maxSizeBytes) {
      debugPrint('⚠️ Image exceeds OpenAI 20MB limit, will compress aggressively or use Gemini');
    } else {
      debugPrint('⚠️ Image larger than preferred 5MB, compressing for better performance');
    }
    
    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image for compression');
        throw Exception('Unable to decode image for compression');
      }
      
      debugPrint('Original image dimensions: ${image.width}x${image.height}');
      
      // Calculate compression strategy
      int targetWidth = image.width;
      int targetHeight = image.height;
      int quality = 85;
      
      // If image is too large, we need aggressive compression
      if (imageBytes.length > maxSizeBytes) {
        // Very aggressive compression for oversized images
        final double scaleFactor = 0.5; // Reduce dimensions by 50%
        targetWidth = (image.width * scaleFactor).round();
        targetHeight = (image.height * scaleFactor).round();
        quality = 70;
        debugPrint('🔄 Applying aggressive compression: ${targetWidth}x$targetHeight, quality: $quality');
      } else {
        // Moderate compression for large but acceptable images
        final double scaleFactor = 0.8; // Reduce dimensions by 20%
        targetWidth = (image.width * scaleFactor).round();
        targetHeight = (image.height * scaleFactor).round();
        quality = 80;
        debugPrint('🔄 Applying moderate compression: ${targetWidth}x$targetHeight, quality: $quality');
      }
      
      // Resize image if needed
      if (targetWidth != image.width || targetHeight != image.height) {
        image = img.copyResize(image, width: targetWidth, height: targetHeight);
        debugPrint('✅ Image resized to: ${image.width}x${image.height}');
      }
      
      // Encode as JPEG with specified quality
      final compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      
      debugPrint('Compressed image size: ${compressedBytes.length} bytes (${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      debugPrint('Compression ratio: ${((1 - compressedBytes.length / imageBytes.length) * 100).toStringAsFixed(1)}%');
      
      // If still too large after aggressive compression, throw error to trigger Gemini fallback
      if (compressedBytes.length > maxSizeBytes) {
        debugPrint('❌ Image still too large after compression, will use Gemini fallback');
        throw Exception('Image too large even after compression (${compressedBytes.length} bytes). Using Gemini fallback.');
      }
      
      return compressedBytes;
      
    } catch (e) {
      debugPrint('❌ Image compression failed: $e');
      // If compression fails and image is too large, trigger Gemini fallback
      if (imageBytes.length > maxSizeBytes) {
        throw Exception('Image compression failed and image exceeds OpenAI limits. Using Gemini fallback.');
      }
      // If compression fails but image is within limits, return original
      return imageBytes;
    }
  }

  /// Applies light compression to image [Uint8List] data for the Gemini API.
  ///
  /// Reduces image dimensions slightly and applies a moderate JPEG quality setting.
  /// Returns original bytes if compression fails.
  Future<Uint8List> _compressImageForGemini(Uint8List imageBytes) async {
    debugPrint('🔄 Applying light compression for Gemini');
    
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image for Gemini compression');
        return imageBytes; // Return original if compression fails
      }
      
      // Light compression - just reduce quality, keep dimensions mostly the same
      final double scaleFactor = 0.9; // Reduce dimensions by 10%
      final int targetWidth = (image.width * scaleFactor).round();
      final int targetHeight = (image.height * scaleFactor).round();
      
      image = img.copyResize(image, width: targetWidth, height: targetHeight);
      final compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
      
      debugPrint('✅ Gemini compression: ${imageBytes.length} -> ${compressedBytes.length} bytes');
      return compressedBytes;
      
    } catch (e) {
      debugPrint('❌ Gemini compression failed: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  /// Analyzes a waste item image provided as [Uint8List] (typically for web).
  ///
  /// Handles caching, image compression, API calls to OpenAI (with retries),
  /// and fallback to Gemini if OpenAI fails or the image is too large.
  ///
  /// - [imageBytes]: The raw byte data of the image.
  /// - [imageName]: A descriptive name or path for the image (used in fallback).
  /// - [retryCount]: Current retry attempt number for API calls.
  /// - [maxRetries]: Maximum number of retries for API calls.
  /// - [region]: The geographical region for context-specific classification.
  /// - [instructionsLang]: The desired language for disposal instructions.
  ///
  /// Returns a [WasteClassification] object.
  Future<WasteClassification> analyzeWebImage(
      Uint8List imageBytes, String imageName, {
      int retryCount = 0, 
      int maxRetries = 3,
      String? region,
      String? instructionsLang,
    }) async {
    String? imageHash;
    final analysisRegion = region ?? defaultRegion;
    final analysisLang = instructionsLang ?? defaultLanguage;
    
    try {
      // Check cache if enabled
      if (cachingEnabled) {
        imageHash = await ImageUtils.generateImageHash(imageBytes);
        debugPrint('Generated perceptual hash for web image: $imageHash');
        
        final cachedResult = await cacheService.getCachedClassification(
          imageHash,
          similarityThreshold: 10
        );
        if (cachedResult != null) {
          debugPrint('Cache hit for web image hash: $imageHash - returning cached classification');
          return cachedResult.classification;
        }
        
        debugPrint('Cache miss for web image hash: $imageHash - will call API and save result');
      }

      // Try OpenAI first with compression
      try {
        return await _analyzeWithOpenAI(imageBytes, imageName, analysisRegion, analysisLang, imageHash);
      } catch (openAiError) {
        debugPrint('OpenAI analysis failed: $openAiError');
        
        // If it's an image size issue or OpenAI fails, try Gemini
        if (openAiError.toString().contains('too large') || 
            openAiError.toString().contains('compression failed') ||
            retryCount >= maxRetries) {
          debugPrint('🔄 Switching to Gemini due to image size or OpenAI failure');
          return await _analyzeWithGemini(imageBytes, imageName, analysisRegion, analysisLang, imageHash);
        }
        
        // For other errors, retry with OpenAI
        if (retryCount < maxRetries) {
          final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          await Future.delayed(waitTime);
          return analyzeWebImage(
            imageBytes, 
            imageName,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
            region: region,
            instructionsLang: instructionsLang,
          );
        }
        
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ All analysis methods failed: $e');
      return WasteClassification.fallback(imageName);
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
  ) async {
    // Compress image if needed
    final compressedBytes = await _compressImageForOpenAI(imageBytes);
    final String base64Image = _bytesToBase64(compressedBytes);
    final String mimeType = _detectImageMimeType(compressedBytes);
    
    debugPrint('🔄 Making OpenAI API request...');
    debugPrint('🔄 Model: ${ApiConfig.primaryModel}');
    debugPrint('🔄 Image size: ${compressedBytes.length} bytes');
    debugPrint('🔄 MIME type: $mimeType');
    debugPrint('🔄 Base64 size: ${base64Image.length} characters');

    final Map<String, dynamic> requestBody = {
      "model": ApiConfig.primaryModel,
      "messages": [
        {
          "role": "system",
          "content": _systemPrompt
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": "$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Instructions language: $language\n- Image source: web upload"
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:$mimeType;base64,$base64Image"}
            }
          ]
        }
      ],
      "max_tokens": 1500,
      "temperature": 0.1
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
      },
      body: jsonEncode(requestBody),
    );

    // Enhanced error handling with detailed logging
    if (response.statusCode == 200) {
      debugPrint('✅ OpenAI API Success');
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final classification = _processAiResponseData(responseData, imageName, region);
      
      // Cache the result if we have a valid hash
      if (cachingEnabled && imageHash != null) {
        await cacheService.cacheClassification(imageHash, classification, imageSize: imageBytes.length);
      }
      
      return classification;
    } else {
      // ENHANCED ERROR LOGGING
      debugPrint('❌ OpenAI API Error - Status: ${response.statusCode}');
      debugPrint('❌ Response Headers: ${response.headers}');
      debugPrint('❌ Response Body: ${response.body}');
      
      // Parse error details if available
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          debugPrint('❌ OpenAI Error Type: ${errorData['error']['type']}');
          debugPrint('❌ OpenAI Error Message: ${errorData['error']['message']}');
          if (errorData['error']['code'] != null) {
            debugPrint('❌ OpenAI Error Code: ${errorData['error']['code']}');
          }
        }
      } catch (e) {
        debugPrint('❌ Could not parse error response: $e');
      }
      
      // Handle specific error codes
      if (response.statusCode == 400) {
        throw Exception('OpenAI Bad Request - Check image format and prompt: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('OpenAI Unauthorized - Check API key: ${response.body}');
      } else if (response.statusCode == 429) {
        throw Exception('OpenAI Rate limit exceeded: ${response.body}');
      } else if (response.statusCode == 503) {
        throw Exception('OpenAI Service unavailable: ${response.body}');
      } else {
        throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
      }
    }
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
  ) async {
    debugPrint('🔄 Using Gemini for analysis...');
    
    // Gemini can handle larger images, but still compress if extremely large
    Uint8List processedBytes = imageBytes;
    const int geminiMaxSize = 50 * 1024 * 1024; // 50MB for Gemini (more generous)
    
    if (imageBytes.length > geminiMaxSize) {
      debugPrint('⚠️ Image too large even for Gemini, applying light compression');
      processedBytes = await _compressImageForGemini(imageBytes);
    }
    
    final String base64Image = _bytesToBase64(processedBytes);
    final String mimeType = _detectImageMimeType(processedBytes);
    
    debugPrint('🔄 Gemini request - Image size: ${processedBytes.length} bytes, MIME: $mimeType');
    
    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "$_systemPrompt\n\n$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Instructions language: $language\n- Image source: Gemini analysis (OpenAI fallback)"
            },
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "maxOutputTokens": 1500
      }
    };

    final response = await http.post(
      Uri.parse('$geminiBaseUrl/models/${ApiConfig.tertiaryModel}:generateContent'),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': geminiApiKey,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Gemini API Success');
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      // Extract content from Gemini response format
      if (responseData['candidates'] != null && 
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        
        final String content = responseData['candidates'][0]['content']['parts'][0]['text'];
        
        // Convert Gemini response to OpenAI format for processing
        final Map<String, dynamic> openAiFormat = {
          'choices': [
            {
              'message': {
                'content': content
              }
            }
          ]
        };
        
        final classification = _processAiResponseData(openAiFormat, imageName, region);
        
        // Cache the result if we have a valid hash
        if (cachingEnabled && imageHash != null) {
          await cacheService.cacheClassification(imageHash, classification, imageSize: imageBytes.length);
        }
        
        return classification;
      } else {
        throw Exception('Invalid Gemini response format');
      }
    } else {
      // Enhanced Gemini error logging
      debugPrint('❌ Gemini API Error - Status: ${response.statusCode}');
      debugPrint('❌ Gemini Response: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          debugPrint('❌ Gemini Error Message: ${errorData['error']['message']}');
        }
      } catch (e) {
        debugPrint('❌ Could not parse Gemini error response: $e');
      }
      
      throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Handles user-provided corrections to a previous classification.
  ///
  /// Re-analyzes the item using the AI model, incorporating the user's feedback
  /// and reason. Can accept image data ([imageBytes] or [imageFile]) if available
  /// for re-analysis, otherwise performs a text-only correction.
  ///
  /// - [originalClassification]: The initial AI classification.
  /// - [userCorrection]: The user's corrected category or information.
  /// - [userReason]: The user's explanation for the correction.
  /// - [imageBytes]: Optional image data for re-analysis.
  /// - [imageFile]: Optional image file for re-analysis.
  ///
  /// Returns an updated [WasteClassification].
  Future<WasteClassification> handleUserCorrection(
    WasteClassification originalClassification,
    String userCorrection,
    String? userReason, {
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    try {
      debugPrint('Processing user correction: $userCorrection');
      
      // Prepare the correction prompt
      final correctionPrompt = _getCorrectionPrompt(
        originalClassification.toJson(),
        userCorrection,
        userReason,
      );

      Map<String, dynamic> requestBody;

      // If we have image data, include it in the request
      if (imageBytes != null || imageFile != null) {
        String base64Image;
        if (imageBytes != null) {
          base64Image = _bytesToBase64(imageBytes);
        } else {
          base64Image = await _imageToBase64(imageFile!);
        }

        requestBody = {
          "model": ApiConfig.primaryModel,
          "messages": [
            {
              "role": "system",
              "content": _systemPrompt
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": correctionPrompt
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                }
              ]
            }
          ],
          "max_tokens": 1500,
          "temperature": 0.1
        };
      } else {
        // Text-only correction
        requestBody = {
          "model": ApiConfig.secondaryModel1,
          "messages": [
            {
              "role": "system",
              "content": _systemPrompt
            },
            {
              "role": "user",
              "content": correctionPrompt
            }
          ],
          "max_tokens": 1500,
          "temperature": 0.1
        };
      }

      // Make HTTP request to the OpenAI API
      final response = await http.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final correctedClassification = _processAiResponseData(
          responseData, 
          originalClassification.imageUrl ?? 'correction_update',
          originalClassification.region,
        );
        
        // Preserve some original metadata
        return correctedClassification.copyWith(
          imageUrl: originalClassification.imageUrl,
          imageHash: originalClassification.imageHash,
          source: originalClassification.source,
          userCorrection: userCorrection,
        );
      } else {
        debugPrint('Error in correction request: ${response.body}');
        throw Exception('Failed to process correction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error handling user correction: $e');
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
  /// if it's embedded in other text. Uses [_cleanJsonString] for preprocessing.
  /// If direct parsing fails, it attempts a fallback partial extraction via [_createFallbackClassification].
  WasteClassification _processAiResponseData(Map<String, dynamic> responseData, String imagePath, String region) {
    try {
      final choices = responseData['choices'];
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message != null) {
          final content = message['content'];
          if (content != null) {
            try {
              String jsonString = content;
              debugPrint('Raw AI response content: ${content.substring(0, content.length.clamp(0, 200))}...');
              
              // Remove markdown code block formatting if present
              if (jsonString.contains('```json')) {
                jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
              } else if (jsonString.contains('```')) {
                jsonString = jsonString.replaceAll('```', '').trim();
              }
              
              // Try to find JSON object boundaries if the response has extra text
              final int startIndex = jsonString.indexOf('{');
              final int endIndex = jsonString.lastIndexOf('}');
              
              if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                jsonString = jsonString.substring(startIndex, endIndex + 1);
                debugPrint('Extracted JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 200))}...');
              }
              
              // Try to fix common JSON formatting issues
              jsonString = _cleanJsonString(jsonString);
                
              debugPrint('Final JSON string to parse: ${jsonString.substring(0, jsonString.length.clamp(0, 200))}...');
              
              final jsonContent = jsonDecode(jsonString);
              
              // ENHANCED: Better error handling and field parsing
              return _createClassificationFromJson(jsonContent, imagePath, region);
              
            } catch (jsonError) {
              debugPrint('Failed to parse JSON from AI response: $jsonError');
              debugPrint('Problematic JSON content: $content');
              
              // Try to extract basic info even if full parsing fails
              return _createFallbackClassification(content, imagePath, region);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing AI response data: $e');
      return WasteClassification.fallback(imagePath);
    }
    
    // Fallback for unexpected response structure
    return WasteClassification.fallback(imagePath);
  }

  /// Creates a [WasteClassification] object from a parsed JSON map.
  ///
  /// This method uses several safe parsing helpers (e.g., [_safeStringParse],
  /// [_parseRecyclingCode], [_parseBool]) to robustly handle potentially
  /// malformed or missing fields in the AI's JSON response.
  /// It defaults to sensible values if parsing fails for specific fields.
  WasteClassification _createClassificationFromJson(Map<String, dynamic> jsonContent, String imagePath, String region) {
    try {
      // Handle disposal instructions safely
      DisposalInstructions disposalInstructions;
      
      if (jsonContent['disposalInstructions'] != null) {
        try {
          if (jsonContent['disposalInstructions'] is Map) {
            disposalInstructions = DisposalInstructions.fromJson(
              Map<String, dynamic>.from(jsonContent['disposalInstructions'])
            );
          } else {
            // If it's a string or other format, create basic instructions
            disposalInstructions = DisposalInstructions(
              primaryMethod: jsonContent['disposalMethod']?.toString() ?? 'Review required',
              steps: _parseStepsFromString(jsonContent['disposalInstructions'].toString()),
              hasUrgentTimeframe: false,
            );
          }
        } catch (e) {
          debugPrint('Error parsing disposal instructions: $e');
          disposalInstructions = DisposalInstructions(
            primaryMethod: jsonContent['disposalMethod']?.toString() ?? 'Review required',
            steps: ['Please review disposal method'],
            hasUrgentTimeframe: false,
          );
        }
      } else {
        disposalInstructions = DisposalInstructions(
          primaryMethod: jsonContent['disposalMethod']?.toString() ?? 'Review required',
          steps: ['Please review disposal method'],
          hasUrgentTimeframe: false,
        );
      }

      // Parse alternatives with better error handling
      List<AlternativeClassification> alternatives = [];
      try {
        if (jsonContent['alternatives'] != null) {
          alternatives = _parseAlternativesSafely(jsonContent['alternatives']);
        }
      } catch (e) {
        debugPrint('Error parsing alternatives: $e');
        alternatives = [];
      }

      // Create comprehensive classification from AI response
      return WasteClassification(
        itemName: _safeStringParse(jsonContent['itemName']) ?? 'Unknown Item',
        category: _safeStringParse(jsonContent['category']) ?? 'Dry Waste',
        subcategory: _safeStringParse(jsonContent['subcategory']),
        materialType: _safeStringParse(jsonContent['materialType']),
        recyclingCode: _parseRecyclingCode(jsonContent['recyclingCode']),
        explanation: _safeStringParse(jsonContent['explanation']) ?? '',
        disposalMethod: _safeStringParse(jsonContent['disposalMethod']),
        disposalInstructions: disposalInstructions,
        region: _safeStringParse(jsonContent['region']) ?? region,
        localGuidelinesReference: _safeStringParse(jsonContent['localGuidelinesReference']),
        imageUrl: imagePath,
        imageHash: _safeStringParse(jsonContent['imageHash']),
        imageMetrics: _parseImageMetrics(jsonContent['imageMetrics']),
        visualFeatures: _parseStringListSafely(jsonContent['visualFeatures']),
        isRecyclable: _parseBool(jsonContent['isRecyclable']),
        isCompostable: _parseBool(jsonContent['isCompostable']),
        requiresSpecialDisposal: _parseBool(jsonContent['requiresSpecialDisposal']),
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
        source: 'ai_analysis',
      );
      
    } catch (e) {
      debugPrint('Error creating classification from JSON: $e');
      return _createFallbackClassification(jsonContent.toString(), imagePath, region);
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
    
    try {
      // Handle single string case
      if (value is String) {
        // Handle empty or null-like strings
        if (value.trim().isEmpty || 
            value.toLowerCase().contains('none') ||
            value.toLowerCase().contains('null')) {
          return [];
        }
        // Handle comma-separated strings
        if (value.contains(',')) {
          return value.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        // Handle JSON array as string
        if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) {
              return parsed
                  .where((item) => item != null)
                  .map((item) => item.toString().trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          } catch (e) {
            debugPrint('Failed to parse JSON array string: $e');
          }
        }
        // Single string value
        return [value.trim()];
      }
      
      // Handle list type
      if (value is List) {
        return value
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      // Handle other types by converting to string
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? [] : [stringValue];
      
    } catch (e) {
      debugPrint('Error parsing string list safely: $e');
      return [];
    }
  }

  /// Safely parses a map of strings from a dynamic input.
  ///
  /// Handles nulls, actual maps, and JSON map strings.
  /// Returns null if the input is null or parsing fails.
  Map<String, String>? _parseStringMapSafely(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Map) {
        final Map<String, String> result = {};
        value.forEach((k, v) {
          if (k != null && v != null) {
            result[k.toString()] = v.toString();
          }
        });
        return result.isEmpty ? null : result;
      }
      
      // Handle JSON string
      if (value is String && value.trim().startsWith('{')) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is Map) {
            return _parseStringMapSafely(parsed);
          }
        } catch (e) {
          debugPrint('Failed to parse JSON map string: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Error parsing string map safely: $e');
    }
    
    return null;
  }

  /// Safely parses a list of [AlternativeClassification] objects from a dynamic input.
  ///
  /// Handles nulls, empty/none strings, JSON array strings, and actual lists of maps.
  /// Uses safe parsing for individual alternative fields. Returns an empty list on failure.
  List<AlternativeClassification> _parseAlternativesSafely(dynamic value) {
    if (value == null) return [];
    
    try {
      // Handle string input (sometimes AI returns a string instead of array)
      if (value is String) {
        if (value.trim().isEmpty || 
            value.toLowerCase().contains('none') ||
            value.toLowerCase().contains('null')) {
          return [];
        }
        
        // Try to parse as JSON array
        if (value.trim().startsWith('[')) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) {
              return _parseAlternativesSafely(parsed);
            }
          } catch (e) {
            debugPrint('Failed to parse alternatives JSON string: $e');
          }
        }
        
        return [];
      }
      
      if (value is List) {
        final List<AlternativeClassification> alternatives = [];
        
        for (final alt in value) {
          try {
            if (alt is Map) {
              // Convert Map to Map<String, dynamic> safely
              final Map<String, dynamic> altMap = {};
              alt.forEach((key, val) {
                if (key != null) {
                  altMap[key.toString()] = val;
                }
              });
              
              // Create alternative with safe parsing
              final alternative = AlternativeClassification(
                category: _safeStringParse(altMap['category']) ?? 'Unknown',
                subcategory: _safeStringParse(altMap['subcategory']),
                confidence: _parseDouble(altMap['confidence']) ?? 0.5,
                reason: _safeStringParse(altMap['reason']) ?? 'Alternative classification',
              );
              alternatives.add(alternative);
            }
          } catch (e) {
            debugPrint('Error parsing individual alternative: $e');
            // Continue processing other alternatives
          }
        }
        
        return alternatives;
      }
      
    } catch (e) {
      debugPrint('Error parsing alternatives safely: $e');
    }
    
    return [];
  }

  /// Parses a string containing disposal steps into a list of strings.
  ///
  /// Attempts to parse as a JSON array first. If that fails, splits the string
  /// by common delimiters (newline, semicolon, comma).
  /// Returns a default message if the input is empty.
  List<String> _parseStepsFromString(String stepsString) {
    if (stepsString.trim().isEmpty) return ['Please review disposal method'];
    
    // Try to parse as JSON array first
    if (stepsString.trim().startsWith('[')) {
      try {
        final parsed = jsonDecode(stepsString);
        if (parsed is List) {
          return parsed.map((s) => s.toString()).toList();
        }
      } catch (e) {
        debugPrint('Failed to parse steps as JSON: $e');
      }
    }
    
    // Split by common delimiters
    if (stepsString.contains('\n')) {
      return stepsString.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (stepsString.contains(';')) {
      return stepsString.split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (stepsString.contains(',')) {
      return stepsString.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    // Return as single step
    return [stepsString.trim()];
  }

  /// Creates a fallback [WasteClassification] when full JSON parsing fails.
  ///
  /// Attempts to extract basic information (itemName, category, explanation)
  /// from the raw content string using simple keyword matching and regex.
  /// Assigns moderate confidence and marks clarification as needed.
  WasteClassification _createFallbackClassification(String content, String imagePath, String region) {
    debugPrint('Creating fallback classification from partial content');
    
    // Try to extract basic information from the text
    String itemName = 'Unknown Item';
    String category = 'Dry Waste';
    String explanation = 'Classification extracted from partial AI response.';
    
    // Basic text extraction
    final lines = content.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('itemname') || lowerLine.contains('item_name')) {
        final RegExp itemPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final RegExpMatch? itemMatch = itemPattern.firstMatch(line);
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
        final RegExp explanationPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final RegExpMatch? explanationMatch = explanationPattern.firstMatch(line);
        if (explanationMatch != null) {
          explanation = (explanationMatch.group(1) ?? explanationMatch.group(2)) ?? explanation;
        }
      }
    }
    
    return WasteClassification(
      itemName: itemName,
      category: category,
      explanation: explanation,
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Please review classification',
        steps: ['AI response partially parsed', 'Manual review recommended'],
        hasUrgentTimeframe: false,
      ),
      region: region,
      imageUrl: imagePath,
      confidence: 0.7, // Moderate confidence for partial parsing
      clarificationNeeded: true,
      source: 'ai_analysis_partial',
      alternatives: [], // Required parameter
      visualFeatures: [], // Required parameter
    );
  }

  /// Cleans and prepares a JSON string for parsing.
  ///
  /// Removes markdown code block formatting (```json ... ``` or ``` ... ```).
  /// Extracts the JSON object if it's wrapped in extraneous text.
  /// Fixes common JSON issues like single quotes, 'None' instead of 'null',
  /// unescaped quotes in strings, and trailing commas in objects/arrays.
  String _cleanJsonString(String jsonString) {
    // Remove markdown formatting
    if (jsonString.contains('```json')) {
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
    } else if (jsonString.contains('```')) {
      jsonString = jsonString.replaceAll('```', '').trim();
    }
    
    // Extract JSON object if wrapped in text
    final startIndex = jsonString.indexOf('{');
    final endIndex = jsonString.lastIndexOf('}');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      jsonString = jsonString.substring(startIndex, endIndex + 1);
    }
    
    // Fix unescaped quotes in string values (common AI response issue)
    // This regex finds string values and escapes internal quotes
    jsonString = jsonString.replaceAllMapped(
      RegExp(r'"([^"]*)"(\s*:\s*)"([^"]*(?:[^"\\]|\\.)*)(?<!\\)"'),
      (match) {
        final key = match.group(1);
        final separator = match.group(2);
        final value = match.group(3);
        if (value != null) {
          // Escape unescaped quotes in the value
          final escapedValue = value.replaceAll(RegExp(r'(?<!\\)"'), '\\"');
          return '"$key"$separator"$escapedValue"';
        }
        return match.group(0)!;
      },
    );
    
    // Fix common JSON issues
    jsonString = jsonString
        .replaceAll("''", '""')
        .replaceAll('None', 'null')
        .replaceAll('True', 'true')
        .replaceAll('False', 'false')
        // Fix trailing commas
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*]'), ']');
        
    return jsonString;
  }

  /// Analyzes a waste item image provided as a [File] (typically for mobile platforms).
  ///
  /// Reads the file into [Uint8List] and then calls [analyzeWebImage].
  Future<WasteClassification> analyzeImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return analyzeWebImage(imageBytes, imageFile.path);
  }

  /// Placeholder for image segmentation.
  ///
  /// Currently returns the full image as a single segment.
  /// Intended for future implementation of more sophisticated object detection/segmentation.
  Future<List<Map<String, dynamic>>> segmentImage(dynamic input) async {
    // Basic segmentation - returns the full image as a single segment
    return [
      {
        'bounds': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
        'confidence': 1.0,
        'area': 1.0,
      }
    ];
  }

  /// Placeholder for analyzing specific image segments (web version).
  ///
  /// Currently defers to analyzing the full image via [analyzeWebImage].
  Future<WasteClassification> analyzeImageSegmentsWeb(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> segments, {
    String? region,
    String? instructionsLang,
  }) async {
    // For now, just analyze the full image
    return analyzeWebImage(imageBytes, imageName, region: region, instructionsLang: instructionsLang);
  }

  /// Placeholder for analyzing specific image segments (mobile version).
  ///
  /// Currently defers to analyzing the full image via [analyzeImage].
  Future<WasteClassification> analyzeImageSegments(
    File imageFile,
    List<Map<String, dynamic>> segments, {
    String? region,
    String? instructionsLang,
  }) async {
    // For now, just analyze the full image
    return analyzeImage(imageFile);
  }

  // ================ DEFENSIVE PARSING HELPERS ================
  
  /// Safely parses a recycling code (integer) from a dynamic input.
  ///
  /// Handles null, int, and string types. For strings, it attempts to parse
  /// an integer and handles common textual responses like "None visible".
  int? _parseRecyclingCode(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Handle common AI responses like "None visible", "Not visible", etc.
      if (value.toLowerCase().contains('none') || 
          value.toLowerCase().contains('not') ||
          value.toLowerCase().contains('visible') ||
          value.trim().isEmpty) {
        return null;
      }
      // Try to parse numeric string
      return int.tryParse(value.trim());
    }
    return null;
  }
  
  /// Safely parses a boolean value from a dynamic input.
  ///
  /// Handles null, bool, string ("true", "yes", "1", "false", "no", "0"),
  /// and int (0 is false, non-zero is true).
  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == 'yes' || lower == '1') return true;
      if (lower == 'false' || lower == 'no' || lower == '0') return false;
    }
    if (value is int) {
      return value != 0;
    }
    return null;
  }
  
  /// Safely parses a double value from a dynamic input.
  ///
  /// Handles null, double, int (converted to double), and string.
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
  
  /// Safely parses an integer value from a dynamic input.
  ///
  /// Handles null, int, double (rounded), and string.
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
  
  /// Safely parses image metrics (`Map<String, double>`) from a dynamic input.
  ///
  /// Expects a Map. Converts keys to strings and values to doubles using `_parseDouble`.
  /// Returns null if input is not a map or parsing fails.
  Map<String, double>? _parseImageMetrics(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      try {
        final Map<String, double> result = {};
        value.forEach((k, v) {
          final doubleValue = _parseDouble(v);
          if (doubleValue != null) {
            result[k.toString()] = doubleValue;
          }
        });
        return result.isEmpty ? null : result;
      } catch (e) {
        debugPrint('Error parsing image metrics: $e');
        return null;
      }
    }
    return null;
  }
}
