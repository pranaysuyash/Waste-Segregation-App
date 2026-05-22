import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';

void main() {
  group('NavigationSettingsService', () {
    test('isValidStyle rejects invalid styles', () {
      expect(NavigationSettingsService.isValidStyle('invalid'), isFalse);
      expect(NavigationSettingsService.isValidStyle(''), isFalse);
      expect(NavigationSettingsService.isValidStyle('glass'), isFalse);
    });

    test('isValidStyle accepts valid styles', () {
      expect(NavigationSettingsService.isValidStyle('glassmorphism'), isTrue);
      expect(NavigationSettingsService.isValidStyle('material3'), isTrue);
      expect(NavigationSettingsService.isValidStyle('floating'), isTrue);
    });

    test('validStyles contains expected values', () {
      expect(NavigationSettingsService.validStyles,
          containsAll(['glassmorphism', 'material3', 'floating']));
      expect(NavigationSettingsService.validStyles.length, equals(3));
    });

    test('setNavigationStyle rejects invalid styles silently', () async {
      SharedPreferences.setMockInitialValues({});
      final service = NavigationSettingsService();
      await Future.delayed(const Duration(milliseconds: 10));
      final initialStyle = service.navigationStyle;

      await service.setNavigationStyle('invalid_style');
      expect(service.navigationStyle, equals(initialStyle));
      expect(NavigationSettingsService.isValidStyle(service.navigationStyle),
          isTrue);
    });
  });
}
