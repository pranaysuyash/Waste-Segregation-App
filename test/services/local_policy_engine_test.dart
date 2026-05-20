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
      expect(decision.rulePack!.categories, contains('dry_waste'));
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
      expect(decision.classification, equals(baseClassification));
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
  });
}
