import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/frame_performance_monitor.dart';
import '../utils/waste_app_logger.dart';
import 'analytics_service.dart';

/// Service for monitoring UI performance and providing optimization recommendations
class UIPerformanceService {
  static UIPerformanceService? _instance;
  static UIPerformanceService get instance => _instance ??= UIPerformanceService._();
  
  UIPerformanceService._();

  final Map<String, _WidgetPerformanceData> _widgetMetrics = {};
  final Map<String, Timer> _reportingTimers = {};
  AnalyticsService? _analyticsService;
  bool _isInitialized = false;

  /// Initialize the UI performance service
  void initialize(AnalyticsService analyticsService) {
    _analyticsService = analyticsService;
    _isInitialized = true;
    
    WasteAppLogger.info('UI Performance Service initialized', null, null, {
      'service': 'UIPerformanceService',
    });
  }

  /// Start monitoring performance for a specific widget
  void startWidgetMonitoring(String widgetId, {String? debugLabel}) {
    if (!_isInitialized) return;

    _widgetMetrics[widgetId] = _WidgetPerformanceData(
      widgetId: widgetId,
      debugLabel: debugLabel,
      startTime: DateTime.now(),
    );

    // Set up periodic reporting
    _reportingTimers[widgetId] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reportWidgetMetrics(widgetId),
    );

    WasteAppLogger.info('Started monitoring widget: $widgetId', null, null, {
      'widget_id': widgetId,
      'debug_label': debugLabel,
      'service': 'UIPerformanceService',
    });
  }

  /// Stop monitoring performance for a specific widget
  void stopWidgetMonitoring(String widgetId) {
    _reportingTimers[widgetId]?.cancel();
    _reportingTimers.remove(widgetId);
    
    final data = _widgetMetrics.remove(widgetId);
    if (data != null) {
      _reportFinalWidgetMetrics(data);
    }

    WasteAppLogger.info('Stopped monitoring widget: $widgetId', null, null, {
      'widget_id': widgetId,
      'service': 'UIPerformanceService',
    });
  }

  /// Record a frame render time for a specific widget
  void recordFrameTime(String widgetId, double frameTimeMs) {
    final data = _widgetMetrics[widgetId];
    if (data == null) return;

    data.recordFrame(frameTimeMs);

    // Check for performance issues
    if (frameTimeMs > 32) { // Jank threshold (30fps)
      _reportJankFrame(widgetId, frameTimeMs);
    }
  }

  /// Record a rebuild event for a specific widget
  void recordRebuild(String widgetId, {String? reason}) {
    final data = _widgetMetrics[widgetId];
    if (data == null) return;

    data.recordRebuild(reason);
  }

  /// Record memory usage for a specific widget
  void recordMemoryUsage(String widgetId, int memoryBytes) {
    final data = _widgetMetrics[widgetId];
    if (data == null) return;

    data.recordMemoryUsage(memoryBytes);
  }

  /// Get performance metrics for a specific widget
  Map<String, dynamic>? getWidgetMetrics(String widgetId) {
    final data = _widgetMetrics[widgetId];
    return data?.toMap();
  }

  /// Get performance metrics for all monitored widgets
  Map<String, Map<String, dynamic>> getAllMetrics() {
    return _widgetMetrics.map((key, value) => MapEntry(key, value.toMap()));
  }

  /// Get performance recommendations based on current metrics
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];

    for (final data in _widgetMetrics.values) {
      if (data.averageFrameTime > 16) {
        recommendations.add(
          'Widget ${data.debugLabel ?? data.widgetId} is rendering slowly '
          '(${data.averageFrameTime.toStringAsFixed(1)}ms avg). '
          'Consider adding RepaintBoundary or optimizing build method.',
        );
      }

      if (data.rebuildsPerSecond > 10) {
        recommendations.add(
          'Widget ${data.debugLabel ?? data.widgetId} is rebuilding frequently '
          '(${data.rebuildsPerSecond.toStringAsFixed(1)}/sec). '
          'Check for unnecessary state changes or use const constructors.',
        );
      }

      if (data.peakMemoryUsage > 50 * 1024 * 1024) { // 50MB
        recommendations.add(
          'Widget ${data.debugLabel ?? data.widgetId} has high memory usage '
          '(${(data.peakMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB peak). '
          'Consider implementing lazy loading or image optimization.',
        );
      }
    }

    return recommendations;
  }

  /// Report widget metrics to analytics
  void _reportWidgetMetrics(String widgetId) {
    final data = _widgetMetrics[widgetId];
    if (data == null || _analyticsService == null) return;

    final metrics = data.toMap();
    _analyticsService!.trackUserAction('widget_performance_metrics', parameters: {
      'widget_id': widgetId,
      ...metrics,
    });
  }

  /// Report final widget metrics when monitoring stops
  void _reportFinalWidgetMetrics(_WidgetPerformanceData data) {
    if (_analyticsService == null) return;

    final metrics = data.toMap();
    _analyticsService!.trackUserAction('widget_performance_session_end', parameters: {
      'widget_id': data.widgetId,
      'session_duration_ms': DateTime.now().difference(data.startTime).inMilliseconds,
      ...metrics,
    });
  }

  /// Report jank frame to analytics
  void _reportJankFrame(String widgetId, double frameTimeMs) {
    if (_analyticsService == null) return;

    _analyticsService!.trackUserAction('widget_jank_frame', parameters: {
      'widget_id': widgetId,
      'frame_time_ms': frameTimeMs,
      'debug_label': _widgetMetrics[widgetId]?.debugLabel,
    });

    WasteAppLogger.warning('Jank frame detected in widget: $widgetId', null, null, {
      'widget_id': widgetId,
      'frame_time_ms': frameTimeMs,
      'service': 'UIPerformanceService',
    });
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    for (final timer in _reportingTimers.values) {
      timer.cancel();
    }
    _reportingTimers.clear();
    _widgetMetrics.clear();
    _isInitialized = false;
  }
}

/// Internal class to track performance data for a specific widget
class _WidgetPerformanceData {
  _WidgetPerformanceData({
    required this.widgetId,
    this.debugLabel,
    required this.startTime,
  });

  final String widgetId;
  final String? debugLabel;
  final DateTime startTime;

  int _frameCount = 0;
  double _totalFrameTime = 0.0;
  double _maxFrameTime = 0.0;
  double _minFrameTime = double.infinity;

  int _rebuildCount = 0;
  final List<String> _rebuildReasons = [];

  int _currentMemoryUsage = 0;
  int _peakMemoryUsage = 0;

  void recordFrame(double frameTimeMs) {
    _frameCount++;
    _totalFrameTime += frameTimeMs;
    _maxFrameTime = frameTimeMs > _maxFrameTime ? frameTimeMs : _maxFrameTime;
    _minFrameTime = frameTimeMs < _minFrameTime ? frameTimeMs : _minFrameTime;
  }

  void recordRebuild(String? reason) {
    _rebuildCount++;
    if (reason != null) {
      _rebuildReasons.add(reason);
    }
  }

  void recordMemoryUsage(int memoryBytes) {
    _currentMemoryUsage = memoryBytes;
    _peakMemoryUsage = memoryBytes > _peakMemoryUsage ? memoryBytes : _peakMemoryUsage;
  }

  double get averageFrameTime => _frameCount > 0 ? _totalFrameTime / _frameCount : 0.0;
  double get rebuildsPerSecond {
    final durationSeconds = DateTime.now().difference(startTime).inSeconds;
    return durationSeconds > 0 ? _rebuildCount / durationSeconds : 0.0;
  }
  int get peakMemoryUsage => _peakMemoryUsage;

  Map<String, dynamic> toMap() {
    return {
      'widget_id': widgetId,
      'debug_label': debugLabel,
      'frame_count': _frameCount,
      'average_frame_time_ms': averageFrameTime,
      'max_frame_time_ms': _maxFrameTime,
      'min_frame_time_ms': _minFrameTime == double.infinity ? 0.0 : _minFrameTime,
      'rebuild_count': _rebuildCount,
      'rebuilds_per_second': rebuildsPerSecond,
      'current_memory_usage_bytes': _currentMemoryUsage,
      'peak_memory_usage_bytes': _peakMemoryUsage,
      'session_duration_ms': DateTime.now().difference(startTime).inMilliseconds,
      'rebuild_reasons': _rebuildReasons.take(10).toList(), // Limit to last 10 reasons
    };
  }
}

/// Widget wrapper that automatically monitors performance
class PerformanceMonitoredWidget extends StatefulWidget {
  const PerformanceMonitoredWidget({
    super.key,
    required this.child,
    required this.widgetId,
    this.debugLabel,
    this.enableFrameMonitoring = true,
    this.enableRebuildMonitoring = true,
    this.enableMemoryMonitoring = false,
  });

  final Widget child;
  final String widgetId;
  final String? debugLabel;
  final bool enableFrameMonitoring;
  final bool enableRebuildMonitoring;
  final bool enableMemoryMonitoring;

  @override
  State<PerformanceMonitoredWidget> createState() => _PerformanceMonitoredWidgetState();
}

class _PerformanceMonitoredWidgetState extends State<PerformanceMonitoredWidget> {
  DateTime? _lastFrameTime;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    UIPerformanceService.instance.startWidgetMonitoring(
      widget.widgetId,
      debugLabel: widget.debugLabel,
    );

    if (widget.enableFrameMonitoring) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  @override
  void dispose() {
    UIPerformanceService.instance.stopWidgetMonitoring(widget.widgetId);
    super.dispose();
  }

  void _onFrame(Duration timestamp) {
    if (!mounted || !widget.enableFrameMonitoring) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      UIPerformanceService.instance.recordFrameTime(widget.widgetId, frameTime);
    }
    _lastFrameTime = now;

    // Schedule next frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableRebuildMonitoring) {
      _buildCount++;
      UIPerformanceService.instance.recordRebuild(
        widget.widgetId,
        reason: 'build_$_buildCount',
      );
    }

    return RepaintBoundary(
      child: widget.child,
    );
  }
}

/// Extension to easily wrap widgets with performance monitoring
extension PerformanceMonitoring on Widget {
  /// Wrap this widget with performance monitoring
  Widget withPerformanceMonitoring({
    required String widgetId,
    String? debugLabel,
    bool enableFrameMonitoring = true,
    bool enableRebuildMonitoring = true,
    bool enableMemoryMonitoring = false,
  }) {
    return PerformanceMonitoredWidget(
      widgetId: widgetId,
      debugLabel: debugLabel,
      enableFrameMonitoring: enableFrameMonitoring,
      enableRebuildMonitoring: enableRebuildMonitoring,
      enableMemoryMonitoring: enableMemoryMonitoring,
      child: this,
    );
  }
}