import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'package:crypto/crypto.dart';

const String manifestPath = 'tools/policy_source_manifest.json';
const String reportPath = 'build/reports/policy_source_check/latest.json';

class PolicySourceEntry {
  PolicySourceEntry({
    required this.pluginId,
    required this.region,
    required this.sourceUrl,
    required this.sourceTitle,
    required this.authority,
    required this.governanceStage,
    this.lastChecked,
    this.lastVerified,
    this.lastEtag,
    this.lastContentHash,
    this.lastModified,
    this.lastStatus,
    this.lastStatusMessage,
  });

  factory PolicySourceEntry.fromJson(Map<String, dynamic> json) {
    return PolicySourceEntry(
      pluginId: json['pluginId'] as String,
      region: json['region'] as String,
      sourceUrl: json['sourceUrl'] as String,
      sourceTitle: json['sourceTitle'] as String,
      authority: json['authority'] as String,
      governanceStage: json['governanceStage'] as String,
      lastChecked: json['lastChecked'] as String?,
      lastVerified: json['lastVerified'] as String?,
      lastEtag: json['lastEtag'] as String?,
      lastContentHash: json['lastContentHash'] as String?,
      lastModified: json['lastModified'] as String?,
      lastStatus: json['lastStatus'] as String?,
      lastStatusMessage: json['lastStatusMessage'] as String?,
    );
  }

  final String pluginId;
  final String region;
  final String sourceUrl;
  final String sourceTitle;
  final String authority;
  final String governanceStage;
  final String? lastChecked;
  final String? lastVerified;
  final String? lastEtag;
  final String? lastContentHash;
  final String? lastModified;
  final String? lastStatus;
  final String? lastStatusMessage;

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'region': region,
        'sourceUrl': sourceUrl,
        'sourceTitle': sourceTitle,
        'authority': authority,
        'governanceStage': governanceStage,
        'lastChecked': lastChecked,
        'lastVerified': lastVerified,
        'lastEtag': lastEtag,
        'lastContentHash': lastContentHash,
        'lastModified': lastModified,
        'lastStatus': lastStatus,
        'lastStatusMessage': lastStatusMessage,
      };

  PolicySourceEntry copyWith({
    String? lastChecked,
    String? lastVerified,
    String? lastEtag,
    String? lastContentHash,
    String? lastModified,
    String? lastStatus,
    String? lastStatusMessage,
  }) {
    return PolicySourceEntry(
      pluginId: pluginId,
      region: region,
      sourceUrl: sourceUrl,
      sourceTitle: sourceTitle,
      authority: authority,
      governanceStage: governanceStage,
      lastChecked: lastChecked ?? this.lastChecked,
      lastVerified: lastVerified ?? this.lastVerified,
      lastEtag: lastEtag ?? this.lastEtag,
      lastContentHash: lastContentHash ?? this.lastContentHash,
      lastModified: lastModified ?? this.lastModified,
      lastStatus: lastStatus ?? this.lastStatus,
      lastStatusMessage: lastStatusMessage ?? this.lastStatusMessage,
    );
  }
}

class SourceManifest {
  SourceManifest({
    required this.generatedAt,
    required this.sources,
  });

  factory SourceManifest.fromJson(Map<String, dynamic> json) {
    final sourceList = (json['sources'] as List<dynamic>?) ?? const [];
    return SourceManifest(
      generatedAt: json['generatedAt'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      sources: sourceList
          .map((e) => PolicySourceEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  final String generatedAt;
  final List<PolicySourceEntry> sources;

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt,
        'sources': sources.map((s) => s.toJson()).toList(),
      };
}

class SourceCheckResult {
  SourceCheckResult({
    required this.pluginId,
    required this.region,
    required this.sourceUrl,
    required this.status,
    required this.changed,
    this.error,
    required this.requestedAt,
    this.lastEtag,
    this.currentEtag,
    this.lastHash,
    this.currentHash,
    this.lastModified,
    this.currentModified,
  });

  final String pluginId;
  final String region;
  final String sourceUrl;
  final String status;
  final bool changed;
  final String? error;
  final String requestedAt;
  final String? lastEtag;
  final String? currentEtag;
  final String? lastHash;
  final String? currentHash;
  final String? lastModified;
  final String? currentModified;

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'region': region,
        'sourceUrl': sourceUrl,
        'status': status,
        'changed': changed,
        'error': error,
        'requestedAt': requestedAt,
        'lastEtag': lastEtag,
        'currentEtag': currentEtag,
        'lastHash': lastHash,
        'currentHash': currentHash,
        'lastModified': lastModified,
        'currentModified': currentModified,
      };
}

Future<SourceManifest> _loadManifest() async {
  final file = File(manifestPath);
  final contents = await file.readAsString();
  final jsonMap = jsonDecode(contents) as Map<String, dynamic>;
  return SourceManifest.fromJson(jsonMap);
}

Future<void> _writeManifest(SourceManifest manifest) async {
  final file = File(manifestPath);
  final encoded = const JsonEncoder.withIndent('  ').convert(manifest.toJson());
  await file.writeAsString(encoded);
}

Future<List<SourceCheckResult>> _checkAllSources(
  SourceManifest manifest,
) async {
  final client = HttpClient()..userAgent = 'waste-seg-source-checker/1.0';
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final updatedSources = <PolicySourceEntry>[];
  final results = <SourceCheckResult>[];

  for (final entry in manifest.sources) {
    final result = await _checkSingleSource(client, entry);
    updatedSources.add(
      entry.copyWith(
        lastChecked: nowIso,
        lastVerified: result.status == 'ok'
            ? nowIso
            : (entry.lastVerified ?? entry.lastChecked),
        lastEtag: result.currentEtag ?? entry.lastEtag,
        lastContentHash: result.currentHash ?? entry.lastContentHash,
        lastModified: result.currentModified ?? entry.lastModified,
        lastStatus: result.status,
        lastStatusMessage: result.error,
      ),
    );
    results.add(result);
  }

  client.close(force: true);

  await _writeManifest(
    SourceManifest(
      generatedAt: manifest.generatedAt,
      sources: updatedSources,
    ),
  );

  return results;
}

Future<SourceCheckResult> _checkSingleSource(
  HttpClient client,
  PolicySourceEntry entry,
) async {
  final nowIso = DateTime.now().toUtc().toIso8601String();
  try {
    final request = await client.getUrl(Uri.parse(entry.sourceUrl));
    final response = await request.close();

    final statusCode = response.statusCode;
    final lastModified = response.headers.value('last-modified');
    final etag = response.headers.value('etag');
    final bytes = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );

    final body = bytes.takeBytes();
    final contentHash = sha256.convert(body).toString();

    if (statusCode < 200 || statusCode >= 300) {
      return SourceCheckResult(
        pluginId: entry.pluginId,
        region: entry.region,
        sourceUrl: entry.sourceUrl,
        status: 'non_2xx',
        changed: false,
        error: 'HTTP $statusCode',
        requestedAt: nowIso,
        lastEtag: entry.lastEtag,
        currentEtag: etag,
        lastHash: entry.lastContentHash,
        currentHash: contentHash,
        lastModified: entry.lastModified,
        currentModified: lastModified,
      );
    }

    final changed =
        (entry.lastEtag != null && etag != null && entry.lastEtag != etag) ||
            (entry.lastContentHash != null &&
                entry.lastContentHash != contentHash) ||
            (entry.lastModified != null &&
                lastModified != null &&
                entry.lastModified != lastModified);

    return SourceCheckResult(
      pluginId: entry.pluginId,
      region: entry.region,
      sourceUrl: entry.sourceUrl,
      status: changed ? 'changed' : 'ok',
      changed: changed,
      requestedAt: nowIso,
      lastEtag: entry.lastEtag,
      currentEtag: etag,
      lastHash: entry.lastContentHash,
      currentHash: contentHash,
      lastModified: entry.lastModified,
      currentModified: lastModified,
    );
  } on SocketException {
    return SourceCheckResult(
      pluginId: entry.pluginId,
      region: entry.region,
      sourceUrl: entry.sourceUrl,
      status: 'offline',
      changed: false,
      error: 'Network unavailable',
      requestedAt: nowIso,
      lastEtag: entry.lastEtag,
      lastHash: entry.lastContentHash,
      lastModified: entry.lastModified,
    );
  } on Exception catch (e) {
    return SourceCheckResult(
      pluginId: entry.pluginId,
      region: entry.region,
      sourceUrl: entry.sourceUrl,
      status: 'error',
      changed: false,
      error: e.toString(),
      requestedAt: nowIso,
      lastEtag: entry.lastEtag,
      lastHash: entry.lastContentHash,
      lastModified: entry.lastModified,
    );
  }
}

Future<void> main(List<String> args) async {
  final manifest = await _loadManifest();
  final reportRows = await _checkAllSources(manifest);
  final summary = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'total': reportRows.length,
    'changed': reportRows.where((r) => r.changed).length,
    'errors': reportRows.where((r) => r.status == 'error' || r.status == 'offline').length,
    'rows': reportRows.map((r) => r.toJson()).toList(),
  };

  final outFile = File(reportPath);
  await outFile.create(recursive: true);
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(summary),
  );

  final failed = reportRows.where((r) => r.status != 'ok' && r.status != 'changed');
  stdout.writeln(
    'policy-source-check complete: total=${summary['total']}, '
    'changed=${summary['changed']}, errors=${summary['errors']}',
  );
  stdout.writeln('report_path=${outFile.path}');

  for (final row in failed) {
    stdout.writeln(
      '[${row.status}] ${row.pluginId} (${row.region}) :: ${row.error}',
    );
  }
}
