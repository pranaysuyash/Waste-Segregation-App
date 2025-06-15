import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:waste_segregation_app/screens/theme_settings_screen_riverpod.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';
import 'package:waste_segregation_app/providers.dart';

import 'theme_settings_riverpod_test.mocks.dart';

@GenerateMocks([PremiumService, ThemeProvider])
void main() {
  group('ThemeSettingsScreen Riverpod Tests', () {
    late MockPremiumService mockPremiumService;
    late MockThemeProvider mockThemeProvider;

    setUp(() {
      mockPremiumService = MockPremiumService();
      mockThemeProvider = MockThemeProvider();
      
      // Setup default mock behavior
      when(mockPremiumService.isPremiumFeature(any)).thenReturn(false);
      when(mockThemeProvider.themeMode).thenReturn(ThemeMode.system);
    });

    testWidgets('tapping Premium Features navigates to PremiumFeaturesScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Clean provider overrides - no complex setup needed!
            premiumServiceProvider.overrideWithValue(mockPremiumService),
            themeProvider.overrideWithValue(mockThemeProvider),
          ],
          child: MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (_) => const ThemeSettingsScreen(),
              '/premium': (_) => const PremiumFeaturesScreen(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap Premium Features
      final premiumTile = find.text('Premium Features');
      expect(premiumTile, findsWidgets);

      await tester.tap(premiumTile.first);
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
    });

    testWidgets('shows Custom Themes for non-premium users', (tester) async {
      // Setup: user is NOT premium
      when(mockPremiumService.isPremiumFeature('theme_customization')).thenReturn(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumServiceProvider.overrideWithValue(mockPremiumService),
            themeProvider.overrideWithValue(mockThemeProvider),
          ],
          child: const MaterialApp(
            home: ThemeSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Custom Themes tile is visible for non-premium users
      expect(find.text('Custom Themes'), findsOneWidget);
      expect(find.text('Create your own theme colors'), findsOneWidget);
    });

    testWidgets('hides Custom Themes for premium users', (tester) async {
      // Setup: user IS premium
      when(mockPremiumService.isPremiumFeature('theme_customization')).thenReturn(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumServiceProvider.overrideWithValue(mockPremiumService),
            themeProvider.overrideWithValue(mockThemeProvider),
          ],
          child: const MaterialApp(
            home: ThemeSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Custom Themes tile is hidden for premium users
      expect(find.text('Custom Themes'), findsNothing);
    });

    testWidgets('theme mode selection works correctly', (tester) async {
      when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumServiceProvider.overrideWithValue(mockPremiumService),
            themeProvider.overrideWithValue(mockThemeProvider),
          ],
          child: const MaterialApp(
            home: ThemeSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify theme options are present
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      
      // Verify radio buttons are present
      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
    });
  });
} 