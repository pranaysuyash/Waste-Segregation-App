import 'eval_models.dart';

class EvalScoring {
  static EvalCaseOutcome scoreCase(EvalCase c, EvalPrediction p) {
    final expectedCategory = c.expected['category'] as String;
    final strictPass = p.category == expectedCategory;
    final acceptableAlternativePass = c.acceptableAlternatives
        .any((alt) => alt['category'] == p.category);
    final mustNotViolation = c.mustNot.contains(p.category);
    final safetyCriticalFailure = c.safetyCritical && !strictPass && !acceptableAlternativePass;
    final localRuleMismatch = (c.localRuleId != null && p.localRuleId != null && c.localRuleId != p.localRuleId);
    final localRuleFailure = c.localRuleCritical && (mustNotViolation || localRuleMismatch);

    var multiItemFailure = false;
    if (c.multiItem) {
      final expectedItems = c.expectedItems.length;
      final predictedItems = p.predictedItems.length;
      multiItemFailure = expectedItems > 0 && predictedItems != expectedItems;
      if (!multiItemFailure && c.expectedItems.isNotEmpty && p.predictedItems.isNotEmpty) {
        final expectedCats = c.expectedItems.map((e) => '${e['category'] ?? ''}'.toLowerCase()).toList()..sort();
        final predictedCats = p.predictedItems.map((e) => '${e['category'] ?? ''}'.toLowerCase()).toList()..sort();
        multiItemFailure = expectedCats.join('|') != predictedCats.join('|');
      }
    }

    final overconfidentWrong = (p.confidence ?? 0) >= 0.8 && !strictPass && !acceptableAlternativePass;
    final underconfidentCorrect = (p.confidence ?? 1) < 0.5 && (strictPass || acceptableAlternativePass);
    final policyOverclaim = (c.region.toLowerCase().contains('unknown') && p.localRuleId != null);

    return EvalCaseOutcome(
      caseId: c.id,
      expectedCategory: expectedCategory,
      predictedCategory: p.category,
      strictPass: strictPass,
      acceptableAlternativePass: !strictPass && acceptableAlternativePass,
      mustNotViolation: mustNotViolation,
      safetyCriticalFailure: safetyCriticalFailure,
      localRuleFailure: localRuleFailure,
      multiItemFailure: multiItemFailure,
      overconfidentWrong: overconfidentWrong,
      underconfidentCorrect: underconfidentCorrect,
      providerFailure: p.providerFailure,
      fallbackUsed: p.fallbackUsed,
      policyOverclaim: policyOverclaim,
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
    final multiItemFailures = outcomes.where((o) => o.multiItemFailure).length;
    final overconfidentWrong = outcomes.where((o) => o.overconfidentWrong).length;
    final underconfidentCorrect = outcomes.where((o) => o.underconfidentCorrect).length;

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
      multiItemFailures: multiItemFailures,
      overconfidentWrong: overconfidentWrong,
      underconfidentCorrect: underconfidentCorrect,
      avgConfidenceOnCorrect: avg(correctConfidence),
      avgConfidenceOnWrong: avg(wrongConfidence),
      outcomes: outcomes,
    );
  }
}
