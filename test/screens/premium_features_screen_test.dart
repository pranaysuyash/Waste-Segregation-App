import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';

class FakePremiumService extends ChangeNotifier implements PremiumService {
  final Map<String, bool> _enabled = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  bool isPremiumFeature(String featureId) => _enabled[featureId] ?? false;

  @override
  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    _enabled[featureId] = isPremium;
    notifyListeners();
  }

  @override
  Future<void> setPremiumPlanEntitlement(bool isPremium) async {
    await setPremiumFeature(PremiumService.proSubscriptionEntitlement, isPremium);
  }

  @override
  Future<void> toggleFeature(String featureId) async {
    await setPremiumFeature(featureId, !isPremiumFeature(featureId));
  }

  @override
  bool hasActivePremiumPlan() => false;

  @override
  List<PremiumFeature> getPremiumFeatures() => PremiumFeature.features
      .where((feature) => isPremiumFeature(feature.id))
      .map((feature) => PremiumFeature(
            id: feature.id,
            title: feature.title,
            description: feature.description,
            icon: feature.icon,
            route: feature.route,
            isEnabled: true,
          ))
      .toList();

  @override
  List<PremiumFeature> getComingSoonFeatures() => PremiumFeature.features
      .where((feature) => !isPremiumFeature(feature.id))
      .toList();

  @override
  Future<void> resetPremiumFeatures() async {
    _enabled.clear();
    notifyListeners();
  }

  @override
  PremiumTier getCurrentTier() => PremiumTier.free;

  @override
  int getDailyScanLimit() => 10;

  @override
  bool canPerformScan(int dailyScanCount) => true;
}

Widget buildTestApp(FakePremiumService premiumService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PremiumService>.value(value: premiumService),
    ],
    child: const MaterialApp(home: PremiumFeaturesScreen()),
  );
}

Future<void> scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PremiumFeaturesScreen', () {
    testWidgets('renders title and header', (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      expect(find.text('Premium Features'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('shows web checkout CTA when no IAP service is provided',
        (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      // No PurchaseService provided → IAP section hidden; DodoPayments button shown.
      await scrollToText(tester, 'Pay with Card / UPI');
      expect(find.text('Pay with Card / UPI'), findsOneWidget);
    });

    testWidgets('shows all features as locked when no premium features active',
        (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      for (final feature in PremiumFeature.features) {
        expect(find.text(feature.title), findsOneWidget);
        expect(find.text(feature.description), findsOneWidget);
      }

      expect(find.text('Available Premium Features'), findsOneWidget);
      expect(find.text('Your Premium Features'), findsNothing);
    });

    testWidgets('moves unlocked features to Your Premium Features section',
        (tester) async {
      final premiumService = FakePremiumService();
      await premiumService.setPremiumFeature('remove_ads', true);
      await premiumService.setPremiumFeature('offline_mode', true);

      await tester.pumpWidget(buildTestApp(premiumService));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Your Premium Features');
      expect(find.text('Your Premium Features'), findsOneWidget);
      expect(find.text('Available Premium Features'), findsOneWidget);

      for (final feature in PremiumFeature.features) {
        expect(find.text(feature.title), findsOneWidget);
        expect(find.text(feature.description), findsOneWidget);
      }
    });

    testWidgets('web checkout CTA shows payment method hint text', (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      await scrollToText(
        tester,
        'Pay online with credit/debit card, UPI, or net banking. No app store required.',
      );
      expect(
        find.text(
          'Pay online with credit/debit card, UPI, or net banking. No app store required.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('web checkout CTA button is tappable when not processing',
        (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Pay with Card / UPI');
      // When not processing, the label reads 'Pay with Card / UPI' (not 'Creating checkout...').
      // Verify it is visible and backed by an enabled ButtonStyleButton.
      expect(find.text('Pay with Card / UPI'), findsOneWidget);
      final btnFinder = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed != null,
      );
      expect(btnFinder, findsWidgets);
    });
  });
}
