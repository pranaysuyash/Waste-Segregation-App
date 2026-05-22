import 'dart:convert';
import 'dart:io';

import 'training_candidate_policy.dart';

class DatasetExportSummary {
  const DatasetExportSummary({
    required this.datasetVersion,
    required this.caseCount,
    required this.excludedCounts,
  });

  final String datasetVersion;
  final int caseCount;
  final Map<String, int> excludedCounts;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'datasetVersion': datasetVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'sourcePolicyVersion': 'training-data-v1',
        'caseCount': caseCount,
        'excludedCounts': excludedCounts,
      };
}

class DatasetExporter {
  Future<DatasetExportSummary> export({
    required List<Map<String, dynamic>> rawCandidates,
    required String datasetVersion,
    required String outputDir,
  }) async {
    final eligible = <Map<String, dynamic>>[];
    final excluded = <String, int>{
      'noConsent': 0,
      'revoked': 0,
      'pii': 0,
      'unreviewed': 0,
      'rejected': 0,
      'deleted': 0,
    };

    for (final c in rawCandidates) {
      final consent = c['consent'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final review = c['review'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final image = c['image'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      final status = (review['status'] as String?) ?? 'unreviewed';
      final redaction = (image['redactionStatus'] as String?) ?? 'pending';
      final hasConsent = consent['enabledAtCapture'] == true;
      final revoked = consent['revokedAt'] != null;
      final deleted = c['deletedAt'] != null;

      if (!hasConsent) {
        excluded['noConsent'] = excluded['noConsent']! + 1;
        continue;
      }
      if (revoked) {
        excluded['revoked'] = excluded['revoked']! + 1;
        continue;
      }
      if (deleted) {
        excluded['deleted'] = excluded['deleted']! + 1;
        continue;
      }
      if (status == 'unreviewed') {
        excluded['unreviewed'] = excluded['unreviewed']! + 1;
        continue;
      }
      if (status == 'rejected') {
        excluded['rejected'] = excluded['rejected']! + 1;
        continue;
      }
      if (redaction != 'passed' && redaction != 'redacted') {
        excluded['pii'] = excluded['pii']! + 1;
        continue;
      }

      if (!TrainingCandidatePolicy.exportEligible(
        TrainingCandidateRecord(
          candidateId: '${c['candidateId'] ?? ''}',
          reviewStatus: status,
          consentEnabledAtCapture: true,
          policyVersion: '${consent['policyVersion'] ?? 'training-data-v1'}',
          deletedAt: deleted ? DateTime.now() : null,
          excludedFromTrainingAt: c['excludedFromTrainingAt'] != null ? DateTime.now() : null,
        ),
      )) {
        excluded['rejected'] = excluded['rejected']! + 1;
        continue;
      }

      eligible.add(c);
    }

    eligible.sort((a, b) => ('${a['candidateId']}').compareTo('${b['candidateId']}'));

    final out = Directory(outputDir);
    out.createSync(recursive: true);

    final manifest = File('$outputDir/manifest.jsonl');
    final labels = File('$outputDir/labels.jsonl');
    final datasheet = File('$outputDir/datasheet.md');

    final manifestLines = eligible.map((e) => jsonEncode(e)).join('\n');
    final labelsLines = eligible.map((e) {
      final review = e['review'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      return jsonEncode(<String, dynamic>{
        'candidateId': e['candidateId'],
        'verifiedLabel': review['verifiedLabel'] ?? review['status'],
        'status': review['status'],
      });
    }).join('\n');

    manifest.writeAsStringSync('$manifestLines\n');
    labels.writeAsStringSync('$labelsLines\n');
    datasheet.writeAsStringSync('# Dataset $datasetVersion\n\nEligible cases: ${eligible.length}\n');

    final summary = DatasetExportSummary(
      datasetVersion: datasetVersion,
      caseCount: eligible.length,
      excludedCounts: excluded,
    );

    File('$outputDir/version.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(summary.toJson()),
    );
    return summary;
  }
}
