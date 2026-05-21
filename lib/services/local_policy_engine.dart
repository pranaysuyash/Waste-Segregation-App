import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
import 'package:waste_segregation_app/services/local_policy_rule_packs.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Versioned policy pack metadata for provenance and rollout tracking.
class LocalPolicyRulePack {
  const LocalPolicyRulePack({
    required this.rulePackId,
    required this.pluginId,
    required this.authorityName,
    required this.region,
    required this.guidelinesVersion,
    required this.governanceStage,
    required this.owningTeam,
    required this.categories,
    required this.rules,
  });

  final String rulePackId;
  final String pluginId;
  final String authorityName;
  final String region;
  final String guidelinesVersion;
  final String governanceStage;
  final String owningTeam;
  final List<String> categories;
  final List<LocalPolicyRule> rules;
}

/// Canonical compliance result produced before policy mutations are applied.
class LocalPolicyComplianceEvaluation {
  const LocalPolicyComplianceEvaluation({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.recommendations,
  });

  final String status;
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;
}

enum LocalPolicyRuleSeverity { violation, warning }

enum LocalPolicyRuleCheckType {
  requiresSpecialDisposalTrue,
  hasUrgentTimeframeTrue,
  isCompostableTrue,
  isRecyclableTrue,
  visualFeatureMustNotContain,
}

/// Structured rule definition that can be versioned and extended per city.
class LocalPolicyRule {
  const LocalPolicyRule({
    required this.ruleId,
    required this.categoryKey,
    required this.severity,
    required this.checkType,
    required this.message,
    this.targetValue,
  });

  final String ruleId;
  final String categoryKey;
  final LocalPolicyRuleSeverity severity;
  final LocalPolicyRuleCheckType checkType;
  final String message;
  final String? targetValue;
}

/// Dedicated evaluator that computes compliance independently from mutation.
class LocalPolicyComplianceEvaluator {
  const LocalPolicyComplianceEvaluator();

  LocalPolicyComplianceEvaluation evaluate({
    required LocalGuidelinesPlugin plugin,
    required WasteClassification classification,
    required LocalPolicyRulePack rulePack,
  }) {
    final result = plugin.validateCompliance(classification);
    final violations = <String>[...result.violations];
    final warnings = <String>[...result.warnings];

    final categoryKey = _toCategoryKey(classification.category);
    final categoryRules =
        rulePack.rules.where((rule) => rule.categoryKey == categoryKey);

    for (final rule in categoryRules) {
      final passed = _evaluateRule(rule, classification);
      if (passed) continue;
      if (rule.severity == LocalPolicyRuleSeverity.violation) {
        violations.add('[${rule.ruleId}] ${rule.message}');
      } else {
        warnings.add('[${rule.ruleId}] ${rule.message}');
      }
    }

    var status = 'compliant';
    if (violations.isNotEmpty) {
      status = 'violation';
    } else if (warnings.isNotEmpty) {
      status = 'requires_attention';
    }

    return LocalPolicyComplianceEvaluation(
      status: status,
      violations: violations,
      warnings: warnings,
      recommendations: result.recommendations,
    );
  }

  bool _evaluateRule(LocalPolicyRule rule, WasteClassification classification) {
    switch (rule.checkType) {
      case LocalPolicyRuleCheckType.requiresSpecialDisposalTrue:
        return classification.requiresSpecialDisposal == true;
      case LocalPolicyRuleCheckType.hasUrgentTimeframeTrue:
        return classification.hasUrgentTimeframe == true;
      case LocalPolicyRuleCheckType.isCompostableTrue:
        return classification.isCompostable == true;
      case LocalPolicyRuleCheckType.isRecyclableTrue:
        return classification.isRecyclable == true;
      case LocalPolicyRuleCheckType.visualFeatureMustNotContain:
        final token = (rule.targetValue ?? '').trim().toLowerCase();
        if (token.isEmpty) return true;
        return !classification.visualFeatures
            .map((feature) => feature.toLowerCase())
            .any((feature) => feature.contains(token));
    }
  }

  String _toCategoryKey(String category) =>
      category.toLowerCase().replaceAll(' ', '_');
}

/// Canonical outcome of local policy evaluation.
class LocalPolicyDecision {
  const LocalPolicyDecision({
    required this.classification,
    required this.policyApplied,
    required this.evaluatedAt,
    this.pluginId,
    this.authorityName,
    this.guidelinesVersion,
    this.rulePackId,
    this.complianceStatus,
    this.rulePack,
    this.violations = const <String>[],
    this.warnings = const <String>[],
    this.recommendations = const <String>[],
  });

  final WasteClassification classification;
  final bool policyApplied;
  final DateTime evaluatedAt;
  final String? pluginId;
  final String? authorityName;
  final String? guidelinesVersion;
  final String? rulePackId;
  final String? complianceStatus;
  final LocalPolicyRulePack? rulePack;
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;
}

/// Canonical policy engine that routes classification outputs through
/// region-aware municipal/local rules before downstream use.
class LocalPolicyEngine {
  const LocalPolicyEngine({
    LocalPolicyComplianceEvaluator complianceEvaluator =
        const LocalPolicyComplianceEvaluator(),
    LocalPolicyRulePackRegistry rulePackRegistry =
        const LocalPolicyRulePackRegistry(),
  })  : _complianceEvaluator = complianceEvaluator,
        _rulePackRegistry = rulePackRegistry;

  final LocalPolicyComplianceEvaluator _complianceEvaluator;
  final LocalPolicyRulePackRegistry _rulePackRegistry;

  Future<LocalPolicyDecision> applyPolicy({
    required WasteClassification classification,
    required String region,
  }) async {
    final plugin = LocalGuidelinesManager.getPluginForRegion(region);
    if (plugin == null) {
      WasteAppLogger.info('No local policy plugin matched region',
          context: {'region': region});
      return LocalPolicyDecision(
        classification: classification,
        policyApplied: false,
        evaluatedAt: DateTime.now(),
      );
    }

    final rulePack = _buildRulePack(plugin);
    final compliance = _complianceEvaluator.evaluate(
      plugin: plugin,
      classification: classification,
      rulePack: rulePack,
    );
    final updated = await plugin.applyLocalGuidelines(classification);

    return LocalPolicyDecision(
      classification: updated,
      policyApplied: true,
      evaluatedAt: DateTime.now(),
      pluginId: plugin.pluginId,
      authorityName: plugin.authorityName,
      guidelinesVersion: plugin.guidelinesVersion,
      rulePackId: rulePack.rulePackId,
      complianceStatus: compliance.status,
      rulePack: rulePack,
      violations: compliance.violations,
      warnings: compliance.warnings,
      recommendations: compliance.recommendations,
    );
  }

  LocalPolicyRulePack _buildRulePack(LocalGuidelinesPlugin plugin) {
    final categories = plugin.getColorCoding().keys.toList()..sort();
    final definition = _rulePackRegistry.getPackForPlugin(plugin.pluginId);
    return LocalPolicyRulePack(
      rulePackId: '${plugin.pluginId}:${plugin.guidelinesVersion}',
      pluginId: plugin.pluginId,
      authorityName: plugin.authorityName,
      region: plugin.region,
      guidelinesVersion: plugin.guidelinesVersion,
      governanceStage: definition.governanceStage,
      owningTeam: definition.owningTeam,
      categories: categories,
      rules: definition.rules,
    );
  }
}
