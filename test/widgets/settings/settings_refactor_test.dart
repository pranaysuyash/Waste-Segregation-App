import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';
import 'package:waste_segregation_app/widgets/settings/premium_section.dart';
import 'package:waste_segregation_app/widgets/settings/app_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/legal_support_section.dart';
import '../../helpers/test_helper.dart';

class _FakeGoogleDriveService extends GoogleDriveService {
  _FakeGoogleDriveService() : super(MockStorageService());

  @override
  Future<bool> isSignedIn() async => false;
}

class _FakeHapticSettingsService extends HapticSettingsService {
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
  }
}

class _FakePremiumService extends ChangeNotifier implements PremiumService {
  final Map<String, bool> _features = <String, bool>{
    'theme_customization': true,
    'offline_mode': true,
    'export_data': true,
    'remove_ads': false,
  };

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  bool isPremiumFeature(String featureId) => _features[featureId] ?? false;

  @override
  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    _features[featureId] = isPremium;
    notifyListeners();
  }

  @override
  Future<void> toggleFeature(String featureId) async {
    await setPremiumFeature(featureId, !isPremiumFeature(featureId));
  }

  @override
  bool hasActivePremiumPlan() => _features.values.any((v) => v);

  @override
  PremiumTier getCurrentTier() =>
      hasActivePremiumPlan() ? PremiumTier.premium : PremiumTier.free;

  @override
  int getDailyScanLimit() {
    switch (getCurrentTier()) {
      case PremiumTier.free:
        return 10;
      case PremiumTier.premium:
        return 100;
      case PremiumTier.family:
        return 500;
    }
  }

  @override
  bool canPerformScan(int dailyScanCount) =>
      dailyScanCount < getDailyScanLimit();

  @override
  List<PremiumFeature> getPremiumFeatures() => const [];

  @override
  List<PremiumFeature> getComingSoonFeatures() => const [];

  @override
  Future<void> resetPremiumFeatures() async {
    _features.clear();
    notifyListeners();
  }

  @override
  Future<void> setPremiumPlanEntitlement(bool isPremium) async {
    _features[PremiumService.proSubscriptionEntitlement] = isPremium;
    _features[PremiumService.legacyPremiumSignal] = isPremium;
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settings Refactor Tests', () {
    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          Provider<GoogleDriveService>(
              create: (_) => _FakeGoogleDriveService()),
          ChangeNotifierProvider<HapticSettingsService>(
              create: (_) => _FakeHapticSettingsService()),
          ChangeNotifierProvider<PremiumService>(
              create: (_) => _FakePremiumService()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
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

    testWidgets('SettingTile exposes semantic locked state when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingTile(
            icon: Icons.lock,
            title: 'Locked Feature',
            subtitle: 'Premium only',
            semanticsValue: 'Premium feature, disabled',
            visuallyDisabled: true,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Locked Feature'), findsOneWidget);
      expect(find.text('Locked Feature'), findsOneWidget);
    });

    testWidgets('SettingToggleTile renders correctly',
        (WidgetTester tester) async {
      var testValue = false;

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

    testWidgets('SettingsSectionHeader renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSectionHeader(title: 'Test Section'),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('SettingsSectionSpacer renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSectionSpacer(),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('PremiumSection renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PremiumSection(),
        ),
      );

      // Section header is now handled by parent, so we only check for the content
      expect(find.text('Premium Features'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(1));
    });

    testWidgets('AppSettingsSection renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SingleChildScrollView(child: AppSettingsSection()),
        ),
      );

      // Section header is now handled by parent, so we only check for the content
      expect(find.text('Theme Settings'), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Remove Ads'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Data Export'), findsOneWidget);
    });

    testWidgets('LegalSupportSection renders correctly',
        (WidgetTester tester) async {
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

    testWidgets('SettingsTheme helper methods work',
        (WidgetTester tester) async {
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
