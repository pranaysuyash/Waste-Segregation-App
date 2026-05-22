import 'dart:typed_data';

import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';
import 'barcode_lookup_service.dart';
import 'color_histogram_classifier.dart';
import 'layer0_disposal_mapping.dart';
import 'local_classifier_service.dart';

/// Routing decision from Layer 0.
enum Layer0Decision {
  /// Accept — skip AI, use Layer 0 result directly.
  accept,

  /// Hint — Layer 0 has a suggestion but not enough confidence to accept.
  /// Fall through to AI; the hint may bias the prompt in future.
  hint,

  /// Escalate — safety-sensitive category detected; must go through AI.
  escalate,

  /// Reject — Layer 0 could not produce a result; proceed to AI.
  reject,
}

/// Complete result from Layer 0 routing.
class Layer0Result {
  Layer0Result({
    required this.decision,
    this.classificationResult,
    this.barcodeResult,
    this.wasteClassification,
    required this.totalProcessingTimeMs,
    this.routeReason,
  });

  final Layer0Decision decision;
  final LocalClassificationResult? classificationResult;
  final BarcodeLookupResult? barcodeResult;
  final WasteClassification? wasteClassification;
  final int totalProcessingTimeMs;
  final String? routeReason;
}

/// Orchestrates Layer 0 deterministic classification.
///
/// Runs barcode lookup (if barcode provided) and color histogram analysis,
/// then decides whether to accept, hint, escalate, or reject.
///
/// When [accept], builds a complete [WasteClassification] using
/// [Layer0DisposalMapping] — no AI call needed.
class Layer0Router {
  Layer0Router({
    required this.colorClassifier,
    required this.barcodeService,
  });

  final ColorHistogramClassifier colorClassifier;
  final BarcodeLookupService barcodeService;

  /// Acceptance confidence threshold for non-safety items.
  static const double acceptThreshold = 0.90;

  /// Hint confidence threshold — below this, reject outright.
  static const double hintThreshold = 0.50;

  Future<Layer0Result> classify({
    Uint8List? imageBytes,
    String? barcode,
    required String region,
  }) async {
    final sw = Stopwatch()..start();

    // Phase 1: Barcode lookup (if provided).
    BarcodeLookupResult? barcodeResult;
    if (barcode != null && barcode.trim().isNotEmpty) {
      barcodeResult = await barcodeService.lookup(barcode.trim(), region: region);

      if (barcodeResult.found && barcodeResult.category != null) {
        final barcodeCategory = barcodeResult.category!;

        // Safety-sensitive categories always escalate, even from barcode.
        if (_isSafetyCategory(barcodeCategory)) {
          sw.stop();
          WasteAppLogger.aiEvent(
            'Layer 0: barcode hit but safety category — escalating',
            model: 'layer0',
          );
          return Layer0Result(
            decision: Layer0Decision.escalate,
            barcodeResult: barcodeResult,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: 'barcode_safety_escalate',
          );
        }

        if (barcodeResult.confidence >= acceptThreshold) {
          final wc = _buildWasteClassification(
            category: barcodeResult.category!,
            subcategory: barcodeResult.subcategory,
            confidence: barcodeResult.confidence,
            region: region,
            source: 'barcode:${barcodeResult.source}',
            productName: barcodeResult.productName,
            brand: barcodeResult.brand,
          );
          sw.stop();
          return Layer0Result(
            decision: Layer0Decision.accept,
            barcodeResult: barcodeResult,
            wasteClassification: wc,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: 'barcode_accept',
          );
        }

        // Barcode found but below accept threshold — use as hint.
        if (barcodeResult.confidence >= hintThreshold) {
          sw.stop();
          return Layer0Result(
            decision: Layer0Decision.hint,
            barcodeResult: barcodeResult,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: 'barcode_hint',
          );
        }
      }
    }

    // Phase 2: Color histogram analysis (if image provided).
    LocalClassificationResult? colorResult;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        colorResult = await colorClassifier.classify(
          imageBytes: imageBytes,
          region: region,
        );

        if (colorResult.failureReason == null &&
            colorResult.confidence >= acceptThreshold &&
            !colorResult.requiresEscalation) {
          final wc = _buildWasteClassification(
            category: colorResult.category,
            subcategory: colorResult.subcategory,
            confidence: colorResult.confidence,
            region: region,
            source: 'color_histogram',
          );
          sw.stop();
          return Layer0Result(
            decision: Layer0Decision.accept,
            classificationResult: colorResult,
            barcodeResult: barcodeResult,
            wasteClassification: wc,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: 'color_accept',
          );
        }

        if (colorResult.requiresEscalation && colorResult.confidence >= hintThreshold) {
          sw.stop();
          return Layer0Result(
            decision: Layer0Decision.escalate,
            classificationResult: colorResult,
            barcodeResult: barcodeResult,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: colorResult.isSafetySensitive
                ? 'color_safety_escalate'
                : 'color_requires_escalation',
          );
        }

        if (colorResult.confidence >= hintThreshold) {
          sw.stop();
          return Layer0Result(
            decision: Layer0Decision.hint,
            classificationResult: colorResult,
            barcodeResult: barcodeResult,
            totalProcessingTimeMs: sw.elapsedMilliseconds,
            routeReason: 'color_hint',
          );
        }
      } catch (e) {
        WasteAppLogger.warning('Layer 0 color analysis failed', error: e);
        // Fall through to reject.
      }
    }

    // Neither path accepted — reject and let AI handle it.
    sw.stop();
    return Layer0Result(
      decision: Layer0Decision.reject,
      classificationResult: colorResult,
      barcodeResult: barcodeResult,
      totalProcessingTimeMs: sw.elapsedMilliseconds,
      routeReason: 'no_path_accepted',
    );
  }

  /// Build a complete [WasteClassification] from Layer 0 data.
  WasteClassification _buildWasteClassification({
    required String category,
    String? subcategory,
    required double confidence,
    required String region,
    required String source,
    String? productName,
    String? brand,
  }) {
    final disposal = Layer0DisposalMapping.getDisposalInstructions(
      category,
      subcategory,
    );

    final itemName = productName ?? subcategory ?? category;

    return WasteClassification(
      itemName: itemName,
      category: category,
      subcategory: subcategory,
      explanation: 'Classified by deterministic Layer 0 ($source). '
          'This item matches known patterns for $category'
          '${subcategory != null ? ' / $subcategory' : ''}.',
      disposalInstructions: disposal ?? DisposalInstructions(
        primaryMethod: 'Follow local waste guidelines',
        steps: [
          'Identify the correct waste category',
          'Place in the appropriate bin',
          'Follow local collection schedule',
        ],
        hasUrgentTimeframe: false,
      ),
      region: region,
      visualFeatures: subcategory != null ? [subcategory] : [],
      alternatives: [],
      confidence: confidence,
      modelSource: 'layer0_deterministic',
      modelVersion: '1.0.0',
      source: source,
      brand: brand,
    );
  }

  /// Check if a category is safety-sensitive and must always escalate.
  static bool _isSafetyCategory(String category) {
    const safetyCategories = {
      'Hazardous Waste',
      'Medical Waste',
      'Medical',
      'E-Waste',
      'Electronic Waste',
      'Chemical Waste',
      'Chemical',
      'Sharps',
      'Pharmaceutical Waste',
      'Pharmaceutical',
    };
    return safetyCategories.contains(category);
  }
}
