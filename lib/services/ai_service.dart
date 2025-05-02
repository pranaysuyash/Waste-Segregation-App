import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math' show pow;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openai_api/openai_api.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';

class AiService {
  final String baseUrl;
  final String apiKey;
  
  // Simple segmentation parameters - can be adjusted based on needs
  static const int segmentGridSize = 3; // 3x3 grid for basic segmentation
  static const double minSegmentArea = 0.05; // Minimum 5% of image area
  static const int objectDetectionSegments = 9; // Maximum number of segments to return

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

  // Analyze web image using Gemini Vision API with retry and fallback
  Future<WasteClassification> analyzeWebImage(
      Uint8List imageBytes, String imageName, {int retryCount = 0, int maxRetries = 3}) async {
    try {
      final String base64Image = _bytesToBase64(imageBytes);

      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content":
                "You are an expert in waste classification and recycling that can identify items from images. "
                    "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Analyze this item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ]
      };

      // Create the web image URL with base64 data
      final String webImageUrl = 'web_image:data:image/jpeg;base64,$base64Image';
      
      // Make HTTP request to the Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return _processAiResponseData(responseData, webImageUrl);
      }
      // Handle service unavailable (503) with retry logic
      else if (response.statusCode == 503 && retryCount < maxRetries) {
        debugPrint('Gemini API overloaded (503). Retry ${retryCount + 1} of $maxRetries...');
        
        // Exponential backoff - wait longer between each retry (500ms × 2^retryCount)
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        
        // Retry with incremented count
        return analyzeWebImage(imageBytes, imageName, retryCount: retryCount + 1, maxRetries: maxRetries);
      } 
      // If all retries fail, fall back to OpenAI
      else if (response.statusCode == 503) {
        debugPrint('Gemini API unavailable after $maxRetries retries. Falling back to OpenAI...');
        return await _fallbackToOpenAIWeb(imageBytes, imageName);
      }
      // Handle other errors
      else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an exception (like network error), try fallback if we've exhausted retries
      if (retryCount >= maxRetries) {
        debugPrint('Exception after $maxRetries retries. Attempting OpenAI fallback...');
        try {
          return await _fallbackToOpenAIWeb(imageBytes, imageName);
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
          rethrow; // If fallback also fails, rethrow the original error
        }
      }
      debugPrint('Error analyzing web image (try $retryCount): $e');
      
      // For other types of errors, increment retry count and try again
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return analyzeWebImage(imageBytes, imageName, retryCount: retryCount + 1, maxRetries: maxRetries);
      }
      
      rethrow;
    }
  }
  
  // OpenAI fallback for web images
  Future<WasteClassification> _fallbackToOpenAIWeb(Uint8List imageBytes, String imageName) async {
    try {
      debugPrint('Using OpenAI fallback for web image analysis');
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Create HTTP client for OpenAI API
      final client = http.Client();
      
      // Prepare the request body for OpenAI's vision API
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.openAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. "
                "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Analyze this item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 800
      };
      
      // Make the API request to OpenAI
      final response = await client.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );
      
      // Create the web image URL with base64 data
      final String webImageUrl = 'web_image:data:image/jpeg;base64,$base64Image';
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Process the OpenAI response using the same logic as the Gemini response
        return _processAiResponseData(responseData, webImageUrl);
      } else {
        debugPrint('OpenAI fallback error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI fallback failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in OpenAI web fallback: $e');
      rethrow;
    }
  }

  // Analyze image using Gemini Vision API (OpenAI-compatible endpoint)
  // Image segmentation method for mobile platforms
  Future<List<Rect>> segmentImage(dynamic image) async {
    try {
      List<Rect> segments = [];
      
      // For simplicity, we'll create a grid-based segmentation
      // In a real app, this would use ML for object detection
      
      if (image is File) {
        // Wait for the image dimensions to be determined
        final File file = image;
        
        // Create a simple grid of segments
        final List<Rect> gridSegments = _createGridSegments();
        
        // Add all segments to the list
        segments.addAll(gridSegments);
        
        // Return the segments
        return segments;
      } else if (image is Uint8List) {
        // Create a simple grid of segments
        final List<Rect> gridSegments = _createGridSegments();
        
        // Add all segments to the list
        segments.addAll(gridSegments);
        
        // Return the segments
        return segments;
      } else {
        throw Exception('Unsupported image type for segmentation');
      }
    } catch (e) {
      debugPrint('Error segmenting image: $e');
      rethrow;
    }
  }
  
  // Create a grid of segments
  List<Rect> _createGridSegments() {
    final List<Rect> segments = [];
    
    // Create a grid of segments
    final double cellWidth = 1.0 / segmentGridSize;
    final double cellHeight = 1.0 / segmentGridSize;
    
    for (int row = 0; row < segmentGridSize; row++) {
      for (int col = 0; col < segmentGridSize; col++) {
        // Calculate segment bounds (normalized 0-1)
        final double left = col * cellWidth;
        final double top = row * cellHeight;
        
        // Create the segment rectangle
        final Rect segment = Rect.fromLTWH(
          left, 
          top, 
          cellWidth, 
          cellHeight
        );
        
        segments.add(segment);
      }
    }
    
    // Create one larger center segment
    final double centerSize = 0.6; // 60% of the image
    final double centerOffset = (1.0 - centerSize) / 2;
    final Rect centerSegment = Rect.fromLTWH(
      centerOffset,
      centerOffset,
      centerSize,
      centerSize
    );
    segments.add(centerSegment);
    
    return segments;
  }
  
  // Analyze image segments for mobile platforms with retry and fallback
  Future<WasteClassification> analyzeImageSegments(
      File imageFile, List<Rect> segments, {int retryCount = 0, int maxRetries = 3}) async {
    try {
      // For now, we'll just use the whole image AI analysis
      // In a more advanced implementation, we'd crop and analyze just the selected segments
      
      // Get the base64 encoded image data
      final String base64Image = await _imageToBase64(imageFile);
      
      // Describe the selected regions in the prompt
      final String segmentDescription = _describeSegments(segments);
      
      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content":
                "You are an expert in waste classification and recycling that can identify items from images. "
                    "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Focus on the following regions of the image: $segmentDescription\n\n"
                    "Analyze the item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ]
      };
      
      // Make HTTP request to the Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return _processAiResponseData(responseData, imageFile.path);
      }
      // Handle service unavailable (503) with retry logic
      else if (response.statusCode == 503 && retryCount < maxRetries) {
        debugPrint('Gemini API overloaded (503). Retry ${retryCount + 1} of $maxRetries...');
        
        // Exponential backoff - wait longer between each retry (500ms × 2^retryCount)
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        
        // Retry with incremented count
        return analyzeImageSegments(imageFile, segments, retryCount: retryCount + 1, maxRetries: maxRetries);
      } 
      // If all retries fail, fall back to OpenAI
      else if (response.statusCode == 503) {
        debugPrint('Gemini API unavailable after $maxRetries retries. Falling back to OpenAI...');
        return await _fallbackToOpenAISegments(imageFile, segments);
      }
      // Handle other errors
      else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image segments: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an exception (like network error), try fallback if we've exhausted retries
      if (retryCount >= maxRetries) {
        debugPrint('Exception after $maxRetries retries. Attempting OpenAI fallback...');
        try {
          return await _fallbackToOpenAISegments(imageFile, segments);
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
          rethrow; // If fallback also fails, rethrow the original error
        }
      }
      debugPrint('Error analyzing image segments (try $retryCount): $e');
      
      // For other types of errors, increment retry count and try again
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return analyzeImageSegments(imageFile, segments, retryCount: retryCount + 1, maxRetries: maxRetries);
      }
      
      rethrow;
    }
  }
  
  // OpenAI fallback for segmented images
  Future<WasteClassification> _fallbackToOpenAISegments(File imageFile, List<Rect> segments) async {
    try {
      debugPrint('Using OpenAI fallback for segmented image analysis');
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Describe the selected regions in the prompt
      final String segmentDescription = _describeSegments(segments);
      
      // Create HTTP client for OpenAI API
      final client = http.Client();
      
      // Prepare the request body for OpenAI's vision API with segment information
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.openAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. "
                "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Focus on the following regions of the image: $segmentDescription\n\n"
                    "Analyze the item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 800
      };
      
      // Make the API request to OpenAI
      final response = await client.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Process the OpenAI response using the same logic as the Gemini response
        return _processAiResponseData(responseData, imageFile.path);
      } else {
        debugPrint('OpenAI fallback error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI fallback failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in OpenAI segments fallback: $e');
      rethrow;
    }
  }
  
  // Analyze web image segments with retry and fallback
  Future<WasteClassification> analyzeImageSegmentsWeb(
      Uint8List imageBytes, List<Rect> segments, String imageName, {int retryCount = 0, int maxRetries = 3}) async {
    try {
      // Get the base64 encoded image data
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Describe the selected regions in the prompt
      final String segmentDescription = _describeSegments(segments);
      
      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content":
                "You are an expert in waste classification and recycling that can identify items from images. "
                    "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Focus on the following regions of the image: $segmentDescription\n\n"
                    "Analyze the item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ]
      };
      
      // Create the web image URL with base64 data
      final String webImageUrl = 'web_image:data:image/jpeg;base64,$base64Image';
      
      // Make HTTP request to the Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return _processAiResponseData(responseData, webImageUrl);
      }
      // Handle service unavailable (503) with retry logic
      else if (response.statusCode == 503 && retryCount < maxRetries) {
        debugPrint('Gemini API overloaded (503). Retry ${retryCount + 1} of $maxRetries...');
        
        // Exponential backoff - wait longer between each retry (500ms × 2^retryCount)
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        
        // Retry with incremented count
        return analyzeImageSegmentsWeb(imageBytes, segments, imageName, retryCount: retryCount + 1, maxRetries: maxRetries);
      } 
      // If all retries fail, fall back to OpenAI
      else if (response.statusCode == 503) {
        debugPrint('Gemini API unavailable after $maxRetries retries. Falling back to OpenAI...');
        return await _fallbackToOpenAISegmentsWeb(imageBytes, segments, imageName);
      }
      // Handle other errors
      else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze web image segments: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an exception (like network error), try fallback if we've exhausted retries
      if (retryCount >= maxRetries) {
        debugPrint('Exception after $maxRetries retries. Attempting OpenAI fallback...');
        try {
          return await _fallbackToOpenAISegmentsWeb(imageBytes, segments, imageName);
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
          rethrow; // If fallback also fails, rethrow the original error
        }
      }
      debugPrint('Error analyzing web image segments (try $retryCount): $e');
      
      // For other types of errors, increment retry count and try again
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return analyzeImageSegmentsWeb(imageBytes, segments, imageName, retryCount: retryCount + 1, maxRetries: maxRetries);
      }
      
      rethrow;
    }
  }
  
  // OpenAI fallback for web segmented images
  Future<WasteClassification> _fallbackToOpenAISegmentsWeb(Uint8List imageBytes, List<Rect> segments, String imageName) async {
    try {
      debugPrint('Using OpenAI fallback for web segmented image analysis');
      final String base64Image = _bytesToBase64(imageBytes);
      
      // Describe the selected regions in the prompt
      final String segmentDescription = _describeSegments(segments);
      
      // Create HTTP client for OpenAI API
      final client = http.Client();
      
      // Prepare the request body for OpenAI's vision API with segment information
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.openAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. "
                "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Focus on the following regions of the image: $segmentDescription\n\n"
                    "Analyze the item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 800
      };
      
      // Make the API request to OpenAI
      final response = await client.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );
      
      // Create the web image URL with base64 data
      final String webImageUrl = 'web_image:data:image/jpeg;base64,$base64Image';
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Process the OpenAI response using the same logic as the Gemini response
        return _processAiResponseData(responseData, webImageUrl);
      } else {
        debugPrint('OpenAI fallback error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI fallback failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in OpenAI web segments fallback: $e');
      rethrow;
    }
  }
  
  // Helper to describe segments in natural language for the AI prompt
  String _describeSegments(List<Rect> segments) {
    if (segments.isEmpty) {
      return "the entire image";
    }
    
    // Prioritize center or larger segments in the description
    final List<String> descriptions = [];
    
    // Sort segments by area (largest first)
    final sortedSegments = List<Rect>.from(segments)
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    
    // Describe each segment using relative positioning
    for (int i = 0; i < sortedSegments.length; i++) {
      final segment = sortedSegments[i];
      
      // Determine position in image
      String position = "";
      
      // Vertical position
      if (segment.top < 0.33) {
        position += "top";
      } else if (segment.top + segment.height > 0.66) {
        position += "bottom";
      } else {
        position += "middle";
      }
      
      // Horizontal position
      if (segment.left < 0.33) {
        position += " left";
      } else if (segment.left + segment.width > 0.66) {
        position += " right";
      } else {
        position += " center";
      }
      
      // Add size descriptor for very large or small segments
      final area = segment.width * segment.height;
      String sizePrefix = "";
      if (area > 0.25) { // Larger than 25% of image
        sizePrefix = "large ";
      } else if (area < 0.1) { // Smaller than 10% of image
        sizePrefix = "small ";
      }
      
      descriptions.add("the $sizePrefix$position region");
      
      // Limit to 3 descriptions to avoid overwhelming the prompt
      if (i >= 2) break;
    }
    
    return descriptions.join(", ");
  }
  
  // Process AI response and create WasteClassification object
  Future<WasteClassification> _processAiResponse(
      Map<String, dynamic> requestBody, String imageUrl) async {
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
      return _processAiResponseData(responseData, imageUrl);
    } else {
      debugPrint('Error response: ${response.body}');
      throw Exception('Failed to analyze image: ${response.statusCode}');
    }
  }
  
  // Process AI response data and create WasteClassification object
  WasteClassification _processAiResponseData(
      Map<String, dynamic> responseData, String imageUrl) {
    // Extract content from the OpenAI-formatted response
    final String textContent =
        responseData['choices'][0]['message']['content'] ?? '{}';

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

    // Handle recyclingCode which might come as an int from AI
    String? recyclingCode;
    if (parsedJson['recyclingCode'] != null) {
      recyclingCode = parsedJson['recyclingCode'].toString();
    }
    
    return WasteClassification(
      itemName: parsedJson['itemName'] ?? 'Unknown Item',
      category: parsedJson['category'] ?? 'Unknown Category',
      subcategory: parsedJson['subcategory'],
      materialType: parsedJson['materialType'],
      explanation: parsedJson['explanation'] ?? 'No explanation provided',
      disposalMethod: parsedJson['disposalMethod'],
      recyclingCode: recyclingCode,
      isRecyclable: parsedJson['isRecyclable'] != null
          ? parsedJson['isRecyclable'] is bool
              ? parsedJson['isRecyclable']
              : parsedJson['isRecyclable'].toString().toLowerCase() ==
                  'true'
          : null,
      isCompostable: parsedJson['isCompostable'] != null
          ? parsedJson['isCompostable'] is bool
              ? parsedJson['isCompostable']
              : parsedJson['isCompostable'].toString().toLowerCase() ==
                  'true'
          : null,
      requiresSpecialDisposal: parsedJson['requiresSpecialDisposal'] != null
          ? parsedJson['requiresSpecialDisposal'] is bool
              ? parsedJson['requiresSpecialDisposal']
              : parsedJson['requiresSpecialDisposal']
                      .toString()
                      .toLowerCase() ==
                  'true'
          : null,
      colorCode: parsedJson['colorCode'] ?? colorCode,
      imageUrl: imageUrl,
    );
  }
  
  // Fallback to OpenAI API when Gemini is unavailable
  Future<WasteClassification> _fallbackToOpenAI(File imageFile) async {
    try {
      debugPrint('Using OpenAI fallback for image analysis');
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Create HTTP client for OpenAI API
      final client = http.Client();
      
      // Prepare the request body for OpenAI's vision API
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.openAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert in waste classification and recycling that can identify items from images. "
                "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Analyze this item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 800
      };
      
      // Make the API request to OpenAI
      final response = await client.post(
        Uri.parse('${ApiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode(requestBody),
      );
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Process the OpenAI response using the same logic as the Gemini response
        return _processAiResponseData(responseData, imageFile.path);
      } else {
        debugPrint('OpenAI fallback error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI fallback failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in OpenAI fallback: $e');
      rethrow;
    }
  }
  
  // Analyze image with retry and fallback mechanism
  Future<WasteClassification> analyzeImage(File imageFile, {int retryCount = 0, int maxRetries = 3}) async {
    try {
      final String base64Image = await _imageToBase64(imageFile);

      // Prepare request body using OpenAI format for Gemini with enhanced prompting
      final Map<String, dynamic> requestBody = {
        "model": ApiConfig.model,
        "messages": [
          {
            "role": "system",
            "content":
                "You are an expert in waste classification and recycling that can identify items from images. "
                    "You have deep knowledge of international waste segregation standards, recycling codes, and proper disposal methods."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Analyze this item in detail and classify it according to the following hierarchy:\n\n1. Main category (choose exactly one):\n   - Wet Waste (organic, compostable)\n   - Dry Waste (recyclable)\n   - Hazardous Waste (requires special handling)\n   - Medical Waste (potentially contaminated)\n   - Non-Waste (reusable items, edible food)\n\n2. Subcategory (choose the most specific one that applies):\n   For Wet Waste: Food Waste, Garden Waste, Animal Waste, Biodegradable Packaging, Other Wet Waste\n   For Dry Waste: Paper, Plastic, Glass, Metal, Carton, Textile, Rubber, Wood, Other Dry Waste\n   For Hazardous Waste: Electronic Waste, Batteries, Chemical Waste, Paint Waste, Light Bulbs, Aerosol Cans, Automotive Waste, Other Hazardous Waste\n   For Medical Waste: Sharps, Pharmaceutical, Infectious, Non-Infectious, Other Medical Waste\n   For Non-Waste: Reusable Items, Donatable Items, Edible Food, Repurposable Items, Other Non-Waste\n\n3. Material Type: Identify the specific material (e.g., PET plastic, cardboard, food scraps, etc.)\n\n4. For plastics, identify the recycling code if possible (1-7)\n\n5. Determine if the item is:\n   - Recyclable (true/false)\n   - Compostable (true/false)\n   - Requires special disposal (true/false)\n\n6. Provide a detailed explanation of why it belongs to the assigned categories and how it should be properly disposed.\n\nFormat the response as a valid JSON object with these fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode"
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ]
      };

      // Make HTTP request to the Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Use the existing _processAiResponseData method to process the response
        return _processAiResponseData(responseData, imageFile.path);
      }
      // Handle service unavailable (503) with retry logic and fallback
      else if (response.statusCode == 503 && retryCount < maxRetries) {
        debugPrint('Gemini API overloaded (503). Retry ${retryCount + 1} of $maxRetries...');
        
        // Exponential backoff - wait longer between each retry (500ms × 2^retryCount)
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        
        // Retry with incremented count
        return analyzeImage(imageFile, retryCount: retryCount + 1, maxRetries: maxRetries);
      } 
      // If all retries fail, fall back to OpenAI
      else if (response.statusCode == 503) {
        debugPrint('Gemini API unavailable after $maxRetries retries. Falling back to OpenAI...');
        return await _fallbackToOpenAI(imageFile);
      }
      // Handle other errors
      else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an exception (like network error), try fallback if we've exhausted retries
      if (retryCount >= maxRetries) {
        debugPrint('Exception after $maxRetries retries. Attempting OpenAI fallback...');
        try {
          return await _fallbackToOpenAI(imageFile);
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
          rethrow; // If fallback also fails, rethrow the original error
        }
      }
      debugPrint('Error analyzing image (try $retryCount): $e');
      
      // For other types of errors, increment retry count and try again
      if (retryCount < maxRetries) {
        final waitTime = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
        await Future.delayed(waitTime);
        return analyzeImage(imageFile, retryCount: retryCount + 1, maxRetries: maxRetries);
      }
      
      rethrow;
    }
  }
}
