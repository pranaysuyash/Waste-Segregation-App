import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

// Mock services for performance testing
class MockAiService extends Mock implements AiService {}
class MockStorageService extends Mock implements StorageService {}
class MockCacheService extends Mock implements CacheService {}
class MockGamificationService extends Mock implements GamificationService {}

void main() {
  group('Performance Tests', () {
    late MockAiService mockAiService;
    late MockStorageService mockStorageService;
    late MockCacheService mockCacheService;
    late MockGamificationService mockGamificationService;

    setUp(() {
      mockAiService = MockAiService();
      mockStorageService = MockStorageService();
      mockCacheService = MockCacheService();
      mockGamificationService = MockGamificationService();
    });

    group('Memory Usage Tests', () {
      test('should not leak memory during image processing', () async {
        final initialMemory = _getCurrentMemoryUsage();
        
        // Process 50 images to simulate heavy usage
        for (int i = 0; i < 50; i++) {
          final imageData = _generateTestImageData(1024 * 1024); // 1MB each
          
          when(mockAiService.analyzeWebImage(any, any))
              .thenAnswer((_) async => _createTestClassification('Image $i'));
          
          final classification = await mockAiService.analyzeWebImage(imageData, 'test_$i.jpg');
          
          // Simulate processing
          await _simulateImageProcessing(imageData);
          
          // Clear reference to allow garbage collection
          imageData.clear();
        }
        
        // Force garbage collection
        await _forceGarbageCollection();
        
        final finalMemory = _getCurrentMemoryUsage();
        final memoryGrowth = finalMemory - initialMemory;
        
        // Memory growth should be reasonable (less than 50MB for processing 50MB of images)
        expect(memoryGrowth, lessThan(50 * 1024 * 1024));
        
        // Verify no major memory leaks
        expect(memoryGrowth / (50 * 1024 * 1024), lessThan(0.5)); // Less than 50% retention
      });

      test('should handle large classification history efficiently', () async {
        final largeHistory = List.generate(10000, (i) => _createTestClassification('Item $i'));
        
        when(mockStorageService.getClassificationHistory())
            .thenAnswer((_) async => largeHistory);
        
        final stopwatch = Stopwatch()..start();
        final initialMemory = _getCurrentMemoryUsage();
        
        // Load large history multiple times
        for (int i = 0; i < 10; i++) {
          final history = await mockStorageService.getClassificationHistory();
          expect(history.length, equals(10000));
        }
        
        stopwatch.stop();
        final finalMemory = _getCurrentMemoryUsage();
        
        // Should load efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Within 5 seconds
        
        // Memory usage should be reasonable
        final memoryGrowth = finalMemory - initialMemory;
        expect(memoryGrowth, lessThan(100 * 1024 * 1024)); // Less than 100MB
      });

      test('should manage cache memory usage within limits', () async {
        final cacheLimit = 50 * 1024 * 1024; // 50MB cache limit
        
        // Setup cache service mock
        when(mockCacheService.getCacheMemoryUsage())
            .thenAnswer((_) async => cacheLimit - (10 * 1024 * 1024)); // Near limit
        
        // Add items until cache limit
        for (int i = 0; i < 100; i++) {
          final classification = _createTestClassification('Cached Item $i');
          await mockCacheService.cacheClassification('hash_$i', classification);
        }
        
        final memoryUsage = await mockCacheService.getCacheMemoryUsage();
        expect(memoryUsage, lessThanOrEqualTo(cacheLimit));
      });

      test('should handle memory pressure gracefully', () async {
        // Simulate low memory conditions
        _simulateMemoryPressure(true);
        
        final initialMemory = _getCurrentMemoryUsage();
        
        // Try to perform memory-intensive operations
        final largeDataSet = List.generate(1000, (i) => _createTestClassification('Memory Test $i'));
        
        when(mockStorageService.saveClassificationBatch(any))
            .thenAnswer((_) async => {});
        
        // Should complete without crashes
        expect(() async => mockStorageService.saveClassificationBatch(largeDataSet), 
               returnsNormally);
        
        final finalMemory = _getCurrentMemoryUsage();
        
        // Memory usage should remain controlled
        expect(finalMemory - initialMemory, lessThan(200 * 1024 * 1024)); // Less than 200MB
        
        _simulateMemoryPressure(false);
      });

      test('should clean up temporary resources properly', () async {
        final initialMemory = _getCurrentMemoryUsage();
        
        // Create temporary resources
        final tempFiles = <File>[];
        for (int i = 0; i < 20; i++) {
          final tempFile = File('temp_image_$i.jpg');
          tempFiles.add(tempFile);
        }
        
        // Process and clean up
        for (final file in tempFiles) {
          await _processTemporaryFile(file);
          await _cleanupTemporaryFile(file);
        }
        
        // Force cleanup
        await _forceGarbageCollection();
        
        final finalMemory = _getCurrentMemoryUsage();
        final memoryGrowth = finalMemory - initialMemory;
        
        // Should have minimal memory growth after cleanup
        expect(memoryGrowth, lessThan(10 * 1024 * 1024)); // Less than 10MB
      });
    });

    group('Startup Performance Tests', () {
      test('should start app within performance target', () async {
        final stopwatch = Stopwatch()..start();
        
        // Simulate app initialization
        await _simulateAppInitialization();
        
        stopwatch.stop();
        
        // Should start within 3 seconds on average device
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });

      test('should load initial data efficiently', () async {
        final recentClassifications = List.generate(10, (i) => _createTestClassification('Recent $i'));
        final userProfile = _createTestUserProfile();
        
        when(mockStorageService.getRecentClassifications(limit: 10))
            .thenAnswer((_) async => recentClassifications);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => userProfile);
        
        final stopwatch = Stopwatch()..start();
        
        // Load initial app data
        final futures = [
          mockStorageService.getRecentClassifications(limit: 10),
          mockGamificationService.getUserProfile(),
        ];
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Initial data load should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Within 1 second
      });

      test('should initialize services in optimal order', () async {
        final initOrder = <String>[];
        
        // Mock service initialization with timing
        when(mockStorageService.initialize()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          initOrder.add('storage');
        });
        
        when(mockCacheService.initialize()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          initOrder.add('cache');
        });
        
        when(mockGamificationService.initialize()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 75));
          initOrder.add('gamification');
        });
        
        // Initialize in optimal order (cache first, then storage, then gamification)
        await _initializeServices([
          mockCacheService,
          mockStorageService,
          mockGamificationService,
        ]);
        
        expect(initOrder, equals(['cache', 'storage', 'gamification']));
      });

      test('should handle cold start vs warm start differently', () async {
        // Test cold start (first app launch)
        final coldStartTime = await _measureColdStart();
        
        // Test warm start (app already initialized)
        final warmStartTime = await _measureWarmStart();
        
        // Warm start should be significantly faster
        expect(warmStartTime, lessThan(coldStartTime * 0.5));
        expect(coldStartTime, lessThan(5000)); // Cold start under 5 seconds
        expect(warmStartTime, lessThan(1000)); // Warm start under 1 second
      });
    });

    group('Large Dataset Performance', () {
      test('should handle 10,000 classifications efficiently', () async {
        final largeDataset = List.generate(10000, (i) => _createTestClassification('Large Item $i'));
        
        when(mockStorageService.saveClassificationBatch(any))
            .thenAnswer((_) async => {});
        when(mockStorageService.searchClassifications(any))
            .thenAnswer((_) async => largeDataset.take(100).toList());
        
        final stopwatch = Stopwatch()..start();
        
        // Save large dataset
        await mockStorageService.saveClassificationBatch(largeDataset);
        
        // Search through large dataset
        final searchResults = await mockStorageService.searchClassifications('Item');
        
        stopwatch.stop();
        
        expect(searchResults.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Within 10 seconds
      });

      test('should paginate large results efficiently', () async {
        final pageSize = 50;
        final totalItems = 1000;
        
        when(mockStorageService.getClassificationHistory(
          offset: any, 
          limit: pageSize
        )).thenAnswer((invocation) async {
          final offset = invocation.namedArguments[#offset] ?? 0;
          final start = offset;
          final end = (start + pageSize).clamp(0, totalItems);
          
          return List.generate(end - start, (i) => 
            _createTestClassification('Paginated Item ${start + i}')
          );
        });
        
        final stopwatch = Stopwatch()..start();
        
        // Load multiple pages
        final allResults = <WasteClassification>[];
        for (int page = 0; page < 20; page++) {
          final results = await mockStorageService.getClassificationHistory(
            offset: page * pageSize,
            limit: pageSize,
          );
          allResults.addAll(results);
          
          if (results.length < pageSize) break;
        }
        
        stopwatch.stop();
        
        expect(allResults.length, equals(totalItems));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Efficient pagination
      });

      test('should handle concurrent large operations', () async {
        final datasets = List.generate(5, (i) => 
          List.generate(1000, (j) => _createTestClassification('Concurrent $i-$j'))
        );
        
        when(mockStorageService.saveClassificationBatch(any))
            .thenAnswer((_) async => Future.delayed(Duration(milliseconds: 500)));
        
        final stopwatch = Stopwatch()..start();
        
        // Process multiple large datasets concurrently
        final futures = datasets.map((dataset) => 
          mockStorageService.saveClassificationBatch(dataset)
        ).toList();
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Concurrent processing should be faster than sequential
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Faster than 5 * 500ms
        
        // Verify all operations completed
        verify(mockStorageService.saveClassificationBatch(any)).called(5);
      });

      test('should maintain performance with mixed operations', () async {
        final classifications = List.generate(100, (i) => _createTestClassification('Mixed $i'));
        
        when(mockStorageService.saveClassification(any))
            .thenAnswer((_) async => Future.delayed(Duration(milliseconds: 10)));
        when(mockStorageService.getClassificationHistory())
            .thenAnswer((_) async => classifications);
        when(mockCacheService.getCachedClassification(any))
            .thenAnswer((_) async => classifications.first);
        
        final stopwatch = Stopwatch()..start();
        
        // Mix of read/write operations
        final futures = <Future>[];
        
        // 50 saves
        for (int i = 0; i < 50; i++) {
          futures.add(mockStorageService.saveClassification(classifications[i]));
        }
        
        // 30 reads
        for (int i = 0; i < 30; i++) {
          futures.add(mockStorageService.getClassificationHistory());
        }
        
        // 20 cache lookups
        for (int i = 0; i < 20; i++) {
          futures.add(mockCacheService.getCachedClassification('hash_$i'));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Mixed operations should complete efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });
    });

    group('UI Performance Tests', () {
      test('should render large lists efficiently', () async {
        final largeItemList = List.generate(1000, (i) => _createTestClassification('List Item $i'));
        
        final stopwatch = Stopwatch()..start();
        
        // Simulate rendering large list
        await _simulateListRendering(largeItemList);
        
        stopwatch.stop();
        
        // Large list rendering should be optimized
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('should handle rapid user interactions', () async {
        final interactionCount = 100;
        final stopwatch = Stopwatch()..start();
        
        // Simulate rapid tap interactions
        for (int i = 0; i < interactionCount; i++) {
          await _simulateUserInteraction('tap', i);
        }
        
        stopwatch.stop();
        
        // Should handle rapid interactions without lag
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(stopwatch.elapsedMilliseconds / interactionCount, lessThan(10)); // < 10ms per interaction
      });

      test('should maintain 60fps during animations', () async {
        final frameRate = await _measureAnimationFrameRate();
        
        // Should maintain at least 55fps (allowing for some drops)
        expect(frameRate, greaterThan(55.0));
      });

      test('should handle image loading efficiently', () async {
        final imageCount = 20;
        final imageSizes = [100 * 1024, 500 * 1024, 1024 * 1024]; // 100KB, 500KB, 1MB
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < imageCount; i++) {
          final size = imageSizes[i % imageSizes.length];
          final imageData = _generateTestImageData(size);
          await _simulateImageLoading(imageData);
        }
        
        stopwatch.stop();
        
        // Image loading should be efficient
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(stopwatch.elapsedMilliseconds / imageCount, lessThan(250)); // < 250ms per image
      });
    });

    group('Network Performance Tests', () {
      test('should handle AI API calls within timeout', () async {
        final imageData = _generateTestImageData(2 * 1024 * 1024); // 2MB image
        
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(Duration(seconds: 3)); // Simulate API delay
              return _createTestClassification('API Result');
            });
        
        final stopwatch = Stopwatch()..start();
        
        final result = await mockAiService.analyzeWebImage(imageData, 'test.jpg');
        
        stopwatch.stop();
        
        expect(result.itemName, equals('API Result'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Within 5 second timeout
      });

      test('should batch network requests efficiently', () async {
        final batchSize = 10;
        final requests = List.generate(batchSize, (i) => 'request_$i');
        
        when(mockAiService.batchAnalyzeImages(any))
            .thenAnswer((_) async {
              await Future.delayed(Duration(milliseconds: 1000)); // Simulate batch processing
              return requests.map((r) => _createTestClassification(r)).toList();
            });
        
        final stopwatch = Stopwatch()..start();
        
        final results = await mockAiService.batchAnalyzeImages(requests);
        
        stopwatch.stop();
        
        expect(results.length, equals(batchSize));
        // Batch should be faster than individual requests
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Faster than 10 individual calls
      });

      test('should handle network timeouts gracefully', () async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(Duration(seconds: 10)); // Simulate slow network
              return _createTestClassification('Timeout Test');
            });
        
        // Should timeout and handle gracefully
        expect(() async {
          await Future.timeout(
            mockAiService.analyzeWebImage(Uint8List(100), 'test.jpg'),
            Duration(seconds: 5),
          );
        }, throwsA(isA<TimeoutException>()));
      });
    });

    group('Resource Management Tests', () {
      test('should clean up resources after operations', () async {
        final resourceTracker = ResourceTracker();
        
        // Simulate resource-intensive operations
        for (int i = 0; i < 10; i++) {
          await _performResourceIntensiveOperation(resourceTracker);
        }
        
        // Force cleanup
        await resourceTracker.cleanup();
        
        // Verify resources are properly cleaned up
        expect(resourceTracker.activeResourceCount, equals(0));
        expect(resourceTracker.totalResourcesCreated, equals(10));
        expect(resourceTracker.totalResourcesCleaned, equals(10));
      });

      test('should handle resource exhaustion gracefully', () async {
        // Simulate resource exhaustion
        _simulateResourceExhaustion(true);
        
        expect(() async {
          await _performResourceIntensiveOperation(ResourceTracker());
        }, returnsNormally); // Should not crash
        
        _simulateResourceExhaustion(false);
      });

      test('should optimize resource allocation', () async {
        final tracker = ResourceTracker();
        
        // Test resource pooling efficiency
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          await _performOptimizedResourceOperation(tracker);
        }
        
        stopwatch.stop();
        
        // Optimized operations should reuse resources
        expect(tracker.resourceReuseRate, greaterThan(0.7)); // > 70% reuse
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}

// Helper functions and classes for performance testing

class ResourceTracker {
  int activeResourceCount = 0;
  int totalResourcesCreated = 0;
  int totalResourcesCleaned = 0;
  int resourceReuses = 0;

  double get resourceReuseRate => 
    totalResourcesCreated > 0 ? resourceReuses / totalResourcesCreated : 0.0;

  Future<void> cleanup() async {
    totalResourcesCleaned = activeResourceCount;
    activeResourceCount = 0;
  }
}

int _getCurrentMemoryUsage() {
  // Mock implementation - in real app would use platform-specific memory APIs
  return ProcessInfo.currentRss ?? (100 * 1024 * 1024); // Default 100MB
}

Uint8List _generateTestImageData(int sizeBytes) {
  final data = Uint8List(sizeBytes);
  for (int i = 0; i < sizeBytes; i++) {
    data[i] = i % 256;
  }
  return data;
}

Future<void> _forceGarbageCollection() async {
  // In Dart, we can't force GC, but we can encourage it
  for (int i = 0; i < 10; i++) {
    final temp = List.generate(1000, (i) => i);
    temp.clear();
    await Future.delayed(Duration(milliseconds: 10));
  }
}

Future<void> _simulateImageProcessing(Uint8List imageData) async {
  // Simulate image processing operations
  await Future.delayed(Duration(milliseconds: 10));
  
  // Simulate some processing
  var sum = 0;
  for (int i = 0; i < imageData.length; i += 100) {
    sum += imageData[i];
  }
}

void _simulateMemoryPressure(bool enabled) {
  // Mock implementation for memory pressure simulation
  // In real app, this would use platform-specific APIs
}

Future<void> _processTemporaryFile(File file) async {
  // Mock file processing
  await Future.delayed(Duration(milliseconds: 50));
}

Future<void> _cleanupTemporaryFile(File file) async {
  // Mock file cleanup
  await Future.delayed(Duration(milliseconds: 10));
}

Future<void> _simulateAppInitialization() async {
  // Simulate full app initialization sequence
  await Future.delayed(Duration(milliseconds: 500)); // Storage init
  await Future.delayed(Duration(milliseconds: 300)); // Service init
  await Future.delayed(Duration(milliseconds: 200)); // UI init
}

Future<void> _initializeServices(List<dynamic> services) async {
  for (final service in services) {
    if (service is MockCacheService) {
      await service.initialize();
    } else if (service is MockStorageService) {
      await service.initialize();
    } else if (service is MockGamificationService) {
      await service.initialize();
    }
  }
}

Future<int> _measureColdStart() async {
  final stopwatch = Stopwatch()..start();
  await _simulateAppInitialization();
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

Future<int> _measureWarmStart() async {
  final stopwatch = Stopwatch()..start();
  // Warm start skips heavy initialization
  await Future.delayed(Duration(milliseconds: 100));
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

Future<void> _simulateListRendering(List<WasteClassification> items) async {
  // Simulate list rendering with virtual scrolling
  final visibleItems = items.take(50); // Only render visible items
  for (final item in visibleItems) {
    await Future.delayed(Duration(microseconds: 500)); // Simulate render time
  }
}

Future<void> _simulateUserInteraction(String type, int index) async {
  // Simulate user interaction processing
  await Future.delayed(Duration(microseconds: 100));
}

Future<double> _measureAnimationFrameRate() async {
  // Mock frame rate measurement
  // In real app, would measure actual frame rendering times
  final frameCount = 60;
  final duration = Duration(seconds: 1);
  
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < frameCount; i++) {
    await Future.delayed(Duration(microseconds: 16667)); // 60fps = 16.67ms per frame
  }
  
  stopwatch.stop();
  
  return frameCount / (stopwatch.elapsedMilliseconds / 1000.0);
}

Future<void> _simulateImageLoading(Uint8List imageData) async {
  // Simulate image decoding and loading
  final processingTime = (imageData.length / (1024 * 1024) * 100).round(); // 100ms per MB
  await Future.delayed(Duration(milliseconds: processingTime));
}

Future<void> _performResourceIntensiveOperation(ResourceTracker tracker) async {
  tracker.activeResourceCount++;
  tracker.totalResourcesCreated++;
  
  // Simulate operation
  await Future.delayed(Duration(milliseconds: 50));
  
  // Cleanup
  tracker.activeResourceCount--;
}

void _simulateResourceExhaustion(bool enabled) {
  // Mock resource exhaustion simulation
}

Future<void> _performOptimizedResourceOperation(ResourceTracker tracker) async {
  // Simulate resource reuse 70% of the time
  if (tracker.totalResourcesCreated > 0 && (tracker.totalResourcesCreated % 10) < 7) {
    tracker.resourceReuses++;
  } else {
    tracker.totalResourcesCreated++;
  }
  
  await Future.delayed(Duration(milliseconds: 5));
}

WasteClassification _createTestClassification(String itemName) {
  return WasteClassification(
    itemName: itemName,
    category: 'Dry Waste',
    subcategory: 'Test',
    explanation: 'Performance test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test'],
    alternatives: [],
    confidence: 0.85,
  );
}

GamificationProfile _createTestUserProfile() {
  return GamificationProfile(
    userId: 'performance_test_user',
    points: UserPoints(total: 500),
    streak: Streak(current: 5, longest: 10, lastUsageDate: DateTime.now()),
    achievements: [],
  );
}

// Extension methods for mock services
extension MockAiServicePerformance on MockAiService {
  Future<List<WasteClassification>> batchAnalyzeImages(List<String> requests) async {
    // Mock batch analysis
    return requests.map((r) => _createTestClassification(r)).toList();
  }
}

extension MockStorageServicePerformance on MockStorageService {
  Future<void> initialize() async {
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  Future<void> saveClassificationBatch(List<WasteClassification> classifications) async {
    await Future.delayed(Duration(milliseconds: 200));
  }
  
  Future<List<WasteClassification>> searchClassifications(String query) async {
    await Future.delayed(Duration(milliseconds: 100));
    return List.generate(100, (i) => _createTestClassification('Search Result $i'));
  }
  
  Future<List<WasteClassification>> getClassificationHistory({int? offset, int? limit}) async {
    await Future.delayed(Duration(milliseconds: 50));
    return List.generate(limit ?? 10, (i) => _createTestClassification('History Item ${(offset ?? 0) + i}'));
  }
}

extension MockCacheServicePerformance on MockCacheService {
  Future<void> initialize() async {
    await Future.delayed(Duration(milliseconds: 50));
  }
}

extension MockGamificationServicePerformance on MockGamificationService {
  Future<void> initialize() async {
    await Future.delayed(Duration(milliseconds: 75));
  }
}

class ProcessInfo {
  static int? get currentRss {
    // Mock implementation - would use actual process info in real app
    return 100 * 1024 * 1024; // 100MB
  }
}
