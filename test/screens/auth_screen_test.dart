import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/screens/auth_screen.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('AuthScreen', () {
    testWidgets('renders app name', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      expect(find.text(AppStrings.appName), findsOneWidget);
    });
  });
}
