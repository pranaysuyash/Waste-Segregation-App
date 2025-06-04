import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Advanced floating particle system for background animations
/// Designed for Gen Z appeal with smooth, mesmerizing motion
class FloatingParticleSystem extends StatefulWidget {
  
  const FloatingParticleSystem({
    super.key,
    this.particleCount = 20,
    this.primaryColor = const Color(0xFF06FFA5),
    this.secondaryColor = const Color(0xFF00B4D8),
    this.particleSize = 4.0,
    this.animationSpeed = 1.0,
    this.isDarkMode = false,
  });
  final int particleCount;
  final Color primaryColor;
  final Color secondaryColor;
  final double particleSize;
  final double animationSpeed;
  final bool isDarkMode;
  
  @override
  _FloatingParticleSystemState createState() => _FloatingParticleSystemState();
}

class _FloatingParticleSystemState extends State<FloatingParticleSystem>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late List<Particle> _particles;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: (10 / widget.animationSpeed).round()),
      vsync: this,
    )..repeat();
    
    _initializeParticles();
  }
  
  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: widget.particleSize * (0.5 + random.nextDouble() * 1.5),
        speed: 0.1 + random.nextDouble() * 0.3,
        direction: random.nextDouble() * 2 * math.pi,
        opacity: 0.3 + random.nextDouble() * 0.4,
        color: Color.lerp(
          widget.primaryColor,
          widget.secondaryColor,
          random.nextDouble(),
        )!,
        phase: random.nextDouble() * 2 * math.pi,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticleSystemPainter(
            particles: _particles,
            animationValue: _controller.value,
            isDarkMode: widget.isDarkMode,
          ),
          size: Size.infinite,
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

class Particle {
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.direction,
    required this.opacity,
    required this.color,
    required this.phase,
  });
  double x;
  double y;
  final double size;
  final double speed;
  final double direction;
  final double opacity;
  final Color color;
  final double phase;
}

class ParticleSystemPainter extends CustomPainter {
  
  ParticleSystemPainter({
    required this.particles,
    required this.animationValue,
    required this.isDarkMode,
  });
  final List<Particle> particles;
  final double animationValue;
  final bool isDarkMode;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate animated position with organic movement
      final timeOffset = animationValue * 2 * math.pi;
      final breathingEffect = math.sin(timeOffset + particle.phase) * 0.3;
      final driftEffect = math.cos(timeOffset * 0.5 + particle.phase) * 0.2;
      
      final animatedX = (particle.x + 
          math.cos(particle.direction + timeOffset * particle.speed) * 0.1 +
          driftEffect) % 1.0;
      final animatedY = (particle.y + 
          math.sin(particle.direction + timeOffset * particle.speed) * 0.1 +
          breathingEffect * 0.5) % 1.0;
      
      // Dynamic opacity based on animation
      final dynamicOpacity = particle.opacity * 
          (0.7 + 0.3 * math.sin(timeOffset * 2 + particle.phase));
      
      // Adjust opacity for theme
      final themeAdjustedOpacity = isDarkMode ? 
          dynamicOpacity * 0.8 : dynamicOpacity * 0.6;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(themeAdjustedOpacity)
        ..style = PaintingStyle.fill;
      
      // Add subtle glow effect
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(themeAdjustedOpacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.5);
      
      final center = Offset(
        animatedX * size.width,
        animatedY * size.height,
      );
      
      final animatedSize = particle.size * (1.0 + breathingEffect * 0.2);
      
      // Draw glow
      canvas.drawCircle(center, animatedSize * 1.5, glowPaint);
      
      // Draw particle
      canvas.drawCircle(center, animatedSize, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticleSystemPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

/// Pulsing scan button with particle trail effect
class PulsingScanButton extends StatefulWidget {
  
  const PulsingScanButton({
    super.key,
    required this.onPressed,
    this.label = 'SCAN',
    this.icon = Icons.camera_alt_rounded,
    this.primaryColor = const Color(0xFF06FFA5),
    this.secondaryColor = const Color(0xFF00B4D8),
    this.size = 120.0,
  });
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;
  
  @override
  _PulsingScanButtonState createState() => _PulsingScanButtonState();
}

class _PulsingScanButtonState extends State<PulsingScanButton>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _particleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : _pulseAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor,
                    widget.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 20 * _pulseAnimation.value,
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particle trails
                  CustomPaint(
                    painter: ButtonParticleTrailPainter(
                      animationValue: _particleController.value,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    size: Size(widget.size, widget.size),
                  ),
                  
                  // Main button content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: widget.size * 0.25,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.size * 0.12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

class ButtonParticleTrailPainter extends CustomPainter {
  
  ButtonParticleTrailPainter({
    required this.animationValue,
    required this.color,
  });
  final double animationValue;
  final Color color;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw orbiting particles
    for (var i = 0; i < 6; i++) {
      final angle = (i * 2 * math.pi / 6) + (animationValue * 2 * math.pi);
      final particleRadius = radius * 0.7;
      final particlePosition = Offset(
        center.dx + math.cos(angle) * particleRadius,
        center.dy + math.sin(angle) * particleRadius,
      );
      
      final opacity = (math.sin(animationValue * 4 * math.pi + i) + 1) / 2;
      paint.color = color.withOpacity(opacity * 0.8);
      
      canvas.drawCircle(particlePosition, 2, paint);
    }
  }
  
  @override
  bool shouldRepaint(ButtonParticleTrailPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}