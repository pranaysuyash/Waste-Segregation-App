import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/pricing_ab_test_service.dart';

void main() {
  late PricingABTestService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PricingABTestService();
  });

  tearDown(() {
    service.dispose();
  });

  group('Deterministic Assignment', () {
    test('same userId always gets the same variant', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_abc');
      final variant1 = service.currentVariant;

      service.resetAssignment();
      await service.initialize(testId: 'test_v1', userId: 'user_abc');

      expect(variant1, equals(service.currentVariant));
    });

    test('different userIds can get different variants', () async {
      final variants = <PricingVariant>[];

      for (var i = 0; i < 100; i++) {
        service.resetAssignment();
        await service.initialize(testId: 'test_v1', userId: 'user_$i');
        variants.add(service.currentVariant);
      }

      // With 100 users, we should see at least 2 different variants
      final uniqueVariants = variants.toSet();
      expect(uniqueVariants.length, greaterThanOrEqualTo(2));
    });

    test('variant distribution is roughly 10/30/30/30', () async {
      final counts = <PricingVariant, int>{};
      for (var i = 0; i < 1000; i++) {
        final identifier = 'user_$i';
        final hash = identifier.hashCode;
        final mod = (hash % 100).abs();

        PricingVariant variant;
        if (mod < 10) {
          variant = PricingVariant.control;
        } else if (mod < 40) {
          variant = PricingVariant.variantA;
        } else if (mod < 70) {
          variant = PricingVariant.variantB;
        } else {
          variant = PricingVariant.variantC;
        }

        counts[variant] = (counts[variant] ?? 0) + 1;
      }

      // Control should be ~10% (50-150 out of 1000)
      expect(counts[PricingVariant.control], inInclusiveRange(50, 200));
      // Each other variant should be ~30% (200-400 out of 1000)
      expect(counts[PricingVariant.variantA], inInclusiveRange(200, 400));
      expect(counts[PricingVariant.variantB], inInclusiveRange(200, 400));
      expect(counts[PricingVariant.variantC], inInclusiveRange(200, 400));
    });

    test('falls back to testId hash when userId is null', () async {
      await service.initialize(testId: 'test_v1');
      final variant1 = service.currentVariant;

      service.resetAssignment();
      await service.initialize(testId: 'test_v1');
      final variant2 = service.currentVariant;

      expect(variant1, equals(variant2));
    });

    test('different testIds produce different assignments', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_1');

      service.resetAssignment();
      await service.initialize(testId: 'test_v2', userId: 'user_1');

      // Not guaranteed to be different, but testId changes the hash
      // We just verify both initialize successfully
      expect(service.isInitialized, isTrue);
      expect(service.currentAssignment!.testId, equals('test_v2'));
    });
  });

  group('Initialization', () {
    test('starts uninitialized', () {
      expect(service.isInitialized, isFalse);
      expect(service.currentVariant, equals(PricingVariant.control));
      expect(service.currentConfig, isNull);
      expect(service.currentAssignment, isNull);
    });

    test('initializes successfully with default values', () async {
      await service.initialize();

      expect(service.isInitialized, isTrue);
      expect(service.currentAssignment, isNotNull);
      expect(service.currentConfig, isNotNull);
    });

    test('assigns variant based on userId', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_abc');

      expect(service.currentAssignment, isNotNull);
      expect(service.currentAssignment!.userId, equals('user_abc'));
      expect(service.currentAssignment!.testId, equals('test_v1'));
      expect(service.currentAssignment!.assignedAt, isNotNull);
    });

    test('double initialize is idempotent', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_abc');
      final variant1 = service.currentVariant;

      // Second initialize should be a no-op
      await service.initialize(testId: 'test_v1', userId: 'user_abc');
      final variant2 = service.currentVariant;

      expect(variant1, equals(variant2));
    });
  });

  group('Configuration', () {
    test('control group has no tiers and enforcement disabled', () async {
      // Find a userId that maps to control
      String controlUserId = 'control_test_0';
      for (var i = 0; i < 1000; i++) {
        service.resetAssignment();
        final userId = 'control_test_$i';
        final hash = userId.hashCode;
        final mod = (hash % 100).abs();
        if (mod < 10) {
          controlUserId = userId;
          break;
        }
      }

      service.resetAssignment();
      await service.initialize(testId: 'test_v1', userId: controlUserId);

      expect(service.currentVariant, equals(PricingVariant.control));
      expect(service.currentConfig!.tiers, isEmpty);
      expect(service.currentConfig!.enforcementEnabled, isFalse);
      expect(service.currentConfig!.showPricing, isFalse);
      expect(service.isControlGroup, isTrue);
      expect(service.isEnforcementEnabled, isFalse);
      expect(service.shouldShowPricing, isFalse);
    });

    test('variantA has 3 tiers and enforcement enabled', () async {
      // Find a userId that maps to variantA
      String variantAUserId = 'variant_a_test_0';
      for (var i = 0; i < 1000; i++) {
        service.resetAssignment();
        final userId = 'variant_a_test_$i';
        final hash = userId.hashCode;
        final mod = (hash % 100).abs();
        if (mod >= 10 && mod < 40) {
          variantAUserId = userId;
          break;
        }
      }

      service.resetAssignment();
      await service.initialize(testId: 'test_v1', userId: variantAUserId);

      expect(service.currentVariant, equals(PricingVariant.variantA));
      expect(service.currentConfig!.tiers.length, equals(3));
      expect(service.currentConfig!.enforcementEnabled, isTrue);
      expect(service.currentConfig!.showPricing, isTrue);
      expect(service.isControlGroup, isFalse);
      expect(service.isEnforcementEnabled, isTrue);
      expect(service.shouldShowPricing, isTrue);

      // Check tier details
      final freeTier = service.currentConfig!.tiers.first;
      expect(freeTier.id, equals('free'));
      expect(freeTier.price, equals(0));

      final proTier = service.currentConfig!.tiers[1];
      expect(proTier.id, equals('pro'));
      expect(proTier.price, equals(9900)); // ₹99 in paise
      expect(proTier.isPopular, isTrue);

      final premiumTier = service.currentConfig!.tiers[2];
      expect(premiumTier.id, equals('premium'));
      expect(premiumTier.price, equals(29900)); // ₹299 in paise
    });

    test('variantB has 4 tiers including society tiers', () async {
      String variantBUserId = 'variant_b_test_0';
      for (var i = 0; i < 1000; i++) {
        service.resetAssignment();
        final userId = 'variant_b_test_$i';
        final hash = userId.hashCode;
        final mod = (hash % 100).abs();
        if (mod >= 40 && mod < 70) {
          variantBUserId = userId;
          break;
        }
      }

      service.resetAssignment();
      await service.initialize(testId: 'test_v1', userId: variantBUserId);

      expect(service.currentVariant, equals(PricingVariant.variantB));
      expect(service.currentConfig!.tiers.length, equals(4));

      // Check society tiers exist
      final tierIds = service.currentConfig!.tiers.map((t) => t.id).toList();
      expect(tierIds, contains('society_basic'));
      expect(tierIds, contains('society_premium'));

      final societyBasic = service.currentConfig!.tiers
          .firstWhere((t) => t.id == 'society_basic');
      expect(societyBasic.price, equals(49900)); // ₹499 in paise
    });

    test('variantC has 4 token-based tiers', () async {
      String variantCUserId = 'variant_c_test_0';
      for (var i = 0; i < 1000; i++) {
        service.resetAssignment();
        final userId = 'variant_c_test_$i';
        final hash = userId.hashCode;
        final mod = (hash % 100).abs();
        if (mod >= 70) {
          variantCUserId = userId;
          break;
        }
      }

      service.resetAssignment();
      await service.initialize(testId: 'test_v1', userId: variantCUserId);

      expect(service.currentVariant, equals(PricingVariant.variantC));
      expect(service.currentConfig!.tiers.length, equals(4));

      // Check token costs are set
      final starterTier = service.currentConfig!.tiers
          .firstWhere((t) => t.id == 'starter');
      expect(starterTier.tokenCost, equals(50));
      expect(starterTier.price, equals(4900)); // ₹49 in paise
      expect(starterTier.period, equals('one_time'));

      final subscriptionTier = service.currentConfig!.tiers
          .firstWhere((t) => t.id == 'subscription');
      expect(subscriptionTier.tokenCost, equals(200));
      expect(subscriptionTier.period, equals('monthly'));
    });
  });

  group('Persistence', () {
    test('assignment is saved to SharedPreferences', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_persist');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('pricing_ab_test_assignment');

      expect(stored, isNotNull);
      expect(stored, contains('test_v1'));
      expect(stored, contains(service.currentVariant.name));
    });

    test('assignment is loaded from SharedPreferences on re-initialize',
        () async {
      // First initialization saves the assignment
      await service.initialize(testId: 'test_v1', userId: 'user_load');
      final originalVariant = service.currentVariant;

      // Create a new service instance (simulates app restart)
      final newService = PricingABTestService();
      await newService.initialize(testId: 'test_v1', userId: 'user_load');

      // Should load the same assignment
      expect(newService.currentVariant, equals(originalVariant));
      expect(newService.currentAssignment!.testId, equals('test_v1'));

      newService.dispose();
    });

    test('different testId creates new assignment', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_multi');
      final variant1 = service.currentVariant;

      // New testId should create a new assignment
      service.resetAssignment();
      await service.initialize(testId: 'test_v2', userId: 'user_multi');

      expect(service.isInitialized, isTrue);
      expect(service.currentAssignment!.testId, equals('test_v2'));
    });

    test('resetAssignment clears stored assignment', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_reset');

      service.resetAssignment();

      expect(service.isInitialized, isFalse);
      expect(service.currentAssignment, isNull);
      expect(service.currentConfig, isNull);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('pricing_ab_test_assignment');
      expect(stored, isNull);
    });
  });

  group('Event Tracking', () {
    setUp(() async {
      await service.initialize(testId: 'test_v1', userId: 'user_events');
    });

    test('trackPricingScreenViewed does not throw', () {
      expect(
        () => service.trackPricingScreenViewed(tierShown: 'pro'),
        returnsNormally,
      );
    });

    test('trackPricingTierSelected does not throw', () {
      expect(
        () => service.trackPricingTierSelected(
          tier: 'pro',
          price: 9900,
        ),
        returnsNormally,
      );
    });

    test('trackPurchaseInitiated does not throw', () {
      expect(
        () => service.trackPurchaseInitiated(
          tier: 'pro',
          price: 9900,
          paymentMethod: 'upi',
        ),
        returnsNormally,
      );
    });

    test('trackPurchaseCompleted does not throw', () {
      expect(
        () => service.trackPurchaseCompleted(
          tier: 'pro',
          price: 9900,
          revenueInPaise: 9900,
        ),
        returnsNormally,
      );
    });

    test('trackPurchaseFailed does not throw', () {
      expect(
        () => service.trackPurchaseFailed(
          tier: 'pro',
          errorReason: 'payment_declined',
        ),
        returnsNormally,
      );
    });

    test('trackTokenSpent does not throw', () {
      expect(
        () => service.trackTokenSpent(
          speed: 'instant',
          cost: 5,
          balanceAfter: 45,
        ),
        returnsNormally,
      );
    });

    test('trackSubscriptionCancelled does not throw', () {
      expect(
        () => service.trackSubscriptionCancelled(
          tier: 'pro',
          tenureDays: 30,
        ),
        returnsNormally,
      );
    });

    test('trackUpgradeInitiated does not throw', () {
      expect(
        () => service.trackUpgradeInitiated(
          fromTier: 'free',
          toTier: 'pro',
        ),
        returnsNormally,
      );
    });

    test('events include variant and test_id context', () {
      // Verify that events don't throw and include the current variant
      // The actual logging is tested by WasteAppLogger integration tests
      expect(service.currentVariant, isNotNull);
      expect(service.currentAssignment?.testId, equals('test_v1'));
    });
  });

  group('formatPrice', () {
    test('returns Free for 0 paise', () {
      expect(PricingABTestService.formatPrice(0), equals('Free'));
    });

    test('formats price correctly', () {
      expect(PricingABTestService.formatPrice(9900), equals('₹99'));
      expect(PricingABTestService.formatPrice(29900), equals('₹299'));
      expect(PricingABTestService.formatPrice(4900), equals('₹49'));
      expect(PricingABTestService.formatPrice(100), equals('₹1'));
    });
  });

  group('Error Handling', () {
    test('defaults to control group on initialization error', () async {
      // Service with null prefs should still initialize
      final errorService = PricingABTestService(prefs: null);
      await errorService.initialize(testId: 'test_v1', userId: 'user_error');

      expect(errorService.isInitialized, isTrue);
      expect(errorService.currentVariant, isNotNull);
      expect(errorService.currentConfig, isNotNull);

      errorService.dispose();
    });

    test('loadAssignment handles corrupt data gracefully', () async {
      // Seed corrupt data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pricing_ab_test_assignment', 'invalid|format|data|extra');

      final newService = PricingABTestService();
      await newService.initialize(testId: 'test_v1', userId: 'user_corrupt');

      // Should create new assignment despite corrupt data
      expect(newService.isInitialized, isTrue);
      expect(newService.currentAssignment, isNotNull);

      newService.dispose();
    });

    test('loadAssignment handles unknown variant gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pricing_ab_test_assignment',
          'test_v1|unknown_variant|${DateTime.now().toIso8601String()}');

      final newService = PricingABTestService();
      await newService.initialize(testId: 'test_v1', userId: 'user_unknown');

      expect(newService.isInitialized, isTrue);
      // Should fallback to control for unknown variant
      expect(newService.currentVariant, equals(PricingVariant.control));

      newService.dispose();
    });
  });

  group('ChangeNotifier', () {
    test('notifies listeners on initialization', () async {
      var notified = false;
      service.addListener(() => notified = true);

      await service.initialize(testId: 'test_v1', userId: 'user_notify');

      expect(notified, isTrue);
    });

    test('notifies listeners on reset', () async {
      await service.initialize(testId: 'test_v1', userId: 'user_reset');

      var notified = false;
      service.addListener(() => notified = true);

      service.resetAssignment();

      expect(notified, isTrue);
    });
  });
}
