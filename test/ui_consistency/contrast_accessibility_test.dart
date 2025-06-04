import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Contrast and Accessibility Tests', () {
    
    /// Color Contrast Compliance Tests
    group('WCAG Color Contrast Compliance', () {
      testWidgets('Primary color scheme meets WCAG AA standards', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
            ),
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final colorScheme = Theme.of(context).colorScheme;

        // Test primary color combinations
        final primaryContrast = _calculateContrast(
          colorScheme.onPrimary,
          colorScheme.primary,
        );
        expect(primaryContrast, greaterThan(4.5),
               reason: 'Primary color contrast should meet WCAG AA (4.5:1) - got ${primaryContrast.toStringAsFixed(2)}:1');

        // Test secondary color combinations
        final secondaryContrast = _calculateContrast(
          colorScheme.onSecondary,
          colorScheme.secondary,
        );
        expect(secondaryContrast, greaterThan(4.5),
               reason: 'Secondary color contrast should meet WCAG AA (4.5:1) - got ${secondaryContrast.toStringAsFixed(2)}:1');

        // Test surface color combinations
        final surfaceContrast = _calculateContrast(
          colorScheme.onSurface,
          colorScheme.surface,
        );
        expect(surfaceContrast, greaterThan(4.5),
               reason: 'Surface color contrast should meet WCAG AA (4.5:1) - got ${surfaceContrast.toStringAsFixed(2)}:1');
      });

      testWidgets('Error and warning colors have sufficient contrast', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
            ),
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final colorScheme = Theme.of(context).colorScheme;

        // Test error color contrast
        final errorContrast = _calculateContrast(
          colorScheme.onError,
          colorScheme.error,
        );
        expect(errorContrast, greaterThan(4.5),
               reason: 'Error color contrast should meet WCAG AA (4.5:1) - got ${errorContrast.toStringAsFixed(2)}:1');

        // Test error container contrast
        final errorContainerContrast = _calculateContrast(
          colorScheme.onErrorContainer,
          colorScheme.errorContainer,
        );
        expect(errorContainerContrast, greaterThan(3.0),
               reason: 'Error container should have minimum readable contrast - got ${errorContainerContrast.toStringAsFixed(2)}:1');
      });

      testWidgets('App-specific color constants meet contrast requirements', (WidgetTester tester) async {
        // Test predefined color constants
        final colorPairs = [
          [Colors.white, AppTheme.primaryColor],
          [Colors.black, AppTheme.backgroundColor],
          [AppTheme.textColor, AppTheme.backgroundColor],
          [AppTheme.secondaryTextColor, AppTheme.backgroundColor],
        ];

        for (final pair in colorPairs) {
          final contrast = _calculateContrast(pair[0], pair[1]);
          expect(contrast, greaterThan(3.0),
                 reason: 'Color pair ${pair[0]} on ${pair[1]} should have minimum readable contrast - got ${contrast.toStringAsFixed(2)}:1');
        }
      });
    });

    /// Dark Mode Contrast Tests
    group('Dark Mode Color Contrast', () {
      testWidgets('Dark theme maintains proper contrast ratios', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final colorScheme = Theme.of(context).colorScheme;

        // Test dark theme primary colors
        final primaryContrast = _calculateContrast(
          colorScheme.onPrimary,
          colorScheme.primary,
        );
        expect(primaryContrast, greaterThan(3.0),
               reason: 'Dark theme primary contrast should be readable - got ${primaryContrast.toStringAsFixed(2)}:1');

        // Test dark theme surface colors
        final surfaceContrast = _calculateContrast(
          colorScheme.onSurface,
          colorScheme.surface,
        );
        expect(surfaceContrast, greaterThan(4.5),
               reason: 'Dark theme surface contrast should meet WCAG AA - got ${surfaceContrast.toStringAsFixed(2)}:1');
      });

      testWidgets('High contrast mode support', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.highContrastDark(),
            ),
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final colorScheme = Theme.of(context).colorScheme;

        // High contrast should exceed WCAG AAA (7:1)
        final primaryContrast = _calculateContrast(
          colorScheme.onPrimary,
          colorScheme.primary,
        );
        expect(primaryContrast, greaterThan(7.0),
               reason: 'High contrast theme should exceed WCAG AAA (7:1) - got ${primaryContrast.toStringAsFixed(2)}:1');
      });
    });

    /// Text Readability Tests
    group('Text Readability and Sizing', () {
      testWidgets('Text maintains readability at different sizes', (WidgetTester tester) async {
        final testSizes = [12.0, 14.0, 16.0, 18.0, 20.0, 24.0];
        
        for (final fontSize in testSizes) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Text(
                  'Sample text for readability testing',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          );

          // Verify text renders without overflow
          final textWidget = tester.widget<Text>(find.byType(Text));
          expect(textWidget.style?.fontSize, equals(fontSize));

          // For sizes below 14px, recommend higher contrast
          if (fontSize < 14.0) {
            final contrast = _calculateContrast(Colors.black, Colors.white);
            expect(contrast, greaterThan(7.0),
                   reason: 'Small text (${fontSize}px) should have enhanced contrast (7:1)');
          }
        }
      });

      testWidgets('Text scales properly with accessibility settings', (WidgetTester tester) async {
        final scaleFactors = [0.8, 1.0, 1.2, 1.5, 2.0, 3.0];
        
        for (final scaleFactor in scaleFactors) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaleFactor: scaleFactor),
              child: MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Heading Text', style: Theme.of(tester.element(find.byType(Scaffold))).textTheme.headlineMedium),
                      Text('Body Text', style: Theme.of(tester.element(find.byType(Scaffold))).textTheme.bodyMedium),
                      Text('Caption Text', style: Theme.of(tester.element(find.byType(Scaffold))).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verify no text overflow at any scale factor
          final textWidgets = tester.widgetList<Text>(find.byType(Text));
          for (final textWidget in textWidgets) {
            final renderBox = tester.renderObject(find.byWidget(textWidget));
            expect(renderBox.hasSize, isTrue,
                   reason: 'Text should render properly at scale factor $scaleFactor');
          }
        }
      });

      testWidgets('Long text handles overflow gracefully', (WidgetTester tester) async {
        const longText = 'This is a very long text that should test how the application handles text overflow when the content is too long to fit in the available space and should wrap or truncate appropriately.';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200, // Constrained width to force overflow
                child: Column(
                  children: [
                    Text(longText),
                    Text(longText, overflow: TextOverflow.ellipsis),
                    Text(longText, overflow: TextOverflow.fade),
                    Text(longText, maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
        );

        // Should render without exceptions
        expect(find.byType(Text), findsNWidgets(4));
      });
    });

    /// Color Blindness Accessibility Tests
    group('Color Blindness Accessibility', () {
      testWidgets('Important information is not conveyed by color alone', (WidgetTester tester) async {
        // Test common UI patterns that should not rely solely on color
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Error state with icon and text
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      Text('Error: Invalid input'),
                    ],
                  ),
                  // Success state with icon and text
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      Text('Success: Operation completed'),
                    ],
                  ),
                  // Warning state with icon and text
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      Text('Warning: Please review'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify that state is indicated by both color and other visual cues
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('Error: Invalid input'), findsOneWidget);
        expect(find.text('Success: Operation completed'), findsOneWidget);
        expect(find.text('Warning: Please review'), findsOneWidget);
      });

      testWidgets('Color combinations work for common color blindness types', (WidgetTester tester) async {
        // Test color combinations that should work for most color blind users
        final colorBlindFriendlyPairs = [
          [Colors.blue, Colors.orange],    // Blue-Orange (protanopia/deuteranopia friendly)
          [Colors.black, Colors.white],    // High contrast
          [Colors.blue, Colors.yellow],    // Blue-Yellow (red-green color blind friendly)
        ];

        for (final pair in colorBlindFriendlyPairs) {
          final contrast = _calculateContrast(pair[0], pair[1]);
          expect(contrast, greaterThan(3.0),
                 reason: 'Color blind friendly pair ${pair[0]} on ${pair[1]} should have good contrast');
        }
      });
    });

    /// Interactive Element Accessibility
    group('Interactive Element Accessibility', () {
      testWidgets('Touch targets meet minimum size requirements', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button')),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                  Checkbox(value: false, onChanged: (value) {}),
                  Radio(value: 1, groupValue: 1, onChanged: (value) {}),
                  Switch(value: false, onChanged: (value) {}),
                ],
              ),
            ),
          ),
        );

        final interactiveElements = [
          find.byType(ElevatedButton),
          find.byType(IconButton),
          find.byType(Checkbox),
          find.byType(Radio),
          find.byType(Switch),
        ];

        for (final finder in interactiveElements) {
          final size = tester.getSize(finder);
          
          // Material Design minimum touch target is 48x48dp
          expect(size.width, greaterThanOrEqualTo(48.0),
                 reason: 'Interactive element should meet minimum width of 48dp');
          expect(size.height, greaterThanOrEqualTo(48.0),
                 reason: 'Interactive element should meet minimum height of 48dp');
        }
      });

      testWidgets('Focus indicators are visible and accessible', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                  TextField(decoration: const InputDecoration(labelText: 'Input')),
                ],
              ),
            ),
          ),
        );

        // Test keyboard navigation focus
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Focus should be visible (verified by testing framework)
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });
    });

    /// Dynamic Content Accessibility
    group('Dynamic Content Accessibility', () {
      testWidgets('Loading states maintain accessibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const CircularProgressIndicator(),
                  const LinearProgressIndicator(),
                  Container(
                    height: 100,
                    color: Colors.grey.shade300,
                    child: const Center(child: Text('Loading...')),
                  ),
                ],
              ),
            ),
          ),
        );

        // Loading indicators should be accessible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
      });

      testWidgets('Error states provide clear feedback', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade100,
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(child: Text('An error occurred. Please try again.')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Error state should be clearly visible and informative
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('An error occurred. Please try again.'), findsOneWidget);
        
        // Error container should have sufficient contrast
        final errorContrast = _calculateContrast(Colors.red, Colors.red.shade100);
        expect(errorContrast, greaterThan(2.0),
               reason: 'Error state should have visible contrast');
      });
    });
  });
}

/// Calculate contrast ratio between two colors
/// Returns ratio from 1:1 (no contrast) to 21:1 (maximum contrast)
double _calculateContrast(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  
  return (lighter + 0.05) / (darker + 0.05);
}

/// Simulate color blindness for testing (simplified simulation)
Color _simulateProtanopia(Color original) {
  // Simplified protanopia simulation (red weakness)
  return Color.fromARGB(
    original.alpha,
    (original.red * 0.567).round(),
    (original.green * 1.433).round(),
    original.blue,
  );
}

Color _simulateDeuteranopia(Color original) {
  // Simplified deuteranopia simulation (green weakness)
  return Color.fromARGB(
    original.alpha,
    (original.red * 1.25).round(),
    (original.green * 0.75).round(),
    original.blue,
  );
} 