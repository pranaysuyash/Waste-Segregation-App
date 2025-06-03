import 'package:flutter/material.dart';

/// Advanced Animation System for Waste Segregation App
/// Provides consistent animations, transitions, and micro-interactions
class WasteAppAnimations {
  // Animation Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Animation Curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  // Classification Result Reveal Animation
  static Widget buildClassificationReveal({
    required Widget child,
    required bool isVisible,
    Duration duration = medium,
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 0.3),
      duration: duration,
      curve: curve,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: AnimatedScale(
          scale: isVisible ? 1.0 : 0.95,
          duration: duration,
          curve: curve,
          child: child,
        ),
      ),
    );
  }

  // Staggered List Animation
  static Widget buildStaggeredListItem({
    required Widget child,
    required int index,
    required bool isVisible,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0.3, 0),
      duration: medium + (delay * index),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: medium + (delay * index),
        curve: easeOut,
        child: child,
      ),
    );
  }

  // Achievement Popup Animation
  static Widget buildAchievementPopup({
    required Widget child,
    required bool isVisible,
    VoidCallback? onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: extraSlow,
      curve: elasticOut,
      onEnd: onComplete,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: (1 - value) * 0.1,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // Points Earned Animation
  static Widget buildPointsAnimation({
    required int points,
    required bool isVisible,
    Duration duration = slow,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: duration,
      curve: bounceOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Transform.scale(
            scale: 0.5 + (0.5 * value),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Loading Skeleton Animation
  static Widget buildSkeletonLoader({
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * value), 0.0),
              end: Alignment(1.0 + (2.0 * value), 0.0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // Pressable Button Animation
  static Widget buildPressableButton({
    required Widget child,
    required VoidCallback onPressed,
    double scaleDown = 0.95,
    Duration duration = fast,
    Color? rippleColor,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        var isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: onPressed,
          child: AnimatedScale(
            scale: isPressed ? scaleDown : 1.0,
            duration: duration,
            curve: easeInOut,
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // Floating Action Button Animation
  static Widget buildFloatingButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isVisible,
  }) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: medium,
      curve: elasticOut,
      child: AnimatedRotation(
        turns: isVisible ? 0.0 : 0.25,
        duration: medium,
        curve: easeOutBack,
        child: GestureDetector(
          onTap: onPressed,
          child: child,
        ),
      ),
    );
  }

  // Page Transition Route
  static Route<T> createSlideRoute<T>(
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Scale Transition Route
  static Route<T> createScaleRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Rotation Transition
  static Widget buildRotationTransition({
    required Widget child,
    required bool isVisible,
    Duration duration = medium,
  }) {
    return AnimatedRotation(
      turns: isVisible ? 0.0 : 0.5,
      duration: duration,
      curve: easeInOut,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: duration,
        child: child,
      ),
    );
  }

  // Shimmer Loading Effect
  static Widget buildShimmerEffect({
    required Widget child,
    required bool isLoading,
    Color? baseColor,
    Color? highlightColor,
  }) {
    if (!isLoading) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (2.0 * value), 0.0),
              end: Alignment(1.0 + (2.0 * value), 0.0),
              colors: [
                baseColor ?? Colors.grey.shade300,
                highlightColor ?? Colors.grey.shade100,
                baseColor ?? Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  // Progress Indicator Animation
  static Widget buildProgressAnimation({
    required double progress,
    required Color color,
    Duration duration = medium,
    double height = 4.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: duration,
      curve: easeOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Bounce Animation
  static Widget buildBounceAnimation({
    required Widget child,
    required bool isVisible,
    Duration duration = slow,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: duration,
      curve: bounceOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Typing Animation for Text
  static Widget buildTypingAnimation({
    required String text,
    required bool isVisible,
    Duration duration = const Duration(milliseconds: 50),
    TextStyle? style,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: isVisible ? text.length : 0),
      duration: duration * text.length,
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: style,
        );
      },
    );
  }

  // Slide and Fade List Item Animation
  static Widget buildListItemAnimation({
    required Widget child,
    required int index,
    required bool isVisible,
    Duration baseDuration = medium,
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final delay = staggerDelay * index;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: baseDuration + delay,
      curve: easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Points Earned Popup Widget
class PointsEarnedPopup extends StatelessWidget {

  const PointsEarnedPopup({
    super.key,
    required this.points,
    required this.action,
    required this.onDismiss,
  });
  final int points;
  final String action;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return WasteAppAnimations.buildAchievementPopup(
      isVisible: true,
      onComplete: () {
        // Auto-dismiss after animation completes
        Future.delayed(const Duration(seconds: 2), onDismiss);
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                '+$points Points!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job on $action!',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading Screen with Enhanced Animations
class AnimatedLoadingScreen extends StatelessWidget {

  const AnimatedLoadingScreen({
    super.key,
    this.message = 'Loading...',
    this.color,
  });
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WasteAppAnimations.buildBounceAnimation(
              isVisible: true,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  color ?? Theme.of(context).primaryColor,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            WasteAppAnimations.buildTypingAnimation(
              text: message,
              isVisible: true,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Card Widget with Animations
class AnimatedCard extends StatelessWidget {

  const AnimatedCard({
    super.key,
    required this.child,
    this.isVisible = true,
    this.index = 0,
    this.onTap,
    this.margin,
    this.elevation = 2,
  });
  final Widget child;
  final bool isVisible;
  final int index;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return WasteAppAnimations.buildListItemAnimation(
      index: index,
      isVisible: isVisible,
      child: Card(
        elevation: elevation,
        margin: margin ?? const EdgeInsets.all(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
