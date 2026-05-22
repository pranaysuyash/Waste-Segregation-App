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
    this.sourceUrl,
    this.helpline,
    this.lastVerified,
    this.nextReviewDue,
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
  final String? sourceUrl;
  final String? helpline;
  final String? lastVerified;
  final String? nextReviewDue;
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
  safetyOverrideAlways,
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
    final pluginResult = plugin.validateCompliance(classification);
    final confidence = classification.confidence ?? 1.0;
    final violations = <String>[];
    final warnings = <String>[...pluginResult.warnings];

    for (final v in pluginResult.violations) {
      final severity = _resolvePluginViolationSeverity(v, confidence);
      if (severity == LocalPolicyRuleSeverity.violation) {
        violations.add(v);
      } else {
        warnings.add('[confidence_gated] $v');
      }
    }

    final categoryKey = _toCategoryKey(classification.category);
    final categoryRules =
        rulePack.rules.where((rule) => rule.categoryKey == categoryKey);

    for (final rule in categoryRules) {
      final passed = _evaluateRule(rule, classification);

      if (passed) continue;

      final severity = _resolveRuleSeverity(rule, confidence);

      if (severity == LocalPolicyRuleSeverity.violation) {
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
      recommendations: pluginResult.recommendations,
    );
  }

  /// Resolves the effective severity of a plugin-level violation, applying
  /// confidence gating.
  ///
  /// Plugin violations come from [LocalGuidelinesPlugin.validateCompliance]
  /// and are based on the plugin's deterministic rules applied to ML-sourced
  /// fields. When confidence is low, those ML-sourced fields may be wrong,
  /// so violations are demoted to warnings.
  ///
  ///   ≥ 0.70  — full enforcement
  ///   0.50–0.69 — demoted to warning
  ///   < 0.50  — demoted to warning
  LocalPolicyRuleSeverity _resolvePluginViolationSeverity(
    String violation,
    double confidence,
  ) {
    if (confidence >= 0.70) return LocalPolicyRuleSeverity.violation;
    return LocalPolicyRuleSeverity.warning;
  }

  /// Resolves the effective severity of a rule-pack rule, applying confidence
  /// gating.
  ///
  /// Rules with check type `safetyOverrideAlways` are held to a higher
  /// standard — they remain violations at ≥0.70 but demote below that.
  ///
  ///   ≥ 0.90  — full enforcement per rule
  ///   0.70–0.89 — safetyOverrideAlways stays violation; others stay as-is
  ///   0.50–0.69 — all violations demoted to warning
  ///   < 0.50  — all violations demoted to warning
  LocalPolicyRuleSeverity _resolveRuleSeverity(
    LocalPolicyRule rule,
    double confidence,
  ) {
    if (confidence >= 0.90) return rule.severity;

    if (confidence >= 0.70) {
      if (rule.checkType == LocalPolicyRuleCheckType.safetyOverrideAlways) {
        return rule.severity;
      }
      return rule.severity;
    }

    if (confidence >= 0.50) {
      if (rule.checkType == LocalPolicyRuleCheckType.safetyOverrideAlways) {
        return LocalPolicyRuleSeverity.warning;
      }
      return LocalPolicyRuleSeverity.warning;
    }

    return LocalPolicyRuleSeverity.warning;
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
      case LocalPolicyRuleCheckType.safetyOverrideAlways:
        return false;
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
    this.sourceUrl,
    this.helpline,
    this.lastVerified,
    this.confidenceGated = false,
    this.originalSeverity,
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

  // Provenance card fields
  final String? sourceUrl;
  final String? helpline;
  final String? lastVerified;
  final bool confidenceGated;
  final String? originalSeverity;
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
    String? societyId,
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

    final confidence = classification.confidence ?? 1.0;
    final isConfidenceGated = confidence < 0.70;

    if (societyId != null) {
      WasteAppLogger.info('Applying policy with society override',
          context: {'societyId': societyId, 'region': region});
    }

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
      sourceUrl: rulePack.sourceUrl,
      helpline: rulePack.helpline,
      lastVerified: rulePack.lastVerified,
      confidenceGated: isConfidenceGated,
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
