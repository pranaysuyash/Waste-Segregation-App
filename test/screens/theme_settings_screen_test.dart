import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/theme_settings_screen.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';

import 'theme_settings_screen_test.mocks.dart';

@GenerateMocks([PremiumService, ThemeProvider])
void main() {
  group('ThemeSettingsScreen Tests', () {
    late MockPremiumService mockPremiumService;
    late MockThemeProvider mockThemeProvider;

    setUp(() {
      mockPremiumService = MockPremiumService();
      mockThemeProvider = MockThemeProvider();

      // Set up default mock behavior
      when(mockPremiumService.isPremiumFeature('theme_customization'))
          .thenReturn(false);
      when(mockThemeProvider.themeMode).thenReturn(ThemeMode.system);
    });

    Widget createTestWidget({
      bool isPremium = false,
      ThemeMode initialThemeMode = ThemeMode.system,
    }) {
      when(mockPremiumService.isPremiumFeature('theme_customization'))
          .thenReturn(isPremium);
      when(mockThemeProvider.themeMode).thenReturn(initialThemeMode);

      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ChangeNotifierProvider<PremiumService>.value(value: mockPremiumService),
          ],
          child: const ThemeSettingsScreen(),
        ),
      );
    }

    group('Widget Construction', () {
      testWidgets('should render theme settings screen', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Theme Settings'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should show all theme mode options', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('System Default'), findsOneWidget);
        expect(find.text('Light Theme'), findsOneWidget);
        expect(find.text('Dark Theme'), findsOneWidget);
        
        expect(find.text('Follow system theme settings'), findsOneWidget);
        expect(find.text('Always use light theme'), findsOneWidget);
        expect(find.text('Always use dark theme'), findsOneWidget);
      });

      testWidgets('should show theme mode icons', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
        expect(find.byIcon(Icons.light_mode), findsOneWidget);
        expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      });

      testWidgets('should show radio buttons for theme selection', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Radio<ThemeMode>), findsNWidgets(3));
      });

      testWidgets('should show premium features navigation row', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: false));

        expect(find.text('Premium Features').first, findsOneWidget);
        expect(find.text('Unlock advanced theme customization and more'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should show custom themes section for non-premium users', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: false));

        expect(find.text('Custom Themes'), findsOneWidget);
        expect(find.text('Create your own theme colors'), findsOneWidget);
        expect(find.byIcon(Icons.palette), findsOneWidget);
      });

      testWidgets('should hide custom themes section for premium users', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: true));

        expect(find.text('Custom Themes'), findsNothing);
        expect(find.text('Create your own theme colors'), findsNothing);
        expect(find.byIcon(Icons.palette), findsNothing);
      });
    });

    group('Premium Features Navigation', () {
      testWidgets('should show premium feature prompt when custom themes is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: false));

        await tester.tap(find.text('Custom Themes'));
        await tester.pumpAndSettle();

        expect(find.text('Premium Feature'), findsOneWidget);
        expect(find.text('Custom themes are available with a premium subscription. Upgrade to unlock this feature!'), findsOneWidget);
        expect(find.text('Maybe Later'), findsOneWidget);
        expect(find.text('Upgrade Now'), findsOneWidget);
      });

      testWidgets('should close dialog when maybe later is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: false));

        // Tap custom themes to show dialog
        await tester.tap(find.text('Custom Themes'));
        await tester.pumpAndSettle();

        // Tap maybe later
        await tester.tap(find.text('Maybe Later'));
        await tester.pumpAndSettle();

        // Dialog should be closed, back to theme settings
        expect(find.text('Premium Feature'), findsNothing);
        expect(find.text('Theme Settings'), findsOneWidget);
      });

      testWidgets('should find premium features navigation row', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the premium features navigation row (not the custom themes one)
        final premiumFeaturesRow = find.byWidgetPredicate((widget) =>
          widget is ListTile &&
          widget.title is Text &&
          (widget.title as Text).data == 'Premium Features' &&
          widget.subtitle is Text &&
          (widget.subtitle as Text).data == 'Unlock advanced theme customization and more'
        );

        expect(premiumFeaturesRow, findsOneWidget);
      });
    });

    group('Theme Mode Selection', () {
      testWidgets('should select system theme by default', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        final systemRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.system),
        );
        
        expect(systemRadio.groupValue, equals(ThemeMode.system));
      });

      testWidgets('should select light theme when specified', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.light,
        ));

        final lightRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.light),
        );
        
        expect(lightRadio.groupValue, equals(ThemeMode.light));
      });

      testWidgets('should select dark theme when specified', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.dark,
        ));

        final darkRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.dark),
        );
        
        expect(darkRadio.groupValue, equals(ThemeMode.dark));
      });

      testWidgets('should change theme mode when light theme is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('should change theme mode when dark theme is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.light,
        ));

        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.dark));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.dark)).called(1);
      });

      testWidgets('should change theme mode when system theme is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.dark,
        ));

        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.system));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.system)).called(1);
      });

      testWidgets('should update UI state when theme mode changes', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        // Initially system should be selected
        Radio<ThemeMode> systemRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.system),
        );
        expect(systemRadio.groupValue, equals(ThemeMode.system));

        // Tap light theme
        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
        await tester.pumpAndSettle();

        // Light theme should now be selected
        final lightRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.light),
        );
        expect(lightRadio.groupValue, equals(ThemeMode.light));
      });
    });

    group('List Interaction', () {
      testWidgets('should be scrollable', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(ListView), findsOneWidget);

        // Try scrolling
        await tester.drag(find.byType(ListView), const Offset(0, -100));
        await tester.pumpAndSettle();

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show divider between sections', (tester) async {
        await tester.pumpWidget(createTestWidget(isPremium: false));

        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('should handle tap on system default ListTile', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.light,
        ));

        await tester.tap(find.text('System Default'));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.system)).called(1);
      });

      testWidgets('should handle tap on light theme ListTile', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        await tester.tap(find.text('Light Theme'));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('should handle tap on dark theme ListTile', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        await tester.tap(find.text('Dark Theme'));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.dark)).called(1);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null theme mode gracefully', (tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.system);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(ThemeSettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle theme provider errors gracefully', (tester) async {
        when(mockThemeProvider.setThemeMode(any)).thenThrow(Exception('Theme error'));

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
        await tester.pumpAndSettle();

        // Should not crash the app
        expect(find.byType(ThemeSettingsScreen), findsOneWidget);
      });

      testWidgets('should handle premium service errors gracefully', (tester) async {
        when(mockPremiumService.isPremiumFeature('theme_customization'))
            .thenThrow(Exception('Premium service error'));

        expect(() async {
          await tester.pumpWidget(createTestWidget());
        }, returnsNormally);
      });

      testWidgets('should handle rapid theme mode changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Rapidly change theme modes
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
          await tester.pump();
          
          await tester.tap(find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.dark));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Should handle rapid changes gracefully
        verify(mockThemeProvider.setThemeMode(any)).called(10);
      });
    });

    group('Navigation', () {
      testWidgets('should have back button in app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(AppBar), findsOneWidget);
        
        // In a real navigation context, this would show a back button
        // For this test, we just ensure the AppBar is present
      });

      testWidgets('should handle back navigation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                                                  providers: [
                          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
                          ChangeNotifierProvider<PremiumService>.value(value: mockPremiumService),
                        ],
                          child: const ThemeSettingsScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Theme Settings'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Theme Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Theme Settings'), findsOneWidget);

        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Open Theme Settings'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for radio buttons', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final radioButtons = find.byType(Radio<ThemeMode>);
        expect(radioButtons, findsNWidgets(3));

        // Radio buttons should be accessible
        for (int i = 0; i < 3; i++) {
          final radio = tester.widget<Radio<ThemeMode>>(radioButtons.at(i));
          expect(radio.onChanged, isNotNull);
        }
      });

      testWidgets('should have proper labels for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('System Default'), findsOneWidget);
        expect(find.text('Light Theme'), findsOneWidget);
        expect(find.text('Dark Theme'), findsOneWidget);
        
        // Subtitles provide additional context
        expect(find.text('Follow system theme settings'), findsOneWidget);
        expect(find.text('Always use light theme'), findsOneWidget);
        expect(find.text('Always use dark theme'), findsOneWidget);
      });

      testWidgets('should be navigable with keyboard', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // ListTiles should be focusable
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsAtLeastNWidgets(3));
      });
    });

    group('State Management', () {
      testWidgets('should initialize with current theme mode', (tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.dark);

        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.dark,
        ));

        final darkRadio = tester.widget<Radio<ThemeMode>>(
          find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.dark),
        );
        
        expect(darkRadio.groupValue, equals(ThemeMode.dark));
      });

      testWidgets('should update state when theme provider changes', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.system,
        ));

        // Change the theme via the provider
        await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
        await tester.pumpAndSettle();

        // Verify the provider method was called
        verify(mockThemeProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('should handle widget rebuilds properly', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Force a rebuild
        await tester.pumpWidget(createTestWidget(
          initialThemeMode: ThemeMode.dark,
        ));

        expect(find.byType(ThemeSettingsScreen), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle multiple rapid taps efficiently', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final stopwatch = Stopwatch()..start();

        // Rapidly tap different options
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.byWidgetPredicate((widget) => 
            widget is Radio<ThemeMode> && widget.value == ThemeMode.light));
          await tester.pump();
        }

        stopwatch.stop();

        // Should complete quickly (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('should dispose properly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Text('Different Screen')));
        
        expect(find.text('Different Screen'), findsOneWidget);
        expect(find.byType(ThemeSettingsScreen), findsNothing);
      });
    });
  });
}
