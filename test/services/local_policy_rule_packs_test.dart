import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_policy_rule_packs.dart';

void main() {
  group('LocalPolicyRulePackRegistry', () {
    const registry = LocalPolicyRulePackRegistry();

    test('returns BBMP rule set', () {
      final rules = registry.getRulesForPlugin('bbmp_bangalore');

      expect(rules, isNotEmpty);
      expect(
        rules.any((rule) => rule.ruleId == 'bbmp_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('returns empty rule set for unknown plugin', () {
      final rules = registry.getRulesForPlugin('unknown_plugin');
      expect(rules, isEmpty);
    });
  });
}
