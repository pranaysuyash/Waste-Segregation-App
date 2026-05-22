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

import 'settings_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<PremiumService>(),
  MockSpec<StorageService>(),
  MockSpec<AdService>(),
  MockSpec<AnalyticsService>(),
  MockSpec<GoogleDriveService>(),
  MockSpec<CloudStorageService>(),
  MockSpec<NavigationSettingsService>(),
  MockSpec<HapticSettingsService>(),
])
void main() {
  group('EnhancedSettingsScreen (canonical settings)', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget _wrap() {
      final premiumService = MockPremiumService();
      final storageService = MockStorageService();
      final adService = MockAdService();
      final navigationSettingsService = MockNavigationSettingsService();
      final hapticSettingsService = MockHapticSettingsService();

      when(premiumService.isPremiumFeature(any)).thenReturn(false);
      when(premiumService.isInitialized).thenReturn(true);

      when(storageService.getSettings()).thenAnswer((_) async => {});
      when(storageService.getLastCloudSync()).thenAnswer((_) async => null);
      when(storageService.getCurrentUserProfile())
          .thenAnswer((_) async => null);

      when(navigationSettingsService.bottomNavEnabled).thenReturn(true);
      when(navigationSettingsService.fabEnabled).thenReturn(true);
      when(navigationSettingsService.navigationStyle)
          .thenReturn('glassmorphism');

      when(hapticSettingsService.enabled).thenReturn(true);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<AdService>.value(value: adService),
          ChangeNotifierProvider<AnalyticsService>.value(
              value: MockAnalyticsService()),
          Provider<GoogleDriveService>.value(value: MockGoogleDriveService()),
          Provider<CloudStorageService>.value(
              value: MockCloudStorageService()),
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

    testWidgets('renders the settings title in the app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
