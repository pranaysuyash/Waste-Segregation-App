import 'package:waste_segregation_app/services/local_policy_engine.dart';

/// Registry of structured local policy rule packs.
///
/// Packs are keyed by plugin ID to keep policy definitions versionable and
/// data-driven as we expand beyond a single city/authority.
class LocalPolicyRulePackRegistry {
  const LocalPolicyRulePackRegistry();

  LocalPolicyPackDefinition getPackForPlugin(String pluginId) {
    return _rulePacksByPlugin[pluginId] ??
        const LocalPolicyPackDefinition(
          governanceStage: 'draft',
          owningTeam: 'policy_platform',
          rules: <LocalPolicyRule>[],
        );
  }

  static const Map<String, LocalPolicyPackDefinition> _rulePacksByPlugin = {
    // ---- BBMP Bangalore (production) ----
    'bbmp_bangalore': LocalPolicyPackDefinition(
      governanceStage: 'production',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'bbmp_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Hazardous waste must be marked as requiring special disposal.',
        ),
        LocalPolicyRule(
          ruleId: 'bbmp_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message: 'Medical waste must be flagged for urgent disposal.',
        ),
        LocalPolicyRule(
          ruleId: 'bbmp_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message: 'Wet waste should generally be compostable.',
        ),
        LocalPolicyRule(
          ruleId: 'bbmp_dry_recyclable',
          categoryKey: 'dry_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isRecyclableTrue,
          message: 'Dry waste should usually be recyclable after sorting.',
        ),
        LocalPolicyRule(
          ruleId: 'bbmp_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'Hazardous waste requires special disposal per BBMP — this is a safety requirement regardless of confidence.',
        ),
        LocalPolicyRule(
          ruleId: 'bbmp_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'Medical waste requires urgent handling per BBMP — this is a safety requirement regardless of confidence.',
        ),
      ],
    ),

    // ---- BMC Mumbai (pilot) ----
    'bmc_mumbai': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'bmc_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Mumbai hazardous waste must be routed for special disposal.',
        ),
        LocalPolicyRule(
          ruleId: 'bmc_wet_no_plastic_trace',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.visualFeatureMustNotContain,
          targetValue: 'plastic',
          message:
              'Wet waste should be free from visible plastic contaminants.',
        ),
        LocalPolicyRule(
          ruleId: 'bmc_dry_recyclable',
          categoryKey: 'dry_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isRecyclableTrue,
          message: 'Dry stream items should be recyclable after basic sorting.',
        ),
        LocalPolicyRule(
          ruleId: 'bmc_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'BMC requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'bmc_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'BMC requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),

    // ---- MCD Delhi (pilot) ----
    'mcd_delhi': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'mcd_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message: 'Delhi medical waste must be marked urgent for disposal.',
        ),
        LocalPolicyRule(
          ruleId: 'mcd_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Delhi hazardous waste requires special disposal routing.',
        ),
        LocalPolicyRule(
          ruleId: 'mcd_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message:
              'Wet waste should usually be compostable in the city stream.',
        ),
        LocalPolicyRule(
          ruleId: 'mcd_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'MCD requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'mcd_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'MCD requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),

    // ---- PMC Pune (pilot) ----
    'pmc_pune': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'pmc_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Pune hazardous waste requires special disposal via PMC ward office.',
        ),
        LocalPolicyRule(
          ruleId: 'pmc_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message:
              'Medical waste in Pune must be handled urgently via authorized biomedical waste handler.',
        ),
        LocalPolicyRule(
          ruleId: 'pmc_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message:
              'PMC encourages composting; apartments ≥20 units must compost on-site.',
        ),
        LocalPolicyRule(
          ruleId: 'pmc_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'PMC requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'pmc_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'PMC requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),

    // ---- GHMC Hyderabad (pilot) ----
    'ghmc_hyderabad': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'ghmc_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Hyderabad hazardous waste requires special disposal routing via GHMC.',
        ),
        LocalPolicyRule(
          ruleId: 'ghmc_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message:
              'Hyderabad medical waste must be flagged for urgent disposal via authorized handler.',
        ),
        LocalPolicyRule(
          ruleId: 'ghmc_wet_no_plastic',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.visualFeatureMustNotContain,
          targetValue: 'plastic',
          message:
              'Wet waste in Hyderabad should be free from plastic contaminants.',
        ),
        LocalPolicyRule(
          ruleId: 'ghmc_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'GHMC requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'ghmc_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'GHMC requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),

    // ---- GCC Chennai (pilot) ----
    'gcc_chennai': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'gcc_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Chennai hazardous waste requires special disposal via GCC ward office.',
        ),
        LocalPolicyRule(
          ruleId: 'gcc_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message:
              'Chennai medical waste must be handled via authorized BMW handler.',
        ),
        LocalPolicyRule(
          ruleId: 'gcc_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message:
              'Wet waste should be compostable; GCC operates bio-mining of legacy waste.',
        ),
        LocalPolicyRule(
          ruleId: 'gcc_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'GCC requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'gcc_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'GCC requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),

    // ---- KMC Kolkata (pilot) ----
    'kmc_kolkata': LocalPolicyPackDefinition(
      governanceStage: 'pilot',
      owningTeam: 'india_city_ops',
      rules: <LocalPolicyRule>[
        LocalPolicyRule(
          ruleId: 'kmc_hazardous_special_disposal',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.requiresSpecialDisposalTrue,
          message:
              'Kolkata hazardous waste requires special disposal via KMC borough office.',
        ),
        LocalPolicyRule(
          ruleId: 'kmc_medical_urgent',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.hasUrgentTimeframeTrue,
          message:
              'Kolkata medical waste must be flagged for urgent disposal via authorized handler.',
        ),
        LocalPolicyRule(
          ruleId: 'kmc_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message: 'Wet waste should be compostable in the city stream.',
        ),
        LocalPolicyRule(
          ruleId: 'kmc_hazardous_safety_override',
          categoryKey: 'hazardous_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'KMC requires special disposal for hazardous waste — safety override.',
        ),
        LocalPolicyRule(
          ruleId: 'kmc_medical_safety_override',
          categoryKey: 'medical_waste',
          severity: LocalPolicyRuleSeverity.violation,
          checkType: LocalPolicyRuleCheckType.safetyOverrideAlways,
          message:
              'KMC requires urgent handling for medical waste — safety override.',
        ),
      ],
    ),
  };
}

class LocalPolicyPackDefinition {
  const LocalPolicyPackDefinition({
    required this.governanceStage,
    required this.owningTeam,
    required this.rules,
  });

  final String governanceStage;
  final String owningTeam;
  final List<LocalPolicyRule> rules;
}
