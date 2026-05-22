import 'dart:typed_data';

import '../models/offline_degradation_tier.dart';
import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';
import 'classification_pipeline.dart';
import 'layer0_router.dart';
import 'local_classifier_service.dart';

/// Result from an offline classification attempt.
class OfflineClassificationResult {
  OfflineClassificationResult({
    this.classification,
    this.tier = OfflineDegradationTier.queued,
    this.needsCloudVerification = false,
  });

  /// Non-null when a local layer accepted the classification.
  final WasteClassification? classification;

  /// Degradation tier that was active during this attempt.
  final OfflineDegradationTier tier;

  /// True when the classification is a best-guess hint that should be
  /// re-verified by cloud when connectivity returns.
  final bool needsCloudVerification;
}

/// Manages offline classification with degradation tiers.
///
/// Determines what local classification capability is available and
/// routes the request accordingly. Higher tiers produce richer results.
class OfflineClassificationService {
  OfflineClassificationService({
    required this.pipeline,
  });

  final ClassificationPipeline pipeline;

  /// Determine the current degradation tier based on model availability.
  OfflineDegradationTier determineTier() {
    if (pipeline.localClassifier.isModelLoaded) {
      return OfflineDegradationTier.fullOffline;
    }
    // Layer 0 (deterministic) is always available — it's pure math.
    return OfflineDegradationTier.deterministicOnly;
  }

  /// Attempt offline classification at the current tier.
  ///
  /// Returns [OfflineClassificationResult] with the outcome.
  /// When [classification] is null, the caller should queue for cloud.
  Future<OfflineClassificationResult> classifyOffline({
    required Uint8List imageBytes,
    required String region,
    String? barcode,
  }) async {
    final tier = determineTier();

    if (tier == OfflineDegradationTier.queued) {
      return OfflineClassificationResult(tier: tier);
    }

    // Try local layers — returns null when all escalate or fail.
    final localResult = await pipeline.tryLocalOnly(
      imageBytes: imageBytes,
      region: region,
      barcode: barcode,
    );

    if (localResult != null) {
      WasteAppLogger.info(
        'Offline classification accepted at tier $tier',
        context: {
          'category': localResult.category,
          'tier': tier.name,
        },
      );
      return OfflineClassificationResult(
        classification: localResult,
        tier: tier,
        needsCloudVerification: false,
      );
    }

    // Local layers didn't accept — try hint path (Layer 0 hint data).
    final hintResult = await pipeline.tryLocalWithHint(
      imageBytes: imageBytes,
      region: region,
      barcode: barcode,
    );

    if (hintResult.layer0Result?.decision == Layer0Decision.hint &&
        hintResult.accepted == null) {
      // Layer 0 had a hint but not enough confidence — build a degraded result.
      final hintWc = _buildHintClassification(
        hintResult.layer0Result!,
        region,
      );
      if (hintWc != null) {
        WasteAppLogger.info(
          'Offline hint classification at tier $tier',
          context: {
            'category': hintWc.category,
            'tier': tier.name,
          },
        );
        return OfflineClassificationResult(
          classification: hintWc,
          tier: tier,
          needsCloudVerification: true,
        );
      }
    }

    WasteAppLogger.info(
      'Offline classification failed at tier $tier — must queue',
      context: {'tier': tier.name},
    );
    return OfflineClassificationResult(tier: tier);
  }

  WasteClassification? _buildHintClassification(
    Layer0Result layer0Result,
    String region,
  ) {
    final colorResult = layer0Result.classificationResult;
    final barcodeResult = layer0Result.barcodeResult;

    final category = barcodeResult?.category ?? colorResult?.category;
    if (category == null) return null;

    final subcategory =
        barcodeResult?.subcategory ?? colorResult?.subcategory;
    final confidence =
        barcodeResult?.confidence ?? colorResult?.confidence ?? 0.0;

    final wc = pipeline.buildLocalClassification(
      localResult: colorResult ??
          LocalClassificationResult(
            category: category,
            subcategory: subcategory,
            confidence: confidence,
            modelVersion: 'layer0_hint',
          ),
      region: region,
    );

    return wc.copyWith(
      isOfflineHint: true,
      classificationLayer: 'layer0_hint_pending_cloud',
      confidence: confidence,
      explanation:
          'Preliminary classification (offline). This item matches patterns '
          'for $category${subcategory != null ? ' / $subcategory' : ''}. '
          'Will re-verify when connected.',
    );
  }
}
