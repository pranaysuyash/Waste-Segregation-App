class EvalCase {
  const EvalCase({
    required this.id,
    required this.imageRef,
    required this.region,
    required this.language,
    required this.expected,
    required this.mustNot,
    required this.safetyCritical,
    required this.localRuleCritical,
    this.inputHints = const <String, dynamic>{},
    this.acceptableAlternatives = const <Map<String, dynamic>>[],
    this.expectedItems = const <Map<String, dynamic>>[],
    this.expectedAggregateWarnings = const <String>[],
    this.localRuleId,
    this.globalSafetyRule,
    this.authority,
    this.expectedPolicy = const <String, dynamic>{},
    this.notes,
  });

  factory EvalCase.fromJson(Map<String, dynamic> json) {
    final expected = (json['expected'] as Map?)?.cast<String, dynamic>();
    if (expected == null || (expected['category'] as String?) == null) {
      throw FormatException('Eval case missing expected.category for ${json['id']}');
    }
    return EvalCase(
      id: json['id'] as String,
      imageRef: json['imageRef'] as String,
      region: json['region'] as String,
      language: json['language'] as String,
      inputHints: (json['inputHints'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      expected: expected,
      acceptableAlternatives: ((json['acceptableAlternatives'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      mustNot: ((json['mustNot'] as List?) ?? const <dynamic>[]).map((e) => '$e').toList(),
      expectedItems: ((json['expectedItems'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      expectedAggregateWarnings: ((json['expectedAggregateWarnings'] as List?) ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(),
      localRuleId: json['localRuleId'] as String?,
      globalSafetyRule: json['globalSafetyRule'] as String?,
      authority: json['authority'] as String?,
      expectedPolicy: (json['expectedPolicy'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      safetyCritical: json['safetyCritical'] == true,
      localRuleCritical: json['localRuleCritical'] == true,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String imageRef;
  final String region;
  final String language;
  final Map<String, dynamic> inputHints;
  final Map<String, dynamic> expected;
  final List<Map<String, dynamic>> acceptableAlternatives;
  final List<String> mustNot;
  final List<Map<String, dynamic>> expectedItems;
  final List<String> expectedAggregateWarnings;
  final String? localRuleId;
  final String? globalSafetyRule;
  final String? authority;
  final Map<String, dynamic> expectedPolicy;
  final bool safetyCritical;
  final bool localRuleCritical;
  final String? notes;

  bool get multiItem => inputHints['multiItem'] == true || expectedItems.isNotEmpty;
}

class EvalPrediction {
  const EvalPrediction({
    required this.caseId,
    required this.category,
    required this.provider,
    required this.model,
    this.subcategory,
    this.materialType,
    this.predictedItems = const <Map<String, dynamic>>[],
    this.aggregateWarnings = const <String>[],
    this.confidence,
    this.route,
    this.latencyMs,
    this.estimatedCostUsd,
    this.cacheHit,
    this.fallbackUsed = false,
    this.providerFailure = false,
    this.askClarification = false,
    this.localRuleId,
    this.globalSafetyRule,
  });

  factory EvalPrediction.fromJson(Map<String, dynamic> json) {
    final prediction = (json['prediction'] as Map?)?.cast<String, dynamic>();
    return EvalPrediction(
      caseId: json['caseId'] as String,
      category: (prediction?['category'] as String?) ?? (json['category'] as String),
      subcategory: (prediction?['subcategory'] as String?) ?? (json['subcategory'] as String?),
      materialType: (prediction?['materialType'] as String?) ?? (json['materialType'] as String?),
      provider: (json['provider'] as String?) ?? 'unknown',
      model: (json['model'] as String?) ?? 'unknown',
      route: json['route'] as String?,
      predictedItems: ((json['predictedItems'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      aggregateWarnings: ((json['aggregateWarnings'] as List?) ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(),
      confidence: (prediction?['confidence'] as num?)?.toDouble() ?? (json['confidence'] as num?)?.toDouble(),
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      estimatedCostUsd: (json['estimatedCostUsd'] as num?)?.toDouble(),
      cacheHit: json['cacheHit'] == true,
      fallbackUsed: json['fallbackUsed'] == true || json['usedFallback'] == true,
      providerFailure: json['providerFailure'] == true,
      askClarification: json['askClarification'] == true,
      localRuleId: json['localRuleId'] as String?,
      globalSafetyRule: json['globalSafetyRule'] as String?,
    );
  }

  final String caseId;
  final String category;
  final String provider;
  final String model;
  final String? subcategory;
  final String? materialType;
  final List<Map<String, dynamic>> predictedItems;
  final List<String> aggregateWarnings;
  final String? route;
  final double? confidence;
  final int? latencyMs;
  final double? estimatedCostUsd;
  final bool? cacheHit;
  final bool fallbackUsed;
  final bool providerFailure;
  final bool askClarification;
  final String? localRuleId;
  final String? globalSafetyRule;
}

class EvalCaseOutcome {
  const EvalCaseOutcome({
    required this.caseId,
    required this.expectedCategory,
    required this.predictedCategory,
    required this.strictPass,
    required this.acceptableAlternativePass,
    required this.mustNotViolation,
    required this.safetyCriticalFailure,
    required this.localRuleFailure,
    required this.multiItemFailure,
    required this.overconfidentWrong,
    required this.underconfidentCorrect,
    required this.provider,
    required this.model,
    required this.providerFailure,
    required this.fallbackUsed,
    required this.policyOverclaim,
    this.confidence,
    this.route,
    this.latencyMs,
    this.estimatedCostUsd,
    this.cacheHit,
  });

  final String caseId;
  final String expectedCategory;
  final String predictedCategory;
  final bool strictPass;
  final bool acceptableAlternativePass;
  final bool mustNotViolation;
  final bool safetyCriticalFailure;
  final bool localRuleFailure;
  final bool multiItemFailure;
  final bool overconfidentWrong;
  final bool underconfidentCorrect;
  final bool providerFailure;
  final bool fallbackUsed;
  final bool policyOverclaim;
  final String provider;
  final String model;
  final double? confidence;
  final String? route;
  final int? latencyMs;
  final double? estimatedCostUsd;
  final bool? cacheHit;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'caseId': caseId,
        'expectedCategory': expectedCategory,
        'predictedCategory': predictedCategory,
        'strictPass': strictPass,
        'acceptableAlternativePass': acceptableAlternativePass,
        'mustNotViolation': mustNotViolation,
        'safetyCriticalFailure': safetyCriticalFailure,
        'localRuleFailure': localRuleFailure,
        'multiItemFailure': multiItemFailure,
        'overconfidentWrong': overconfidentWrong,
        'underconfidentCorrect': underconfidentCorrect,
        'providerFailure': providerFailure,
        'fallbackUsed': fallbackUsed,
        'policyOverclaim': policyOverclaim,
        'confidence': confidence,
        'provider': provider,
        'model': model,
        'route': route,
        'latencyMs': latencyMs,
        'estimatedCostUsd': estimatedCostUsd,
        'cacheHit': cacheHit,
      };
}

class EvalSummary {
  const EvalSummary({
    required this.mode,
    required this.providerLabel,
    required this.cases,
    required this.strictPass,
    required this.acceptablePass,
    required this.fail,
    required this.safetyCriticalFailures,
    required this.mustNotViolations,
    required this.localRuleFailures,
    required this.multiItemFailures,
    required this.overconfidentWrong,
    required this.underconfidentCorrect,
    required this.avgConfidenceOnCorrect,
    required this.avgConfidenceOnWrong,
    required this.outcomes,
  });

  final String mode;
  final String providerLabel;
  final int cases;
  final int strictPass;
  final int acceptablePass;
  final int fail;
  final int safetyCriticalFailures;
  final int mustNotViolations;
  final int localRuleFailures;
  final int multiItemFailures;
  final int overconfidentWrong;
  final int underconfidentCorrect;
  final double avgConfidenceOnCorrect;
  final double avgConfidenceOnWrong;
  final List<EvalCaseOutcome> outcomes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode,
        'provider': providerLabel,
        'cases': cases,
        'strictPass': strictPass,
        'acceptablePass': acceptablePass,
        'fail': fail,
        'safetyCriticalFailures': safetyCriticalFailures,
        'mustNotViolations': mustNotViolations,
        'localRuleFailures': localRuleFailures,
        'multiItemFailures': multiItemFailures,
        'overconfidentWrong': overconfidentWrong,
        'underconfidentCorrect': underconfidentCorrect,
        'avgConfidenceOnCorrect': avgConfidenceOnCorrect,
        'avgConfidenceOnWrong': avgConfidenceOnWrong,
        'outcomes': outcomes.map((e) => e.toJson()).toList(),
      };
}
