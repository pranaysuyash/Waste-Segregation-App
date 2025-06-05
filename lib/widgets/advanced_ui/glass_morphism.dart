import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// Glass morphism card with backdrop blur effect
class GlassMorphismCard extends StatelessWidget {
  
  const GlassMorphismCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.boxShadow,
  });
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final List<BoxShadow>? boxShadow;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? 
        (theme.brightness == Brightness.dark 
            ? Colors.white.withValues(alpha:opacity)
            : Colors.black.withValues(alpha:opacity));
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.2),
              ),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading effect for cards
class ShimmerCard extends StatefulWidget {
  
  const ShimmerCard({
    super.key,
    required this.child,
    this.shimmerColors = const [
      Color(0xFF845EC2),
      Color(0xFFFF6B6B),
    ],
    this.duration = const Duration(milliseconds: 2000),
    this.borderRadius,
  });
  final Widget child;
  final List<Color> shimmerColors;
  final Duration duration;
  final BorderRadius? borderRadius;
  
  @override
  _ShimmerCardState createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                widget.shimmerColors[0],
                widget.shimmerColors[1],
                widget.shimmerColors[0],
              ],
              stops: [
                math.max(0.0, _animation.value - 0.3),
                _animation.value,
                math.min(1.0, _animation.value + 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Morphing progress indicator with smooth transitions
class MorphingProgressIndicator extends StatefulWidget {
  
  const MorphingProgressIndicator({
    super.key,
    required this.progress,
    this.primaryColor = const Color(0xFF06FFA5),
    this.secondaryColor = const Color(0xFF00B4D8),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.height = 8.0,
    this.borderRadius = 8.0,
    this.child,
  });
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final Widget? child;
  
  @override
  _MorphingProgressIndicatorState createState() => _MorphingProgressIndicatorState();
}

class _MorphingProgressIndicatorState extends State<MorphingProgressIndicator>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }
  
  @override
  void didUpdateWidget(MorphingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.forward(from: 0);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Stack(
              children: [
                // Progress bar
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryColor,
                          widget.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha:0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Optional child content
                if (widget.child != null)
                  Center(child: widget.child!),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}