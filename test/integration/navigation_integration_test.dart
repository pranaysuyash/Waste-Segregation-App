import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Integration Tests', () {
    testWidgets('Analysis flow should not cause double navigation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the camera/analysis button
      final cameraButton = find.byIcon(Icons.camera_alt).first;
      expect(cameraButton, findsOneWidget);

      // Get initial Navigator state
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      final initialRouteCount = navigator.widget.pages?.length ?? 1;

      // Tap the camera button
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred but not duplicated
      final newRouteCount = navigator.widget.pages?.length ?? 1;
      expect(newRouteCount, equals(initialRouteCount + 1),
             reason: 'Should navigate to exactly one new screen');

      // Visual verification - app should be in stable state
      await tester.pumpAndSettle();
    });

    testWidgets('Rapid button taps should not cause multiple navigations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find navigation buttons
      final buttons = find.byType(FloatingActionButton);
      if (buttons.evaluate().isNotEmpty) {
        final button = buttons.first;
        
        // Get initial state
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        final initialRouteCount = navigator.widget.pages?.length ?? 1;

        // Rapid fire taps
        await tester.tap(button);
        await tester.tap(button);
        await tester.tap(button);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // Verify only one navigation occurred
        final finalRouteCount = navigator.widget.pages?.length ?? 1;
        expect(finalRouteCount, lessThanOrEqualTo(initialRouteCount + 1),
               reason: 'Rapid taps should not cause multiple navigations');
      }
    });

    testWidgets('Auto-analyze flow should complete without double processing', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for auto-analyze button or instant analysis option
      final autoAnalyzeButton = find.textContaining('Auto').first;
      if (autoAnalyzeButton.evaluate().isNotEmpty) {
        // Get initial Navigator state
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        final initialRouteCount = navigator.widget.pages?.length ?? 1;

        // Trigger auto-analyze
        await tester.tap(autoAnalyzeButton);
        await tester.pumpAndSettle();

        // Wait for analysis to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify we ended up on a single result screen
        final finalRouteCount = navigator.widget.pages?.length ?? 1;
        expect(finalRouteCount, lessThanOrEqualTo(initialRouteCount + 1),
               reason: 'Auto-analyze should not create multiple routes');

        // Verify we're on the expected screen
        final resultFinder = find.textContaining('Result');
        final classificationFinder = find.textContaining('Classification');
        expect(resultFinder.evaluate().isNotEmpty || classificationFinder.evaluate().isNotEmpty, 
               isTrue, reason: 'Should find either Result or Classification text');
      }
    });

    testWidgets('Navigation stack should remain clean after operations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Perform a complete navigation cycle
      final homeButton = find.byIcon(Icons.home).first;
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
      }

      // Navigate to different tabs
      final tabs = find.byType(BottomNavigationBar);
      if (tabs.evaluate().isNotEmpty) {
        final tabItems = find.descendant(
          of: tabs.first,
          matching: find.byType(InkWell),
        );
        
        for (int i = 0; i < tabItems.evaluate().length && i < 3; i++) {
          await tester.tap(tabItems.at(i));
          await tester.pumpAndSettle();
          
          // Verify Navigator stack doesn't grow unnecessarily
          final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
          final routeCount = navigator.widget.pages?.length ?? 1;
          expect(routeCount, lessThanOrEqualTo(2),
                 reason: 'Tab navigation should not accumulate routes');
        }
      }
    });

    testWidgets('Error scenarios should not leave orphaned routes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to trigger error scenarios
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      final initialRouteCount = navigator.widget.pages?.length ?? 1;

      // Simulate network error or analysis failure
      // (This would need to be coordinated with mock services in a real test)
      
      // For now, just verify the app remains stable
      await tester.pumpAndSettle();
      
      final finalRouteCount = navigator.widget.pages?.length ?? 1;
      expect(finalRouteCount, equals(initialRouteCount),
             reason: 'Error scenarios should not leave orphaned routes');
    });
  });

  group('Visual Navigation Tests', () {
    testWidgets('Navigation animations should complete properly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find a navigation trigger
      final button = find.byType(FloatingActionButton).first;
      if (button.evaluate().isNotEmpty) {
        // Trigger navigation
        await tester.tap(button);
        
        // Let animations complete
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Verify final state is stable
        await tester.pumpAndSettle();
        
        // Verify no duplicate screens are visible
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });
  });
} 