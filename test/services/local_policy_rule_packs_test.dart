import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_policy_rule_packs.dart';

void main() {
  group('LocalPolicyRulePackRegistry', () {
    const registry = LocalPolicyRulePackRegistry();

    test('returns BBMP rule set', () {
      final pack = registry.getPackForPlugin('bbmp_bangalore');
      final rules = pack.rules;

      expect(rules, isNotEmpty);
      expect(pack.governanceStage, equals('production'));
      expect(
        rules.any((rule) => rule.ruleId == 'bbmp_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('returns empty rule set for unknown plugin', () {
      final pack = registry.getPackForPlugin('unknown_plugin');
      expect(pack.rules, isEmpty);
      expect(pack.governanceStage, equals('draft'));
    });
  });
}
