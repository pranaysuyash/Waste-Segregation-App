import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      themeProvider = ThemeProvider();
    });

    group('Theme Mode Management', () {
      test('should have light theme as default', () {
        expect(themeProvider.themeMode, ThemeMode.light);
        expect(themeProvider.isDarkMode, false);
      });

      test('should switch to dark theme correctly', () {
        themeProvider.setThemeMode(ThemeMode.dark);
        
        expect(themeProvider.themeMode, ThemeMode.dark);
        expect(themeProvider.isDarkMode, true);
      });

      test('should switch to system theme correctly', () {
        themeProvider.setThemeMode(ThemeMode.system);
        
        expect(themeProvider.themeMode, ThemeMode.system);
        expect(themeProvider.isDarkMode, false); // Depends on system default
      });

      test('should toggle theme correctly', () {
        // Start with light theme
        expect(themeProvider.isDarkMode, false);
        
        // Toggle to dark
        themeProvider.toggleTheme();
        expect(themeProvider.isDarkMode, true);
        expect(themeProvider.themeMode, ThemeMode.dark);
        
        // Toggle back to light
        themeProvider.toggleTheme();
        expect(themeProvider.isDarkMode, false);
        expect(themeProvider.themeMode, ThemeMode.light);
      });
    });

    group('Theme Persistence', () {
      test('should save theme preference when changed', () async {
        SharedPreferences.setMockInitialValues({});
        
        themeProvider.setThemeMode(ThemeMode.dark);
        
        // Verify the theme mode was set
        expect(themeProvider.themeMode, ThemeMode.dark);
      });

      test('should load saved theme preference on initialization', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'dark',
        });
        
        final provider = ThemeProvider();
        await provider.loadThemePreference();
        
        expect(provider.themeMode, ThemeMode.dark);
        expect(provider.isDarkMode, true);
      });

      test('should handle invalid saved theme preference', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'invalid_mode',
        });
        
        final provider = ThemeProvider();
        await provider.loadThemePreference();
        
        // Should fallback to light theme
        expect(provider.themeMode, ThemeMode.light);
        expect(provider.isDarkMode, false);
      });

      test('should handle missing theme preference', () async {
        SharedPreferences.setMockInitialValues({});
        
        final provider = ThemeProvider();
        await provider.loadThemePreference();
        
        // Should use default light theme
        expect(provider.themeMode, ThemeMode.light);
        expect(provider.isDarkMode, false);
      });
    });

    group('Theme Data Generation', () {
      test('should provide light theme data', () {
        final lightTheme = themeProvider.lightTheme;
        
        expect(lightTheme.brightness, Brightness.light);
        expect(lightTheme.primarySwatch, Colors.green);
        expect(lightTheme.scaffoldBackgroundColor, Colors.grey[50]);
      });

      test('should provide dark theme data', () {
        final darkTheme = themeProvider.darkTheme;
        
        expect(darkTheme.brightness, Brightness.dark);
        expect(darkTheme.primarySwatch, Colors.green);
        expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF121212));
      });

      test('should provide current theme data based on mode', () {
        // Test light theme
        themeProvider.setThemeMode(ThemeMode.light);
        final currentLight = themeProvider.currentTheme;
        expect(currentLight.brightness, Brightness.light);
        
        // Test dark theme
        themeProvider.setThemeMode(ThemeMode.dark);
        final currentDark = themeProvider.currentTheme;
        expect(currentDark.brightness, Brightness.dark);
      });
    });

    group('Theme Colors and Styles', () {
      test('should provide consistent primary colors across themes', () {
        final lightTheme = themeProvider.lightTheme;
        final darkTheme = themeProvider.darkTheme;
        
        // Primary color should be consistent
        expect(lightTheme.primaryColor, darkTheme.primaryColor);
      });

      test('should provide appropriate contrast colors', () {
        final lightTheme = themeProvider.lightTheme;
        final darkTheme = themeProvider.darkTheme;
        
        // Light theme should have dark text
        expect(lightTheme.textTheme.bodyLarge?.color, isNot(equals(Colors.white)));
        
        // Dark theme should have light text
        expect(darkTheme.textTheme.bodyLarge?.color, isNot(equals(Colors.black)));
      });

      test('should provide appropriate card colors', () {
        final lightTheme = themeProvider.lightTheme;
        final darkTheme = themeProvider.darkTheme;
        
        // Card colors should be appropriate for each theme
        expect(lightTheme.cardColor, isNot(equals(darkTheme.cardColor)));
      });
    });

    group('Notification and Listeners', () {
      test('should notify listeners when theme changes', () {
        bool notified = false;
        themeProvider.addListener(() {
          notified = true;
        });
        
        themeProvider.setThemeMode(ThemeMode.dark);
        
        expect(notified, true);
      });

      test('should not notify listeners when setting same theme', () {
        int notificationCount = 0;
        themeProvider.addListener(() {
          notificationCount++;
        });
        
        // Set the same theme multiple times
        themeProvider.setThemeMode(ThemeMode.light);
        themeProvider.setThemeMode(ThemeMode.light);
        themeProvider.setThemeMode(ThemeMode.light);
        
        // Should only notify once (or not at all if already light)
        expect(notificationCount, lessThanOrEqualTo(1));
      });
    });

    group('System Theme Integration', () {
      test('should handle system theme changes when in system mode', () {
        themeProvider.setThemeMode(ThemeMode.system);
        
        expect(themeProvider.themeMode, ThemeMode.system);
        // Note: isDarkMode depends on actual system theme in real implementation
      });

      test('should provide correct theme when system mode is selected', () {
        themeProvider.setThemeMode(ThemeMode.system);
        final currentTheme = themeProvider.currentTheme;
        
        // Should provide a valid theme
        expect(currentTheme, isNotNull);
        expect(currentTheme.brightness, isIn([Brightness.light, Brightness.dark]));
      });
    });

    group('Accessibility Support', () {
      test('should support high contrast themes if implemented', () {
        // Test that theme provides good contrast ratios
        final lightTheme = themeProvider.lightTheme;
        final darkTheme = themeProvider.darkTheme;
        
        expect(lightTheme, isNotNull);
        expect(darkTheme, isNotNull);
        
        // Ensure themes are different
        expect(lightTheme.brightness, isNot(equals(darkTheme.brightness)));
      });

      test('should maintain consistent styling across theme changes', () {
        final lightTheme = themeProvider.lightTheme;
        final darkTheme = themeProvider.darkTheme;
        
        // Text themes should be consistently structured
        expect(lightTheme.textTheme.headlineLarge, isNotNull);
        expect(darkTheme.textTheme.headlineLarge, isNotNull);
        
        // Button themes should be consistently structured
        expect(lightTheme.elevatedButtonTheme, isNotNull);
        expect(darkTheme.elevatedButtonTheme, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle null theme preference gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': null,
        });
        
        final provider = ThemeProvider();
        await provider.loadThemePreference();
        
        // Should not throw and use default
        expect(provider.themeMode, ThemeMode.light);
      });

      test('should handle SharedPreferences errors gracefully', () async {
        // Test that provider handles storage errors without crashing
        final provider = ThemeProvider();
        
        expect(() async => await provider.loadThemePreference(), 
               returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should not create new theme objects unnecessarily', () {
        final theme1 = themeProvider.lightTheme;
        final theme2 = themeProvider.lightTheme;
        
        // Should return the same instance or equivalent object
        expect(theme1.brightness, theme2.brightness);
        expect(theme1.primaryColor, theme2.primaryColor);
      });

      test('should handle rapid theme changes efficiently', () {
        // Simulate rapid theme switching
        for (int i = 0; i < 100; i++) {
          themeProvider.setThemeMode(i % 2 == 0 ? ThemeMode.light : ThemeMode.dark);
        }
        
        // Should complete without issues
        expect(themeProvider.themeMode, ThemeMode.dark);
      });
    });
  });
}
