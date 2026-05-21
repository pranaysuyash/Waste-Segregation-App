import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waste_segregation_app/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService consent and premium gating', () {
    late AdService adService;

    setUp(() {
      adService = AdService();
    });

    tearDown(() {
      adService.dispose();
    });

    test('does not show ads by default before consent eligibility', () {
      expect(adService.shouldShowAds, isFalse);
    });

    test('shows ads only when consent eligibility is true and not premium', () {
      if (kIsWeb) {
        expect(adService.shouldShowAds, isFalse);
        return;
      }

      adService.debugSetCanRequestAds(true);
      expect(adService.shouldShowAds, isTrue);

      adService.setPremiumStatus(true);
      expect(adService.shouldShowAds, isFalse);

      adService.setPremiumStatus(false);
      expect(adService.shouldShowAds, isTrue);
    });

    test('suppresses ads in restricted contexts even when consent is granted', () {
      if (kIsWeb) {
        expect(adService.shouldShowAds, isFalse);
        return;
      }

      adService.debugSetCanRequestAds(true);
      expect(adService.shouldShowAds, isTrue);

      adService.setInClassificationFlow(true);
      expect(adService.shouldShowAds, isFalse);
      adService.setInClassificationFlow(false);
      expect(adService.shouldShowAds, isTrue);

      adService.setInEducationalContent(true);
      expect(adService.shouldShowAds, isFalse);
      adService.setInEducationalContent(false);
      expect(adService.shouldShowAds, isTrue);

      adService.setInSettings(true);
      expect(adService.shouldShowAds, isFalse);
      adService.setInSettings(false);
      expect(adService.shouldShowAds, isTrue);
    });

    test('interstitial eligibility requires both event threshold and ad eligibility', () {
      if (kIsWeb) {
        expect(adService.shouldShowInterstitial(), isFalse);
        return;
      }

      for (var i = 0; i < 6; i++) {
        adService.trackClassificationCompleted();
      }

      // Still false because consent eligibility is false.
      expect(adService.shouldShowInterstitial(), isFalse);

      adService.debugSetCanRequestAds(true);
      expect(adService.shouldShowInterstitial(), isTrue);
    });

    test('dispose is idempotent', () {
      adService.dispose();
      expect(() => adService.dispose(), returnsNormally);
    });
  });
}
