import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';

void main() {
  group('LocalPolicyEngine', () {
    late LocalPolicyEngine engine;
    late WasteClassification baseClassification;

    setUpAll(() {
      LocalGuidelinesManager.initializeDefaultPlugins();
    });

    setUp(() {
      engine = const LocalPolicyEngine();
      baseClassification = WasteClassification(
        itemName: 'AA Battery',
        category: 'Hazardous Waste',
        subcategory: 'Battery',
        explanation: 'Battery requires special disposal',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Special disposal facility',
          steps: ['Do not mix with regular waste'],
          hasUrgentTimeframe: true,
        ),
        region: 'Bangalore, IN',
        visualFeatures: const ['battery', 'metal contact'],
        alternatives: const [],
        requiresSpecialDisposal: true,
        confidence: 0.95,
      );
    });

    test('applies policy for supported regions', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.pluginId, equals('bbmp_bangalore'));
      expect(decision.authorityName, equals('BBMP'));
      expect(decision.guidelinesVersion, startsWith('BBMP-'));
      expect(decision.rulePackId, contains('bbmp_bangalore:BBMP-'));
      expect(decision.rulePack, isNotNull);
      expect(decision.rulePack!.rules, isNotEmpty);
      expect(
        decision.rulePack!.rules.any(
          (rule) => rule.ruleId == 'bbmp_hazardous_special_disposal',
        ),
        isTrue,
      );
      expect(decision.evaluatedAt, isA<DateTime>());
      expect(decision.classification.localGuidelinesVersion, isNotNull);
      expect(decision.classification.localRegulations, isNotEmpty);
      expect(
        decision.complianceStatus,
        isIn(<String>['compliant', 'requires_attention', 'violation']),
      );
    });

    test('returns unchanged classification for unsupported regions', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Unknown City',
      );

      expect(decision.policyApplied, isFalse);
      expect(decision.pluginId, isNull);
      expect(decision.rulePack, isNull);
      expect(decision.complianceStatus, isNull);
      expect(decision.evaluatedAt, isA<DateTime>());
    });

    test('rule-driven evaluator marks hazardous item without special disposal',
        () async {
      final risky = baseClassification.copyWith(
        requiresSpecialDisposal: false,
      );

      final decision = await engine.applyPolicy(
        classification: risky,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.complianceStatus, equals('violation'));
      expect(
        decision.violations
            .any((v) => v.contains('bbmp_hazardous_special_disposal')),
        isTrue,
      );
    });

    test('safetyOverrideAlways triggers regardless of ML flags', () async {
      final item = baseClassification.copyWith(
        itemName: 'Motor Oil',
        requiresSpecialDisposal: false,
        confidence: 0.95,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(
        decision.violations
            .any((v) => v.contains('bbmp_hazardous_safety_override')),
        isTrue,
      );
    });

    test('confidence gating demotes violations to warnings below threshold',
        () async {
      final item = baseClassification.copyWith(
        itemName: 'Motor Oil',
        requiresSpecialDisposal: false,
        confidence: 0.60,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.complianceStatus, equals('requires_attention'));
      expect(
        decision.warnings
            .any((v) => v.contains('bbmp_hazardous_special_disposal')),
        isTrue,
      );
    });

    test(
        'confidence gating keeps safetyOverrideAlways as violation at ≥0.70',
        () async {
      final item = baseClassification.copyWith(
        itemName: 'Motor Oil',
        requiresSpecialDisposal: false,
        confidence: 0.75,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(
        decision.violations
            .any((v) => v.contains('bbmp_hazardous_safety_override')),
        isTrue,
      );
    });

    test('confidence gating demotes safetyOverrideAlways to warning at <0.70',
        () async {
      final item = baseClassification.copyWith(
        itemName: 'Motor Oil',
        requiresSpecialDisposal: false,
        confidence: 0.60,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(
        decision.warnings
            .any((v) => v.contains('bbmp_hazardous_safety_override')),
        isTrue,
      );
    });

    test('applies policy for Pune region', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Pune, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.pluginId, equals('pmc_pune'));
      expect(decision.authorityName, equals('Pune Municipal Corporation'));
    });

    test('applies policy for Hyderabad region', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Hyderabad, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.pluginId, equals('ghmc_hyderabad'));
    });

    test('applies policy for Chennai region', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Chennai, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.pluginId, equals('gcc_chennai'));
    });

    test('applies policy for Kolkata region', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Kolkata, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.pluginId, equals('kmc_kolkata'));
    });

    test('applies policy for Ahmedabad', () async {
      final d = await engine.applyPolicy(classification: baseClassification, region: 'Ahmedabad, IN');
      expect(d.policyApplied, isTrue);
      expect(d.pluginId, equals('amc_ahmedabad'));
    });

    test('applies policy for Indore', () async {
      final d = await engine.applyPolicy(classification: baseClassification, region: 'Indore, IN');
      expect(d.policyApplied, isTrue);
      expect(d.pluginId, equals('imc_indore'));
    });

    test('applies policy for Chandigarh', () async {
      final d = await engine.applyPolicy(classification: baseClassification, region: 'Chandigarh, IN');
      expect(d.policyApplied, isTrue);
      expect(d.pluginId, equals('mcc_chandigarh'));
    });

    test('applies policy for all 17 registered cities', () async {
      final cities = [
        ('Bangalore, IN', 'bbmp_bangalore'),
        ('Mumbai, IN', 'bmc_mumbai'),
        ('Delhi, IN', 'mcd_delhi'),
        ('Pune, IN', 'pmc_pune'),
        ('Hyderabad, IN', 'ghmc_hyderabad'),
        ('Chennai, IN', 'gcc_chennai'),
        ('Kolkata, IN', 'kmc_kolkata'),
        ('Ahmedabad, IN', 'amc_ahmedabad'),
        ('Surat, IN', 'smc_surat'),
        ('Jaipur, IN', 'jmc_jaipur'),
        ('Lucknow, IN', 'lmc_lucknow'),
        ('Nagpur, IN', 'nmc_nagpur'),
        ('Indore, IN', 'imc_indore'),
        ('Bhopal, IN', 'bmc_bhopal'),
        ('Coimbatore, IN', 'ccmc_coimbatore'),
        ('Kochi, IN', 'cochin_kochi'),
        ('Chandigarh, IN', 'mcc_chandigarh'),
      ];
      for (final (region, expectedId) in cities) {
        final d = await engine.applyPolicy(classification: baseClassification, region: region);
        expect(d.policyApplied, isTrue, reason: '$region should resolve');
        expect(d.pluginId, equals(expectedId), reason: '$region should map to $expectedId');
        expect(d.rulePack, isNotNull, reason: '$region should have a rule pack');
        expect(d.rulePack!.rules, isNotEmpty, reason: '$region should have rules');
      }
    });

    test('provenance fields present in decision with high confidence', () async {
      final decision = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Bangalore, IN',
      );

      expect(decision.pluginId, isNotNull);
      expect(decision.guidelinesVersion, isNotNull);
      expect(decision.rulePackId, isNotNull);
      expect(decision.confidenceGated, isFalse);
    });

    test('confidenceGated is true when confidence < 0.70', () async {
      final lowConf = baseClassification.copyWith(confidence: 0.50);

      final decision = await engine.applyPolicy(
        classification: lowConf,
        region: 'Bangalore, IN',
      );

      expect(decision.confidenceGated, isTrue);
    });
  });
}
