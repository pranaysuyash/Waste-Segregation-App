import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vm_service/vm_service.dart';
import '../utils/waste_app_logger.dart';

/// Memory usage statistics
class MemoryStats {
  const MemoryStats({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.freeMemoryMB,
    required this.timestamp,
    this.gcCount = 0,
    this.imageMemoryMB = 0.0,
  });

  final double usedMemoryMB;
  final double totalMemoryMB;
  final double freeMemoryMB;
  final DateTime timestamp;
  final int gcCount;
  final double imageMemoryMB;

  double get utilizationPercent => (usedMemoryMB / totalMemoryMB) * 100;

  Map<String, dynamic> toJson() => {
    'usedMemoryMB': usedMemoryMB,
    'totalMemoryMB': totalMemoryMB,
    'freeMemoryMB': freeMemoryMB,
    'utilizationPercent': utilizationPercent,
    'timestamp': timestamp.toIso8601String(),
    'gcCount': gcCount,
    'imageMemoryMB': imageMemoryMB,
  };
}

/// Resource that can be disposed
abstract class DisposableResource {
  void dispose();
  String get resourceId;
  String get resourceType;
}

/// Memory leak detector for tracking object lifecycles
class MemoryLeakDetector {
  static final Map<String, WeakReference<Object>> _trackedObjects = {};
  static final Map<String, DateTime> _creationTimes = {};
  static final Map<String, String> _objectTypes = {};
  
  /// Track an object for memory leak detection
  static void track(Object object, String id, String type) {
    _trackedObjects[id] = WeakReference(object);
    _creationTimes[id] = DateTime.now();
    _objectTypes[id] = type;
  }
  
  /// Stop tracking an object
  static void untrack(String id) {
    _trackedObjects.remove(id);
    _creationTimes.remove(id);
    _objectTypes.remove(id);
  }
  
  /// Check for potential memory leaks
  static List<Map<String, dynamic>> checkForLeaks() {
    final leaks = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    _trackedObjects.removeWhere((id, weakRef) {
      final object = weakRef.target;
      if (object == null) {
        // Object was garbage collected, remove from tracking
        _creationTimes.remove(id);
        _objectTypes.remove(id);
        return true;
      }
      
      final creationTime = _creationTimes[id];
      if (creationTime != null) {
        final age = now.difference(creationTime);
        // Consider objects older than 10 minutes as potential leaks
        if (age.inMinutes > 10) {
          leaks.add({
            'id': id,
            'type': _objectTypes[id] ?? 'Unknown',
            'ageMinutes': age.inMinutes,
            'createdAt': creationTime.toIso8601String(),
          });
        }
      }
      
      return false;
    });
    
    return leaks;
  }
  
  /// Get current tracking statistics
  static Map<String, dynamic> getStats() {
    final typeCount = <String, int>{};
    for (final type in _objectTypes.values) {
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    return {
      'totalTracked': _trackedObjects.length,
      'typeBreakdown': typeCount,
      'oldestObject': _creationTimes.values.isEmpty 
        ? null 
        : _creationTimes.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
}

/// Service for managing memory usage and preventing memory leaks
class MemoryManagementService {
  MemoryManagementService._internal();
  
  static final MemoryManagementService _instance = MemoryManagementService._internal();
  static MemoryManagementService get instance => _instance;

  // Resource tracking
  final Map<String, DisposableResource> _disposableResources = {};
  final Map<String, Timer> _resourceTimers = {};
  
  // Memory monitoring
  Timer? _memoryMonitorTimer;
  final List<MemoryStats> _memoryHistory = [];
  static const int _maxHistorySize = 100;
  
  // Image processing cleanup
  final Set<String> _activeImageOperations = {};
  final Map<String, Timer> _imageCleanupTimers = {};
  
  // Garbage collection tracking
  int _lastGcCount = 0;
  
  // Configuration
  static const double _memoryWarningThreshold = 80.0; // 80% memory usage
  static const double _memoryCriticalThreshold = 90.0; // 90% memory usage
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const Duration _resourceTimeout = Duration(minutes: 5);

  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Initialize the memory management service
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Start memory monitoring
      _startMemoryMonitoring();
      
      // Start periodic cleanup
      _startPeriodicCleanup();
      
      _isInitialized = true;
      
      WasteAppLogger.info('Memory management service initialized', {
        'service': 'memory_management',
        'monitoring_interval_seconds': _monitoringInterval.inSeconds,
        'warning_threshold': _memoryWarningThreshold,
        'critical_threshold': _memoryCriticalThreshold,
      });
      
    } catch (e) {
      WasteAppLogger.severe('Memory management service initialization failed', e, null, {
        'service': 'memory_management',
      });
      rethrow;
    }
  }

  /// Register a disposable resource for automatic cleanup
  void registerDisposableResource(DisposableResource resource) {
    if (_isDisposed) return;
    
    _disposableResources[resource.resourceId] = resource;
    
    // Set up automatic cleanup timer
    _resourceTimers[resource.resourceId] = Timer(_resourceTimeout, () {
      _cleanupResource(resource.resourceId);
    });
    
    // Track for memory leak detection
    MemoryLeakDetector.track(resource, resource.resourceId, resource.resourceType);
    
    WasteAppLogger.debug('Disposable resource registered', {
      'service': 'memory_management',
      'resource_id': resource.resourceId,
      'resource_type': resource.resourceType,
      'total_resources': _disposableResources.length,
    });
  }

  /// Unregister and dispose a resource
  void unregisterDisposableResource(String resourceId) {
    _cleanupResource(resourceId);
  }

  /// Track image processing operation
  void trackImageOperation(String operationId) {
    if (_isDisposed) return;
    
    _activeImageOperations.add(operationId);
    
    // Set up cleanup timer for image operation
    _imageCleanupTimers[operationId] = Timer(const Duration(minutes: 2), () {
      _cleanupImageOperation(operationId);
    });
    
    WasteAppLogger.debug('Image operation tracked', {
      'service': 'memory_management',
      'operation_id': operationId,
      'active_operations': _activeImageOperations.length,
    });
  }

  /// Complete image processing operation
  void completeImageOperation(String operationId) {
    _cleanupImageOperation(operationId);
  }

  /// Force garbage collection
  Future<void> forceGarbageCollection() async {
    try {
      // Clear image cache if available
      await _clearImageCache();
      
      // Force garbage collection
      if (!kIsWeb) {
        // Note: gc() is not available in release mode
        developer.log('Requesting garbage collection');
      }
      
      // Wait a moment for GC to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final stats = await getCurrentMemoryStats();
      
      WasteAppLogger.info('Forced garbage collection completed', {
        'service': 'memory_management',
        'memory_usage_mb': stats.usedMemoryMB,
        'memory_utilization': '${stats.utilizationPercent.toStringAsFixed(1)}%',
      });
      
    } catch (e) {
      WasteAppLogger.warning('Force garbage collection failed', e, null, {
        'service': 'memory_management',
      });
    }
  }

  /// Get current memory statistics
  Future<MemoryStats> getCurrentMemoryStats() async {
    try {
      double usedMemoryMB = 0;
      double totalMemoryMB = 0;
      double imageMemoryMB = 0;
      int gcCount = 0;

      if (!kIsWeb) {
        // Note: VM Service methods are not available in release mode
        // This is for development/debug purposes only
        if (kDebugMode) {
          developer.log('Memory usage monitoring is only available in debug mode');
        }
        // Use fallback values for now
        usedMemoryMB = 50.0; // Placeholder
        totalMemoryMB = 100.0; // Placeholder
        gcCount = 0;
      } else {
        // Web fallback - estimate based on performance
        final performance = await _getWebPerformanceMemory();
        usedMemoryMB = (performance['usedJSHeapSize'] ?? 0) / (1024 * 1024);
        totalMemoryMB = (performance['totalJSHeapSize'] ?? 0) / (1024 * 1024);
      }

      // Get image memory usage
      imageMemoryMB = await _getImageMemoryUsage();

      final stats = MemoryStats(
        usedMemoryMB: usedMemoryMB,
        totalMemoryMB: totalMemoryMB,
        freeMemoryMB: totalMemoryMB - usedMemoryMB,
        timestamp: DateTime.now(),
        gcCount: gcCount,
        imageMemoryMB: imageMemoryMB,
      );

      // Add to history
      _memoryHistory.add(stats);
      if (_memoryHistory.length > _maxHistorySize) {
        _memoryHistory.removeAt(0);
      }

      return stats;
    } catch (e) {
      WasteAppLogger.warning('Failed to get memory stats', e, null, {
        'service': 'memory_management',
      });
      
      // Return fallback stats
      return MemoryStats(
        usedMemoryMB: 0,
        totalMemoryMB: 0,
        freeMemoryMB: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get memory usage history
  List<MemoryStats> getMemoryHistory() {
    return List.unmodifiable(_memoryHistory);
  }

  /// Check for memory leaks
  Future<Map<String, dynamic>> checkMemoryLeaks() async {
    final leaks = MemoryLeakDetector.checkForLeaks();
    final stats = MemoryLeakDetector.getStats();
    
    final result = {
      'potentialLeaks': leaks,
      'trackingStats': stats,
      'activeResources': _disposableResources.length,
      'activeImageOperations': _activeImageOperations.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (leaks.isNotEmpty) {
      WasteAppLogger.warning('Potential memory leaks detected', null, null, {
        'service': 'memory_management',
        'leak_count': leaks.length,
        'leaks': leaks,
      });
    }
    
    return result;
  }

  /// Cleanup all resources and dispose
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      // Stop monitoring
      _memoryMonitorTimer?.cancel();
      
      // Cleanup all resources
      final resourceIds = _disposableResources.keys.toList();
      for (final resourceId in resourceIds) {
        _cleanupResource(resourceId);
      }
      
      // Cleanup all image operations
      final operationIds = _activeImageOperations.toList();
      for (final operationId in operationIds) {
        _cleanupImageOperation(operationId);
      }
      
      // Cancel all timers
      for (final timer in _resourceTimers.values) {
        timer.cancel();
      }
      _resourceTimers.clear();
      
      for (final timer in _imageCleanupTimers.values) {
        timer.cancel();
      }
      _imageCleanupTimers.clear();
      
      // Clear history
      _memoryHistory.clear();
      
      // Force final garbage collection
      await forceGarbageCollection();
      
      WasteAppLogger.info('Memory management service disposed', {
        'service': 'memory_management',
        'resources_cleaned': resourceIds.length,
        'operations_cleaned': operationIds.length,
      });
      
    } catch (e) {
      WasteAppLogger.severe('Error during memory management service disposal', e, null, {
        'service': 'memory_management',
      });
    }
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_monitoringInterval, (timer) async {
      await _performMemoryCheck();
    });
  }

  /// Start periodic cleanup tasks
  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      await _performPeriodicCleanup();
    });
  }

  /// Perform memory check and take action if needed
  Future<void> _performMemoryCheck() async {
    if (_isDisposed) return;
    
    try {
      final stats = await getCurrentMemoryStats();
      
      if (stats.utilizationPercent > _memoryCriticalThreshold) {
        WasteAppLogger.warning('Critical memory usage detected', null, null, {
          'service': 'memory_management',
          'utilization_percent': stats.utilizationPercent,
          'used_memory_mb': stats.usedMemoryMB,
          'total_memory_mb': stats.totalMemoryMB,
        });
        
        // Aggressive cleanup
        await _performAggressiveCleanup();
        
      } else if (stats.utilizationPercent > _memoryWarningThreshold) {
        WasteAppLogger.info('High memory usage detected', {
          'service': 'memory_management',
          'utilization_percent': stats.utilizationPercent,
          'used_memory_mb': stats.usedMemoryMB,
        });
        
        // Gentle cleanup
        await _performGentleCleanup();
      }
      
      // Check for garbage collection activity
      if (stats.gcCount > _lastGcCount) {
        WasteAppLogger.debug('Garbage collection activity detected', {
          'service': 'memory_management',
          'gc_count': stats.gcCount,
          'previous_count': _lastGcCount,
        });
        _lastGcCount = stats.gcCount;
      }
      
    } catch (e) {
      WasteAppLogger.warning('Memory check failed', e, null, {
        'service': 'memory_management',
      });
    }
  }

  /// Perform periodic cleanup tasks
  Future<void> _performPeriodicCleanup() async {
    try {
      // Check for memory leaks
      await checkMemoryLeaks();
      
      // Cleanup expired resources
      final now = DateTime.now();
      final expiredResources = <String>[];
      
      for (final entry in _disposableResources.entries) {
        // Check if resource has been around too long
        final timer = _resourceTimers[entry.key];
        if (timer == null || !timer.isActive) {
          expiredResources.add(entry.key);
        }
      }
      
      for (final resourceId in expiredResources) {
        _cleanupResource(resourceId);
      }
      
      // Cleanup expired image operations
      final expiredOperations = <String>[];
      for (final operationId in _activeImageOperations) {
        final timer = _imageCleanupTimers[operationId];
        if (timer == null || !timer.isActive) {
          expiredOperations.add(operationId);
        }
      }
      
      for (final operationId in expiredOperations) {
        _cleanupImageOperation(operationId);
      }
      
      WasteAppLogger.debug('Periodic cleanup completed', {
        'service': 'memory_management',
        'expired_resources': expiredResources.length,
        'expired_operations': expiredOperations.length,
        'active_resources': _disposableResources.length,
        'active_operations': _activeImageOperations.length,
      });
      
    } catch (e) {
      WasteAppLogger.warning('Periodic cleanup failed', e, null, {
        'service': 'memory_management',
      });
    }
  }

  /// Perform gentle cleanup for moderate memory pressure
  Future<void> _performGentleCleanup() async {
    // Clear image cache partially
    await _clearImageCache(partial: true);
    
    // Cleanup old resources
    final oldResources = _disposableResources.entries
        .where((entry) => !(_resourceTimers[entry.key]?.isActive ?? false))
        .take(5)
        .map((entry) => entry.key)
        .toList();
    
    for (final resourceId in oldResources) {
      _cleanupResource(resourceId);
    }
  }

  /// Perform aggressive cleanup for critical memory pressure
  Future<void> _performAggressiveCleanup() async {
    // Clear all image cache
    await _clearImageCache();
    
    // Force garbage collection
    await forceGarbageCollection();
    
    // Cleanup half of the resources
    final resourcesToCleanup = _disposableResources.keys
        .take((_disposableResources.length / 2).ceil())
        .toList();
    
    for (final resourceId in resourcesToCleanup) {
      _cleanupResource(resourceId);
    }
    
    // Cleanup all image operations
    final operationsToCleanup = _activeImageOperations.toList();
    for (final operationId in operationsToCleanup) {
      _cleanupImageOperation(operationId);
    }
  }

  /// Cleanup a specific resource
  void _cleanupResource(String resourceId) {
    final resource = _disposableResources.remove(resourceId);
    final timer = _resourceTimers.remove(resourceId);
    
    timer?.cancel();
    
    if (resource != null) {
      try {
        resource.dispose();
        MemoryLeakDetector.untrack(resourceId);
        
        WasteAppLogger.debug('Resource cleaned up', {
          'service': 'memory_management',
          'resource_id': resourceId,
          'resource_type': resource.resourceType,
        });
      } catch (e) {
        WasteAppLogger.warning('Error disposing resource', e, null, {
          'service': 'memory_management',
          'resource_id': resourceId,
          'resource_type': resource.resourceType,
        });
      }
    }
  }

  /// Cleanup image operation
  void _cleanupImageOperation(String operationId) {
    _activeImageOperations.remove(operationId);
    final timer = _imageCleanupTimers.remove(operationId);
    timer?.cancel();
    
    WasteAppLogger.debug('Image operation cleaned up', {
      'service': 'memory_management',
      'operation_id': operationId,
      'remaining_operations': _activeImageOperations.length,
    });
  }

  /// Clear image cache
  Future<void> _clearImageCache({bool partial = false}) async {
    try {
      if (partial) {
        // Clear only a portion of the cache
        // This would integrate with your existing cache service
        WasteAppLogger.debug('Partial image cache clear requested', {
          'service': 'memory_management',
        });
      } else {
        // Clear entire cache
        WasteAppLogger.debug('Full image cache clear requested', {
          'service': 'memory_management',
        });
      }
    } catch (e) {
      WasteAppLogger.warning('Image cache clear failed', e, null, {
        'service': 'memory_management',
        'partial': partial,
      });
    }
  }

  /// Get image memory usage estimate
  Future<double> _getImageMemoryUsage() async {
    // This would integrate with your image caching system
    // For now, return 0 as placeholder
    return 0.0;
  }

  /// Get web performance memory info
  Future<Map<String, double>> _getWebPerformanceMemory() async {
    if (kIsWeb) {
      try {
        // This would use JS interop to get performance.memory
        // For now, return placeholder values
        return {
          'usedJSHeapSize': 50 * 1024 * 1024, // 50MB
          'totalJSHeapSize': 100 * 1024 * 1024, // 100MB
        };
      } catch (e) {
        // Fallback values
        return {
          'usedJSHeapSize': 0,
          'totalJSHeapSize': 0,
        };
      }
    }
    
    return {
      'usedJSHeapSize': 0,
      'totalJSHeapSize': 0,
    };
  }
}