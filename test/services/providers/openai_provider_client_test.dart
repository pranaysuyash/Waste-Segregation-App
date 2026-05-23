import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/ai_failure.dart';
import 'package:waste_segregation_app/services/providers/openai_provider_client.dart';

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
      data: responseData ?? <String, dynamic>{'choices': []},
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

  group('OpenAiProviderClient', () {
    test('request body shape includes model, messages, max_tokens, temperature',
        () async {
      final mockDio = _MockDio(
        responseData: {
          'choices': [
            {'message': {'content': '{}'}},
          ],
          'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
        },
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test prompt',
      );

      final body = mockDio.lastData as Map<String, dynamic>;
      expect(body['model'], equals('gpt-4.1-nano'));
      expect(body['messages'], isA<List>());
      expect(body['max_tokens'], equals(1500));
      expect(body['temperature'], equals(0.1));
    });

    test('headers include Content-Type and Authorization', () async {
      final mockDio = _MockDio(
        responseData: {
          'choices': [
            {'message': {'content': '{}'}},
          ],
          'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
        },
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(mockDio.lastOptions?.headers?['Content-Type'],
          equals('application/json'));
      expect(mockDio.lastOptions?.headers?['Authorization'],
          equals('Bearer sk-test-key'));
    });

    test('tokens are extracted from response usage', () async {
      final mockDio = _MockDio(
        responseData: {
          'choices': [
            {'message': {'content': '{"itemName":"Test"}'}},
          ],
          'usage': {'prompt_tokens': 150, 'completion_tokens': 80},
        },
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      final result = await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(result.inputTokens, equals(150));
      expect(result.outputTokens, equals(80));
    });

    test('DioException cancel throws AiFailure.cancelled', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/chat/completions'),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>(
            (f) => f.kind == AiFailureKind.cancelled)),
      );
    });

    test('401 throws AiFailure.auth', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 401,
            data: 'Unauthorized',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'bad-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.auth)),
      );
    });

    test('403 throws AiFailure.auth', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 403,
            data: 'Forbidden',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'bad-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.auth)),
      );
    });

    test('429 throws AiFailure.rateLimited', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 429,
            data: 'Too Many Requests',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(
            predicate<AiFailure>((f) => f.kind == AiFailureKind.rateLimited)),
      );
    });

    test('502 throws AiFailure.providerUnavailable', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 502,
            data: 'Bad Gateway',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>(
            (f) => f.kind == AiFailureKind.providerUnavailable)),
      );
    });

    test('503 throws AiFailure.providerUnavailable', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 503,
            data: 'Service Unavailable',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>(
            (f) => f.kind == AiFailureKind.providerUnavailable)),
      );
    });

    test('malformed response (500) throws AiFailure.unknown', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 500,
            data: 'Internal Server Error',
          ),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.unknown)),
      );
    });

    test('placeholder key throws AiFailure.auth before any HTTP call',
        () async {
      final mockDio = _MockDio(
        responseData: {
          'choices': [
            {'message': {'content': '{}'}},
          ],
        },
      );

      // Should fail before calling post
      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'your-openai-api-key-here',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.auth)),
      );

      expect(mockDio.lastPath, isNull);
    });

    test('connection timeout throws AiFailure.network', () async {
      final mockDio = _MockDio(
        error: DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/chat/completions'),
        ),
      );

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      expect(
        () => client.analyze(
            imageBytes: imageBytes, mimeType: 'image/jpeg', prompt: 'test'),
        throwsA(predicate<AiFailure>((f) => f.kind == AiFailureKind.network)),
      );
    });

    test('rawResponseMap contains full API response', () async {
      final responseData = {
        'id': 'chatcmpl-abc123',
        'object': 'chat.completion',
        'choices': [
          {'message': {'content': '{"itemName":"Bottle"}'}},
        ],
        'usage': {'prompt_tokens': 100, 'completion_tokens': 50},
      };
      final mockDio = _MockDio(responseData: responseData);

      final client = OpenAiProviderClient(
        dio: mockDio,
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
        model: 'gpt-4.1-nano',
      );

      final result = await client.analyze(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        prompt: 'test',
      );

      expect(result.rawResponseMap, equals(responseData));
      expect(result.provider, equals('openai'));
      expect(result.model, equals('gpt-4.1-nano'));
    });
  });
}
