import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/providers.dart';
import 'package:waste_segregation_app/screens/theme_settings_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';
import 'package:waste_segregation_app/widgets/settings/premium_feature_visuals.dart';

class _FakePremiumService extends ChangeNotifier implements PremiumService {
  _FakePremiumService({Map<String, bool>? features})
      : _features = Map<String, bool>.from(features ?? const {});

  final Map<String, bool> _features;

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
  bool hasActivePremiumPlan() => _features.values.any((value) => value);

  @override
  PremiumTier getCurrentTier() =>
      hasActivePremiumPlan() ? PremiumTier.premium : PremiumTier.free;

  @override
  int getDailyScanLimit() {
    switch (getCurrentTier()) {
      case PremiumTier.premium:
        return 100;
      case PremiumTier.family:
        return 500;
      case PremiumTier.free:
        return 10;
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

Widget _buildTestApp(PremiumService premiumService) {
  return ProviderScope(
    overrides: [
      premiumServiceProvider.overrideWithValue(premiumService),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        Routes.premium: (_) => const Scaffold(body: Text('premium-route')),
      },
      home: const ThemeSettingsScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'free tier shows locked theme customization state with contextual upgrade prompt',
      (tester) async {
    final premiumService =
        _FakePremiumService(features: const {'theme_customization': false});

    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_buildTestApp(premiumService));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ThemeSettingsScreen));
      final t = AppLocalizations.of(context)!;

      final semanticsNode = tester.getSemantics(find.text(t.themeCustomization));
      expect(semanticsNode.label, t.themeCustomization);
      expect(
        semanticsNode.value,
        PremiumFeatureVisuals.semanticsState(context, isUnlocked: false),
      );
      expect(semanticsNode.hint, t.upgradeToUse(t.themeCustomization));
      expect(semanticsNode.hasFlag(SemanticsFlag.isButton), isTrue);

      expect(find.text(t.themeCustomization), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);

      await tester.tap(find.text(t.themeCustomization));
      await tester.pumpAndSettle();

      expect(find.text(t.upgradeToUse(t.themeCustomization)), findsOneWidget);
      expect(
        find.textContaining('Customize app appearance'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('Theme Customization is a premium feature'),
        findsOneWidget,
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('premium tier shows unlocked active state for theme customization',
      (tester) async {
    final premiumService =
        _FakePremiumService(features: const {'theme_customization': true});

    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_buildTestApp(premiumService));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ThemeSettingsScreen));
      final t = AppLocalizations.of(context)!;

      final semanticsNode = tester.getSemantics(find.text(t.themeCustomization));
      expect(semanticsNode.label, t.themeCustomization);
      expect(
        semanticsNode.value,
        PremiumFeatureVisuals.semanticsState(context, isUnlocked: true),
      );
      expect(semanticsNode.hint, t.themeSettingsSubtitle);
      expect(semanticsNode.hasFlag(SemanticsFlag.isButton), isTrue);

      expect(find.text(t.themeCustomization), findsOneWidget);
      expect(find.text(t.enabled.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.themeCustomization));
      await tester.pumpAndSettle();

      expect(find.text(t.upgradeToUse(t.themeCustomization)), findsNothing);
    } finally {
      semanticsHandle.dispose();
    }
  });
}
