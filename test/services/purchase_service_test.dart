import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/purchase_service.dart';

class MockStoreBillingGateway extends Mock implements StoreBillingGateway {}

class MockPremiumService extends Mock implements PremiumService {}

class FakePurchaseUpdate extends Fake implements PurchaseUpdate {}

void main() {
  group('PurchaseService', () {
    late MockStoreBillingGateway gateway;
    late MockPremiumService premiumService;
    late StreamController<List<PurchaseUpdate>> updates;

    setUp(() {
      registerFallbackValue(FakePurchaseUpdate());
      gateway = MockStoreBillingGateway();
      premiumService = MockPremiumService();
      updates = StreamController<List<PurchaseUpdate>>.broadcast();

      when(() => gateway.purchaseUpdates).thenAnswer((_) => updates.stream);
      when(() => premiumService.setPremiumFeature(any(), any()))
          .thenAnswer((_) async {});
      when(() => premiumService.setPremiumPlanEntitlement(any()))
          .thenAnswer((_) async {});
      when(() => premiumService.hasActivePremiumPlan()).thenReturn(false);
    });

    tearDown(() async {
      await updates.close();
    });

    test('initialize reports unavailable store correctly', () async {
      when(() => gateway.isAvailable()).thenAnswer((_) async => false);

      final service = PurchaseService(
        premiumService,
        gateway: gateway,
      );

      await service.initialize();

      expect(service.isAvailable, isFalse);
      expect(service.premiumProduct, isNull);
      expect(service.canPurchase, isFalse);
      expect(service.errorMessage, isNotNull);
    });

    test('initialize loads premium product and enables purchase', () async {
      when(() => gateway.isAvailable()).thenAnswer((_) async => true);
      when(() => gateway.queryProducts(any())).thenAnswer(
        (_) async => const [
          PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium Monthly',
            description: 'Unlock all premium features',
            price: r'$4.99',
          ),
        ],
      );

      final service = PurchaseService(
        premiumService,
        gateway: gateway,
      );

      await service.initialize();

      expect(service.isAvailable, isTrue);
      expect(service.premiumProduct, isNotNull);
      expect(service.canPurchase, isTrue);
      expect(service.errorMessage, isNull);
    });

    test('purchased update grants premium entitlement', () async {
      when(() => gateway.isAvailable()).thenAnswer((_) async => true);
      when(() => gateway.queryProducts(any())).thenAnswer(
        (_) async => const [
          PurchaseProduct(
            id: 'waste_premium_monthly',
            title: 'Premium Monthly',
            description: 'Unlock all premium features',
            price: r'$4.99',
          ),
        ],
      );
      when(() => gateway.completePurchase(any())).thenAnswer((_) async {});

      final service = PurchaseService(
        premiumService,
        gateway: gateway,
      );

      await service.initialize();

      updates.add(const [
        PurchaseUpdate(
          productId: 'waste_premium_monthly',
          status: PurchaseUpdateStatus.purchased,
          needsCompletion: true,
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(() => premiumService.setPremiumPlanEntitlement(true)).called(1);
      verify(() => premiumService.setPremiumFeature('remove_ads', true))
          .called(greaterThanOrEqualTo(1));
      verify(() => gateway.completePurchase(any())).called(1);
      expect(service.isProcessingPurchase, isFalse);
    });
  });
}
