import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Ensure we capture frame times
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Performance Regression Tests', () {
    testWidgets('App startup and initial render performance',
        (WidgetTester tester) async {
      final stopWatch = Stopwatch()..start();

      // Start the app
      app.main();
      
      // Wait for the initial frame
      await tester.pumpAndSettle();
      
      stopWatch.stop();
      final startupTime = stopWatch.elapsedMilliseconds;

      debugPrint('App startup time: $startupTime ms');

      // Check if startup time exceeds budget (e.g. 2000ms)
      // This is just a baseline for CI. If it grows too much, it fails.
      expect(startupTime, lessThan(5000), reason: 'App startup is too slow, possible Token Economy initialization regression.');
    });

    // TODO: Add further benchmark steps for classification UI rendering 
    // once mock providers are set up to bypass camera initialization in CI.
  });
}
