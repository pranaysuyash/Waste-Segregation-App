import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Performance optimizer for snappy Gen Z user experience
class PerformanceOptimizer {
  static const Duration _fastTransition = Duration(milliseconds: 200);
  static const Duration _mediumTransition = Duration(milliseconds: 300);
  static const Duration _slowTransition = Duration(milliseconds: 500);

  /// Optimized state update that feels instant
  static void fastStateUpdate(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Debounced state update to prevent lag
  static void debouncedUpdate(VoidCallback callback, {Duration delay = const Duration(milliseconds: 100)}) {
    Future.delayed(delay, callback);
  }

  /// Smooth animation curves for modern feel
  static const Curve snappyCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  /// Pre-built animation durations
  static Duration get fastDuration => _fastTransition;
  static Duration get mediumDuration => _mediumTransition;
  static Duration get slowDuration => _slowTransition;

  /// Optimized list building for large datasets
  static Widget buildOptimizedList<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: items.length,
      cacheExtent: 500, // Pre-cache items for smooth scrolling
      itemBuilder: (context, index) {
        if (index >= items.length) return const SizedBox.shrink();
        return itemBuilder(context, items[index], index);
      },
    );
  }

  /// Memory-efficient image loading
  static Widget buildOptimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error_outline, color: Colors.grey),
        );
      },
    );
  }

  /// Optimized button with haptic feedback
  static Widget buildSnappyButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: backgroundColor ?? Colors.blue,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          // Add haptic feedback for premium feel
          HapticFeedback.lightImpact();
          fastStateUpdate(onPressed);
        },
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  /// Smooth page transitions
  static PageRouteBuilder<T> createSmoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _fastTransition,
      reverseTransitionDuration: _fastTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: snappyCurve),
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Optimized setState wrapper
  static void optimizedSetState(State state, VoidCallback callback) {
    if (state.mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (state.mounted) {
          callback();
        }
      });
    }
  }
} 