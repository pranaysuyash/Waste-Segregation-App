class MonetizationAiConfigKeys {
  MonetizationAiConfigKeys._();

  // Canonical keys (shared semantic contract across client/backend).
  static const String backendRequiredRelease =
      'ai.routing.backend_required_release';
  static const String freeDailyScanLimit =
      'monetization.free_daily_scan_limit';
  static const String classifyImageTokenCost =
      'monetization.classify_image_token_cost';
  static const String classifyImagePremiumDiscountPercent =
      'monetization.classify_image_premium_discount_percent';

  // Legacy keys kept for migration compatibility.
  static const String backendRequiredReleaseLegacy =
      'use_backend_classification';
  static const String freeDailyScanLimitLegacy =
      'daily_free_classifications';
  static const String classifyImageTokenCostLegacy =
      'classify_image_token_cost';
  static const String classifyImagePremiumDiscountPercentLegacy =
      'classify_image_premium_discount_percent';

  static const Map<String, List<String>> aliases = {
    backendRequiredRelease: [backendRequiredReleaseLegacy],
    freeDailyScanLimit: [freeDailyScanLimitLegacy],
    classifyImageTokenCost: [classifyImageTokenCostLegacy],
    classifyImagePremiumDiscountPercent: [
      classifyImagePremiumDiscountPercentLegacy,
    ],
  };

  static Map<String, dynamic> defaultRemoteConfigValues() {
    const backendRequired = true;
    const freeLimit = 5;
    const tokenCost = 5;
    const premiumDiscount = 50;

    return {
      backendRequiredRelease: backendRequired,
      backendRequiredReleaseLegacy: backendRequired,
      freeDailyScanLimit: freeLimit,
      freeDailyScanLimitLegacy: freeLimit,
      classifyImageTokenCost: tokenCost,
      classifyImageTokenCostLegacy: tokenCost,
      classifyImagePremiumDiscountPercent: premiumDiscount,
      classifyImagePremiumDiscountPercentLegacy: premiumDiscount,
    };
  }

  static bool readBool(
    Map<String, Object?> values,
    String canonicalKey, {
    required bool defaultValue,
  }) {
    final dynamic raw = _readRaw(values, canonicalKey);
    if (raw is bool) return raw;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (raw is num) return raw != 0;
    return defaultValue;
  }

  static int readInt(
    Map<String, Object?> values,
    String canonicalKey, {
    required int defaultValue,
    int? min,
    int? max,
  }) {
    final dynamic raw = _readRaw(values, canonicalKey);
    int value;

    if (raw is int) {
      value = raw;
    } else if (raw is num) {
      value = raw.floor();
    } else if (raw is String) {
      value = int.tryParse(raw.trim()) ?? defaultValue;
    } else {
      value = defaultValue;
    }

    if (min != null && value < min) value = min;
    if (max != null && value > max) value = max;
    return value;
  }

  static dynamic _readRaw(Map<String, Object?> values, String canonicalKey) {
    if (values.containsKey(canonicalKey)) {
      return values[canonicalKey];
    }
    final keyAliases = aliases[canonicalKey] ?? const [];
    for (final alias in keyAliases) {
      if (values.containsKey(alias)) {
        return values[alias];
      }
    }
    return null;
  }
}
