import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';

class MiniCpmService {
  MiniCpmService({
    this.apiBaseUrl = _kDefaultApiUrl,
    this.apiKey,
    this.useLocalInference = false,
  });

  static const String _kDefaultApiUrl =
      'https://api.openbmb.ai/v1/chat/completions';
  static const String _kDefaultApiKey = 'sk-minicpm-free'; // Free tier key

  final String apiBaseUrl;
  final String? apiKey;
  final bool useLocalInference;

  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
    if (useLocalInference) {
      WasteAppLogger.info(
        'MiniCPM-V 4.6 initialized for local inference '
        '(requires llama.cpp or Ollama mobile integration)',
      );
    } else {
      WasteAppLogger.info(
        'MiniCPM-V 4.6 initialized for API inference '
        '(free tier key available)',
      );
    }
  }

  String get _effectiveApiKey =>
      apiKey ?? const String.fromEnvironment('MINICPM_API_KEY',
          defaultValue: _kDefaultApiKey);

  Future<WasteClassification> classifyCrop(
    Uint8List cropBytes,
    String imageName, {
    String? region,
  }) async {
    if (!_initialized) await initialize();

    if (useLocalInference) {
      return _classifyLocal(cropBytes, imageName, region: region);
    }
    return _classifyCloud(cropBytes, imageName, region: region);
  }

  Future<WasteClassification> _classifyCloud(
    Uint8List cropBytes,
    String imageName, {
    String? region,
  }) async {
    try {
      final base64Image = base64Encode(cropBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse(apiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_effectiveApiKey',
        },
        body: jsonEncode({
          'model': 'openbmb/MiniCPM-V-4.6',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': dataUri},
                },
                {
                  'type': 'text',
                  'text': _buildPrompt(region: region),
                },
              ],
            },
          ],
          'max_tokens': 256,
          'temperature': 0.1,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('MiniCPM API error: HTTP ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        throw Exception('MiniCPM API: empty response');
      }

      return _parseResponse(content, imageName, region: region);
    } catch (e) {
      WasteAppLogger.warning('MiniCPM cloud classification failed',
          error: e);
      rethrow;
    }
  }

  Future<WasteClassification> _classifyLocal(
    Uint8List cropBytes,
    String imageName, {
    String? region,
  }) async {
    // Local inference via llama.cpp/Ollama mobile
    // Implement when flutter_llama.cpp or similar is integrated
    throw UnimplementedError(
      'Local MiniCPM-V 4.6 inference requires flutter_llama.cpp.\n'
      'Use cloud API or switch to useLocalInference=false for now.',
    );
  }

  String _buildPrompt({String? region}) {
    final regionContext = region != null && region.isNotEmpty
        ? ' The user is located in $region.'
        : '';
    return '''You are a waste classification AI. Identify the item in this image and classify it.
Return JSON with these fields:
- itemName: string (what the item is)
- category: "Wet Waste" | "Dry Waste" | "Hazardous Waste" | "Medical Waste" | "Non-Waste"
- subcategory: string (more specific type)
- material: string (primary material)
- explanation: string (2-3 sentences)
- disposalMethod: string (how to dispose)
- isRecyclable: boolean
- isCompostable: boolean
- requiresSpecialDisposal: boolean
- confidence: number (0.0-1.0)$regionContext''';
  }

  WasteClassification _parseResponse(
    String content,
    String imageName, {
    String? region,
  }) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return WasteClassification(
        itemName: json['itemName'] as String? ?? 'Unknown Item',
        category: json['category'] as String? ?? 'Dry Waste',
        subCategory: json['subcategory'] as String?,
        materials: json['material'] != null ? [json['material'] as String] : null,
        explanation: json['explanation'] as String? ?? '',
        disposalMethod: json['disposalMethod'] as String?,
        disposalInstructions: DisposalInstructions(
          primaryMethod: json['disposalMethod'] as String? ?? 'Review required',
          steps: [
            'Identified as ${json['itemName'] ?? "unknown item"}',
            'Category: ${json['category'] ?? "unknown"}',
            'Follow local disposal guidelines for ${json['material'] ?? "this material"}',
          ],
          hasUrgentTimeframe:
              json['requiresSpecialDisposal'] == true,
        ),
        visualFeatures: [],
        alternatives: [],
        region: region ?? 'Global',
        confidence: (json['confidence'] as num?)?.toDouble(),
        isRecyclable: json['isRecyclable'] as bool?,
        isCompostable: json['isCompostable'] as bool?,
        requiresSpecialDisposal:
            json['requiresSpecialDisposal'] as bool?,
        imageUrl: imageName,
        modelSource: 'MiniCPM-V-4.6',
      );
    } catch (e) {
      WasteAppLogger.warning('MiniCPM parse failed', error: e);
      return WasteClassification.fallback(imageName);
    }
  }
}
