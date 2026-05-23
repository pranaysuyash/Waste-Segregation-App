import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/purchase_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';

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
  bool hasActivePremiumPlan() =>
      _enabled[PremiumService.proSubscriptionEntitlement] == true ||
      _enabled[PremiumService.legacyPremiumSignal] == true;

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
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PremiumFeaturesScreen(),
    ),
  );
}

class FakePurchaseService extends ChangeNotifier implements PurchaseService {
  @override
  final String productId = 'waste_premium_monthly';

  bool _isAvailable = true;
  bool _isProcessingPurchase = false;
  String? _errorMessage;
  PurchaseProduct? _premiumProduct;

  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isLoading => false;

  @override
  bool get isProcessingPurchase => _isProcessingPurchase;

  @override
  String? get errorMessage => _errorMessage;

  @override
  PurchaseProduct? get premiumProduct => _premiumProduct;

  @override
  bool get canPurchase => _isAvailable && _premiumProduct != null && !_isProcessingPurchase;

  void setProduct(PurchaseProduct? product) {
    _premiumProduct = product;
    _initialized = true;
    notifyListeners();
  }

  void setIsProcessing(bool processing) {
    _isProcessingPurchase = processing;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setAvailable(bool available) {
    _isAvailable = available;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _initialized = true;
    notifyListeners();
  }

  @override
  Future<void> buyPremium() async {
    _isProcessingPurchase = true;
    notifyListeners();
  }

  @override
  Future<void> restorePurchases() async {
    _isProcessingPurchase = true;
    notifyListeners();
  }

}

Widget buildTestAppWithIap({
  required FakePremiumService premiumService,
  required FakePurchaseService purchaseService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PremiumService>.value(value: premiumService),
      ChangeNotifierProvider<PurchaseService>.value(value: purchaseService),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PremiumFeaturesScreen(),
    ),
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
        // Title appears in card AND in PremiumLockWrapper's amber overlay badge.
        expect(find.text(feature.title), findsWidgets);
        expect(find.text(feature.description), findsOneWidget);
      }

      expect(find.text('Locked Premium Features'), findsOneWidget);
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
      expect(find.text('Locked Premium Features'), findsOneWidget);

      for (final feature in PremiumFeature.features) {
        // Locked features render title twice (card + PremiumLockWrapper overlay).
        // Unlocked features render title once. Either way at least one is present.
        expect(find.text(feature.title), findsWidgets);
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

    testWidgets('locked premium feature card opens upgrade explanation',
        (tester) async {
      await tester.pumpWidget(buildTestApp(FakePremiumService()));
      await tester.pumpAndSettle();

      final offlineCard = find.byWidgetPredicate(
        (widget) =>
            widget is PremiumFeatureCard && widget.feature.id == 'offline_mode',
      );
      expect(offlineCard, findsOneWidget);

      await tester.ensureVisible(offlineCard);
      await tester.pumpAndSettle();
      await tester.tap(offlineCard);
      await tester.pumpAndSettle();

      expect(find.text('See Premium Features'), findsOneWidget);
      expect(find.textContaining('Offline Classification is a premium feature'),
          findsOneWidget);
    });

    group('IAP purchase flow', () {
      testWidgets('shows IAP section when PurchaseService is provided',
          (tester) async {
        final purchaseService = FakePurchaseService();
        purchaseService.setProduct(
          const PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium',
            description: 'Unlock all premium features',
            price: '\$4.99',
          ),
        );

        await tester.pumpWidget(buildTestAppWithIap(
          premiumService: FakePremiumService(),
          purchaseService: purchaseService,
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('\$4.99'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.textContaining('\$4.99'), findsOneWidget);
        expect(find.text('Restore Purchases'), findsOneWidget);
      });

      testWidgets('shows Premium Unavailable when product is null',
          (tester) async {
        final purchaseService = FakePurchaseService();
        purchaseService.setProduct(null);

        await tester.pumpWidget(buildTestAppWithIap(
          premiumService: FakePremiumService(),
          purchaseService: purchaseService,
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Premium Unavailable'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Premium Unavailable'), findsOneWidget);
      });

      testWidgets('shows Processing... during purchase', (tester) async {
        final purchaseService = FakePurchaseService();
        purchaseService.setProduct(
          const PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium',
            description: 'Unlock all premium features',
            price: '\$4.99',
          ),
        );
        purchaseService.setIsProcessing(true);

        await tester.pumpWidget(buildTestAppWithIap(
          premiumService: FakePremiumService(),
          purchaseService: purchaseService,
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Processing...'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Processing...'), findsOneWidget);
        // Restore Purchases button should be disabled during processing
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is ButtonStyleButton &&
                w.child is Text &&
                (w.child! as Text).data == 'Restore Purchases' &&
                w.onPressed == null,
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows error message from purchase service', (tester) async {
        final purchaseService = FakePurchaseService();
        purchaseService.setProduct(
          const PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium',
            description: 'Unlock all premium features',
            price: '\$4.99',
          ),
        );
        purchaseService.setError('Purchase failed. Please try again.');

        await tester.pumpWidget(buildTestAppWithIap(
          premiumService: FakePremiumService(),
          purchaseService: purchaseService,
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Purchase failed. Please try again.'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Purchase failed. Please try again.'), findsOneWidget);
      });

      testWidgets('shows Premium Active when user already has premium plan',
          (tester) async {
        final premiumService = FakePremiumService();
        await premiumService.setPremiumPlanEntitlement(true);

        final purchaseService = FakePurchaseService();
        purchaseService.setProduct(
          const PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium',
            description: 'Unlock all premium features',
            price: '\$4.99',
          ),
        );

        await tester.pumpWidget(buildTestAppWithIap(
          premiumService: premiumService,
          purchaseService: purchaseService,
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Premium Active'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Premium Active'), findsOneWidget);
        // Purchase buttons should not appear
        expect(find.text('Pay with Card / UPI'), findsNothing);
        expect(find.text('Restore Purchases'), findsNothing);
      });

      testWidgets('locked feature tap on premium screen does not navigate',
          (tester) async {
        final premiumService = FakePremiumService();

        await tester.pumpWidget(MultiProvider(
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
            initialRoute: Routes.premiumFeatures,
            routes: {
              Routes.premiumFeatures: (_) =>
                  const PremiumFeaturesScreen(),
            },
          ),
        ));
        await tester.pumpAndSettle();

        final offlineCard = find.byWidgetPredicate(
          (widget) =>
              widget is PremiumFeatureCard &&
              widget.feature.id == 'offline_mode',
        );
        expect(offlineCard, findsOneWidget);

        await tester.ensureVisible(offlineCard);
        await tester.pumpAndSettle();
        await tester.tap(offlineCard);
        await tester.pumpAndSettle();

        expect(find.text('See Premium Features'), findsOneWidget);
        expect(
          find.textContaining('Offline Classification is a premium feature'),
          findsOneWidget,
        );

        await tester.tap(find.text('See Premium Features'));
        await tester.pumpAndSettle();

        // Should NOT have pushed a duplicate — only one instance on screen
        expect(find.text('Premium Features'), findsOneWidget);
      });
    });
  });
}
