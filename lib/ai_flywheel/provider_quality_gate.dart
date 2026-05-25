class ProviderQualityGateThresholds {
  const ProviderQualityGateThresholds({
    this.minAccuracy = 0.95,
    this.maxMustNotViolations = 0,
    this.maxSafetyCriticalFailures = 0,
    this.maxLocalRuleFailures = 0,
  });

  final double minAccuracy;
  final int maxMustNotViolations;
  final int maxSafetyCriticalFailures;
  final int maxLocalRuleFailures;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'minAccuracy': minAccuracy,
        'maxMustNotViolations': maxMustNotViolations,
        'maxSafetyCriticalFailures': maxSafetyCriticalFailures,
        'maxLocalRuleFailures': maxLocalRuleFailures,
      };
}

class ProviderQualityGateResult {
  const ProviderQualityGateResult({
    required this.providerLabel,
    required this.cases,
    required this.accuracy,
    required this.mustNotViolations,
    required this.safetyCriticalFailures,
    required this.localRuleFailures,
    required this.passed,
    this.failureReasons = const <String>[],
  });

  final String providerLabel;
  final int cases;
  final double accuracy;
  final int mustNotViolations;
  final int safetyCriticalFailures;
  final int localRuleFailures;
  final bool passed;
  final List<String> failureReasons;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'providerLabel': providerLabel,
        'cases': cases,
        'accuracy': accuracy,
        'mustNotViolations': mustNotViolations,
        'safetyCriticalFailures': safetyCriticalFailures,
        'localRuleFailures': localRuleFailures,
        'passed': passed,
        'failureReasons': failureReasons,
      };
}

class ProviderQualityGate {
  const ProviderQualityGate(this.thresholds);

  final ProviderQualityGateThresholds thresholds;

  ProviderQualityGateResult evaluateSummary(
    Map<String, dynamic> summary, {
    required String defaultProviderLabel,
  }) {
    final cases = (summary['cases'] as num?)?.toInt() ?? 0;
    final strictPass = (summary['strictPass'] as num?)?.toInt() ?? 0;
    final acceptablePass = (summary['acceptablePass'] as num?)?.toInt() ?? 0;
    final mustNotViolations =
        (summary['mustNotViolations'] as num?)?.toInt() ?? 0;
    final safetyCriticalFailures =
        (summary['safetyCriticalFailures'] as num?)?.toInt() ?? 0;
    final localRuleFailures =
        (summary['localRuleFailures'] as num?)?.toInt() ?? 0;

    final correct = strictPass + acceptablePass;
    final accuracy = cases == 0 ? 0.0 : correct / cases;
    final providerLabel =
        '${summary['providerLabel'] ?? defaultProviderLabel}'.trim();

    final failureReasons = <String>[];
    if (accuracy < thresholds.minAccuracy) {
      failureReasons.add(
          'accuracy_below_threshold(${accuracy.toStringAsFixed(4)} < ${thresholds.minAccuracy.toStringAsFixed(4)})');
    }
    if (mustNotViolations > thresholds.maxMustNotViolations) {
      failureReasons.add(
          'must_not_violations_exceeded($mustNotViolations > ${thresholds.maxMustNotViolations})');
    }
    if (safetyCriticalFailures > thresholds.maxSafetyCriticalFailures) {
      failureReasons.add(
          'safety_failures_exceeded($safetyCriticalFailures > ${thresholds.maxSafetyCriticalFailures})');
    }
    if (localRuleFailures > thresholds.maxLocalRuleFailures) {
      failureReasons.add(
          'local_rule_failures_exceeded($localRuleFailures > ${thresholds.maxLocalRuleFailures})');
    }

    return ProviderQualityGateResult(
      providerLabel:
          providerLabel.isEmpty ? defaultProviderLabel : providerLabel,
      cases: cases,
      accuracy: accuracy,
      mustNotViolations: mustNotViolations,
      safetyCriticalFailures: safetyCriticalFailures,
      localRuleFailures: localRuleFailures,
      passed: failureReasons.isEmpty,
      failureReasons: failureReasons,
    );
  }
}
