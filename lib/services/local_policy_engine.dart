import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/society_policy_override.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
import 'package:waste_segregation_app/services/local_policy_rule_packs.dart';
import 'package:waste_segregation_app/services/society_policy_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Versioned policy pack metadata for provenance and rollout tracking.
class LocalPolicyRulePack {
  const LocalPolicyRulePack({
    required this.rulePackId,
    required this.pluginId,
    required this.authorityName,
    required this.region,
    required this.guidelinesVersion,
    required this.governanceStage,
    required this.owningTeam,
    required this.categories,
    required this.rules,
    this.sourceUrl,
    this.sourceTitle,
    this.helpline,
    this.lastVerified,
    this.nextReviewDue,
    this.trustTier,
    this.sourceStatus = 'unverified',
    this.authorityStatus = 'unknown',
    this.localName,
  });

  final String rulePackId;
  final String pluginId;
  final String authorityName;
  final String region;
  final String guidelinesVersion;
  final String governanceStage;
  final String owningTeam;
  final List<String> categories;
  final List<LocalPolicyRule> rules;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? helpline;
  final String? lastVerified;
  final String? nextReviewDue;
  final String? trustTier;
  final String sourceStatus;
  final String authorityStatus;
  final String? localName;
}

/// Canonical compliance result produced before policy mutations are applied.
class LocalPolicyComplianceEvaluation {
  const LocalPolicyComplianceEvaluation({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.recommendations,
  });

  final String status;
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;
}

enum LocalPolicyRuleSeverity { violation, warning }

enum LocalPolicyRuleCheckType {
  requiresSpecialDisposalTrue,
  hasUrgentTimeframeTrue,
  isCompostableTrue,
  isRecyclableTrue,
  visualFeatureMustNotContain,
  safetyOverrideAlways,
}

/// Structured rule definition that can be versioned and extended per city.
class LocalPolicyRule {
  const LocalPolicyRule({
    required this.ruleId,
    required this.categoryKey,
    required this.severity,
    required this.checkType,
    required this.message,
    this.targetValue,
  });

  final String ruleId;
  final String categoryKey;
  final LocalPolicyRuleSeverity severity;
  final LocalPolicyRuleCheckType checkType;
  final String message;
  final String? targetValue;
}

/// Dedicated evaluator that computes compliance independently from mutation.
class LocalPolicyComplianceEvaluator {
  const LocalPolicyComplianceEvaluator();

  static const Set<String> _safetyCriticalCategoryKeys = {
    'hazardous_waste',
    'medical_waste',
    'sanitary_waste',
    'special_care_waste',
    'special_care',
  };

  static const Set<String> _safetyVisualSignals = {
    'battery',
    'acid',
    'chemical',
    'medicine',
    'needle',
    'ampoule',
    'syringe',
    'sharps',
    'sharp',
    'biomedical',
  };

  static const Map<String, String> _safetyVisualSignalAliases = {
    'syringes': 'syringe',
    'medicines': 'medicine',
    'ampoules': 'ampoule',
    'batteries': 'battery',
    'chemicals': 'chemical',
  };

  LocalPolicyComplianceEvaluation evaluate({
    required LocalGuidelinesPlugin plugin,
    required WasteClassification classification,
    required LocalPolicyRulePack rulePack,
  }) {
    final isSafetyCritical = _isSafetyCriticalClassification(classification);
    final pluginResult = plugin.validateCompliance(classification);
    final confidence = classification.confidence ?? 1.0;
    final violations = <String>[];
    final warnings = <String>[...pluginResult.warnings];

    if (isSafetyCritical) {
      violations.add(
        '[safety_floor] Special-care handling is required before disposal.',
      );
    }

    for (final v in pluginResult.violations) {
      final severity = _resolvePluginViolationSeverity(
        v,
        confidence,
        isSafetyCritical,
      );
      if (severity == LocalPolicyRuleSeverity.violation) {
        violations.add(v);
      } else {
        warnings.add('[confidence_gated] $v');
      }
    }

    final categoryKey = _toCategoryKey(classification.category);
    final categoryRules = rulePack.rules.where(
      (rule) => rule.categoryKey == categoryKey,
    );

    for (final rule in categoryRules) {
      final passed = _evaluateRule(rule, classification);

      if (passed) continue;

      final severity = _resolveRuleSeverity(
        rule,
        confidence,
        isSafetyCritical,
      );

      if (severity == LocalPolicyRuleSeverity.violation) {
        violations.add('[${rule.ruleId}] ${rule.message}');
      } else {
        warnings.add('[${rule.ruleId}] ${rule.message}');
      }
    }

    var status = 'compliant';
    if (violations.isNotEmpty) {
      status = 'violation';
    } else if (warnings.isNotEmpty) {
      status = 'requires_attention';
    }

    return LocalPolicyComplianceEvaluation(
      status: status,
      violations: violations,
      warnings: warnings,
      recommendations: pluginResult.recommendations,
    );
  }

  /// Resolves the effective severity of a plugin-level violation, applying
  /// confidence gating.
  ///
  /// < 0.70  — violations become warnings unless safety-critical.
  /// ≥0.70    — full enforcement unless rule indicates risk-based exception.
  LocalPolicyRuleSeverity _resolvePluginViolationSeverity(
    String violation,
    double confidence,
    bool isSafetyCritical,
  ) {
    if (isSafetyCritical) return LocalPolicyRuleSeverity.violation;
    if (confidence >= 0.70) return LocalPolicyRuleSeverity.violation;
    return LocalPolicyRuleSeverity.warning;
  }

  /// Resolves the effective severity of a rule-pack rule, applying confidence
  /// gating.
  ///
  /// - >= 0.90  — full enforcement per rule
  /// - 0.70–0.89 — keep configured severity (safety overrides preserved)
  /// - >=0.70 — keep configured severity except safety-critical overrides.
  /// - <0.70  — warnings for non-safety failures.
  LocalPolicyRuleSeverity _resolveRuleSeverity(
    LocalPolicyRule rule,
    double confidence,
    bool isSafetyCritical,
  ) {
    if (rule.checkType == LocalPolicyRuleCheckType.safetyOverrideAlways) {
      return LocalPolicyRuleSeverity.violation;
    }

    if (isSafetyCritical &&
        rule.severity == LocalPolicyRuleSeverity.violation) {
      return LocalPolicyRuleSeverity.violation;
    }

    if (rule.severity == LocalPolicyRuleSeverity.violation &&
        rule.checkType == LocalPolicyRuleCheckType.safetyOverrideAlways) {
      return LocalPolicyRuleSeverity.violation;
    }

    if (confidence >= 0.90) return rule.severity;
    if (confidence >= 0.70) return rule.severity;
    return LocalPolicyRuleSeverity.warning;
  }

  bool _isSafetyCriticalClassification(WasteClassification classification) {
    final categoryKey = _toCategoryKey(classification.category);
    if (_safetyCriticalCategoryKeys.contains(categoryKey)) {
      return true;
    }

    if (classification.requiresSpecialDisposal == true) return true;
    if (classification.hasUrgentTimeframe == true) return true;
    if (_containsSpecialCareSignals(classification)) return true;
    if (_containsSafetyVisualSignal(classification.visualFeatures)) return true;
    if (classification.itemName.trim().isNotEmpty &&
        _containsSafetyVisualSignal([classification.itemName])) {
      return true;
    }

    final metadataSignals = _buildSafetySignalText([
      classification.explanation,
      ...[classification.subCategory, classification.disposalMethod]
          .whereType<String>(),
      ...classification.visualFeatures,
    ]);
    return metadataSignals.any(_safetyVisualSignals.contains);
  }

  bool _containsSafetyVisualSignal(Iterable<String> values) {
    final signals = _buildSafetySignalText(values);
    return signals.any((value) => _isSafetyVisualSignal(value));
  }

  bool _isSafetyVisualSignal(String value) {
    if (value.isEmpty) return false;
    final alias = _safetyVisualSignalAliases[value];
    if (alias != null && _safetyVisualSignals.contains(alias)) {
      return true;
    }
    if (_safetyVisualSignals.contains(value)) return true;
    final singular = _toSingularSafetyToken(value);
    return singular.isNotEmpty && _safetyVisualSignals.contains(singular);
  }

  String _toSingularSafetyToken(String token) {
    final alias = _safetyVisualSignalAliases[token];
    if (alias != null) {
      return alias;
    }

    if (token.endsWith('ies') && token.length > 3) {
      return '${token.substring(0, token.length - 3)}y';
    }
    if (token.endsWith('es') && token.length > 2) {
      return token.substring(0, token.length - 2);
    }
    if (token.endsWith('s') && token.length > 1) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  bool _containsSpecialCareSignals(WasteClassification classification) {
    final normalized = _normalizeTextForSafety([
      classification.itemName,
      classification.explanation,
      classification.subCategory,
      classification.category,
    ].whereType<String>().join(' '));

    if (normalized.contains('special care')) {
      return true;
    }
    if (normalized.contains('specialcare')) {
      return true;
    }
    final tokens =
        normalized.split(RegExp(r'\s+')).where((value) => value.isNotEmpty);
    return tokens.any((token) => token == 'special' || token == 'care') &&
        normalized.contains('care') &&
        normalized.contains('special');
  }

  Set<String> _buildSafetySignalText(Iterable<String> values) {
    final tokens = <String>{};
    for (final value in values.whereType<String>()) {
      final normalized = _normalizeTextForSafety(value);
      final split =
          normalized.split(RegExp(r'\s+')).where((value) => value.isNotEmpty);
      for (final token in split) {
        tokens.add(token);
        final singular = _toSingularSafetyToken(token);
        if (singular.isNotEmpty) {
          tokens.add(singular);
        }
      }
    }
    return tokens;
  }

  String _normalizeTextForSafety(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'[_-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _evaluateRule(LocalPolicyRule rule, WasteClassification classification) {
    switch (rule.checkType) {
      case LocalPolicyRuleCheckType.requiresSpecialDisposalTrue:
        return classification.requiresSpecialDisposal == true;
      case LocalPolicyRuleCheckType.hasUrgentTimeframeTrue:
        return classification.hasUrgentTimeframe == true;
      case LocalPolicyRuleCheckType.isCompostableTrue:
        return classification.isCompostable == true;
      case LocalPolicyRuleCheckType.isRecyclableTrue:
        return classification.isRecyclable == true;
      case LocalPolicyRuleCheckType.visualFeatureMustNotContain:
        final token = (rule.targetValue ?? '').trim().toLowerCase();
        if (token.isEmpty) return true;
        return !classification.visualFeatures
            .map((feature) => feature.toLowerCase())
            .any((feature) => feature.contains(token));
      case LocalPolicyRuleCheckType.safetyOverrideAlways:
        return false;
    }
  }

  String _toCategoryKey(String category) => category
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), '_');
}

/// Canonical outcome of local policy evaluation.
class LocalPolicyDecision {
  const LocalPolicyDecision({
    required this.classification,
    required this.policyApplied,
    required this.evaluatedAt,
    this.pluginId,
    this.authorityName,
    this.guidelinesVersion,
    this.rulePackId,
    this.complianceStatus,
    this.rulePack,
    this.violations = const <String>[],
    this.warnings = const <String>[],
    this.recommendations = const <String>[],
    this.sourceUrl,
    this.sourceTitle,
    this.helpline,
    this.lastVerified,
    this.nextReviewDue,
    this.trustTier,
    this.technicalStatus = 'draft',
    this.sourceStatus = 'unverified',
    this.authorityStatus = 'unknown',
    this.localName,
    this.householdWasteStream = 'unknown',
    this.confidenceGated = false,
    this.confidenceState,
    this.societyId,
    this.societyName,
    this.societyConflictCount = 0,
    this.societyConflicts = const <String>[],
    this.societyOverrides = const <String>[],
    this.originalSeverity,
    this.ruleOverridesApplied = const <String>[],
  });

  final WasteClassification classification;
  final bool policyApplied;
  final DateTime evaluatedAt;
  final String? pluginId;
  final String? authorityName;
  final String? guidelinesVersion;
  final String? rulePackId;
  final String? complianceStatus;
  final LocalPolicyRulePack? rulePack;
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;

  // Provenance card fields
  final String? sourceUrl;
  final String? sourceTitle;
  final String? helpline;
  final String? lastVerified;
  final String? nextReviewDue;
  final String? trustTier;
  final String technicalStatus;
  final String sourceStatus;
  final String authorityStatus;
  final String? localName;
  final String householdWasteStream;
  final bool confidenceGated;
  final String? confidenceState;
  final String? societyId;
  final String? societyName;
  final int societyConflictCount;
  final List<String> societyConflicts;
  final List<String> societyOverrides;
  final List<String> ruleOverridesApplied;
  final String? originalSeverity;
}

class _SocietyRuleLayerResult {
  const _SocietyRuleLayerResult({
    required this.classification,
    required this.societyDecision,
  });

  final WasteClassification classification;
  final SocietyAwareDecision societyDecision;
}

/// Canonical policy engine that routes classification outputs through
/// region-aware municipal/local rules before downstream use.
class LocalPolicyEngine {
  const LocalPolicyEngine({
    LocalPolicyComplianceEvaluator complianceEvaluator =
        const LocalPolicyComplianceEvaluator(),
    LocalPolicyRulePackRegistry rulePackRegistry =
        const LocalPolicyRulePackRegistry(),
  })  : _complianceEvaluator = complianceEvaluator,
        _rulePackRegistry = rulePackRegistry;

  final LocalPolicyComplianceEvaluator _complianceEvaluator;
  final LocalPolicyRulePackRegistry _rulePackRegistry;

  Future<LocalPolicyDecision> applyPolicy({
    required WasteClassification classification,
    required String region,
    String? societyId,
    SocietyPolicyService? societyPolicyService,
  }) async {
    final plugin = LocalGuidelinesManager.getPluginForRegion(region);
    if (plugin == null) {
      WasteAppLogger.info(
        'No local policy plugin matched region',
        context: {'region': region},
      );
      return LocalPolicyDecision(
        classification: classification,
        policyApplied: false,
        evaluatedAt: DateTime.now(),
      );
    }

    final rulePack = _buildRulePack(plugin);
    final confidence = classification.confidence ?? 1.0;
    final confidenceState = _confidenceState(confidence);
    final isConfidenceGated = confidence < 0.70;

    final compliance = _complianceEvaluator.evaluate(
      plugin: plugin,
      classification: classification,
      rulePack: rulePack,
    );

    final updated = await plugin.applyLocalGuidelines(classification);
    final appliedSocietyResult = await _applySocietyOverrides(
      baseClassification: updated,
      societyId: societyId,
      plugin: plugin,
      categoryKey: _toCategoryKey(updated.category),
      confidence: confidence,
      userConfirmed: classification.userConfirmed == true,
      service: societyPolicyService,
    );
    final policyClassification = appliedSocietyResult.classification;

    final warnings = [...compliance.warnings];
    final violations = [...compliance.violations];

    warnings.addAll(appliedSocietyResult.societyDecision.conflicts);
    if (isConfidenceGated) {
      warnings.add(
        'Low-confidence classification: municipal policy is conservative.',
      );
    }

    final freshnessWarnings = _freshnessWarnings(rulePack);
    if (freshnessWarnings.isNotEmpty) {
      warnings.addAll(freshnessWarnings);
    }

    final sourceTrustWarnings = _policySourceTrustWarnings(rulePack);
    if (sourceTrustWarnings.isNotEmpty) {
      warnings.addAll(sourceTrustWarnings);
    }

    String status;
    if (violations.isNotEmpty) {
      status = 'violation';
    } else if (warnings.isNotEmpty) {
      status = 'requires_attention';
    } else {
      status = 'compliant';
    }

    final policyDecision = LocalPolicyDecision(
      classification: policyClassification,
      policyApplied: true,
      evaluatedAt: DateTime.now(),
      pluginId: plugin.pluginId,
      authorityName: plugin.authorityName,
      guidelinesVersion: plugin.guidelinesVersion,
      rulePackId: rulePack.rulePackId,
      complianceStatus: status,
      rulePack: rulePack,
      violations: _dedupeAndSort(violations),
      warnings: _dedupeAndSort(warnings),
      recommendations: compliance.recommendations,
      sourceUrl: rulePack.sourceUrl,
      sourceTitle: rulePack.sourceTitle,
      helpline: rulePack.helpline,
      lastVerified: rulePack.lastVerified,
      nextReviewDue: rulePack.nextReviewDue,
      trustTier: rulePack.trustTier,
      technicalStatus: rulePack.governanceStage,
      sourceStatus: rulePack.sourceStatus,
      authorityStatus: rulePack.authorityStatus,
      localName: rulePack.localName,
      confidenceGated: isConfidenceGated,
      confidenceState: confidenceState,
      householdWasteStream: policyClassification.householdWasteStream,
      societyId: appliedSocietyResult.societyDecision.society?.societyId,
      societyName: appliedSocietyResult.societyDecision.society?.societyName,
      societyConflictCount:
          appliedSocietyResult.societyDecision.conflicts.length,
      societyConflicts: appliedSocietyResult.societyDecision.conflicts,
      societyOverrides: appliedSocietyResult.societyDecision.appliedOverrides
          .map(
            (override) =>
                '${override.categoryKey}:${override.overrideType.name}=${override.value}',
          )
          .toList(),
      ruleOverridesApplied:
          appliedSocietyResult.societyDecision.appliedOverrides
              .map(
                (override) =>
                    '${override.categoryKey}:${override.overrideType.name}',
              )
              .toList(),
    );

    if (societyId != null) {
      WasteAppLogger.info(
        'Applied policy with society override',
        context: {
          'societyId': societyId,
          'region': region,
          'societyConflicts': policyDecision.societyConflictCount,
        },
      );
    }

    return policyDecision;
  }

  LocalPolicyRulePack _buildRulePack(LocalGuidelinesPlugin plugin) {
    final categories = plugin.getColorCoding().keys.toList()..sort();
    final definition = _rulePackRegistry.getPackForPlugin(plugin.pluginId);
    final cityData = plugin.cityData;
    return LocalPolicyRulePack(
      rulePackId: '${plugin.pluginId}:${plugin.guidelinesVersion}',
      pluginId: plugin.pluginId,
      authorityName: plugin.authorityName,
      region: plugin.region,
      guidelinesVersion: plugin.guidelinesVersion,
      governanceStage: definition.governanceStage,
      owningTeam: definition.owningTeam,
      categories: categories,
      rules: definition.rules,
      sourceUrl: cityData?.sourceUrl,
      sourceTitle: cityData?.sourceTitle,
      helpline: cityData?.helpline,
      lastVerified: cityData?.lastVerified,
      nextReviewDue: cityData?.nextReviewDue,
      trustTier: cityData?.trustTier,
      sourceStatus: definition.sourceStatus.isNotEmpty
          ? definition.sourceStatus
          : (cityData?.sourceStatus ?? 'unverified'),
      authorityStatus: definition.authorityStatus.isNotEmpty
          ? definition.authorityStatus
          : (cityData?.authorityStatus ?? 'unknown'),
      localName: cityData?.localName,
    );
  }

  String _confidenceState(double confidence) {
    if (confidence < 0.50) return 'warning_only';
    if (confidence < 0.70) return 'warning_only';
    if (confidence < 0.90) return 'full_softened';
    return 'full';
  }

  List<String> _freshnessWarnings(LocalPolicyRulePack rulePack) {
    if (rulePack.nextReviewDue == null) {
      return const <String>[];
    }

    final reviewDate = DateTime.tryParse(rulePack.nextReviewDue!);
    if (reviewDate == null) {
      return const <String>[
        '[freshness] Policy source review date is missing or malformed.',
      ];
    }

    if (DateTime.now().isAfter(reviewDate)) {
      return <String>[
        '[freshness] Policy source is overdue for review since '
            '${rulePack.nextReviewDue}.',
      ];
    }

    return const <String>[];
  }

  List<String> _policySourceTrustWarnings(LocalPolicyRulePack rulePack) {
    final warnings = <String>[];

    final sourceStatus = rulePack.sourceStatus.toLowerCase().trim();
    if (sourceStatus.isNotEmpty && sourceStatus != 'verified') {
      warnings.add(
        '[source] Policy source status is "$sourceStatus". Treat guidance as '
        'provisional until independently verified.',
      );
    }

    final authorityStatus = rulePack.authorityStatus.toLowerCase().trim();
    if (authorityStatus.isNotEmpty && authorityStatus != 'approved') {
      warnings.add(
        '[authority] Authority status is "$authorityStatus". Confirm before acting '
        'on irreversible disposal steps.',
      );
    }

    return warnings;
  }

  List<String> _dedupeAndSort(Iterable<String> source) {
    final values = <String>{};
    final deduped = <String>[];
    for (final value in source) {
      if (values.add(value)) {
        deduped.add(value);
      }
    }
    deduped.sort();
    return deduped;
  }

  Future<_SocietyRuleLayerResult> _applySocietyOverrides({
    required WasteClassification baseClassification,
    required String? societyId,
    required LocalGuidelinesPlugin plugin,
    required String categoryKey,
    required double confidence,
    required bool userConfirmed,
    required SocietyPolicyService? service,
  }) async {
    if (societyId == null) {
      return _SocietyRuleLayerResult(
        classification: baseClassification,
        societyDecision: const SocietyAwareDecision(
          society: null,
          appliedOverrides: <RuleOverride>[],
          attemptedOverrides: <RuleOverride>[],
          conflicts: <String>[],
        ),
      );
    }

    final resolvedService = service ?? SocietyPolicyService();
    final societyPolicy = await resolvedService.getSocietyPolicy(societyId);
    if (societyPolicy == null) {
      return _SocietyRuleLayerResult(
        classification: baseClassification,
        societyDecision: const SocietyAwareDecision(
          society: null,
          appliedOverrides: <RuleOverride>[],
          attemptedOverrides: <RuleOverride>[],
          conflicts: <String>[],
        ),
      );
    }

    if (societyPolicy.basePluginId != plugin.pluginId) {
      return _SocietyRuleLayerResult(
        classification: baseClassification,
        societyDecision: SocietyAwareDecision(
          society: societyPolicy,
          appliedOverrides: const <RuleOverride>[],
          attemptedOverrides: const <RuleOverride>[],
          conflicts: [
            'Society profile basePluginId (${societyPolicy.basePluginId}) does not '
                'match resolved plugin (${plugin.pluginId}).',
          ],
        ),
      );
    }

    final normalizedCategoryKey = _toCategoryKey(categoryKey);
    final applicableOverrides = societyPolicy.overrides
        .where(
          (override) =>
              _toCategoryKey(override.categoryKey) == normalizedCategoryKey,
        )
        .toList();

    if (applicableOverrides.isEmpty) {
      return _SocietyRuleLayerResult(
        classification: baseClassification,
        societyDecision: SocietyAwareDecision(
          society: societyPolicy,
          appliedOverrides: const <RuleOverride>[],
          attemptedOverrides: const <RuleOverride>[],
          conflicts: const <String>[],
        ),
      );
    }

    if (confidence < 0.70 && !userConfirmed) {
      return _SocietyRuleLayerResult(
        classification: baseClassification,
        societyDecision: SocietyAwareDecision(
          society: societyPolicy,
          appliedOverrides: const <RuleOverride>[],
          attemptedOverrides: applicableOverrides,
          conflicts: const <String>[],
        ),
      );
    }

    var updated = baseClassification;
    final conflicts = <String>[];
    final appliedOverrides = <RuleOverride>[];
    final regulations = Map<String, String>.from(
      updated.localRegulations ?? const <String, String>{},
    );

    final cityColor = plugin.getColorCoding();
    final citySchedule = plugin.getCollectionSchedule();
    final cityDisposal = plugin.getLocalDisposalInstructions(
      baseClassification.category,
      baseClassification.subCategory,
    );

    for (final override in applicableOverrides) {
      switch (override.overrideType) {
        case RuleOverrideType.binColor:
          final cityValue = cityColor[normalizedCategoryKey];
          if (cityValue == null || cityValue.trim().isEmpty) {
            conflicts.add(
              'City bin guidance unavailable for ${normalizedCategoryKey}; '
              'blocking society bin override to preserve municipal safety. '
              '(${override.value}).',
            );
            break;
          }
          if (!_safeEquals(cityValue, override.value)) {
            conflicts.add(
              'City bin guidance conflicts with society bin override '
              '($cityValue vs ${override.value}).',
            );
            break;
          }
          regulations['society_bin_alias'] = override.value;
          appliedOverrides.add(override);
          break;

        case RuleOverrideType.collectionFrequency:
          final cityFrequency =
              citySchedule[normalizedCategoryKey]?['frequency']?.toString();
          if (cityFrequency == null || cityFrequency.trim().isEmpty) {
            conflicts.add(
              'City collection schedule unavailable for ${normalizedCategoryKey}; '
              'blocking society frequency override to preserve municipal safety. '
              '(${override.value}).',
            );
            break;
          }
          if (!_safeEquals(cityFrequency, override.value)) {
            conflicts.add(
              'City collection frequency conflicts with society override '
              '($cityFrequency vs ${override.value}).',
            );
            break;
          }
          regulations['society_pickup_window'] = override.value;
          appliedOverrides.add(override);
          break;

        case RuleOverrideType.disposalMethod:
          final cityDisposalMethod = cityDisposal?['primaryMethod']?.toString();
          if (cityDisposalMethod == null || cityDisposalMethod.trim().isEmpty) {
            conflicts.add(
              'City disposal method unavailable for ${normalizedCategoryKey}; '
              'blocking society disposal override to preserve municipal safety. '
              '(${override.value}).',
            );
            break;
          }
          if (!_safeEquals(cityDisposalMethod, override.value)) {
            conflicts.add(
              'City disposal method conflicts with society override '
              '($cityDisposalMethod vs ${override.value}).',
            );
            break;
          }
          regulations['society_disposal_method'] = override.value;
          appliedOverrides.add(override);
          break;

        case RuleOverrideType.collectionLocation:
          final cityLocation = cityDisposal?['location']?.toString();
          if (cityLocation == null || cityLocation.trim().isEmpty) {
            conflicts.add(
              'City collection location unavailable for ${normalizedCategoryKey}; '
              'blocking society location override to preserve municipal safety. '
              '(${override.value}).',
            );
            break;
          }
          if (!_safeEquals(cityLocation, override.value)) {
            conflicts.add(
              'City collection location conflicts with society override '
              '($cityLocation vs ${override.value}).',
            );
            break;
          }
          regulations['society_collection_location'] = override.value;
          appliedOverrides.add(override);
          break;

        case RuleOverrideType.bannedItem:
          if (updated.visualFeatures.any(
            (feature) => _safeEquals(feature, override.value),
          )) {
            conflicts.add(
              'Visual content contains item banned by society policy: '
              '${override.value}.',
            );
          }
          final banned = _appendPipeSeparatedValue(
            existing: regulations['society_banned_items'],
            value: override.value,
          );
          regulations['society_banned_items'] = banned;
          appliedOverrides.add(override);
          break;

        case RuleOverrideType.customInstruction:
          final instructions = _appendPipeSeparatedValue(
            existing: regulations['society_custom_instructions'],
            value: override.value,
          );
          regulations['society_custom_instructions'] = instructions;
          appliedOverrides.add(override);
          break;
      }
    }

    updated = updated.copyWith(localRegulations: regulations);

    return _SocietyRuleLayerResult(
      classification: updated,
      societyDecision: SocietyAwareDecision(
        society: societyPolicy,
        appliedOverrides: appliedOverrides,
        attemptedOverrides: applicableOverrides,
        conflicts: conflicts,
      ),
    );
  }

  bool _safeEquals(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  String _appendPipeSeparatedValue({
    required String? existing,
    required String value,
  }) {
    final parts = existing
        ?.split('|')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    if (parts == null || parts.isEmpty) {
      return value;
    }
    parts.add(value);
    return parts.join('|');
  }

  WasteClassification _overrideDisposalMethod(
    WasteClassification classification,
    String disposalMethod,
  ) {
    final sourceInstructions = classification.disposalInstructions;
    final nextInstructions = DisposalInstructions(
      primaryMethod: disposalMethod,
      steps: sourceInstructions.steps,
      timeframe: sourceInstructions.timeframe,
      location: sourceInstructions.location,
      warnings: sourceInstructions.warnings,
      tips: sourceInstructions.tips,
      recyclingInfo: sourceInstructions.recyclingInfo,
      estimatedTime: sourceInstructions.estimatedTime,
      hasUrgentTimeframe: sourceInstructions.hasUrgentTimeframe,
    );
    return classification.copyWith(
      disposalMethod: disposalMethod,
      disposalInstructions: nextInstructions,
    );
  }

  WasteClassification _overrideDisposalLocation(
    WasteClassification classification,
    String location,
  ) {
    final sourceInstructions = classification.disposalInstructions;
    final nextInstructions = DisposalInstructions(
      primaryMethod: sourceInstructions.primaryMethod,
      steps: sourceInstructions.steps,
      timeframe: sourceInstructions.timeframe,
      location: location,
      warnings: sourceInstructions.warnings,
      tips: sourceInstructions.tips,
      recyclingInfo: sourceInstructions.recyclingInfo,
      estimatedTime: sourceInstructions.estimatedTime,
      hasUrgentTimeframe: sourceInstructions.hasUrgentTimeframe,
    );
    return classification.copyWith(disposalInstructions: nextInstructions);
  }

  String _toCategoryKey(String category) {
    return category
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
