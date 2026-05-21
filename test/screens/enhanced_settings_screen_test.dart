import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
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

import 'settings_screen_test.mocks.dart';

class _FakeHapticSettingsService extends HapticSettingsService {
  _FakeHapticSettingsService() : super();

  bool _enabledValue = true;

  @override
  bool get enabled => _enabledValue;

  @override
  Future<void> setEnabled(bool value) async {
    _enabledValue = value;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('EnhancedSettingsScreen (smoke)', () {
    late MockPremiumService premiumService;
    late MockStorageService storageService;
    late MockAdService adService;
    late MockAnalyticsService analyticsService;
    late MockGoogleDriveService googleDriveService;
    late MockCloudStorageService cloudStorageService;
    late MockNavigationSettingsService navigationSettingsService;
    late _FakeHapticSettingsService hapticSettingsService;

    setUp(() {
      premiumService = MockPremiumService();
      storageService = MockStorageService();
      adService = MockAdService();
      analyticsService = MockAnalyticsService();
      googleDriveService = MockGoogleDriveService();
      cloudStorageService = MockCloudStorageService();
      navigationSettingsService = MockNavigationSettingsService();
      hapticSettingsService = _FakeHapticSettingsService();

      when(premiumService.isPremiumFeature(any)).thenReturn(false);

      when(adService.setInClassificationFlow(any)).thenReturn(null);
      when(adService.setInEducationalContent(any)).thenReturn(null);
      when(adService.setInSettings(any)).thenReturn(null);

      when(googleDriveService.isSignedIn()).thenAnswer((_) async => false);
      when(storageService.getSettings()).thenAnswer((_) async => {
            'isGoogleSyncEnabled': false,
            'allowHistoryFeedback': true,
            'feedbackTimeframeDays': 7,
          });

      when(navigationSettingsService.bottomNavEnabled).thenReturn(true);
      when(navigationSettingsService.fabEnabled).thenReturn(true);
      when(navigationSettingsService.navigationStyle).thenReturn('material3');
      when(navigationSettingsService.setBottomNavEnabled(any))
          .thenAnswer((_) async {});
      when(navigationSettingsService.setFabEnabled(any))
          .thenAnswer((_) async {});
      when(navigationSettingsService.setNavigationStyle(any))
          .thenAnswer((_) async {});
    });

    Widget wrap() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<AdService>.value(value: adService),
          ChangeNotifierProvider<AnalyticsService>.value(
            value: analyticsService,
          ),
          Provider<GoogleDriveService>.value(value: googleDriveService),
          Provider<CloudStorageService>.value(value: cloudStorageService),
          ChangeNotifierProvider<NavigationSettingsService>.value(
            value: navigationSettingsService,
          ),
          ChangeNotifierProvider<HapticSettingsService>.value(
            value: hapticSettingsService,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EnhancedSettingsScreen(),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byType(EnhancedSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
