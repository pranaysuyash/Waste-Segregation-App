import 'dart:convert';
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
    final endpoint = '$baseUrl/v1/chat/completions';
    
    // Determine MIME type dynamically
    String? mimeType = lookupMimeType('', headerBytes: imageBytes);
    // Default to JPEG if detection fails, as it's common for camera images
    mimeType ??= 'image/jpeg'; 

    // Encode image bytes to base64
    String base64Image = base64Encode(imageBytes);
    
    // System prompt to analyze the waste item
    const systemPrompt = "You are a waste classification expert. Analyze the image to identify the primary waste item. Classify it into one category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, or Non-Waste. If applicable, provide a specific subcategory (e.g., Food Waste, Plastic, E-waste, Sharps, Reusable Item). Give a brief explanation for the classification and suggest a general disposal method.";
    
    // User prompt with the analysis request
    const userPrompt = "Please analyze this image and identify the waste item. Provide the result ONLY in valid JSON format like this: {\"item_name\": \"Identified Item Name\", \"category\": \"Matched Category\", \"subcategory\": \"Matched Subcategory or null\", \"explanation\": \"Brief reason\", \"disposal_method\": \"General disposal tip\", \"material_type\": \"Detected material like Plastic, Metal, Glass, Organic, Paper, etc., or null\", \"recycling_code\": \"Plastic recycling code 1-7 or null\", \"is_recyclable\": true/false/null, \"is_compostable\": true/false/null, \"requires_special_disposal\": true/false/null}";

    // OpenAI-compatible format
    final requestBody = jsonEncode({
      "model": ApiConfig.model,
      "messages": [
        {
          "role": "system",
          "content": systemPrompt
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": userPrompt
            },
            {
              "type": "image_url",
              "image_url": {
                "url": "data:$mimeType;base64,$base64Image"
              }
            }
          ]
        }
      ],
      "temperature": 0.4,
      "max_tokens": 4096,
      "top_p": 1,
      "frequency_penalty": 0,
      "presence_penalty": 0
    });

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: ApiConfig.getHeaders(),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // OpenAI format has choices array with messages
        if (responseBody['choices'] != null && responseBody['choices'].isNotEmpty) {
          final messageContent = responseBody['choices'][0]['message']['content'];
          
          if (messageContent != null) {
             // Clean the response text: remove potential markdown/code blocks
             String cleanedText = messageContent.replaceAll('```json', '').replaceAll('```', '').trim();
             
             try {
                final parsedJson = jsonDecode(cleanedText);
                
                // Validate required fields
                if (parsedJson['item_name'] == null || parsedJson['category'] == null) {
                    throw const FormatException('Missing required fields (item_name or category) in AI response.');
                }

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
                  // No image URL here, should be added by the caller
                );
             } catch (e) {
                 debugPrint('Error decoding JSON from AI: $e Raw Text: $messageContent');
                 throw FormatException('Failed to parse AI response: $e');
             }
          } else {
            throw const FormatException('Missing content in AI response message.');
          }
        } else {
           // Handle cases where the API might block the response due to safety settings or other reasons
           final errorMessage = responseBody['error']?['message'] ?? 'Unknown reason';
           debugPrint('AI Response blocked or empty. Reason: $errorMessage');
           throw FormatException('AI response blocked or empty. Reason: $errorMessage');
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
    final endpoint = '$baseUrl/v1/chat/completions';
    
    // If it's a public URL, we can use it directly without downloading
    bool isPublicUrl = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    String? mimeType;
    String? base64Image;
    
    // If not a public URL or if we need to support local URLs, download and encode
    if (!isPublicUrl) {
      try {
        final response = await _client.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          Uint8List imageBytes = response.bodyBytes;
          // Try to determine MIME type
          mimeType = lookupMimeType(imageUrl, headerBytes: imageBytes) ?? 'image/jpeg';
          base64Image = base64Encode(imageBytes);
        } else {
          throw Exception('Failed to download image from URL: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching image from URL $imageUrl: $e');
        throw Exception('Failed to fetch image from URL: $e');
      }
    }
    
    // System prompt to analyze the waste item
    const systemPrompt = "You are a waste classification expert. Analyze the image to identify the primary waste item. Classify it into one category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, or Non-Waste. If applicable, provide a specific subcategory (e.g., Food Waste, Plastic, E-waste, Sharps, Reusable Item). Give a brief explanation for the classification and suggest a general disposal method.";
    
    // User prompt with the analysis request
    const userPrompt = "Please analyze this image and identify the waste item. Provide the result ONLY in valid JSON format like this: {\"item_name\": \"Identified Item Name\", \"category\": \"Matched Category\", \"subcategory\": \"Matched Subcategory or null\", \"explanation\": \"Brief reason\", \"disposal_method\": \"General disposal tip\", \"material_type\": \"Detected material like Plastic, Metal, Glass, Organic, Paper, etc., or null\", \"recycling_code\": \"Plastic recycling code 1-7 or null\", \"is_recyclable\": true/false/null, \"is_compostable\": true/false/null, \"requires_special_disposal\": true/false/null}";

    // Configure the image URL based on whether it's a public URL or a base64-encoded image
    var imageUrlConfig = isPublicUrl 
        ? { "url": imageUrl }
        : { "url": "data:$mimeType;base64,$base64Image" };

    // OpenAI-compatible format
    final requestBody = jsonEncode({
      "model": ApiConfig.model,
      "messages": [
        {
          "role": "system",
          "content": systemPrompt
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": userPrompt
            },
            {
              "type": "image_url",
              "image_url": imageUrlConfig
            }
          ]
        }
      ],
      "temperature": 0.4,
      "max_tokens": 4096,
      "top_p": 1,
      "frequency_penalty": 0,
      "presence_penalty": 0
    });

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: ApiConfig.getHeaders(),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // OpenAI format has choices array with messages
        if (responseBody['choices'] != null && responseBody['choices'].isNotEmpty) {
          final messageContent = responseBody['choices'][0]['message']['content'];
          
          if (messageContent != null) {
             // Clean the response text: remove potential markdown/code blocks
             String cleanedText = messageContent.replaceAll('```json', '').replaceAll('```', '').trim();
             
             try {
                final parsedJson = jsonDecode(cleanedText);
                
                // Validate required fields
                if (parsedJson['item_name'] == null || parsedJson['category'] == null) {
                    throw const FormatException('Missing required fields (item_name or category) in AI response.');
                }

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
                );
             } catch (e) {
                 debugPrint('Error decoding JSON from AI (URL method): $e Raw Text: $messageContent');
                 throw FormatException('Failed to parse AI response (URL method): $e');
             }
          } else {
            throw const FormatException('Missing content in AI response message (URL method).');
          }
        } else {
           // Handle cases where the API might block the response due to safety settings or other reasons
           final errorMessage = responseBody['error']?['message'] ?? 'Unknown reason';
           debugPrint('AI Response blocked or empty (URL method). Reason: $errorMessage');
           throw FormatException('AI response blocked or empty (URL method). Reason: $errorMessage');
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