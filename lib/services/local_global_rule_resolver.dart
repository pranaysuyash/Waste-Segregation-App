class RuleResolution {
  const RuleResolution({
    required this.region,
    required this.localRuleId,
    required this.globalSafetyRule,
    required this.authority,
    required this.usedGlobalFallback,
  });

  final String region;
  final String? localRuleId;
  final String globalSafetyRule;
  final String authority;
  final bool usedGlobalFallback;
}

class LocalGlobalRuleResolver {
  const LocalGlobalRuleResolver();

  RuleResolution resolve(String region) {
    final normalized = region.trim().toLowerCase();
    if (normalized.contains('bangalore')) {
      return const RuleResolution(
        region: 'Bangalore, IN',
        localRuleId: 'bbmp_default_ruleset',
        globalSafetyRule: 'battery_never_regular_bin',
        authority: 'BBMP + global baseline',
        usedGlobalFallback: false,
      );
    }
    if (normalized.contains('india')) {
      return const RuleResolution(
        region: 'India Generic',
        localRuleId: 'india_generic_ruleset',
        globalSafetyRule: 'battery_never_regular_bin',
        authority: 'India generic + global baseline',
        usedGlobalFallback: false,
      );
    }
    return const RuleResolution(
      region: 'Global Fallback',
      localRuleId: null,
      globalSafetyRule: 'battery_never_regular_bin',
      authority: 'global safety baseline',
      usedGlobalFallback: true,
    );
  }
}

