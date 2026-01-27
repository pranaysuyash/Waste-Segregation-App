import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/instant_analysis_screen.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';

import '../mocks/mock_services.dart';

class _NavObserver extends NavigatorObserver {
  int pushes = 0;
  int replaces = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaces += 1;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

void main() {
  group('Navigation - InstantAnalysisScreen', () {
    testWidgets('pushReplacement navigates to ResultScreen exactly once',
        (WidgetTester tester) async {
      final aiService = MockAiService();
      final gamificationService = MockGamificationService();
      final observer = _NavObserver();

      final tmpDir = await Directory.systemTemp.createTemp('waste_app_test_');
      final tmpFile = File('${tmpDir.path}/image.jpg')
        ..writeAsBytesSync([0, 1, 2, 3]);
      addTearDown(() async {
        try {
          await tmpDir.delete(recursive: true);
        } catch (_) {}
      });

      final image = XFile(tmpFile.path);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AiService>.value(value: aiService),
            Provider<GamificationService>.value(value: gamificationService),
          ],
          child: MaterialApp(
            home: InstantAnalysisScreen(image: image),
            navigatorObservers: [observer],
          ),
        ),
      );

      // Let analysis + navigation complete without waiting on indeterminate animations.
      await tester.pump(); // first frame
      await tester
          .pump(const Duration(milliseconds: 50)); // post-frame callback
      await tester.pump(const Duration(seconds: 2)); // async work + navigation

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(observer.replaces, 1,
          reason: 'InstantAnalysisScreen should replace itself once');
    });
  });
}
