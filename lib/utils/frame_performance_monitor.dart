import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../services/analytics_service.dart';
import 'waste_app_logger.dart';

/// Frame performance monitoring utility for tracking frame drops and UI performance
class FramePerformanceMonitor {
  static AnalyticsService? _analyticsService;
  static bool _isInitialized = false;
  static bool _isMonitoring = false;
  
  // Performance thresholds
  static const int slowFrameThresholdMs = 16; // 60 FPS target
  static const int jankFrameThresholdMs = 32; // 30 FPS threshold
  static const int maxEventsPerMinute = 10; // Rate limiting
  
  // Rate limiting
  static DateTime? _lastEventTime;
  static int _eventCountThisMinute = 0;
  
  // Statistics
  static int _totalFrames = 0;
  static int _slowFrames = 0;
  static int _jankFrames = 0;
  static double _averageFrameTime = 0.0;

  /// Initialize performance monitoring with analytics service
  static void initialize(AnalyticsService analyticsService) {
    _analyticsService = analyticsService;
    _isInitialized = true;
    
    WasteAppLogger.info('🚀 Frame performance monitor initialized', null, null, {
      'service': 'FramePerformanceMonitor',
    });
  }

  /// Start monitoring frame performance
  static void startMonitoring() {
    if (!_isInitialized) {
      WasteAppLogger.warning('Frame performance monitor not initialized');
      return;
    }
    
    if (_isMonitoring) {
      WasteAppLogger.info('Frame performance monitoring already active');
      return;
    }
    
    _isMonitoring = true;
    _resetStatistics();
    
    // Add frame timing callback
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    
    WasteAppLogger.info('📊 Frame performance monitoring started', null, null, {
      'slow_frame_threshold_ms': slowFrameThresholdMs,
      'jank_frame_threshold_ms': jankFrameThresholdMs,
      'service': 'FramePerformanceMonitor',
    });
  }

  /// Stop monitoring frame performance
  static void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    
    _logFinalStatistics();
    
    WasteAppLogger.info('⏹️ Frame performance monitoring stopped', null, null, {
      'service': 'FramePerformanceMonitor',
    });
  }

  /// Handle frame timing data
  static void _onFrameTimings(List<FrameTiming> timings) {
    if (!_isMonitoring || _analyticsService == null) return;
    
    for (final timing in timings) {
      _processFrameTiming(timing);
    }
  }

  /// Process individual frame timing
  static void _processFrameTiming(FrameTiming timing) {
    final frameTimeMs = timing.totalSpan.inMilliseconds;
    final buildTimeMs = timing.buildDuration.inMilliseconds;
    final rasterTimeMs = timing.rasterDuration.inMilliseconds;
    
    _totalFrames++;
    _updateAverageFrameTime(frameTimeMs.toDouble());
    
    // Check for slow frames
    if (frameTimeMs > slowFrameThresholdMs) {
      _slowFrames++;
      _trackSlowFrame(frameTimeMs, buildTimeMs, rasterTimeMs);
    }
    
    // Check for jank frames (very slow)
    if (frameTimeMs > jankFrameThresholdMs) {
      _jankFrames++;
      _trackJankFrame(frameTimeMs, buildTimeMs, rasterTimeMs);
    }
    
    // Log statistics periodically
    if (_totalFrames % 1000 == 0) {
      _logPerformanceStatistics();
    }
  }

  /// Track slow frame event
  static void _trackSlowFrame(int frameTimeMs, int buildTimeMs, int rasterTimeMs) {
    if (!_shouldSendEvent()) return;
    
    _analyticsService!.trackSlowResource(
      operationName: 'frame_render',
      durationMs: frameTimeMs,
      resourceType: 'ui_frame',
      additionalData: {
        'build_time_ms': buildTimeMs,
        'raster_time_ms': rasterTimeMs,
        'frame_type': 'slow',
        'total_frames': _totalFrames,
        'slow_frame_percentage': (_slowFrames / _totalFrames * 100).toStringAsFixed(2),
      },
    );
    
    WasteAppLogger.performanceLog('slow_frame', frameTimeMs, context: {
      'build_time_ms': buildTimeMs,
      'raster_time_ms': rasterTimeMs,
      'total_frames': _totalFrames,
    });
  }

  /// Track jank frame event (very slow)
  static void _trackJankFrame(int frameTimeMs, int buildTimeMs, int rasterTimeMs) {
    if (!_shouldSendEvent()) return;
    
    _analyticsService!.trackUserAction('jank_frame_detected', parameters: {
      'frame_time_ms': frameTimeMs,
      'build_time_ms': buildTimeMs,
      'raster_time_ms': rasterTimeMs,
      'total_frames': _totalFrames,
      'jank_frame_percentage': (_jankFrames / _totalFrames * 100).toStringAsFixed(2),
      'average_frame_time': _averageFrameTime.toStringAsFixed(2),
    });
    
    WasteAppLogger.severe('🐌 Jank frame detected: ${frameTimeMs}ms', null, null, {
      'build_time_ms': buildTimeMs,
      'raster_time_ms': rasterTimeMs,
      'service': 'FramePerformanceMonitor',
    });
  }

  /// Check if we should send analytics event (rate limiting)
  static bool _shouldSendEvent() {
    final now = DateTime.now();
    
    // Reset counter if it's a new minute
    if (_lastEventTime == null || now.difference(_lastEventTime!).inMinutes >= 1) {
      _eventCountThisMinute = 0;
      _lastEventTime = now;
    }
    
    // Check rate limit
    if (_eventCountThisMinute >= maxEventsPerMinute) {
      return false;
    }
    
    _eventCountThisMinute++;
    return true;
  }

  /// Update running average frame time
  static void _updateAverageFrameTime(double frameTime) {
    _averageFrameTime = ((_averageFrameTime * (_totalFrames - 1)) + frameTime) / _totalFrames;
  }

  /// Reset performance statistics
  static void _resetStatistics() {
    _totalFrames = 0;
    _slowFrames = 0;
    _jankFrames = 0;
    _averageFrameTime = 0.0;
    _eventCountThisMinute = 0;
    _lastEventTime = null;
  }

  /// Log current performance statistics
  static void _logPerformanceStatistics() {
    if (_totalFrames == 0) return;
    
    final slowFramePercentage = (_slowFrames / _totalFrames * 100);
    final jankFramePercentage = (_jankFrames / _totalFrames * 100);
    
    WasteAppLogger.info('📊 Frame Performance Stats', null, null, {
      'total_frames': _totalFrames,
      'slow_frames': _slowFrames,
      'jank_frames': _jankFrames,
      'slow_frame_percentage': slowFramePercentage.toStringAsFixed(2),
      'jank_frame_percentage': jankFramePercentage.toStringAsFixed(2),
      'average_frame_time_ms': _averageFrameTime.toStringAsFixed(2),
      'service': 'FramePerformanceMonitor',
    });
  }

  /// Log final statistics when monitoring stops
  static void _logFinalStatistics() {
    if (_totalFrames == 0) return;
    
    _logPerformanceStatistics();
    
    // Send summary analytics event
    if (_analyticsService != null) {
      _analyticsService!.trackUserAction('frame_performance_session_summary', parameters: {
        'total_frames': _totalFrames,
        'slow_frames': _slowFrames,
        'jank_frames': _jankFrames,
        'slow_frame_percentage': (_slowFrames / _totalFrames * 100).toStringAsFixed(2),
        'jank_frame_percentage': (_jankFrames / _totalFrames * 100).toStringAsFixed(2),
        'average_frame_time_ms': _averageFrameTime.toStringAsFixed(2),
      });
    }
  }

  /// Get current performance statistics
  static Map<String, dynamic> getStatistics() {
    return {
      'is_monitoring': _isMonitoring,
      'total_frames': _totalFrames,
      'slow_frames': _slowFrames,
      'jank_frames': _jankFrames,
      'slow_frame_percentage': _totalFrames > 0 ? (_slowFrames / _totalFrames * 100) : 0.0,
      'jank_frame_percentage': _totalFrames > 0 ? (_jankFrames / _totalFrames * 100) : 0.0,
      'average_frame_time_ms': _averageFrameTime,
    };
  }

  /// Check if performance is good (< 5% slow frames)
  static bool get isPerformanceGood {
    if (_totalFrames < 100) return true; // Not enough data
    return (_slowFrames / _totalFrames) < 0.05;
  }

  /// Force trigger a slow frame for testing
  static void simulateSlowFrame({int durationMs = 50}) {
    if (!kDebugMode) return;
    
    WasteAppLogger.info('🧪 Simulating slow frame for testing: ${durationMs}ms');
    
    // Simulate heavy computation
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < durationMs) {
      // Busy wait to simulate slow frame
    }
    stopwatch.stop();
  }
} 