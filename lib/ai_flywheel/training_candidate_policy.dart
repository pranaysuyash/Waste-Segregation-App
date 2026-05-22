class TrainingConsentSnapshot {
  const TrainingConsentSnapshot({
    required this.enabled,
    required this.policyVersion,
    this.revokedAt,
  });

  final bool enabled;
  final String policyVersion;
  final DateTime? revokedAt;
}

class TrainingCandidateRecord {
  const TrainingCandidateRecord({
    required this.candidateId,
    required this.reviewStatus,
    required this.consentEnabledAtCapture,
    required this.policyVersion,
    required this.deletedAt,
    required this.excludedFromTrainingAt,
  });

  final String candidateId;
  final String reviewStatus;
  final bool consentEnabledAtCapture;
  final String policyVersion;
  final DateTime? deletedAt;
  final DateTime? excludedFromTrainingAt;
}

class TrainingCandidatePolicy {
  static const List<String> reviewStates = <String>[
    'unreviewed',
    'approved',
    'rejected',
    'needs_redaction',
    'golden',
    'training_eligible',
    'deleted',
  ];

  static bool shouldCreateCandidate(TrainingConsentSnapshot consent) {
    if (!consent.enabled) return false;
    if (consent.revokedAt != null) return false;
    return true;
  }

  static bool exportEligible(TrainingCandidateRecord record) {
    if (!record.consentEnabledAtCapture) return false;
    if (record.deletedAt != null) return false;
    if (record.excludedFromTrainingAt != null) return false;
    if (record.reviewStatus != 'training_eligible' && record.reviewStatus != 'golden') {
      return false;
    }
    return true;
  }
}
