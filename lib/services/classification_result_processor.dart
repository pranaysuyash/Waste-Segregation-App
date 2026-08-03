import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/ai_service.dart' show AiService;
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/classification_cache_key.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';
import 'package:waste_segregation_app/services/parsers/ai_response_parser.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response_adapter.dart';
import 'package:waste_segregation_app/services/recycling_taxonomy_service.dart';

/// Processes an [AiProviderResponse] into a fully resolved
/// [WasteClassification] by running it through the standard post-processing
/// pipeline: normalisation, parsing, local policy application, metadata
/// attachment, and caching.
///
/// Extracted from [AiService] to avoid repeating the same 5 steps across the
/// OpenAI, Gemini, and backend provider paths.
class ClassificationResultProcessor {
  ClassificationResultProcessor({
    required this.policyEngine,
    required this.cacheService,
    required this.cachingEnabled,
    required this.promptVersion,
    required this.schemaVersion,
    required this.localGuidelinesVersion,
    required this.taxonomyService,
  });

  final LocalPolicyEngine policyEngine;
  final ClassificationCacheService cacheService;
  final bool cachingEnabled;
  final String promptVersion;
  final String schemaVersion;
  final String localGuidelinesVersion;
  final RecyclingTaxonomyService taxonomyService;

  /// Run the full post-processing pipeline.
  Future<WasteClassification> process({
    required AiProviderResponse providerResponse,
    required String imagePath,
    required String region,
    required String? language,
    required int imageSize,
    String? classificationId,
    String? imageHash,
    String? contentHash,
    String? thumbnailPath,
  }) async {
    final provider = providerResponse.provider;
    final model = providerResponse.model;

    final parserMap = AiProviderResponseAdapter.toParserMap(providerResponse);

    var classification = AiResponseParser.processResponse(
      parserMap,
      imagePath,
      region,
      language,
      null,
      classificationId,
      provider: provider,
      model: model,
      thumbnailPath: thumbnailPath,
    );

    final policyDecision = await policyEngine.applyPolicy(
      classification: classification,
      region: region,
    );
    classification = _attachPolicyDecisionMetadata(
      policyDecision.classification,
      policyDecision,
    );
    final taxonomyDecision = await taxonomyService.resolveFromClassification(
      classification,
    );
    classification = _attachTaxonomyDecisionMetadata(
      classification,
      taxonomyDecision,
    );

    if (cachingEnabled && imageHash != null) {
      final contextAwareContentHash = _buildContextAwareContentHash(
        contentHash,
        region: region,
        language: language,
        provider: provider,
        model: model,
      );
      final contextAwareCacheKey = ClassificationCacheKey.build(
        imageHash: imageHash,
        region: region,
        language: language ?? '',
        promptVersion: promptVersion,
        schemaVersion: schemaVersion,
        localGuidelinesVersion: localGuidelinesVersion,
        provider: provider,
        model: model,
      );
      await cacheService.cacheClassification(
        contextAwareCacheKey,
        classification,
        contentHash: contextAwareContentHash,
        imageSize: imageSize,
        entryImageHash: imageHash,
      );
    }

    return classification;
  }

  String? _buildContextAwareContentHash(
    String? rawContentHash, {
    required String region,
    required String? language,
    required String provider,
    required String model,
  }) {
    if (rawContentHash == null) return null;
    return '$rawContentHash::${_buildContextSignature(region: region, language: language, provider: provider, model: model)}';
  }

  String _buildContextSignature({
    required String region,
    required String? language,
    required String provider,
    required String model,
  }) {
    return ClassificationCacheKey.build(
      imageHash: 'ctx',
      region: region,
      language: language ?? '',
      promptVersion: promptVersion,
      schemaVersion: schemaVersion,
      localGuidelinesVersion: localGuidelinesVersion,
      provider: provider,
      model: model,
    );
  }

  WasteClassification _attachPolicyDecisionMetadata(
    WasteClassification classification,
    LocalPolicyDecision decision,
  ) {
    final baseRegulations = Map<String, String>.from(
      classification.localRegulations ?? const <String, String>{},
    );

    if (decision.rulePackId != null) {
      baseRegulations['policy_rule_pack_id'] = decision.rulePackId!;
    }
    if (decision.pluginId != null) {
      baseRegulations['policy_plugin_id'] = decision.pluginId!;
    }
    if (decision.complianceStatus != null) {
      baseRegulations['policy_compliance_status'] = decision.complianceStatus!;
    }
    if (decision.sourceTitle != null) {
      baseRegulations['policy_source_title'] = decision.sourceTitle!;
    }
    if (decision.localName != null) {
      baseRegulations['policy_local_name'] = decision.localName!;
    }
    if (decision.technicalStatus.isNotEmpty) {
      baseRegulations['policy_technical_status'] = decision.technicalStatus;
    }
    if (decision.sourceStatus.isNotEmpty) {
      baseRegulations['policy_source_status'] = decision.sourceStatus;
    }
    if (decision.authorityStatus.isNotEmpty) {
      baseRegulations['policy_authority_status'] = decision.authorityStatus;
    }
    if (decision.lastVerified != null) {
      baseRegulations['policy_last_verified'] = decision.lastVerified!;
    }
    if (decision.nextReviewDue != null) {
      baseRegulations['policy_next_review_due'] = decision.nextReviewDue!;
    }
    if (decision.trustTier != null) {
      baseRegulations['policy_source_trust_tier'] = decision.trustTier!;
    }
    if (decision.sourceUrl != null) {
      baseRegulations['policy_source_url'] = decision.sourceUrl!;
    }
    if (decision.warnings.isNotEmpty) {
      baseRegulations['policy_warning_count'] =
          decision.warnings.length.toString();
    }
    if (decision.violations.isNotEmpty) {
      baseRegulations['policy_violation_count'] =
          decision.violations.length.toString();
    }
    if (decision.societyId != null) {
      baseRegulations['policy_society_id'] = decision.societyId!;
    }
    if (decision.societyName != null) {
      baseRegulations['policy_society_name'] = decision.societyName!;
    }
    baseRegulations['policy_confidence_state'] = decision.confidenceState ??
        (decision.policyApplied ? 'full' : 'not_applied');
    baseRegulations['policy_society_override_count'] =
        decision.societyConflictCount.toString();
    if (decision.societyConflicts.isNotEmpty) {
      baseRegulations['policy_society_conflicts'] =
          decision.societyConflicts.join('|');
    }
    if (decision.societyOverrides.isNotEmpty) {
      baseRegulations['policy_society_overrides'] =
          decision.societyOverrides.join('|');
    }
    if (decision.ruleOverridesApplied.isNotEmpty) {
      baseRegulations['policy_society_rule_overrides'] =
          decision.ruleOverridesApplied.join('|');
    }
    if (decision.recommendations.isNotEmpty) {
      baseRegulations['policy_recommendations'] =
          decision.recommendations.take(3).join(' | ');
    }
    baseRegulations['policy_evaluated_at'] =
        decision.evaluatedAt.toIso8601String();

    return classification.copyWith(
      localRegulations: baseRegulations,
      bbmpComplianceStatus:
          decision.complianceStatus ?? classification.bbmpComplianceStatus,
      localGuidelinesVersion:
          decision.guidelinesVersion ?? classification.localGuidelinesVersion,
    );
  }

  WasteClassification _attachTaxonomyDecisionMetadata(
    WasteClassification classification,
    RecyclingTaxonomyResolution resolution,
  ) {
    final baseRegulations = Map<String, String>.from(
      classification.localRegulations ?? const <String, String>{},
    );

    if (resolution.version.isNotEmpty) {
      baseRegulations['taxonomy_version'] = resolution.version;
    }
    baseRegulations['taxonomy_resolution_source'] = resolution.source;
    baseRegulations['taxonomy_resolution_method'] = resolution.method;
    baseRegulations['taxonomy_matched_signal'] = resolution.matchedSignal;
    baseRegulations['taxonomy_resolution_confidence'] =
        resolution.confidence.toString();

    if (resolution.familyId != null) {
      baseRegulations['taxonomy_family_id'] = resolution.familyId!;
    }
    if (resolution.categoryId != null) {
      baseRegulations['taxonomy_category_id'] = resolution.categoryId!;
    }
    if (resolution.familyLabel != null) {
      baseRegulations['taxonomy_family_label'] = resolution.familyLabel!;
    }
    if (resolution.categoryLabel != null) {
      baseRegulations['taxonomy_category_label'] = resolution.categoryLabel!;
    }

    return classification.copyWith(
      localRegulations: baseRegulations,
      taxonomyVersion: resolution.version,
      taxonomyFamilyId: resolution.familyId,
      taxonomyCategoryId: resolution.categoryId,
      taxonomyFamilyLabel: resolution.familyLabel,
      taxonomyCategoryLabel: resolution.categoryLabel,
      taxonomySource: resolution.source,
      taxonomyMethod: resolution.method,
      taxonomyConfidence: resolution.confidence,
      taxonomyMatchedSignal: resolution.matchedSignal,
    );
  }
}
