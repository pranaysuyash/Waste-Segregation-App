import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';
import 'package:waste_segregation_app/widgets/settings/app_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/features_section.dart';
import 'package:waste_segregation_app/widgets/settings/navigation_section.dart';

class _FakeHapticSettingsService extends ChangeNotifier
    implements HapticSettingsService {
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
  }
}

class _FakeNavigationSettingsService extends ChangeNotifier
    implements NavigationSettingsService {
  bool _bottomNavEnabled = true;
  bool _fabEnabled = false;
  String _navigationStyle = 'material3';

  @override
  bool get bottomNavEnabled => _bottomNavEnabled;

  @override
  bool get fabEnabled => _fabEnabled;

  @override
  String get navigationStyle => _navigationStyle;

  @override
  Future<void> resetToDefaults() async {
    _bottomNavEnabled = true;
    _fabEnabled = false;
    _navigationStyle = 'glassmorphism';
    notifyListeners();
  }

  @override
  Future<void> setBottomNavEnabled(bool enabled) async {
    _bottomNavEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setFabEnabled(bool enabled) async {
    _fabEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setNavigationStyle(String style) async {
    _navigationStyle = style;
    notifyListeners();
  }
}

class _FakePremiumService extends ChangeNotifier implements PremiumService {
  final Map<String, bool> _features = <String, bool>{};

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
  bool hasActivePremiumPlan() => false;

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
    await setPremiumFeature(PremiumService.proSubscriptionEntitlement, isPremium);
    _features[PremiumService.legacyPremiumSignal] = isPremium;
    notifyListeners();
  }
}

class _RouteTarget extends StatelessWidget {
  const _RouteTarget(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(label),
      ),
    );
  }
}

Widget _buildApp({
  required Widget child,
  required Map<String, WidgetBuilder> routes,
  HapticSettingsService? hapticSettingsService,
  NavigationSettingsService? navigationSettingsService,
  PremiumService? premiumService,
}) {
  final providers = <SingleChildWidget>[
    if (hapticSettingsService != null)
      ChangeNotifierProvider<HapticSettingsService>.value(
        value: hapticSettingsService,
      ),
    if (navigationSettingsService != null)
      ChangeNotifierProvider<NavigationSettingsService>.value(
        value: navigationSettingsService,
      ),
    if (premiumService != null)
      ChangeNotifierProvider<PremiumService>.value(value: premiumService),
  ];

  final app = MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routes: routes,
    home: Scaffold(body: child),
  );

  if (providers.isEmpty) {
    return app;
  }

  return MultiProvider(
    providers: providers,
    child: app,
  );
}

void main() {
  group('Settings navigation contract', () {
    Future<void> expectAppSettingsRoute(
      WidgetTester tester,
      String tileText,
      String routeName,
      String routeTargetLabel,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          hapticSettingsService: _FakeHapticSettingsService(),
          child: const AppSettingsSection(),
          routes: {
            Routes.themeSettings: (_) =>
                const _RouteTarget('theme-settings-route'),
            Routes.notificationSettings: (_) =>
                const _RouteTarget('notification-settings-route'),
            Routes.offlineModeSettings: (_) =>
                const _RouteTarget('offline-settings-route'),
            Routes.dataExport: (_) => const _RouteTarget('data-export-route'),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tileText), findsOneWidget);
      await tester.tap(find.text(tileText));
      await tester.pumpAndSettle();
      expect(find.text(routeTargetLabel), findsOneWidget);
      expect(Routes.isValidRoute(routeName), isTrue);
    }

    testWidgets('AppSettingsSection routes Theme Settings by name',
        (tester) async {
      await expectAppSettingsRoute(
        tester,
        'Theme Settings',
        Routes.themeSettings,
        'theme-settings-route',
      );
    });

    testWidgets('AppSettingsSection routes Notification Settings by name',
        (tester) async {
      await expectAppSettingsRoute(
        tester,
        'Notification Settings',
        Routes.notificationSettings,
        'notification-settings-route',
      );
    });

    testWidgets('AppSettingsSection routes Offline Mode by name',
        (tester) async {
      await expectAppSettingsRoute(
        tester,
        'Offline Mode',
        Routes.offlineModeSettings,
        'offline-settings-route',
      );
    });

    testWidgets('AppSettingsSection routes Data Export by name',
        (tester) async {
      await expectAppSettingsRoute(
        tester,
        'Data Export',
        Routes.dataExport,
        'data-export-route',
      );
    });

    testWidgets('NavigationSection routes navigation styles to the demo',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          navigationSettingsService: _FakeNavigationSettingsService(),
          child: const NavigationSection(),
          routes: {
            Routes.navigationDemo: (_) =>
                const _RouteTarget('navigation-demo-route'),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Navigation Styles'));
      await tester.pumpAndSettle();

      expect(find.text('navigation-demo-route'), findsOneWidget);
    });

    testWidgets('FeaturesSection routes premium offline mode to settings',
        (tester) async {
      final premiumService = _FakePremiumService();
      await premiumService.setPremiumFeature('offline_mode', true);

      await tester.pumpWidget(
        _buildApp(
          premiumService: premiumService,
          child: const FeaturesSection(),
          routes: {
            Routes.modernUIShowcase: (_) =>
                const _RouteTarget('modern-ui-route'),
            Routes.offlineModeSettings: (_) =>
                const _RouteTarget('offline-settings-route'),
            Routes.wasteDashboard: (_) => const _RouteTarget('analytics-route'),
            Routes.premiumFeatures: (_) => const _RouteTarget('premium-route'),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Offline Mode'));
      await tester.pumpAndSettle();

      expect(find.text('offline-settings-route'), findsOneWidget);
    });

    testWidgets('Training review queue is reachable via a named route',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.trainingReviewQueue);
                    },
                    child: const Text('Open training review queue'),
                  ),
                ),
              );
            },
          ),
          routes: {
            Routes.trainingReviewQueue: (_) =>
                const _RouteTarget('training-review-route'),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open training review queue'));
      await tester.pumpAndSettle();

      expect(find.text('training-review-route'), findsOneWidget);
    });
  });
}
