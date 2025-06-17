import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/screens/auth_screen.dart';
import '../helpers/test_helper.dart';

void main() {
  group('Auth Screen Golden Tests', () {
    testWidgets('auth screen - light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthScreen(),
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('auth_screen_light.png'),
      );
    });

    testWidgets('auth screen - dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthScreen(),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(
        find.byType(AuthScreen),
        matchesGoldenFile('auth_screen_dark.png'),
      );
    });
  });
} 