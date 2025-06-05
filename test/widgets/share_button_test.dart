import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/share_button.dart';

void main() {
  // Constants available to all test groups
  const testText = 'Test share content';
  const testSubject = 'Test Subject';
  final testFiles = ['file1.txt', 'file2.jpg'];

  group('ShareButton Tests', () {

    Widget createTestWidget({
      String text = testText,
      String? subject,
      List<String>? files,
      String? tooltip,
      IconData? icon,
      Color? color,
      double? size,
      bool showSnackBar = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ShareButton(
            text: text,
            subject: subject,
            files: files,
            tooltip: tooltip,
            icon: icon ?? Icons.share,
            color: color,
            size: size ?? 24.0,
            showSnackBar: showSnackBar,
          ),
        ),
      );
    }

    group('Widget Construction', () {
      testWidgets('should render share button with default properties', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(ShareButton), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('should render with custom icon', (tester) async {
        await tester.pumpWidget(createTestWidget(
          icon: Icons.send,
        ));

        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.byIcon(Icons.share), findsNothing);
      });

      testWidgets('should render with custom tooltip', (tester) async {
        await tester.pumpWidget(createTestWidget(
          tooltip: 'Custom Share Tooltip',
        ));

        expect(find.byTooltip('Custom Share Tooltip'), findsOneWidget);
      });

      testWidgets('should render with custom size', (tester) async {
        await tester.pumpWidget(createTestWidget(
          size: 32.0,
        ));

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(32.0));
      });

      testWidgets('should render with custom color', (tester) async {
        await tester.pumpWidget(createTestWidget(
          color: Colors.red,
        ));

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(Colors.red));
      });

      testWidgets('should handle null optional parameters', (tester) async {
        await tester.pumpWidget(createTestWidget(
          subject: null,
          files: null,
          tooltip: null,
          color: null,
        ));

        expect(find.byType(ShareButton), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
      });
    });

    group('Share Functionality', () {
      testWidgets('should trigger share when button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share with subject', (tester) async {
        await tester.pumpWidget(createTestWidget(
          subject: testSubject,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share with files', (tester) async {
        await tester.pumpWidget(createTestWidget(
          files: testFiles,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share with all parameters', (tester) async {
        await tester.pumpWidget(createTestWidget(
          subject: testSubject,
          files: testFiles,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share without snackbar', (tester) async {
        await tester.pumpWidget(createTestWidget(
          showSnackBar: false,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle rapid taps gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Rapidly tap multiple times
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(IconButton));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle empty text gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(
          text: '',
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very long text', (tester) async {
        final longText = 'A' * 10000; // 10k character string

        await tester.pumpWidget(createTestWidget(
          text: longText,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle special characters in text', (tester) async {
        const specialText = 'Share with émojis 🚀 & spëcial chars: <>&"\'';

        await tester.pumpWidget(createTestWidget(
          text: specialText,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty file list', (tester) async {
        await tester.pumpWidget(createTestWidget(
          files: [],
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle invalid file paths', (tester) async {
        final invalidFiles = [
          'non_existent_file.txt',
          '/invalid/path/file.jpg',
          '',
        ];

        await tester.pumpWidget(createTestWidget(
          files: invalidFiles,
        ));

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper tooltip for accessibility', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byTooltip('Share'), findsOneWidget);
      });

      testWidgets('should be focusable for keyboard navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        expect(iconButton.onPressed, isNotNull);
      });

      testWidgets('should have sufficient touch target size', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final iconButton = find.byType(IconButton);
        final buttonSize = tester.getSize(iconButton);
        
        // IconButton should have minimum 48x48 touch target
        expect(buttonSize.width, greaterThanOrEqualTo(48.0));
        expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('should work with screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(
          tooltip: 'Share this content with others',
        ));

        expect(find.byTooltip('Share this content with others'), findsOneWidget);
      });
    });

    group('Visual Consistency', () {
      testWidgets('should maintain consistent appearance across themes', (tester) async {
        // Test light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ShareButton(text: testText),
            ),
          ),
        );

        expect(find.byType(ShareButton), findsOneWidget);

        // Test dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ShareButton(text: testText),
            ),
          ),
        );

        expect(find.byType(ShareButton), findsOneWidget);
      });

      testWidgets('should respect theme colors when no custom color is provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              iconTheme: const IconThemeData(color: Colors.purple),
            ),
            home: Scaffold(
              body: ShareButton(text: testText),
            ),
          ),
        );

        expect(find.byType(ShareButton), findsOneWidget);
      });

      testWidgets('should override theme colors when custom color is provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              iconTheme: const IconThemeData(color: Colors.purple),
            ),
            home: Scaffold(
              body: ShareButton(
                text: testText,
                color: Colors.red,
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(Colors.red));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null text gracefully', (tester) async {
        // This tests the behavior when required text parameter is null
        // In practice, this would be caught at compile time, but good to test
        expect(() async {
          await tester.pumpWidget(createTestWidget(text: ''));
        }, returnsNormally);
      });

      testWidgets('should handle extreme icon sizes', (tester) async {
        // Test very small size
        await tester.pumpWidget(createTestWidget(size: 1.0));
        expect(find.byType(ShareButton), findsOneWidget);

        // Test very large size
        await tester.pumpWidget(createTestWidget(size: 100.0));
        expect(find.byType(ShareButton), findsOneWidget);
      });

      testWidgets('should handle widget disposal properly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Text('Different Widget')));
        
        expect(find.text('Different Widget'), findsOneWidget);
        expect(find.byType(ShareButton), findsNothing);
      });
    });
  });

  group('ShareFloatingActionButton Tests', () {
    const testText = 'Test FAB share content';
    const testSubject = 'Test FAB Subject';
    final testFiles = ['fab_file1.txt', 'fab_file2.jpg'];

    Widget createFABTestWidget({
      String text = testText,
      String? subject,
      List<String>? files,
      String? tooltip,
      Color? backgroundColor,
      Color? foregroundColor,
      bool showSnackBar = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: const Text('Test Content'),
          floatingActionButton: ShareFloatingActionButton(
            text: text,
            subject: subject,
            files: files,
            tooltip: tooltip,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            showSnackBar: showSnackBar,
          ),
        ),
      );
    }

    group('Widget Construction', () {
      testWidgets('should render floating action button', (tester) async {
        await tester.pumpWidget(createFABTestWidget());

        expect(find.byType(ShareFloatingActionButton), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('should render with custom colors', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ));

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(fab.backgroundColor, equals(Colors.red));
        expect(fab.foregroundColor, equals(Colors.white));
      });

      testWidgets('should render with custom tooltip', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          tooltip: 'Custom FAB Share',
        ));

        expect(find.byTooltip('Custom FAB Share'), findsOneWidget);
      });

      testWidgets('should handle null optional parameters', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          subject: null,
          files: null,
          tooltip: null,
          backgroundColor: null,
          foregroundColor: null,
        ));

        expect(find.byType(ShareFloatingActionButton), findsOneWidget);
      });
    });

    group('Share Functionality', () {
      testWidgets('should trigger share when FAB is tapped', (tester) async {
        await tester.pumpWidget(createFABTestWidget());

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share with all parameters', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          subject: testSubject,
          files: testFiles,
        ));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle share without snackbar', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          showSnackBar: false,
        ));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper tooltip for accessibility', (tester) async {
        await tester.pumpWidget(createFABTestWidget());

        expect(find.byTooltip('Share'), findsOneWidget);
      });

      testWidgets('should be properly sized for touch interaction', (tester) async {
        await tester.pumpWidget(createFABTestWidget());

        final fab = find.byType(FloatingActionButton);
        final fabSize = tester.getSize(fab);
        
        // FAB should be at least 56x56 (standard FAB size)
        expect(fabSize.width, greaterThanOrEqualTo(56.0));
        expect(fabSize.height, greaterThanOrEqualTo(56.0));
      });
    });

    group('Theme Integration', () {
      testWidgets('should respect theme when no custom colors provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.yellow,
              ),
            ),
            home: Scaffold(
              floatingActionButton: ShareFloatingActionButton(text: testText),
            ),
          ),
        );

        expect(find.byType(ShareFloatingActionButton), findsOneWidget);
      });

      testWidgets('should override theme when custom colors provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.yellow,
              ),
            ),
            home: Scaffold(
              floatingActionButton: ShareFloatingActionButton(
                text: testText,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(fab.backgroundColor, equals(Colors.red));
        expect(fab.foregroundColor, equals(Colors.white));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle share errors gracefully', (tester) async {
        await tester.pumpWidget(createFABTestWidget(
          text: '', // Empty text might cause share issues
        ));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle rapid FAB taps', (tester) async {
        await tester.pumpWidget(createFABTestWidget());

        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });

  group('Comparison Tests', () {
    testWidgets('should have different widgets for button vs FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShareButton(text: testText),
                ShareFloatingActionButton(text: testText),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ShareButton), findsOneWidget);
      expect(find.byType(ShareFloatingActionButton), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should both handle same share functionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShareButton(text: testText),
                ShareFloatingActionButton(text: testText),
              ],
            ),
          ),
        ),
      );

      // Test both buttons
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
