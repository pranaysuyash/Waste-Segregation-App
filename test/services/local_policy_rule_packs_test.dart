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

    test('BBMP pack includes safety override rules', () {
      final pack = registry.getPackForPlugin('bbmp_bangalore');
      expect(
        pack.rules
            .any((rule) => rule.ruleId == 'bbmp_hazardous_safety_override'),
        isTrue,
      );
      expect(
        pack.rules
            .any((rule) => rule.ruleId == 'bbmp_medical_safety_override'),
        isTrue,
      );
    });

    test('returns empty rule set for unknown plugin', () {
      final pack = registry.getPackForPlugin('unknown_plugin');
      expect(pack.rules, isEmpty);
      expect(pack.governanceStage, equals('draft'));
    });

    test('BMC Mumbai rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('bmc_mumbai');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
    });

    test('MCD Delhi rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('mcd_delhi');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
    });

    test('PMC Pune rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('pmc_pune');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
      expect(
        pack.rules.any((rule) => rule.ruleId == 'pmc_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('GHMC Hyderabad rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('ghmc_hyderabad');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
      expect(
        pack.rules.any((rule) => rule.ruleId == 'ghmc_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('GCC Chennai rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('gcc_chennai');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
      expect(
        pack.rules.any((rule) => rule.ruleId == 'gcc_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('KMC Kolkata rule set is pilot stage', () {
      final pack = registry.getPackForPlugin('kmc_kolkata');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('pilot'));
      expect(
        pack.rules.any((rule) => rule.ruleId == 'kmc_hazardous_special_disposal'),
        isTrue,
      );
    });

    test('every pack has safety override rules for hazardous and medical', () {
      for (final pluginId in [
        'bbmp_bangalore',
        'bmc_mumbai',
        'mcd_delhi',
        'pmc_pune',
        'ghmc_hyderabad',
        'gcc_chennai',
        'kmc_kolkata',
      ]) {
        final pack = registry.getPackForPlugin(pluginId);
        expect(
          pack.rules.any((r) => r.ruleId.contains('safety_override')),
          isTrue,
          reason: '$pluginId should have safety override rules',
        );
      }
    });
  });
}
