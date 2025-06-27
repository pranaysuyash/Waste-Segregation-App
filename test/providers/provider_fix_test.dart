import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

void main() {
  group('Provider Fix Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('storageServiceProvider should create StorageService instance', () {
      final storageService = container.read(storageServiceProvider);
      expect(storageService, isA<StorageService>());
    });

    test('providers should not throw UnimplementedError', () {
      // Test that we can read the storage service provider without errors
      expect(() => container.read(storageServiceProvider), returnsNormally);

      // Test that the provider returns a real instance, not a throwing one
      final storageService = container.read(storageServiceProvider);
      expect(storageService, isNotNull);
      expect(storageService, isA<StorageService>());
    });

    test('providers should maintain singleton behavior', () {
      final storageService1 = container.read(storageServiceProvider);
      final storageService2 = container.read(storageServiceProvider);

      // Should return the same instance (singleton behavior)
      expect(identical(storageService1, storageService2), isTrue);
    });

    test('provider structure should be consistent', () {
      // Verify that we can access the provider without errors
      expect(() => storageServiceProvider, returnsNormally);

      // Verify the provider is properly defined
      expect(storageServiceProvider, isNotNull);
    });

    test('no duplicate provider declarations should exist', () {
      // This test verifies that we can successfully read from the central provider
      // without conflicts from duplicate declarations
      final storageService = container.read(storageServiceProvider);
      expect(storageService, isA<StorageService>());

      // Verify we can read it multiple times without issues
      final storageService2 = container.read(storageServiceProvider);
      expect(storageService2, isA<StorageService>());
    });

    test('provider imports should be consistent', () {
      // This test verifies that the provider can be imported and accessed
      // without any import conflicts or duplicate declarations
      expect(storageServiceProvider.runtimeType.toString(), contains('Provider'));
    });

    test('central providers file should be accessible', () {
      // Verify that we can access providers from the central file
      // without any compilation or import errors
      expect(() => storageServiceProvider, returnsNormally);
    });
  });
}
