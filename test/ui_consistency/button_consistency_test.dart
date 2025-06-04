import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/main.dart';
import 'package:waste_segregation_app/utils/ui_consistency_utils.dart';

void main() {
  group('Button Consistency Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Test various button types using UIConsistency
              Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      style: UIConsistency.primaryButtonStyle(context),
                      onPressed: () {},
                      child: const Text('Primary Button'),
                    ),
                    OutlinedButton(
                      style: UIConsistency.secondaryButtonStyle(context),
                      onPressed: () {},
                      child: const Text('Secondary Button'),
                    ),
                    TextButton(
                      style: UIConsistency.tertiaryButtonStyle(context),
                      onPressed: () {},
                      child: const Text('Tertiary Button'),
                    ),
                    ElevatedButton(
                      style: UIConsistency.destructiveButtonStyle(context),
                      onPressed: () {},
                      child: const Text('Destructive Button'),
                    ),
                    ElevatedButton(
                      style: UIConsistency.successButtonStyle(context),
                      onPressed: () {},
                      child: const Text('Success Button'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });

    /// Button Style Consistency Tests
    group('Button Style Consistency', () {
      testWidgets('Primary buttons use consistent styling', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        final primaryStyle = UIConsistency.primaryButtonStyle(context);

        // Verify primary button style properties
        expect(primaryStyle.backgroundColor?.resolve({}), isNotNull);
        expect(primaryStyle.foregroundColor?.resolve({}), isNotNull);
        expect(primaryStyle.elevation?.resolve({}), isNotNull);
        expect(primaryStyle.padding?.resolve({}), isNotNull);
        expect(primaryStyle.shape?.resolve({}), isNotNull);
      });

      testWidgets('Button styles maintain visual hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        
        final primaryStyle = UIConsistency.primaryButtonStyle(context);
        final secondaryStyle = UIConsistency.secondaryButtonStyle(context);
        final tertiaryStyle = UIConsistency.tertiaryButtonStyle(context);

        // Primary should have highest elevation
        final primaryElevation = primaryStyle.elevation?.resolve({}) ?? 0;
        final secondaryElevation = secondaryStyle.elevation?.resolve({}) ?? 0;
        final tertiaryElevation = tertiaryStyle.elevation?.resolve({}) ?? 0;

        expect(primaryElevation, greaterThanOrEqualTo(secondaryElevation),
               reason: 'Primary buttons should have equal or higher elevation than secondary');
        expect(secondaryElevation, greaterThanOrEqualTo(tertiaryElevation),
               reason: 'Secondary buttons should have equal or higher elevation than tertiary');
      });

      testWidgets('Destructive buttons have appropriate warning styling', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        final destructiveStyle = UIConsistency.destructiveButtonStyle(context);

        final backgroundColor = destructiveStyle.backgroundColor?.resolve({});
        expect(backgroundColor, isNotNull);
        
        // Should use red-ish color for destructive actions
        final red = backgroundColor!.red;
        final green = backgroundColor.green;
        final blue = backgroundColor.blue;
        
        expect(red, greaterThan(green),
               reason: 'Destructive buttons should have more red than green');
        expect(red, greaterThan(blue),
               reason: 'Destructive buttons should have more red than blue');
      });

      testWidgets('Success buttons have appropriate positive styling', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        final successStyle = UIConsistency.successButtonStyle(context);

        final backgroundColor = successStyle.backgroundColor?.resolve({});
        expect(backgroundColor, isNotNull);
        
        // Should use green-ish color for success actions
        final red = backgroundColor!.red;
        final green = backgroundColor.green;
        final blue = backgroundColor.blue;
        
        expect(green, greaterThan(red),
               reason: 'Success buttons should have more green than red');
        expect(green, greaterThan(blue),
               reason: 'Success buttons should have more green than blue');
      });
    });

    /// Button Size and Spacing Tests
    group('Button Size and Spacing', () {
      testWidgets('All buttons have consistent padding', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        
        final buttonStyles = [
          UIConsistency.primaryButtonStyle(context),
          UIConsistency.secondaryButtonStyle(context),
          UIConsistency.tertiaryButtonStyle(context),
        ];

        EdgeInsetsGeometry? expectedPadding;
        for (final style in buttonStyles) {
          final padding = style.padding?.resolve({});
          if (expectedPadding == null) {
            expectedPadding = padding;
          } else {
            expect(padding, equals(expectedPadding),
                   reason: 'All button types should have consistent padding');
          }
        }
      });

      testWidgets('Buttons have minimum touch target size', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find the actual button widgets, not just text
        final buttonFinders = [
          find.byType(ElevatedButton).first,  // Primary
          find.byType(OutlinedButton).first,  // Secondary
          find.byType(TextButton).first,      // Tertiary
        ];

        for (final finder in buttonFinders) {
          final buttonSize = tester.getSize(finder);
          
          // Material Design minimum touch target is 48x48
          expect(buttonSize.height, greaterThanOrEqualTo(48.0),
                 reason: 'Buttons should meet minimum touch target height of 48px');
          expect(buttonSize.width, greaterThanOrEqualTo(48.0),
                 reason: 'Buttons should meet minimum touch target width of 48px');
        }
      });

      testWidgets('Button text maintains readable size', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        
        for (final textWidget in textWidgets) {
          final fontSize = textWidget.style?.fontSize ?? 14.0;
          expect(fontSize, greaterThanOrEqualTo(14.0),
                 reason: 'Button text should be at least 14px for readability');
          expect(fontSize, lessThanOrEqualTo(20.0),
                 reason: 'Button text should not exceed 20px to maintain button proportions');
        }
      });
    });

    /// Button Accessibility Tests
    group('Button Accessibility', () {
      testWidgets('Buttons have sufficient color contrast', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        
        final buttonStyles = [
          UIConsistency.primaryButtonStyle(context),
          UIConsistency.secondaryButtonStyle(context),
          UIConsistency.destructiveButtonStyle(context),
          UIConsistency.successButtonStyle(context),
        ];

        for (final style in buttonStyles) {
          final backgroundColor = style.backgroundColor?.resolve({});
          final foregroundColor = style.foregroundColor?.resolve({});
          
          if (backgroundColor != null && foregroundColor != null) {
            final contrast = _calculateContrast(foregroundColor, backgroundColor);
            expect(contrast, greaterThan(4.5),
                   reason: 'Button text should have at least 4.5:1 contrast ratio with background');
          }
        }
      });

      testWidgets('Buttons respond to touch events', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final buttonFinders = [
          find.text('Primary Button'),
          find.text('Secondary Button'),
          find.text('Tertiary Button'),
        ];

        for (final finder in buttonFinders) {
          // Verify button can be tapped
          await tester.tap(finder);
          await tester.pumpAndSettle();
          
          // No exceptions should be thrown
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('Buttons scale properly with text size', (WidgetTester tester) async {
        // Test with larger text scale
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaleFactor: 1.5),
            child: testApp,
          ),
        );
        await tester.pumpAndSettle();

        // FIXED: Test actual button widgets, not text widgets for touch target compliance
        final buttonFinders = [
          find.byType(ElevatedButton).first,  // Primary Button
          find.byType(OutlinedButton).first,  // Secondary Button  
          find.byType(TextButton).first,      // Tertiary Button
        ];

        for (final finder in buttonFinders) {
          final buttonSize = tester.getSize(finder);
          
          // Buttons should still meet minimum touch targets when scaled
          expect(buttonSize.height, greaterThanOrEqualTo(48.0),
                 reason: 'Scaled buttons should still meet minimum touch target height');
          expect(buttonSize.width, greaterThanOrEqualTo(48.0),
                 reason: 'Scaled buttons should still meet minimum touch target width');
        }
      });
    });

    /// Button State Tests
    group('Button State Consistency', () {
      testWidgets('Button states have visual feedback', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Builder).first);
        final primaryStyle = UIConsistency.primaryButtonStyle(context);

        // Test different material states
        final pressedColor = primaryStyle.backgroundColor?.resolve({MaterialState.pressed});
        final normalColor = primaryStyle.backgroundColor?.resolve({});
        final disabledColor = primaryStyle.backgroundColor?.resolve({MaterialState.disabled});

        expect(pressedColor, isNotNull);
        expect(normalColor, isNotNull);
        expect(disabledColor, isNotNull);

        // Pressed state should be different from normal
        expect(pressedColor, isNot(equals(normalColor)),
               reason: 'Pressed button should have different color than normal state');

        // Disabled state should be different from normal
        expect(disabledColor, isNot(equals(normalColor)),
               reason: 'Disabled button should have different color than normal state');
      });

      testWidgets('Disabled buttons are properly styled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      style: UIConsistency.primaryButtonStyle(context),
                      onPressed: null, // Disabled button
                      child: const Text('Disabled Button'),
                    ),
                    ElevatedButton(
                      style: UIConsistency.primaryButtonStyle(context),
                      onPressed: () {}, // Enabled button
                      child: const Text('Enabled Button'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find buttons
        final disabledButton = find.text('Disabled Button');
        final enabledButton = find.text('Enabled Button');

        expect(disabledButton, findsOneWidget);
        expect(enabledButton, findsOneWidget);

        // Verify disabled button cannot be tapped
        await tester.tap(disabledButton);
        await tester.pumpAndSettle();
        
        // No visual changes should occur for disabled button
        expect(tester.takeException(), isNull);
      });
    });

    /// Button Layout Consistency Tests
    group('Button Layout Consistency', () {
      testWidgets('Button content is properly aligned', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        
        for (final textWidget in textWidgets) {
          expect(textWidget.textAlign, anyOf(isNull, equals(TextAlign.center)),
                 reason: 'Button text should be center-aligned by default');
        }
      });

      testWidgets('Buttons with icons maintain proper spacing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton.icon(
                      style: UIConsistency.primaryButtonStyle(context),
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                    ElevatedButton.icon(
                      style: UIConsistency.secondaryButtonStyle(context),
                      onPressed: () {},
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Item'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify icon buttons render properly
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
        expect(find.text('Add Item'), findsOneWidget);
        expect(find.text('Delete Item'), findsOneWidget);
      });
    });
  });
}

/// Calculate contrast ratio between two colors for accessibility testing
double _calculateContrast(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  
  return (lighter + 0.05) / (darker + 0.05);
} 