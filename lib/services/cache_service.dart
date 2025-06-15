import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/constants.dart';

/// Service for caching image classifications
///
/// This service manages the local caching of image classification results
/// to reduce redundant API calls, improve response times, and ensure
/// consistent classification results for identical images.
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
  /// Maps imageHash to lastAccessed timestamp
  final LinkedHashMap<String, DateTime> _lruMap = LinkedHashMap<String, DateTime>();

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
      debugPrint('Classification cache initialized with ${_cacheBox.length} entries');
    } catch (e) {
      debugPrint('Error initializing classification cache: $e');
      rethrow;
    }
  }

  /// Load the LRU map from the cache box for faster access
  void _loadLruMapFromCache() {
    for (final String hash in _cacheBox.keys) {
      try {
        final cacheEntry = _deserializeEntry(hash);
        if (cacheEntry != null) {
          _lruMap[hash] = cacheEntry.lastAccessed;
        }
      } catch (e) {
        debugPrint('Error loading cache entry $hash: $e');
        // Skip corrupted entries
      }
    }
    
    // Sort the LRU map by lastAccessed (most recently used first)
    final sortedEntries = _lruMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _lruMap.clear();
    for (final entry in sortedEntries) {
      _lruMap[entry.key] = entry.value;
    }
  }

  /// Get a cached classification by image hash
  /// 
  /// This method checks for both exact matches and similar images when using
  /// perceptual hashing (phash_) prefixes. Uses dual-hash verification to prevent
  /// false positives: perceptual hash for similarity + content hash for verification.
  ///
  /// [imageHash]: The hash of the image to find in cache
  /// [contentHash]: The content hash for exact verification (required for similarity matching)
  /// [similarityThreshold]: The maximum number of bits that can differ for similar hashes (default: 6)
  Future<CachedClassification?> getCachedClassification(
    String imageHash, {
    String? contentHash,
    int similarityThreshold = 6  // LOWERED: from 10 to 6 for stricter matching
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Check for exact match first
      if (_cacheBox.containsKey(imageHash)) {
        final cacheEntry = _deserializeEntry(imageHash);
        
        if (cacheEntry != null) {
          // Update stats
          _statistics['hits']++;
          debugPrint('Cache hit (exact match) for image hash: $imageHash');
          debugPrint('Cache entry created: ${cacheEntry.timestamp}, last accessed: ${cacheEntry.lastAccessed}');
          
          // Crashlytics breadcrumb for field debugging (safe for testing)
          try {
            FirebaseCrashlytics.instance.log('CACHE exact_hit hash=${imageHash.substring(0, 16)}... age=${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min');
          } catch (e) {
            // Firebase not initialized (testing environment)
            debugPrint('Crashlytics not available: $e');
          }
          
          // Update LRU tracking
          cacheEntry.markUsed();
          _lruMap.remove(imageHash);
          _lruMap[imageHash] = cacheEntry.lastAccessed;
          
          // Update the stored entry with new access info
          await _cacheBox.put(imageHash, cacheEntry.serialize());
          
          return cacheEntry;
        }
      }
      
      // If this is a perceptual hash, check for similar matches with dual-hash verification
      if (imageHash.startsWith('phash_') && contentHash != null && CacheFeatureFlags.contentHashVerificationEnabled) {
        debugPrint('Looking for similar perceptual hashes to $imageHash with threshold $similarityThreshold');
        final similarHash = await _findSimilarPerceptualHashWithVerification(
          imageHash, 
          contentHash, 
          similarityThreshold
        );
        
        if (similarHash != null) {
          final cacheEntry = _deserializeEntry(similarHash);
          
          if (cacheEntry != null) {
            // Update stats - count as hit but also track similar hits separately
            _statistics['hits']++;
            _statistics['similarHits'] = (_statistics['similarHits'] ?? 0) + 1;
            debugPrint('Cache hit (verified similar match) for image hash: original=$imageHash, matched=$similarHash');
            debugPrint('Similar cache entry created: ${cacheEntry.timestamp}, last accessed: ${cacheEntry.lastAccessed}');
            
            // Crashlytics breadcrumb for field debugging (safe for testing)
            try {
              FirebaseCrashlytics.instance.log('CACHE verified_similar_hit original=${imageHash.substring(0, 16)}... matched=${similarHash.substring(0, 16)}... age=${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min');
            } catch (e) {
              // Firebase not initialized (testing environment)
              debugPrint('Crashlytics not available: $e');
            }
            
            // Update LRU tracking
            cacheEntry.markUsed();
            _lruMap.remove(similarHash);
            _lruMap[similarHash] = cacheEntry.lastAccessed;
            
            // Update the stored entry with new access info
            await _cacheBox.put(similarHash, cacheEntry.serialize());
            
            return cacheEntry;
          }
        } else {
          debugPrint('No verified similar hashes found for $imageHash');
        }
      } else if (imageHash.startsWith('phash_') && !CacheFeatureFlags.contentHashVerificationEnabled) {
        debugPrint('🔧 KILL-SWITCH: Content hash verification disabled - falling back to basic perceptual matching');
        final similarHash = await _findSimilarPerceptualHash(imageHash, similarityThreshold);
        
        if (similarHash != null) {
          final cacheEntry = _deserializeEntry(similarHash);
          
          if (cacheEntry != null) {
            _statistics['hits']++;
            _statistics['similarHits'] = (_statistics['similarHits'] ?? 0) + 1;
            debugPrint('Cache hit (basic similarity match) for image hash: original=$imageHash, matched=$similarHash');
            
            // Update LRU tracking
            cacheEntry.markUsed();
            _lruMap.remove(similarHash);
            _lruMap[similarHash] = cacheEntry.lastAccessed;
            
            // Update the stored entry with new access info
            await _cacheBox.put(similarHash, cacheEntry.serialize());
            
            return cacheEntry;
          }
        }
      } else if (imageHash.startsWith('phash_') && contentHash == null) {
        debugPrint('⚠️ Perceptual hash provided without content hash - skipping similarity search for safety');
      }
      
      // Cache miss
      _statistics['misses']++;
      debugPrint('Cache miss for image hash: $imageHash');
      debugPrint('Current cache size: ${_cacheBox.length} entries');
      
      // Crashlytics breadcrumb for field debugging (safe for testing)
      try {
        FirebaseCrashlytics.instance.log('CACHE miss hash=${imageHash.substring(0, 16)}... cache_size=${_cacheBox.length}');
      } catch (e) {
        // Firebase not initialized (testing environment)
        debugPrint('Crashlytics not available: $e');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error retrieving from cache: $e');
      // If there's any error, treat it as a cache miss
      _statistics['misses']++;
      return null;
    }
  }
  
  /// Finds a similar perceptual hash in the cache with content hash verification
  /// 
  /// Two-stage verification process:
  /// 1. Find perceptual hashes with small Hamming distance (similarity)
  /// 2. Verify content hash matches exactly (prevents false positives)
  ///
  /// [pHash]: The perceptual hash to compare (must start with 'phash_')
  /// [contentHash]: The content hash for exact verification
  /// [threshold]: Maximum number of bits that can differ (0-64, where lower is more strict)
  Future<String?> _findSimilarPerceptualHashWithVerification(
    String pHash, 
    String contentHash, 
    int threshold
  ) async {
    try {
      if (!pHash.startsWith('phash_')) {
        debugPrint('Not a perceptual hash (no phash_ prefix): $pHash');
        return null;
      }
      
      // Extract the hex part
      final hexHash = pHash.substring(6); // Remove 'phash_' prefix
      if (hexHash.length != 16) {
        debugPrint('Invalid perceptual hash length: ${hexHash.length} (expected 16)');
        return null; // Should be 16 hex chars (64 bits)
      }
      
      // Convert to binary
      final binaryHash = _hexToBinary(hexHash);
      if (binaryHash.length != 64) {
        debugPrint('Invalid binary hash length: ${binaryHash.length} (expected 64)');
        return null;
      }
      
      debugPrint('🔍 DUAL-HASH: Searching for similar hashes to: $pHash (bin: ${binaryHash.substring(0, 16)}...)');
      debugPrint('🔍 DUAL-HASH: Content hash for verification: $contentHash');
      
      // Get all perceptual hashes in cache for faster processing
      final pHashKeys = _cacheBox.keys.where((key) => key.startsWith('phash_')).toList();
      debugPrint('🔍 DUAL-HASH: Found ${pHashKeys.length} perceptual hashes in cache to compare');
      
      // Track best match
      String? bestMatch;
      var bestDistance = threshold + 1; // Initialize with a value greater than threshold
      final allDistances = <int>[]; // Track all distances for debugging
      var verificationAttempts = 0;
      var verificationFailures = 0;
      
      // Compare with all perceptual hashes in cache
      for (final String cachedHash in pHashKeys) {
        final cachedHexHash = cachedHash.substring(6);
        if (cachedHexHash.length != 16) continue;
        
        final cachedBinaryHash = _hexToBinary(cachedHexHash);
        if (cachedBinaryHash.length != 64) continue;
        
        // Calculate Hamming distance (number of bits that differ)
        final distance = _hammingDistance(binaryHash, cachedBinaryHash);
        
        // Log every distance calculated, even if above threshold
        debugPrint('🔍 DUAL-HASH: Comparing with $cachedHash: distance = $distance (threshold = $threshold)');
        allDistances.add(distance);
        
        // If distance is within threshold, verify with content hash
        if (distance <= threshold) {
          verificationAttempts++;
          
          // Get the cached entry to check content hash
          final cacheEntry = _deserializeEntry(cachedHash);
          if (cacheEntry != null && cacheEntry.contentHash != null) {
            debugPrint('🔍 DUAL-HASH: Verifying content hash for similar pHash $cachedHash');
            debugPrint('🔍 DUAL-HASH: Cached content hash: ${cacheEntry.contentHash}');
            debugPrint('🔍 DUAL-HASH: Current content hash: $contentHash');
            
            // Content hash must match exactly for verification
            if (cacheEntry.contentHash == contentHash) {
              debugPrint('✅ DUAL-HASH: Content hash verification PASSED - same image confirmed');
              
              // If it's a better match than current best, update it
              if (distance < bestDistance) {
                bestDistance = distance;
                bestMatch = cachedHash;
                
                // If exact match (distance = 0), return immediately
                if (distance == 0) break;
              }
            } else {
              verificationFailures++;
              debugPrint('❌ DUAL-HASH: Content hash verification FAILED - different image (pHash distance: $distance)');
              debugPrint('❌ DUAL-HASH: This prevents false positive cache hit');
            }
          } else {
            debugPrint('⚠️ DUAL-HASH: Cached entry missing content hash - skipping verification');
          }
        }
      }
      
      if (bestMatch != null) {
        debugPrint('✅ DUAL-HASH: Found verified similar hash: $bestMatch with distance $bestDistance');
        debugPrint('✅ DUAL-HASH: Verification stats - attempts: $verificationAttempts, failures: $verificationFailures');
      } else {
        // More detailed logging for debug purposes
        if (allDistances.isNotEmpty) {
          allDistances.sort(); // Sort distances for better analysis
          final minDistance = allDistances.first;
          debugPrint('❌ DUAL-HASH: No verified similar hashes found within threshold $threshold');
          debugPrint('❌ DUAL-HASH: Closest pHash distance: $minDistance, verification attempts: $verificationAttempts, failures: $verificationFailures');
          
          if (verificationFailures > 0) {
            debugPrint('🛡️ DUAL-HASH: Prevented $verificationFailures potential false positive(s)');
            // Crashlytics breadcrumb for false positive prevention tracking (safe for testing)
            try {
              FirebaseCrashlytics.instance.log('CACHE prevented_false_positives count=$verificationFailures hash=${pHash.substring(0, 16)}...');
            } catch (e) {
              // Firebase not initialized (testing environment)
              debugPrint('Crashlytics not available: $e');
            }
          }
          
          // Log distribution of distances
          final distCounts = <int, int>{};
          for (final d in allDistances) {
            distCounts[d] = (distCounts[d] ?? 0) + 1;
          }
          final keys = distCounts.keys.toList()..sort();
          final distLog = StringBuffer('🔍 DUAL-HASH: Distance distribution: ');
          for (final k in keys) {
            distLog.write('$k: ${distCounts[k]} hashes, ');
          }
          debugPrint(distLog.toString());
        } else {
          debugPrint('❌ DUAL-HASH: No similar hashes found within threshold $threshold. No perceptual hashes to compare.');
        }
      }
      
      return bestMatch;
    } catch (e) {
      debugPrint('❌ DUAL-HASH: Error finding similar perceptual hash: $e');
      return null;
    }
  }
  
  /// Calculates the Hamming distance between two binary strings
  /// (the number of positions at which corresponding bits differ)
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
  
  /// Converts a hexadecimal string to a binary string
  String _hexToBinary(String hex) {
    var binary = '';
    
    for (var i = 0; i < hex.length; i++) {
      // Convert each hex digit to 4 binary digits
      final value = int.parse(hex[i], radix: 16);
      final binDigit = value.toRadixString(2).padLeft(4, '0');
      binary += binDigit;
    }
    
    return binary;
  }

  /// Cache a classification result with the given image hash
  Future<void> cacheClassification(
    String imageHash,
    WasteClassification classification, {
    String? contentHash,
    int? imageSize,
  }) async {
    try {
      if (!_isInitialized) {
        debugPrint('Cache not initialized, initializing now...');
        await initialize();
      }
      
      // Check if this hash already exists (shouldn't happen due to prior check, but just in case)
      if (_cacheBox.containsKey(imageHash)) {
        debugPrint('Warning: Hash already exists in cache: $imageHash. Updating existing entry.');
        // Get the existing entry
        final existingEntry = _deserializeEntry(imageHash);
        if (existingEntry != null) {
          debugPrint('Existing entry found for $imageHash, created at ${existingEntry.timestamp}');
        }
      }
      
      // Create cache entry with content hash for dual-hash verification
      final cacheEntry = CachedClassification.fromClassification(
        imageHash,
        classification,
        contentHash: contentHash,
        imageSize: imageSize,
      );
      
      // Manage cache size (evict oldest entries if needed)
      await _ensureCacheSize();
      
      // Add to cache
      await _cacheBox.put(imageHash, cacheEntry.serialize());
      
      // Update LRU tracking
      _lruMap.remove(imageHash);
      _lruMap[imageHash] = cacheEntry.lastAccessed;
      
      // Update statistics
      _statistics['size'] = _cacheBox.length;
      if (imageSize != null) {
        _statistics['bytesSaved'] = (_statistics['bytesSaved'] ?? 0) + imageSize;
      }
      
      debugPrint('Successfully cached classification for $imageHash (${classification.itemName})');
      if (contentHash != null) {
        debugPrint('🔍 DUAL-HASH: Stored with content hash: $contentHash');
      }
      debugPrint('Current cache size: ${_cacheBox.length} entries');
    } catch (e) {
      debugPrint('ERROR caching classification: $e');
      // Errors during caching shouldn't break the app flow
    }
  }

  /// Ensure the cache doesn't exceed maximum size
  Future<void> _ensureCacheSize() async {
    if (_cacheBox.length < _maxCacheSize) return;
    
    // Get the least recently used entries to remove
    final entriesToRemove = _maxCacheSize * 0.1; // Remove 10% of max cache
    final keysToRemove = <String>[];
    
    // We'll use the LRU map which is already sorted by access time
    var count = 0;
    for (final key in _lruMap.keys.toList().reversed) {
      keysToRemove.add(key);
      count++;
      if (count >= entriesToRemove) break;
    }
    
    // Remove entries
    for (final key in keysToRemove) {
      await _cacheBox.delete(key);
      _lruMap.remove(key);
    }
    
    debugPrint('Removed ${keysToRemove.length} least recently used cache entries');
  }

  /// Clear the entire cache
  Future<void> clearCache() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _cacheBox.clear();
      _lruMap.clear();
      
      // Reset statistics
      _statistics['hits'] = 0;
      _statistics['misses'] = 0;
      _statistics['size'] = 0;
      _statistics['bytesSaved'] = 0;
      _statistics['createdAt'] = DateTime.now();
      
      debugPrint('Classification cache cleared');
    } catch (e) {
      debugPrint('Error clearing classification cache: $e');
      rethrow;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final stats = Map<String, dynamic>.from(_statistics);
    
    // Calculate hit rate
    final totalRequests = stats['hits'] + stats['misses'];
    stats['hitRate'] = totalRequests > 0 
        ? (stats['hits'] / totalRequests * 100).toStringAsFixed(1) + '%'
        : '0%';
    
    // Calculate similar hit rate when available
    final similarHits = stats['similarHits'] ?? 0;
    if (similarHits > 0) {
      final similarHitPercent = (similarHits / stats['hits'] * 100).toStringAsFixed(1);
      stats['similarHitRate'] = '$similarHitPercent%';
    } else {
      stats['similarHitRate'] = '0%';
    }
    
    // Calculate age
    final age = DateTime.now().difference(stats['createdAt'] as DateTime);
    stats['ageHours'] = age.inHours;
    
    // Format bytesSaved
    final bytesSaved = stats['bytesSaved'] ?? 0;
    if (bytesSaved > 1024 * 1024) {
      stats['bytesSavedFormatted'] = '${(bytesSaved / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytesSaved > 1024) {
      stats['bytesSavedFormatted'] = '${(bytesSaved / 1024).toStringAsFixed(2)} KB';
    } else {
      stats['bytesSavedFormatted'] = '$bytesSaved bytes';
    }
    
    // Count hash types
    var pHashCount = 0;
    var standardHashCount = 0;
    var fallbackHashCount = 0;
    
    for (final String key in _cacheBox.keys) {
      if (key.startsWith('phash_')) {
        pHashCount++;
      } else if (key.startsWith('fallback_')) {
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

  /// Helper method to deserialize a cache entry
  CachedClassification? _deserializeEntry(String hash) {
    try {
      final jsonString = _cacheBox.get(hash);
      if (jsonString == null) return null;
      
      return CachedClassification.deserialize(jsonString);
    } catch (e) {
      debugPrint('Error deserializing cache entry: $e');
      return null;
    }
  }

  /// Finds a similar perceptual hash in the cache (basic version without content verification)
  /// Used as fallback when content hash verification is disabled via kill-switch
  Future<String?> _findSimilarPerceptualHash(String pHash, int threshold) async {
    try {
      if (!pHash.startsWith('phash_')) {
        debugPrint('Not a perceptual hash (no phash_ prefix): $pHash');
        return null;
      }
      
      // Extract the hex part
      final hexHash = pHash.substring(6); // Remove 'phash_' prefix
      if (hexHash.length != 16) {
        debugPrint('Invalid perceptual hash length: ${hexHash.length} (expected 16)');
        return null; // Should be 16 hex chars (64 bits)
      }
      
      // Convert to binary
      final binaryHash = _hexToBinary(hexHash);
      if (binaryHash.length != 64) {
        debugPrint('Invalid binary hash length: ${binaryHash.length} (expected 64)');
        return null;
      }
      
      debugPrint('🔧 BASIC: Searching for similar hashes to: $pHash (bin: ${binaryHash.substring(0, 16)}...)');
      
      // Get all perceptual hashes in cache for faster processing
      final pHashKeys = _cacheBox.keys.where((key) => key.startsWith('phash_')).toList();
      debugPrint('🔧 BASIC: Found ${pHashKeys.length} perceptual hashes in cache to compare');
      
      // Track best match
      String? bestMatch;
      var bestDistance = threshold + 1; // Initialize with a value greater than threshold
      
      // Compare with all perceptual hashes in cache
      for (final String cachedHash in pHashKeys) {
        final cachedHexHash = cachedHash.substring(6);
        if (cachedHexHash.length != 16) continue;
        
        final cachedBinaryHash = _hexToBinary(cachedHexHash);
        if (cachedBinaryHash.length != 64) continue;
        
        // Calculate Hamming distance (number of bits that differ)
        final distance = _hammingDistance(binaryHash, cachedBinaryHash);
        
        debugPrint('🔧 BASIC: Comparing with $cachedHash: distance = $distance (threshold = $threshold)');
        
        // If distance is within threshold, consider it a match
        if (distance <= threshold) {
          // If it's a better match than current best, update it
          if (distance < bestDistance) {
            bestDistance = distance;
            bestMatch = cachedHash;
            
            // If exact match (distance = 0), return immediately
            if (distance == 0) break;
          }
        }
      }
      
      if (bestMatch != null) {
        debugPrint('🔧 BASIC: Found similar hash: $bestMatch with distance $bestDistance');
      } else {
        debugPrint('🔧 BASIC: No similar hashes found within threshold $threshold');
      }
      
      return bestMatch;
    } catch (e) {
      debugPrint('🔧 BASIC: Error finding similar perceptual hash: $e');
      return null;
    }
  }

  /// Get the cache box for testing purposes
  Box<String> get cacheBox => _cacheBox;
}

/// Temporary alias to maintain compatibility with older tests that referenced
/// `CacheService`. This alias maps the old name to the current
/// `ClassificationCacheService` implementation.
typedef CacheService = ClassificationCacheService;

/// Feature flags for cache service
class CacheFeatureFlags {
  static bool _contentHashVerificationEnabled = true;
  
  /// Enable/disable content hash verification (kill-switch for production)
  static bool get contentHashVerificationEnabled => _contentHashVerificationEnabled;
  
  /// Set content hash verification state (for testing or remote config)
  static void setContentHashVerification(bool enabled) {
    _contentHashVerificationEnabled = enabled;
    debugPrint('🔧 FEATURE FLAG: Content hash verification ${enabled ? 'ENABLED' : 'DISABLED'}');
  }
  
  /// Initialize feature flags from remote config (placeholder for future implementation)
  static Future<void> initialize() async {
    // TODO: Integrate with Firebase Remote Config
    // final remoteConfig = FirebaseRemoteConfig.instance;
    // await remoteConfig.fetchAndActivate();
    // _contentHashVerificationEnabled = remoteConfig.getBool('content_hash_verification_enabled');
    
    debugPrint('🔧 FEATURE FLAGS: Initialized with contentHashVerification=$_contentHashVerificationEnabled');
  }
}
