import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Import mime package
import '../models/waste_classification.dart';
import '../utils/constants.dart'; // Import ApiConfig and WasteInfo

class AiService {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  AiService({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.geminiBaseUrl, // Use ApiConfig
        apiKey = apiKey ?? ApiConfig.apiKey, // Use ApiConfig
        _client = client ?? http.Client();

  Future<WasteClassification> classifyImage(Uint8List imageBytes) async {
    final endpoint = '$baseUrl/v1beta/models/${ApiConfig.model}:generateContent?key=$apiKey';
    
    // Determine MIME type dynamically
    String? mimeType = lookupMimeType('', headerBytes: imageBytes);
    // Default to JPEG if detection fails, as it's common for camera images
    mimeType ??= 'image/jpeg'; 

    // Encode image bytes to base64
    String base64Image = base64Encode(imageBytes);

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Analyze the image to identify the primary waste item. Classify it into one category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, or Non-Waste. If applicable, provide a specific subcategory (e.g., Food Waste, Plastic, E-waste, Sharps, Reusable Item). Give a brief explanation for the classification and suggest a general disposal method. Provide the result ONLY in valid JSON format like this: {"item_name": "Identified Item Name", "category": "Matched Category", "subcategory": "Matched Subcategory or null", "explanation": "Brief reason", "disposal_method": "General disposal tip", "material_type": "Detected material like Plastic, Metal, Glass, Organic, Paper, etc., or null", "recycling_code": "Plastic recycling code 1-7 or null", "is_recyclable": true/false/null, "is_compostable": true/false/null, "requires_special_disposal": true/false/null}"
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
        // "temperature": 0.4, // Adjust creativity/determinism
        // "topK": 32,
        // "topP": 1,
        // "maxOutputTokens": 4096, // Adjust as needed
        // "stopSequences": []
        // Add safety settings if needed
         "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      }
    });

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // Defensive programming: Check if 'candidates' exists and is not empty
        if (responseBody['candidates'] != null && responseBody['candidates'].isNotEmpty) {
          final content = responseBody['candidates'][0]['content'];
          
          // Check if 'parts' exists and is not empty
          if (content['parts'] != null && content['parts'].isNotEmpty) {
             final textPart = content['parts'][0]['text'];
             
             // Clean the response text: remove potential markdown/code blocks
             String cleanedText = textPart.replaceAll('```json
', '').replaceAll('
```', '').trim();
             
             try {
                final parsedJson = jsonDecode(cleanedText);
                
                // Validate required fields
                if (parsedJson['item_name'] == null || parsedJson['category'] == null) {
                    throw const FormatException('Missing required fields (item_name or category) in AI response.');
                }

                // // Map color based on category/subcategory - Removed as color handled by AppTheme
                // String? colorCode = WasteInfo.colorCoding[parsedJson['category']];
                // if (parsedJson['subcategory'] != null && WasteInfo.colorCoding[parsedJson['subcategory']] != null) {
                //   colorCode = WasteInfo.colorCoding[parsedJson['subcategory']];
                // }

                return WasteClassification(
                  itemName: parsedJson['item_name'],
                  category: parsedJson['category'],
                  subcategory: parsedJson['subcategory'], // Can be null
                  explanation: parsedJson['explanation'] ?? 'No explanation provided.', // Provide default
                  disposalMethod: parsedJson['disposal_method'] ?? 'Follow local guidelines.', // Provide default
                  materialType: parsedJson['material_type'], // Can be null
                  recyclingCode: parsedJson['recycling_code']?.toString(), // Ensure it's string, can be null
                  isRecyclable: parsedJson['is_recyclable'], // Can be null
                  isCompostable: parsedJson['is_compostable'], // Can be null
                  requiresSpecialDisposal: parsedJson['requires_special_disposal'], // Can be null
                  timestamp: DateTime.now(),
                  // colorCode: colorCode, // Color handled by theme
                  // No image URL here, should be added by the caller
                );
             } catch (e) {
                 debugPrint('Error decoding JSON from AI: $e
Raw Text: $textPart');
                 throw FormatException('Failed to parse AI response: $e');
             }
          } else {
            throw const FormatException('Missing 'parts' in AI response content.');
          }
        } else {
           // Handle cases where the API might block the response due to safety settings or other reasons
           String blockReason = responseBody['promptFeedback']?['blockReason'] ?? 'Unknown reason';
           debugPrint('AI Response blocked or empty. Reason: $blockReason');
           throw FormatException('AI response blocked or empty. Reason: $blockReason');
        }
      } else {
        debugPrint('AI Error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to classify image (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('AI Service Exception: $e');
      // Re-throw specific exception types if needed, or a generic one
       if (e is FormatException) {
         rethrow; // Keep format exceptions specific
       } else {
         throw Exception('Error communicating with AI service: $e');
       }
    }
  }

    // Overload for providing image URL (less efficient for API, might be useful internally)
    Future<WasteClassification> classifyImageUrl(String imageUrl) async {
    final endpoint = '$baseUrl/v1beta/models/${ApiConfig.model}:generateContent?key=$apiKey';
    
    // Fetch image bytes from URL
    Uint8List imageBytes;
    String mimeType = 'image/jpeg'; // Default MIME type
    try {
        final response = await _client.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
            // Try to determine MIME type from headers or extension if possible
            final detectedMime = lookupMimeType(imageUrl, headerBytes: imageBytes);
            if (detectedMime != null) {
              mimeType = detectedMime;
            }
        } else {
            throw Exception('Failed to download image from URL: ${response.statusCode}');
        }
    } catch (e) {
         debugPrint('Error fetching image from URL $imageUrl: $e');
         throw Exception('Failed to fetch image from URL: $e');
    }

    // Encode image bytes to base64
    String base64Image = base64Encode(imageBytes);

     final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Analyze the image to identify the primary waste item. Classify it into one category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, or Non-Waste. If applicable, provide a specific subcategory (e.g., Food Waste, Plastic, E-waste, Sharps, Reusable Item). Give a brief explanation for the classification and suggest a general disposal method. Provide the result ONLY in valid JSON format like this: {"item_name": "Identified Item Name", "category": "Matched Category", "subcategory": "Matched Subcategory or null", "explanation": "Brief reason", "disposal_method": "General disposal tip", "material_type": "Detected material like Plastic, Metal, Glass, Organic, Paper, etc., or null", "recycling_code": "Plastic recycling code 1-7 or null", "is_recyclable": true/false/null, "is_compostable": true/false/null, "requires_special_disposal": true/false/null}"
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
        // Add safety settings if needed
         "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      }
    });

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

       if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        if (responseBody['candidates'] != null && responseBody['candidates'].isNotEmpty) {
          final content = responseBody['candidates'][0]['content'];
          
          if (content['parts'] != null && content['parts'].isNotEmpty) {
             final textPart = content['parts'][0]['text'];
             String cleanedText = textPart.replaceAll('```json
', '').replaceAll('
```', '').trim();
             
             try {
                final parsedJson = jsonDecode(cleanedText);
                
                if (parsedJson['item_name'] == null || parsedJson['category'] == null) {
                    throw const FormatException('Missing required fields (item_name or category) in AI response.');
                }

                // // Map color based on category/subcategory - Removed
                // String? colorCode = WasteInfo.colorCoding[parsedJson['category']];
                // if (parsedJson['subcategory'] != null && WasteInfo.colorCoding[parsedJson['subcategory']] != null) {
                //   colorCode = WasteInfo.colorCoding[parsedJson['subcategory']];
                // }

                return WasteClassification(
                  imageUrl: imageUrl, // Include the original URL
                  itemName: parsedJson['item_name'],
                  category: parsedJson['category'],
                  subcategory: parsedJson['subcategory'],
                  explanation: parsedJson['explanation'] ?? 'No explanation provided.',
                  disposalMethod: parsedJson['disposal_method'] ?? 'Follow local guidelines.',
                  materialType: parsedJson['material_type'],
                  recyclingCode: parsedJson['recycling_code']?.toString(),
                  isRecyclable: parsedJson['is_recyclable'],
                  isCompostable: parsedJson['is_compostable'],
                  requiresSpecialDisposal: parsedJson['requires_special_disposal'],
                  timestamp: DateTime.now(),
                  // colorCode: colorCode, // Color handled by theme
                );
             } catch (e) {
                 debugPrint('Error decoding JSON from AI (URL method): $e
Raw Text: $textPart');
                 throw FormatException('Failed to parse AI response (URL method): $e');
             }
          } else {
            throw const FormatException('Missing 'parts' in AI response content (URL method).');
          }
        } else {
           String blockReason = responseBody['promptFeedback']?['blockReason'] ?? 'Unknown reason';
            debugPrint('AI Response blocked or empty (URL method). Reason: $blockReason');
           throw FormatException('AI response blocked or empty (URL method). Reason: $blockReason');
        }
      } else {
         debugPrint('AI Error (URL method): ${response.statusCode} ${response.body}');
        throw Exception('Failed to classify image from URL (${response.statusCode})');
      }
    } catch (e) {
       debugPrint('AI Service Exception (URL method): $e');
        if (e is FormatException) {
         rethrow;
       } else {
         throw Exception('Error communicating with AI service (URL method): $e');
       }
    }
  }
}
