import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/waste_classification.dart';
import '../utils/constants.dart';

class AiService {
  final String baseUrl;
  final String apiKey;

  AiService({
    String? baseUrl,
    String? apiKey,
  })  : baseUrl = baseUrl ?? ApiConfig.geminiBaseUrl,
        apiKey = apiKey ?? ApiConfig.apiKey;

  // Convert image to base64 for API request
  Future<String> _imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }
  
  // Convert bytes to base64 (for web)
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  // Analyze web image using Gemini Vision API (OpenAI-compatible endpoint)
  Future<WasteClassification> analyzeWebImage(Uint8List imageBytes, String imageName) async {
    try {
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. " +
                       "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Analyze this item in detail and classify it according to the following hierarchy:\n\n" +
                       "1. Main category (choose exactly one):\n" +
                       "   - Wet Waste (organic, compostable)\n" +
                       "   - Dry Waste (recyclable)\n" +
                       "   - Hazardous Waste (requires special handling)\n" +
                       "   - Medical Waste (potentially contaminated)\n" +
                       "   - Non-Waste (reusable items, edible food)\n\n" +
                       
                       "2. Subcategory (choose the most specific one that applies):\n" +
                       "   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n" +
                       "   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n" +
                       "   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n" +
                       "   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n" +
                       "   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n" +
                       
                       "3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n" +
                       
                       "4. For plastics, identify the recycling code if possible (1-7)\n\n" +
                       
                       "5. Determine if the item is:\n" +
                       "   - Recyclable (true/false)\n" +
                       "   - Compostable (true/false)\n" +
                       "   - Requires special disposal (true/false)\n\n" +
                       
                       "6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\n" +
                       
                       "Format the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, " +
                       "recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ]
      };

      // Make HTTP request to OpenAI-compatible Gemini API endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extract content from the OpenAI-formatted response
        final String textContent = responseData['choices'][0]['message']['content'] ?? '{}';
        
        // Parse the JSON from the text content
        final RegExp jsonRegex = RegExp(r'\{.*\}', dotAll: true);
        final Match? jsonMatch = jsonRegex.firstMatch(textContent);
        
        if (jsonMatch == null) {
          throw Exception('Could not parse AI response');
        }
        
        final String jsonString = jsonMatch.group(0) ?? '{}';
        final Map<String, dynamic> parsedJson = jsonDecode(jsonString);
        
        // Get the appropriate color code based on category or subcategory
        String? colorCode = WasteInfo.colorCoding[parsedJson['category']];
        if (colorCode == null && parsedJson['subcategory'] != null) {
          colorCode = WasteInfo.colorCoding[parsedJson['subcategory']];
        }
        
        // Create WasteClassification object with a data URL for web
        // Store the actual image data to ensure it's displayed properly
        return WasteClassification(
          itemName: parsedJson['itemName'] ?? 'Unknown Item',
          category: parsedJson['category'] ?? 'Unknown Category',
          subcategory: parsedJson['subcategory'],
          materialType: parsedJson['materialType'],
          explanation: parsedJson['explanation'] ?? 'No explanation provided',
          disposalMethod: parsedJson['disposalMethod'],
          recyclingCode: parsedJson['recyclingCode'],
          isRecyclable: parsedJson['isRecyclable'] != null ? 
              parsedJson['isRecyclable'] is bool ? 
                  parsedJson['isRecyclable'] : 
                  parsedJson['isRecyclable'].toString().toLowerCase() == 'true' : 
              null,
          isCompostable: parsedJson['isCompostable'] != null ? 
              parsedJson['isCompostable'] is bool ? 
                  parsedJson['isCompostable'] : 
                  parsedJson['isCompostable'].toString().toLowerCase() == 'true' : 
              null,
          requiresSpecialDisposal: parsedJson['requiresSpecialDisposal'] != null ? 
              parsedJson['requiresSpecialDisposal'] is bool ? 
                  parsedJson['requiresSpecialDisposal'] : 
                  parsedJson['requiresSpecialDisposal'].toString().toLowerCase() == 'true' : 
              null,
          colorCode: parsedJson['colorCode'] ?? colorCode,
          imageUrl: 'web_image:data:image/jpeg;base64,$base64Image', // Data URL with image data
        );
      } else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing web image: $e');
      rethrow;
    }
  }

  // Analyze image using Gemini Vision API (OpenAI-compatible endpoint)
  Future<WasteClassification> analyzeImage(File imageFile) async {
    try {
      final String base64Image = await _imageToBase64(imageFile);
      
      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. " +
                       "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Analyze this item in detail and classify it according to the following hierarchy:\n\n" +
                       "1. Main category (choose exactly one):\n" +
                       "   - Wet Waste (organic, compostable)\n" +
                       "   - Dry Waste (recyclable)\n" +
                       "   - Hazardous Waste (requires special handling)\n" +
                       "   - Medical Waste (potentially contaminated)\n" +
                       "   - Non-Waste (reusable items, edible food)\n\n" +
                       
                       "2. Subcategory (choose the most specific one that applies):\n" +
                       "   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n" +
                       "   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n" +
                       "   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n" +
                       "   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n" +
                       "   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n" +
                       
                       "3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n" +
                       
                       "4. For plastics, identify the recycling code if possible (1-7)\n\n" +
                       
                       "5. Determine if the item is:\n" +
                       "   - Recyclable (true/false)\n" +
                       "   - Compostable (true/false)\n" +
                       "   - Requires special disposal (true/false)\n\n" +
                       
                       "6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\n" +
                       
                       "Format the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, " +
                       "recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ]
      };

      // Make HTTP request to OpenAI-compatible Gemini API endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extract content from the OpenAI-formatted response
        final String textContent = responseData['choices'][0]['message']['content'] ?? '{}';
        
        // Parse the JSON from the text content
        final RegExp jsonRegex = RegExp(r'\{.*\}', dotAll: true);
        final Match? jsonMatch = jsonRegex.firstMatch(textContent);
        
        if (jsonMatch == null) {
          throw Exception('Could not parse AI response');
        }
        
        final String jsonString = jsonMatch.group(0) ?? '{}';
        final Map<String, dynamic> parsedJson = jsonDecode(jsonString);
        
        // Get the appropriate color code based on category or subcategory
        String? colorCode = WasteInfo.colorCoding[parsedJson['category']];
        if (colorCode == null && parsedJson['subcategory'] != null) {
          colorCode = WasteInfo.colorCoding[parsedJson['subcategory']];
        }
        
        // Create WasteClassification object
        return WasteClassification(
          itemName: parsedJson['itemName'] ?? 'Unknown Item',
          category: parsedJson['category'] ?? 'Unknown Category',
          subcategory: parsedJson['subcategory'],
          materialType: parsedJson['materialType'],
          explanation: parsedJson['explanation'] ?? 'No explanation provided',
          disposalMethod: parsedJson['disposalMethod'],
          recyclingCode: parsedJson['recyclingCode'],
          isRecyclable: parsedJson['isRecyclable'] != null ? 
              parsedJson['isRecyclable'] is bool ? 
                  parsedJson['isRecyclable'] : 
                  parsedJson['isRecyclable'].toString().toLowerCase() == 'true' : 
              null,
          isCompostable: parsedJson['isCompostable'] != null ? 
              parsedJson['isCompostable'] is bool ? 
                  parsedJson['isCompostable'] : 
                  parsedJson['isCompostable'].toString().toLowerCase() == 'true' : 
              null,
          requiresSpecialDisposal: parsedJson['requiresSpecialDisposal'] != null ? 
              parsedJson['requiresSpecialDisposal'] is bool ? 
                  parsedJson['requiresSpecialDisposal'] : 
                  parsedJson['requiresSpecialDisposal'].toString().toLowerCase() == 'true' : 
              null,
          colorCode: parsedJson['colorCode'] ?? colorCode,
          imageUrl: imageFile.path,
        );
      } else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      rethrow;
    }
  }
}