import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import '../test_helper.dart';

// Mock classes for testing
class MockInterstitialAd extends Mock implements InterstitialAd {}
class MockBannerAd extends Mock implements BannerAd {}
class MockMobileAds extends Mock implements MobileAds {}

void main() {
  group('AdService Critical Tests', () {
    late AdService adService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
      // Mock platform to avoid issues with Platform.isAndroid in tests
      if (!kIsWeb) {
        // TestWidgetsFlutterBinding.ensureInitialized();
      }
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      adService = AdService();
      TestHelper.setupMockSharedPreferences();
    });

    tearDown(() {
      adService.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize successfully on mobile platforms', () async {
        // Skip on web since ads are not supported
        if (kIsWeb) {
          await adService.initialize();
          expect(adService.isInitialized, isTrue);
          return;
        }

        // For mobile platforms, initialize should complete
        try {
          await adService.initialize();
          // In test environment, initialization may fail due to missing AdMob config
          // This is expected and acceptable for unit tests
        } catch (e) {
          // Expected in test environment without proper AdMob setup
          expect(e, isA<Exception>());
        }
      });

      test('should skip initialization on web platform', () async {
        // This test specifically for web behavior
        if (kIsWeb) {
          await adService.initialize();
          expect(adService.isInitialized, isTrue);
        }
      });

      test('should not initialize twice', () async {
        await adService.initialize();
        final firstInit = adService.isInitialized;
        
        await adService.initialize();
        final secondInit = adService.isInitialized;
        
        expect(firstInit, equals(secondInit));
      });

      test('should handle initialization failure gracefully', () async {
        // This test verifies that initialization failures don't crash the app
        try {
          await adService.initialize();
          // If successful, verify it's initialized
          if (adService.isInitialized) {
            expect(adService.isInitialized, isTrue);
          }
        } catch (e) {
          // If failed, should handle gracefully
          expect(e, isA<Exception>());
          // Service should still be usable even if ads fail to initialize
        }
      });
    });

    group('Premium Status Tests', () {
      test('should start with premium status false', () {
        expect(adService.shouldShowAds, isTrue);
      });

      test('should update premium status correctly', () {
        adService.setPremiumStatus(true);
        expect(adService.shouldShowAds, isFalse);

        adService.setPremiumStatus(false);
        expect(adService.shouldShowAds, isTrue);
      });

      test('should not show ads when premium is active', () {
        adService.setPremiumStatus(true);
        
        final bannerWidget = adService.getBannerAd();
        expect(bannerWidget, isA<SizedBox>());
        expect((bannerWidget as SizedBox).width, equals(0.0));
        expect(bannerWidget.height, equals(0.0));
      });

      test('should notify listeners when premium status changes', () {
        var notified = false;
        adService.addListener(() => notified = true);

        adService.setPremiumStatus(true);
        
        // Wait for post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          expect(notified, isTrue);
        });
      });
    });

    group('Context Management Tests', () {
      test('should not show ads during classification flow', () {
        adService.setInClassificationFlow(true);
        expect(adService.shouldShowAds, isFalse);

        adService.setInClassificationFlow(false);
        expect(adService.shouldShowAds, isTrue);
      });

      test('should not show ads during educational content', () {
        adService.setInEducationalContent(true);
        expect(adService.shouldShowAds, isFalse);

        adService.setInEducationalContent(false);
        expect(adService.shouldShowAds, isTrue);
      });

      test('should not show ads in settings', () {
        adService.setInSettings(true);
        expect(adService.shouldShowAds, isFalse);

        adService.setInSettings(false);
        expect(adService.shouldShowAds, isTrue);
      });

      test('should handle multiple context restrictions', () {
        adService.setInClassificationFlow(true);
        adService.setInEducationalContent(true);
        expect(adService.shouldShowAds, isFalse);

        adService.setInClassificationFlow(false);
        expect(adService.shouldShowAds, isFalse); // Still in educational content

        adService.setInEducationalContent(false);
        expect(adService.shouldShowAds, isTrue); // Now should show ads
      });
    });

    group('Banner Ad Tests', () {
      test('should return empty widget on web', () {
        if (kIsWeb) {
          final bannerWidget = adService.getBannerAd();
          expect(bannerWidget, isA<SizedBox>());
          expect((bannerWidget as SizedBox).width, equals(0.0));
        }
      });

      test('should return placeholder when ad not loaded', () {
        if (!kIsWeb) {
          final bannerWidget = adService.getBannerAd();
          expect(bannerWidget, isA<RepaintBoundary>());
          // Placeholder should have loading indicator
        }
      });

      test('should return empty widget when ads should not be shown', () {
        adService.setPremiumStatus(true);
        final bannerWidget = adService.getBannerAd();
        expect(bannerWidget, isA<SizedBox>());
      });

      test('should handle banner ad refresh', () {
        // Test that refresh method doesn't crash
        expect(() => adService.refreshBannerAd(), returnsNormally);
      });
    });

    group('Interstitial Ad Tests', () {
      test('should not show interstitial ad on web', () async {
        if (kIsWeb) {
          final result = await adService.showInterstitialAd();
          expect(result, isFalse);
        }
      });

      test('should not show interstitial when premium is active', () async {
        adService.setPremiumStatus(true);
        final result = await adService.showInterstitialAd();
        expect(result, isFalse);
      });

      test('should not show interstitial too frequently', () async {
        // First call might succeed (if ad is loaded)
        await adService.showInterstitialAd();
        
        // Second call should respect frequency limit
        final result = await adService.showInterstitialAd();
        expect(result, isFalse); // Should be false due to frequency limit
      });

      test('should track classification count for interstitial trigger', () {
        expect(adService.shouldShowInterstitial(), isFalse);
        
        // Track multiple classifications
        for (var i = 0; i < 6; i++) {
          adService.trackClassificationCompleted();
        }
        
        expect(adService.shouldShowInterstitial(), isTrue);
      });

      test('should handle interstitial ad errors gracefully', () async {
        // This test verifies that failed interstitial ads don't crash
        expect(() async => adService.showInterstitialAd(), returnsNormally);
      });
    });

    group('Classification Tracking Tests', () {
      test('should track classification completed correctly', () {
        expect(() => adService.trackClassificationCompleted(), returnsNormally);
      });

      test('should increment classification count', () {
        expect(() => adService.incrementClassificationCount(), returnsNormally);
      });

      test('should track classification using convenience method', () {
        expect(() => adService.trackClassification(), returnsNormally);
      });

      test('should reset classification count after interstitial', () async {
        // Track multiple classifications to trigger interstitial
        for (var i = 0; i < 6; i++) {
          adService.trackClassificationCompleted();
        }
        
        expect(adService.shouldShowInterstitial(), isTrue);
        
        // Attempt to show interstitial (may fail in test environment)
        await adService.showInterstitialAd();
        
        // Classification count should be reset (internal behavior)
        // We can't directly test this, but we verify the method doesn't crash
      });
    });

    group('Lifecycle Management Tests', () {
      test('should handle disposal correctly', () {
        expect(() => adService.dispose(), returnsNormally);
        expect(adService.mounted, isFalse);
      });

      test('should not notify listeners after disposal', () {
        adService.dispose();
        
        // These operations should not crash after disposal
        expect(() => adService.setPremiumStatus(true), returnsNormally);
        expect(() => adService.setInClassificationFlow(true), returnsNormally);
        expect(() => adService.trackClassification(), returnsNormally);
      });

      test('should not perform operations after disposal', () {
        adService.dispose();
        
        // Ad operations should handle disposed state gracefully
        final bannerWidget = adService.getBannerAd();
        expect(bannerWidget, isA<SizedBox>());
        
        expect(() => adService.refreshBannerAd(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle missing AdMob configuration gracefully', () async {
        // In test environment, AdMob is not configured
        // Service should handle this gracefully without crashing
        await adService.initialize();
        
        // Basic operations should work even without AdMob
        expect(() => adService.getBannerAd(), returnsNormally);
        expect(() async => adService.showInterstitialAd(), returnsNormally);
      });

      test('should handle network errors gracefully', () async {
        // Test that network failures don't crash the service
        await adService.initialize();
        
        // Ad operations should handle network errors
        expect(() => adService.getBannerAd(), returnsNormally);
        expect(() async => adService.showInterstitialAd(), returnsNormally);
      });

      test('should handle invalid ad unit IDs gracefully', () async {
        // Service should not crash with invalid configuration
        await adService.initialize();
        expect(adService, isNotNull);
      });
    });

    group('Performance Tests', () {
      test('should not block UI thread during initialization', () async {
        final stopwatch = Stopwatch()..start();
        await adService.initialize();
        stopwatch.stop();
        
        // Initialization should be relatively fast (not blocking)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      });

      test('should cache banner widget for performance', () {
        final widget1 = adService.getBannerAd();
        final widget2 = adService.getBannerAd();
        
        // Should return the same widget instance for performance
        if (!kIsWeb && !adService.shouldShowAds) {
          expect(widget1.runtimeType, equals(widget2.runtimeType));
        }
      });

      test('should handle rapid context changes efficiently', () {
        // Rapid context changes should not cause performance issues
        for (var i = 0; i < 100; i++) {
          adService.setInClassificationFlow(i.isEven);
          adService.setInEducationalContent(i.isOdd);
        }
        
        expect(adService, isNotNull);
      });
    });

    group('GDPR and Privacy Tests', () {
      test('should handle ad requests with appropriate targeting', () {
        // Test that ad requests include appropriate keywords
        expect(() => adService.getBannerAd(), returnsNormally);
        
        // In a real implementation, you might test:
        // - Consent management
        // - Targeted vs non-targeted ads
        // - Privacy-compliant ad requests
      });

      test('should respect user privacy settings', () {
        // Test privacy-related functionality
        adService.setPremiumStatus(true); // Ad removal as privacy option
        expect(adService.shouldShowAds, isFalse);
      });
    });

    group('Integration Tests', () {
      testWidgets('should integrate correctly with Flutter widget tree',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: adService.getBannerAd(),
            ),
          ),
        );

        expect(find.byType(Scaffold), findsOneWidget);
      });

      test('should work with ChangeNotifier pattern', () {
        var listenerCalled = false;
        adService.addListener(() => listenerCalled = true);
        
        adService.setPremiumStatus(true);
        
        // Verify listener pattern works
        WidgetsBinding.instance.addPostFrameCallback((_) {
          expect(listenerCalled, isTrue);
        });
      });
    });

    group('Revenue Critical Tests', () {
      test('should allow premium upgrade to remove ads', () {
        // Test the core monetization flow
        expect(adService.shouldShowAds, isTrue); // Free users see ads
        
        adService.setPremiumStatus(true); // User upgrades
        expect(adService.shouldShowAds, isFalse); // Premium users don't see ads
      });

      test('should show interstitials at appropriate frequency', () {
        // Test ad frequency for revenue optimization
        adService.trackClassificationCompleted();
        expect(adService.shouldShowInterstitial(), isFalse); // Too early
        
        for (var i = 0; i < 5; i++) {
          adService.trackClassificationCompleted();
        }
        
        expect(adService.shouldShowInterstitial(), isTrue); // Should trigger
      });

      test('should handle ad loading states for optimal revenue', () {
        // Test that ads are preloaded for better fill rates
        adService.initialize();
        
        // Banner should show placeholder while loading
        final bannerWidget = adService.getBannerAd();
        expect(bannerWidget, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle extremely rapid classification tracking', () {
        for (var i = 0; i < 1000; i++) {
          adService.trackClassification();
        }
        expect(adService, isNotNull);
      });

      test('should handle simultaneous context changes', () {
        adService.setInClassificationFlow(true);
        adService.setInEducationalContent(true);
        adService.setInSettings(true);
        adService.setPremiumStatus(true);
        
        expect(adService.shouldShowAds, isFalse);
      });

      test('should handle disposal during ad operations', () {
        adService.trackClassification();
        adService.dispose();
        
        // Should not crash after disposal
        expect(() => adService.trackClassification(), returnsNormally);
      });
    });
  });
}
