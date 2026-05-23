class RouterComparisonResult {
  const RouterComparisonResult({
    required this.provider,
    required this.total,
    required this.correct,
    required this.safetyCriticalFailures,
    required this.mustNotViolations,
    required this.localRuleFailures,
    required this.multiItemFailures,
    required this.overconfidentWrong,
    required this.underconfidentCorrect,
    required this.avgLatencyMs,
    required this.avgEstimatedCostUsd,
    required this.cacheHitRate,
    required this.fallbackRate,
    required this.providerFailureRate,
  });

  final String provider;
  final int total;
  final int correct;
  final int safetyCriticalFailures;
  final int mustNotViolations;
  final int localRuleFailures;
  final int multiItemFailures;
  final int overconfidentWrong;
  final int underconfidentCorrect;
  final double avgLatencyMs;
  final double avgEstimatedCostUsd;
  final double cacheHitRate;
  final double fallbackRate;
  final double providerFailureRate;
}

class RouterMetrics {
  static RouterComparisonResult compare({
    required String provider,
    required List<Map<String, dynamic>> outcomes,
  }) {
    final total = outcomes.length;
    double avgNum(String k) {
      if (total == 0) return 0;
      final vals = outcomes.map((o) => (o[k] as num?)?.toDouble() ?? 0).toList();
      return vals.reduce((a, b) => a + b) / vals.length;
    }

    int countBool(String k) => outcomes.where((o) => o[k] == true).length;

    return RouterComparisonResult(
      provider: provider,
      total: total,
      correct: countBool('strictPass') + countBool('acceptableAlternativePass'),
      safetyCriticalFailures: countBool('safetyCriticalFailure'),
      mustNotViolations: countBool('mustNotViolation'),
      localRuleFailures: countBool('localRuleFailure'),
      multiItemFailures: countBool('multiItemFailure'),
      overconfidentWrong: countBool('overconfidentWrong'),
      underconfidentCorrect: countBool('underconfidentCorrect'),
      avgLatencyMs: avgNum('latencyMs'),
      avgEstimatedCostUsd: avgNum('estimatedCostUsd'),
      cacheHitRate: total == 0 ? 0 : countBool('cacheHit') / total,
      fallbackRate: total == 0 ? 0 : countBool('fallbackUsed') / total,
      providerFailureRate: total == 0 ? 0 : countBool('providerFailure') / total,
    );
  }
}
