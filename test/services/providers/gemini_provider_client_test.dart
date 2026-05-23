import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/providers/gemini_provider_client.dart';

/// Fake Dio that captures the last request and returns configurable responses.
class _MockDio implements Dio {
  _MockDio({this.statusCode = 200, this.responseData, this.error});

  int statusCode;
  Map<String, dynamic>? responseData;
  DioException? error;

  String? lastPath;
  Object? lastData;
  Options? lastOptions;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastData = data;
    lastOptions = options;

    if (error != null) throw error!;

    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: responseData ?? <String, dynamic>{'candidates': []},
    ) as Response<T>;
  }

  @override
  BaseOptions get options => BaseOptions();
  @override
  set options(BaseOptions _) {}
  @override
  HttpClientAdapter get httpClientAdapter =>
      throw UnimplementedError('not used');
  @override
  set httpClientAdapter(HttpClientAdapter _) {}
  @override
  Interceptors get interceptors => Interceptors();
  @override
  Transformer get transformer => throw UnimplementedError('not used');
  @override
  set transformer(Transformer _) {}

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  final imageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);

  group('GeminiProviderClient', () {
    test('request body shape includes contents and generationConfig', () async {
      final mockDio = _MockDio(
        responseData: {
          'candidates': [
            {
              'content': {
                'parts': [{'text': '{}'}],
              },
            },
          ],
          'usageMetadata': {
            'promptTokenCount': 10,
            'candidatesTokenCount': 5,
          },
        },
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'Classify this waste',
      );

      final body = mockDio.lastData as Map<String, dynamic>;
      expect(body['contents'], isA<List>());
      expect(body['generationConfig'], isA<Map>());
      expect(body['generationConfig']['temperature'], equals(0.1));
      expect(body['generationConfig']['maxOutputTokens'], equals(1500));

      final parts = (body['contents'] as List).first['parts'] as List;
      expect(parts[0]['text'], equals('Classify this waste'));
      expect(parts[1]['inline_data']['mime_type'], equals('image/jpeg'));
    });

    test('headers include Content-Type and x-goog-api-key', () async {
      final mockDio = _MockDio(
        responseData: {
          'candidates': [
            {
              'content': {
                'parts': [{'text': '{}'}],
              },
            },
          ],
          'usageMetadata': {
            'promptTokenCount': 10,
            'candidatesTokenCount': 5,
          },
        },
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(mockDio.lastOptions?.headers?['Content-Type'],
          equals('application/json'));
      expect(mockDio.lastOptions?.headers?['x-goog-api-key'],
          equals('test-gemini-key'));
    });

    test('textContent extracted from candidates[0].content.parts[0].text',
        () async {
      final mockDio = _MockDio(
        responseData: {
          'candidates': [
            {
              'content': {
                'parts': [{'text': '{"itemName":"Can"}'}],
              },
            },
          ],
          'usageMetadata': {
            'promptTokenCount': 100,
            'candidatesTokenCount': 50,
          },
        },
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      final result = await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(result.textContent, equals('{"itemName":"Can"}'));
    });

    test('tokens extracted from usageMetadata', () async {
      final mockDio = _MockDio(
        responseData: {
          'candidates': [
            {
              'content': {
                'parts': [{'text': '{"itemName":"Can"}'}],
              },
            },
          ],
          'usageMetadata': {
            'promptTokenCount': 150,
            'candidatesTokenCount': 80,
          },
        },
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      final result = await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(result.inputTokens, equals(150));
      expect(result.outputTokens, equals(80));
    });

    test('malformed response (no candidates) returns null textContent',
        () async {
      final mockDio = _MockDio(
        responseData: {
          'candidates': [],
          'usageMetadata': {
            'promptTokenCount': 10,
            'candidatesTokenCount': 5,
          },
        },
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      final result = await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(result.textContent, isNull);
      expect(result.rawResponseMap, isNotEmpty);
    });

    test('DioException cancel throws AiFailure.cancelled', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/v1beta/models/gemini-2.0-flash:generateContent'),
        ),
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      expect(
        () =>
            client.analyze(imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>(
            (f) => f.kind == AiFailureKind.cancelled)),
      );
    });

    test('401 throws AiFailure.auth', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(
              path: '/v1beta/models/gemini-2.0-flash:generateContent'),
          response: Response(
            requestOptions: RequestOptions(
                path: '/v1beta/models/gemini-2.0-flash:generateContent'),
            statusCode: 401,
            data: 'Unauthorized',
          ),
        ),
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'bad-key',
        model: 'gemini-2.0-flash',
      );

      expect(
        () =>
            client.analyze(imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.auth)),
      );
    });

    test('429 throws AiFailure.rateLimited', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(
              path: '/v1beta/models/gemini-2.0-flash:generateContent'),
          response: Response(
            requestOptions: RequestOptions(
                path: '/v1beta/models/gemini-2.0-flash:generateContent'),
            statusCode: 429,
            data: 'Too Many Requests',
          ),
        ),
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      expect(
        () =>
            client.analyze(imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(
            predicate<AiFailure>((f) => f.kind == AiFailureKind.rateLimited)),
      );
    });

    test('503 throws AiFailure.providerUnavailable', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(
              path: '/v1beta/models/gemini-2.0-flash:generateContent'),
          response: Response(
            requestOptions: RequestOptions(
                path: '/v1beta/models/gemini-2.0-flash:generateContent'),
            statusCode: 503,
            data: 'Service Unavailable',
          ),
        ),
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      expect(
        () =>
            client.analyze(imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>(
            (f) => f.kind == AiFailureKind.providerUnavailable)),
      );
    });

    test('connection timeout throws AiFailure.network', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(
              path: '/v1beta/models/gemini-2.0-flash:generateContent'),
        ),
      );

      final client = GeminiProviderClient(
        dio: mockDio,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-gemini-key',
        model: 'gemini-2.0-flash',
      );

      expect(
        () =>
            client.analyze(imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.network)),
      );
    });
  });
}
