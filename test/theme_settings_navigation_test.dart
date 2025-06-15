import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:waste_segregation_app/screens/theme_settings_screen.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';

void main() {
  group('ThemeSettingsScreen navigation', () {
    testWidgets('tapping Premium Features navigates to PremiumFeaturesScreen', (tester) async {
      // 1. Build our test app with both Provider and Riverpod scopes
      await tester.pumpWidget(
        ProviderScope( // for any Riverpod providers you might still use downstream
          child: provider.MultiProvider(
            providers: [
              provider.ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(),
              ),
              provider.ChangeNotifierProvider<PremiumService>(
                create: (_) => PremiumService(),
              ),
            ],
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (_) => const ThemeSettingsScreen(),
                '/premium': (_) => const PremiumFeaturesScreen(),
                '/premium-features': (_) => const PremiumFeaturesScreen(),
                '/premium_features': (_) => const PremiumFeaturesScreen(),
              },
            ),
          ),
        ),
      );

      // 2. Wait for any async init to settle
      await tester.pumpAndSettle();

      // 3. Verify the "Premium Features" tile exists
      final premiumTile = find.text('Premium Features');
      expect(premiumTile, findsWidgets);

      // 4. Tap it & let navigation happen
      await tester.tap(premiumTile.first);
      await tester.pumpAndSettle();

      // 5. Confirm that PremiumFeaturesScreen is now on screen
      expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
      expect(find.text('Premium Features'), findsWidgets); // AppBar title
    });

    testWidgets('tapping Upgrade Now in dialog navigates to PremiumFeaturesScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: provider.MultiProvider(
            providers: [
              provider.ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(),
              ),
              provider.ChangeNotifierProvider<PremiumService>(
                create: (_) => PremiumService(),
              ),
            ],
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (_) => const ThemeSettingsScreen(),
                '/premium': (_) => const PremiumFeaturesScreen(),
                '/premium-features': (_) => const PremiumFeaturesScreen(),
                '/premium_features': (_) => const PremiumFeaturesScreen(),
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap Custom Themes to trigger the premium dialog
      final customThemesTile = find.text('Custom Themes');
      expect(customThemesTile, findsOneWidget);
      
      await tester.tap(customThemesTile);
      await tester.pumpAndSettle();

      // Verify dialog appeared
      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.text('Upgrade Now'), findsOneWidget);

      // Tap Upgrade Now
      await tester.tap(find.text('Upgrade Now'));
      await tester.pumpAndSettle();

      // Verify navigation to PremiumFeaturesScreen
      expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
    });

    testWidgets('Premium Features tile is always visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: provider.MultiProvider(
            providers: [
              provider.ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(),
              ),
              provider.ChangeNotifierProvider<PremiumService>(
                create: (_) => PremiumService(),
              ),
            ],
            child: const MaterialApp(
              home: ThemeSettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Premium Features section and tile are visible
      expect(find.text('Premium Features'), findsWidgets);
      expect(find.text('Unlock advanced theme customization and more'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });
  });
} 