import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Performance monitoring system for settings screen
class SettingsPerformanceMonitor {
  factory SettingsPerformanceMonitor() => _instance;
  SettingsPerformanceMonitor._internal();
  static final SettingsPerformanceMonitor _instance = SettingsPerformanceMonitor._internal();

  final Map<String, PerformanceMetrics> _metrics = {};
  final List<FrameTimingInfo> _frameTimings = [];
  bool _isMonitoring = false;

  /// Start monitoring performance
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameTimings.clear();

    if (kDebugMode) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
      WasteAppLogger.info('🔍 Settings Performance Monitor: Started');
    }
  }

  /// Stop monitoring performance
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;

    if (kDebugMode) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
      _printPerformanceReport();
      WasteAppLogger.info('🔍 Settings Performance Monitor: Stopped');
    }
  }

  /// Track widget rebuild
  void trackRebuild(String widgetName) {
    if (!_isMonitoring) return;

    final metrics = _metrics.putIfAbsent(
      widgetName,
      () => PerformanceMetrics(widgetName),
    );

    metrics.incrementRebuild();

    if (kDebugMode && metrics.rebuildCount % 10 == 0) {
      WasteAppLogger.info('⚠️ Widget $widgetName has rebuilt ${metrics.rebuildCount} times');
    }
  }

  /// Track animation performance
  void trackAnimation(String animationName, Duration duration) {
    if (!_isMonitoring) return;

    final metrics = _metrics.putIfAbsent(
      animationName,
      () => PerformanceMetrics(animationName),
    );

    metrics.addAnimationDuration(duration);
  }

  /// Track memory usage
  void trackMemoryUsage(String context) {
    if (!_isMonitoring || !kDebugMode) return;

    // Note: This is a simplified memory tracking
    // In production, you might want to use more sophisticated tools
    final runtimeType = context.runtimeType.toString();
    WasteAppLogger.info('💾 Memory context: $runtimeType');
  }

  /// Handle frame timing callback
  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isMonitoring) return;

    for (final timing in timings) {
      final frameInfo = FrameTimingInfo(
        buildDuration: timing.buildDuration,
        rasterDuration: timing.rasterDuration,
        totalSpan: timing.totalSpan,
        timestamp: DateTime.now(),
      );

      _frameTimings.add(frameInfo);

      // Keep only last 100 frames
      if (_frameTimings.length > 100) {
        _frameTimings.removeAt(0);
      }

      // Warn about slow frames
      if (timing.totalSpan.inMilliseconds > 16) {
        WasteAppLogger.info('🐌 Slow frame detected: ${timing.totalSpan.inMilliseconds}ms');
      }
    }
  }

  /// Print comprehensive performance report
  void _printPerformanceReport() {
    if (!kDebugMode) return;

    WasteAppLogger.info('\n📊 Settings Performance Report');
    WasteAppLogger.info('=' * 50);

    // Widget rebuild statistics
    WasteAppLogger.info('\n🔄 Widget Rebuilds:');
    for (final metrics in _metrics.values) {
      if (metrics.rebuildCount > 0) {
        WasteAppLogger.info('  ${metrics.name}: ${metrics.rebuildCount} rebuilds');
      }
    }

    // Animation performance
    WasteAppLogger.info('\n🎬 Animation Performance:');
    for (final metrics in _metrics.values) {
      if (metrics.animationDurations.isNotEmpty) {
        final avgDuration = metrics.averageAnimationDuration;
        WasteAppLogger.info('  ${metrics.name}: ${avgDuration.inMilliseconds}ms avg');
      }
    }

    // Frame timing statistics
    if (_frameTimings.isNotEmpty) {
      WasteAppLogger.info('\n🖼️ Frame Timing Statistics:');
      final avgBuild = _calculateAverageFrameTime((f) => f.buildDuration);
      final avgRaster = _calculateAverageFrameTime((f) => f.rasterDuration);
      final avgTotal = _calculateAverageFrameTime((f) => f.totalSpan);

      WasteAppLogger.info('  Average build time: ${avgBuild.inMilliseconds}ms');
      WasteAppLogger.info('  Average raster time: ${avgRaster.inMilliseconds}ms');
      WasteAppLogger.info('  Average total time: ${avgTotal.inMilliseconds}ms');

      final slowFrames = _frameTimings.where((f) => f.totalSpan.inMilliseconds > 16).length;
      final frameRate = slowFrames / _frameTimings.length * 100;
      WasteAppLogger.info('  Slow frames: $slowFrames/${_frameTimings.length} (${frameRate.toStringAsFixed(1)}%)');
    }

    WasteAppLogger.info('=' * 50);
  }

  Duration _calculateAverageFrameTime(Duration Function(FrameTimingInfo) selector) {
    if (_frameTimings.isEmpty) return Duration.zero;

    final totalMs = _frameTimings.map(selector).map((d) => d.inMicroseconds).reduce((a, b) => a + b);

    return Duration(microseconds: totalMs ~/ _frameTimings.length);
  }

  /// Get current performance metrics
  Map<String, PerformanceMetrics> get metrics => Map.unmodifiable(_metrics);

  /// Get frame timing information
  List<FrameTimingInfo> get frameTimings => List.unmodifiable(_frameTimings);

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _frameTimings.clear();
  }
}

/// Performance metrics for a specific component
class PerformanceMetrics {
  PerformanceMetrics(this.name);

  final String name;
  int rebuildCount = 0;
  final List<Duration> animationDurations = [];
  DateTime? firstRebuild;
  DateTime? lastRebuild;

  void incrementRebuild() {
    rebuildCount++;
    final now = DateTime.now();

    firstRebuild ??= now;
    lastRebuild = now;
  }

  void addAnimationDuration(Duration duration) {
    animationDurations.add(duration);

    // Keep only last 50 animation timings
    if (animationDurations.length > 50) {
      animationDurations.removeAt(0);
    }
  }

  Duration get averageAnimationDuration {
    if (animationDurations.isEmpty) return Duration.zero;

    final totalMs = animationDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b);

    return Duration(microseconds: totalMs ~/ animationDurations.length);
  }

  Duration? get rebuildFrequency {
    if (firstRebuild == null || lastRebuild == null || rebuildCount <= 1) {
      return null;
    }

    final totalDuration = lastRebuild!.difference(firstRebuild!);
    return Duration(
      milliseconds: totalDuration.inMilliseconds ~/ (rebuildCount - 1),
    );
  }
}

/// Frame timing information
class FrameTimingInfo {
  const FrameTimingInfo({
    required this.buildDuration,
    required this.rasterDuration,
    required this.totalSpan,
    required this.timestamp,
  });

  final Duration buildDuration;
  final Duration rasterDuration;
  final Duration totalSpan;
  final DateTime timestamp;

  bool get isSlowFrame => totalSpan.inMilliseconds > 16;
}

/// Widget wrapper that automatically tracks performance
class PerformanceTracker extends StatefulWidget {
  const PerformanceTracker({
    super.key,
    required this.name,
    required this.child,
    this.trackRebuilds = true,
    this.trackMemory = false,
  });

  final String name;
  final Widget child;
  final bool trackRebuilds;
  final bool trackMemory;

  @override
  State<PerformanceTracker> createState() => _PerformanceTrackerState();
}

class _PerformanceTrackerState extends State<PerformanceTracker> {
  final _monitor = SettingsPerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    if (widget.trackRebuilds) {
      _monitor.trackRebuild(widget.name);
    }

    if (widget.trackMemory) {
      _monitor.trackMemoryUsage(widget.name);
    }

    return widget.child;
  }
}

/// Mixin for widgets that want to track their performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  final _monitor = SettingsPerformanceMonitor();

  String get performanceTrackingName => widget.runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    _monitor.trackRebuild(performanceTrackingName);
    return buildWithTracking(context);
  }

  /// Override this instead of build() when using the mixin
  Widget buildWithTracking(BuildContext context);

  /// Track animation performance
  void trackAnimation(String animationName, Duration duration) {
    _monitor.trackAnimation('$performanceTrackingName.$animationName', duration);
  }
}

/// Performance-aware settings screen wrapper
class PerformanceAwareSettingsScreen extends StatefulWidget {
  const PerformanceAwareSettingsScreen({
    super.key,
    required this.child,
    this.enableMonitoring = kDebugMode,
  });

  final Widget child;
  final bool enableMonitoring;

  @override
  State<PerformanceAwareSettingsScreen> createState() => _PerformanceAwareSettingsScreenState();
}

class _PerformanceAwareSettingsScreenState extends State<PerformanceAwareSettingsScreen> with WidgetsBindingObserver {
  final _monitor = SettingsPerformanceMonitor();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.enableMonitoring) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monitor.startMonitoring();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (widget.enableMonitoring) {
      _monitor.stopMonitoring();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!widget.enableMonitoring) return;

    switch (state) {
      case AppLifecycleState.paused:
        _monitor.stopMonitoring();
        break;
      case AppLifecycleState.resumed:
        _monitor.startMonitoring();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceTracker(
      name: 'SettingsScreen',
      trackRebuilds: widget.enableMonitoring,
      trackMemory: widget.enableMonitoring,
      child: widget.child,
    );
  }
}

/// Performance optimization utilities
class SettingsOptimizations {
  /// Create a performance-optimized ListView for settings
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }

  /// Wrap widget with RepaintBoundary for optimization
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Create optimized section with lazy loading
  static Widget lazySection({
    required String title,
    required List<Widget> Function() childrenBuilder,
    bool initiallyExpanded = true,
  }) {
    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: initiallyExpanded,
      children: [
        Builder(
          builder: (context) {
            // Children are built only when expanded
            return Column(children: childrenBuilder());
          },
        ),
      ],
    );
  }
}
