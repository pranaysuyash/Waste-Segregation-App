import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/performance_optimizer.dart';

/// Gen Z-focused microinteractions for modern app feel
class GenZMicrointeractions {
  /// Bouncy success animation
  static Widget buildSuccessAnimation({
    required Widget child,
    required bool isVisible,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: duration,
      curve: PerformanceOptimizer.bouncyCurve,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: duration,
        child: child,
      ),
    );
  }

  /// Pulse animation for attention-grabbing elements
  static Widget buildPulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // Reverse the animation
      },
      child: child,
    );
  }

  /// Shimmer loading effect
  static Widget buildShimmerLoader({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// Floating action button with modern animations
  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    String? heroTag,
  }) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        PerformanceOptimizer.fastStateUpdate(onPressed);
      },
      backgroundColor: backgroundColor ?? Colors.blue,
      foregroundColor: foregroundColor ?? Colors.white,
      heroTag: heroTag,
      elevation: 8,
      child: AnimatedSwitcher(
        duration: PerformanceOptimizer.fastDuration,
        child: Icon(icon, key: ValueKey(icon)),
      ),
    );
  }

  /// Swipe-to-action card
  static Widget buildSwipeCard({
    required Widget child,
    required VoidCallback onSwipeLeft,
    required VoidCallback onSwipeRight,
    Color leftActionColor = Colors.red,
    Color rightActionColor = Colors.green,
    IconData leftIcon = Icons.delete,
    IconData rightIcon = Icons.check,
  }) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: leftActionColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(leftIcon, color: Colors.white, size: 30),
      ),
      secondaryBackground: Container(
        color: rightActionColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(rightIcon, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          onSwipeLeft();
        } else {
          onSwipeRight();
        }
      },
      child: child,
    );
  }

  /// Animated stat card with count-up effect
  static Widget buildAnimatedStatCard({
    required String title,
    required int value,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
    Duration animationDuration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: animationDuration,
      curve: PerformanceOptimizer.smoothCurve,
      builder: (context, animatedValue, child) {
        return Card(
          color: backgroundColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  animatedValue.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor?.withValues(alpha: 0.7) ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Morphing button that changes shape and content
  static Widget buildMorphingButton({
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget collapsedChild,
    required Widget expandedChild,
    Color? backgroundColor,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: duration,
        curve: PerformanceOptimizer.snappyCurve,
        width: isExpanded ? 200 : 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.blue,
          borderRadius: BorderRadius.circular(isExpanded ? 30 : 30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: duration,
          child: isExpanded ? expandedChild : collapsedChild,
        ),
      ),
    );
  }

  /// Particle burst effect for celebrations
  static Widget buildParticleBurst({
    required bool isActive,
    required Widget child,
    int particleCount = 20,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (isActive)
          ...List.generate(particleCount, (index) {
            final angle = (index * 360 / particleCount) * (3.14159 / 180);
            const distance = 50.0;

            return AnimatedPositioned(
              duration: duration,
              curve: Curves.easeOut,
              left: isActive ? distance * (index % 2 == 0 ? 1 : -1) : 0,
              top: isActive ? distance * (index % 3 == 0 ? 1 : -1) : 0,
              child: AnimatedOpacity(
                duration: duration,
                opacity: isActive ? 0.0 : 1.0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Smooth progress indicator with gradient
  static Widget buildGradientProgressBar({
    required double progress,
    required List<Color> gradientColors,
    double height = 8,
    BorderRadius? borderRadius,
    Duration animationDuration = const Duration(milliseconds: 500),
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        color: Colors.grey.shade200,
      ),
      child: AnimatedContainer(
        duration: animationDuration,
        curve: PerformanceOptimizer.smoothCurve,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            colors: gradientColors,
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                colors: gradientColors,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bouncy list item entrance animation
  static Widget buildBounceInListItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: PerformanceOptimizer.bouncyCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
