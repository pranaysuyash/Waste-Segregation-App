import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Canonical result of recycling taxonomy lookup.
class RecyclingTaxonomyResolution {
  const RecyclingTaxonomyResolution({
    required this.version,
    this.familyId,
    this.categoryId,
    this.familyLabel,
    this.categoryLabel,
    required this.source,
    required this.method,
    required this.confidence,
    required this.matchedSignal,
  });

  final String version;
  final String? familyId;
  final String? categoryId;
  final String? familyLabel;
  final String? categoryLabel;
  final String source;
  final String method;
  final double confidence;
  final String matchedSignal;

  bool get isResolved =>
      familyId != null &&
      categoryId != null &&
      familyId!.isNotEmpty &&
      categoryId!.isNotEmpty;
}

/// Internal parsed taxonomy shape.
class _RecyclingTaxonomyCategory {
  _RecyclingTaxonomyCategory({
    required this.id,
    required this.name,
    required this.familyId,
    required this.ricCodes,
    required this.aliases,
    required this.keywords,
    required this.signals,
  });

  final String id;
  final String name;
  final String familyId;
  final List<String> ricCodes;
  final List<String> aliases;
  final List<String> keywords;
  final Map<String, List<String>> signals;

  Set<String> get indexKeys => {
        ...ricCodes,
        ...aliases,
        ...keywords,
        ...signals.values.expand((e) => e),
        id,
        familyId,
        name,
      }.map(_normalize).where((token) => token.isNotEmpty).toSet();

  static final RegExp _slugCleaner =
      RegExp(r'[^a-z0-9]+', caseSensitive: false);

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(_slugCleaner, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _RecyclingTaxonomyData {
  _RecyclingTaxonomyData({
    required this.version,
    required this.families,
    required this.categories,
    required this.fallbackMap,
  });

  final String version;
  final Map<String, String> families;
  final List<_RecyclingTaxonomyCategory> categories;
  final Map<String, String> fallbackMap;

  final Map<String, _RecyclingTaxonomyCategory> byId =
      <String, _RecyclingTaxonomyCategory>{};
  final Map<String, _RecyclingTaxonomyCategory> byRic =
      <String, _RecyclingTaxonomyCategory>{};
  final Map<String, Set<_RecyclingTaxonomyCategory>> bySignal =
      <String, Set<_RecyclingTaxonomyCategory>>{};

  void buildIndexes() {
    for (final category in categories) {
      byId[category.id] = category;
      for (final ric in category.ricCodes) {
        byRic[_RecyclingTaxonomyCategory._normalize(ric)] = category;
      }
      for (final signal in category.indexKeys) {
        bySignal
            .putIfAbsent(signal, () => <_RecyclingTaxonomyCategory>{})
            .add(category);
      }
    }
  }
}

/// Canonical recycling-taxonomy resolver.
class RecyclingTaxonomyService {
  RecyclingTaxonomyService({
    String? assetPath,
    AssetBundle? assetBundle,
    @visibleForTesting String? fallbackJsonOverride,
    @visibleForTesting bool allowDefaultAssetCandidates = true,
  })  : _assetPath = assetPath ?? 'lib/data/recycling_taxonomy.json',
        _assetBundle = assetBundle,
        _fallbackJsonOverride = fallbackJsonOverride,
        _allowDefaultAssetCandidates = allowDefaultAssetCandidates;

  final String _assetPath;
  final AssetBundle? _assetBundle;
  final String? _fallbackJsonOverride;
  final bool _allowDefaultAssetCandidates;
  static const List<String> _defaultAssetCandidates = <String>[
    'lib/data/recycling_taxonomy.json',
  ];

  _RecyclingTaxonomyData? _data;
  Future<_RecyclingTaxonomyData>? _loadFuture;

  Future<RecyclingTaxonomyResolution> resolveFromClassification(
    WasteClassification classification,
  ) async {
    return resolve(
      category: classification.category,
      subCategory: classification.subCategory,
      itemName: classification.itemName,
      productName: classification.product,
      recyclingCode: classification.recyclingCode,
      barcode: classification.barcode,
      source: 'classification_payload',
    );
  }

  Future<RecyclingTaxonomyResolution> resolve({
    String? category,
    String? subCategory,
    String? itemName,
    String? productName,
    int? recyclingCode,
    String? barcode,
    String? source,
    List<String>? packagingTags,
    List<String>? categoryTags,
  }) async {
    late final _RecyclingTaxonomyData data;
    try {
      data = await _loadData();
    } catch (error, stackTrace) {
      WasteAppLogger.warning(
        'Taxonomy resolution unavailable; preserving the base classification.',
        error: error,
        stackTrace: stackTrace,
      );
      return const RecyclingTaxonomyResolution(
        version: '',
        source: 'taxonomy_unavailable',
        method: 'asset_missing',
        confidence: 0.0,
        matchedSignal: '',
      );
    }

    final candidates = <String>{
      if (category != null) ..._tokenize(category),
      if (subCategory != null) ..._tokenize(subCategory),
      if (itemName != null) ..._tokenize(itemName),
      if (productName != null) ..._tokenize(productName),
      if (barcode != null && barcode.trim().isNotEmpty) barcode.trim(),
      if (recyclingCode != null) recyclingCode.toString(),
    };

    for (final tag in packagingTags ?? const <String>[]) {
      if (tag.trim().isNotEmpty) {
        candidates.add(tag.toLowerCase());
      }
    }
    for (final tag in categoryTags ?? const <String>[]) {
      if (tag.trim().isNotEmpty) {
        candidates.add(tag.toLowerCase());
      }
    }

    var best = _bestUnresolvedMatch(data);

    for (final candidate in candidates) {
      final token = _normalize(candidate);
      if (token.isEmpty) continue;

      // Numeric resin code exact match.
      final byRic = data.byRic[token];
      if (byRic != null) {
        final candidateMatch = _buildResult(
          data: data,
          category: byRic,
          method: 'ric_code',
          source: source ?? 'unknown',
          confidence: 0.96,
          matchedSignal: token,
        );
        if (candidateMatch.confidence > best.confidence) {
          best = candidateMatch;
          if (candidateMatch.confidence >= 0.95) break;
        }
      }

      // Exact alias and keyword match.
      final exact = data.bySignal[token];
      if (exact != null && exact.isNotEmpty) {
        final categoryMatch = exact
            .map(
              (candidateCategory) => _buildResult(
                data: data,
                category: candidateCategory,
                method: 'alias_exact',
                source: source ?? 'unknown',
                confidence: 0.9,
                matchedSignal: token,
              ),
            )
            .reduce((a, b) => a.confidence >= b.confidence ? a : b);
        if (categoryMatch.confidence > best.confidence) {
          best = categoryMatch;
        }
      }

      // Substring match fallback.
      for (final entry in data.categories) {
        for (final key in entry.indexKeys) {
          if (key.isEmpty) continue;
          if (token.contains(key) || key.contains(token)) {
            final candidateMatch = _buildResult(
              data: data,
              category: entry,
              method: 'alias_contains',
              source: source ?? 'unknown',
              confidence: 0.75,
              matchedSignal: token,
            );
            if (candidateMatch.confidence > best.confidence) {
              best = candidateMatch;
            }
          }
        }
      }
    }

    // If not resolved, attempt family-level fallback from structured category token.
    final fallback = _fallbackFromTokens(data, candidates.toList());
    if (fallback != null && fallback.confidence > best.confidence) {
      best = fallback;
    }

    return best;
  }

  Future<_RecyclingTaxonomyData> _loadData() async {
    if (_data != null) return _data!;
    _loadFuture ??= _loadAndParse();
    _data = await _loadFuture;
    return _data!;
  }

  Future<_RecyclingTaxonomyData> _loadAndParse() async {
    final raw = await _readCatalogJson();
    final document = jsonDecode(raw);

    final families = <String, String>{};
    final categories = <_RecyclingTaxonomyCategory>[];
    final fallback = <String, String>{};

    final rawFamilies = document['families'];
    if (rawFamilies is List) {
      for (final family in rawFamilies) {
        if (family is Map<String, dynamic>) {
          final id = family['id']?.toString();
          final name = family['name']?.toString();
          if (id != null && id.isNotEmpty) {
            families[id] = (name ?? id).trim();
          }
        }
      }
    }

    final rawCategories = document['categories'];
    if (rawCategories is List) {
      for (final category in rawCategories) {
        if (category is Map<String, dynamic>) {
          final id = category['id']?.toString();
          final name = category['name']?.toString();
          final familyId = category['familyId']?.toString();
          if (id == null || name == null || familyId == null) {
            continue;
          }

          final signals = _readSignals(category['signals']);
          categories.add(
            _RecyclingTaxonomyCategory(
              id: id,
              name: name,
              familyId: familyId,
              ricCodes: (() {
                final ricCodes = _readStringList(category['ricCodes']);
                final normalizedId = id.toLowerCase();
                if (!ricCodes.contains(normalizedId)) {
                  ricCodes.add(normalizedId);
                }
                return ricCodes;
              })(),
              aliases: _readStringList(category['aliases']),
              keywords: signals['keywords'] ?? const <String>[],
              signals: signals,
            ),
          );
        }
      }
    }

    final rawFallback = document['fallbackCategoryIds'];
    if (rawFallback is Map) {
      fallback.addAll(rawFallback.map(
        (key, value) =>
            MapEntry(key.toString().toLowerCase(), value.toString()),
      ));
    }

    final data = _RecyclingTaxonomyData(
      version: document['version']?.toString() ?? 'unknown',
      families: families,
      categories: categories,
      fallbackMap: fallback,
    )..buildIndexes();

    return data;
  }

  Future<String> _readCatalogJson() async {
    if (_fallbackJsonOverride != null) {
      return _fallbackJsonOverride;
    }

    final candidates = <String>{
      if (_assetPath.trim().isNotEmpty) _assetPath,
      if (_allowDefaultAssetCandidates) ..._defaultAssetCandidates,
    }.where((path) => path.trim().isNotEmpty).toList();

    Object? lastException;

    for (final candidate in candidates) {
      final loaders = <Future<String> Function(String)>[];
      final assetBundle = _assetBundle;
      if (assetBundle != null) {
        loaders.add((path) => assetBundle.loadString(path));
      }
      loaders.add((path) => rootBundle.loadString(path));

      for (final loadFrom in loaders) {
        try {
          return await loadFrom(candidate);
        } catch (error) {
          lastException = error;
        }
      }
    }

    try {
      final errorPayload = {
        'candidates': candidates,
        'fallback_error': lastException?.toString(),
      };
      WasteAppLogger.severe(
        'Recycling taxonomy asset load failed.',
        context: errorPayload,
      );
    } catch (_) {}

    throw StateError(
      'Recycling taxonomy asset unavailable. '
      'Ensure lib/data/recycling_taxonomy.json is packaged.',
    );
  }

  static Map<String, List<String>> _readSignals(dynamic raw) {
    final result = <String, List<String>>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        result[entry.key.toString()] = _readStringList(entry.value);
      }
    }
    return result;
  }

  static List<String> _readStringList(dynamic value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value
          .whereType<String>()
          .map((value) => value.toLowerCase().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Set<String> _tokenize(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return const <String>{};

    final split = normalized
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();

    return {
      normalized,
      ...split,
      ...split.where((token) => token.length > 3).map((token) =>
          token.length > 3 ? token.substring(0, token.length - 1) : token),
    };
  }

  static RecyclingTaxonomyResolution _buildResult({
    required _RecyclingTaxonomyData data,
    required _RecyclingTaxonomyCategory category,
    required String method,
    required String source,
    required double confidence,
    required String matchedSignal,
  }) {
    return RecyclingTaxonomyResolution(
      version: data.version,
      familyId: category.familyId,
      categoryId: category.id,
      familyLabel: data.families[category.familyId] ?? category.familyId,
      categoryLabel: category.name,
      source: source,
      method: method,
      confidence: confidence,
      matchedSignal: matchedSignal,
    );
  }

  RecyclingTaxonomyResolution _bestUnresolvedMatch(
          _RecyclingTaxonomyData data) =>
      RecyclingTaxonomyResolution(
        version: data.version,
        source: 'unresolved',
        method: 'unresolved',
        confidence: 0.0,
        matchedSignal: '',
      );

  RecyclingTaxonomyResolution? _fallbackFromTokens(
    _RecyclingTaxonomyData data,
    List<String> tokens,
  ) {
    final flattened = <String>[];
    for (final raw in tokens) {
      final normalized = _normalize(raw);
      if (normalized.isNotEmpty) flattened.add(normalized);
    }

    for (final token in flattened) {
      final fallbackId = data.fallbackMap[token];
      if (fallbackId == null || fallbackId.isEmpty) continue;
      final category = data.byId[fallbackId];
      if (category != null) {
        return _buildResult(
          data: data,
          category: category,
          method: 'family_fallback',
          source: 'fallback_map',
          confidence: 0.5,
          matchedSignal: token,
        );
      }

      // Tokenized partial match.
      for (final entry in data.fallbackMap.entries) {
        if (token.contains(entry.key) || entry.key.contains(token)) {
          final fallbackEntry = data.byId[entry.value];
          if (fallbackEntry != null) {
            return _buildResult(
              data: data,
              category: fallbackEntry,
              method: 'family_fallback_partial',
              source: 'fallback_map',
              confidence: 0.44,
              matchedSignal: token,
            );
          }
        }
      }
    }
    return null;
  }
}
