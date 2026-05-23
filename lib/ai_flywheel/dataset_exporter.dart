import 'dart:convert';
import 'dart:io';

import 'training_candidate_policy.dart';

class DatasetExportSummary {
  const DatasetExportSummary({
    required this.datasetVersion,
    required this.caseCount,
    required this.excludedCounts,
    required this.categoryBreakdown,
    required this.regionBreakdown,
    required this.safetyCriticalCount,
    required this.localRuleCriticalCount,
    required this.inputHash,
  });

  final String datasetVersion;
  final int caseCount;
  final Map<String, int> excludedCounts;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> regionBreakdown;
  final int safetyCriticalCount;
  final int localRuleCriticalCount;
  final String inputHash;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'datasetVersion': datasetVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'sourcePolicyVersion': TrainingCandidatePolicy.canonicalPolicyVersion,
        'caseCount': caseCount,
        'categoryBreakdown': categoryBreakdown,
        'regionBreakdown': regionBreakdown,
        'safetyCriticalCount': safetyCriticalCount,
        'localRuleCriticalCount': localRuleCriticalCount,
        'excludedCounts': excludedCounts,
        'toolVersion': 'ai-dataset-exporter-v2',
        'inputHash': inputHash,
      };
}

class DatasetExporter {
  Future<DatasetExportSummary> export({
    required List<Map<String, dynamic>> rawCandidates,
    required String datasetVersion,
    required String outputDir,
  }) async {
    final eligible = <Map<String, dynamic>>[];
    final excludedRows = <Map<String, dynamic>>[];
    final excluded = <String, int>{
      'noConsent': 0,
      'revoked': 0,
      'pii': 0,
      'unreviewed': 0,
      'rejected': 0,
      'deleted': 0,
      'noVerifiedLabel': 0,
      'stalePolicy': 0,
      'needsRedaction': 0,
    };

    for (final c in rawCandidates) {
      final consent = (c['consent'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final review = (c['review'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final image = (c['image'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final verified = (c['reviewerVerified'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

      final status = (review['status'] as String?) ?? 'unreviewed';
      final privacy = (image['redactionStatus'] as String?) ?? 'pii_pending';
      final hasConsent = consent['enabledAtCapture'] == true;
      final revoked = consent['revokedAt'] != null;
      final deleted = c['deletedAt'] != null;
      final stalePolicy = (consent['policyVersion'] as String?) != TrainingCandidatePolicy.canonicalPolicyVersion;
      final hasVerifiedLabel = (verified['groundTruth'] as Map?) != null || review['verifiedLabel'] != null;

      String? reason;
      if (!hasConsent) {
        reason = 'noConsent';
      } else if (revoked) {
        reason = 'revoked';
      } else if (deleted) {
        reason = 'deleted';
      } else if (status == 'unreviewed' || status == 'approved') {
        reason = 'unreviewed';
      } else if (status == 'rejected') {
        reason = 'rejected';
      } else if (privacy == 'needs_redaction') {
        reason = 'needsRedaction';
      } else if (privacy == 'pii_failed' || privacy == 'rejected') {
        reason = 'pii';
      } else if (!hasVerifiedLabel) {
        reason = 'noVerifiedLabel';
      } else if (stalePolicy) {
        reason = 'stalePolicy';
      }

      if (reason != null) {
        excluded[reason] = (excluded[reason] ?? 0) + 1;
        excludedRows.add(<String, dynamic>{
          'candidateId': c['candidateId'],
          'reason': reason,
          'reviewStatus': status,
          'privacyStatus': privacy,
        });
        continue;
      }

      final exportAllowed = TrainingCandidatePolicy.exportEligible(
        TrainingCandidateRecord(
          candidateId: '${c['candidateId'] ?? ''}',
          reviewStatus: status,
          consentEnabledAtCapture: true,
          policyVersion: '${consent['policyVersion'] ?? TrainingCandidatePolicy.canonicalPolicyVersion}',
          deletedAt: deleted ? DateTime.now() : null,
          excludedFromTrainingAt: c['excludedFromTrainingAt'] != null ? DateTime.now() : null,
          privacyStatus: privacy,
          hasVerifiedLabel: hasVerifiedLabel,
        ),
      );
      if (!exportAllowed) {
        excluded['rejected'] = (excluded['rejected'] ?? 0) + 1;
        excludedRows.add(<String, dynamic>{'candidateId': c['candidateId'], 'reason': 'policyGate'});
        continue;
      }

      eligible.add(c);
    }

    eligible.sort((a, b) => ('${a['candidateId']}').compareTo('${b['candidateId']}'));

    final out = Directory(outputDir);
    out.createSync(recursive: true);

    final manifest = File('$outputDir/manifest.jsonl');
    final labels = File('$outputDir/labels.jsonl');
    final excludedFile = File('$outputDir/excluded.jsonl');
    final datasheet = File('$outputDir/datasheet.md');

    final manifestLines = eligible.map((e) => jsonEncode(e)).join('\n');
    final labelsLines = eligible.map((e) {
      final review = e['review'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final verified = e['reviewerVerified'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final gt = (verified['groundTruth'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      return jsonEncode(<String, dynamic>{
        'candidateId': e['candidateId'],
        'verifiedCategory': gt['category'] ?? review['verifiedLabel'] ?? review['status'],
        'verifiedSubcategory': gt['subcategory'],
        'verifiedMaterialType': gt['material'],
        'status': review['status'],
      });
    }).join('\n');

    manifest.writeAsStringSync('$manifestLines\n');
    labels.writeAsStringSync('$labelsLines\n');
    excludedFile.writeAsStringSync('${excludedRows.map(jsonEncode).join('\n')}\n');

    final categoryBreakdown = <String, int>{};
    final regionBreakdown = <String, int>{};
    var safetyCriticalCount = 0;
    var localRuleCriticalCount = 0;

    for (final e in eligible) {
      final pred = (e['modelPrediction'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final cat = '${pred['category'] ?? 'Unknown'}';
      categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + 1;
      final region = '${pred['region'] ?? 'unknown'}';
      regionBreakdown[region] = (regionBreakdown[region] ?? 0) + 1;
      if (pred['riskLevel'] == 'high' || cat.contains('Hazardous') || cat.contains('Medical')) {
        safetyCriticalCount += 1;
      }
      if ((e['localRuleCritical'] == true) || (pred['localRuleCritical'] == true)) {
        localRuleCriticalCount += 1;
      }
    }

    final canonicalInput = rawCandidates
        .map((e) => jsonEncode(e))
        .toList()
      ..sort();
    final inputHash = canonicalInput.join('|').hashCode.toRadixString(16);

    datasheet.writeAsStringSync(
      '# Dataset $datasetVersion\n\n'
      'Collection policy version: ${TrainingCandidatePolicy.canonicalPolicyVersion}\n\n'
      'Eligible cases: ${eligible.length}\n\n'
      'Limitations:\n'
      '- Contains reviewed candidates only\n'
      '- Excludes revoked/unreviewed/privacy-failed rows\n'
      '- Not a raw image dump\n',
    );

    final summary = DatasetExportSummary(
      datasetVersion: datasetVersion,
      caseCount: eligible.length,
      excludedCounts: excluded,
      categoryBreakdown: categoryBreakdown,
      regionBreakdown: regionBreakdown,
      safetyCriticalCount: safetyCriticalCount,
      localRuleCriticalCount: localRuleCriticalCount,
      inputHash: inputHash,
    );

    File('$outputDir/version.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(summary.toJson()),
    );
    return summary;
  }
}
