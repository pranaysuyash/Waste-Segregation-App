import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../utils/waste_app_logger.dart';

/// Enhanced cache service with LRU eviction, size limits, and image compression
class EnhancedCacheService {
  EnhancedCacheService({
    int? maxCacheSize,
    int? maxCacheSizeBytes,
    double? compressionQuality,
    int? maxImageDimension,
  })  : _maxCacheSize = maxCacheSize ?? 2000,
        _maxCacheSizeBytes = maxCacheSizeBytes ?? 100 * 1024 * 1024, // 100MB
        _compressionQuality = compressionQuality ?? 0.8,
        _maxImageDimension = maxImageDimension ?? 1024;

  static final EnhancedCacheService _instance = EnhancedCacheService();
  static EnhancedCacheService get instance => _instance;

  // Configuration
  final int _maxCacheSize;
  final int _maxCacheSizeBytes;
  final double _compressionQuality;
  final int _maxImageDimension;

  // Storage
  late Box<String> _cacheBox;
  late Box<Uint8List> _imageBox;
  bool _isInitialized = false;

  // LRU tracking
  final LinkedHashMap<String, DateTime> _lruMap =
      LinkedHashMap<String, DateTime>();

  // Size tracking
  int _currentCacheSizeBytes = 0;

  // Statistics
  final Map<String, dynamic> _statistics = {
    'hits': 0,
    'misses': 0,
    'compressionSavings': 0,
    'totalRequests': 0,
    'averageCompressionRatio': 0.0,
    'createdAt': DateTime.now(),
  };

  // Compression pipeline
  final Map<String, Uint8List> _compressionCache = {};
  Timer? _compressionCleanupTimer;

  /// Initialize the enhanced cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open cache boxes
      _cacheBox = await Hive.openBox<String>('enhanced_cache_classifications');
      _imageBox = await Hive.openBox<Uint8List>('enhanced_cache_images');

      // Load existing cache entries into LRU map and calculate size
      await _loadCacheMetadata();

      // Start periodic cleanup
      _startPeriodicCleanup();

      _isInitialized = true;

      WasteAppLogger.info('Enhanced cache service initialized', context: {
        'service': 'enhanced_cache',
        'cache_entries': _cacheBox.length,
        'image_entries': _imageBox.length,
        'cache_size_mb':
            (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'max_size_mb': (_maxCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      });
    } catch (e) {
      WasteAppLogger.severe('Enhanced cache initialization failed',
          error: e,
          context: {
            'service': 'enhanced_cache',
            'max_cache_size': _maxCacheSize,
            'max_size_bytes': _maxCacheSizeBytes,
          });
      rethrow;
    }
  }

  /// Load cache metadata for LRU tracking and size calculation
  Future<void> _loadCacheMetadata() async {
    _currentCacheSizeBytes = 0;

    for (final String hash in _cacheBox.keys) {
      try {
        final jsonString = _cacheBox.get(hash);
        if (jsonString != null) {
          final cacheEntry = CachedClassification.deserialize(jsonString);
          _lruMap[hash] = cacheEntry.lastAccessed;

          // Calculate size
          final entrySize = _calculateEntrySize(jsonString);
          final imageData = _imageBox.get(hash);
          if (imageData != null) {
            _currentCacheSizeBytes += entrySize + imageData.length;
          } else {
            _currentCacheSizeBytes += entrySize;
          }
        }
      } catch (e) {
        WasteAppLogger.warning('Error loading cache entry metadata',
            error: e,
            context: {
              'service': 'enhanced_cache',
              'hash': hash.substring(0, 16),
            });
      }
    }

    // Sort LRU map by access time
    final sortedEntries = _lruMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _lruMap.clear();
    for (final entry in sortedEntries) {
      _lruMap[entry.key] = entry.value;
    }
  }

  /// Get cached classification with enhanced LRU management
  Future<CachedClassification?> getCachedClassification(
    String imageHash, {
    String? contentHash,
    int similarityThreshold = 6,
  }) async {
    if (!_isInitialized) await initialize();

    _statistics['totalRequests']++;

    try {
      // Check for exact match first
      if (_cacheBox.containsKey(imageHash)) {
        final cacheEntry = await _getCacheEntry(imageHash);
        if (cacheEntry != null) {
          _statistics['hits']++;
          await _updateLRU(imageHash, cacheEntry);

          WasteAppLogger.cacheEvent('cache_hit', 'enhanced_classification',
              hit: true,
              key: imageHash.substring(0, 16),
              context: {
                'match_type': 'exact',
                'cache_age_minutes':
                    DateTime.now().difference(cacheEntry.timestamp).inMinutes,
                'item_name': cacheEntry.classification.itemName,
              });

          return cacheEntry;
        }
      }

      // Check for similar perceptual hashes if applicable
      if (imageHash.startsWith('phash_') && contentHash != null) {
        final similarHash =
            await _findSimilarHash(imageHash, contentHash, similarityThreshold);
        if (similarHash != null) {
          final cacheEntry = await _getCacheEntry(similarHash);
          if (cacheEntry != null) {
            _statistics['hits']++;
            await _updateLRU(similarHash, cacheEntry);

            WasteAppLogger.cacheEvent('cache_hit', 'enhanced_classification',
                hit: true,
                key: imageHash.substring(0, 16),
                context: {
                  'match_type': 'similar',
                  'matched_hash': similarHash.substring(0, 16),
                  'cache_age_minutes':
                      DateTime.now().difference(cacheEntry.timestamp).inMinutes,
                  'item_name': cacheEntry.classification.itemName,
                });

            return cacheEntry;
          }
        }
      }

      // Cache miss
      _statistics['misses']++;
      WasteAppLogger.cacheEvent('cache_miss', 'enhanced_classification',
          hit: false,
          key: imageHash.substring(0, 16),
          context: {
            'cache_size': _cacheBox.length,
            'cache_size_mb':
                (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
          });

      return null;
    } catch (e) {
      WasteAppLogger.severe('Error retrieving from enhanced cache',
          error: e,
          context: {
            'service': 'enhanced_cache',
            'hash': imageHash.substring(0, 16),
          });
      _statistics['misses']++;
      return null;
    }
  }

  /// Cache classification with image compression
  Future<void> cacheClassification(
    String imageHash,
    WasteClassification classification, {
    String? contentHash,
    String? imagePath,
    Uint8List? imageData,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Compress image if provided
      Uint8List? compressedImageData;
      var originalSize = 0;
      var compressedSize = 0;

      if (imagePath != null || imageData != null) {
        final result =
            await _compressImage(imagePath: imagePath, imageData: imageData);
        if (result != null) {
          compressedImageData = result['compressed'];
          originalSize = result['originalSize'];
          compressedSize = result['compressedSize'];

          final compressionRatio =
              originalSize > 0 ? (compressedSize / originalSize) : 1.0;
          _statistics['compressionSavings'] += originalSize - compressedSize;
          _updateAverageCompressionRatio(compressionRatio);
        }
      }

      // Create cache entry
      final cacheEntry = CachedClassification.fromClassification(
        imageHash,
        classification,
        contentHash: contentHash,
        imageSize: compressedSize > 0 ? compressedSize : originalSize,
      );

      // Ensure cache size limits before adding
      await _ensureCacheSize(
        additionalSize:
            _calculateEntrySize(cacheEntry.serialize()) + compressedSize,
      );

      // Store classification data
      await _cacheBox.put(imageHash, cacheEntry.serialize());

      // Store compressed image data if available
      if (compressedImageData != null) {
        await _imageBox.put(imageHash, compressedImageData);
      }

      // Update LRU tracking
      await _updateLRU(imageHash, cacheEntry);

      // Update size tracking
      _currentCacheSizeBytes +=
          _calculateEntrySize(cacheEntry.serialize()) + compressedSize;

      WasteAppLogger.cacheEvent('cache_store', 'enhanced_classification',
          key: imageHash.substring(0, 16),
          context: {
            'item_name': classification.itemName,
            'has_content_hash': contentHash != null,
            'has_image': compressedImageData != null,
            'original_size': originalSize,
            'compressed_size': compressedSize,
            'compression_ratio': originalSize > 0
                ? (compressedSize / originalSize).toStringAsFixed(3)
                : 'N/A',
            'cache_size': _cacheBox.length,
            'cache_size_mb':
                (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
          });
    } catch (e) {
      WasteAppLogger.severe('Error caching classification in enhanced cache',
          error: e,
          context: {
            'service': 'enhanced_cache',
            'hash': imageHash.substring(0, 16),
            'item_name': classification.itemName,
          });
    }
  }

  /// Compress image data for efficient storage
  Future<Map<String, dynamic>?> _compressImage({
    String? imagePath,
    Uint8List? imageData,
  }) async {
    try {
      Uint8List originalData;

      if (imagePath != null) {
        final file = File(imagePath);
        if (!await file.exists()) return null;
        originalData = await file.readAsBytes();
      } else if (imageData != null) {
        originalData = imageData;
      } else {
        return null;
      }

      final originalSize = originalData.length;

      // Check compression cache first
      final cacheKey = originalData.hashCode.toString();
      if (_compressionCache.containsKey(cacheKey)) {
        final cached = _compressionCache[cacheKey]!;
        return {
          'compressed': cached,
          'originalSize': originalSize,
          'compressedSize': cached.length,
        };
      }

      // Decode image
      var image = img.decodeImage(originalData);
      if (image == null) return null;

      // Resize if too large
      if (image.width > _maxImageDimension ||
          image.height > _maxImageDimension) {
        final aspectRatio = image.width / image.height;
        int newWidth, newHeight;

        if (image.width > image.height) {
          newWidth = _maxImageDimension;
          newHeight = (_maxImageDimension / aspectRatio).round();
        } else {
          newHeight = _maxImageDimension;
          newWidth = (_maxImageDimension * aspectRatio).round();
        }

        image = img.copyResize(image, width: newWidth, height: newHeight);
      }

      // Compress as JPEG
      final compressedData = img.encodeJpg(
        image,
        quality: (_compressionQuality * 100).round(),
      );

      final compressedSize = compressedData.length;

      // Cache the compression result temporarily
      _compressionCache[cacheKey] = compressedData;
      _scheduleCompressionCleanup();

      return {
        'compressed': compressedData,
        'originalSize': originalSize,
        'compressedSize': compressedSize,
      };
    } catch (e) {
      WasteAppLogger.warning('Image compression failed', error: e, context: {
        'service': 'enhanced_cache',
        'image_path': imagePath?.substring(imagePath.length - 20),
        'has_image_data': imageData != null,
      });
      return null;
    }
  }

  /// Get cached image data
  Future<Uint8List?> getCachedImage(String imageHash) async {
    if (!_isInitialized) await initialize();

    try {
      return _imageBox.get(imageHash);
    } catch (e) {
      WasteAppLogger.warning('Error retrieving cached image',
          error: e,
          context: {
            'service': 'enhanced_cache',
            'hash': imageHash.substring(0, 16),
          });
      return null;
    }
  }

  /// Ensure cache doesn't exceed size limits
  Future<void> _ensureCacheSize({int additionalSize = 0}) async {
    final projectedSize = _currentCacheSizeBytes + additionalSize;
    final projectedCount = _cacheBox.length + 1;

    if (projectedSize <= _maxCacheSizeBytes &&
        projectedCount <= _maxCacheSize) {
      return;
    }

    // Calculate how much to remove (remove 20% when limit is reached)
    final targetSize = (_maxCacheSizeBytes * 0.8).round();
    final targetCount = (_maxCacheSize * 0.8).round();

    var removedSize = 0;
    var removedCount = 0;
    final keysToRemove = <String>[];

    // Remove least recently used entries
    for (final key in _lruMap.keys.toList().reversed) {
      if (_currentCacheSizeBytes - removedSize <= targetSize &&
          _cacheBox.length - removedCount <= targetCount) {
        break;
      }

      final entrySize = await _getEntrySize(key);
      keysToRemove.add(key);
      removedSize += entrySize;
      removedCount++;
    }

    // Remove entries
    for (final key in keysToRemove) {
      await _removeEntry(key);
    }

    WasteAppLogger.info('Cache eviction completed', context: {
      'service': 'enhanced_cache',
      'entries_removed': removedCount,
      'bytes_removed': removedSize,
      'cache_size_after': _cacheBox.length,
      'cache_bytes_after': _currentCacheSizeBytes,
      'target_size_mb': (targetSize / (1024 * 1024)).toStringAsFixed(2),
    });
  }

  /// Remove a cache entry and update tracking
  Future<void> _removeEntry(String key) async {
    final entrySize = await _getEntrySize(key);

    await _cacheBox.delete(key);
    await _imageBox.delete(key);
    _lruMap.remove(key);

    _currentCacheSizeBytes -= entrySize;
  }

  /// Get the size of a cache entry
  Future<int> _getEntrySize(String key) async {
    var size = 0;

    final classificationData = _cacheBox.get(key);
    if (classificationData != null) {
      size += _calculateEntrySize(classificationData);
    }

    final imageData = _imageBox.get(key);
    if (imageData != null) {
      size += imageData.length;
    }

    return size;
  }

  /// Calculate the size of a cache entry string
  int _calculateEntrySize(String data) {
    return utf8.encode(data).length;
  }

  /// Get cache entry and handle deserialization
  Future<CachedClassification?> _getCacheEntry(String hash) async {
    try {
      final jsonString = _cacheBox.get(hash);
      if (jsonString == null) return null;
      return CachedClassification.deserialize(jsonString);
    } catch (e) {
      WasteAppLogger.warning('Error deserializing cache entry',
          error: e,
          context: {
            'service': 'enhanced_cache',
            'hash': hash.substring(0, 16),
          });
      // Remove corrupted entry
      await _removeEntry(hash);
      return null;
    }
  }

  /// Update LRU tracking
  Future<void> _updateLRU(String hash, CachedClassification entry) async {
    entry.markUsed();
    _lruMap.remove(hash);
    _lruMap[hash] = entry.lastAccessed;

    // Update stored entry
    await _cacheBox.put(hash, entry.serialize());
  }

  /// Find similar hash with content verification
  Future<String?> _findSimilarHash(
      String pHash, String contentHash, int threshold) async {
    if (!pHash.startsWith('phash_')) return null;

    final hexHash = pHash.substring(6);
    if (hexHash.length != 16) return null;

    final binaryHash = _hexToBinary(hexHash);
    if (binaryHash.length != 64) return null;

    String? bestMatch;
    var bestDistance = threshold + 1;

    for (final String cachedHash in _cacheBox.keys) {
      if (!cachedHash.startsWith('phash_')) continue;

      final cachedHexHash = cachedHash.substring(6);
      if (cachedHexHash.length != 16) continue;

      final cachedBinaryHash = _hexToBinary(cachedHexHash);
      if (cachedBinaryHash.length != 64) continue;

      final distance = _hammingDistance(binaryHash, cachedBinaryHash);

      if (distance <= threshold) {
        final cacheEntry = await _getCacheEntry(cachedHash);
        if (cacheEntry?.contentHash == contentHash && distance < bestDistance) {
          bestDistance = distance;
          bestMatch = cachedHash;
          if (distance == 0) break;
        }
      }
    }

    return bestMatch;
  }

  /// Convert hex to binary string
  String _hexToBinary(String hex) {
    var binary = '';
    for (var i = 0; i < hex.length; i++) {
      final value = int.parse(hex[i], radix: 16);
      binary += value.toRadixString(2).padLeft(4, '0');
    }
    return binary;
  }

  /// Calculate Hamming distance between binary strings
  int _hammingDistance(String a, String b) {
    if (a.length != b.length) return 64; // Max distance for invalid comparison

    var distance = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) distance++;
    }
    return distance;
  }

  /// Update average compression ratio
  void _updateAverageCompressionRatio(double newRatio) {
    // Safe type extraction
    final currentAvgValue = _statistics['averageCompressionRatio'];
    final currentAvg = currentAvgValue is double ? currentAvgValue : 0.0;

    final totalRequestsValue = _statistics['totalRequests'];
    final totalRequests = totalRequestsValue is int ? totalRequestsValue : 0;

    if (totalRequests <= 1) {
      _statistics['averageCompressionRatio'] = newRatio;
    } else {
      _statistics['averageCompressionRatio'] =
          (currentAvg * (totalRequests - 1) + newRatio) / totalRequests;
    }
  }

  /// Schedule compression cache cleanup
  void _scheduleCompressionCleanup() {
    _compressionCleanupTimer?.cancel();
    _compressionCleanupTimer = Timer(const Duration(minutes: 5), () {
      _compressionCache.clear();
    });
  }

  /// Start periodic cleanup tasks
  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _performPeriodicCleanup();
    });
  }

  /// Perform periodic cleanup tasks
  Future<void> _performPeriodicCleanup() async {
    try {
      // Clean up compression cache
      _compressionCache.clear();

      // Validate cache integrity
      await _validateCacheIntegrity();

      WasteAppLogger.debug('Periodic cache cleanup completed', context: {
        'service': 'enhanced_cache',
        'cache_size': _cacheBox.length,
        'cache_size_mb':
            (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      });
    } catch (e) {
      WasteAppLogger.warning('Periodic cache cleanup failed',
          error: e,
          context: {
            'service': 'enhanced_cache',
          });
    }
  }

  /// Validate cache integrity and remove corrupted entries
  Future<void> _validateCacheIntegrity() async {
    final corruptedKeys = <String>[];

    for (final key in _cacheBox.keys) {
      try {
        final entry = await _getCacheEntry(key);
        if (entry == null) {
          corruptedKeys.add(key);
        }
      } catch (e) {
        corruptedKeys.add(key);
      }
    }

    for (final key in corruptedKeys) {
      await _removeEntry(key);
    }

    if (corruptedKeys.isNotEmpty) {
      WasteAppLogger.info('Removed corrupted cache entries', context: {
        'service': 'enhanced_cache',
        'corrupted_count': corruptedKeys.length,
      });
    }
  }

  /// Get comprehensive cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final stats = Map<String, dynamic>.from(_statistics);

    // Calculate derived statistics with safe type extraction
    final totalRequestsValue = stats['totalRequests'];
    final totalRequests = totalRequestsValue is int ? totalRequestsValue : 0;

    final hitsValue = stats['hits'];
    final hits = hitsValue is int ? hitsValue : 0;

    final missesValue = stats['misses'];
    final misses = missesValue is int ? missesValue : 0;

    stats['hitRate'] = totalRequests > 0
        ? '${((hits / totalRequests) * 100).toStringAsFixed(1)}%'
        : '0%';

    stats['currentSize'] = _cacheBox.length;
    stats['currentSizeBytes'] = _currentCacheSizeBytes;
    stats['currentSizeMB'] =
        (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    stats['maxSizeMB'] =
        (_maxCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    stats['utilizationPercent'] =
        '${((_currentCacheSizeBytes / _maxCacheSizeBytes) * 100).toStringAsFixed(1)}%';

    // Compression statistics with safe type extraction
    final compressionSavingsValue = stats['compressionSavings'];
    final compressionSavings =
        compressionSavingsValue is int ? compressionSavingsValue : 0;
    stats['compressionSavingsMB'] =
        (compressionSavings / (1024 * 1024)).toStringAsFixed(2);

    final avgCompressionValue = stats['averageCompressionRatio'];
    final avgCompression =
        avgCompressionValue is double ? avgCompressionValue : 0.0;
    stats['averageCompressionRatio'] = avgCompression.toStringAsFixed(3);

    // Age statistics
    final age = DateTime.now().difference(stats['createdAt'] as DateTime);
    stats['ageHours'] = age.inHours;
    stats['ageDays'] = age.inDays;

    return stats;
  }

  /// Clear all cache data
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();

    try {
      await _cacheBox.clear();
      await _imageBox.clear();
      _lruMap.clear();
      _compressionCache.clear();
      _currentCacheSizeBytes = 0;

      // Reset statistics
      _statistics.clear();
      _statistics.addAll({
        'hits': 0,
        'misses': 0,
        'compressionSavings': 0,
        'totalRequests': 0,
        'averageCompressionRatio': 0.0,
        'createdAt': DateTime.now(),
      });

      WasteAppLogger.info('Enhanced cache cleared', context: {
        'service': 'enhanced_cache',
      });
    } catch (e) {
      WasteAppLogger.severe('Error clearing enhanced cache',
          error: e,
          context: {
            'service': 'enhanced_cache',
          });
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    _compressionCleanupTimer?.cancel();
    _compressionCache.clear();
  }
}
