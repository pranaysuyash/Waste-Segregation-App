import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/classification_cache_key.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';
import 'package:waste_segregation_app/services/parsers/ai_response_parser.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response_adapter.dart';

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
  });

  final LocalPolicyEngine policyEngine;
  final ClassificationCacheService cacheService;
  final bool cachingEnabled;
  final String promptVersion;
  final String schemaVersion;
  final String localGuidelinesVersion;

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

    final parserMap =
        AiProviderResponseAdapter.toParserMap(providerResponse);

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
    return '$rawContentHash::${_buildContextSignature(
      region: region,
      language: language,
      provider: provider,
      model: model,
    )}';
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
    if (!decision.policyApplied) {
      return classification;
    }

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
      baseRegulations['policy_compliance_status'] =
          decision.complianceStatus!;
    }
    if (decision.warnings.isNotEmpty) {
      baseRegulations['policy_warning_count'] =
          decision.warnings.length.toString();
    }
    if (decision.violations.isNotEmpty) {
      baseRegulations['policy_violation_count'] =
          decision.violations.length.toString();
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
}
