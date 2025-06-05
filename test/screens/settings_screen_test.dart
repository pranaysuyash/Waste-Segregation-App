import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/settings_screen.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';
import 'package:waste_segregation_app/services/user_consent_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

@GenerateMocks([ThemeProvider, UserConsentService, StorageService])
import 'settings_screen_test.mocks.dart';

void main() {
  group('SettingsScreen Tests', () {
    late MockThemeProvider mockThemeProvider;
    late MockUserConsentService mockConsentService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockThemeProvider = MockThemeProvider();
      mockConsentService = MockUserConsentService();
      mockStorageService = MockStorageService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            Provider<UserConsentService>.value(value: mockConsentService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: const SettingsScreen(),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render settings screen with all sections', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.hasMarketingConsent).thenReturn(false);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Data & Storage'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('should show current theme selection', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.dark);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.hasMarketingConsent).thenReturn(false);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
      });

      testWidgets('should display privacy consent toggles', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.hasMarketingConsent).thenReturn(false);
        when(mockConsentService.hasFunctionalConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Analytics'), findsOneWidget);
        expect(find.text('Marketing'), findsOneWidget);
        expect(find.text('Functional'), findsOneWidget);

        // Check switch states
        final analyticsSwitches = find.byType(Switch);
        expect(analyticsSwitches, findsWidgets);
      });

      testWidgets('should show storage usage information', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.getStorageUsage()).thenAnswer((_) async => {
          'totalSize': 1024000,
          'classificationsSize': 512000,
          'cacheSize': 256000,
          'imagesSize': 256000,
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Storage Usage'), findsOneWidget);
        expect(find.text('1.0 MB'), findsOneWidget); // Total size
        expect(find.text('Clear Cache'), findsOneWidget);
      });
    });

    group('Theme Settings', () {
      testWidgets('should change theme when theme option is selected', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        // Tap on theme setting
        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(find.text('Choose Theme'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('System'), findsOneWidget);

        // Select dark theme
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        verify(mockThemeProvider.setThemeMode(ThemeMode.dark)).called(1);
      });

      testWidgets('should show current theme as selected', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.system);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        // System should be selected (checked)
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should update theme display after change', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Light'), findsOneWidget);

        // Simulate theme change
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.dark);

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        // Should update display
        expect(find.text('Dark'), findsOneWidget);
      });
    });

    group('Privacy Settings', () {
      testWidgets('should toggle analytics consent', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(false);
        when(mockConsentService.hasMarketingConsent).thenReturn(false);
        when(mockConsentService.setAnalyticsConsent(true))
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());

        // Find and tap analytics toggle
        final analyticsSwitch = find.widgetWithText(SwitchListTile, 'Analytics').first;
        await tester.tap(analyticsSwitch);
        await tester.pumpAndSettle();

        verify(mockConsentService.setAnalyticsConsent(true)).called(1);
      });

      testWidgets('should toggle marketing consent', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.hasMarketingConsent).thenReturn(true);
        when(mockConsentService.setMarketingConsent(false))
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());

        // Find and tap marketing toggle
        final marketingSwitch = find.widgetWithText(SwitchListTile, 'Marketing').first;
        await tester.tap(marketingSwitch);
        await tester.pumpAndSettle();

        verify(mockConsentService.setMarketingConsent(false)).called(1);
      });

      testWidgets('should show privacy policy link', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Privacy Policy'), findsOneWidget);

        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        // Should navigate to privacy policy
        expect(find.text('Privacy Policy'), findsWidgets);
      });

      testWidgets('should handle consent service errors gracefully', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(false);
        when(mockConsentService.setAnalyticsConsent(true))
            .thenThrow(Exception('Failed to update consent'));

        await tester.pumpWidget(createTestWidget());

        final analyticsSwitch = find.widgetWithText(SwitchListTile, 'Analytics').first;
        await tester.tap(analyticsSwitch);
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Failed to update privacy settings'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('Notification Settings', () {
      testWidgets('should toggle notification preferences', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Push Notifications'), findsOneWidget);
        expect(find.text('Email Updates'), findsOneWidget);
        expect(find.text('Classification Reminders'), findsOneWidget);

        // Test notification toggles
        final pushNotificationSwitch = find.widgetWithText(SwitchListTile, 'Push Notifications').first;
        await tester.tap(pushNotificationSwitch);
        await tester.pumpAndSettle();

        // Should update notification preferences
        expect(find.byType(Switch), findsWidgets);
      });

      testWidgets('should configure notification times', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Notification Schedule'));
        await tester.pumpAndSettle();

        expect(find.text('Reminder Times'), findsOneWidget);
        expect(find.text('Daily at 9:00 AM'), findsOneWidget);
        expect(find.text('Add Time'), findsOneWidget);
      });
    });

    group('Data & Storage Settings', () {
      testWidgets('should clear cache successfully', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.getStorageUsage()).thenAnswer((_) async => {
          'totalSize': 1024000,
          'cacheSize': 256000,
        });
        when(mockStorageService.clearCache()).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Cache'));
        await tester.pumpAndSettle();

        expect(find.text('Clear Cache?'), findsOneWidget);
        expect(find.text('This will clear 256 KB of cached data.'), findsOneWidget);

        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        verify(mockStorageService.clearCache()).called(1);
        expect(find.text('Cache cleared successfully'), findsOneWidget);
      });

      testWidgets('should export data', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.exportAllData()).thenAnswer((_) async => 'exported_data.json');

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Export Data'));
        await tester.pumpAndSettle();

        expect(find.text('Export All Data?'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);

        await tester.tap(find.text('Export'));
        await tester.pumpAndSettle();

        verify(mockStorageService.exportAllData()).called(1);
        expect(find.text('Data exported successfully'), findsOneWidget);
      });

      testWidgets('should delete all data with confirmation', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.deleteAllData()).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Delete All Data'));
        await tester.pumpAndSettle();

        expect(find.text('Delete All Data?'), findsOneWidget);
        expect(find.text('This action cannot be undone.'), findsOneWidget);
        expect(find.text('DELETE'), findsOneWidget);

        await tester.tap(find.text('DELETE'));
        await tester.pumpAndSettle();

        verify(mockStorageService.deleteAllData()).called(1);
      });

      testWidgets('should handle storage operations errors', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.clearCache()).thenThrow(Exception('Storage error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Cache'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to clear cache'), findsOneWidget);
      });
    });

    group('About Section', () {
      testWidgets('should show app information', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Version'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Licenses'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);
      });

      testWidgets('should show app version', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('1.'), findsOneWidget); // Version number
      });

      testWidgets('should open support contact', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Contact Support'));
        await tester.pumpAndSettle();

        expect(find.text('Contact Support'), findsWidgets);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Report Bug'), findsOneWidget);
        expect(find.text('Feature Request'), findsOneWidget);
      });

      testWidgets('should show open source licenses', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Licenses'));
        await tester.pumpAndSettle();

        expect(find.text('Open Source Licenses'), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should search settings options', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        // Find search icon
        expect(find.byIcon(Icons.search), findsOneWidget);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'theme');
        await tester.pumpAndSettle();

        // Should show theme-related settings
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Privacy'), findsNothing); // Should be filtered out
      });

      testWidgets('should clear search results', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'theme');
        await tester.pumpAndSettle();

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Should show all settings again
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should support screen reader navigation', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        // Check semantic labels
        expect(
          tester.getSemantics(find.text('Theme')),
          matchesSemantics(
            label: contains('Theme'),
            isButton: true,
          ),
        );

        expect(
          tester.getSemantics(find.widgetWithText(SwitchListTile, 'Analytics').first),
          matchesSemantics(
            hasToggleAction: true,
          ),
        );
      });

      testWidgets('should provide proper switch descriptions', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.hasMarketingConsent).thenReturn(false);

        await tester.pumpWidget(createTestWidget());

        // Check that switches have proper descriptions
        expect(find.text('Allow analytics data collection'), findsOneWidget);
        expect(find.text('Receive marketing communications'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(WidgetsBinding.instance.focusManager.primaryFocus, isNotNull);

        // Test enter key activation
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      });
    });

    group('Error Handling', () {
      testWidgets('should handle theme provider errors', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockThemeProvider.setThemeMode(any))
            .thenThrow(Exception('Theme change failed'));
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to change theme'), findsOneWidget);
      });

      testWidgets('should handle storage service unavailable', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockStorageService.getStorageUsage())
            .thenThrow(Exception('Storage unavailable'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Storage information unavailable'), findsOneWidget);
      });

      testWidgets('should recover from network errors', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);
        when(mockConsentService.setAnalyticsConsent(any))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());

        final analyticsSwitch = find.widgetWithText(SwitchListTile, 'Analytics').first;
        await tester.tap(analyticsSwitch);
        await tester.pumpAndSettle();

        expect(find.text('Network error. Please try again.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Mock successful retry
        when(mockConsentService.setAnalyticsConsent(any))
            .thenAnswer((_) async => null);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Settings updated successfully'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should load settings quickly', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(true);

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should handle multiple rapid toggles', (WidgetTester tester) async {
        when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
        when(mockConsentService.hasAnalyticsConsent).thenReturn(false);
        when(mockConsentService.setAnalyticsConsent(any))
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());

        final analyticsSwitch = find.widgetWithText(SwitchListTile, 'Analytics').first;

        // Rapidly toggle multiple times
        for (int i = 0; i < 5; i++) {
          await tester.tap(analyticsSwitch);
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should handle gracefully without errors
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });
  });
}
