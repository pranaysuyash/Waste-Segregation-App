import 'dart:ui'; // Added for PathMetrics and PathMetric
import 'dart:math'; // Added for cos and sin
import 'package:flutter/material.dart';

/// Animation helpers for providing visual feedback in the app
class AnimationHelpers {
  /// Creates a particle burst animation effect
  /// Use this for celebrations like completing a classification or achievement
  static Widget createParticleBurst({
    required Color color,
    required double size,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animation: controller,
            color: color,
          ),
          size: Size(size, size),
        );
      },
    );
  }
  
  /// Creates a success checkmark animation
  static Widget createSuccessCheck({
    required Color color,
    required AnimationController controller,
    double size = 100,
  }) {
    // Animation for drawing the checkmark
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2 * animation.value),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: size * 0.6,
              height: size * 0.6,
              child: CustomPaint(
                painter: CheckmarkPainter(
                  animation: animation.value,
                  color: color,
                  strokeWidth: size * 0.08,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Creates a bouncing animation for UI elements
  static Animation<double> createBounceAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60.0,
      ),
    ]).animate(controller);
  }
  
  /// Creates a pulse animation for UI elements
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(controller);
  }
  
  /// Creates a progress animation with color transition
  static Animation<Color?> createProgressColorAnimation(
    AnimationController controller,
    Color startColor,
    Color endColor,
  ) {
    return ColorTween(
      begin: startColor,
      end: endColor,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ),
    );
  }
}

/// A custom painter that draws a checkmark animation
class CheckmarkPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.animation,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    final Path path = Path();
    
    // Define the checkmark path
    path.moveTo(width * 0.2, height * 0.5);
    path.lineTo(width * 0.45, height * 0.75);
    path.lineTo(width * 0.8, height * 0.25);

    // Use path metrics to animate the drawing of the path
    final PathMetrics pathMetrics = path.computeMetrics();
    
    // Guard against empty path metrics
    if (pathMetrics.isEmpty) {
      debugPrint('Warning: Path metrics is empty, skipping checkmark animation');
      return;
    }
    
    final PathMetric pathMetric = pathMetrics.first;
    
    final double length = pathMetric.length;
    final double animatedLength = length * animation;
    
    final Path animatedPath = pathMetric.extractPath(0, animatedLength);
    
    canvas.drawPath(animatedPath, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A custom painter that draws a burst of particles
class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final int particleCount;

  ParticlePainter({
    required this.animation,
    required this.color,
    this.particleCount = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double animationValue = animation.value;
    final Paint paint = Paint()
      ..color = color.withOpacity(1.0 - animationValue)
      ..style = PaintingStyle.fill;
    
    final double center = size.width / 2;
    
    for (int i = 0; i < particleCount; i++) {
      final double angle = i * (2 * 3.14159 / particleCount);
      final double distance = animationValue * size.width / 2;
      
      final double x = center + distance * cos(angle);
      final double y = center + distance * sin(angle);
      
      // Reduce particle size as they move outward
      final double particleSize = (1.0 - animationValue) * 8.0;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.color != color;
  }
}

/// Helper method to animate the size of a widget
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool autoPlay;
  final bool repeat;
  final VoidCallback? onComplete;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.elasticOut,
    this.autoPlay = true,
    this.repeat = false,
    this.onComplete,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: widget.curve)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: widget.curve)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    if (widget.autoPlay) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
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
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Helper method to animate the opacity and position of a widget
class FadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset startOffset;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutQuad,
    this.startOffset = const Offset(0.0, 50.0),
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<FadeSlideAnimation> createState() => _FadeSlideAnimationState();
}

class _FadeSlideAnimationState extends State<FadeSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoPlay) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
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
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
