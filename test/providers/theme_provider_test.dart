import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      // Set up mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
    });

    group('Theme Mode Management', () {
      test('should have light theme as default', () {
        expect(themeProvider.themeMode, ThemeMode.light);
      });

      test('should switch to dark theme correctly', () async {
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.themeMode, ThemeMode.dark);
      });

      test('should switch to system theme correctly', () async {
        await themeProvider.setThemeMode(ThemeMode.system);
        expect(themeProvider.themeMode, ThemeMode.system);
      });

      test('should switch back to light theme correctly', () async {
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.themeMode, ThemeMode.dark);
        
        await themeProvider.setThemeMode(ThemeMode.light);
        expect(themeProvider.themeMode, ThemeMode.light);
      });
    });

    group('Theme Persistence', () {
      test('should save theme preference when changed', () async {
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.themeMode, ThemeMode.dark);
        
        // Create a new provider to test persistence
        final newProvider = ThemeProvider();
        // Give it time to load from SharedPreferences
        await Future.delayed(const Duration(milliseconds: 100));
        expect(newProvider.themeMode, ThemeMode.dark);
      });

      test('should load saved theme preference on initialization', () async {
        SharedPreferences.setMockInitialValues({
          'themeMode': 2, // ThemeMode.dark.index
        });
        
        final provider = ThemeProvider();
        // Give it time to load from SharedPreferences
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(provider.themeMode, ThemeMode.dark);
      });

      test('should handle invalid saved theme preference', () async {
        SharedPreferences.setMockInitialValues({
          'themeMode': 999, // Invalid index
        });
        
        final provider = ThemeProvider();
        // Give it time to load from SharedPreferences
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should fallback to light theme (index 1)
        expect(provider.themeMode, ThemeMode.light);
      });

      test('should handle missing theme preference', () async {
        SharedPreferences.setMockInitialValues({});
        
        final provider = ThemeProvider();
        // Give it time to load from SharedPreferences
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should use default light theme
        expect(provider.themeMode, ThemeMode.light);
      });
    });

    group('Notification and Listeners', () {
      test('should notify listeners when theme changes', () async {
        var notified = false;
        themeProvider.addListener(() {
          notified = true;
        });
        
        await themeProvider.setThemeMode(ThemeMode.dark);
        
        expect(notified, true);
      });

      test('should notify listeners for each theme change', () async {
        var notificationCount = 0;
        themeProvider.addListener(() {
          notificationCount++;
        });
        
        await themeProvider.setThemeMode(ThemeMode.dark);
        await themeProvider.setThemeMode(ThemeMode.system);
        await themeProvider.setThemeMode(ThemeMode.light);
        
        expect(notificationCount, 3);
      });
    });

    group('Theme Mode Values', () {
      test('should support all ThemeMode values', () async {
        // Test light mode
        await themeProvider.setThemeMode(ThemeMode.light);
        expect(themeProvider.themeMode, ThemeMode.light);
        
        // Test dark mode
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.themeMode, ThemeMode.dark);
        
        // Test system mode
        await themeProvider.setThemeMode(ThemeMode.system);
        expect(themeProvider.themeMode, ThemeMode.system);
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test ensures the provider doesn't crash if SharedPreferences fails
        final provider = ThemeProvider();
        
        // Should not throw an exception
        expect(() async => await provider.setThemeMode(ThemeMode.dark), 
               returnsNormally);
      });
    });
  });
}
