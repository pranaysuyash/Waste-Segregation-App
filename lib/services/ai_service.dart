import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';
import '../services/cache_service.dart';

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

  /// System prompt for waste classification expert
  String get _systemPrompt => '''
You are an expert in international waste classification, recycling, and proper disposal practices. 
You are familiar with global and local waste management rules (including $defaultRegion), brand-specific packaging, and recycling codes. 
Your goal is to provide accurate, actionable, and safe waste sorting guidance based on the latest environmental standards.
''';

  /// Main classification prompt for analyzing waste items
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

  /// Correction/disagreement prompt for handling user feedback
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

  // Convert bytes to base64 (for web)
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Analyze web image using AI with comprehensive classification
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
        // Generate image hash
        imageHash = await ImageUtils.generateImageHash(imageBytes);
        debugPrint('Generated perceptual hash for web image: $imageHash');
        
        // Try to get from cache
        final cachedResult = await cacheService.getCachedClassification(
          imageHash,
          similarityThreshold: 10 // Larger threshold for better matching of similar images
        );
        if (cachedResult != null) {
          debugPrint('Cache hit for web image hash: $imageHash - returning cached classification');
          return cachedResult.classification;
        }
        
        debugPrint('Cache miss for web image hash: $imageHash - will call API and save result');
      }

      final String base64Image = _bytesToBase64(imageBytes);

      // Prepare request body using OpenAI format with comprehensive prompting
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
                "text": "$_mainClassificationPrompt\n\nAdditional context:\n- Region: $analysisRegion\n- Instructions language: $analysisLang\n- Image source: web upload"
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

      // Create the web image URL with base64 data
      final String webImageUrl = 'web_image:data:image/jpeg;base64,$base64Image';
      
      // Make HTTP request to the OpenAI API
      final response = await http.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final classification = _processAiResponseData(responseData, webImageUrl, analysisRegion);
        
        // Cache the result if we have a valid hash
        if (cachingEnabled && imageHash != null) {
          debugPrint('Caching web classification result for hash: $imageHash');
          await cacheService.cacheClassification(
            imageHash, 
            classification, 
            imageSize: imageBytes.length
          );
          debugPrint('Successfully cached web classification for hash: $imageHash');
        }
        
        return classification;
      }
      // Handle service unavailable (503) with retry logic
      else if (response.statusCode == 503 && retryCount < maxRetries) {
        debugPrint('OpenAI API overloaded (503). Retry ${retryCount + 1} of $maxRetries...');
        
        // Exponential backoff - wait longer between each retry (500ms × 2^retryCount)
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        
        // Retry with incremented count
        return analyzeWebImage(imageBytes, imageName, 
          retryCount: retryCount + 1, 
          maxRetries: maxRetries,
          region: region,
          instructionsLang: instructionsLang,
        );
      } 
      // If all retries fail, fall back to secondary model
      else if (response.statusCode == 503) {
        debugPrint('OpenAI API unavailable after $maxRetries retries. Falling back to secondary model...');
        final classification = await _fallbackToSecondaryModel(imageBytes, imageName, analysisRegion);
        
        // Cache the fallback result
        if (cachingEnabled && imageHash != null) {
          await cacheService.cacheClassification(
            imageHash, 
            classification, 
            imageSize: imageBytes.length
          );
        }
        
        return classification;
      }
      // Handle other errors
      else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      // If all retries fail, fall back to secondary model
      if (retryCount >= maxRetries) {
        debugPrint('Exception after $maxRetries retries. Attempting secondary model fallback...');
        try {
          final classification = await _fallbackToSecondaryModel(imageBytes, imageName, analysisRegion);
          
          // Cache the fallback result if caching is enabled
          if (cachingEnabled && imageHash != null) {
            await cacheService.cacheClassification(
              imageHash, 
              classification, 
              imageSize: imageBytes.length
            );
          }
          
          return classification;
        } catch (fallbackError) {
          debugPrint('Secondary model fallback also failed: $fallbackError');
          // Try third OpenAI model
          try {
            final classification = await _fallbackToThirdModel(imageBytes, imageName, analysisRegion);
            
            // Cache the fallback result if caching is enabled
            if (cachingEnabled && imageHash != null) {
              await cacheService.cacheClassification(
                imageHash, 
                classification, 
                imageSize: imageBytes.length
              );
            }
            
            return classification;
          } catch (thirdModelError) {
            debugPrint('Third model fallback also failed: $thirdModelError');
            // Try Gemini as final resort
            try {
              final classification = await _fallbackToTertiaryModel(imageBytes, imageName, analysisRegion);
              return classification;
            } catch (tertiaryError) {
              debugPrint('All fallbacks failed. Using default fallback.');
              return WasteClassification.fallback(imageName);
            }
          }
        }
      }
      debugPrint('Error analyzing web image (try $retryCount): $e');
      
      // For other types of errors, increment retry count and try again
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return analyzeWebImage(imageBytes, imageName, 
          retryCount: retryCount + 1, 
          maxRetries: maxRetries,
          region: region,
          instructionsLang: instructionsLang,
        );
      }
      
      rethrow;
    }
  }

  /// Handle user corrections and disagreements
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

  // ... existing fallback methods remain the same ...

  /// Processes the raw AI response data to extract classification
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
              jsonString = jsonString
                .replaceAll("''", '""')
                .replaceAll("'", '"');
                
              debugPrint('Final JSON string to parse: ${jsonString.substring(0, jsonString.length.clamp(0, 200))}...');
              
              final jsonContent = jsonDecode(jsonString);
              
              // Create comprehensive classification from AI response
              return WasteClassification(
                itemName: jsonContent['itemName'] ?? 'Unknown Item',
                category: jsonContent['category'] ?? 'Dry Waste',
                subcategory: jsonContent['subcategory'],
                materialType: jsonContent['materialType'],
                recyclingCode: _parseRecyclingCode(jsonContent['recyclingCode']),
                explanation: jsonContent['explanation'] ?? '',
                disposalMethod: jsonContent['disposalMethod'],
                disposalInstructions: jsonContent['disposalInstructions'] != null
                    ? DisposalInstructions.fromJson(jsonContent['disposalInstructions'])
                    : DisposalInstructions(
                        primaryMethod: jsonContent['disposalMethod'] ?? 'Review required',
                        steps: ['Please review disposal method'],
                        hasUrgentTimeframe: false,
                      ),
                region: jsonContent['region'] ?? region,
                localGuidelinesReference: jsonContent['localGuidelinesReference'],
                imageUrl: imagePath,
                imageHash: jsonContent['imageHash'],
                imageMetrics: _parseImageMetrics(jsonContent['imageMetrics']),
                visualFeatures: _parseStringList(jsonContent['visualFeatures']),
                isRecyclable: _parseBool(jsonContent['isRecyclable']),
                isCompostable: _parseBool(jsonContent['isCompostable']),
                requiresSpecialDisposal: _parseBool(jsonContent['requiresSpecialDisposal']),
                colorCode: jsonContent['colorCode'],
                riskLevel: jsonContent['riskLevel'],
                requiredPPE: _parseStringList(jsonContent['requiredPPE']),
                brand: jsonContent['brand'],
                product: jsonContent['product'],
                barcode: jsonContent['barcode'],
                confidence: _parseDouble(jsonContent['confidence']),
                clarificationNeeded: _parseBool(jsonContent['clarificationNeeded']),
                alternatives: _parseAlternatives(jsonContent['alternatives']),
                suggestedAction: jsonContent['suggestedAction'],
                hasUrgentTimeframe: _parseBool(jsonContent['hasUrgentTimeframe']),
                instructionsLang: jsonContent['instructionsLang'],
                translatedInstructions: _parseStringMap(jsonContent['translatedInstructions']),
                modelVersion: jsonContent['modelVersion'],
                modelSource: jsonContent['modelSource'] ?? 'openai-${ApiConfig.primaryModel}',
                processingTimeMs: _parseInt(jsonContent['processingTimeMs']),
                analysisSessionId: jsonContent['analysisSessionId'],
                disagreementReason: jsonContent['disagreementReason'],
                source: 'ai_analysis',
              );
            } catch (jsonError) {
              debugPrint('Failed to parse JSON from AI response: $jsonError');
              return WasteClassification.fallback(imagePath);
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

  /// Fallback to secondary model (Gemini) when OpenAI fails
  Future<WasteClassification> _fallbackToSecondaryModel(Uint8List imageBytes, String imageName, String region) async {
    try {
      debugPrint('Attempting fallback to Gemini model...');
      
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Prepare request body for secondary OpenAI model
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.secondaryModel1,
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
                "text": "$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Image source: fallback analysis"
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

      // Make HTTP request to the OpenAI API with secondary model
      final response = await http.post(
        Uri.parse('${openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return _processAiResponseData(responseData, imageName, region);
      } else {
        throw Exception('Secondary OpenAI model failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Secondary model fallback failed: $e');
      throw e;
    }
  }

  /// Third OpenAI model fallback
  Future<WasteClassification> _fallbackToThirdModel(Uint8List imageBytes, String imageName, String region) async {
    try {
      debugPrint('Attempting fallback to third OpenAI model...');
      
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Prepare request body for third OpenAI model
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.secondaryModel2,
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
                "text": "$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Image source: third model fallback analysis"
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

      // Make HTTP request to the OpenAI API with third model
      final response = await http.post(
        Uri.parse('${openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return _processAiResponseData(responseData, imageName, region);
      } else {
        throw Exception('Third OpenAI model failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Third model fallback failed: $e');
      throw e;
    }
  }

  /// Tertiary fallback using Gemini model
  Future<WasteClassification> _fallbackToTertiaryModel(Uint8List imageBytes, String imageName, String region) async {
    try {
      debugPrint('Attempting tertiary fallback to Gemini model...');
      
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Prepare request body for Gemini API
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "$_systemPrompt\n\n$_mainClassificationPrompt\n\nAdditional context:\n- Region: $region\n- Image source: tertiary fallback analysis"
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
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

      // Make HTTP request to the Gemini API
      final response = await http.post(
        Uri.parse('${geminiBaseUrl}/models/${ApiConfig.tertiaryModel}:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiApiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
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
          
          return _processAiResponseData(openAiFormat, imageName, region);
        } else {
          throw Exception('Invalid Gemini response format');
        }
      } else {
        throw Exception('Gemini API failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gemini tertiary fallback failed: $e');
      
      // Final fallback - basic heuristic classification
      return _basicHeuristicClassification(imageName, region);
    }
  }

  /// Final fallback using basic heuristic classification
  WasteClassification _basicHeuristicClassification(String imageName, String region) {
    debugPrint('Using final heuristic fallback - basic classification');
    
    // Simple heuristic-based classification as last resort
    return WasteClassification(
      itemName: 'Unidentified Item',
      category: 'Dry Waste',
      subcategory: 'Other',
      explanation: 'Unable to classify automatically. All AI models failed. Please manually review and correct.',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Manual review required',
        steps: [
          'Please review the item manually',
          'Consult local waste management guidelines',
          'When in doubt, treat as dry waste'
        ],
        hasUrgentTimeframe: false,
      ),
      region: region,
      visualFeatures: ['unidentified'],
      alternatives: [],
      imageUrl: imageName,
      confidence: 0.1,
      clarificationNeeded: true,
      riskLevel: 'safe',
      modelSource: 'fallback-heuristic',
      source: 'tertiary_fallback',
    );
  }

  /// Analyze image using file input (for mobile platforms)
  Future<WasteClassification> analyzeImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return analyzeWebImage(imageBytes, imageFile.path);
  }

  /// Segment image for analysis (placeholder implementation)
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

  /// Analyze image segments for web
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

  /// Analyze image segments for mobile
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
  
  /// Safely parses recycling code from various input types
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
  
  /// Safely parses boolean values from various input types
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
  
  /// Safely parses double values from various input types
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
  
  /// Safely parses integer values from various input types
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
  
  /// Safely parses string lists from various input types
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      try {
        return value.map((item) => item.toString()).toList();
      } catch (e) {
        debugPrint('Error parsing string list: $e');
        return [];
      }
    }
    if (value is String) {
      // Handle comma-separated strings
      return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
  
  /// Safely parses string maps from various input types
  Map<String, String>? _parseStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      try {
        return Map<String, String>.from(value.map((k, v) => MapEntry(k.toString(), v.toString())));
      } catch (e) {
        debugPrint('Error parsing string map: $e');
        return null;
      }
    }
    return null;
  }
  
  /// Safely parses image metrics from various input types
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
  
  /// Safely parses alternative classifications from various input types
  List<AlternativeClassification> _parseAlternatives(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      try {
        return value
            .map((alt) {
              try {
                if (alt is Map<String, dynamic>) {
                  return AlternativeClassification.fromJson(alt);
                }
                return null;
              } catch (e) {
                debugPrint('Error parsing alternative classification: $e');
                return null;
              }
            })
            .where((alt) => alt != null)
            .cast<AlternativeClassification>()
            .toList();
      } catch (e) {
        debugPrint('Error parsing alternatives list: $e');
        return [];
      }
    }
    return [];
  }
}
