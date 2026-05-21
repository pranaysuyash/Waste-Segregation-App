import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:waste_segregation_app/models/waste_classification.dart'
    show WasteClassification;

import '../../models/waste_classification.dart' show WasteClassification;
import '../ai_failure.dart';
import 'ai_provider_response.dart';
import 'classification_provider.dart';

/// Thin HTTP client for Gemini generateContent.
///
/// Responsibilities (only):
/// - Build the generateContent request body.
/// - Attach the base64-encoded image as inline_data.
/// - POST to [baseUrl]/models/{model}:generateContent.
/// - Return a raw [AiProviderResponse] with extracted text content
///   and usage metadata.
/// - Map transport and HTTP errors to [AiFailure].
///
/// Does **not** build classification prompts, parse [WasteClassification],
/// apply local guidelines, cache, record spending, decide fallback, or
/// compress images.
class GeminiProviderClient implements ClassificationProvider {
  GeminiProviderClient({
    required Dio dio,
    required String baseUrl,
    required String apiKey,
    required String model,
  })  : _dio = dio,
        _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model;

  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;
  final String _model;

  // ---------------------------------------------------------------------------
  // ClassificationProvider interface
  // ---------------------------------------------------------------------------

  @override
  String get providerName => 'gemini';

  @override
  String get modelName => _model;

  /// Rough estimated cost per call at ~1 500 input + 800 output tokens.
  /// For accurate telemetry use the token counts from [AiProviderResponse].
  @override
  double? get estimatedCostPerCall {
    // gemini-2.0-flash: ~$0.000075/1K input, ~$0.0003/1K output
    const inputTokens = 1500;
    const outputTokens = 800;
    return (inputTokens / 1000) * 0.000075 + (outputTokens / 1000) * 0.0003;
  }

  // ---------------------------------------------------------------------------

  /// Sends a generateContent request with an attached image.
  ///
  /// [imageBytes] should already be compressed — this client does not
  /// perform any compression.
  ///
  /// [prompt] is the combined system + user prompt string, since Gemini
  /// does not have a separate system role in the same way as OpenAI.
  /// Defaults to an empty string for [ClassificationProvider] interface parity;
  /// callers should always pass a real prompt.
  @override
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    // ClassificationProvider interface params
    String? clientHash,
    String? region,
    String? lang,
    String? requestId, // ignored by Gemini direct client
    CancelToken? cancelToken,
    // Gemini-specific extra params
    int maxOutputTokens = 1500,
    double temperature = 0.1,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final requestBody = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      },
    };

    late final Response<dynamic> response;
    try {
      response = await _dio.post(
        '$_baseUrl/models/$_model:generateContent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
        ),
        data: requestBody,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _throwAiFailure(e);
    }

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final usage = data['usageMetadata'] as Map<String, dynamic>?;

      String? textContent;
      try {
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              textContent = parts[0]['text'] as String?;
            }
          }
        }
      } catch (_) {
        // Malformed response structure — return raw response map
        // without textContent; the caller can handle it.
      }

      return AiProviderResponse(
        provider: 'gemini',
        model: _model,
        rawResponseMap: data,
        textContent: textContent,
        inputTokens: usage?['promptTokenCount'] as int?,
        outputTokens: usage?['candidatesTokenCount'] as int?,
      );
    }

    throw AiFailure(
      _failureKindFromStatus(response.statusCode ?? 0),
      'Gemini API error ${response.statusCode}: ${response.data}',
      provider: 'gemini',
      model: _model,
    );
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

  Never _throwAiFailure(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      throw AiFailure(
        AiFailureKind.cancelled,
        'Analysis cancelled by user',
        provider: 'gemini',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      throw AiFailure(
        _failureKindFromStatus(statusCode),
        'Gemini HTTP error $statusCode: ${e.response?.data}',
        provider: 'gemini',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Connection timeout - please check your internet connection',
        provider: 'gemini',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Request timeout - the server took too long to respond',
        provider: 'gemini',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Upload timeout - failed to send image data',
        provider: 'gemini',
        model: _model,
        cause: e,
      );
    }
    throw AiFailure(
      AiFailureKind.network,
      'Network error: ${e.message}',
      provider: 'gemini',
      model: _model,
      cause: e,
    );
  }
}
