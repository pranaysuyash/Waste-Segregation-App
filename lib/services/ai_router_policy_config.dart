import 'dart:convert';

class AiRouterPolicyConfig {
  const AiRouterPolicyConfig({
    required this.policyPackVersion,
    required this.localAcceptanceThreshold,
    required this.localEscalationThreshold,
    required this.localSafetyThreshold,
    required this.blockCacheOnRuleVersionChange,
    required this.enforceSafetyEscalation,
  });

  final String policyPackVersion;
  final double localAcceptanceThreshold;
  final double localEscalationThreshold;
  final double localSafetyThreshold;
  final bool blockCacheOnRuleVersionChange;
  final bool enforceSafetyEscalation;

  static const AiRouterPolicyConfig defaults = AiRouterPolicyConfig(
    policyPackVersion: 'router-policy-v1',
    localAcceptanceThreshold: 0.85,
    localEscalationThreshold: 0.70,
    localSafetyThreshold: 0.97,
    blockCacheOnRuleVersionChange: true,
    enforceSafetyEscalation: true,
  );

  factory AiRouterPolicyConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return defaults;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AiRouterPolicyConfig(
        policyPackVersion:
            '${json['policyPackVersion'] ?? defaults.policyPackVersion}',
        localAcceptanceThreshold:
            (json['localAcceptanceThreshold'] as num?)?.toDouble() ??
                defaults.localAcceptanceThreshold,
        localEscalationThreshold:
            (json['localEscalationThreshold'] as num?)?.toDouble() ??
                defaults.localEscalationThreshold,
        localSafetyThreshold:
            (json['localSafetyThreshold'] as num?)?.toDouble() ??
                defaults.localSafetyThreshold,
        blockCacheOnRuleVersionChange:
            json['blockCacheOnRuleVersionChange'] == null
                ? defaults.blockCacheOnRuleVersionChange
                : json['blockCacheOnRuleVersionChange'] == true,
        enforceSafetyEscalation: json['enforceSafetyEscalation'] == null
            ? defaults.enforceSafetyEscalation
            : json['enforceSafetyEscalation'] == true,
      );
    } catch (_) {
      return defaults;
    }
  }
}

