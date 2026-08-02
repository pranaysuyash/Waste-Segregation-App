import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/waste_app_logger.dart';

/// Pricing A/B test variants
enum PricingVariant {
  control, // No pricing shown, enforcement off
  variantA, // Freemium + Token Economy
  variantB, // Freemium + Society Model
  variantC, // Token Economy (Refined)
}

/// Pricing tier configuration for each variant
class PricingTier {
  const PricingTier({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.tokenCost,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final int price; // Price in INR (paise * 100)
  final String period; // 'monthly', 'yearly', 'one_time'
  final List<String> features;
  final int? tokenCost; // For token-based variants
  final bool isPopular;
}

/// Pricing variant configuration
class PricingVariantConfig {
  const PricingVariantConfig({
    required this.variant,
    required this.name,
    required this.tiers,
    required this.enforcementEnabled,
    required this.showPricing,
    this.description,
  });

  final PricingVariant variant;
  final String name;
  final List<PricingTier> tiers;
  final bool enforcementEnabled;
  final bool showPricing;
  final String? description;
}

/// User assignment to a pricing test
class PricingTestAssignment {
  const PricingTestAssignment({
    required this.userId,
    required this.variant,
    required this.assignedAt,
    required this.testId,
  });

  final String userId;
  final PricingVariant variant;
  final DateTime assignedAt;
  final String testId;
}

/// Pricing A/B test service
///
/// Manages variant assignment, configuration, and tracking for pricing tests.
/// Integrates with Firebase Remote Config for dynamic configuration.
class PricingABTestService extends ChangeNotifier {
  PricingABTestService({
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  SharedPreferences? _prefs;

  // Storage keys
  static const String _assignmentKey = 'pricing_ab_test_assignment';

  // Current state
  PricingTestAssignment? _currentAssignment;
  PricingVariantConfig? _currentConfig;
  bool _initialized = false;

  // Getters
  PricingTestAssignment? get currentAssignment => _currentAssignment;
  PricingVariantConfig? get currentConfig => _currentConfig;
  bool get isInitialized => _initialized;
  PricingVariant get currentVariant =>
      _currentAssignment?.variant ?? PricingVariant.control;
  bool get isControlGroup =>
      _currentAssignment?.variant == PricingVariant.control;
  bool get isEnforcementEnabled =>
      _currentConfig?.enforcementEnabled ?? false;
  bool get shouldShowPricing => _currentConfig?.showPricing ?? false;

  /// Initialize the service and load/create assignment
  Future<void> initialize({
    String testId = 'pricing_ab_v1',
    String? userId,
  }) async {
    if (_initialized) return;

    try {
      _prefs = _prefs ?? await SharedPreferences.getInstance();

      // Try to load existing assignment
      final existingAssignment = _loadAssignment();

      if (existingAssignment != null &&
          existingAssignment.testId == testId) {
        _currentAssignment = existingAssignment;
        _currentConfig = _getConfigForVariant(existingAssignment.variant);
        _initialized = true;
        notifyListeners();

        WasteAppLogger.info(
          'Pricing AB test loaded existing assignment',
          context: {
            'test_id': testId,
            'variant': existingAssignment.variant.name,
            'assigned_at': existingAssignment.assignedAt.toIso8601String(),
          },
        );
        return;
      }

      // Create new assignment with deterministic hash
      final variant = _assignVariant(testId, userId: userId);
      _currentAssignment = PricingTestAssignment(
        userId: userId ?? '',
        variant: variant,
        assignedAt: DateTime.now(),
        testId: testId,
      );
      _currentConfig = _getConfigForVariant(variant);

      // Save assignment
      _saveAssignment(_currentAssignment!);

      _initialized = true;
      notifyListeners();

      WasteAppLogger.info(
        'Pricing AB test assigned new variant',
        context: {
          'test_id': testId,
          'user_id': userId,
          'variant': variant.name,
          'enforcement': _currentConfig?.enforcementEnabled,
          'show_pricing': _currentConfig?.showPricing,
        },
      );
    } catch (e, s) {
      WasteAppLogger.severe(
        'Failed to initialize pricing AB test',
        error: e,
        stackTrace: s,
      );
      // Default to control group on error
      _currentAssignment = PricingTestAssignment(
        userId: userId ?? '',
        variant: PricingVariant.control,
        assignedAt: DateTime.now(),
        testId: testId,
      );
      _currentConfig = _getConfigForVariant(PricingVariant.control);
      _initialized = true;
      notifyListeners();
    }
  }

  /// Assign user to variant using deterministic hash
  PricingVariant _assignVariant(String testId, {String? userId}) {
    // Use deterministic hash based on testId + userId for reproducible assignment
    final identifier = userId ?? testId;
    final hash = identifier.hashCode;
    final mod = (hash % 100).abs();

    // 10% control, 30% each variant
    if (mod < 10) return PricingVariant.control;
    if (mod < 40) return PricingVariant.variantA;
    if (mod < 70) return PricingVariant.variantB;
    return PricingVariant.variantC;
  }

  /// Get configuration for a variant
  PricingVariantConfig _getConfigForVariant(PricingVariant variant) {
    switch (variant) {
      case PricingVariant.control:
        return const PricingVariantConfig(
          variant: PricingVariant.control,
          name: 'Control (No Pricing)',
          tiers: [],
          enforcementEnabled: false,
          showPricing: false,
          description: 'No pricing shown, enforcement disabled',
        );

      case PricingVariant.variantA:
        return const PricingVariantConfig(
          variant: PricingVariant.variantA,
          name: 'Freemium + Token Economy',
          tiers: [
            PricingTier(
              id: 'free',
              name: 'Free',
              price: 0,
              period: 'monthly',
              features: [
                '10 classifications/day',
                'Basic disposal info',
                'Community feed',
              ],
            ),
            PricingTier(
              id: 'pro',
              name: 'Pro',
              price: 9900, // ₹99 in paise
              period: 'monthly',
              features: [
                'Unlimited classifications',
                'Advanced analytics',
                'Priority support',
              ],
              isPopular: true,
            ),
            PricingTier(
              id: 'premium',
              name: 'Premium',
              price: 29900, // ₹299 in paise
              period: 'monthly',
              features: [
                'Everything in Pro',
                'Family sharing',
                'Society dashboard',
                'EPR compliance',
              ],
            ),
          ],
          enforcementEnabled: true,
          showPricing: true,
          description: 'Subscription tiers with token costs',
        );

      case PricingVariant.variantB:
        return const PricingVariantConfig(
          variant: PricingVariant.variantB,
          name: 'Freemium + Society Model',
          tiers: [
            PricingTier(
              id: 'individual_free',
              name: 'Individual Free',
              price: 0,
              period: 'monthly',
              features: [
                'Basic classification',
                'Limited history',
              ],
            ),
            PricingTier(
              id: 'individual_pro',
              name: 'Individual Pro',
              price: 9900, // ₹99 in paise
              period: 'monthly',
              features: [
                'Unlimited classifications',
                'Full history',
              ],
              isPopular: true,
            ),
            PricingTier(
              id: 'society_basic',
              name: 'Society Basic',
              price: 49900, // ₹499 in paise
              period: 'monthly',
              features: [
                'Up to 100 households',
                'Society leaderboard',
                'Basic analytics',
              ],
            ),
            PricingTier(
              id: 'society_premium',
              name: 'Society Premium',
              price: 99900, // ₹999 in paise
              period: 'monthly',
              features: [
                'Unlimited households',
                'Advanced analytics',
                'EPR compliance',
              ],
            ),
          ],
          enforcementEnabled: true,
          showPricing: true,
          description: 'Individual + Society subscription tiers',
        );

      case PricingVariant.variantC:
        return const PricingVariantConfig(
          variant: PricingVariant.variantC,
          name: 'Token Economy (Refined)',
          tiers: [
            PricingTier(
              id: 'starter',
              name: 'Starter',
              price: 4900, // ₹49 in paise
              period: 'one_time',
              features: [
                '50 tokens',
                '₹0.98 per token',
              ],
              tokenCost: 50,
            ),
            PricingTier(
              id: 'value',
              name: 'Value',
              price: 14900, // ₹149 in paise
              period: 'one_time',
              features: [
                '180 tokens',
                '₹0.83 per token',
              ],
              tokenCost: 180,
              isPopular: true,
            ),
            PricingTier(
              id: 'premium',
              name: 'Premium',
              price: 29900, // ₹299 in paise
              period: 'one_time',
              features: [
                '400 tokens',
                '₹0.75 per token',
              ],
              tokenCost: 400,
            ),
            PricingTier(
              id: 'subscription',
              name: 'Subscription',
              price: 9900, // ₹99 in paise
              period: 'monthly',
              features: [
                '200 tokens/month',
                '2x earning rate',
              ],
              tokenCost: 200,
            ),
          ],
          enforcementEnabled: true,
          showPricing: true,
          description: 'Token packages with subscription option',
        );
    }
  }

  /// Load assignment from storage
  PricingTestAssignment? _loadAssignment() {
    try {
      final assignmentJson = _prefs?.getString(_assignmentKey);
      if (assignmentJson == null) return null;

      // Parse simple format: testId|variant|assignedAt
      final parts = assignmentJson.split('|');
      if (parts.length != 3) return null;

      final variant = PricingVariant.values.firstWhere(
        (v) => v.name == parts[1],
        orElse: () => PricingVariant.control,
      );

      return PricingTestAssignment(
        userId: '',
        variant: variant,
        assignedAt: DateTime.parse(parts[2]),
        testId: parts[0],
      );
    } catch (e) {
      return null;
    }
  }

  /// Save assignment to storage
  void _saveAssignment(PricingTestAssignment assignment) {
    try {
      final json =
          '${assignment.testId}|${assignment.variant.name}|${assignment.assignedAt.toIso8601String()}';
      _prefs?.setString(_assignmentKey, json);
    } catch (e) {
      WasteAppLogger.warning('Failed to save pricing AB test assignment', error: e);
    }
  }

  /// Track pricing screen viewed event
  void trackPricingScreenViewed({required String tierShown}) {
    WasteAppLogger.info(
      'Pricing AB test: screen viewed',
      context: {
        'event': 'pricing_screen_viewed',
        'variant': currentVariant.name,
        'tier_shown': tierShown,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track pricing tier selected event
  void trackPricingTierSelected({
    required String tier,
    required int price,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: tier selected',
      context: {
        'event': 'pricing_tier_selected',
        'variant': currentVariant.name,
        'tier': tier,
        'price': price,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track purchase initiated event
  void trackPurchaseInitiated({
    required String tier,
    required int price,
    required String paymentMethod,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: purchase initiated',
      context: {
        'event': 'purchase_initiated',
        'variant': currentVariant.name,
        'tier': tier,
        'price': price,
        'payment_method': paymentMethod,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track purchase completed event
  void trackPurchaseCompleted({
    required String tier,
    required int price,
    required int revenueInPaise,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: purchase completed',
      context: {
        'event': 'purchase_completed',
        'variant': currentVariant.name,
        'tier': tier,
        'price': price,
        'revenue_paise': revenueInPaise,
        'revenue_rupees': revenueInPaise / 100.0,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track purchase failed event
  void trackPurchaseFailed({
    required String tier,
    required String errorReason,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: purchase failed',
      context: {
        'event': 'purchase_failed',
        'variant': currentVariant.name,
        'tier': tier,
        'error_reason': errorReason,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track token spent event
  void trackTokenSpent({
    required String speed,
    required int cost,
    required int balanceAfter,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: token spent',
      context: {
        'event': 'token_spent',
        'variant': currentVariant.name,
        'speed': speed,
        'cost': cost,
        'balance_after': balanceAfter,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track subscription cancelled event
  void trackSubscriptionCancelled({
    required String tier,
    required int tenureDays,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: subscription cancelled',
      context: {
        'event': 'subscription_cancelled',
        'variant': currentVariant.name,
        'tier': tier,
        'tenure_days': tenureDays,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Track upgrade initiated event
  void trackUpgradeInitiated({
    required String fromTier,
    required String toTier,
  }) {
    WasteAppLogger.info(
      'Pricing AB test: upgrade initiated',
      context: {
        'event': 'upgrade_initiated',
        'variant': currentVariant.name,
        'from_tier': fromTier,
        'to_tier': toTier,
        'test_id': _currentAssignment?.testId,
      },
    );
  }

  /// Get formatted price string
  static String formatPrice(int priceInPaise) {
    if (priceInPaise == 0) return 'Free';
    final rupees = priceInPaise ~/ 100;
    return '₹$rupees';
  }

  /// Reset assignment (for testing)
  void resetAssignment() {
    _currentAssignment = null;
    _currentConfig = null;
    _initialized = false;
    _prefs?.remove(_assignmentKey);
    notifyListeners();
  }
}
