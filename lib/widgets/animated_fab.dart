import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Animated FAB with pulsing effects and celebratory animations
class AnimatedFAB extends StatefulWidget {

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.camera_alt,
    this.tooltip = 'Scan Waste',
    this.isPulsing = true,
    this.showCelebration = false,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final bool isPulsing;
  final bool showCelebration;

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late AnimationController _rippleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Celebration animation
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPulsing && !oldWidget.isPulsing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.showCelebration && !oldWidget.showCelebration) {
      _triggerCelebration();
    }
  }

  void _triggerCelebration() {
    _celebrationController.forward().then((_) {
      _celebrationController.reverse();
    });
  }

  void _onPressed() {
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    widget.onPressed();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _celebrationController,
        _rippleController,
      ]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            if (_rippleAnimation.value > 0)
              Container(
                width: 56 + (40 * _rippleAnimation.value),
                height: 56 + (40 * _rippleAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha:
                      0.5 * (1 - _rippleAnimation.value),
                    ),
                    width: 2,
                  ),
                ),
              ),

            // Pulse glow effect
            if (widget.isPulsing)
              Container(
                width: 56 + (20 * _pulseAnimation.value),
                height: 56 + (20 * _pulseAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha:
                        0.3 * _pulseAnimation.value,
                      ),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                  ],
                ),
              ),

            // Main FAB
            Transform.scale(
              scale: _pulseAnimation.value * _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: Semantics(
                  label: widget.tooltip ?? 'Camera shutter',
                  hint: 'Takes a photo',
                  button: true,
                  child: FloatingActionButton(
                    onPressed: _onPressed,
                    tooltip: widget.tooltip,
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(widget.icon),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Celebration particles
            if (widget.showCelebration)
              ...List.generate(8, (index) {
                final angle = (index * 45) * (3.14159 / 180);
                final distance = 60 * _celebrationController.value;
                return Positioned(
                  left: 28 + (distance * cos(angle)),
                  top: 28 + (distance * sin(angle)),
                  child: Transform.scale(
                    scale: _celebrationController.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getParticleColor(index),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Color _getParticleColor(int index) {
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

/// Flame streak animation widget for streaks
class FlameStreakWidget extends StatefulWidget {

  const FlameStreakWidget({
    super.key,
    required this.streakCount,
    this.isActive = true,
  });
  final int streakCount;
  final bool isActive;

  @override
  State<FlameStreakWidget> createState() => _FlameStreakWidgetState();
}

class _FlameStreakWidgetState extends State<FlameStreakWidget>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _flameAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _flameController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.orange,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _flameController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _flameController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FlameStreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _flameController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _flameController.stop();
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _flameController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _flameAnimation.value,
              child: Icon(
                Icons.local_fire_department,
                color: _colorAnimation.value,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.streakCount}',
              style: TextStyle(
                color: _colorAnimation.value,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Celebratory effects overlay
class CelebrationOverlay extends StatefulWidget {

  const CelebrationOverlay({
    super.key,
    required this.isVisible,
    this.message = 'Great job!',
    this.onComplete,
  });
  final bool isVisible;
  final String message;
  final VoidCallback? onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    if (widget.isVisible) {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0).then((_) {
        widget.onComplete?.call();
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
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha:0.3 * (1 - _fadeAnimation.value)),
              child: Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 