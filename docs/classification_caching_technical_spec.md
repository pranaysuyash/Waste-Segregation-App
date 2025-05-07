# Classification Caching - Technical Specification

## Overview
This document provides detailed technical specifications for implementing image classification caching in the Waste Segregation application. It serves as a comprehensive guide for developers working on the feature implementation.

## Architecture

### Components
1. **Hash Generator**: Creates consistent image fingerprints
2. **Cache Service**: Manages the storage and retrieval of cached classifications
3. **Cache Model**: Defines the data structure for cached items
4. **AI Service Integration**: Connects caching system with existing AI classification service

### File Structure
```
lib/
  ├── services/
  │   ├── ai_service.dart         (Modified to implement caching)
  │   ├── storage_service.dart    (Modified to add caching capabilities)
  │   └── cache_service.dart      (New file for dedicated cache management)
  ├── models/
  │   └── cached_classification.dart  (New model for cached items)
  └── utils/
      └── image_utils.dart        (New utilities for image processing and hashing)
```

## Detailed Component Specifications

### 1. Hash Generator (`lib/utils/image_utils.dart`)

#### Functions:

**`Future<String> generateImageHash(Uint8List imageBytes, {bool normalize = true})`**
- **Purpose**: Creates a perceptual hash (pHash) of the image data for similarity detection
- **Parameters**: 
  - `imageBytes`: Raw image data as Uint8List
  - `normalize`: Whether to normalize the image before hashing
- **Returns**: String representation of the hash with appropriate prefix
- **Dependencies**: `image` package
- **Implementation Notes**: 
  - Implements perceptual hashing algorithm for robust similarity matching
  - Reduces image to 8x8 grayscale and generates a 64-bit feature hash
  - Includes fallback to SHA-256 for error cases
  - Ensures consistent results for visually similar images

**`Future<Uint8List> preprocessImage(Uint8List imageBytes, {int targetWidth = 300, int targetHeight = 300, bool convertToGrayscale = true, bool applyStrongerBlur = false})`**
- **Purpose**: Normalizes image for consistent hashing
- **Parameters**:
  - `imageBytes`: Raw image data
  - `targetWidth`: Width to resize to
  - `targetHeight`: Height to resize to
  - `convertToGrayscale`: Whether to convert to grayscale
  - `applyStrongerBlur`: Whether to apply additional noise reduction
- **Returns**: Preprocessed image bytes
- **Dependencies**: `image` package, `compute` for isolate processing
- **Implementation Notes**:
  - Runs in separate isolate for performance
  - Resizes image to standard dimensions
  - Converts to grayscale (configurable)
  - Applies Gaussian blur to reduce noise sensitivity

**`String _generatePerceptualHash(Uint8List processedImageBytes)`**
- **Purpose**: Handles the core perceptual hashing algorithm
- **Parameters**:
  - `processedImageBytes`: Preprocessed image data
- **Returns**: String perceptual hash with "phash_" prefix
- **Implementation Notes**:
  - Reduces image to 8x8 pixels
  - Computes average pixel value
  - Generates bitstring by comparing each pixel to average
  - Converts bitstring to hexadecimal for storage efficiency

### 2. Cache Model (`lib/models/cached_classification.dart`)

#### Class: `CachedClassification`

**Properties**:
- `String imageHash` - Unique identifier (primary key)
- `WasteClassification classification` - The classification result
- `DateTime timestamp` - When the classification was cached
- `int useCount` - Number of times this cache entry was accessed

**Methods**:
- `Map<String, dynamic> toJson()` - Converts to JSON for storage
- `CachedClassification.fromJson(Map<String, dynamic> json)` - Constructor from JSON
- `factory CachedClassification.fromClassification(String hash, WasteClassification classification)` - Factory constructor

### 3. Cache Service (`lib/services/cache_service.dart`)

#### Class: `ClassificationCacheService`

**Properties**:
- `Box<String> _cacheBox` - Hive box for storing serialized cached classifications
- `int _maxCacheSize` - Maximum number of entries to store
- `Map<String, dynamic> _statistics` - Cache performance metrics
- `LinkedHashMap<String, DateTime> _lruMap` - In-memory tracking for LRU policy

**Methods**:

**`Future<void> initialize()`**
- **Purpose**: Initialize the cache service and open Hive box
- **Implementation Notes**: 
  - Opens the cache box
  - Loads existing entries into LRU map
  - Initializes statistics

**`Future<CachedClassification?> getCachedClassification(String imageHash, {int similarityThreshold = 10})`**
- **Purpose**: Retrieve cached classification by image hash, including similar image matching
- **Parameters**: 
  - `imageHash`: The hash key to look up
  - `similarityThreshold`: Maximum hamming distance allowed for similar matches (0-64)
- **Returns**: Cached classification if found, null otherwise
- **Implementation Notes**: 
  - First checks for exact match by hash
  - For perceptual hashes, also checks for similar matches using Hamming distance
  - Updates access timestamp and use count on hit
  - Tracks separate statistics for exact vs. similar matches

**`Future<String?> _findSimilarPerceptualHash(String pHash, int threshold)`**
- **Purpose**: Find similar perceptual hashes in the cache using Hamming distance
- **Parameters**:
  - `pHash`: The perceptual hash to compare against
  - `threshold`: Maximum number of bits that can differ (0-64)
- **Returns**: The hash of the closest match within threshold, or null if none found
- **Implementation Notes**:
  - Converts hex hashes to binary for bit comparisons
  - Calculates Hamming distance (bit differences)
  - Returns best match within threshold

**`Future<void> cacheClassification(String imageHash, WasteClassification classification, {int? imageSize})`**
- **Purpose**: Store a new classification in the cache
- **Parameters**: 
  - `imageHash`: Hash key for storage
  - `classification`: Classification result to cache
  - `imageSize`: Size of original image in bytes (for statistics)
- **Implementation Notes**: 
  - Handles cache eviction when max size reached
  - Implements LRU (Least Recently Used) policy
  - Updates statistics for monitoring

**`Future<void> clearCache()`**
- **Purpose**: Clear the entire cache
- **Implementation Notes**: 
  - Handles proper Hive box clearing
  - Resets metadata

**`Map<String, dynamic> getCacheStatistics()`**
- **Purpose**: Get comprehensive statistics about cache usage
- **Returns**: Map containing detailed performance metrics
- **Implementation Notes**: 
  - Tracks hits, misses, and similar hits
  - Calculates overall hit rate and similar hit percentage
  - Reports hash type distribution (perceptual vs. fallback vs. simple)
  - Tracks estimated bandwidth savings
  - Reports cache age and size information

### 4. AI Service Integration (`lib/services/ai_service.dart`)

#### Modified Methods:

**`Future<WasteClassification> classifyImage(Uint8List imageBytes)`**
- **Original Purpose**: Send image to API for classification
- **Modified Behavior**: 
  - First generates image hash
  - Checks cache for existing classification
  - Returns cached result if found
  - Otherwise calls API and caches result
- **Parameters**: 
  - `imageBytes`: The image to classify
- **Returns**: Classification result
- **Dependencies**: 
  - `ClassificationCacheService`
  - `ImageUtils` for hash generation
  - Original API client
- **Implementation Notes**:
  - Handles cache service exceptions gracefully
  - Falls back to API call on cache error
  - Updates cache with new results

### 5. Storage Service Modifications (`lib/services/storage_service.dart`)

#### Added Methods:

**`Future<Box<CachedClassification>> openClassificationCacheBox()`**
- **Purpose**: Open and configure Hive box for classification cache
- **Returns**: Configured Hive box
- **Implementation Notes**: 
  - Ensures proper box configuration
  - Sets up any needed indices

## Interfaces and Dependencies

### External Dependencies
- `crypto`: ^3.0.3 (for SHA-256 hashing)
- `hive`: ^2.2.3 (for local cache storage)
- `hive_flutter`: ^1.1.0 (for Flutter integration)
- `image`: ^4.0.17 (for image preprocessing)

### Internal Dependencies
- `models/waste_classification.dart` - For classification data structure
- `services/storage_service.dart` - For Hive box management

## Implementation Workflow

### Phase 1: Foundation
1. Add necessary dependencies to `pubspec.yaml`
2. Create `image_utils.dart` with hashing functions
3. Create `cached_classification.dart` model
4. Add Hive type adapter for the model

### Phase 2: Core Services
1. Create `cache_service.dart` with basic functionality
2. Modify `storage_service.dart` to handle cache box
3. Add initialization to app startup

### Phase 3: Integration
1. Modify `ai_service.dart` to use cache
2. Add error handling and fallback mechanisms
3. Implement cache statistics tracking

### Phase 4: Optimization
1. Add cache size management
2. Implement LRU eviction policy
3. Add cache invalidation for outdated entries

## Testing Strategy

### Unit Tests
- Test hash generation consistency
- Test cache hit/miss scenarios
- Test serialization/deserialization
- Test LRU eviction policy

### Integration Tests
- Test end-to-end flow with mock API
- Test cache persistence across app restarts
- Test error handling and recovery

### Performance Tests
- Measure classification time with/without cache
- Benchmark cache lookup performance
- Test with various cache sizes

## Usage Examples

### Basic Usage in Screens

```dart
// In image_capture_screen.dart or result_screen.dart
final aiService = getIt<AIService>();

// Use existing code - caching is handled internally
final classification = await aiService.classifyImage(imageBytes);
```

### Advanced Usage with Cache Statistics

```dart
final cacheService = getIt<ClassificationCacheService>();
final cacheStats = await cacheService.getCacheStatistics();

print('Cache hit rate: ${cacheStats['hitRate']}%');
print('Cache size: ${cacheStats['size']} entries');
```

## Error Handling and Edge Cases

### Error Scenarios
1. **Cache corruption**: Fall back to API calls, log error, attempt recovery
2. **Hashing errors**: Use alternative hashing method or bypass cache
3. **Storage limitations**: Implement more aggressive cache eviction
4. **API format changes**: Version cache entries, invalidate on format change

### Edge Cases
1. **Very similar but different images**: The perceptual hashing system is designed to detect similarity, with configurable threshold for controlling strictness
2. **API response structure changes**: Version cache entries, invalidate on format change
3. **Device storage full**: Handle gracefully with user notification and reduced cache size
4. **Hash calculation errors**: Robust fallback mechanisms ensure graceful degradation
5. **Similar hash false positives**: Configurable similarity threshold allows fine-tuning to balance hit rate vs. accuracy
6. **Perceptual hash quality**: For items where perceptual hashing isn't ideal (like transparent items), fallback algorithms are available