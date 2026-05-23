import '../models/waste_classification.dart';
import 'local_classifier_service.dart';

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
  });

  final double localAcceptanceThreshold;
  final double localEscalationThreshold;
  final double localSafetyThreshold;

  static const Set<String> _alwaysEscalate = <String>{
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

  static const Set<String> _manualReviewCategories = <String>{
    'Unknown',
    'Requires Manual Review',
  };

  RouterGuardrailDecision evaluateLocal(LocalClassificationResult local) {
    if (local.failureReason != null) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'local_failure');
    }
    if (_manualReviewCategories.contains(local.category)) {
      return const RouterGuardrailDecision(
          accepted: false, reason: 'manual_review_category');
    }
    if (_alwaysEscalate.contains(local.category) &&
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
    if (localRuleVersionChanged) {
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

