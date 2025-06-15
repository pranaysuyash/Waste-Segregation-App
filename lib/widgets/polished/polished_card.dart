import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

/// Enhanced card with modern shadows, micro-interactions, and polish
class PolishedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final Duration animationDuration;

  const PolishedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.shadowColor,
    this.borderRadius,
    this.backgroundColor,
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<PolishedCard> createState() => _PolishedCardState();
}

class _PolishedCardState extends State<PolishedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppThemePolish.scalePressed,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScaleAnimation && widget.onTap != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation && widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation && widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = Container(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      child: Material(
        elevation: widget.elevation ?? AppThemePolish.elevationSubtle,
        shadowColor: widget.shadowColor ?? AppThemePolish.shadowColorLight,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(16.0),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.enableScaleAnimation && widget.onTap != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: card,
          );
        },
      );
    }

    return card;
  }
} 