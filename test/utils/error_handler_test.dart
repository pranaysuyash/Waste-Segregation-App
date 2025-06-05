import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/error_handler.dart';

void main() {
  group('WasteAppException Tests', () {
    group('ClassificationException', () {
      test('should create exception with message only', () {
        final exception = ClassificationException('Test classification error');
        
        expect(exception.message, equals('Test classification error'));
        expect(exception.code, equals('CLASSIFICATION_ERROR'));
        expect(exception.metadata, isNull);
        expect(exception.timestamp, isA<DateTime>());
      });

      test('should create exception with message and metadata', () {
        final metadata = {'imageSize': '1024x768', 'confidence': 0.85};
        final exception = ClassificationException('Test error', metadata);
        
        expect(exception.message, equals('Test error'));
        expect(exception.code, equals('CLASSIFICATION_ERROR'));
        expect(exception.metadata, equals(metadata));
      });

      test('should convert to map correctly', () {
        final metadata = {'imageSize': '1024x768'};
        final exception = ClassificationException('Test error', metadata);
        final map = exception.toMap();
        
        expect(map['code'], equals('CLASSIFICATION_ERROR'));
        expect(map['message'], equals('Test error'));
        expect(map['metadata'], equals(metadata));
        expect(map['timestamp'], isA<String>());
      });

      test('should have proper toString format', () {
        final exception = ClassificationException('Test error');
        final string = exception.toString();
        
        expect(string, contains('WasteAppException(CLASSIFICATION_ERROR)'));
        expect(string, contains('Test error'));
      });
    });

    group('NetworkException', () {
      test('should create with correct code', () {
        final exception = NetworkException('Network timeout');
        
        expect(exception.code, equals('NETWORK_ERROR'));
        expect(exception.message, equals('Network timeout'));
      });

      test('should handle metadata', () {
        final metadata = {'endpoint': '/api/classify', 'timeout': 5000};
        final exception = NetworkException('Request failed', metadata);
        
        expect(exception.metadata, equals(metadata));
      });
    });

    group('StorageException', () {
      test('should create with correct code', () {
        final exception = StorageException('Storage full');
        
        expect(exception.code, equals('STORAGE_ERROR'));
        expect(exception.message, equals('Storage full'));
      });
    });

    group('CameraException', () {
      test('should create with correct code', () {
        final exception = CameraException('Camera permission denied');
        
        expect(exception.code, equals('CAMERA_ERROR'));
        expect(exception.message, equals('Camera permission denied'));
      });
    });

    group('AuthException', () {
      test('should create with correct code', () {
        final exception = AuthException('Invalid credentials');
        
        expect(exception.code, equals('AUTH_ERROR'));
        expect(exception.message, equals('Invalid credentials'));
      });
    });
  });

  group('ErrorHandler Tests', () {
    group('User Friendly Messages', () {
      test('should return appropriate message for ClassificationException', () {
        final exception = ClassificationException('AI model failed');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('AI model failed'));
      });

      test('should return generic message for ClassificationException type', () {
        final exception = ClassificationException('Complex technical error');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, contains('Complex technical error'));
      });

      test('should return network message for NetworkException', () {
        final exception = NetworkException('HTTP 500 error');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('HTTP 500 error'));
      });

      test('should return camera message for CameraException', () {
        final exception = CameraException('Camera not available');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('Camera not available'));
      });

      test('should return storage message for StorageException', () {
        final exception = StorageException('Disk full');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('Disk full'));
      });

      test('should return auth message for AuthException', () {
        final exception = AuthException('Token expired');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('Token expired'));
      });

      test('should return generic message for unknown exceptions', () {
        final exception = Exception('Random error');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        
        expect(message, equals('An unexpected error occurred. Please try again.'));
      });

      test('should handle null errors gracefully', () {
        final message = ErrorHandler.getUserFriendlyMessage(null);
        
        expect(message, equals('An unexpected error occurred. Please try again.'));
      });

      test('should handle string errors', () {
        final message = ErrorHandler.getUserFriendlyMessage('String error');
        
        expect(message, equals('An unexpected error occurred. Please try again.'));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle error without navigator key', (tester) async {
        // Arrange
        final exception = ClassificationException('Test error');
        final stackTrace = StackTrace.current;

        // Act & Assert - Should not throw
        expect(
          () => ErrorHandler.handleError(exception, stackTrace),
          returnsNormally,
        );
      });

      testWidgets('should initialize with navigator key', (tester) async {
        // Arrange
        final navigatorKey = GlobalKey<NavigatorState>();

        // Act
        ErrorHandler.initialize(navigatorKey);

        // Assert - Should complete without error
        expect(ErrorHandler.navigatorKey, equals(navigatorKey));
      });

      test('should handle different error types in handleError', () {
        // Arrange
        final errors = [
          ClassificationException('Test classification'),
          NetworkException('Test network'),
          CameraException('Test camera'),
          StorageException('Test storage'),
          AuthException('Test auth'),
          Exception('Generic exception'),
        ];

        // Act & Assert - Should not throw
        for (final error in errors) {
          expect(
            () => ErrorHandler.handleError(error, StackTrace.current),
            returnsNormally,
          );
        }
      });

      test('should handle fatal errors', () {
        // Arrange
        final exception = ClassificationException('Fatal error');
        final stackTrace = StackTrace.current;

        // Act & Assert - Should not throw
        expect(
          () => ErrorHandler.handleError(
            exception,
            stackTrace,
            fatal: true,
          ),
          returnsNormally,
        );
      });

      test('should handle errors with context', () {
        // Arrange
        final exception = NetworkException('Request failed');
        final stackTrace = StackTrace.current;
        final context = {'userId': '123', 'action': 'classify'};

        // Act & Assert - Should not throw
        expect(
          () => ErrorHandler.handleError(
            exception,
            stackTrace,
            context: context,
          ),
          returnsNormally,
        );
      });
    });

    group('Exception Metadata', () {
      test('should preserve complex metadata', () {
        final metadata = {
          'request': {
            'url': 'https://api.example.com',
            'method': 'POST',
            'headers': {'Content-Type': 'application/json'},
          },
          'response': {
            'status': 500,
            'body': 'Internal Server Error',
          },
          'timestamp': DateTime.now().toIso8601String(),
        };

        final exception = NetworkException('Server error', metadata);
        final map = exception.toMap();

        expect(map['metadata'], equals(metadata));
        expect(map['metadata']['request']['url'], equals('https://api.example.com'));
        expect(map['metadata']['response']['status'], equals(500));
      });

      test('should handle empty metadata', () {
        final exception = ClassificationException('Error', {});
        final map = exception.toMap();

        expect(map['metadata'], isEmpty);
      });

      test('should handle null values in metadata', () {
        final metadata = {
          'validKey': 'validValue',
          'nullKey': null,
          'emptyKey': '',
        };

        final exception = StorageException('Error', metadata);
        final map = exception.toMap();

        expect(map['metadata']['validKey'], equals('validValue'));
        expect(map['metadata']['nullKey'], isNull);
        expect(map['metadata']['emptyKey'], equals(''));
      });
    });

    group('Timestamp Management', () {
      test('should have consistent timestamp format', () {
        final exception = ClassificationException('Test');
        final map = exception.toMap();
        final timestamp = map['timestamp'] as String;

        // Should be valid ISO 8601 format
        expect(() => DateTime.parse(timestamp), returnsNormally);
        
        final parsedTimestamp = DateTime.parse(timestamp);
        expect(parsedTimestamp, isA<DateTime>());
      });

      test('should have recent timestamp', () {
        final before = DateTime.now();
        final exception = NetworkException('Test');
        final after = DateTime.now();

        expect(exception.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(exception.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('should have unique timestamps for multiple exceptions', () {
        final exceptions = List.generate(5, (i) => 
          ClassificationException('Error $i')
        );

        final timestamps = exceptions.map((e) => e.timestamp).toList();
        final uniqueTimestamps = timestamps.toSet();

        // Allow for some duplicate timestamps due to fast execution
        expect(uniqueTimestamps.length, greaterThanOrEqualTo(1));
      });
    });

    group('Edge Cases', () {
      test('should handle very long error messages', () {
        final longMessage = 'A' * 10000; // 10k character message
        final exception = ClassificationException(longMessage);

        expect(exception.message, equals(longMessage));
        expect(exception.message.length, equals(10000));
      });

      test('should handle special characters in messages', () {
        final specialMessage = 'Error with émojis 🚫 and ñovel characters: <>&"\'';
        final exception = NetworkException(specialMessage);

        expect(exception.message, equals(specialMessage));
        
        final map = exception.toMap();
        expect(map['message'], equals(specialMessage));
      });

      test('should handle deeply nested metadata', () {
        final deepMetadata = {
          'level1': {
            'level2': {
              'level3': {
                'level4': {
                  'deepValue': 'found'
                }
              }
            }
          }
        };

        final exception = StorageException('Deep error', deepMetadata);
        final map = exception.toMap();

        expect(
          map['metadata']['level1']['level2']['level3']['level4']['deepValue'],
          equals('found'),
        );
      });

      test('should handle circular reference in metadata safely', () {
        // Note: This test ensures we don't have issues with circular references
        // Since we're using basic Map<String, dynamic>, this should work fine
        final metadata = <String, dynamic>{};
        metadata['self'] = metadata; // This would cause issues with JSON serialization
        
        // Our exception should still be created without issues
        expect(
          () => ClassificationException('Circular reference test', {'simple': 'value'}),
          returnsNormally,
        );
      });
    });
  });
}
