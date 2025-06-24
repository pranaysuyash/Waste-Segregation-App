import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Golden Tests - Visual Regression', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens('Basic Widget Test', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      builder.addScenario(
        widget: _buildTestWrapper(
          const Text('Test Widget'),
        ),
        name: 'basic_test',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'basic_widget_test');
    });

    testGoldens('Container Test', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
        ]);

      builder.addScenario(
        widget: _buildTestWrapper(
          Container(
            width: 200,
            height: 100,
            color: Colors.blue,
            child: const Center(
              child: Text(
                'Container Test',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        name: 'container_test',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'container_test');
    });

    testGoldens('Theme Variations - Light and Dark', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();

      final builder = DeviceBuilder()..overrideDevicesForAllScenarios(devices: [Device.phone]);

      // Light theme
      builder.addScenario(
        widget: MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Light Theme Test'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[200],
                    child: const Text(
                      'Theme Test Widget',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'light_theme',
      );

      // Dark theme
      builder.addScenario(
        widget: MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Dark Theme Test'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[800],
                    child: const Text(
                      'Theme Test Widget',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'dark_theme',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'theme_variations');
    });
  });
}

Widget _buildTestWrapper(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    ),
  );
}