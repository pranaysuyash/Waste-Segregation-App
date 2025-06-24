import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/routes.dart';

void main() {
  group('Premium Routes Test', () {
    test('Routes.isValidRoute should return true for all premium route variants', () {
      expect(Routes.isValidRoute('/premium'), isTrue);
      expect(Routes.isValidRoute('/premium-features'), isTrue);
      expect(Routes.isValidRoute('/premium_features'), isTrue);
      expect(Routes.isValidRoute(Routes.premium), isTrue);
      expect(Routes.isValidRoute(Routes.premiumFeatures), isTrue);
      expect(Routes.isValidRoute(Routes.premiumFeaturesHyphen), isTrue);
    });

    test('Routes.isValidRoute should return false for invalid routes', () {
      expect(Routes.isValidRoute('/premium-invalid'), isFalse);
      expect(Routes.isValidRoute('/nonexistent'), isFalse);
      expect(Routes.isValidRoute(''), isFalse);
    });

    test('Routes constants should have correct values', () {
      expect(Routes.premium, equals('/premium'));
      expect(Routes.premiumFeatures, equals('/premium_features'));
      expect(Routes.premiumFeaturesHyphen, equals('/premium-features'));
    });

    test('All premium route variants should be in _allRoutes list', () {
      // This test ensures that our route additions are properly included
      expect(Routes.isValidRoute(Routes.premium), isTrue, reason: 'Routes.premium should be in _allRoutes');
      expect(Routes.isValidRoute(Routes.premiumFeatures), isTrue,
          reason: 'Routes.premiumFeatures should be in _allRoutes');
      expect(Routes.isValidRoute(Routes.premiumFeaturesHyphen), isTrue,
          reason: 'Routes.premiumFeaturesHyphen should be in _allRoutes');
    });

    test('Premium route constants should not be null or empty', () {
      expect(Routes.premium, isNotNull);
      expect(Routes.premium, isNotEmpty);
      expect(Routes.premiumFeatures, isNotNull);
      expect(Routes.premiumFeatures, isNotEmpty);
      expect(Routes.premiumFeaturesHyphen, isNotNull);
      expect(Routes.premiumFeaturesHyphen, isNotEmpty);
    });
  });
}
