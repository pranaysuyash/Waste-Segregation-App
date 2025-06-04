import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/ui_consistency_utils.dart';
import '../test_config/plugin_mock_setup.dart';

void main() {
  group('Text Consistency Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = MyApp();
    });

    /// Typography Consistency Tests
    group('Typography Consistency', () {
      testWidgets('All headings use consistent typography', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find all Text widgets that appear to be headings
        final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
        final headingStyles = <TextStyle>[];
        final bodyStyles = <TextStyle>[];

        for (final textWidget in textWidgets) {
          final style = textWidget.style;
          if (style != null) {
            final fontSize = style.fontSize ?? 14.0;
            final fontWeight = style.fontWeight ?? FontWeight.normal;
            
            // Classify as heading or body text based on size and weight
            if (fontSize >= 18.0 || fontWeight.index >= FontWeight.w600.index) {
              headingStyles.add(style);
            } else {
              bodyStyles.add(style);
            }
          }
        }

        // Check heading consistency
        if (headingStyles.isNotEmpty) {
          final expectedHeadingFont = headingStyles.first.fontFamily;
          for (final style in headingStyles) {
            expect(style.fontFamily, equals(expectedHeadingFont),
                   reason: 'All headings should use the same font family');
          }
        }

        // Verify predefined text styles are used
        expect(headingStyles.where((s) => 
               s.fontSize == UIConsistency.headingLarge(tester.element(find.byType(MyApp))).fontSize ||
               s.fontSize == UIConsistency.headingMedium(tester.element(find.byType(MyApp))).fontSize ||
               s.fontSize == UIConsistency.headingSmall(tester.element(find.byType(MyApp))).fontSize
               ).length, greaterThan(0),
               reason: 'Should use predefined heading styles from UIConsistency');
      });

      testWidgets('Body text uses consistent typography', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        final bodyLargeStyle = UIConsistency.bodyLarge(context);
        final bodyMediumStyle = UIConsistency.bodyMedium(context);
        final bodySmallStyle = UIConsistency.bodySmall(context);

        // Verify style consistency
        expect(bodyLargeStyle.fontFamily, equals(bodyMediumStyle.fontFamily));
        expect(bodyMediumStyle.fontFamily, equals(bodySmallStyle.fontFamily));
        
        // Verify size hierarchy
        expect(bodyLargeStyle.fontSize!, greaterThan(bodyMediumStyle.fontSize!));
        expect(bodyMediumStyle.fontSize!, greaterThan(bodySmallStyle.fontSize!));
      });

      testWidgets('Caption and label text maintains consistency', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        final captionStyle = UIConsistency.caption(context);
        final labelStyle = UIConsistency.label(context);

        // Verify styles exist and are consistent
        expect(captionStyle.fontFamily, isNotNull);
        expect(labelStyle.fontFamily, isNotNull);
        expect(captionStyle.fontFamily, equals(labelStyle.fontFamily));
        
        // Caption should be smaller than label
        expect(captionStyle.fontSize!, lessThanOrEqualTo(labelStyle.fontSize!));
      });
    });

    /// Font Size Consistency Tests
    group('Font Size Consistency', () {
      testWidgets('Font sizes follow established hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        
        // Get all predefined text styles
        final headingLarge = UIConsistency.headingLarge(context);
        final headingMedium = UIConsistency.headingMedium(context);
        final headingSmall = UIConsistency.headingSmall(context);
        final bodyLarge = UIConsistency.bodyLarge(context);
        final bodyMedium = UIConsistency.bodyMedium(context);
        final bodySmall = UIConsistency.bodySmall(context);
        final caption = UIConsistency.caption(context);

        // Verify size hierarchy (largest to smallest)
        expect(headingLarge.fontSize!, greaterThan(headingMedium.fontSize!));
        expect(headingMedium.fontSize!, greaterThan(headingSmall.fontSize!));
        expect(headingSmall.fontSize!, greaterThan(bodyLarge.fontSize!));
        expect(bodyLarge.fontSize!, greaterThan(bodyMedium.fontSize!));
        expect(bodyMedium.fontSize!, greaterThan(bodySmall.fontSize!));
        expect(bodySmall.fontSize!, greaterThan(caption.fontSize!));

        // Verify reasonable size gaps (at least 2px difference)
        expect(headingLarge.fontSize! - headingMedium.fontSize!, greaterThanOrEqualTo(2));
        expect(headingMedium.fontSize! - headingSmall.fontSize!, greaterThanOrEqualTo(2));
      });

      testWidgets('No arbitrary font sizes used', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        final allowedSizes = {
          UIConsistency.headingLarge(context).fontSize!,
          UIConsistency.headingMedium(context).fontSize!,
          UIConsistency.headingSmall(context).fontSize!,
          UIConsistency.bodyLarge(context).fontSize!,
          UIConsistency.bodyMedium(context).fontSize!,
          UIConsistency.bodySmall(context).fontSize!,
          UIConsistency.caption(context).fontSize!,
          UIConsistency.label(context).fontSize!,
          14.0, // Default Flutter text size
        };

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        
        for (final textWidget in textWidgets) {
          final fontSize = textWidget.style?.fontSize ?? 14.0;
          expect(allowedSizes, contains(fontSize),
                 reason: 'Font size $fontSize not in allowed sizes. Text: "${textWidget.data}"');
        }
      });
    });

    /// Color Consistency Tests
    group('Text Color Consistency', () {
      testWidgets('Text colors use theme-defined colors', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        final theme = Theme.of(context);
        
        final allowedColors = {
          theme.colorScheme.onSurface,
          theme.colorScheme.onSurfaceVariant,
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
          theme.colorScheme.error,
          theme.colorScheme.onPrimary,
          theme.colorScheme.onSecondary,
          Colors.white,
          Colors.black,
          null, // Default text color
        };

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        
        for (final textWidget in textWidgets) {
          final textColor = textWidget.style?.color;
          expect(allowedColors, contains(textColor),
                 reason: 'Text color $textColor not in theme colors. Text: "${textWidget.data}"');
        }
      });

      testWidgets('Sufficient color contrast for readability', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MyApp));
        final theme = Theme.of(context);
        
        // Test contrast between text and background colors
        final contrastPairs = [
          [theme.colorScheme.onSurface, theme.colorScheme.surface],
          [theme.colorScheme.onPrimary, theme.colorScheme.primary],
          [theme.colorScheme.onSecondary, theme.colorScheme.secondary],
        ];

        for (final pair in contrastPairs) {
          final contrast = _calculateContrast(pair[0], pair[1]);
          expect(contrast, greaterThan(4.5),
                 reason: 'Contrast ratio ${contrast.toStringAsFixed(2)} between ${pair[0]} and ${pair[1]} should be at least 4.5:1 for WCAG AA');
        }
      });
    });

    /// Screen-Specific Text Consistency Tests
    group('Cross-Screen Text Consistency', () {
      testWidgets('Home screen text consistency', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        await _testScreenTextConsistency(tester, 'Home');
      });

      testWidgets('History screen text consistency', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to History
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        await _testScreenTextConsistency(tester, 'History');
      });

      testWidgets('Settings screen text consistency', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to Settings
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        await _testScreenTextConsistency(tester, 'Settings');
      });
    });

    /// Button Text Consistency Tests
    group('Button Text Consistency', () {
      testWidgets('All buttons use consistent text styles', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final buttonWidgets = [
          ...tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)),
          ...tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)),
          ...tester.widgetList<TextButton>(find.byType(TextButton)),
        ];

        final buttonTextStyles = <TextStyle>[];

        for (final button in buttonWidgets) {
          Widget? child;
          if (button is ElevatedButton) child = button.child;
          if (button is OutlinedButton) child = button.child;
          if (button is TextButton) child = button.child;

          if (child is Text && child.style != null) {
            buttonTextStyles.add(child.style!);
          }
        }

        // Check button text consistency
        if (buttonTextStyles.isNotEmpty) {
          final expectedFontWeight = buttonTextStyles.first.fontWeight;
          for (final style in buttonTextStyles) {
            expect(style.fontWeight, equals(expectedFontWeight),
                   reason: 'All button text should have consistent font weight');
          }
        }
      });
    });

    /// Accessibility Text Tests
    group('Accessibility Text Requirements', () {
      testWidgets('Text scales properly with system font size', (WidgetTester tester) async {
        // Test with different text scale factors
        for (final scaleFactor in [0.8, 1.0, 1.2, 1.5, 2.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaleFactor: scaleFactor),
              child: testApp,
            ),
          );
          await tester.pumpAndSettle();

          // Verify text is still readable and doesn't overflow
          final textWidgets = tester.widgetList<Text>(find.byType(Text));
          for (final textWidget in textWidgets) {
            final renderObject = tester.renderObject<RenderParagraph>(
              find.byWidget(textWidget),
            );
            
            expect(renderObject.hasVisualOverflow, isFalse,
                   reason: 'Text should not overflow at scale factor $scaleFactor: "${textWidget.data}"');
          }
        }
      });

      testWidgets('Text has sufficient minimum size', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        
        for (final textWidget in textWidgets) {
          final fontSize = textWidget.style?.fontSize ?? 14.0;
          expect(fontSize, greaterThanOrEqualTo(12.0),
                 reason: 'Text size should be at least 12px for accessibility: "${textWidget.data}"');
        }
      });
    });
  });
}

/// Helper function to test text consistency within a screen
Future<void> _testScreenTextConsistency(WidgetTester tester, String screenName) async {
  final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
  final usedStyles = <String, TextStyle>{};

  for (final textWidget in textWidgets) {
    if (textWidget.style != null) {
      final styleKey = '${textWidget.style!.fontSize}_${textWidget.style!.fontWeight}_${textWidget.style!.fontFamily}';
      usedStyles[styleKey] = textWidget.style!;
    }
  }

  // Verify limited number of text styles (good design practice)
  expect(usedStyles.length, lessThanOrEqualTo(8),
         reason: '$screenName screen should use no more than 8 distinct text styles');

  // Verify all styles use consistent font family
  final fontFamilies = usedStyles.values.map((s) => s.fontFamily).toSet();
  expect(fontFamilies.length, lessThanOrEqualTo(2),
         reason: '$screenName screen should use at most 2 font families');
}

/// Calculate contrast ratio between two colors
double _calculateContrast(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  
  return (lighter + 0.05) / (darker + 0.05);
} 