import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';

void main() {
  group('HapticSettingsService', () {
    test('defaults to enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final service = HapticSettingsService();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(service.enabled, isTrue);
    });

    test('loads persisted value', () async {
      SharedPreferences.setMockInitialValues({
        'haptic_success_enabled': false,
      });
      final service = HapticSettingsService();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(service.enabled, isFalse);
    });

    test('setEnabled updates value', () async {
      SharedPreferences.setMockInitialValues({});
      final service = HapticSettingsService();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(service.enabled, isTrue);

      await service.setEnabled(false);
      expect(service.enabled, isFalse);

      await service.setEnabled(true);
      expect(service.enabled, isTrue);
    });
  });
}
