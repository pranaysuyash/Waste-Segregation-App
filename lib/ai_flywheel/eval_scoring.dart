import 'eval_models.dart';

class EvalScoring {
  static EvalCaseOutcome scoreCase(EvalCase c, EvalPrediction p) {
    final expectedCategory = c.expected['category'] as String;
    final strictPass = p.category == expectedCategory;
    final acceptableAlternativePass = c.acceptableAlternatives
        .any((alt) => alt['category'] == p.category);
    final mustNotViolation = c.mustNot.contains(p.category);
    final safetyCriticalFailure = c.safetyCritical && !strictPass && !acceptableAlternativePass;
    final localRuleFailure = c.localRuleCritical && mustNotViolation;
    final highConfidenceWrong = (p.confidence ?? 0) >= 0.8 && !strictPass && !acceptableAlternativePass;
    final lowConfidenceCorrect = (p.confidence ?? 1) < 0.5 && (strictPass || acceptableAlternativePass);

    return EvalCaseOutcome(
      caseId: c.id,
      expectedCategory: expectedCategory,
      predictedCategory: p.category,
      strictPass: strictPass,
      acceptableAlternativePass: !strictPass && acceptableAlternativePass,
      mustNotViolation: mustNotViolation,
      safetyCriticalFailure: safetyCriticalFailure,
      localRuleFailure: localRuleFailure,
      highConfidenceWrong: highConfidenceWrong,
      lowConfidenceCorrect: lowConfidenceCorrect,
      confidence: p.confidence,
      provider: p.provider,
      model: p.model,
      route: p.route,
      latencyMs: p.latencyMs,
      estimatedCostUsd: p.estimatedCostUsd,
      cacheHit: p.cacheHit,
    );
  }

  static EvalSummary summarize({
    required String mode,
    required String providerLabel,
    required List<EvalCaseOutcome> outcomes,
  }) {
    final strictPass = outcomes.where((o) => o.strictPass).length;
    final acceptablePass = outcomes.where((o) => o.acceptableAlternativePass).length;
    final fail = outcomes.length - strictPass - acceptablePass;
    final safetyCriticalFailures = outcomes.where((o) => o.safetyCriticalFailure).length;
    final mustNotViolations = outcomes.where((o) => o.mustNotViolation).length;
    final localRuleFailures = outcomes.where((o) => o.localRuleFailure).length;

    final correctConfidence = outcomes
        .where((o) => o.strictPass || o.acceptableAlternativePass)
        .map((o) => o.confidence)
        .whereType<double>()
        .toList();
    final wrongConfidence = outcomes
        .where((o) => !o.strictPass && !o.acceptableAlternativePass)
        .map((o) => o.confidence)
        .whereType<double>()
        .toList();

    double avg(List<double> values) => values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;

    return EvalSummary(
      mode: mode,
      providerLabel: providerLabel,
      cases: outcomes.length,
      strictPass: strictPass,
      acceptablePass: acceptablePass,
      fail: fail,
      safetyCriticalFailures: safetyCriticalFailures,
      mustNotViolations: mustNotViolations,
      localRuleFailures: localRuleFailures,
      avgConfidenceOnCorrect: avg(correctConfidence),
      avgConfidenceOnWrong: avg(wrongConfidence),
      outcomes: outcomes,
    );
  }
}
