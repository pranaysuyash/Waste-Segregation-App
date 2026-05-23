import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/training_data_service.dart';

void main() {
  group('TrainingCandidateEnqueueResult', () {
    test('skippedNoConsent status is correct', () {
      const result = TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.skippedNoConsent,
        reason: 'training_consent_disabled',
      );
      expect(result.status, TrainingCandidateEnqueueStatus.skippedNoConsent);
      expect(result.candidateId, isNull);
      expect(result.reason, 'training_consent_disabled');
    });

    test('enqueued status has candidateId', () {
      const result = TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.enqueued,
        candidateId: 'cand_123',
      );
      expect(result.status, TrainingCandidateEnqueueStatus.enqueued);
      expect(result.candidateId, 'cand_123');
    });

    test('skippedChildProfile is a separate status', () {
      const result = TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.skippedChildProfile,
        reason: 'child_profiles_require_guardian_flow',
      );
      expect(result.status, TrainingCandidateEnqueueStatus.skippedChildProfile);
    });

    test('failed status captures error reason', () {
      const result = TrainingCandidateEnqueueResult(
        status: TrainingCandidateEnqueueStatus.failed,
        reason: 'network_error',
      );
      expect(result.status, TrainingCandidateEnqueueStatus.failed);
      expect(result.reason, 'network_error');
    });
  });

  group('TrainingReviewCandidate', () {
    test('parses from map with all fields', () {
      final candidate = TrainingReviewCandidate.fromMap({
        'id': 'cand_abc',
        'review': {'status': 'approved'},
        'dataset': {'eligible': true},
        'image': {'storagePath': 'training/review/2026/05/img.jpg'},
        'modelPrediction': {
          'category': 'Dry Waste',
          'subcategory': 'Plastic bottle',
          'itemName': 'PET bottle',
        },
        'userIdHash': 'hash_123',
        'createdAt': '2026-05-21T10:00:00Z',
      });

      expect(candidate.id, 'cand_abc');
      expect(candidate.reviewStatus, 'approved');
      expect(candidate.datasetEligible, isTrue);
      expect(candidate.imageStoragePath, 'training/review/2026/05/img.jpg');
      expect(candidate.category, 'Dry Waste');
      expect(candidate.subcategory, 'Plastic bottle');
      expect(candidate.itemName, 'PET bottle');
      expect(candidate.userIdHash, 'hash_123');
    });

    test('parses from map with missing fields gracefully', () {
      final candidate = TrainingReviewCandidate.fromMap({});

      expect(candidate.id, '');
      expect(candidate.reviewStatus, 'unreviewed');
      expect(candidate.datasetEligible, isFalse);
      expect(candidate.imageStoragePath, isNull);
      expect(candidate.category, isNull);
    });

    test('parses candidateId as fallback for id', () {
      final candidate = TrainingReviewCandidate.fromMap({
        'candidateId': 'cand_xyz',
      });
      expect(candidate.id, 'cand_xyz');
    });
  });

  group('TrainingConsent model', () {
    test('disabled() factory creates consent with enabled=false', () {
      final consent = TrainingConsent.disabled();
      expect(consent.enabled, isFalse);
      expect(consent.policyVersion, isNotEmpty);
    });

    test('copyWith preserves fields', () {
      final consent = TrainingConsent.disabled();
      final updated = consent.copyWith(
        enabled: true,
        source: 'settings_dialog',
      );
      expect(updated.enabled, isTrue);
      expect(updated.source, 'settings_dialog');
      expect(updated.policyVersion, consent.policyVersion);
    });

    test('toJson includes all fields', () {
      final consent = TrainingConsent.disabled().copyWith(
        enabled: true,
        source: 'test',
      );
      final json = consent.toJson();
      expect(json['enabled'], isTrue);
      expect(json['policyVersion'], isNotEmpty);
      expect(json['source'], 'test');
    });
  });

  group('enqueueTrainingCandidateInBackground', () {
    test('does nothing when service is null', () {
      // Should not throw.
      enqueueTrainingCandidateInBackground(
        null,
        _makeClassification(),
        captureSource: 'test',
      );
    });
  });

  group('TrainingDataService policy', () {
    test('policyVersion constant is set', () {
      expect(TrainingDataService.policyVersion, isNotEmpty);
    });
  });
}

WasteClassification _makeClassification() {
  return WasteClassification(
    itemName: 'Test Item',
    category: 'Dry Waste',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    region: 'Bangalore, IN',
    visualFeatures: [],
    alternatives: [],
  );
}
