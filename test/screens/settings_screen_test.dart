import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/screens/settings_screen.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

import 'settings_screen_test.mocks.dart';

@GenerateMocks([
  PremiumService,
  StorageService,
  AdService,
  AnalyticsService,
  GoogleDriveService,
  CloudStorageService,
  NavigationSettingsService,
])
void main() {
  group('SettingsScreen (smoke)', () {
    late MockPremiumService premiumService;
    late MockStorageService storageService;
    late MockAdService adService;
    late MockAnalyticsService analyticsService;
    late MockGoogleDriveService googleDriveService;
    late MockCloudStorageService cloudStorageService;
    late MockNavigationSettingsService navigationSettingsService;

    setUp(() {
      premiumService = MockPremiumService();
      storageService = MockStorageService();
      adService = MockAdService();
      analyticsService = MockAnalyticsService();
      googleDriveService = MockGoogleDriveService();
      cloudStorageService = MockCloudStorageService();
      navigationSettingsService = MockNavigationSettingsService();

      when(premiumService.isPremiumFeature(any)).thenReturn(false);

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
      when(navigationSettingsService.setFabEnabled(any)).thenAnswer((_) async {});
      when(navigationSettingsService.setNavigationStyle(any))
          .thenAnswer((_) async {});
    });

    Widget _wrap() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<AdService>.value(value: adService),
          ChangeNotifierProvider<AnalyticsService>.value(value: analyticsService),
          Provider<GoogleDriveService>.value(value: googleDriveService),
          Provider<CloudStorageService>.value(value: cloudStorageService),
          ChangeNotifierProvider<NavigationSettingsService>.value(
              value: navigationSettingsService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // Keep this file as a smoke suite; deeper assertions are brittle because
    // SettingsScreen content and app bar composition evolve frequently.
  });
}
