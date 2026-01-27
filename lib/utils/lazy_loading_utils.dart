import 'package:flutter/material.dart';
import 'waste_app_logger.dart';

/// Utility class for implementing lazy loading in lists and grids
class LazyLoadingUtils {
  /// Creates a lazy loading ListView with performance monitoring
  static Widget createLazyListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    String? debugLabel,
    double? itemExtent,
    Widget Function(BuildContext context)? loadingBuilder,
    Widget Function(BuildContext context)? emptyBuilder,
    int initialVisibleItems = 20,
    int loadMoreThreshold = 5,
  }) {
    return _LazyListView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      debugLabel: debugLabel,
      itemExtent: itemExtent,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      initialVisibleItems: initialVisibleItems,
      loadMoreThreshold: loadMoreThreshold,
    );
  }

  /// Creates a lazy loading GridView with performance monitoring
  static Widget createLazyGridView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    String? debugLabel,
    Widget Function(BuildContext context)? loadingBuilder,
    Widget Function(BuildContext context)? emptyBuilder,
    int initialVisibleItems = 20,
    int loadMoreThreshold = 5,
  }) {
    return _LazyGridView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: gridDelegate,
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      debugLabel: debugLabel,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      initialVisibleItems: initialVisibleItems,
      loadMoreThreshold: loadMoreThreshold,
    );
  }

  /// Creates a performance-optimized image gallery with lazy loading
  static Widget createLazyImageGallery({
    required List<String> imagePaths,
    required Widget Function(BuildContext context, String imagePath, int index)
        imageBuilder,
    int crossAxisCount = 2,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    double childAspectRatio = 1.0,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    String? debugLabel,
    int initialVisibleItems = 10,
  }) {
    return _LazyImageGallery(
      imagePaths: imagePaths,
      imageBuilder: imageBuilder,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      controller: controller,
      debugLabel: debugLabel,
      initialVisibleItems: initialVisibleItems,
    );
  }
}

/// Internal lazy loading ListView implementation
class _LazyListView extends StatefulWidget {
  const _LazyListView({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.debugLabel,
    this.itemExtent,
    this.loadingBuilder,
    this.emptyBuilder,
    this.initialVisibleItems = 20,
    this.loadMoreThreshold = 5,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? debugLabel;
  final double? itemExtent;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final int initialVisibleItems;
  final int loadMoreThreshold;

  @override
  State<_LazyListView> createState() => _LazyListViewState();
}

class _LazyListViewState extends State<_LazyListView> {
  late ScrollController _scrollController;
  int _visibleItemCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _visibleItemCount = widget.initialVisibleItems.clamp(0, widget.itemCount);
    _scrollController.addListener(_onScroll);

    // Log lazy loading initialization
    if (widget.debugLabel != null) {
      WasteAppLogger.info('Lazy ListView initialized: ${widget.debugLabel}',
          context: {
            'total_items': widget.itemCount,
            'initial_visible': _visibleItemCount,
            'service': 'LazyLoadingUtils',
          });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _visibleItemCount >= widget.itemCount) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Calculate remaining items to scroll
    final remainingScroll = maxScroll - currentScroll;
    final itemHeight = widget.itemExtent ?? 80.0; // Estimate if not provided
    final remainingItems = (remainingScroll / itemHeight).ceil();

    if (remainingItems <= widget.loadMoreThreshold) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate async loading with a small delay to prevent frame drops
    Future.delayed(const Duration(milliseconds: 16), () {
      if (mounted) {
        setState(() {
          final newCount = (_visibleItemCount + widget.initialVisibleItems)
              .clamp(0, widget.itemCount);

          if (widget.debugLabel != null) {
            WasteAppLogger.info('Loading more items: ${widget.debugLabel}',
                context: {
                  'previous_count': _visibleItemCount,
                  'new_count': newCount,
                  'service': 'LazyLoadingUtils',
                });
          }

          _visibleItemCount = newCount;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemExtent: widget.itemExtent,
      itemCount: _visibleItemCount + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visibleItemCount) {
          // Show loading indicator
          return widget.loadingBuilder?.call(context) ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        // Wrap each item in RepaintBoundary for better performance
        return RepaintBoundary(
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}

/// Internal lazy loading GridView implementation
class _LazyGridView extends StatefulWidget {
  const _LazyGridView({
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.debugLabel,
    this.loadingBuilder,
    this.emptyBuilder,
    this.initialVisibleItems = 20,
    this.loadMoreThreshold = 5,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? debugLabel;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final int initialVisibleItems;
  final int loadMoreThreshold;

  @override
  State<_LazyGridView> createState() => _LazyGridViewState();
}

class _LazyGridViewState extends State<_LazyGridView> {
  late ScrollController _scrollController;
  int _visibleItemCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _visibleItemCount = widget.initialVisibleItems.clamp(0, widget.itemCount);
    _scrollController.addListener(_onScroll);

    if (widget.debugLabel != null) {
      WasteAppLogger.info('Lazy GridView initialized: ${widget.debugLabel}',
          context: {
            'total_items': widget.itemCount,
            'initial_visible': _visibleItemCount,
            'service': 'LazyLoadingUtils',
          });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _visibleItemCount >= widget.itemCount) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll - currentScroll <= 200) {
      // 200px threshold for grid
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 16), () {
      if (mounted) {
        setState(() {
          final newCount = (_visibleItemCount + widget.initialVisibleItems)
              .clamp(0, widget.itemCount);

          if (widget.debugLabel != null) {
            WasteAppLogger.info('Loading more grid items: ${widget.debugLabel}',
                context: {
                  'previous_count': _visibleItemCount,
                  'new_count': newCount,
                  'service': 'LazyLoadingUtils',
                });
          }

          _visibleItemCount = newCount;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: widget.gridDelegate,
      itemCount: _visibleItemCount + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visibleItemCount) {
          // Show loading indicator
          return widget.loadingBuilder?.call(context) ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        return RepaintBoundary(
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}

/// Internal lazy loading image gallery implementation
class _LazyImageGallery extends StatefulWidget {
  const _LazyImageGallery({
    required this.imagePaths,
    required this.imageBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
    this.debugLabel,
    this.initialVisibleItems = 10,
  });

  final List<String> imagePaths;
  final Widget Function(BuildContext context, String imagePath, int index)
      imageBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final String? debugLabel;
  final int initialVisibleItems;

  @override
  State<_LazyImageGallery> createState() => _LazyImageGalleryState();
}

class _LazyImageGalleryState extends State<_LazyImageGallery> {
  late ScrollController _scrollController;
  int _visibleItemCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _visibleItemCount =
        widget.initialVisibleItems.clamp(0, widget.imagePaths.length);
    _scrollController.addListener(_onScroll);

    if (widget.debugLabel != null) {
      WasteAppLogger.info(
          'Lazy Image Gallery initialized: ${widget.debugLabel}',
          context: {
            'total_images': widget.imagePaths.length,
            'initial_visible': _visibleItemCount,
            'service': 'LazyLoadingUtils',
          });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _visibleItemCount >= widget.imagePaths.length) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll - currentScroll <= 300) {
      // 300px threshold for images
      _loadMoreImages();
    }
  }

  void _loadMoreImages() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Longer delay for images to prevent memory pressure
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          final newCount = (_visibleItemCount + widget.initialVisibleItems)
              .clamp(0, widget.imagePaths.length);

          if (widget.debugLabel != null) {
            WasteAppLogger.info('Loading more images: ${widget.debugLabel}',
                context: {
                  'previous_count': _visibleItemCount,
                  'new_count': newCount,
                  'service': 'LazyLoadingUtils',
                });
          }

          _visibleItemCount = newCount;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return const Center(
        child: Text('No images to display'),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: _visibleItemCount + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visibleItemCount) {
          // Show loading indicator
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final imagePath = widget.imagePaths[index];
        return RepaintBoundary(
          child: widget.imageBuilder(context, imagePath, index),
        );
      },
    );
  }
}

/// Performance monitoring widget that tracks frame rate for specific widgets
class PerformanceMonitoredWidget extends StatefulWidget {
  const PerformanceMonitoredWidget({
    super.key,
    required this.child,
    this.debugLabel,
    this.onPerformanceUpdate,
  });

  final Widget child;
  final String? debugLabel;
  final void Function(Map<String, dynamic> metrics)? onPerformanceUpdate;

  @override
  State<PerformanceMonitoredWidget> createState() =>
      _PerformanceMonitoredWidgetState();
}

class _PerformanceMonitoredWidgetState
    extends State<PerformanceMonitoredWidget> {
  DateTime? _lastFrameTime;
  int _frameCount = 0;
  double _averageFrameTime = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      _frameCount++;
      _averageFrameTime =
          ((_averageFrameTime * (_frameCount - 1)) + frameTime) / _frameCount;

      // Report performance metrics periodically
      if (_frameCount % 60 == 0) {
        // Every 60 frames (~1 second at 60fps)
        final metrics = {
          'widget_label': widget.debugLabel ?? 'unknown',
          'frame_count': _frameCount,
          'average_frame_time_ms': _averageFrameTime,
          'current_fps': 1000.0 / _averageFrameTime,
        };

        widget.onPerformanceUpdate?.call(metrics);

        if (widget.debugLabel != null) {
          WasteAppLogger.info('Widget performance: ${widget.debugLabel}',
              context: {
                ...metrics,
                'service': 'PerformanceMonitoredWidget',
              });
        }
      }
    }
    _lastFrameTime = now;

    // Schedule next frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
