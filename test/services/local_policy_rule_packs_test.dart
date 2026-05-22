import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_policy_rule_packs.dart';

void main() {
  group('LocalPolicyRulePackRegistry', () {
    const registry = LocalPolicyRulePackRegistry();

    test('BBMP rule set is production stage', () {
      final pack = registry.getPackForPlugin('bbmp_bangalore');
      expect(pack.rules, isNotEmpty);
      expect(pack.governanceStage, equals('production'));
    });

    test('all metro pilots are pilot stage', () {
      for (final id in ['bmc_mumbai', 'mcd_delhi', 'pmc_pune', 'ghmc_hyderabad', 'gcc_chennai', 'kmc_kolkata']) {
        final pack = registry.getPackForPlugin(id);
        expect(pack.rules, isNotEmpty, reason: '$id should have rules');
        expect(pack.governanceStage, equals('pilot'), reason: '$id should be pilot');
      }
    });

    test('all tier-2 cities are draft stage', () {
      for (final id in ['amc_ahmedabad', 'smc_surat', 'jmc_jaipur', 'lmc_lucknow',
          'nmc_nagpur', 'imc_indore', 'bmc_bhopal', 'ccmc_coimbatore',
          'cochin_kochi', 'mcc_chandigarh']) {
        final pack = registry.getPackForPlugin(id);
        expect(pack.rules, isNotEmpty, reason: '$id should have rules');
        expect(pack.governanceStage, equals('draft'), reason: '$id should be draft');
      }
    });

    test('every city pack has safety override rules', () {
      final allIds = [
        'bbmp_bangalore', 'bmc_mumbai', 'mcd_delhi', 'pmc_pune',
        'ghmc_hyderabad', 'gcc_chennai', 'kmc_kolkata',
        'amc_ahmedabad', 'smc_surat', 'jmc_jaipur', 'lmc_lucknow',
        'nmc_nagpur', 'imc_indore', 'bmc_bhopal', 'ccmc_coimbatore',
        'cochin_kochi', 'mcc_chandigarh',
      ];
      for (final id in allIds) {
        final pack = registry.getPackForPlugin(id);
        expect(
          pack.rules.where((r) => r.checkType.name == 'safetyOverrideAlways'),
          hasLength(2),
          reason: '$id should have exactly 2 safety override rules (hazardous + medical)',
        );
      }
    });

    test('returns empty rule set for unknown plugin', () {
      final pack = registry.getPackForPlugin('unknown_plugin');
      expect(pack.rules, isEmpty);
      expect(pack.governanceStage, equals('draft'));
    });

    test('Indore has strict segregation rule', () {
      final pack = registry.getPackForPlugin('imc_indore');
      expect(
        pack.rules.any((r) => r.ruleId == 'imc_wet_segregation'),
        isTrue,
      );
    });

    test('Chandigarh has wet compostable rule', () {
      final pack = registry.getPackForPlugin('mcc_chandigarh');
      expect(
        pack.rules.any((r) => r.ruleId == 'mcc_wet_compostable'),
        isTrue,
      );
    });
  });
}
