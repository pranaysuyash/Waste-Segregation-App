import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pricing_ab_test_service.dart';

/// Provider for PricingABTestService
final pricingABTestServiceProvider =
    StateNotifierProvider<PricingABTestServiceNotifier, PricingABTestState>(
        (ref) {
  return PricingABTestServiceNotifier();
});

/// State for PricingABTestService
class PricingABTestState {
  const PricingABTestState({
    this.isInitialized = false,
    this.variant,
    this.config,
    this.assignment,
  });

  final bool isInitialized;
  final PricingVariant? variant;
  final PricingVariantConfig? config;
  final PricingTestAssignment? assignment;

  bool get isControlGroup => variant == PricingVariant.control;
  bool get isEnforcementEnabled => config?.enforcementEnabled ?? false;
  bool get shouldShowPricing => config?.showPricing ?? false;
  List<PricingTier> get tiers => config?.tiers ?? [];
}

/// Notifier for PricingABTestService
class PricingABTestServiceNotifier
    extends StateNotifier<PricingABTestState> {
  PricingABTestServiceNotifier() : super(const PricingABTestState()) {
    _service = PricingABTestService();
    _service.addListener(_onServiceChanged);
  }

  late PricingABTestService _service;

  PricingABTestService get service => _service;

  void _onServiceChanged() {
    state = PricingABTestState(
      isInitialized: _service.isInitialized,
      variant: _service.currentVariant,
      config: _service.currentConfig,
      assignment: _service.currentAssignment,
    );
  }

  /// Initialize the service
  Future<void> initialize({String testId = 'pricing_ab_v1'}) async {
    await _service.initialize(testId: testId);
  }

  /// Track pricing screen viewed
  void trackPricingScreenViewed({required String tierShown}) {
    _service.trackPricingScreenViewed(tierShown: tierShown);
  }

  /// Track pricing tier selected
  void trackPricingTierSelected({
    required String tier,
    required int price,
  }) {
    _service.trackPricingTierSelected(tier: tier, price: price);
  }

  /// Track purchase initiated
  void trackPurchaseInitiated({
    required String tier,
    required int price,
    required String paymentMethod,
  }) {
    _service.trackPurchaseInitiated(
      tier: tier,
      price: price,
      paymentMethod: paymentMethod,
    );
  }

  /// Track purchase completed
  void trackPurchaseCompleted({
    required String tier,
    required int price,
    required int revenueInPaise,
  }) {
    _service.trackPurchaseCompleted(
      tier: tier,
      price: price,
      revenueInPaise: revenueInPaise,
    );
  }

  /// Track purchase failed
  void trackPurchaseFailed({
    required String tier,
    required String errorReason,
  }) {
    _service.trackPurchaseFailed(
      tier: tier,
      errorReason: errorReason,
    );
  }

  /// Track token spent
  void trackTokenSpent({
    required String speed,
    required int cost,
    required int balanceAfter,
  }) {
    _service.trackTokenSpent(
      speed: speed,
      cost: cost,
      balanceAfter: balanceAfter,
    );
  }

  /// Track subscription cancelled
  void trackSubscriptionCancelled({
    required String tier,
    required int tenureDays,
  }) {
    _service.trackSubscriptionCancelled(
      tier: tier,
      tenureDays: tenureDays,
    );
  }

  /// Track upgrade initiated
  void trackUpgradeInitiated({
    required String fromTier,
    required String toTier,
  }) {
    _service.trackUpgradeInitiated(
      fromTier: fromTier,
      toTier: toTier,
    );
  }

  /// Reset assignment (for testing)
  void resetAssignment() {
    _service.resetAssignment();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    super.dispose();
  }
}
