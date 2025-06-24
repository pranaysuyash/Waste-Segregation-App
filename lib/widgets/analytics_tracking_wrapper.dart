import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../providers/app_providers.dart';
import '../utils/waste_app_logger.dart';

/// Widget that automatically tracks user interactions for analytics
class AnalyticsTrackingWrapper extends ConsumerStatefulWidget {
  const AnalyticsTrackingWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.elementId,
    this.elementType = 'unknown',
    this.trackClicks = true,
    this.trackScrollDepth = true,
    this.trackRageClicks = true,
    this.userIntent,
  });

  final Widget child;
  final String screenName;
  final String? elementId;
  final String elementType;
  final bool trackClicks;
  final bool trackScrollDepth;
  final bool trackRageClicks;
  final String? userIntent;

  @override
  ConsumerState<AnalyticsTrackingWrapper> createState() => _AnalyticsTrackingWrapperState();
}

class _AnalyticsTrackingWrapperState extends ConsumerState<AnalyticsTrackingWrapper> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _tapTimes = [];
  final Set<int> _scrollDepthsReported = {};

  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = ref.read(analyticsServiceProvider);

    if (widget.trackScrollDepth) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles scroll depth tracking
  void _onScroll() {
    try {
      final scrollPosition = _scrollController.position;
      final maxScroll = scrollPosition.maxScrollExtent;
      final currentScroll = scrollPosition.pixels;

      if (maxScroll > 0) {
        final scrollPercent = ((currentScroll / maxScroll) * 100).round();

        // Track at 25%, 50%, 75%, and 100% scroll depths
        const milestones = [25, 50, 75, 100];
        for (final milestone in milestones) {
          if (scrollPercent >= milestone && !_scrollDepthsReported.contains(milestone)) {
            _scrollDepthsReported.add(milestone);
            _trackScrollDepth(milestone);
            break; // Only track one milestone per scroll event
          }
        }
      }
    } catch (e) {
      WasteAppLogger.warning('Error tracking scroll depth', e, null,
          {'screen_name': widget.screenName, 'service': 'AnalyticsTrackingWrapper'});
    }
  }

  /// Tracks scroll depth milestone
  void _trackScrollDepth(int depthPercent) {
    _analyticsService.trackScrollDepth(
      depthPercent: depthPercent,
      screenName: widget.screenName,
      contentType: widget.elementType,
    );
  }

  /// Handles tap/click tracking
  void _onTap() {
    try {
      final now = DateTime.now();
      _tapTimes.add(now);

      // Clean up old tap times (keep only last 5 seconds)
      _tapTimes.removeWhere((time) => now.difference(time).inSeconds > 5);

      if (widget.trackClicks && widget.elementId != null) {
        _trackClick();
      }

      if (widget.trackRageClicks && _tapTimes.length >= 3) {
        // Check if 3+ taps happened within 1 second
        final recentTaps = _tapTimes.where((time) => now.difference(time).inSeconds <= 1).toList();

        if (recentTaps.length >= 3) {
          _trackRageClick(recentTaps.length);
          _tapTimes.clear(); // Clear to avoid duplicate rage click events
        }
      }
    } catch (e) {
      WasteAppLogger.warning('Error tracking tap', e, null,
          {'screen_name': widget.screenName, 'element_id': widget.elementId, 'service': 'AnalyticsTrackingWrapper'});
    }
  }

  /// Tracks regular click
  void _trackClick() {
    _analyticsService.trackClick(
      elementId: widget.elementId!,
      screenName: widget.screenName,
      elementType: widget.elementType,
      userIntent: widget.userIntent,
    );
  }

  /// Tracks rage click (multiple rapid taps)
  void _trackRageClick(int tapCount) {
    if (widget.elementId != null) {
      _analyticsService.trackRageClick(
        elementId: widget.elementId!,
        screenName: widget.screenName,
        tapCount: tapCount,
      );

      WasteAppLogger.info('Rage click detected', null, null, {
        'element_id': widget.elementId,
        'screen_name': widget.screenName,
        'tap_count': tapCount,
        'service': 'AnalyticsTrackingWrapper'
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    // Wrap with scroll tracking if enabled
    if (widget.trackScrollDepth && widget.child is! Scrollable) {
      child = SingleChildScrollView(
        controller: _scrollController,
        child: child,
      );
    } else if (widget.trackScrollDepth && widget.child is Scrollable) {
      // If child is already scrollable, we need to inject our controller
      // This is more complex and might need specific handling per scrollable type
      WasteAppLogger.info('Child is already scrollable, scroll tracking may not work', null, null,
          {'screen_name': widget.screenName, 'service': 'AnalyticsTrackingWrapper'});
    }

    // Wrap with tap tracking if enabled
    if (widget.trackClicks || widget.trackRageClicks) {
      child = GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.translucent,
        child: child,
      );
    }

    return child;
  }
}

/// Simplified wrapper for buttons and clickable elements
class AnalyticsButton extends ConsumerWidget {
  const AnalyticsButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.elementId,
    required this.screenName,
    this.elementType = 'button',
    this.userIntent,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String elementId;
  final String screenName;
  final String elementType;
  final String? userIntent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.read(analyticsServiceProvider);

    return GestureDetector(
      onTap: () {
        // Track the click
        analyticsService.trackClick(
          elementId: elementId,
          screenName: screenName,
          elementType: elementType,
          userIntent: userIntent,
        );

        // Execute the original callback
        onPressed?.call();
      },
      child: child,
    );
  }
}

/// Analytics-aware ElevatedButton
class AnalyticsElevatedButton extends ConsumerWidget {
  const AnalyticsElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.elementId,
    required this.screenName,
    this.userIntent,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String elementId;
  final String screenName;
  final String? userIntent;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.read(analyticsServiceProvider);

    return ElevatedButton(
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
              // Track the click
              analyticsService.trackClick(
                elementId: elementId,
                screenName: screenName,
                elementType: 'elevated_button',
                userIntent: userIntent,
              );

              // Execute the original callback
              onPressed?.call();
            },
      child: child,
    );
  }
}

/// Analytics-aware TextButton
class AnalyticsTextButton extends ConsumerWidget {
  const AnalyticsTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.elementId,
    required this.screenName,
    this.userIntent,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String elementId;
  final String screenName;
  final String? userIntent;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.read(analyticsServiceProvider);

    return TextButton(
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
              // Track the click
              analyticsService.trackClick(
                elementId: elementId,
                screenName: screenName,
                elementType: 'text_button',
                userIntent: userIntent,
              );

              // Execute the original callback
              onPressed?.call();
            },
      child: child,
    );
  }
}

/// Analytics-aware IconButton
class AnalyticsIconButton extends ConsumerWidget {
  const AnalyticsIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.elementId,
    required this.screenName,
    this.userIntent,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String elementId;
  final String screenName;
  final String? userIntent;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.read(analyticsServiceProvider);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              // Track the click
              analyticsService.trackClick(
                elementId: elementId,
                screenName: screenName,
                elementType: 'icon_button',
                userIntent: userIntent,
              );

              // Execute the original callback
              onPressed?.call();
            },
      icon: icon,
    );
  }
}
