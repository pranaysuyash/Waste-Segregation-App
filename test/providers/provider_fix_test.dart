import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/educational_content_analytics_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/purchase_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/user_consent_service.dart';

class _MockAiService extends Mock implements AiService {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockEducationalContentAnalyticsService extends Mock
    implements EducationalContentAnalyticsService {}

class _MockEducationalContentService extends Mock
    implements EducationalContentService {}

class _MockGamificationService extends Mock implements GamificationService {}

class _MockPremiumService extends Mock implements PremiumService {}

class _MockPurchaseService extends Mock implements PurchaseService {}

class _MockAdService extends Mock implements AdService {}

class _MockGoogleDriveService extends Mock implements GoogleDriveService {}

class _MockNavigationSettingsService extends Mock
    implements NavigationSettingsService {}

class _MockHapticSettingsService extends Mock
    implements HapticSettingsService {}

class _MockCommunityService extends Mock implements CommunityService {}

class _MockUserConsentService extends Mock implements UserConsentService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      expect(
          storageServiceProvider.runtimeType.toString(), contains('Provider'));
    });

    test('runtime service overrides preserve initialized service identity', () {
      final storage = StorageService();
      final cloudStorage = CloudStorageService(storage);
      final ai = _MockAiService();
      final analytics = _MockAnalyticsService();
      final educationalAnalytics = _MockEducationalContentAnalyticsService();
      final educational = _MockEducationalContentService();
      final gamification = _MockGamificationService();
      final premium = _MockPremiumService();
      final purchase = _MockPurchaseService();
      final ad = _MockAdService();
      final drive = _MockGoogleDriveService();
      final navigation = _MockNavigationSettingsService();
      final haptic = _MockHapticSettingsService();
      final community = _MockCommunityService();
      final consent = _MockUserConsentService();

      final runtimeContainer = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          cloudStorageServiceProvider.overrideWithValue(cloudStorage),
          aiServiceProvider.overrideWithValue(ai),
          analyticsServiceProvider.overrideWithValue(analytics),
          educationalContentAnalyticsServiceProvider
              .overrideWithValue(educationalAnalytics),
          educationalContentServiceProvider.overrideWithValue(educational),
          gamificationServiceProvider.overrideWithValue(gamification),
          premiumServiceProvider.overrideWithValue(premium),
          purchaseServiceProvider.overrideWithValue(purchase),
          adServiceProvider.overrideWithValue(ad),
          googleDriveServiceProvider.overrideWithValue(drive),
          navigationSettingsServiceProvider.overrideWithValue(navigation),
          hapticSettingsServiceProvider.overrideWithValue(haptic),
          communityServiceProvider.overrideWithValue(community),
          userConsentServiceProvider.overrideWithValue(consent),
        ],
      );
      addTearDown(runtimeContainer.dispose);

      expect(identical(runtimeContainer.read(storageServiceProvider), storage),
          isTrue);
      expect(
          identical(
              runtimeContainer.read(cloudStorageServiceProvider), cloudStorage),
          isTrue);
      expect(identical(runtimeContainer.read(aiServiceProvider), ai), isTrue);
      expect(
          identical(runtimeContainer.read(analyticsServiceProvider), analytics),
          isTrue);
      expect(
          identical(
              runtimeContainer.read(educationalContentAnalyticsServiceProvider),
              educationalAnalytics),
          isTrue);
      expect(
          identical(runtimeContainer.read(educationalContentServiceProvider),
              educational),
          isTrue);
      expect(
          identical(
              runtimeContainer.read(gamificationServiceProvider), gamification),
          isTrue);
      expect(identical(runtimeContainer.read(premiumServiceProvider), premium),
          isTrue);
      expect(
          identical(runtimeContainer.read(purchaseServiceProvider), purchase),
          isTrue);
      expect(identical(runtimeContainer.read(adServiceProvider), ad), isTrue);
      expect(
          identical(runtimeContainer.read(googleDriveServiceProvider), drive),
          isTrue);
      expect(
          identical(runtimeContainer.read(navigationSettingsServiceProvider),
              navigation),
          isTrue);
      expect(
          identical(
              runtimeContainer.read(hapticSettingsServiceProvider), haptic),
          isTrue);
      expect(
          identical(runtimeContainer.read(communityServiceProvider), community),
          isTrue);
      expect(
          identical(runtimeContainer.read(userConsentServiceProvider), consent),
          isTrue);
    });

    test('central providers file should be accessible', () {
      // Verify that we can access providers from the central file
      // without any compilation or import errors
      expect(() => storageServiceProvider, returnsNormally);
    });
  });
}
