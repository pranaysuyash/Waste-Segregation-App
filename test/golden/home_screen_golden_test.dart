import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/screens/new_modern_home_screen.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import '../helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('Home Screen Golden Tests', () {
    testWidgets('home screen - light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createRiverpodTestWidget(
          child: const NewModernHomeScreen(),
          theme: ThemeData.light(),
        ),
      );
      
      // Wait for animations and async loading
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Take golden screenshot
      await expectLater(
        find.byType(NewModernHomeScreen),
        matchesGoldenFile('home_screen_light.png'),
      );
    });

    testWidgets('home screen - dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createRiverpodTestWidget(
          child: const NewModernHomeScreen(),
          theme: ThemeData.dark(),
        ),
      );
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await expectLater(
        find.byType(NewModernHomeScreen),
        matchesGoldenFile('home_screen_dark.png'),
      );
    });

    testWidgets('home screen - guest mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        createRiverpodTestWidget(
          child: const NewModernHomeScreen(isGuestMode: true),
          theme: ThemeData.light(),
        ),
      );
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await expectLater(
        find.byType(NewModernHomeScreen),
        matchesGoldenFile('home_screen_guest_mode.png'),
      );
    });

    testWidgets('home screen - different screen sizes', (WidgetTester tester) async {
      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        createRiverpodTestWidget(
          child: const NewModernHomeScreen(),
          theme: ThemeData.light(),
        ),
      );
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await expectLater(
        find.byType(NewModernHomeScreen),
        matchesGoldenFile('home_screen_tablet.png'),
      );
      
      // Reset to phone size
      await tester.binding.setSurfaceSize(const Size(375, 667));
    });
  });
} 