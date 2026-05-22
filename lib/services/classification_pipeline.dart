import 'dart:typed_data';

import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';
import 'layer0_disposal_mapping.dart';
import 'layer0_router.dart';
import 'local_classifier_service.dart';

/// Orchestrates the multi-layer classification pipeline:
/// Layer 0 (deterministic) → Layer 1 (on-device ML) → Cloud.
///
/// Each layer is tried in order. The first layer that produces a confident
/// result short-circuits the pipeline. The `classificationLayer` field on
/// the returned `WasteClassification` records which layer handled it.
class ClassificationPipeline {
  ClassificationPipeline({
    required this.layer0Router,
    required this.localClassifier,
  });

  final Layer0Router layer0Router;
  final LocalClassifier localClassifier;

  /// Try only local layers (Layer 0 + Layer 1) and return null if all escalate.
  ///
  /// Use this when the caller manages cloud classification separately.
  /// Returns a [WasteClassification] when a local layer accepted the result,
  /// or `null` when all local layers escalated or failed.
  Future<WasteClassification?> tryLocalOnly({
    required Uint8List imageBytes,
    required String region,
    String? barcode,
  }) async {
    // Layer 0: Deterministic classification (barcode + color histogram).
    try {
      final layer0Result = await layer0Router.classify(
        imageBytes: imageBytes,
        barcode: barcode,
        region: region,
      );

      if (layer0Result.decision == Layer0Decision.accept &&
          layer0Result.wasteClassification != null) {
        WasteAppLogger.aiEvent(
          'Pipeline: Layer 0 accepted',
          model: 'layer0_deterministic',
          context: {
            'route_reason': layer0Result.routeReason,
            'processing_time_ms': layer0Result.totalProcessingTimeMs,
          },
        );
        return layer0Result.wasteClassification!.copyWith(
          classificationLayer: 'layer0_deterministic',
        );
      }

      WasteAppLogger.aiEvent(
        'Pipeline: Layer 0 ${layer0Result.decision.name}',
        model: 'layer0_deterministic',
        context: {
          'route_reason': layer0Result.routeReason,
          'processing_time_ms': layer0Result.totalProcessingTimeMs,
        },
      );
    } catch (e, s) {
      WasteAppLogger.warning('Pipeline: Layer 0 error, falling through',
          error: e, stackTrace: s);
    }

    // Layer 1: On-device ML (if model is loaded and available).
    if (localClassifier.isModelLoaded) {
      try {
        final localResult = await localClassifier.classify(
          imageBytes: imageBytes,
          region: region,
        );

        if (!localResult.requiresEscalation) {
          WasteAppLogger.aiEvent(
            'Pipeline: Layer 1 accepted',
            model: localResult.modelVersion,
            context: {
              'category': localResult.category,
              'confidence': localResult.confidence,
              'processing_time_ms': localResult.processingTimeMs,
            },
          );
          return buildLocalClassification(
            localResult: localResult,
            region: region,
          );
        }

        WasteAppLogger.aiEvent(
          'Pipeline: Layer 1 escalation',
          model: localResult.modelVersion,
          context: {
            'should_escalate': localResult.shouldEscalateToCloud,
            'is_safety_sensitive': localResult.isSafetySensitive,
            'confidence': localResult.confidence,
          },
        );
      } catch (e, s) {
        WasteAppLogger.warning('Pipeline: Layer 1 error, falling through',
            error: e, stackTrace: s);
      }
    }

    return null;
  }

  /// Try local layers and return the full [Layer0Result] for offline hint use.
  ///
  /// Unlike [tryLocalOnly], this returns the raw [Layer0Result] so the caller
  /// can inspect [Layer0Decision.hint] to show a degraded result when offline.
  /// Returns `null` only if Layer 0 threw an exception (no result at all).
  Future<({WasteClassification? accepted, Layer0Result? layer0Result})>
      tryLocalWithHint({
    required Uint8List imageBytes,
    required String region,
    String? barcode,
  }) async {
    Layer0Result? layer0Result;
    try {
      layer0Result = await layer0Router.classify(
        imageBytes: imageBytes,
        barcode: barcode,
        region: region,
      );

      if (layer0Result.decision == Layer0Decision.accept &&
          layer0Result.wasteClassification != null) {
        WasteAppLogger.aiEvent(
          'Pipeline (hint): Layer 0 accepted',
          model: 'layer0_deterministic',
          context: {
            'route_reason': layer0Result.routeReason,
            'processing_time_ms': layer0Result.totalProcessingTimeMs,
          },
        );
        return (
          accepted: layer0Result.wasteClassification!.copyWith(
            classificationLayer: 'layer0_deterministic',
          ),
          layer0Result: layer0Result,
        );
      }

      WasteAppLogger.aiEvent(
        'Pipeline (hint): Layer 0 ${layer0Result.decision.name}',
        model: 'layer0_deterministic',
        context: {
          'route_reason': layer0Result.routeReason,
          'processing_time_ms': layer0Result.totalProcessingTimeMs,
        },
      );
    } catch (e, s) {
      WasteAppLogger.warning('Pipeline (hint): Layer 0 error',
          error: e, stackTrace: s);
    }

    // Layer 1 check skipped for hint path — the purpose is offline fallback.
    return (accepted: null, layer0Result: layer0Result);
  }

  /// Run the full classification pipeline including cloud fallback.
  ///
  /// [imageBytes] — raw image data to classify.
  /// [region] — user region (e.g. 'Bangalore, IN').
  /// [barcode] — optional barcode string for Layer 0 lookup.
  /// [cloudClassifier] — called when all local layers escalate or fail.
  ///   Should perform cloud classification and return a [WasteClassification].
  Future<WasteClassification> classify({
    required Uint8List imageBytes,
    required String region,
    String? barcode,
    required Future<WasteClassification> Function({
      required Uint8List imageBytes,
      required String imageName,
      required String region,
      required String language,
    }) cloudClassifier,
  }) async {
    final localResult = await tryLocalOnly(
      imageBytes: imageBytes,
      region: region,
      barcode: barcode,
    );
    if (localResult != null) return localResult;

    // Layer 2/3: Cloud classification (cheap then strong fallback).
    final cloudResult = await cloudClassifier(
      imageBytes: imageBytes,
      imageName: 'capture.jpg',
      region: region,
      language: 'en',
    );

      return cloudResult.copyWith(
        classificationLayer: 'layer2_cloud_cheap',
        analysisSource: cloudResult.analysisSource ??
            WasteClassification.analysisSourceCloudPrimary,
      );
  }

  /// Build a [WasteClassification] from a [LocalClassificationResult].
  ///
  /// Public so callers can construct a classification from a local result
  /// without going through the full pipeline.
  WasteClassification buildLocalClassification({
    required LocalClassificationResult localResult,
    required String region,
  }) {
    final disposal = Layer0DisposalMapping.getDisposalInstructions(
      localResult.category,
      localResult.subcategory,
    );

    return WasteClassification(
      itemName: localResult.subcategory ?? localResult.category,
      category: localResult.category,
      subcategory: localResult.subcategory,
      explanation:
          'Classified by on-device model (${localResult.modelVersion}).',
      disposalInstructions: disposal ??
          DisposalInstructions(
            primaryMethod: 'Follow local waste guidelines',
            steps: ['Identify the correct waste category'],
            hasUrgentTimeframe: false,
          ),
      region: region,
      visualFeatures:
          localResult.subcategory != null ? [localResult.subcategory!] : [],
      alternatives: [],
      confidence: localResult.confidence,
      modelSource: 'layer1_on_device',
      modelVersion: localResult.modelVersion,
      classificationLayer: 'layer1_on_device',
      source: 'layer1_on_device',
      analysisSource: WasteClassification.analysisSourceLocalExperimental,
    );
  }
}
