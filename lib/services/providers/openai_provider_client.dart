import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:waste_segregation_app/models/waste_classification.dart'
    show WasteClassification;

import '../../models/waste_classification.dart' show WasteClassification;
import '../ai_failure.dart';
import '../../utils/production_safety_config.dart';
import 'ai_provider_response.dart';
import 'classification_provider.dart';

/// Thin HTTP client for OpenAI Chat Completions.
///
/// Responsibilities (only):
/// - Build the Chat Completions request body.
/// - Attach the base64-encoded image as a data URL.
/// - POST to [baseUrl]/chat/completions.
/// - Return a raw [AiProviderResponse] with usage metadata.
/// - Map transport and HTTP errors to [AiFailure].
///
/// Does **not** build classification prompts, parse [WasteClassification],
/// apply local guidelines, cache, record spending, decide fallback, or
/// compress images.
class OpenAiProviderClient implements ClassificationProvider {
  OpenAiProviderClient({
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

  static const String _endpoint = '/chat/completions';

  // ---------------------------------------------------------------------------
  // ClassificationProvider interface
  // ---------------------------------------------------------------------------

  @override
  String get providerName => 'openai';

  @override
  String get modelName => _model;

  /// Rough estimated cost per call at ~1 500 input + 800 output tokens.
  /// For accurate telemetry use the token counts from [AiProviderResponse].
  @override
  double? get estimatedCostPerCall {
    // gpt-4.1-nano: ~$0.0001/1K input, ~$0.0004/1K output
    const inputTokens = 1500;
    const outputTokens = 800;
    return (inputTokens / 1000) * 0.0001 + (outputTokens / 1000) * 0.0004;
  }

  /// [ClassificationProvider] adapter: treats [prompt] as the system prompt
  /// and passes a fixed user message to request JSON classification.
  ///
  /// Callers that need full control over the system/user split should call
  /// [analyzeWithSplitPrompts] directly.
  @override
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    // Extra params accepted for interface parity; not used by OpenAI wire call.
    String? clientHash,
    String? region,
    String? lang,
    String? requestId, // ignored by OpenAI direct client
    CancelToken? cancelToken,
  }) {
    return analyzeWithSplitPrompts(
      imageBytes: imageBytes,
      mimeType: mimeType,
      systemPrompt: prompt,
      userPrompt: 'Classify this waste item and return the JSON object.',
      cancelToken: cancelToken,
    );
  }

  // ---------------------------------------------------------------------------

  /// Sends a Chat Completions request with an attached image.
  ///
  /// [imageBytes] should already be compressed — this client does not
  /// perform any compression.
  ///
  /// Prefer this method when you need separate [systemPrompt] and [userPrompt].
  /// The [ClassificationProvider.analyze] adapter calls this internally.
  Future<AiProviderResponse> analyzeWithSplitPrompts({
    required Uint8List imageBytes,
    required String mimeType,
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1500,
    double temperature = 0.1,
    CancelToken? cancelToken,
  }) async {
    ProductionSafetyConfig.guardClientAiCall('OpenAI Provider Client');
    if (ProductionSafetyConfig.hasPlaceholderKey(_apiKey)) {
      throw AiFailure(
        AiFailureKind.auth,
        'OpenAI provider client blocked: placeholder/missing API key.',
        provider: 'openai',
        model: _model,
      );
    }

    final base64Image = base64Encode(imageBytes);

    final requestBody = <String, dynamic>{
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        },
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
    };

    late final Response<dynamic> response;
    try {
      response = await _dio.post(
        '$_baseUrl$_endpoint',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
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
      final usage = data['usage'] as Map<String, dynamic>?;

      return AiProviderResponse(
        provider: 'openai',
        model: _model,
        rawResponseMap: data,
        inputTokens: usage?['prompt_tokens'] as int?,
        outputTokens: usage?['completion_tokens'] as int?,
      );
    }

    throw AiFailure(
      _failureKindFromStatus(response.statusCode ?? 0),
      'OpenAI API error ${response.statusCode}: ${response.data}',
      provider: 'openai',
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
        provider: 'openai',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      throw AiFailure(
        _failureKindFromStatus(statusCode),
        'OpenAI HTTP error $statusCode: ${e.response?.data}',
        provider: 'openai',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Connection timeout - please check your internet connection',
        provider: 'openai',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Request timeout - the server took too long to respond',
        provider: 'openai',
        model: _model,
        cause: e,
      );
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw AiFailure(
        AiFailureKind.network,
        'Upload timeout - failed to send image data',
        provider: 'openai',
        model: _model,
        cause: e,
      );
    }
    throw AiFailure(
      AiFailureKind.network,
      'Network error: ${e.message}',
      provider: 'openai',
      model: _model,
      cause: e,
    );
  }
}
