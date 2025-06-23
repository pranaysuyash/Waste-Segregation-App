import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Waste Segregation App E2E Tests', () {
    testWidgets('Complete waste classification flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify home screen loads
      expect(find.text('Waste Segregation'), findsOneWidget);

      // Navigate to camera/classification screen
      final classifyButton = find.byKey(const Key('classify_button'));
      if (classifyButton.evaluate().isNotEmpty) {
        await tester.tap(classifyButton);
        await tester.pumpAndSettle();
      }

      // Test navigation to history
      final historyButton = find.byKey(const Key('history_button'));
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        
        // Verify history screen
        expect(find.text('Classification History'), findsOneWidget);
        
        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Test points system
      final pointsWidget = find.byKey(const Key('points_display'));
      if (pointsWidget.evaluate().isNotEmpty) {
        expect(pointsWidget, findsOneWidget);
      }

      // Test achievements screen
      final achievementsButton = find.byKey(const Key('achievements_button'));
      if (achievementsButton.evaluate().isNotEmpty) {
        await tester.tap(achievementsButton);
        await tester.pumpAndSettle();
        
        // Verify achievements screen
        expect(find.text('Achievements'), findsOneWidget);
        
        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Premium features flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to premium features
      final premiumButton = find.byKey(const Key('premium_button'));
      if (premiumButton.evaluate().isNotEmpty) {
        await tester.tap(premiumButton);
        await tester.pumpAndSettle();
        
        // Verify premium screen
        expect(find.text('Premium Features'), findsOneWidget);
        
        // Test premium banner visibility
        final premiumBanner = find.byKey(const Key('premium_banner'));
        expect(premiumBanner, findsOneWidget);
      }
    });

    testWidgets('Settings and profile flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings
      final settingsButton = find.byKey(const Key('settings_button'));
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        
        // Verify settings screen
        expect(find.text('Settings'), findsOneWidget);
      }
    });
  });
} 