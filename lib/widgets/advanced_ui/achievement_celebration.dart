import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/gamification.dart';

/// Epic achievement celebration with confetti and 3D badge effect
class AchievementCelebration extends StatefulWidget {
  
  const AchievementCelebration({
    super.key,
    required this.achievement,
    required this.onDismiss,
    this.duration = const Duration(seconds: 4),
  });
  final Achievement achievement;
  final VoidCallback onDismiss;
  final Duration duration;
  
  @override
  _AchievementCelebrationState createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _badgeController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  List<ConfettiParticle> _confettiParticles = [];
  
  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    ));
    
    _initializeConfetti();
    _startCelebration();
  }
  
  void _initializeConfetti() {
    final random = math.Random();
    _confettiParticles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1,
        velocityX: (random.nextDouble() - 0.5) * 0.5,
        velocityY: random.nextDouble() * 0.3 + 0.2,
        size: random.nextDouble() * 6 + 2,
        color: _getConfettiColors()[random.nextInt(_getConfettiColors().length)],
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      );
    });
  }
  
  List<Color> _getConfettiColors() {
    return [
      Colors.amber,
      Colors.orange,
      widget.achievement.color,
      Colors.white,
      const Color(0xFF06FFA5),
      const Color(0xFF00B4D8),
      const Color(0xFFFF6B6B),
    ];
  }
  
  void _startCelebration() async {
    HapticFeedback.heavyImpact();
    _mainController.forward();
    _confettiController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _badgeController.forward();
    
    Future.delayed(widget.duration, () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Reward confetti',
      hint: 'Celebrates your achievement',
      child: Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _confettiController]),
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _opacityAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Container(color: Colors.black.withValues(alpha:0.7)),
                  CustomPaint(
                    painter: ConfettiPainter(
                      particles: _confettiParticles,
                      animationValue: _confettiController.value,
                    ),
                    size: Size.infinite,
                  ),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildCelebrationCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCelebrationCard() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.achievement.color.withValues(alpha:0.1),
            Colors.white,
            widget.achievement.color.withValues(alpha:0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.achievement.color.withValues(alpha:0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎉 ACHIEVEMENT UNLOCKED! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.achievement.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildBadge(),
          const SizedBox(height: 24),
          Text(
            widget.achievement.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.achievement.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+${widget.achievement.pointsReward} Points',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadge() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            widget.achievement.color.withValues(alpha:0.8),
            widget.achievement.color,
            widget.achievement.color.withValues(alpha:0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.achievement.color.withValues(alpha:0.4),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getAchievementIcon(),
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
  
  IconData _getAchievementIcon() {
    switch (widget.achievement.iconName) {
      case 'emoji_objects': return Icons.lightbulb;
      case 'recycling': return Icons.recycling;
      case 'workspace_premium': return Icons.workspace_premium;
      case 'category': return Icons.category;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'event_available': return Icons.event_available;
      case 'emoji_events': return Icons.emoji_events;
      case 'school': return Icons.school;
      case 'quiz': return Icons.quiz;
      case 'eco': return Icons.eco;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'military_tech': return Icons.military_tech;
      default: return Icons.emoji_events;
    }
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _badgeController.dispose();
    super.dispose();
  }
}

class ConfettiParticle {
  
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
  double x;
  double y;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;
}

class ConfettiPainter extends CustomPainter {
  
  ConfettiPainter({
    required this.particles,
    required this.animationValue,
  });
  final List<ConfettiParticle> particles;
  final double animationValue;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = animationValue;
      final x = (particle.x + particle.velocityX * progress) * size.width;
      final y = (particle.y + particle.velocityY * progress) * size.height;
      
      if (y > size.height + 50) continue;
      
      final rotation = particle.rotation + particle.rotationSpeed * progress * 10;
      final opacity = math.max(0.0, 1.0 - (y / size.height));
      
      final paint = Paint()
        ..color = particle.color.withValues(alpha:opacity)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      final shapeType = particle.color.hashCode % 3;
      switch (shapeType) {
        case 0:
          canvas.drawCircle(Offset.zero, particle.size, paint);
          break;
        case 1:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 2,
              height: particle.size * 2,
            ),
            paint,
          );
          break;
        case 2:
          final path = Path();
          path.moveTo(0, -particle.size);
          path.lineTo(-particle.size, particle.size);
          path.lineTo(particle.size, particle.size);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Points earned popup with bounce animation
class PointsEarnedPopup extends StatefulWidget {
  
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
  _PointsEarnedPopupState createState() => _PointsEarnedPopupState();
}

class _PointsEarnedPopupState extends State<PointsEarnedPopup>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -50.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));
    
    _controller.forward().then((_) {
      widget.onDismiss();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha:0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.points}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}