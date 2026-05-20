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
      ],
    ),
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
      ],
    ),
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
          message: 'Delhi hazardous waste requires special disposal routing.',
        ),
        LocalPolicyRule(
          ruleId: 'mcd_wet_compostable',
          categoryKey: 'wet_waste',
          severity: LocalPolicyRuleSeverity.warning,
          checkType: LocalPolicyRuleCheckType.isCompostableTrue,
          message:
              'Wet waste should usually be compostable in the city stream.',
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
