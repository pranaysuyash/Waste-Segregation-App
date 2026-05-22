import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/screens/enhanced_settings_screen.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/widgets/settings/account_section.dart';
import 'package:waste_segregation_app/widgets/settings/premium_section.dart';
import 'package:waste_segregation_app/widgets/settings/app_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/privacy_section.dart';
import 'package:waste_segregation_app/widgets/settings/feedback_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/navigation_section.dart';
import 'package:waste_segregation_app/widgets/settings/features_section.dart';
import 'package:waste_segregation_app/widgets/settings/legal_support_section.dart';
import 'package:waste_segregation_app/utils/developer_config.dart';

import 'settings_screen_test.mocks.dart';

@GenerateMocks([
  PremiumService,
  StorageService,
  AdService,
  AnalyticsService,
  GoogleDriveService,
  CloudStorageService,
  NavigationSettingsService,
  HapticSettingsService,
])
void main() {
  group('EnhancedSettingsScreen (canonical settings)', () {
    late MockPremiumService premiumService;
    late MockStorageService storageService;
    late MockAdService adService;
    late MockAnalyticsService analyticsService;
    late MockGoogleDriveService googleDriveService;
    late MockCloudStorageService cloudStorageService;
    late MockNavigationSettingsService navigationSettingsService;
    late MockHapticSettingsService hapticSettingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      premiumService = MockPremiumService();
      storageService = MockStorageService();
      adService = MockAdService();
      analyticsService = MockAnalyticsService();
      googleDriveService = MockGoogleDriveService();
      cloudStorageService = MockCloudStorageService();
      navigationSettingsService = MockNavigationSettingsService();
      hapticSettingsService = MockHapticSettingsService();

      when(premiumService.isPremiumFeature(any)).thenReturn(false);
      when(premiumService.isInitialized).thenReturn(true);

      when(googleDriveService.isSignedIn()).thenAnswer((_) async => false);
      when(storageService.getSettings()).thenAnswer((_) async => {
            'isGoogleSyncEnabled': true,
            'allowHistoryFeedback': true,
            'feedbackTimeframeDays': 7,
            'isDarkMode': false,
          });
      when(storageService.getLastCloudSync()).thenAnswer((_) async => null);
      when(storageService.getCurrentUserProfile())
          .thenAnswer((_) async => null);

      when(navigationSettingsService.bottomNavEnabled).thenReturn(true);
      when(navigationSettingsService.fabEnabled).thenReturn(true);
      when(navigationSettingsService.navigationStyle)
          .thenReturn('glassmorphism');
      when(navigationSettingsService.setBottomNavEnabled(any))
          .thenAnswer((_) async {});
      when(navigationSettingsService.setFabEnabled(any))
          .thenAnswer((_) async {});
      when(navigationSettingsService.setNavigationStyle(any))
          .thenAnswer((_) async {});

      when(hapticSettingsService.enabled).thenReturn(true);
      when(hapticSettingsService.setEnabled(any))
          .thenAnswer((_) async {});
    });

    Widget _wrap() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<AdService>.value(value: adService),
          ChangeNotifierProvider<AnalyticsService>.value(
              value: analyticsService),
          Provider<GoogleDriveService>.value(value: googleDriveService),
          Provider<CloudStorageService>.value(value: cloudStorageService),
          ChangeNotifierProvider<NavigationSettingsService>.value(
              value: navigationSettingsService),
          ChangeNotifierProvider<HapticSettingsService>.value(
              value: hapticSettingsService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EnhancedSettingsScreen(),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.byType(EnhancedSettingsScreen), findsOneWidget);
    });

    testWidgets('renders all expected section widgets', (tester) async {
      await tester.pumpWidget(_wrap());
      // Pump a couple frames to let async loads schedule
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.byType(PremiumSection), findsOneWidget);
      expect(find.byType(AppSettingsSection), findsOneWidget);
      expect(find.byType(PrivacySection), findsOneWidget);
      expect(find.byType(FeedbackSettingsSection), findsOneWidget);
      expect(find.byType(NavigationSection), findsOneWidget);
      expect(find.byType(FeaturesSection), findsOneWidget);
      expect(find.byType(LegalSupportSection), findsOneWidget);
    });

    testWidgets('developer section is hidden by default', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('DEVELOPER OPTIONS'), findsNothing);
    });

    testWidgets('section headers are visible after load', (tester) async {
      await tester.pumpWidget(_wrap());
      // Give time for stateful widgets to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Check section headers are present by widget type
      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.byType(PremiumSection), findsOneWidget);
      expect(find.byType(AppSettingsSection), findsOneWidget);
      expect(find.byType(PrivacySection), findsOneWidget);
      expect(find.byType(FeedbackSettingsSection), findsOneWidget);
      expect(find.byType(NavigationSection), findsOneWidget);
      expect(find.byType(FeaturesSection), findsOneWidget);
      expect(find.byType(LegalSupportSection), findsOneWidget);
    });
  });
}
