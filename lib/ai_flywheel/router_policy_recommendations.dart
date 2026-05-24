import '../services/ai_router_policy_config.dart';
import '../services/classification_router_guardrails.dart';

String buildRouterStrategyRecommendations(AiRouterPolicyConfig policy) {
  final b = StringBuffer();
  b.writeln('# Router Strategy Recommendations');
  b.writeln();
  b.writeln('- Policy pack: `${policy.policyPackVersion}`.');
  b.writeln(
      '- Use `local` route only when confidence >= ${policy.localAcceptanceThreshold.toStringAsFixed(2)} and case is not safety-critical.');

  if (policy.enforceSafetyEscalation) {
    final safetyList = ClassificationRouterGuardrails.alwaysEscalateCategories
        .toList()
      ..sort();
    b.writeln(
        '- Always escalate ${safetyList.join('/')} to backend unless confidence >= ${policy.localSafetyThreshold.toStringAsFixed(2)}.');
  } else {
    b.writeln(
        '- Safety escalation is disabled by policy; enable `enforceSafetyEscalation` for launch safety posture.');
  }

  b.writeln(
      '- Escalate to backend when local confidence < ${policy.localEscalationThreshold.toStringAsFixed(2)}.');
  b.writeln(
      '- If providers disagree on safety category, ask user clarification and enqueue review candidate.');
  if (policy.blockCacheOnRuleVersionChange) {
    b.writeln('- Avoid cache reuse when local-rule version changes.');
  } else {
    b.writeln(
        '- Cache blocking on local-rule version changes is disabled; enable for deterministic policy behavior.');
  }
  b.writeln(
      '- Route to human review when provider pair disagreement persists for > 5% of overlapping cases.');
  return b.toString();
}
