# Claude Notes for Waste Segregation App

This document contains notes and recommendations for working with this project using Claude.

## Key Features Implemented

- **Device-Local Classification Caching**: Implemented a local hashing-based cache system to reduce redundant API calls, improve responsiveness, and ensure consistent classifications (even without internet)
- **Cache Statistics**: Added monitoring for cache performance with hit rate and data savings tracking
- **Modular Implementation**: Clean separation of concerns with dedicated utilities, models, and services

## Implementation Details

The classification caching system consists of:

1. **`image_utils.dart`**: Handles image hashing and preprocessing
2. **`cached_classification.dart`**: Model for cache entries
3. **`cache_service.dart`**: Core caching logic with LRU eviction
4. **`ai_service.dart`**: Integration with main classification flow

## Recent Improvements

- **Enhanced Similarity Matching**: Increased default Hamming distance threshold from 8 to 10 bits for better matching of similar images
- **Improved Image Preprocessing**: Enhanced Gaussian blur radius from 2 to 3 for more robust perceptual hashing
- **Detailed Logging**: Added comprehensive logging of hash comparisons for debugging
- **Fixed AchievementType Handling**: Added missing enum cases in achievements screen for better compatibility

## Future Enhancement Opportunities

- **Cross-Device Sync**: Extend to Firestore for sharing cache across user's devices
- **Cross-User Community Cache**: Enable cached classifications to benefit all users
- **Further Image Matching Refinement**: Consider different perceptual hashing algorithms like dHash
- **Selective Caching**: Cache only high-confidence classifications

## Common Commands

Run tests for the caching system:
```bash
flutter test test/services/cache_service_test.dart
```

Build generated files:
```bash
flutter pub run build_runner build
```

## Documentation

Detailed documentation is available in the `docs/` folder:

- `classification_caching_options.md`: Analysis of implementation approaches
- `classification_caching_technical_spec.md`: Technical specifications
- `classification_caching_implementation.md`: Implementation details

## Best Practices for This Project

1. Always run tests after modifying the caching system
2. Initialize the cache service early in app startup
3. Keep cache statistics UI components optional/behind developer settings
4. Consider adding cache hit/miss logging for analytics

## Performance Notes

The local caching system significantly improves performance:
- First classification: Normal API latency
- Subsequent identical classifications: Near-instant (< 10ms)
- Memory usage: Minimal (JSON serialization of classification results)
- Storage usage: Efficient (only metadata and classification results, not images)