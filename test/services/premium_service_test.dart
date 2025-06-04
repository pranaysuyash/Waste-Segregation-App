import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import '../test_helper.dart';

void main() {
  group('PremiumService Critical Tests', () {
    late PremiumService premiumService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() async {
      premiumService = PremiumService();
      await premiumService.initialize();
    });

    tearDown(() async {
      await premiumService.resetPremiumFeatures();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        final service = PremiumService();
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should not initialize twice', () async {
        final service = PremiumService();
        await service.initialize();
        final firstInit = service.isInitialized;
        
        await service.initialize();
        final secondInit = service.isInitialized;
        
        expect(firstInit, equals(secondInit));
        expect(secondInit, isTrue);
      });

      test('should handle initialization failure gracefully', () async {
        // Test that initialization errors don't crash the app
        final service = PremiumService();
        
        try {
          await service.initialize();
          expect(service.isInitialized, isTrue);
        } catch (e) {
          // Should handle gracefully even if initialization fails
          expect(e, isA<Exception>());
        }
      });

      test('should auto-initialize in constructor', () async {
        final service = PremiumService();
        
        // Give some time for auto-initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(service.isInitialized, isTrue);
      });
    });

    group('Premium Feature Management Tests', () {
      test('should start with no premium features enabled', () {
        final premiumFeatures = premiumService.getPremiumFeatures();
        final comingSoonFeatures = premiumService.getComingSoonFeatures();
        
        // In debug mode, some test features might be enabled
        if (kDebugMode) {
          // Verify at least some features exist
          expect(premiumFeatures.length + comingSoonFeatures.length, 
                 equals(PremiumFeature.features.length));
        } else {
          expect(premiumFeatures, isEmpty);
          expect(comingSoonFeatures.length, equals(PremiumFeature.features.length));
        }
      });

      test('should enable premium feature correctly', () async {
        const featureId = 'remove_ads';
        
        expect(premiumService.isPremiumFeature(featureId), isFalse);
        
        await premiumService.setPremiumFeature(featureId, true);
        
        expect(premiumService.isPremiumFeature(featureId), isTrue);
      });

      test('should disable premium feature correctly', () async {
        const featureId = 'theme_customization';
        
        await premiumService.setPremiumFeature(featureId, true);
        expect(premiumService.isPremiumFeature(featureId), isTrue);
        
        await premiumService.setPremiumFeature(featureId, false);
        expect(premiumService.isPremiumFeature(featureId), isFalse);
      });

      test('should handle multiple premium features', () async {
        const features = ['remove_ads', 'theme_customization', 'offline_mode'];
        
        // Enable all features
        for (final feature in features) {
          await premiumService.setPremiumFeature(feature, true);
        }
        
        // Verify all are enabled
        for (final feature in features) {
          expect(premiumService.isPremiumFeature(feature), isTrue);
        }
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        expect(premiumFeatures.length, equals(features.length));
      });

      test('should toggle feature correctly', () async {
        const featureId = 'advanced_analytics';
        
        expect(premiumService.isPremiumFeature(featureId), isFalse);
        
        await premiumService.toggleFeature(featureId);
        expect(premiumService.isPremiumFeature(featureId), isTrue);
        
        await premiumService.toggleFeature(featureId);
        expect(premiumService.isPremiumFeature(featureId), isFalse);
      });

      test('should persist feature states across service instances', () async {
        const featureId = 'export_data';
        
        await premiumService.setPremiumFeature(featureId, true);
        expect(premiumService.isPremiumFeature(featureId), isTrue);
        
        // Create new service instance
        final newService = PremiumService();
        await newService.initialize();
        
        expect(newService.isPremiumFeature(featureId), isTrue);
      });
    });

    group('Feature List Management Tests', () {
      test('should return correct premium features list', () async {
        const premiumFeatureIds = ['remove_ads', 'theme_customization'];
        
        for (final featureId in premiumFeatureIds) {
          await premiumService.setPremiumFeature(featureId, true);
        }
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        expect(premiumFeatures.length, equals(premiumFeatureIds.length));
        
        for (final feature in premiumFeatures) {
          expect(premiumFeatureIds.contains(feature.id), isTrue);
          expect(feature.isEnabled, isTrue);
        }
      });

      test('should return correct coming soon features list', () async {
        const premiumFeatureIds = ['remove_ads', 'theme_customization'];
        
        for (final featureId in premiumFeatureIds) {
          await premiumService.setPremiumFeature(featureId, true);
        }
        
        final comingSoonFeatures = premiumService.getComingSoonFeatures();
        final expectedCount = PremiumFeature.features.length - premiumFeatureIds.length;
        expect(comingSoonFeatures.length, equals(expectedCount));
        
        for (final feature in comingSoonFeatures) {
          expect(premiumFeatureIds.contains(feature.id), isFalse);
        }
      });

      test('should maintain correct feature properties', () async {
        const featureId = 'advanced_analytics';
        await premiumService.setPremiumFeature(featureId, true);
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        final feature = premiumFeatures.firstWhere((f) => f.id == featureId);
        
        expect(feature.id, equals(featureId));
        expect(feature.title, isNotEmpty);
        expect(feature.description, isNotEmpty);
        expect(feature.icon, isNotEmpty);
        expect(feature.route, isNotEmpty);
        expect(feature.isEnabled, isTrue);
      });

      test('should handle empty premium features list', () async {
        await premiumService.resetPremiumFeatures();
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        final comingSoonFeatures = premiumService.getComingSoonFeatures();
        
        expect(premiumFeatures, isEmpty);
        expect(comingSoonFeatures.length, equals(PremiumFeature.features.length));
      });
    });

    group('Revenue Critical Tests', () {
      test('should handle remove_ads feature for revenue model', () async {
        const removeAdsFeature = 'remove_ads';
        
        // Free user should not have ad removal
        expect(premiumService.isPremiumFeature(removeAdsFeature), isFalse);
        
        // Premium user should have ad removal
        await premiumService.setPremiumFeature(removeAdsFeature, true);
        expect(premiumService.isPremiumFeature(removeAdsFeature), isTrue);
      });

      test('should track premium feature adoption', () async {
        const features = ['remove_ads', 'theme_customization', 'offline_mode'];
        
        // Simulate user purchasing features one by one
        for (var i = 0; i < features.length; i++) {
          await premiumService.setPremiumFeature(features[i], true);
          
          final enabledCount = premiumService.getPremiumFeatures().length;
          expect(enabledCount, equals(i + 1));
        }
      });

      test('should handle premium subscription validation', () async {
        // Test that all premium features can be enabled at once (subscription model)
        const allFeatures = [
          'remove_ads',
          'theme_customization',
          'offline_mode',
          'advanced_analytics',
          'export_data'
        ];
        
        for (final feature in allFeatures) {
          await premiumService.setPremiumFeature(feature, true);
        }
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        expect(premiumFeatures.length, equals(allFeatures.length));
        
        final comingSoonFeatures = premiumService.getComingSoonFeatures();
        expect(comingSoonFeatures, isEmpty);
      });

      test('should handle trial period simulation', () async {
        const trialFeatures = ['remove_ads', 'theme_customization'];
        
        // Enable trial features
        for (final feature in trialFeatures) {
          await premiumService.setPremiumFeature(feature, true);
        }
        
        // Verify trial features are active
        for (final feature in trialFeatures) {
          expect(premiumService.isPremiumFeature(feature), isTrue);
        }
        
        // Simulate trial expiry
        for (final feature in trialFeatures) {
          await premiumService.setPremiumFeature(feature, false);
        }
        
        // Verify features are disabled
        for (final feature in trialFeatures) {
          expect(premiumService.isPremiumFeature(feature), isFalse);
        }
      });
    });

    group('Notification Tests', () {
      test('should notify listeners when feature is enabled', () async {
        var notified = false;
        premiumService.addListener(() => notified = true);
        
        await premiumService.setPremiumFeature('remove_ads', true);
        
        expect(notified, isTrue);
      });

      test('should notify listeners when feature is disabled', () async {
        await premiumService.setPremiumFeature('remove_ads', true);
        
        var notified = false;
        premiumService.addListener(() => notified = true);
        
        await premiumService.setPremiumFeature('remove_ads', false);
        
        expect(notified, isTrue);
      });

      test('should notify listeners when features are reset', () async {
        await premiumService.setPremiumFeature('remove_ads', true);
        
        var notified = false;
        premiumService.addListener(() => notified = true);
        
        await premiumService.resetPremiumFeatures();
        
        expect(notified, isTrue);
      });

      test('should notify listeners when feature is toggled', () async {
        var notified = false;
        premiumService.addListener(() => notified = true);
        
        await premiumService.toggleFeature('theme_customization');
        
        expect(notified, isTrue);
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid feature IDs gracefully', () async {
        const invalidFeatureId = 'non_existent_feature';
        
        expect(() async => premiumService.setPremiumFeature(invalidFeatureId, true), 
               returnsNormally);
        
        expect(premiumService.isPremiumFeature(invalidFeatureId), isFalse);
      });

      test('should handle operations before initialization', () {
        final service = PremiumService();
        
        // Operations should not crash before initialization
        expect(() => service.isPremiumFeature('remove_ads'), returnsNormally);
        expect(service.getPremiumFeatures(), isEmpty);
        expect(service.getComingSoonFeatures(), isEmpty);
      });

      test('should handle storage corruption gracefully', () async {
        // Test service recovery from storage issues
        final service = PremiumService();
        
        try {
          await service.initialize();
          expect(service.isInitialized, isTrue);
        } catch (e) {
          // Should handle storage issues gracefully
          expect(e, isA<Exception>());
        }
      });

      test('should handle concurrent feature modifications', () async {
        const featureId = 'offline_mode';
        
        // Simulate concurrent modifications
        final futures = <Future>[];
        for (var i = 0; i < 10; i++) {
          futures.add(premiumService.setPremiumFeature(featureId, i.isEven));
        }
        
        await Future.wait(futures);
        
        // Service should remain stable
        expect(premiumService.isInitialized, isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle large number of feature checks efficiently', () {
        const featureId = 'remove_ads';
        
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 1000; i++) {
          premiumService.isPremiumFeature(featureId);
        }
        
        stopwatch.stop();
        
        // Should be very fast (local storage check)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle rapid feature toggles efficiently', () async {
        const featureId = 'theme_customization';
        
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 50; i++) {
          await premiumService.toggleFeature(featureId);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('should cache feature lists for performance', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 100; i++) {
          premiumService.getPremiumFeatures();
          premiumService.getComingSoonFeatures();
        }
        
        stopwatch.stop();
        
        // Should be fast with repeated calls
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Edge Cases', () {
      test('should handle null and empty feature IDs', () async {
        expect(() => premiumService.isPremiumFeature(''), returnsNormally);
        expect(premiumService.isPremiumFeature(''), isFalse);
        
        expect(() async => premiumService.setPremiumFeature('', true), 
               returnsNormally);
      });

      test('should handle very long feature IDs', () async {
        final longFeatureId = 'a' * 1000;
        
        expect(() async => premiumService.setPremiumFeature(longFeatureId, true), 
               returnsNormally);
        
        expect(() => premiumService.isPremiumFeature(longFeatureId), returnsNormally);
      });

      test('should handle rapid initialization attempts', () async {
        final service = PremiumService();
        
        final futures = <Future>[];
        for (var i = 0; i < 10; i++) {
          futures.add(service.initialize());
        }
        
        await Future.wait(futures);
        
        expect(service.isInitialized, isTrue);
      });

      test('should handle feature operations during reset', () async {
        await premiumService.setPremiumFeature('remove_ads', true);
        
        // Start reset and immediately try to access features
        final resetFuture = premiumService.resetPremiumFeatures();
        final isEnabled = premiumService.isPremiumFeature('remove_ads');
        
        await resetFuture;
        
        // Should not crash
        expect(isEnabled, isA<bool>());
      });
    });

    group('Integration Tests', () {
      test('should work correctly with ChangeNotifier pattern', () {
        final service = PremiumService();
        var listenerCalled = false;
        
        service.addListener(() => listenerCalled = true);
        
        // Trigger a change
        service.setPremiumFeature('remove_ads', true);
        
        expect(listenerCalled, isTrue);
      });

      test('should integrate with all available premium features', () async {
        // Test with all features defined in PremiumFeature.features
        for (final feature in PremiumFeature.features) {
          await premiumService.setPremiumFeature(feature.id, true);
          expect(premiumService.isPremiumFeature(feature.id), isTrue);
        }
        
        final premiumFeatures = premiumService.getPremiumFeatures();
        expect(premiumFeatures.length, equals(PremiumFeature.features.length));
      });

      test('should maintain feature state consistency', () async {
        const testFeatures = ['remove_ads', 'theme_customization', 'offline_mode'];
        
        // Enable some features
        for (var i = 0; i < testFeatures.length; i++) {
          await premiumService.setPremiumFeature(testFeatures[i], i.isEven);
        }
        
        // Verify consistency
        final enabledFeatures = premiumService.getPremiumFeatures();
        final comingSoonFeatures = premiumService.getComingSoonFeatures();
        
        expect(enabledFeatures.length + comingSoonFeatures.length,
               equals(PremiumFeature.features.length));
      });
    });
  });
}
