import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/api_version.dart';

void main() {
  group('ApiVersion', () {
    group('defaultVersion', () {
      test('creates with v1 and default service', () {
        final version = ApiVersion.defaultVersion();
        expect(version.version, 'v1');
        expect(version.serviceName, 'default');
        expect(version.pathPrefix, '');
      });
    });

    group('openAI', () {
      test('creates with default v1 version', () {
        final version = ApiVersion.openAI();
        expect(version.version, 'v1');
        expect(version.serviceName, 'openai');
        expect(version.pathPrefix, '/v1');
        expect(version.headers, containsPair('OpenAI-Beta', 'assistants=v2'));
      });

      test('accepts custom version string', () {
        final version = ApiVersion.openAI(version: 'v2');
        expect(version.version, 'v2');
        expect(version.pathPrefix, '/v1');
      });

      test('accepts additional headers', () {
        final version = ApiVersion.openAI(
          additionalHeaders: {'X-Custom': 'value'},
        );
        expect(version.headers, containsPair('X-Custom', 'value'));
        expect(version.headers, containsPair('OpenAI-Beta', 'assistants=v2'));
      });
    });

    group('gemini', () {
      test('creates with default v1beta version', () {
        final version = ApiVersion.gemini();
        expect(version.version, 'v1beta');
        expect(version.serviceName, 'gemini');
        expect(version.pathPrefix, '/v1beta');
      });

      test('accepts custom version and headers', () {
        final version = ApiVersion.gemini(
          version: 'v1',
          additionalHeaders: {'X-Debug': 'true'},
        );
        expect(version.version, 'v1');
        expect(version.headers, containsPair('X-Debug', 'true'));
      });
    });

    group('firebase', () {
      test('creates with default v1 version', () {
        final version = ApiVersion.firebase();
        expect(version.version, 'v1');
        expect(version.serviceName, 'firebase');
        expect(version.pathPrefix, '');
      });

      test('accepts custom version and headers', () {
        final version = ApiVersion.firebase(
          version: 'v2',
          additionalHeaders: {'X-Region': 'us-central1'},
        );
        expect(version.version, 'v2');
        expect(version.headers, containsPair('X-Region', 'us-central1'));
      });
    });

    group('fromMap / toMap', () {
      test('round-trips correctly', () {
        final original = ApiVersion(
          version: 'v2',
          serviceName: 'openai',
          pathPrefix: '/v2',
          headerName: 'API-Version',
          headers: {'X-Custom': 'val'},
          isDeprecated: true,
          deprecationDate: DateTime(2026, 6, 1),
          migrationGuide: 'https://docs.example.com/migrate',
        );

        final map = original.toMap();
        final reconstructed = ApiVersion.fromMap(map);

        expect(reconstructed.version, original.version);
        expect(reconstructed.serviceName, original.serviceName);
        expect(reconstructed.pathPrefix, original.pathPrefix);
        expect(reconstructed.headerName, original.headerName);
        expect(reconstructed.headers, original.headers);
        expect(reconstructed.isDeprecated, original.isDeprecated);
        expect(reconstructed.deprecationDate, original.deprecationDate);
        expect(reconstructed.migrationGuide, original.migrationGuide);
      });

      test('handles null deprecationDate', () {
        final map = {
          'version': 'v1',
          'service_name': 'test',
          'path_prefix': '',
          'header_name': '',
          'headers': {},
          'is_deprecated': false,
          'deprecation_date': null,
          'migration_guide': null,
        };

        final version = ApiVersion.fromMap(map);
        expect(version.deprecationDate, isNull);
        expect(version.migrationGuide, isNull);
      });

      test('handles missing optional fields', () {
        final map = {
          'version': 'v1',
          'service_name': 'test',
        };

        final version = ApiVersion.fromMap(map);
        expect(version.version, 'v1');
        expect(version.serviceName, 'test');
        expect(version.pathPrefix, '');
        expect(version.headerName, '');
        expect(version.headers, {});
        expect(version.isDeprecated, false);
        expect(version.deprecationDate, isNull);
        expect(version.migrationGuide, isNull);
      });
    });

    group('equality', () {
      test('equal versions are equal', () {
        final a = ApiVersion.openAI();
        final b = ApiVersion.openAI();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different versions are not equal', () {
        final a = ApiVersion.openAI();
        final b = ApiVersion.gemini();
        expect(a, isNot(equals(b)));
      });

      test('same service with different path is not equal', () {
        final a =
            ApiVersion(version: 'v1', serviceName: 'test', pathPrefix: '/v1');
        final b =
            ApiVersion(version: 'v1', serviceName: 'test', pathPrefix: '/v2');
        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes key fields', () {
        final version =
            ApiVersion(version: 'v2', serviceName: 'mysvc', pathPrefix: '/v2');
        final str = version.toString();
        expect(str, contains('v2'));
        expect(str, contains('mysvc'));
      });
    });
  });
}
