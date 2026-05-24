import '../models/waste_classification.dart';
import 'local_classifier_service.dart';
import 'ai_router_policy_config.dart';

class RouterGuardrailDecision {
  const RouterGuardrailDecision({
    required this.accepted,
    this.reason,
  });

  final bool accepted;
  final String? reason;
}

class ClassificationRouterGuardrails {
  const ClassificationRouterGuardrails({
    this.localAcceptanceThreshold = 0.85,
    this.localEscalationThreshold = 0.70,
    this.localSafetyThreshold = 0.97,
    this.blockCacheOnRuleVersionChange = true,
    this.enforceSafetyEscalation = true,
  });

  final double localAcceptanceThreshold;
  final double localEscalationThreshold;
  final double localSafetyThreshold;
  final bool blockCacheOnRuleVersionChange;
  final bool enforceSafetyEscalation;

  factory ClassificationRouterGuardrails.fromPolicy(
    AiRouterPolicyConfig config,
  ) {
    return ClassificationRouterGuardrails(
      localAcceptanceThreshold: config.localAcceptanceThreshold,
      localEscalationThreshold: config.localEscalationThreshold,
      localSafetyThreshold: config.localSafetyThreshold,
      blockCacheOnRuleVersionChange: config.blockCacheOnRuleVersionChange,
      enforceSafetyEscalation: config.enforceSafetyEscalation,
    );
  }

  static const Set<String> alwaysEscalateCategories = <String>{
    'Hazardous Waste',
    'Medical Waste',
    'Medical',
    'E-Waste',
    'Electronic Waste',
    'Chemical Waste',
    'Chemical',
    'Sharps',
    'Pharmaceutical Waste',
    'Pharmaceutical',
  };

  static const Set<String> manualReviewCategories = <String>{
    'Unknown',
    'Requires Manual Review',
  };

  RouterGuardrailDecision evaluateLocal(LocalClassificationResult local) {
    if (local.failureReason != null) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'local_failure');
    }
    if (manualReviewCategories.contains(local.category)) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'manual_review_category');
    }
    if (enforceSafetyEscalation &&
        alwaysEscalateCategories.contains(local.category) &&
        local.confidence < localSafetyThreshold) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'safety_threshold_guardrail');
    }
    if (local.confidence < localEscalationThreshold) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'below_escalation_threshold');
    }
    if (local.confidence < localAcceptanceThreshold) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'below_acceptance_threshold');
    }
    return const RouterGuardrailDecision(accepted: true);
  }

  RouterGuardrailDecision evaluateCloud(
    WasteClassification cloud, {
    required bool localRuleVersionChanged,
  }) {
    if (blockCacheOnRuleVersionChange && localRuleVersionChanged) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'local_rule_version_changed');
    }
    if (cloud.category == 'Requires Manual Review') {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'cloud_manual_review');
    }
    return const RouterGuardrailDecision(accepted: true);
  }
}
