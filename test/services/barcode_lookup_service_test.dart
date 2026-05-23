import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waste_segregation_app/services/barcode_lookup_service.dart';

void main() {
  group('BarcodeLookupService', () {
    test('rejects empty barcode', () async {
      final service = BarcodeLookupService();
      final result = await service.lookup('');

      expect(result.found, isFalse);
      expect(result.failureReason, contains('too short'));
    });

    test('rejects barcode shorter than 4 characters', () async {
      final service = BarcodeLookupService();
      final result = await service.lookup('123');

      expect(result.found, isFalse);
      expect(result.failureReason, contains('too short'));
    });

    test('returns found=false when API returns non-1 status', () async {
      final service = BarcodeLookupService(
        client: _mockClient(_productNotFoundResponse),
      );

      final result = await service.lookup('0000000000000');

      expect(result.found, isFalse);
      expect(result.failureReason, contains('Product not found'));
    });

    test('maps packaging tags to waste category', () async {
      final service = BarcodeLookupService(
        client: _mockClient((request) => http.Response(
              jsonEncode({
                'status': 1,
                'product': {
                  'product_name': 'Test Cola',
                  'brands': 'TestBrand',
                  'packaging_tags': ['en:plastic-bottle'],
                  'categories_tags': ['en:beverages'],
                },
              }),
              200,
            )),
      );

      final result = await service.lookup('8901234567890');

      expect(result.found, isTrue);
      expect(result.category, equals('Dry Waste'));
      expect(result.subcategory, equals('Plastic Bottle'));
      expect(result.confidence, greaterThanOrEqualTo(0.90));
      expect(result.productName, equals('Test Cola'));
      expect(result.brand, equals('TestBrand'));
    });

    test('maps food category tags when no packaging match', () async {
      final service = BarcodeLookupService(
        client: _mockClient((request) => http.Response(
              jsonEncode({
                'status': 1,
                'product': {
                  'product_name': 'Apple Juice',
                  'packaging_tags': [],
                  'categories_tags': ['en:beverages', 'en:fruits'],
                },
              }),
              200,
            )),
      );

      final result = await service.lookup('8901234567890');

      expect(result.found, isTrue);
      expect(result.category, equals('Wet Waste'));
      expect(result.confidence, greaterThanOrEqualTo(0.80));
    });

    test('defaults to Dry Waste with low confidence for unknown packaging',
        () async {
      final service = BarcodeLookupService(
        client: _mockClient((request) => http.Response(
              jsonEncode({
                'status': 1,
                'product': {
                  'product_name': 'Mystery Product',
                  'packaging_tags': ['en:something-unknown'],
                  'categories_tags': [],
                },
              }),
              200,
            )),
      );

      final result = await service.lookup('8901234567890');

      expect(result.found, isTrue);
      expect(result.category, equals('Dry Waste'));
      expect(result.subcategory, equals('Packaged Item'));
      expect(result.confidence, equals(0.60));
    });

    test('returns not found on HTTP error', () async {
      final service = BarcodeLookupService(
        client: _mockClient((request) => http.Response('Not Found', 404)),
      );

      final result = await service.lookup('8901234567890');

      expect(result.found, isFalse);
      expect(result.failureReason, contains('HTTP 404'));
    });

    test('handles network error gracefully', () async {
      final service = BarcodeLookupService(
        client: _crashingClient(),
      );

      final result = await service.lookup('8901234567890');

      expect(result.found, isFalse);
      expect(result.failureReason, contains('Lookup error'));
    });

    test('caches successful lookups', () async {
      var callCount = 0;
      final service = BarcodeLookupService(
        client: _mockClient((request) {
          callCount++;
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'packaging_tags': ['en:glass-bottle'],
                'categories_tags': [],
              },
            }),
            200,
          );
        }),
      );

      final r1 = await service.lookup('8901234567890');
      final r2 = await service.lookup('8901234567890');

      expect(r1.found, isTrue);
      expect(r1.source, equals('network'));
      expect(r2.found, isTrue);
      expect(r2.source, equals('cache'));
      expect(callCount, equals(1));
    });

    test('trims whitespace from barcode', () async {
      final service = BarcodeLookupService(
        client: _mockClient(_productNotFoundResponse),
      );

      final result = await service.lookup('  12345678  ');

      // Should not crash — the trimmed barcode goes to the API.
      expect(result.found, isFalse);
    });
  });
}

http.Response _productNotFoundResponse(http.Request request) =>
    http.Response(jsonEncode({'status': 0, 'status_verbose': 'product not found'}), 200);

http.Client _mockClient(http.Response Function(http.Request) handler) {
  return MockClient((request) async => handler(request));
}

http.Client _crashingClient() {
  return MockClient((request) async {
    throw const SocketException('Network unreachable');
  });
}
