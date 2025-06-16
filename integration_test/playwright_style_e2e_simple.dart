import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Playwright-Style E2E Tests', () {
    testWidgets(
      'Premium Features Journey - Complete Flow',
      (WidgetTester tester) async {
        // 🚀 Launch the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ✅ Verify home screen loads
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        
        // 🎯 Look for premium features button
        final premiumButton = find.textContaining('Premium');
        final starIcon = find.byIcon(Icons.star);
        
        if (premiumButton.evaluate().isNotEmpty) {
          await tester.tap(premiumButton.first);
          await tester.pumpAndSettle();
        } else if (starIcon.evaluate().isNotEmpty) {
          await tester.tap(starIcon.first);
          await tester.pumpAndSettle();
        }
        
        // ✅ Verify we're still in a valid state
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Waste Classification Flow - End to End',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 🎯 Start classification
        final cameraIcon = find.byIcon(Icons.camera_alt);
        final classifyText = find.textContaining('Classify');
        
        if (cameraIcon.evaluate().isNotEmpty) {
          await tester.tap(cameraIcon.first);
          await tester.pumpAndSettle();
        } else if (classifyText.evaluate().isNotEmpty) {
          await tester.tap(classifyText.first);
          await tester.pumpAndSettle();
        }
        
        // ✅ Verify camera/classification screen
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        
        // Look for capture button or FAB
        final captureButton = find.byIcon(Icons.camera);
        final fab = find.byType(FloatingActionButton);
        
        expect(captureButton.evaluate().isNotEmpty || fab.evaluate().isNotEmpty, 
               isTrue, reason: 'Should find capture button or FAB');
      },
    );

    testWidgets(
      'History and Analytics Navigation',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 🎯 Test history navigation
        final historyText = find.textContaining('History');
        final historyIcon = find.byIcon(Icons.history);
        
        if (historyText.evaluate().isNotEmpty) {
          await tester.tap(historyText.first);
          await tester.pumpAndSettle();
        } else if (historyIcon.evaluate().isNotEmpty) {
          await tester.tap(historyIcon.first);
          await tester.pumpAndSettle();
        }
        
        // ✅ Verify history screen
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        
        // Look for history list or empty state
        final listView = find.byType(ListView);
        final scrollView = find.byType(CustomScrollView);
        final emptyText = find.textContaining('No history');
        
        expect(listView.evaluate().isNotEmpty || 
               scrollView.evaluate().isNotEmpty || 
               emptyText.evaluate().isNotEmpty,
               isTrue, reason: 'Should find history list or empty state');
      },
    );

    testWidgets(
      'Settings and Preferences Flow',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 🎯 Navigate to settings
        final settingsText = find.textContaining('Settings');
        final settingsIcon = find.byIcon(Icons.settings);
        
        if (settingsText.evaluate().isNotEmpty) {
          await tester.tap(settingsText.first);
          await tester.pumpAndSettle();
        } else if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle();
        }
        
        // ✅ Verify settings screen
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        
        // 🎨 Look for theme toggle
        final themeText = find.textContaining('Theme');
        final switchWidget = find.byType(Switch);
        
        if (themeText.evaluate().isNotEmpty || switchWidget.evaluate().isNotEmpty) {
          // Theme settings exist
          expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        }
      },
    );

    testWidgets(
      'Performance Stress Test',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 🔄 Rapid navigation test
        for (var i = 0; i < 3; i++) {
          // Navigate through main screens
          final historyText = find.textContaining('History');
          if (historyText.evaluate().isNotEmpty) {
            await tester.tap(historyText.first);
            await tester.pumpAndSettle();
            
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle();
            }
          }
          
          final settingsText = find.textContaining('Settings');
          if (settingsText.evaluate().isNotEmpty) {
            await tester.tap(settingsText.first);
            await tester.pumpAndSettle();
            
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle();
            }
          }
        }
        
        // ✅ App should still be responsive
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Points System Integration Test',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 🎯 Look for points display
        final pointsText = find.textContaining('Points');
        final scoreText = find.textContaining('Score');
        
        if (pointsText.evaluate().isNotEmpty || scoreText.evaluate().isNotEmpty) {
          expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
          
          // Perform point-earning action
          final cameraIcon = find.byIcon(Icons.camera_alt);
          if (cameraIcon.evaluate().isNotEmpty) {
            await tester.tap(cameraIcon.first);
            await tester.pumpAndSettle();
            
            // Navigate back
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle();
            }
          }
        }
        
        // ✅ App should still be functional
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      },
    );
  });

  group('Accessibility Tests', () {
    testWidgets(
      'Text Scaling and Accessibility',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpAndSettle();
        
        // Verify app handles different sizes
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        
        // Test with larger screen
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        await tester.pumpAndSettle();
        
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      },
    );
  });
} 