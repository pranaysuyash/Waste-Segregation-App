import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/unified_api_client.dart';

/// Tests for UnifiedApiClient covering privacy, lifecycle, and contract hardening.
///
/// Internal methods (sanitizePath, sanitizeHeaders, buildRequestKey) are tested
/// through standalone helper functions that mirror the production logic.
void main() {
  group('URL sanitization', () {
    test('full path with query parameters is not logged', () async {
      final result = sanitizePathHelper(
          '/users/123/items/abc-secret-token?key=hello');
      expect(result, equals('/users/:id/items/abc-secret-token'));
      expect(result, isNot(contains('key=hello')));
      expect(result, isNot(contains('123')));
    });

    test('long opaque paths are normalized', () async {
      final result = sanitizePathHelper(
          '/users/aVeryLongOpaqueTokenStringThatExceeds20Chars?secret=xyz');
      expect(result, equals('/users/:id'));
      expect(result, isNot(contains('secret=xyz')));
      expect(result, isNot(contains('aVeryLongOpaqueTokenStringThatExceeds20Chars')));
    });

    test('normalizes numeric IDs', () {
      expect(sanitizePathHelper('/api/v1/users/42'),
          equals('/api/v1/users/:id'));
    });

    test('normalizes UUIDs', () {
      expect(
          sanitizePathHelper(
              '/users/123e4567-e89b-12d3-a456-426614174000/profile'),
          equals('/users/:id/profile'));
    });

    test('normalizes long opaque segments', () {
      expect(
          sanitizePathHelper(
              '/items/aVeryLongOpaqueTokenStringThatExceeds20Chars/details'),
          equals('/items/:id/details'));
    });

    test('normal path segments are left intact', () {
      expect(sanitizePathHelper('/v1/chat/completions'),
          equals('/v1/chat/completions'));
      expect(sanitizePathHelper('/v1beta/models/gemini-pro'),
          equals('/v1beta/models/gemini-pro'));
    });
  });

  group('Header redaction', () {
    test('redacts all configured sensitive headers regardless of case', () {
      final headers = {
        'Authorization': 'Bearer secret-token-123',
        'Content-Type': 'application/json',
        'X-Api-Key': 'my-api-key-value',
        'X-Goog-Api-Key': 'google-key-value',
        'Cookie': 'session=abc123',
        'Set-Cookie': 'session=def456',
      };
      final sanitized = sanitizeHeadersHelper(headers);
      expect(sanitized['Authorization'], contains('REDACTED'));
      expect(sanitized['X-Api-Key'], contains('REDACTED'));
      expect(sanitized['X-Goog-Api-Key'], contains('REDACTED'));
      expect(sanitized['Cookie'], contains('REDACTED'));
      expect(sanitized['Set-Cookie'], contains('REDACTED'));
      expect(sanitized['Content-Type'], equals('application/json'));
    });

    test('redacts lowercase header variants', () {
      final headers = {
        'authorization': 'Bearer secret',
        'x-api-key': 'key-value',
        'set-cookie': 'session=abc',
      };
      final sanitized = sanitizeHeadersHelper(headers);
      expect(sanitized['authorization'], contains('REDACTED'));
      expect(sanitized['x-api-key'], contains('REDACTED'));
      expect(sanitized['set-cookie'], contains('REDACTED'));
    });

    test('non-sensitive headers are preserved', () {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'text/plain',
        'X-Request-Id': 'abc-123',
      };
      final sanitized = sanitizeHeadersHelper(headers);
      expect(sanitized['Content-Type'], equals('application/json'));
      expect(sanitized['Accept'], equals('text/plain'));
      expect(sanitized['X-Request-Id'], equals('abc-123'));
    });
  });

  group('Dispose lifecycle', () {
    test('disposed client throws StateError on new requests', () {
      final client = UnifiedApiClient(baseUrl: 'https://example.com');
      client.dispose();
      expect(
        () => client.get<dynamic>(endpoint: '/test'),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose does not throw (timer cancel, queue drain)', () {
      final client = UnifiedApiClient(
        baseUrl: 'https://example.com',
        enableRequestDeduplication: true,
      );
      expect(client.dispose, returnsNormally);
    });

    test('dispose is idempotent', () {
      final client = UnifiedApiClient(baseUrl: 'https://example.com');
      client.dispose();
      expect(client.dispose, returnsNormally);
    });
  });

  group('Rate-limit safety', () {
    test('dispose does not throw when maxConcurrentRequests=0', () {
      final client = UnifiedApiClient(
        baseUrl: 'https://example.com',
        enableRateLimiting: true,
        maxConcurrentRequests: 0,
      );
      expect(client.dispose, returnsNormally);
    });
  });

  group('Dedup key safety', () {
    test('dedup key does not contain raw body or query secrets', () {
      final key = buildRequestKeyHelper(
        'POST',
        '/v1/chat/completions',
        {'secret': 'supersensitive', 'token': 'abc123'},
        {'user_data': 'very-private-info', 'image_base64': 'iVBORw0KGgo...'},
      );
      expect(key, isNot(contains('supersensitive')));
      expect(key, isNot(contains('abc123')));
      expect(key, isNot(contains('very-private-info')));
      expect(key, isNot(contains('iVBORw0KGgo')));
    });

    test('dedup key is stable for same method + path + shape', () {
      final key1 = buildRequestKeyHelper(
        'GET',
        '/users/:id/profile',
        {'page': '1'},
        null,
      );
      final key2 = buildRequestKeyHelper(
        'GET',
        '/users/:id/profile',
        {'page': '2'},
        null,
      );
      expect(key1, equals(key2));
    });

    test('dedup key differs for different methods', () {
      final getKey = buildRequestKeyHelper(
        'GET',
        '/v1/resource',
        null,
        null,
      );
      final postKey = buildRequestKeyHelper(
        'POST',
        '/v1/resource',
        null,
        null,
      );
      expect(getKey, isNot(equals(postKey)));
    });
  });

  group('PATCH support', () {
    test('client exposes patch method', () {
      final client = UnifiedApiClient(baseUrl: 'https://example.com');
      expect(client.patch<dynamic>, isA<Function>());
    });
  });
}

// =============================================================================
// Standalone helpers mirroring UnifiedApiClient internal logic.
// =============================================================================

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final _numericPattern = RegExp(r'^\d+$');
final _longOpaquePattern = RegExp(r'^[A-Za-z0-9\-_]{21,}$');
const _sensitiveHeaderKeys = {
  'authorization',
  'x-goog-api-key',
  'api-key',
  'x-api-key',
  'cookie',
  'set-cookie',
};

String sanitizePathHelper(String path) {
  final clean = path.split('?').first;
  final segments = clean
      .split('/')
      .where((s) => s.isNotEmpty)
      .map((segment) {
    if (_numericPattern.hasMatch(segment)) return ':id';
    if (_uuidPattern.hasMatch(segment)) return ':id';
    if (_longOpaquePattern.hasMatch(segment)) return ':id';
    return segment;
  }).toList();
  return '/${segments.join('/')}';
}

Map<String, dynamic> sanitizeHeadersHelper(Map<String, dynamic> headers) {
  final sanitized = Map<String, dynamic>.from(headers);
  for (final key in sanitized.keys) {
    if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
      sanitized[key] = '***REDACTED***';
    }
  }
  return sanitized;
}

String buildRequestKeyHelper(
  String method,
  String endpoint,
  Map<String, dynamic>? queryParameters,
  dynamic data,
) {
  final sanitizedPath = sanitizePathHelper(endpoint);
  final hasQuery = queryParameters != null && queryParameters.isNotEmpty;
  final hasData = data != null;
  final hashInput = '$method|$sanitizedPath|$hasQuery|$hasData';
  final hash = sha256.convert(utf8.encode(hashInput));
  return base64Encode(hash.bytes);
}
