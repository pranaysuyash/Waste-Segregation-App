import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';
import 'package:waste_segregation_app/widgets/premium_segmentation_toggle.dart';

class _FakePremiumService extends ChangeNotifier implements PremiumService {
  _FakePremiumService({bool advancedSegmentation = false}) {
    _features['advanced_segmentation'] = advancedSegmentation;
  }

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
}

class _RouteTarget extends StatelessWidget {
  const _RouteTarget(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label)),
    );
  }
}

Widget _buildApp({
  required PremiumService premiumService,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PremiumService>.value(value: premiumService),
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
        Routes.premiumFeatures: (_) => const _RouteTarget('premium-route'),
      },
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PremiumSegmentationToggle', () {
    testWidgets('shows locked visuals and upgrade flow for free tier',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          premiumService: _FakePremiumService(),
          child: const PremiumSegmentationToggle(value: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Upgrade to Use Advanced Segmentation'), findsOneWidget);

      await tester.tap(find.text('Advanced Segmentation'));
      await tester.pumpAndSettle();

      expect(find.text('See Premium Features'), findsOneWidget);
      await tester.tap(find.text('See Premium Features'));
      await tester.pumpAndSettle();

      expect(find.text('premium-route'), findsOneWidget);
    });

    testWidgets('shows enabled visual state when premium is active',
        (tester) async {
      var toggleValue = false;

      await tester.pumpWidget(
        _buildApp(
          premiumService: _FakePremiumService(advancedSegmentation: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              return PremiumSegmentationToggle(
                value: toggleValue,
                onChanged: (value) {
                  setState(() {
                    toggleValue = value;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ENABLED'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggleValue, isTrue);
    });
  });
}
