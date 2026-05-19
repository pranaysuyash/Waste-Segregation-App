import 'dart:async';
import 'dart:collection';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Safely truncates a hash string for logging preview.
/// Returns '<empty>' when [value] is null or empty.
String _previewHash(String? value) {
  if (value == null || value.isEmpty) return '<empty>';
  return value.length <= 16 ? value : value.substring(0, 16);
}

/// Extracts the raw perceptual hash from a cache key.
///
/// Context-aware keys follow the format:
///   `phash_<hex>::region::lang::...`
/// Raw keys are just:
///   `phash_<hex>`
///
/// In both cases the raw phash prefix up to the first `::` is returned.
String _rawPhashPrefix(String key) {
  final sep = key.indexOf('::');
  return sep == -1 ? key : key.substring(0, sep);
}

/// Service for caching image classifications
///
/// This service manages the local caching of image classification results
/// to reduce redundant API calls, improve response times, and ensure
/// consistent classification results for identical images.
///
/// Cache identity:
///   - Hive key is whatever the caller supplies. When called from
///     [AiService] the key is a context-aware composite string
///     (`phash_<hex>::region::lang::...`), so entries for the same image
///     but different region/language/provider/model are stored separately.
///   - The raw perceptual hash (used for similarity scanning) is stored
///     inside [CachedClassification.imageHash] and is extracted via
///     [_rawPhashPrefix] when the key is composite.
class ClassificationCacheService {
  /// Constructor
  ClassificationCacheService({
    int? maxCacheSize,
  }) : _maxCacheSize = maxCacheSize ?? 1000;

  /// Hive box for storing cached classifications
  late Box<String> _cacheBox;

  /// Maximum number of cache entries (default: 1000)
  final int _maxCacheSize;

  /// Whether the cache has been initialized
  bool _isInitialized = false;

  /// Cache statistics
  final Map<String, dynamic> _statistics = {
    'hits': 0,
    'misses': 0,
    'size': 0,
    'bytesSaved': 0,
    'createdAt': DateTime.now(),
  };

  /// In-memory LRU tracking for faster cache operations
  ///
  /// Invariant: LRU map order = oldest -> newest.
  ///   - On load, entries are sorted by lastAccessed ascending.
  ///   - On access, the key is removed and re-added (moves to end = newest).
  ///   - On eviction, the front of the map (keys.first) is the oldest.
  final LinkedHashMap<String, DateTime> _lruMap =
      LinkedHashMap<String, DateTime>();

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open the cache box
      _cacheBox = await Hive.openBox<String>(StorageKeys.cacheBox);

      // Load existing cache entries into LRU map
      _loadLruMapFromCache();

      // Update initial statistics
      _statistics['size'] = _cacheBox.length;

      _isInitialized = true;
      WasteAppLogger.cacheEvent('cache_initialized', 'classification',
          context: {
            'cache_size': _cacheBox.length,
            'max_cache_size': _maxCacheSize
          });
    } catch (e) {
      WasteAppLogger.severe('Classification cache initialization failed',
          error: e, context: {'max_cache_size': _maxCacheSize});
      rethrow;
    }
  }

  /// Load the LRU map from the cache box.
  ///
  /// Sorted ascending by lastAccessed (oldest first) to match the
  /// oldest->newest invariant.
  void _loadLruMapFromCache() {
    for (final String key in _cacheBox.keys) {
      try {
        final cacheEntry = _deserializeEntry(key);
        if (cacheEntry != null) {
          _lruMap[key] = cacheEntry.lastAccessed;
        }
      } catch (e) {
        WasteAppLogger.warning('cache_lru_load_skip_corrupted',
            error: e,
            context: {
              'key': _previewHash(key),
              'action': 'skip_corrupted_entry'
            });
        // Skip corrupted entries
      }
    }

    // Sort oldest first (ascending) = invariant: oldest -> newest
    final sortedEntries = _lruMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    _lruMap.clear();
    for (final entry in sortedEntries) {
      _lruMap[entry.key] = entry.value;
    }
  }

  /// Get a cached classification by its cache key.
  ///
  /// [cacheKey] is used directly for exact-match lookup. When supplied by
  /// [AiService] it is a context-aware composite key that includes the
  /// image hash, region, language, model, and provider — so cross-context
  /// collisions are impossible.
  ///
  /// [contentHash] is verified against the cached entry on both exact and
  /// similarity paths to prevent false positives.
  ///
  /// [similarityThreshold]: The maximum number of bits that can differ for
  /// similar hashes (default: 6).
  Future<CachedClassification?> getCachedClassification(
    String cacheKey, {
    String? contentHash,
    int similarityThreshold = 6,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Check for exact match first
      if (_cacheBox.containsKey(cacheKey)) {
        final cacheEntry = _deserializeEntry(cacheKey);
        if (cacheEntry != null) {
          // EXACT-MATCH CONTEXT VERIFICATION:
          // If the caller provided a contentHash (context-aware), verify it
          // matches the cached entry. Same image hash but different region/
          // language/provider/model = cache miss here.
          if (contentHash != null &&
              cacheEntry.contentHash != null &&
              cacheEntry.contentHash != contentHash) {
            WasteAppLogger.cacheEvent(
                'cache_exact_context_miss', 'classification',
                key: _previewHash(cacheKey),
                context: {
                  'match_type': 'exact_content_mismatch',
                  'cached_content_hash':
                      _previewHash(cacheEntry.contentHash),
                  'requested_content_hash': _previewHash(contentHash),
                  'item_name': cacheEntry.classification.itemName
                });
            // Fall through to similarity search below
          } else {
            // Exact context match — return cache hit
            _statistics['hits']++;
            WasteAppLogger.cacheEvent('cache_hit', 'classification',
                hit: true,
                key: _previewHash(cacheKey),
                context: {
                  'match_type': 'exact_verified',
                  'cache_age_minutes': DateTime.now()
                      .difference(cacheEntry.timestamp)
                      .inMinutes,
                  'item_name': cacheEntry.classification.itemName
                });

            // Crashlytics breadcrumb for field debugging (safe for testing)
            try {
              FirebaseCrashlytics.instance.log(
                  'CACHE exact_hit key=${_previewHash(cacheKey)}... age=${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min');
            } catch (e) {
              // Firebase not initialized (testing environment)
            }

            // Update LRU tracking: move to end (newest)
            cacheEntry.markUsed();
            _lruMap.remove(cacheKey);
            _lruMap[cacheKey] = cacheEntry.lastAccessed;
            await _cacheBox.put(cacheKey, cacheEntry.serialize());

            return cacheEntry;
          }
        }
      }

      // Similarity search — only for perceptual hashes with verification
      if (_isPerceptualHash(cacheKey) &&
          contentHash != null &&
          CacheFeatureFlags.contentHashVerificationEnabled) {
        WasteAppLogger.cacheEvent(
            'similarity_search_started', 'classification',
            key: _previewHash(cacheKey),
            context: {
              'similarity_threshold': similarityThreshold,
              'has_content_hash': contentHash != null
            });
        final similarKey = await _findSimilarPerceptualHashWithVerification(
            cacheKey, contentHash, similarityThreshold);

        if (similarKey != null) {
          final cacheEntry = _deserializeEntry(similarKey);
          if (cacheEntry != null) {
            _statistics['hits']++;
            _statistics['similarHits'] =
                (_statistics['similarHits'] ?? 0) + 1;
            WasteAppLogger.cacheEvent('cache_hit', 'classification',
                hit: true,
                key: _previewHash(cacheKey),
                context: {
                  'match_type': 'verified_similar',
                  'matched_key': _previewHash(similarKey),
                  'cache_age_minutes': DateTime.now()
                      .difference(cacheEntry.timestamp)
                      .inMinutes,
                  'item_name': cacheEntry.classification.itemName,
                  'created': cacheEntry.timestamp.toIso8601String(),
                  'last_accessed': cacheEntry.lastAccessed.toIso8601String()
                });

            try {
              FirebaseCrashlytics.instance.log(
                  'CACHE verified_similar_hit original=${_previewHash(cacheKey)}... matched=${_previewHash(similarKey)}... age=${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min');
            } catch (e) {
              // Firebase not initialized (testing environment)
            }

            // Update LRU tracking
            cacheEntry.markUsed();
            _lruMap.remove(similarKey);
            _lruMap[similarKey] = cacheEntry.lastAccessed;
            await _cacheBox.put(similarKey, cacheEntry.serialize());

            return cacheEntry;
          }
        } else {
          WasteAppLogger.cacheEvent('cache_miss', 'classification',
              hit: false,
              key: _previewHash(cacheKey),
              context: {
                'match_type': 'no_verified_similar',
                'similarity_threshold': similarityThreshold
              });
        }
      } else if (_isPerceptualHash(cacheKey) &&
          !CacheFeatureFlags.contentHashVerificationEnabled) {
        // --- FALLBACK when content hash verification is disabled ---
        // For AI classification results this is risky because it bypasses
        // region/language/provider context and may return wrong disposal
        // guidance. Only allow fallback for entries explicitly marked as
        // context-agnostic (contentHash == null).
        WasteAppLogger.cacheEvent(
            'fallback_to_basic_matching', 'classification',
            key: _previewHash(cacheKey),
            context: {
              'reason': 'content_hash_verification_disabled',
              'similarity_threshold': similarityThreshold
            });
        final similarKey =
            await _findSimilarPerceptualHash(cacheKey, similarityThreshold);

        if (similarKey != null) {
          final cacheEntry = _deserializeEntry(similarKey);
          if (cacheEntry != null) {
            // Only return context-isolated hits; skip entries with a
            // contentHash (meaning they are context-specific AI results).
            if (cacheEntry.contentHash != null) {
              WasteAppLogger.cacheEvent(
                  'cache_similarity_basic_skipped_context', 'classification',
                  context: {
                    'reason':
                        'basic_fallback_bypassed_context_aware_entry',
                    'matched_key': _previewHash(similarKey)
                  });
            } else {
              _statistics['hits']++;
              _statistics['similarHits'] =
                  (_statistics['similarHits'] ?? 0) + 1;
              WasteAppLogger.cacheEvent('cache_hit', 'classification',
                  hit: true,
                  key: _previewHash(cacheKey),
                  context: {
                    'match_type': 'basic_similarity_context_agnostic',
                    'matched_key': _previewHash(similarKey),
                    'cache_age_minutes': DateTime.now()
                        .difference(cacheEntry.timestamp)
                        .inMinutes,
                    'item_name': cacheEntry.classification.itemName
                  });

              cacheEntry.markUsed();
              _lruMap.remove(similarKey);
              _lruMap[similarKey] = cacheEntry.lastAccessed;
              await _cacheBox.put(similarKey, cacheEntry.serialize());

              return cacheEntry;
            }
          }
        }
      } else if (_isPerceptualHash(cacheKey) && contentHash == null) {
        WasteAppLogger.warning(
            'cache_phash_missing_content_hash_similarity_skipped',
            context: {
              'key': _previewHash(cacheKey),
              'reason': 'missing_content_hash_for_verification'
            });
      }

      // Cache miss
      _statistics['misses']++;
      WasteAppLogger.cacheEvent('cache_miss', 'classification',
          hit: false,
          key: _previewHash(cacheKey),
          context: {
            'match_type': 'no_match',
            'cache_size': _cacheBox.length,
            'is_perceptual_hash': _isPerceptualHash(cacheKey)
          });

      try {
        FirebaseCrashlytics.instance.log(
            'CACHE miss key=${_previewHash(cacheKey)}... cache_size=${_cacheBox.length}');
      } catch (e) {
        // Firebase not initialized (testing environment)
      }

      return null;
    } catch (e) {
      WasteAppLogger.severe('cache_get_error_treat_as_miss',
          error: e,
          context: {
            'key': _previewHash(cacheKey),
            'action': 'treat_as_cache_miss'
          });
      _statistics['misses']++;
      return null;
    }
  }

  /// Store a classification result in the cache.
  ///
  /// [cacheKey] is the Hive key. When called from [AiService] it is a
  /// context-aware composite string so that the same image classified
  /// under different region/language/provider/model produces distinct
  /// entries.
  ///
  /// [entryImageHash] — when set, this raw phash is stored in
  /// [CachedClassification.imageHash] instead of [cacheKey], preserving
  /// similarity scanning even when the Hive key is composite.
  Future<void> cacheClassification(
    String cacheKey,
    WasteClassification classification, {
    String? contentHash,
    int? imageSize,
    String? entryImageHash,
  }) async {
    try {
      if (!_isInitialized) {
        WasteAppLogger.warning('cache_auto_initialize_on_store',
            context: {'action': 'auto_initialize_cache'});
        await initialize();
      }

      // The imageHash stored inside the CachedClassification entry.
      // For context-aware keys, entryImageHash preserves the raw phash
      // so similarity scanning works regardless of Hive key format.
      final storedImageHash = entryImageHash ?? cacheKey;

      // Check if this key already exists
      if (_cacheBox.containsKey(cacheKey)) {
        final existingEntry = _deserializeEntry(cacheKey);
        WasteAppLogger.cacheEvent(
            'cache_store_update_existing', 'classification',
            key: _previewHash(cacheKey),
            context: {
              'existing_item': existingEntry?.classification.itemName,
              'new_item': classification.itemName,
              'existing_content_hash':
                  _previewHash(existingEntry?.contentHash),
              'new_content_hash': _previewHash(contentHash)
            });
      }

      // Create cache entry with the raw image hash stored inside
      // so similarity scanning can compare against it regardless of
      // the Hive key format.
      final cacheEntry = CachedClassification.fromClassification(
        storedImageHash,
        classification,
        contentHash: contentHash,
        imageSize: imageSize,
      );

      // Manage cache size (evict oldest entries if needed)
      await _ensureCacheSize();

      // Add to cache
      await _cacheBox.put(cacheKey, cacheEntry.serialize());

      // Update LRU tracking — append to end (newest)
      _lruMap[cacheKey] = cacheEntry.lastAccessed;

      // Update statistics
      _statistics['size'] = _cacheBox.length;
      if (imageSize != null) {
        _statistics['bytesSaved'] =
            (_statistics['bytesSaved'] ?? 0) + imageSize;
      }

      WasteAppLogger.cacheEvent('cache_store', 'classification',
          key: _previewHash(cacheKey),
          context: {
            'item_name': classification.itemName,
            'has_content_hash': contentHash != null,
            'content_hash': _previewHash(contentHash),
            'cache_size': _cacheBox.length,
            'image_size_bytes': imageSize,
            'entry_image_hash': _previewHash(storedImageHash)
          });
    } catch (e) {
      WasteAppLogger.severe('cache_store_error_continue', error: e, context: {
        'key': _previewHash(cacheKey),
        'item_name': classification.itemName,
        'action': 'continue_without_caching'
      });
      // Errors during caching shouldn't break the app flow
    }
  }

  /// Ensure the cache doesn't exceed maximum size.
  ///
  /// Evicts from the front of the LRU map (oldest entries) because the
  /// LRU invariant is oldest -> newest.
  Future<void> _ensureCacheSize() async {
    if (_cacheBox.length < _maxCacheSize) return;

    // Remove 10% of max cache
    final entriesToRemove = (_maxCacheSize * 0.1).ceil();
    final keysToRemove = <String>[];
    var count = 0;

    // LRU map is oldest -> newest; oldest is at keys.first
    for (final key in _lruMap.keys.toList()) {
      if (count >= entriesToRemove) break;
      keysToRemove.add(key);
      count++;
    }

    // Remove entries and update stats
    for (final key in keysToRemove) {
      final entry = _deserializeEntry(key);
      final size = entry?.imageSize ?? 0;
      await _cacheBox.delete(key);
      _lruMap.remove(key);
      if (size > 0) {
        _statistics['bytesSaved'] =
            ((_statistics['bytesSaved'] ?? 0) - size).clamp(0, double.infinity);
      }
    }
    _statistics['size'] = _cacheBox.length;

    WasteAppLogger.cacheEvent('cache_lru_eviction', 'classification', context: {
      'entries_removed': keysToRemove.length,
      'eviction_count': keysToRemove.length,
      'cache_size_before': _cacheBox.length,
      'cache_size_after': _cacheBox.length,
      'max_cache_size': _maxCacheSize,
      'eviction_percentage':
          (keysToRemove.length / _maxCacheSize * 100).toStringAsFixed(1)
    });
  }

  /// Clear the entire cache
  Future<void> clearCache() async {
    try {
      if (!_isInitialized) await initialize();

      // Capture size BEFORE clearing
      final previousSize = _cacheBox.length;

      await _cacheBox.clear();
      _lruMap.clear();

      // Reset statistics
      _statistics['hits'] = 0;
      _statistics['misses'] = 0;
      _statistics['size'] = 0;
      _statistics['bytesSaved'] = 0;
      _statistics['createdAt'] = DateTime.now();

      WasteAppLogger.cacheEvent('cache_cleared', 'classification', context: {
        'previous_size': previousSize,
        'statistics_reset': true
      });
    } catch (e) {
      WasteAppLogger.severe('cache_clear_error', error: e);
      rethrow;
    }
  }

  /// Clean up expired cache entries based on age.
  ///
  /// [maxAge]: Maximum age for cache entries (default: 30 days).
  /// Returns the number of entries removed.
  Future<int> cleanupExpiredEntries(
      {Duration maxAge = const Duration(days: 30)}) async {
    try {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      final keysToRemove = <String>[];

      for (final key in _lruMap.keys.toList()) {
        try {
          final entry = _deserializeEntry(key);
          if (entry != null) {
            final age = now.difference(entry.lastAccessed);
            if (age > maxAge) {
              keysToRemove.add(key);
            }
          }
        } catch (e) {
          keysToRemove.add(key);
          WasteAppLogger.warning(
              'cache_cleanup_corrupted_entry_removing',
              context: {
                'key': _previewHash(key),
                'action': 'removing'
              });
        }
      }

      for (final key in keysToRemove) {
        await _cacheBox.delete(key);
        _lruMap.remove(key);
      }
      _statistics['size'] = _cacheBox.length;

      if (keysToRemove.isNotEmpty) {
        WasteAppLogger.cacheEvent('cache_cleanup_expired', 'classification',
            context: {
              'entries_removed': keysToRemove.length,
              'max_age_days': maxAge.inDays,
              'cache_size_after': _cacheBox.length,
            });
      }

      return keysToRemove.length;
    } catch (e) {
      WasteAppLogger.severe('cache_cleanup_error', error: e, context: {
        'cache_size': _cacheBox.length,
        'max_age_days': maxAge.inDays
      });
      return 0;
    }
  }

  /// Return cache statistics snapshot.
  Map<String, dynamic> getCacheStatistics() {
    final stats = Map<String, dynamic>.from(_statistics);

    final totalRequests = stats['hits'] + stats['misses'];
    stats['hitRate'] = totalRequests > 0
        ? (stats['hits'] / totalRequests * 100).toStringAsFixed(1) + '%'
        : '0%';

    final similarHits = stats['similarHits'] ?? 0;
    stats['similarHitRate'] = similarHits > 0 && stats['hits'] > 0
        ? '${(similarHits / stats['hits'] * 100).toStringAsFixed(1)}%'
        : '0%';

    final age = DateTime.now().difference(stats['createdAt'] as DateTime);
    stats['ageHours'] = age.inHours;

    final bytesSaved = stats['bytesSaved'] ?? 0;
    if (bytesSaved > 1024 * 1024) {
      stats['bytesSavedFormatted'] =
          '${(bytesSaved / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytesSaved > 1024) {
      stats['bytesSavedFormatted'] =
          '${(bytesSaved / 1024).toStringAsFixed(2)} KB';
    } else {
      stats['bytesSavedFormatted'] = '$bytesSaved bytes';
    }

    // Count hash types by inspecting stored entry imageHash
    var pHashCount = 0;
    var standardHashCount = 0;
    var fallbackHashCount = 0;
    for (final String key in _cacheBox.keys) {
      final raw = _rawPhashPrefix(key);
      if (raw.startsWith('phash_')) {
        pHashCount++;
      } else if (raw.startsWith('fallback_')) {
        fallbackHashCount++;
      } else {
        standardHashCount++;
      }
    }

    stats['pHashCount'] = pHashCount;
    stats['standardHashCount'] = standardHashCount;
    stats['fallbackHashCount'] = fallbackHashCount;

    return stats;
  }

  // ------------------------------------------------------------------
  // SIMILARITY SCANNING (perceptual hash Hamming distance + context)
  // ------------------------------------------------------------------

  /// Finds a similar perceptual hash entry with content hash verification.
  ///
  /// Two-stage verification:
  /// 1. Compute Hamming distance against cached entries' raw phash.
  /// 2. Verify content hash matches exactly (prevents false positives).
  Future<String?> _findSimilarPerceptualHashWithVerification(
      String cacheKey, String contentHash, int threshold) async {
    try {
      final rawKey = _rawPhashPrefix(cacheKey);
      final hexHash = _phashHex(rawKey);
      if (hexHash == null) return null;

      final binaryHash = _hexToBinary(hexHash);
      if (binaryHash.length != 64) return null;

      // Collect all perceptual hash keys from the box
      final pHashKeys =
          _cacheBox.keys.where((k) => _isPerceptualHash(k)).toList();
      WasteAppLogger.cacheEvent(
          'cache_similarity_scan_started', 'classification', context: {
        'candidates_count': pHashKeys.length,
        'threshold': threshold,
        'requested_content_hash': _previewHash(contentHash)
      });

      String? bestMatch;
      var bestDistance = threshold + 1;

      for (final String cachedKey in pHashKeys) {
        // Deserialize to get the entry's raw imageHash (it may differ
        // from the Hive key when context-aware keys are used).
        final cacheEntry = _deserializeEntry(cachedKey);
        if (cacheEntry == null) continue;

        final entryHex = _phashHex(_rawPhashPrefix(cacheEntry.imageHash));
        if (entryHex == null) continue;

        final entryBinary = _hexToBinary(entryHex);
        if (entryBinary.length != 64) continue;

        final distance = _hammingDistance(binaryHash, entryBinary);

        if (distance <= threshold) {
          // Candidate within threshold — verify content hash
          if (cacheEntry.contentHash != null &&
              cacheEntry.contentHash == contentHash) {
            if (distance < bestDistance) {
              bestDistance = distance;
              bestMatch = cachedKey;
              if (distance == 0) break;
            }
          } else {
            WasteAppLogger.cacheEvent(
                'cache_similarity_candidate_rejected_context_mismatch',
                'classification',
                context: {
                  'candidate_key': _previewHash(cachedKey),
                  'distance': distance,
                  'reason': cacheEntry.contentHash == null
                      ? 'entry_missing_content_hash'
                      : 'content_hash_mismatch'
                });
          }
        }
      }

      if (bestMatch != null) {
        WasteAppLogger.cacheEvent(
            'cache_similarity_best_match_found', 'classification',
            context: {
              'matched_key': _previewHash(bestMatch),
              'distance': bestDistance,
              'threshold': threshold
            });
      }

      return bestMatch;
    } catch (e) {
      WasteAppLogger.severe('cache_similarity_search_error', error: e,
          context: {'key': _previewHash(cacheKey)});
      return null;
    }
  }

  /// Basic perceptual similarity search (no content verification).
  /// Only used when [CacheFeatureFlags.contentHashVerificationEnabled] is
  /// false — and even then only for context-agnostic entries
  /// (contentHash == null).
  Future<String?> _findSimilarPerceptualHash(
      String cacheKey, int threshold) async {
    try {
      final rawKey = _rawPhashPrefix(cacheKey);
      final hexHash = _phashHex(rawKey);
      if (hexHash == null) return null;

      final binaryHash = _hexToBinary(hexHash);
      if (binaryHash.length != 64) return null;

      String? bestMatch;
      var bestDistance = threshold + 1;

      final pHashKeys =
          _cacheBox.keys.where((k) => _isPerceptualHash(k)).toList();

      for (final String cachedKey in pHashKeys) {
        final cacheEntry = _deserializeEntry(cachedKey);
        if (cacheEntry == null) continue;

        final entryHex = _phashHex(_rawPhashPrefix(cacheEntry.imageHash));
        if (entryHex == null) continue;

        final entryBinary = _hexToBinary(entryHex);
        if (entryBinary.length != 64) continue;

        final distance = _hammingDistance(binaryHash, entryBinary);

        if (distance <= threshold && distance < bestDistance) {
          bestDistance = distance;
          bestMatch = cachedKey;
          if (distance == 0) break;
        }
      }

      return bestMatch;
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  /// Returns true if [key] starts with a perceptual hash prefix.
  bool _isPerceptualHash(String key) =>
      _rawPhashPrefix(key).startsWith('phash_');

  /// Extracts the 16-hex-char portion after 'phash_' from a raw hash.
  /// Returns null on format error.
  String? _phashHex(String raw) {
    if (!raw.startsWith('phash_')) return null;
    final hex = raw.substring(6);
    if (hex.length != 16) return null;
    return hex;
  }

  /// Hamming distance between two equal-length binary strings.
  int _hammingDistance(String a, String b) {
    if (a.length != b.length) {
      throw ArgumentError('Strings must be of equal length');
    }
    var distance = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) distance++;
    }
    return distance;
  }

  /// Converts a hexadecimal string to a binary string.
  String _hexToBinary(String hex) {
    var binary = '';
    for (var i = 0; i < hex.length; i++) {
      final value = int.parse(hex[i], radix: 16);
      binary += value.toRadixString(2).padLeft(4, '0');
    }
    return binary;
  }

  /// Deserialize a cache entry from its Hive key.
  CachedClassification? _deserializeEntry(String key) {
    try {
      final jsonString = _cacheBox.get(key);
      if (jsonString == null) return null;
      return CachedClassification.deserialize(jsonString);
    } catch (e) {
      WasteAppLogger.warning('cache_deserialize_corrupted_entry',
          error: e, context: {'key': _previewHash(key)});
      return null;
    }
  }

  /// Get the cache box for testing purposes.
  Box<String> get cacheBox => _cacheBox;
}

/// Temporary alias to maintain compatibility with older tests that referenced
/// `CacheService`.
typedef CacheService = ClassificationCacheService;

// ------------------------------------------------------------------
// FEATURE FLAGS
// ------------------------------------------------------------------

/// Feature flags for cache service.
class CacheFeatureFlags {
  static bool _contentHashVerificationEnabled = true;

  /// Enable/disable content hash verification (kill-switch for production).
  static bool get contentHashVerificationEnabled =>
      _contentHashVerificationEnabled;

  /// Set content hash verification state (for testing or remote config).
  static void setContentHashVerification(bool enabled) {
    _contentHashVerificationEnabled = enabled;
    WasteAppLogger.cacheEvent(
        'cache_feature_flag_content_hash_verification', 'classification',
        context: {'enabled': enabled});
  }

  /// Initialize feature flags from remote config (placeholder).
  static Future<void> initialize() async {
    // TODO: Integrate with Firebase Remote Config
    WasteAppLogger.cacheEvent(
        'cache_feature_flags_initialized_default', 'classification');
  }
}
