import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Branded shimmer loading effect for modern loading states
class ShimmerLoading extends StatefulWidget {

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.enabled = true,
  });
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;
  final bool enabled;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.period,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? 
        theme.colorScheme.surfaceContainerHighest;
    final highlightColor = widget.highlightColor ?? 
        theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pre-built shimmer skeletons for common UI patterns
class ShimmerSkeleton {
  /// Card skeleton for loading cards
  static Widget card({
    double height = 120,
    double width = double.infinity,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }

  /// List item skeleton
  static Widget listItem({
    bool hasAvatar = true,
    bool hasSubtitle = true,
    bool hasTrailing = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (hasAvatar) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Text skeleton
  static Widget text({
    double height = 16,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }

  /// Button skeleton
  static Widget button({
    double height = 48,
    double width = 120,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  /// Image skeleton
  static Widget image({
    double height = 100,
    double width = 100,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }
} 