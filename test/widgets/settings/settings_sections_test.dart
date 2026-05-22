import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/widgets/settings/privacy_section.dart';
import 'package:waste_segregation_app/widgets/settings/feedback_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/legal_support_section.dart';
import 'package:waste_segregation_app/widgets/settings/developer_section.dart';
import '../../helpers/test_helper.dart';

class _FakeStorageService extends MockStorageService {
  final Map<String, dynamic> _settings = <String, dynamic>{
    'allowHistoryFeedback': true,
    'feedbackTimeframeDays': 7,
  };

  @override
  Future<Map<String, dynamic>> getSettings() async {
    return Map<String, dynamic>.from(_settings);
  }

  @override
  Future<void> saveSettings({
    required bool isDarkMode,
    required bool isGoogleSyncEnabled,
    DateTime? lastCloudSync,
    bool? allowHistoryFeedback,
    int? feedbackTimeframeDays,
    bool? notifications,
    bool? eduNotifications,
    bool? gamificationNotifications,
    bool? reminderNotifications,
  }) async {
    if (allowHistoryFeedback != null) {
      _settings['allowHistoryFeedback'] = allowHistoryFeedback;
    }
    if (feedbackTimeframeDays != null) {
      _settings['feedbackTimeframeDays'] = feedbackTimeframeDays;
    }
  }
}

class _FakePremiumService extends ChangeNotifier implements PremiumService {
  final Map<String, bool> _features = <String, bool>{
    'remove_ads': false,
    'theme_customization': true,
    'offline_mode': true,
    'advanced_analytics': false,
    'export_data': true,
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

  @override
  bool canPerformScan(int dailyScanCount) {
    return dailyScanCount < getDailyScanLimit();
  }

  @override
  PremiumTier getCurrentTier() {
    return hasActivePremiumPlan() ? PremiumTier.premium : PremiumTier.free;
  }

  @override
  int getDailyScanLimit() {
    switch (getCurrentTier()) {
      case PremiumTier.premium:
        return 100;
      case PremiumTier.family:
        return 500;
      default:
        return 10;
    }
  }
}

Widget _createApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LegalSupportSection', () {
    testWidgets('renders legal & support tiles', (WidgetTester tester) async {
      await tester.pumpWidget(_createApp(const LegalSupportSection()));

      expect(find.text('Legal & Support'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('FeedbackSettingsSection', () {
    testWidgets('shows loading then feedback toggle and timeframe',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>(create: (_) => _FakeStorageService()),
          ],
          child: _createApp(const FeedbackSettingsSection()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Feedback Settings'), findsOneWidget);
      expect(find.text('Allow Feedback on Recent History'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
    });
  });

  group('PrivacySection', () {
    testWidgets('renders privacy & consent toggles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>(create: (_) => MockStorageService()),
            Provider<CloudStorageService>(
                create: (_) => MockCloudStorageService()),
          ],
          child: _createApp(const PrivacySection()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privacy & Consent'), findsOneWidget);
      expect(find.text('Hide from Leaderboard'), findsOneWidget);
      expect(find.text('Improve model with my images'), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });

  group('DeveloperSection', () {
    testWidgets('renders developer options with feature toggles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PremiumService>(
              create: (_) => _FakePremiumService(),
            ),
          ],
          child: _createApp(
            const SingleChildScrollView(
              child: DeveloperSection(showDeveloperOptions: true),
            ),
          ),
        ),
      );

      expect(find.text('DEVELOPER OPTIONS'), findsOneWidget);
      expect(find.text('Toggle features for testing'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
      expect(find.text('Remove Ads'), findsOneWidget);
      expect(find.text('Theme Customization'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Advanced Analytics'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(5));
    });

    testWidgets('hides developer options when showDeveloperOptions is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PremiumService>(
              create: (_) => _FakePremiumService(),
            ),
          ],
          child: _createApp(
            const DeveloperSection(showDeveloperOptions: false),
          ),
        ),
      );

      expect(find.text('DEVELOPER OPTIONS'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
    });
  });
}
