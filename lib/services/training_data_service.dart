import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/models/classification_feedback.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/enhanced_image_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

enum TrainingCandidateEnqueueStatus {
  skippedNoConsent,
  skippedChildProfile,
  enqueued,
  failed,
}

class TrainingCandidateEnqueueResult {
  const TrainingCandidateEnqueueResult({
    required this.status,
    this.candidateId,
    this.reason,
  });

  final TrainingCandidateEnqueueStatus status;
  final String? candidateId;
  final String? reason;
}

class TrainingReviewCandidate {
  const TrainingReviewCandidate({
    required this.id,
    required this.reviewStatus,
    required this.createdAt,
    required this.datasetEligible,
    required this.imageStoragePath,
    required this.category,
    required this.subcategory,
    required this.itemName,
    required this.userIdHash,
  });

  factory TrainingReviewCandidate.fromMap(Map<String, dynamic> map) {
    final review = (map['review'] as Map?)?.cast<String, dynamic>() ?? {};
    final dataset = (map['dataset'] as Map?)?.cast<String, dynamic>() ?? {};
    final image = (map['image'] as Map?)?.cast<String, dynamic>() ?? {};
    final modelPrediction =
        (map['modelPrediction'] as Map?)?.cast<String, dynamic>() ?? {};
    return TrainingReviewCandidate(
      id: '${map['id'] ?? map['candidateId'] ?? ''}',
      reviewStatus: '${review['status'] ?? 'unreviewed'}',
      createdAt: map['createdAt']?.toString(),
      datasetEligible: dataset['eligible'] == true,
      imageStoragePath: image['storagePath']?.toString(),
      category: modelPrediction['category']?.toString(),
      subcategory: modelPrediction['subcategory']?.toString(),
      itemName: modelPrediction['itemName']?.toString(),
      userIdHash: map['userIdHash']?.toString(),
    );
  }

  final String id;
  final String reviewStatus;
  final String? createdAt;
  final bool datasetEligible;
  final String? imageStoragePath;
  final String? category;
  final String? subcategory;
  final String? itemName;
  final String? userIdHash;
}

/// Consent-gated training data pipeline facade.
///
/// V1 intentionally collects metadata and labels only. Image upload is a later
/// phase behind the same explicit consent gate plus EXIF stripping, PII scan,
/// redaction/review, and retention controls.
class TrainingDataService {
  TrainingDataService({
    required StorageService storageService,
    FirebaseFunctions? functions,
  })  : _storageService = storageService,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  static const String policyVersion = trainingDataPolicyVersionV1;

  final StorageService _storageService;
  final FirebaseFunctions _functions;
  final EnhancedImageService _imageService = EnhancedImageService();

  Future<TrainingCandidateEnqueueResult> enqueueCandidateForClassification(
    WasteClassification classification, {
    String captureSource = 'classification_completed',
  }) async {
    try {
      final profile = await _storageService.getCurrentUserProfile();
      final consent = profile?.trainingConsent ?? TrainingConsent.disabled();
      if (!consent.enabled) {
        return const TrainingCandidateEnqueueResult(
          status: TrainingCandidateEnqueueStatus.skippedNoConsent,
          reason: 'training_consent_disabled',
        );
      }

      if (profile?.role == UserRole.child) {
        return const TrainingCandidateEnqueueResult(
          status: TrainingCandidateEnqueueStatus.skippedChildProfile,
          reason: 'child_profiles_require_guardian_flow',
        );
      }

      final callable = _functions.httpsCallable('enqueueTrainingCandidate');
      final imagePayload = await _buildImagePayload(classification);
      final response = await callable.call<Map<String, dynamic>>({
        'captureSource': captureSource,
        'classification': _classificationPayload(classification),
        'consent': consent.toJson(),
        'image': imagePayload,
      });

      final data = response.data;
      return TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.enqueued,
        candidateId: data['candidateId'] as String?,
      );
    } catch (e, s) {
      WasteAppLogger.warning(
        'Training candidate enqueue failed; user flow continues',
        error: e,
        stackTrace: s,
        context: {
          'classificationId': classification.id,
          'service': 'TrainingDataService',
        },
      );
      return TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.failed,
        reason: e.toString(),
      );
    }
  }

  Future<void> attachFeedbackToCandidate({
    required WasteClassification classification,
    required ClassificationFeedback feedback,
  }) async {
    try {
      final profile = await _storageService.getCurrentUserProfile();
      if (profile?.trainingConsent.enabled != true) {
        return;
      }

      final callable = _functions.httpsCallable('attachTrainingLabelFeedback');
      await callable.call<void>({
        'classificationId': classification.id,
        'feedback': feedback.toJson(),
      });
    } catch (e, s) {
      WasteAppLogger.warning(
        'Training label feedback attach failed; feedback flow continues',
        error: e,
        stackTrace: s,
        context: {
          'classificationId': classification.id,
          'feedbackId': feedback.id,
          'service': 'TrainingDataService',
        },
      );
    }
  }

  Future<void> revokeConsentAndRequestDeletion({
    String source = 'settings',
  }) async {
    final profile = await _storageService.getCurrentUserProfile();
    final previous = profile?.trainingConsent ?? TrainingConsent.disabled();
    await _storageService.updateTrainingConsent(
      previous.copyWith(
        enabled: false,
        revokedAt: DateTime.now(),
        source: source,
      ),
    );

    try {
      final callable = _functions.httpsCallable('revokeTrainingConsent');
      await callable.call<void>({
        'policyVersion': previous.policyVersion,
        'source': source,
      });
    } catch (e, s) {
      WasteAppLogger.warning(
        'Training consent revocation cloud marker failed',
        error: e,
        stackTrace: s,
        context: {'service': 'TrainingDataService'},
      );
    }
  }

  Future<List<TrainingReviewCandidate>> getTrainingReviewQueue({
    String? status,
    int limit = 50,
  }) async {
    final callable = _functions.httpsCallable('getTrainingReviewQueue');
    final response = await callable.call<Map<String, dynamic>>({
      'status': status,
      'limit': limit,
    });
    final items = (response.data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(TrainingReviewCandidate.fromMap)
        .toList();
    return items;
  }

  Future<void> reviewTrainingCandidate({
    required String candidateId,
    required String status,
    String? notes,
  }) async {
    final callable = _functions.httpsCallable('reviewTrainingCandidate');
    await callable.call<void>({
      'candidateId': candidateId,
      'status': status,
      'notes': notes,
    });
  }

  Map<String, dynamic> _classificationPayload(WasteClassification c) {
    return {
      'classificationId': c.id,
      'itemName': c.itemName,
      'category': c.category,
      'subCategory': c.normalizedSubcategory,
      'materials': c.normalizedMaterials,
      'confidence': c.confidence,
      'modelSource': c.modelSource,
      'modelVersion': c.modelVersion,
      'region': c.region,
      'createdAt': c.timestamp.toIso8601String(),
      'clarificationNeeded': c.clarificationNeeded,
      'riskLevel': c.riskLevel,
      'barcodePresent': c.barcode?.trim().isNotEmpty == true,
      'qualityScore': c.qualityScore,
      'qualityReasons': c.qualityReasons,
      'duplicateScore': c.duplicateScore,
      'duplicateClusterId': c.duplicateClusterId,
      'rawConfidence': c.rawConfidence ?? c.confidence,
      'calibratedConfidence': c.calibratedConfidence ?? c.confidence,
      'needsReview': c.needsReview,
      'reviewReason': c.reviewReason,
      'routeDecision': c.routeDecision,
      'routeReason': c.routeReason,
      'policyPackId': c.policyPackId,
      'modelRoute': c.modelRoute,
      'routeLatencyMs': c.routeLatencyMs,
      'routeCostUsd': c.routeCostUsd,
    };
  }

  Future<Map<String, dynamic>> _buildImagePayload(
    WasteClassification c,
  ) async {
    final fallback = _imageMetadataPayload(c);
    try {
      final rawBytes = await _loadLocalImageBytes(c);
      if (rawBytes == null || rawBytes.isEmpty) {
        return fallback;
      }

      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        return fallback;
      }

      // Re-encode from decoded pixels to strip EXIF and standardize format.
      final oriented = img.bakeOrientation(decoded);
      final normalized = _resizeIfNeeded(oriented, maxEdge: 1280);
      final encoded =
          Uint8List.fromList(img.encodeJpg(normalized, quality: 82));
      final contentHash = sha256.convert(encoded).toString();

      return {
        'contentHash': contentHash,
        'perceptualHash': null,
        'storagePath': null,
        'thumbnailPath': null,
        'mimeType': 'image/jpeg',
        'width': normalized.width,
        'height': normalized.height,
        'exifStripped': true,
        'redactionStatus': 'pending_scan',
        'rawRetentionDays': 30,
        'hasPotentialText': c.barcode?.trim().isNotEmpty == true,
        'base64': base64Encode(encoded),
      };
    } catch (e, s) {
      WasteAppLogger.warning(
        'Training image preprocessing failed; fallback to metadata-only candidate',
        error: e,
        stackTrace: s,
        context: {
          'classificationId': c.id,
          'service': 'TrainingDataService',
        },
      );
      return fallback;
    }
  }

  Map<String, dynamic> _imageMetadataPayload(WasteClassification c) {
    return {
      'contentHash': c.imageHash,
      'perceptualHash': null,
      'storagePath': null,
      'thumbnailPath': null,
      'mimeType': null,
      'width': c.imageMetrics?['width'],
      'height': c.imageMetrics?['height'],
      'exifStripped': null,
      'redactionStatus': 'not_collected_metadata_only',
      'rawRetentionDays': 0,
    };
  }

  Future<Uint8List?> _loadLocalImageBytes(WasteClassification c) async {
    if (kIsWeb) return null;

    final candidates = <String>[
      if (c.imageRelativePath != null && c.imageRelativePath!.isNotEmpty)
        c.imageRelativePath!,
      if (c.imageUrl != null &&
          c.imageUrl!.isNotEmpty &&
          !c.imageUrl!.startsWith('http'))
        c.imageUrl!,
    ];

    for (final candidate in candidates) {
      final resolved = await _imageService.resolveTrustedLocalPath(candidate);
      if (resolved == null) continue;
      final file = File(resolved);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
    }

    return null;
  }

  img.Image _resizeIfNeeded(img.Image image, {required int maxEdge}) {
    if (image.width <= maxEdge && image.height <= maxEdge) return image;
    if (image.width >= image.height) {
      final resizedHeight = (image.height * maxEdge / image.width).round();
      return img.copyResize(image, width: maxEdge, height: resizedHeight);
    }
    final resizedWidth = (image.width * maxEdge / image.height).round();
    return img.copyResize(image, width: resizedWidth, height: maxEdge);
  }
}

void enqueueTrainingCandidateInBackground(
  TrainingDataService? service,
  WasteClassification classification, {
  required String captureSource,
}) {
  if (service == null) return;
  unawaited(
    service.enqueueCandidateForClassification(
      classification,
      captureSource: captureSource,
    ),
  );
}
