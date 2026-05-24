import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Centralized animation system for consistent animations throughout the app
class AnimationSystem {
  // Standard durations
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);

  // Standard curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve snapCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  /// Create a standard fade animation
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = standardCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a standard scale animation
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = bounceCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a standard slide animation
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = standardCurve,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a rotation animation
  static Animation<double> createRotationAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = standardCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a size animation
  static Animation<double> createSizeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = standardCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a color animation
  static Animation<Color?> createColorAnimation(
    AnimationController controller, {
    required Color begin,
    required Color end,
    Curve curve = standardCurve,
  }) {
    return ColorTween(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );
  }

  /// Create a staggered animation sequence
  static List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int count, {
    double staggerDelay = 0.1,
    Curve curve = standardCurve,
  }) {
    final animations = <Animation<double>>[];

    for (var i = 0; i < count; i++) {
      final start = (i * staggerDelay).clamp(0.0, 1.0);
      final end = (start + (1.0 - start)).clamp(0.0, 1.0);

      animations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: curve),
          ),
        ),
      );
    }

    return animations;
  }

  /// Create a physics-based spring animation
  static AnimationController createSpringController(
    TickerProvider vsync, {
    double mass = 1.0,
    double stiffness = 100.0,
    double damping = 10.0,
  }) {
    final controller = AnimationController.unbounded(vsync: vsync);

    final spring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );

    final simulation = SpringSimulation(spring, 0.0, 1.0, 0.0);
    controller.animateWith(simulation);

    return controller;
  }

  /// Whether animations should play, respecting system accessibility preferences.
  /// Checks both [MediaQuery.disableAnimations] and [MediaQueryData.accessibleNavigation].
  static bool shouldAnimate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) return false;
    if (mediaQuery.accessibleNavigation) return false;
    return true;
  }

  /// Returns [Duration.zero] when animations are disabled, [fallback] otherwise.
  /// Use when building [AnimationController] durations.
  static Duration accessibleDuration(
      BuildContext context, Duration fallback) {
    return shouldAnimate(context) ? fallback : Duration.zero;
  }
}

/// Pre-built animation widgets for common use cases
class AnimatedWidgets {
  /// Animated fade-in widget
  static Widget fadeIn({
    required Widget child,
    Duration duration = AnimationSystem.normalDuration,
    Curve curve = AnimationSystem.standardCurve,
    Duration delay = Duration.zero,
  }) {
    return _AnimatedFadeIn(
      duration: duration,
      curve: curve,
      delay: delay,
      child: child,
    );
  }

  /// Animated slide-in widget
  static Widget slideIn({
    required Widget child,
    Duration duration = AnimationSystem.normalDuration,
    Curve curve = AnimationSystem.standardCurve,
    Offset begin = const Offset(0.0, 1.0),
    Duration delay = Duration.zero,
  }) {
    return _AnimatedSlideIn(
      duration: duration,
      curve: curve,
      begin: begin,
      delay: delay,
      child: child,
    );
  }

  /// Animated scale-in widget
  static Widget scaleIn({
    required Widget child,
    Duration duration = AnimationSystem.normalDuration,
    Curve curve = AnimationSystem.bounceCurve,
    double begin = 0.0,
    Duration delay = Duration.zero,
  }) {
    return _AnimatedScaleIn(
      duration: duration,
      curve: curve,
      begin: begin,
      delay: delay,
      child: child,
    );
  }

  /// Animated list with staggered children
  static Widget staggeredList({
    required List<Widget> children,
    Duration duration = AnimationSystem.normalDuration,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Curve curve = AnimationSystem.standardCurve,
    Axis direction = Axis.vertical,
  }) {
    return _StaggeredAnimatedList(
      duration: duration,
      staggerDelay: staggerDelay,
      curve: curve,
      direction: direction,
      children: children,
    );
  }

  /// Animated counter widget
  static Widget animatedCounter({
    required int value,
    Duration duration = AnimationSystem.normalDuration,
    Curve curve = AnimationSystem.standardCurve,
    TextStyle? style,
  }) {
    return _AnimatedCounter(
      value: value,
      duration: duration,
      curve: curve,
      style: style,
    );
  }

  /// Animated progress indicator with optional label and percentage
  static Widget animatedProgress({
    required double value,
    Duration duration = AnimationSystem.normalDuration,
    Curve curve = AnimationSystem.standardCurve,
    Color? color,
    Color? backgroundColor,
    double height = 4.0,
    String? label,
    bool showPercentage = false,
    double borderRadius = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final progress = _AnimatedProgress(
      value: value,
      duration: duration,
      curve: curve,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      borderRadius: borderRadius,
    );
    if (label == null && !showPercentage) {
      return Padding(padding: padding, child: progress);
    }
    return Padding(
      padding: padding,
      child: _LabeledProgress(
        value: value,
        duration: duration,
        curve: curve,
        color: color,
        label: label,
        showPercentage: showPercentage,
        progress: progress,
      ),
    );
  }
}

/// Internal animated fade-in widget
class _AnimatedFadeIn extends StatefulWidget {
  const _AnimatedFadeIn({
    required this.child,
    required this.duration,
    required this.curve,
    required this.delay,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation =
        AnimationSystem.createFadeAnimation(_controller, curve: widget.curve);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// Internal animated slide-in widget
class _AnimatedSlideIn extends StatefulWidget {
  const _AnimatedSlideIn({
    required this.child,
    required this.duration,
    required this.curve,
    required this.begin,
    required this.delay,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset begin;
  final Duration delay;

  @override
  State<_AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<_AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = AnimationSystem.createSlideAnimation(
      _controller,
      begin: widget.begin,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

/// Internal animated scale-in widget
class _AnimatedScaleIn extends StatefulWidget {
  const _AnimatedScaleIn({
    required this.child,
    required this.duration,
    required this.curve,
    required this.begin,
    required this.delay,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double begin;
  final Duration delay;

  @override
  State<_AnimatedScaleIn> createState() => _AnimatedScaleInState();
}

class _AnimatedScaleInState extends State<_AnimatedScaleIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = AnimationSystem.createScaleAnimation(
      _controller,
      begin: widget.begin,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Internal staggered animated list widget
class _StaggeredAnimatedList extends StatefulWidget {
  const _StaggeredAnimatedList({
    required this.children,
    required this.duration,
    required this.staggerDelay,
    required this.curve,
    required this.direction,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;
  final Axis direction;

  @override
  State<_StaggeredAnimatedList> createState() => _StaggeredAnimatedListState();
}

class _StaggeredAnimatedListState extends State<_StaggeredAnimatedList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final staggerDelayRatio =
        widget.staggerDelay.inMilliseconds / widget.duration.inMilliseconds;
    _animations = AnimationSystem.createStaggeredAnimations(
      _controller,
      widget.children.length,
      staggerDelay: staggerDelayRatio,
      curve: widget.curve,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            children: _buildAnimatedChildren(),
          )
        : Row(
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(widget.children.length, (index) {
      return AnimatedBuilder(
        animation: _animations[index],
        builder: (context, child) {
          return FadeTransition(
            opacity: _animations[index],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: widget.direction == Axis.vertical
                    ? const Offset(0.0, 0.5)
                    : const Offset(0.5, 0.0),
                end: Offset.zero,
              ).animate(_animations[index]),
              child: widget.children[index],
            ),
          );
        },
      );
    });
  }
}

/// Internal animated counter widget
class _AnimatedCounter extends StatefulWidget {
  const _AnimatedCounter({
    required this.value,
    required this.duration,
    required this.curve,
    this.style,
  });

  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.round().toString(),
          style: widget.style,
        );
      },
    );
  }
}

/// Internal animated progress widget
class _AnimatedProgress extends StatefulWidget {
  const _AnimatedProgress({
    required this.value,
    required this.duration,
    required this.curve,
    this.color,
    this.backgroundColor,
    required this.height,
    this.borderRadius = 0.0,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  @override
  State<_AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<_AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicator = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          color: widget.color,
          backgroundColor: widget.backgroundColor,
          minHeight: widget.height,
        );
      },
    );
    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: indicator,
      );
    }
    return indicator;
  }
}

class _LabeledProgress extends StatefulWidget {
  const _LabeledProgress({
    required this.value,
    required this.duration,
    required this.curve,
    required this.progress,
    this.color,
    this.label,
    this.showPercentage = false,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final Widget progress;
  final Color? color;
  final String? label;
  final bool showPercentage;

  @override
  State<_LabeledProgress> createState() => _LabeledProgressState();
}

class _LabeledProgressState extends State<_LabeledProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_LabeledProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    if (widget.label != null || widget.showPercentage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null || widget.showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Text(
                        '${(_animation.value * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: effectiveColor,
                        ),
                      );
                    },
                  ),
              ],
            ),
          if (widget.label != null || widget.showPercentage)
            const SizedBox(height: 6),
          widget.progress,
        ],
      );
    }
    return widget.progress;
  }
}
