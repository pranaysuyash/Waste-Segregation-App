import 'package:flutter/foundation.dart';
import 'dart:collection';

/// Performance Monitoring and Optimization Utilities
/// Tracks app performance metrics and provides optimization recommendations
class PerformanceMonitor {
  static final Map<String, DateTime> _performanceMarkers = {};
  static final LinkedHashMap<String, Duration> _performanceLog = LinkedHashMap();
  static const int _maxLogEntries = 100;
  
  // Performance thresholds (in milliseconds)
  static const int _warningThreshold = 1000;  // 1 second
  static const int _criticalThreshold = 2000; // 2 seconds
  
  /// Start performance tracking for an operation
  static void startTimer(String operationName) {
    _performanceMarkers[operationName] = DateTime.now();
    debugPrint('⏱️ Performance: Started tracking "$operationName"');
  }
  
  /// End performance tracking and log results
  static Duration endTimer(String operationName) {
    final startTime = _performanceMarkers[operationName];
    if (startTime == null) {
      debugPrint('⚠️ Performance: No start marker found for "$operationName"');
      return Duration.zero;
    }
    
    final duration = DateTime.now().difference(startTime);
    _performanceMarkers.remove(operationName);
    
    // Add to performance log
    _addToPerformanceLog(operationName, duration);
    
    // Log based on performance thresholds
    _logPerformanceResult(operationName, duration);
    
    return duration;
  }
  
  /// Track a complete operation with automatic timing
  static Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName);
      return result;
    } catch (error) {
      endTimer(operationName);
      debugPrint('❌ Performance: Operation "$operationName" failed: $error');
      rethrow;
    }
  }
  
  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    if (_performanceLog.isEmpty) {
      return {'message': 'No performance data available'};
    }
    
    final durations = _performanceLog.values.map((d) => d.inMilliseconds).toList();
    durations.sort();
    
    final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    final medianDuration = durations[durations.length ~/ 2];
    final minDuration = durations.first;
    final maxDuration = durations.last;
    
    // Count operations by performance level
    int fastOperations = 0;
    int slowOperations = 0;
    int criticalOperations = 0;
    
    for (final duration in durations) {
      if (duration < _warningThreshold) {
        fastOperations++;
      } else if (duration < _criticalThreshold) {
        slowOperations++;
      } else {
        criticalOperations++;
      }
    }
    
    return {
      'total_operations': _performanceLog.length,
      'average_duration_ms': avgDuration.round(),
      'median_duration_ms': medianDuration,
      'min_duration_ms': minDuration,
      'max_duration_ms': maxDuration,
      'fast_operations': fastOperations,
      'slow_operations': slowOperations,
      'critical_operations': criticalOperations,
      'performance_score': _calculatePerformanceScore(fastOperations, slowOperations, criticalOperations),
    };
  }
  
  /// Get detailed performance breakdown by operation type
  static Map<String, Map<String, dynamic>> getDetailedStats() {
    final Map<String, List<Duration>> operationGroups = {};
    
    // Group operations by name
    _performanceLog.forEach((operation, duration) {
      final baseName = operation.split('_').first; // Group similar operations
      operationGroups[baseName] = operationGroups[baseName] ?? [];
      operationGroups[baseName]!.add(duration);
    });
    
    // Calculate stats for each operation group
    final Map<String, Map<String, dynamic>> detailedStats = {};
    
    operationGroups.forEach((operationName, durations) {
      final milliseconds = durations.map((d) => d.inMilliseconds).toList();
      milliseconds.sort();
      
      final avg = milliseconds.reduce((a, b) => a + b) / milliseconds.length;
      
      detailedStats[operationName] = {
        'count': milliseconds.length,
        'average_ms': avg.round(),
        'min_ms': milliseconds.first,
        'max_ms': milliseconds.last,
        'median_ms': milliseconds[milliseconds.length ~/ 2],
        'status': _getOperationStatus(avg),
      };
    });
    
    return detailedStats;
  }
  
  /// Get performance recommendations
  static List<String> getRecommendations() {
    final stats = getPerformanceStats();
    final recommendations = <String>[];
    
    if (stats['critical_operations'] > 0) {
      recommendations.add('🔴 ${stats['critical_operations']} operations took longer than 2 seconds. Consider optimizing these critical paths.');
    }
    
    if (stats['slow_operations'] > stats['fast_operations']) {
      recommendations.add('🟡 More slow operations than fast ones detected. Review image processing and AI calls.');
    }
    
    if (stats['average_duration_ms'] > _warningThreshold) {
      recommendations.add('⚠️ Average operation time is ${stats['average_duration_ms']}ms. Target is under ${_warningThreshold}ms.');
    }
    
    final performanceScore = stats['performance_score'] as double;
    if (performanceScore < 70) {
      recommendations.add('📊 Overall performance score is ${performanceScore.toStringAsFixed(1)}%. Consider implementing caching and optimization.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ Performance looks good! Keep monitoring for any degradation.');
    }
    
    return recommendations;
  }
  
  /// Clear performance logs
  static void clearPerformanceLog() {
    _performanceLog.clear();
    _performanceMarkers.clear();
    debugPrint('🧹 Performance: Cleared all performance logs');
  }
  
  // Private helper methods
  
  static void _addToPerformanceLog(String operationName, Duration duration) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = '${operationName}_$timestamp';
    
    _performanceLog[key] = duration;
    
    // Keep only recent entries
    if (_performanceLog.length > _maxLogEntries) {
      final firstKey = _performanceLog.keys.first;
      _performanceLog.remove(firstKey);
    }
  }
  
  static void _logPerformanceResult(String operationName, Duration duration) {
    final milliseconds = duration.inMilliseconds;
    
    if (milliseconds >= _criticalThreshold) {
      debugPrint('🔴 Performance: "$operationName" took ${milliseconds}ms (CRITICAL - over 2s)');
    } else if (milliseconds >= _warningThreshold) {
      debugPrint('🟡 Performance: "$operationName" took ${milliseconds}ms (WARNING - over 1s)');
    } else {
      debugPrint('✅ Performance: "$operationName" completed in ${milliseconds}ms');
    }
  }
  
  static double _calculatePerformanceScore(int fast, int slow, int critical) {
    final total = fast + slow + critical;
    if (total == 0) return 100.0;
    
    // Weighted scoring: fast=1.0, slow=0.5, critical=0.0
    final weightedScore = (fast * 1.0 + slow * 0.5 + critical * 0.0) / total;
    return weightedScore * 100;
  }
  
  static String _getOperationStatus(double avgMilliseconds) {
    if (avgMilliseconds < _warningThreshold) return 'good';
    if (avgMilliseconds < _criticalThreshold) return 'warning';
    return 'critical';
  }
}

/// Common Performance Tracking Operations
class PerformanceOperations {
  // Classification operations
  static const String imageClassification = 'image_classification';
  static const String imageProcessing = 'image_processing';
  static const String aiApiCall = 'ai_api_call';
  
  // Storage operations
  static const String dataLoad = 'data_load';
  static const String dataSave = 'data_save';
  static const String cacheHit = 'cache_hit';
  static const String cacheMiss = 'cache_miss';
  
  // UI operations
  static const String screenLoad = 'screen_load';
  static const String animationRender = 'animation_render';
  static const String listRender = 'list_render';
  
  // Network operations
  static const String networkRequest = 'network_request';
  static const String fileUpload = 'file_upload';
  static const String fileDownload = 'file_download';
}

/// Performance-aware wrapper for common operations
class PerformanceAwareOperations {
  /// Perform image classification with performance tracking
  static Future<T> classifyImage<T>(
    Future<T> Function() classificationOperation,
  ) async {
    return PerformanceMonitor.trackOperation(
      PerformanceOperations.imageClassification,
      classificationOperation,
    );
  }
  
  /// Perform storage operation with performance tracking
  static Future<T> storageOperation<T>(
    String operationType,
    Future<T> Function() operation,
  ) async {
    return PerformanceMonitor.trackOperation(
      '${PerformanceOperations.dataSave}_$operationType',
      operation,
    );
  }
  
  /// Load screen with performance tracking
  static Future<T> loadScreen<T>(
    String screenName,
    Future<T> Function() loadOperation,
  ) async {
    return PerformanceMonitor.trackOperation(
      '${PerformanceOperations.screenLoad}_$screenName',
      loadOperation,
    );
  }
}
