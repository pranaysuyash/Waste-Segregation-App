import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/config/monetization_ai_config_contract.dart';

void main() {
  group('MonetizationAiConfigKeys', () {
    test('defaultRemoteConfigValues keeps canonical and legacy keys aligned', () {
      final defaults = MonetizationAiConfigKeys.defaultRemoteConfigValues();

      expect(
        defaults[MonetizationAiConfigKeys.backendRequiredRelease],
        defaults[MonetizationAiConfigKeys.backendRequiredReleaseLegacy],
      );
      expect(
        defaults[MonetizationAiConfigKeys.freeDailyScanLimit],
        defaults[MonetizationAiConfigKeys.freeDailyScanLimitLegacy],
      );
      expect(
        defaults[MonetizationAiConfigKeys.classifyImageTokenCost],
        defaults[MonetizationAiConfigKeys.classifyImageTokenCostLegacy],
      );
      expect(
        defaults[MonetizationAiConfigKeys.classifyImagePremiumDiscountPercent],
        defaults[
            MonetizationAiConfigKeys.classifyImagePremiumDiscountPercentLegacy],
      );
    });

    test('readInt prefers canonical key over legacy alias', () {
      final values = <String, Object?>{
        MonetizationAiConfigKeys.freeDailyScanLimit: '9',
        MonetizationAiConfigKeys.freeDailyScanLimitLegacy: '3',
      };

      final result = MonetizationAiConfigKeys.readInt(
        values,
        MonetizationAiConfigKeys.freeDailyScanLimit,
        defaultValue: 5,
      );

      expect(result, 9);
    });

    test('readInt falls back to legacy alias and clamps bounds', () {
      final values = <String, Object?>{
        MonetizationAiConfigKeys.classifyImageTokenCostLegacy: '-20',
      };

      final result = MonetizationAiConfigKeys.readInt(
        values,
        MonetizationAiConfigKeys.classifyImageTokenCost,
        defaultValue: 5,
        min: 1,
        max: 200,
      );

      expect(result, 1);
    });

    test('readBool accepts bool/string/num and falls back safely', () {
      expect(
        MonetizationAiConfigKeys.readBool(
          {MonetizationAiConfigKeys.backendRequiredRelease: true},
          MonetizationAiConfigKeys.backendRequiredRelease,
          defaultValue: false,
        ),
        true,
      );

      expect(
        MonetizationAiConfigKeys.readBool(
          {MonetizationAiConfigKeys.backendRequiredRelease: 'false'},
          MonetizationAiConfigKeys.backendRequiredRelease,
          defaultValue: true,
        ),
        false,
      );

      expect(
        MonetizationAiConfigKeys.readBool(
          {MonetizationAiConfigKeys.backendRequiredReleaseLegacy: 1},
          MonetizationAiConfigKeys.backendRequiredRelease,
          defaultValue: false,
        ),
        true,
      );

      expect(
        MonetizationAiConfigKeys.readBool(
          {MonetizationAiConfigKeys.backendRequiredRelease: 'garbage'},
          MonetizationAiConfigKeys.backendRequiredRelease,
          defaultValue: true,
        ),
        true,
      );
    });
  });
}
