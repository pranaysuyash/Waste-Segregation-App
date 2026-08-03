import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';
import 'package:waste_segregation_app/services/society_policy_service.dart';
import 'package:waste_segregation_app/models/society_policy_override.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      super.noSuchMethod(
        Invocation.method(#collection, [path]),
        returnValue: MockCollectionReference<Map<String, dynamic>>(),
        returnValueForMissingStub:
            MockCollectionReference<Map<String, dynamic>>(),
      ) as CollectionReference<Map<String, dynamic>>;
}

class MockCollectionReference<T extends Object?> extends Mock
    implements CollectionReference<T> {
  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) => super.noSuchMethod(
        Invocation.method(#get, [options]),
        returnValue: Future.value(MockQuerySnapshot<T>()),
        returnValueForMissingStub: Future.value(MockQuerySnapshot<T>()),
      ) as Future<QuerySnapshot<T>>;
}

class MockQuerySnapshot<T> extends Mock implements QuerySnapshot<T> {
  @override
  List<QueryDocumentSnapshot<T>> get docs => [];
}

class _FakeSocietyPolicyService extends SocietyPolicyService {
  _FakeSocietyPolicyService(this.policyOverride)
      : super(firestore: MockFirebaseFirestore());

  final SocietyPolicyOverride? policyOverride;

  @override
  Future<SocietyPolicyOverride?> getSocietyPolicy(String societyId) async {
    return policyOverride;
  }
}

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
        subCategory: 'Battery',
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
      expect(decision.householdWasteStream, equals('special_care_waste'));
      expect(decision.sourceStatus, isNotEmpty);
      expect(decision.authorityStatus, isNotEmpty);
      expect(
        decision.classification.localRegulations?['collection_frequency'],
        isNotNull,
      );
      expect(
        decision.classification.localRegulations?['collection_time_window'],
        isNotNull,
      );
      expect(
        decision.classification.localRegulations?['policy_authority_status'],
        isNotNull,
      );
    });

    test('classifies legacy hazardous category into SWM special-care stream',
        () async {
      final decision = await engine.applyPolicy(
        classification:
            baseClassification.copyWith(category: 'Hazardous Waste'),
        region: 'Bangalore, IN',
      );
      expect(decision.householdWasteStream, equals('special_care_waste'));
    });

    test('maps wet and dry categories to stable stream keys', () async {
      final wet = await engine.applyPolicy(
        classification: baseClassification.copyWith(category: 'Wet Waste'),
        region: 'Bangalore, IN',
      );
      final dry = await engine.applyPolicy(
        classification: baseClassification.copyWith(category: 'Dry Waste'),
        region: 'Bangalore, IN',
      );

      expect(wet.householdWasteStream, equals('wet_waste'));
      expect(dry.householdWasteStream, equals('dry_waste'));
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

    test(
      'rule-driven evaluator marks hazardous item without special disposal',
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
          decision.violations.any(
            (v) => v.contains('bbmp_hazardous_special_disposal'),
          ),
          isTrue,
        );
      },
    );

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
        decision.violations.any(
          (v) => v.contains('bbmp_hazardous_safety_override'),
        ),
        isTrue,
      );
    });

    test('safety-critical violations remain violations at low confidence',
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
      expect(decision.complianceStatus, equals('violation'));
      expect(
        decision.violations.any(
          (v) => v.contains('bbmp_hazardous_special_disposal'),
        ),
        isTrue,
      );
      expect(
        decision.warnings.any(
          (v) => v.contains('bbmp_hazardous_special_disposal'),
        ),
        isFalse,
      );
    });

    test('low confidence degrades ordinary non-safety policy to warning-only',
        () async {
      final item = baseClassification.copyWith(
        itemName: 'Wet Waste Cup',
        explanation: 'Wet waste with removable packaging residue',
        category: 'Wet Waste',
        subCategory: 'Cup',
        visualFeatures: const ['cup', 'water', 'leaf'],
        isCompostable: false,
        requiresSpecialDisposal: false,
        disposalMethod: 'landfill',
        disposalInstructions: baseClassification.disposalInstructions.copyWith(
          primaryMethod: 'landfill',
        ),
        confidence: 0.60,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.complianceStatus, equals('requires_attention'));
      expect(decision.violations, isEmpty);
      expect(
        decision.warnings.any(
          (v) => v.contains(
              'Wet waste should not go to landfill - must be composted'),
        ),
        isTrue,
      );
      expect(
        decision.warnings,
        contains(
            'Low-confidence classification: municipal policy is conservative.'),
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
          decision.violations.any(
            (v) => v.contains('bbmp_hazardous_safety_override'),
          ),
          isTrue,
        );
      },
    );

    test('safety override remains active as violation at low confidence',
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
        decision.violations.any(
          (v) => v.contains('bbmp_hazardous_safety_override'),
        ),
        isTrue,
      );
      expect(
        decision.warnings.any(
          (v) => v.contains('bbmp_hazardous_safety_override'),
        ),
        isFalse,
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
      final d = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Ahmedabad, IN',
      );
      expect(d.policyApplied, isTrue);
      expect(d.pluginId, equals('amc_ahmedabad'));
    });

    test('applies policy for Indore', () async {
      final d = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Indore, IN',
      );
      expect(d.policyApplied, isTrue);
      expect(d.pluginId, equals('imc_indore'));
    });

    test('applies policy for Chandigarh', () async {
      final d = await engine.applyPolicy(
        classification: baseClassification,
        region: 'Chandigarh, IN',
      );
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
        final d = await engine.applyPolicy(
          classification: baseClassification,
          region: region,
        );
        expect(d.policyApplied, isTrue, reason: '$region should resolve');
        expect(
          d.pluginId,
          equals(expectedId),
          reason: '$region should map to $expectedId',
        );
        expect(
          d.rulePack,
          isNotNull,
          reason: '$region should have a rule pack',
        );
        expect(
          d.rulePack!.rules,
          isNotEmpty,
          reason: '$region should have rules',
        );
      }
    });

    test(
      'provenance fields present in decision with high confidence',
      () async {
        final decision = await engine.applyPolicy(
          classification: baseClassification,
          region: 'Bangalore, IN',
        );

        expect(decision.pluginId, isNotNull);
        expect(decision.guidelinesVersion, isNotNull);
        expect(decision.rulePackId, isNotNull);
        expect(decision.confidenceGated, isFalse);
      },
    );

    test('confidenceGated is true when confidence < 0.70', () async {
      final lowConf = baseClassification.copyWith(confidence: 0.50);

      final decision = await engine.applyPolicy(
        classification: lowConf,
        region: 'Bangalore, IN',
      );

      expect(decision.confidenceGated, isTrue);
    });

    test('policy still applies below 0.50 with conservative warnings',
        () async {
      final lowConf = baseClassification.copyWith(confidence: 0.49);

      final decision = await engine.applyPolicy(
        classification: lowConf,
        region: 'Bangalore, IN',
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.confidenceState, equals('warning_only'));
      expect(
        decision.warnings,
        contains(
          'Low-confidence classification: municipal policy is conservative.',
        ),
      );
      expect(decision.violations, isNotEmpty);
    });

    test('society override adds layer and stores society keys', () async {
      final override = SocietyPolicyOverride(
        societyId: 'sb_001',
        societyName: 'Green Habitat',
        basePluginId: 'bbmp_bangalore',
        overrides: [
          const RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.binColor,
            value: 'Blue Bin/Bag',
            description: 'Custom society bin color.',
          ),
        ],
      );

      final decision = await engine.applyPolicy(
        classification: baseClassification.copyWith(
          category: 'Dry Waste',
          subCategory: 'Bottle',
          requiresSpecialDisposal: false,
        ),
        region: 'Bangalore, IN',
        societyId: 'sb_001',
        societyPolicyService: _FakeSocietyPolicyService(override),
      );

      expect(decision.policyApplied, isTrue);
      expect(decision.societyId, equals('sb_001'));
      expect(decision.societyName, equals('Green Habitat'));
      expect(decision.societyOverrides, isNotEmpty);
      expect(decision.societyConflicts, isEmpty);
      expect(
        decision.classification.localRegulations?['society_bin_alias'],
        equals('Blue Bin/Bag'),
      );
    });

    test('low-confidence society overrides are skipped unless user confirms',
        () async {
      final override = SocietyPolicyOverride(
        societyId: 'sb_002',
        societyName: 'Low Confidence Society',
        basePluginId: 'bbmp_bangalore',
        overrides: const [
          RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.customInstruction,
            value: 'Use separate collection room.',
          ),
        ],
      );

      final skipped = await engine.applyPolicy(
        classification: baseClassification.copyWith(
          category: 'Dry Waste',
          subCategory: 'Bottle',
          requiresSpecialDisposal: false,
          confidence: 0.65,
          userConfirmed: false,
        ),
        region: 'Bangalore, IN',
        societyId: 'sb_002',
        societyPolicyService: _FakeSocietyPolicyService(override),
      );

      expect(skipped.societyOverrides, isEmpty);
      expect(
        skipped.classification.localRegulations?['society_custom_instructions'],
        isNull,
      );

      final applied = await engine.applyPolicy(
        classification: baseClassification.copyWith(
          category: 'Dry Waste',
          subCategory: 'Bottle',
          requiresSpecialDisposal: false,
          confidence: 0.65,
          userConfirmed: true,
        ),
        region: 'Bangalore, IN',
        societyId: 'sb_002',
        societyPolicyService: _FakeSocietyPolicyService(override),
      );

      expect(applied.societyOverrides, isNotEmpty);
      expect(
        applied.classification.localRegulations?['society_custom_instructions'],
        contains('Use separate collection room.'),
      );
    });

    test('dry + battery at low confidence remains safety violation', () async {
      final item = baseClassification.copyWith(
        itemName: 'AA Battery',
        category: 'Dry Waste',
        subCategory: 'Bottle',
        explanation: 'Dry battery in a bottle cap',
        visualFeatures: const ['dry', 'battery'],
        confidence: 0.60,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(decision.complianceStatus, equals('violation'));
      expect(
        decision.violations.any(
          (v) => v.contains('[safety_floor] Special-care handling is required'),
        ),
        isTrue,
      );
    });

    test('special care alias variants become safety critical', () async {
      final item = baseClassification.copyWith(
        itemName: 'Wipes',
        category: 'Special-Care waste',
        subCategory: 'Neon',
        explanation: 'Special care handling pack',
        visualFeatures: const ['soft-pack'],
        confidence: 0.55,
        requiresSpecialDisposal: false,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(
        decision.violations.any(
          (v) => v.contains('[safety_floor] Special-care handling is required'),
        ),
        isTrue,
      );
    });

    test('plural safety signals become safety critical', () async {
      final item = baseClassification.copyWith(
        itemName: 'Old Batteries',
        category: 'Dry Waste',
        subCategory: 'Electronics',
        explanation: 'Used batteries and other chemicals',
        visualFeatures: const ['batteries', 'chemicals'],
        confidence: 0.60,
        requiresSpecialDisposal: false,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(
        decision.violations.any(
          (v) => v.contains('[safety_floor] Special-care handling is required'),
        ),
        isTrue,
      );
    });

    test('safety alias plurals become safety critical', () async {
      final item = baseClassification.copyWith(
        itemName: 'Old Medicines',
        category: 'Dry Waste',
        subCategory: 'Household Items',
        explanation: 'Leftover medicines and glass ampoules with syringes',
        visualFeatures: const ['medicines', 'ampoules', 'syringes'],
        confidence: 0.60,
        requiresSpecialDisposal: false,
      );

      final decision = await engine.applyPolicy(
        classification: item,
        region: 'Bangalore, IN',
      );

      expect(
        decision.violations.any(
          (v) => v.contains('[safety_floor] Special-care handling is required'),
        ),
        isTrue,
      );
    });

    test('society conflicts do not mutate municipal guidance fields', () async {
      final baseline = await engine.applyPolicy(
        classification: baseClassification.copyWith(
          category: 'Dry Waste',
          subCategory: 'Bottle',
          requiresSpecialDisposal: false,
        ),
        region: 'Bangalore, IN',
      );
      final baselineBin = baseline.classification.localRegulations?['bin'];

      final override = SocietyPolicyOverride(
        societyId: 'sb_004',
        societyName: 'Conflicting Society',
        basePluginId: 'bbmp_bangalore',
        overrides: const [
          RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.binColor,
            value: 'Pink Bin',
          ),
          RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.collectionFrequency,
            value: 'monthly',
          ),
          RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.disposalMethod,
            value: 'Hand delivery only',
          ),
          RuleOverride(
            categoryKey: 'dry_waste',
            overrideType: RuleOverrideType.collectionLocation,
            value: 'Basement',
          ),
        ],
      );

      final decision = await engine.applyPolicy(
        classification: baseClassification.copyWith(
          category: 'Dry Waste',
          subCategory: 'Bottle',
          requiresSpecialDisposal: false,
        ),
        region: 'Bangalore, IN',
        societyId: 'sb_004',
        societyPolicyService: _FakeSocietyPolicyService(override),
      );

      expect(decision.classification.localRegulations?['bin'],
          equals(baselineBin));
      expect(
        decision.classification.localRegulations?['society_bin_alias'],
        isNull,
      );
      expect(
        decision.classification.localRegulations?['society_pickup_window'],
        isNull,
      );
      expect(
        decision.classification.localRegulations?['society_disposal_method'],
        isNull,
      );
      expect(
        decision
            .classification.localRegulations?['society_collection_location'],
        isNull,
      );
      expect(decision.societyOverrides, isEmpty);
      expect(decision.ruleOverridesApplied, isEmpty);
      expect(
        decision.societyConflicts.any(
          (conflict) => conflict.contains('conflicts with society'),
        ),
        isTrue,
      );
    });

    test(
      'high-risk society overrides that weaken city safety guidance are blocked',
      () async {
        final override = SocietyPolicyOverride(
          societyId: 'sb_003',
          societyName: 'High Risk Society',
          basePluginId: 'bbmp_bangalore',
          overrides: const [
            RuleOverride(
              categoryKey: 'hazardous_waste',
              overrideType: RuleOverrideType.disposalMethod,
              value: 'Dry Bin',
            ),
          ],
        );

        final decision = await engine.applyPolicy(
          classification: baseClassification,
          region: 'Bangalore, IN',
          societyId: 'sb_003',
          societyPolicyService: _FakeSocietyPolicyService(override),
        );

        expect(decision.policyApplied, isTrue);
        expect(
          decision.societyConflicts.any(
            (conflict) => conflict.contains(
                'City disposal method conflicts with society override'),
          ),
          isTrue,
        );
        expect(
          decision.classification.localRegulations?.containsKey(
            'society_disposal_method',
          ),
          isFalse,
        );
        expect(decision.societyOverrides, isEmpty);
        expect(decision.ruleOverridesApplied, isEmpty);
      },
    );

    test(
      'municipal guidance gaps block high-impact society overrides',
      () async {
        final override = SocietyPolicyOverride(
          societyId: 'sb_005',
          societyName: 'Missing Guidance Society',
          basePluginId: 'bbmp_bangalore',
          overrides: const [
            RuleOverride(
              categoryKey: 'special_care_waste',
              overrideType: RuleOverrideType.binColor,
              value: 'Green Bin',
            ),
            RuleOverride(
              categoryKey: 'special_care_waste',
              overrideType: RuleOverrideType.collectionFrequency,
              value: 'daily',
            ),
            RuleOverride(
              categoryKey: 'special_care_waste',
              overrideType: RuleOverrideType.disposalMethod,
              value: 'Special pickup',
            ),
            RuleOverride(
              categoryKey: 'special_care_waste',
              overrideType: RuleOverrideType.collectionLocation,
              value: 'Society basement',
            ),
          ],
        );

        final decision = await engine.applyPolicy(
          classification: baseClassification.copyWith(
            category: 'Special Care Waste',
            subCategory: 'Unknown',
            requiresSpecialDisposal: false,
          ),
          region: 'Bangalore, IN',
          societyId: 'sb_005',
          societyPolicyService: _FakeSocietyPolicyService(override),
        );

        expect(decision.societyOverrides, isEmpty);
        expect(
          decision.ruleOverridesApplied,
          isEmpty,
          reason:
              'No overrides should apply when municipal guidance is missing',
        );
        expect(
          decision.classification.localRegulations?['society_bin_alias'],
          isNull,
        );
        expect(
          decision.classification.localRegulations?['society_pickup_window'],
          isNull,
        );
        expect(
          decision.classification.localRegulations?['society_disposal_method'],
          isNull,
        );
        expect(
          decision
              .classification.localRegulations?['society_collection_location'],
          isNull,
        );
        expect(decision.societyConflicts, isNotEmpty);
        expect(
          decision.societyConflicts
              .any((conflict) => conflict.contains('unavailable')),
          isTrue,
        );
      },
    );

    test(
      'society mismatch does not apply overrides but records conflict',
      () async {
        final override = SocietyPolicyOverride(
          societyId: 'sb_002',
          societyName: 'Wrong Match Society',
          basePluginId: 'bmc_mumbai',
          overrides: const [
            RuleOverride(
              categoryKey: 'hazardous_waste',
              overrideType: RuleOverrideType.binColor,
              value: 'Blue',
            ),
          ],
        );

        final decision = await engine.applyPolicy(
          classification: baseClassification,
          region: 'Bangalore, IN',
          societyId: 'sb_002',
          societyPolicyService: _FakeSocietyPolicyService(override),
        );

        expect(decision.policyApplied, isTrue);
        expect(decision.societyConflicts, isNotEmpty);
        expect(decision.societyOverrides, isEmpty);
        expect(
          decision.societyConflicts.first,
          contains('does not match resolved plugin'),
        );
      },
    );
  });
}
