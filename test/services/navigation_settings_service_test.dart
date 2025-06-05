import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';

void main() {
  group('NavigationSettingsService', () {
    late NavigationSettingsService service;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization and Defaults', () {
      test('should initialize with default values', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization

        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should load saved settings from SharedPreferences', () async {
        // Set initial values in SharedPreferences
        SharedPreferences.setMockInitialValues({
          'bottom_nav_enabled': false,
          'fab_enabled': true,
          'navigation_style': 'material3',
        });

        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization

        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('material3'));
      });

      test('should use defaults when SharedPreferences values are null', () async {
        SharedPreferences.setMockInitialValues({});

        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization

        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should handle partial settings in SharedPreferences', () async {
        // Only set some values
        SharedPreferences.setMockInitialValues({
          'bottom_nav_enabled': false,
          // fab_enabled and navigation_style missing
        });

        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization

        expect(service.bottomNavEnabled, isFalse); // Saved value
        expect(service.fabEnabled, isFalse); // Default value
        expect(service.navigationStyle, equals('glassmorphism')); // Default value
      });
    });

    group('Bottom Navigation Settings', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should set bottom navigation enabled', () async {
        expect(service.bottomNavEnabled, isTrue); // Default

        await service.setBottomNavEnabled(false);
        expect(service.bottomNavEnabled, isFalse);

        await service.setBottomNavEnabled(true);
        expect(service.bottomNavEnabled, isTrue);
      });

      test('should persist bottom navigation setting', () async {
        await service.setBottomNavEnabled(false);

        // Create new service instance to test persistence
        final newService = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newService.bottomNavEnabled, isFalse);
        newService.dispose();
      });

      test('should notify listeners when bottom navigation changes', () async {
        var notificationCount = 0;
        service.addListener(() {
          notificationCount++;
        });

        await service.setBottomNavEnabled(false);
        expect(notificationCount, equals(1));

        await service.setBottomNavEnabled(true);
        expect(notificationCount, equals(2));

        // Setting to same value should still notify
        await service.setBottomNavEnabled(true);
        expect(notificationCount, equals(3));
      });
    });

    group('FAB Settings', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should set FAB enabled', () async {
        expect(service.fabEnabled, isFalse); // Default

        await service.setFabEnabled(true);
        expect(service.fabEnabled, isTrue);

        await service.setFabEnabled(false);
        expect(service.fabEnabled, isFalse);
      });

      test('should persist FAB setting', () async {
        await service.setFabEnabled(true);

        // Create new service instance to test persistence
        final newService = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newService.fabEnabled, isTrue);
        newService.dispose();
      });

      test('should notify listeners when FAB setting changes', () async {
        var notificationCount = 0;
        service.addListener(() {
          notificationCount++;
        });

        await service.setFabEnabled(true);
        expect(notificationCount, equals(1));

        await service.setFabEnabled(false);
        expect(notificationCount, equals(2));

        // Setting to same value should still notify
        await service.setFabEnabled(false);
        expect(notificationCount, equals(3));
      });
    });

    group('Navigation Style Settings', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should set navigation style', () async {
        expect(service.navigationStyle, equals('glassmorphism')); // Default

        await service.setNavigationStyle('material3');
        expect(service.navigationStyle, equals('material3'));

        await service.setNavigationStyle('floating');
        expect(service.navigationStyle, equals('floating'));

        await service.setNavigationStyle('glassmorphism');
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should persist navigation style setting', () async {
        await service.setNavigationStyle('material3');

        // Create new service instance to test persistence
        final newService = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newService.navigationStyle, equals('material3'));
        newService.dispose();
      });

      test('should notify listeners when navigation style changes', () async {
        var notificationCount = 0;
        service.addListener(() {
          notificationCount++;
        });

        await service.setNavigationStyle('material3');
        expect(notificationCount, equals(1));

        await service.setNavigationStyle('floating');
        expect(notificationCount, equals(2));

        // Setting to same value should still notify
        await service.setNavigationStyle('floating');
        expect(notificationCount, equals(3));
      });

      test('should handle custom navigation styles', () async {
        await service.setNavigationStyle('custom_style');
        expect(service.navigationStyle, equals('custom_style'));

        await service.setNavigationStyle('');
        expect(service.navigationStyle, equals(''));

        await service.setNavigationStyle('very_long_style_name_with_special_chars_123!@#');
        expect(service.navigationStyle, equals('very_long_style_name_with_special_chars_123!@#'));
      });
    });

    group('Reset Functionality', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should reset all settings to defaults', () async {
        // Change all settings from defaults
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        await service.setNavigationStyle('material3');

        // Verify changes
        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('material3'));

        // Reset to defaults
        await service.resetToDefaults();

        // Verify reset
        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should persist reset settings', () async {
        // Change settings
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        await service.setNavigationStyle('material3');

        // Reset
        await service.resetToDefaults();

        // Create new service instance to test persistence
        final newService = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newService.bottomNavEnabled, isTrue);
        expect(newService.fabEnabled, isFalse);
        expect(newService.navigationStyle, equals('glassmorphism'));
        newService.dispose();
      });

      test('should notify listeners when reset', () async {
        var notificationCount = 0;
        service.addListener(() {
          notificationCount++;
        });

        // Change some settings (this will generate notifications)
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        final initialNotifications = notificationCount;

        // Reset should generate one more notification
        await service.resetToDefaults();
        expect(notificationCount, equals(initialNotifications + 1));
      });

      test('should reset even when already at defaults', () async {
        // Settings are already at defaults, but reset should still work
        var notificationCount = 0;
        service.addListener(() {
          notificationCount++;
        });

        await service.resetToDefaults();

        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
        expect(notificationCount, equals(1)); // Should still notify
      });
    });

    group('Multiple Settings Changes', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should handle rapid sequential changes', () async {
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        await service.setNavigationStyle('material3');
        await service.setBottomNavEnabled(true);
        await service.setFabEnabled(false);
        await service.setNavigationStyle('floating');

        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('floating'));
      });

      test('should handle concurrent settings changes', () async {
        // Simulate concurrent changes
        await Future.wait([
          service.setBottomNavEnabled(false),
          service.setFabEnabled(true),
          service.setNavigationStyle('material3'),
        ]);

        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('material3'));
      });

      test('should maintain consistency across settings', () async {
        // Test various combinations
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);

        await service.setNavigationStyle('floating');
        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('floating'));
      });
    });

    group('Listener Management', () {
      setUp(() async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should support multiple listeners', () async {
        var listener1Count = 0;
        var listener2Count = 0;
        var listener3Count = 0;

        void listener1() => listener1Count++;
        void listener2() => listener2Count++;
        void listener3() => listener3Count++;

        service.addListener(listener1);
        service.addListener(listener2);
        service.addListener(listener3);

        await service.setBottomNavEnabled(false);

        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
        expect(listener3Count, equals(1));

        // Remove one listener
        service.removeListener(listener2);

        await service.setFabEnabled(true);

        expect(listener1Count, equals(2));
        expect(listener2Count, equals(1)); // Should not have increased
        expect(listener3Count, equals(2));
      });

      test('should handle listener removal safely', () async {
        var listenerCount = 0;
        void listener() => listenerCount++;

        service.addListener(listener);
        await service.setBottomNavEnabled(false);
        expect(listenerCount, equals(1));

        service.removeListener(listener);
        await service.setFabEnabled(true);
        expect(listenerCount, equals(1)); // Should not increase
      });

      test('should handle removing non-existent listener', () {
        void nonExistentListener() {}

        // Should not throw an error
        expect(() => service.removeListener(nonExistentListener), returnsNormally);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle SharedPreferences errors gracefully during initialization', () async {
        // We can't easily mock SharedPreferences to throw errors in this setup,
        // but we can test that the service initializes even with unexpected data
        SharedPreferences.setMockInitialValues({
          'bottom_nav_enabled': 'invalid_bool', // Wrong type
          'fab_enabled': 123, // Wrong type
          'navigation_style': true, // Wrong type
        });

        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Should fall back to defaults when encountering invalid data
        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should handle empty string navigation style', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        await service.setNavigationStyle('');
        expect(service.navigationStyle, equals(''));
      });

      test('should handle very long navigation style', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        final longStyle = 'a' * 1000;
        await service.setNavigationStyle(longStyle);
        expect(service.navigationStyle, equals(longStyle));
      });

      test('should handle special characters in navigation style', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        const specialStyle = 'style-with_special.chars@123!';
        await service.setNavigationStyle(specialStyle);
        expect(service.navigationStyle, equals(specialStyle));
      });

      test('should handle unicode characters in navigation style', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        const unicodeStyle = 'стиль_навигации_🎯_テーマ';
        await service.setNavigationStyle(unicodeStyle);
        expect(service.navigationStyle, equals(unicodeStyle));
      });
    });

    group('State Consistency', () {
      test('should maintain state consistency after disposal and recreation', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Set custom values
        await service.setBottomNavEnabled(false);
        await service.setFabEnabled(true);
        await service.setNavigationStyle('material3');

        // Dispose and recreate
        service.dispose();
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Values should persist
        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('material3'));
      });

      test('should handle rapid dispose and recreate cycles', () async {
        for (var i = 0; i < 10; i++) {
          service = NavigationSettingsService();
          await Future.delayed(const Duration(milliseconds: 50));
          
          await service.setBottomNavEnabled(i % 2 == 0);
          await service.setFabEnabled(i % 3 == 0);
          await service.setNavigationStyle('style_$i');
          
          service.dispose();
        }

        // Final instance should have the last set values
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.bottomNavEnabled, isTrue); // i=9, 9%2 != 0, so false -> true
        expect(service.fabEnabled, isTrue); // i=9, 9%3 == 0, so true
        expect(service.navigationStyle, equals('style_9'));
      });
    });

    group('Performance', () {
      test('should handle many sequential operations efficiently', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        final stopwatch = Stopwatch()..start();

        // Perform many operations
        for (var i = 0; i < 100; i++) {
          await service.setBottomNavEnabled(i % 2 == 0);
          await service.setFabEnabled(i % 3 == 0);
          await service.setNavigationStyle('style_${i % 5}');
        }

        stopwatch.stop();

        // Should complete in reasonable time (this is a rough check)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

        // Final state should be correct
        expect(service.bottomNavEnabled, isTrue); // 99 % 2 != 0, so would set false, but 100-1=99
        expect(service.fabEnabled, isTrue); // 99 % 3 == 0
        expect(service.navigationStyle, equals('style_4')); // 99 % 5 = 4
      });

      test('should handle many listeners efficiently', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        final listenerCounts = <int>[];
        
        // Add many listeners
        for (var i = 0; i < 50; i++) {
          listenerCounts.add(0);
          final index = i;
          service.addListener(() {
            listenerCounts[index]++;
          });
        }

        // Make a change
        await service.setBottomNavEnabled(false);

        // All listeners should have been notified
        for (final count in listenerCounts) {
          expect(count, equals(1));
        }
      });
    });

    group('Integration Scenarios', () {
      test('should support realistic usage patterns', () async {
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate user toggling settings in UI
        await service.setBottomNavEnabled(false); // User disables bottom nav
        await service.setFabEnabled(true); // User enables FAB as alternative
        
        expect(service.bottomNavEnabled, isFalse);
        expect(service.fabEnabled, isTrue);

        // User tries different navigation styles
        await service.setNavigationStyle('material3');
        expect(service.navigationStyle, equals('material3'));

        await service.setNavigationStyle('floating');
        expect(service.navigationStyle, equals('floating'));

        // User decides to go back to defaults
        await service.resetToDefaults();
        expect(service.bottomNavEnabled, isTrue);
        expect(service.fabEnabled, isFalse);
        expect(service.navigationStyle, equals('glassmorphism'));
      });

      test('should work correctly with app lifecycle events', () async {
        // Simulate app start
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // User makes changes
        await service.setFabEnabled(true);
        await service.setNavigationStyle('material3');

        // Simulate app backgrounding (no explicit action needed)
        
        // Simulate app foregrounding with new service instance
        service.dispose();
        service = NavigationSettingsService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Settings should persist
        expect(service.fabEnabled, isTrue);
        expect(service.navigationStyle, equals('material3'));
      });
    });
  });
}
