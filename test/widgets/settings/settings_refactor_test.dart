import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';
import 'package:waste_segregation_app/widgets/settings/premium_section.dart';
import 'package:waste_segregation_app/widgets/settings/app_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/legal_support_section.dart';

void main() {
  group('Settings Refactor Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    testWidgets('SettingTile renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingTile(
            icon: Icons.settings,
            title: 'Test Setting',
            subtitle: 'Test subtitle',
          ),
        ),
      );

      expect(find.text('Test Setting'), findsOneWidget);
      expect(find.text('Test subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('SettingToggleTile renders correctly', (WidgetTester tester) async {
      bool testValue = false;
      
      await tester.pumpWidget(
        createTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return SettingToggleTile(
                icon: Icons.toggle_on,
                title: 'Test Toggle',
                subtitle: 'Test toggle subtitle',
                value: testValue,
                onChanged: (value) {
                  setState(() {
                    testValue = value;
                  });
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Test Toggle'), findsOneWidget);
      expect(find.text('Test toggle subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.toggle_on), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSectionHeader(title: 'Test Section'),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('SettingsSectionSpacer renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSectionSpacer(),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('PremiumSection renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PremiumSection(),
        ),
      );

      // Section header is now handled by parent, so we only check for the content
      expect(find.text('Premium Features'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('AppSettingsSection renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppSettingsSection(),
        ),
      );

      // Section header is now handled by parent, so we only check for the content
      expect(find.text('Theme Settings'), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Data Export'), findsOneWidget);
    });

    testWidgets('LegalSupportSection renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const LegalSupportSection(),
        ),
      );

      expect(find.text('Legal & Support'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('SettingsTheme helper methods work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test that theme methods don't throw
              final headingStyle = SettingsTheme.sectionHeadingStyle(context);
              final tileTitle = SettingsTheme.tileTitle(context);
              final tileSubtitle = SettingsTheme.tileSubtitle(context);
              
              expect(headingStyle, isA<TextStyle>());
              expect(tileTitle, isA<TextStyle>());
              expect(tileSubtitle, isA<TextStyle>());
              
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
} 