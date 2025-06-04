import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/design_system.dart';

/// Represents a milestone in the impact journey
class ImpactMilestone {

  const ImpactMilestone({
    required this.threshold,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isReached = false,
  });
  final double threshold;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isReached;
}

/// Advanced impact ring with animated progress and environmental storytelling
class ImpactVisualizationRing extends StatefulWidget {
  
  const ImpactVisualizationRing({
    super.key,
    required this.progress,
    required this.targetValue,
    required this.currentValue,
    this.unit = 'items',
    this.primaryColor = const Color(0xFF06FFA5),
    this.secondaryColor = const Color(0xFF00B4D8),
    this.centerText = '',
    this.milestones = const [],
    this.title = 'Environmental Impact',
    this.subtitle = 'Keep up the great work!',
  });
  final double progress;
  final double targetValue;
  final double currentValue;
  final String unit;
  final Color primaryColor;
  final Color secondaryColor;
  final String centerText;
  final List<ImpactMilestone> milestones;
  final String title;
  final String subtitle;
  
  @override
  _ImpactVisualizationRingState createState() => _ImpactVisualizationRingState();
}

class _ImpactVisualizationRingState extends State<ImpactVisualizationRing>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _milestoneController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _milestoneController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
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
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }
  
  @override
  void didUpdateWidget(ImpactVisualizationRing oldWidget) {
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
      
      // Trigger milestone animation if we crossed a milestone
      _checkMilestones(oldWidget.progress, widget.progress);
    }
  }
  
  void _checkMilestones(double oldProgress, double newProgress) {
    for (final milestone in widget.milestones) {
      if (oldProgress < milestone.threshold && newProgress >= milestone.threshold) {
        _milestoneController.forward(from: 0);
        break;
      }
    }
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressController,
        _pulseController,
        _milestoneController,
      ]),
      builder: (context, child) {
        return Column(
          children: [
            // Title and subtitle
            if (widget.title.isNotEmpty) ...[
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: WasteAppDesignSystem.spacingXS),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WasteAppDesignSystem.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: WasteAppDesignSystem.spacingL),
            ],
            
            // Main impact ring
            Transform.scale(
              scale: _pulseAnimation.value,
              child: CustomPaint(
                painter: ImpactRingPainter(
                  progress: _progressAnimation.value,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  glowIntensity: _glowAnimation.value,
                  milestones: widget.milestones,
                  milestoneAnimation: _milestoneController.value,
                ),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Current value
                        Text(
                          '${widget.currentValue.toInt()}',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                        
                        // Target and unit
                        Text(
                          'of ${widget.targetValue.toInt()} ${widget.unit}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WasteAppDesignSystem.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Percentage
                        const SizedBox(height: WasteAppDesignSystem.spacingXS),
                        Text(
                          '${(widget.progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        // Center text if provided
                        if (widget.centerText.isNotEmpty) ...[
                          const SizedBox(height: WasteAppDesignSystem.spacingXS),
                          Text(
                            widget.centerText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WasteAppDesignSystem.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Milestones indicator
            if (widget.milestones.isNotEmpty) ...[
              const SizedBox(height: WasteAppDesignSystem.spacingL),
              _buildMilestonesIndicator(),
            ],
          ],
        );
      },
    );
  }
  
  Widget _buildMilestonesIndicator() {
    return Container(
      padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
      decoration: WasteAppDesignSystem.getCardDecoration(
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WasteAppDesignSystem.spacingS),
          ...widget.milestones.map((milestone) => _buildMilestoneItem(milestone)),
        ],
      ),
    );
  }
  
  Widget _buildMilestoneItem(ImpactMilestone milestone) {
    final isReached = widget.progress >= milestone.threshold;
    final isActive = widget.progress >= milestone.threshold - 0.1 && 
                     widget.progress <= milestone.threshold + 0.1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WasteAppDesignSystem.spacingXS),
      child: Row(
        children: [
          // Milestone icon
          Container(
            padding: const EdgeInsets.all(WasteAppDesignSystem.spacingS),
            decoration: BoxDecoration(
              color: isReached 
                  ? milestone.color.withOpacity(0.2)
                  : WasteAppDesignSystem.lightGray,
              shape: BoxShape.circle,
              border: isActive 
                  ? Border.all(color: milestone.color, width: 2)
                  : null,
            ),
            child: Icon(
              milestone.icon,
              color: isReached 
                  ? milestone.color
                  : WasteAppDesignSystem.darkGray,
              size: 20,
            ),
          ),
          
          const SizedBox(width: WasteAppDesignSystem.spacingM),
          
          // Milestone info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isReached 
                        ? milestone.color
                        : WasteAppDesignSystem.textBlack,
                  ),
                ),
                Text(
                  milestone.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WasteAppDesignSystem.darkGray,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress indicator
          if (isReached)
            Icon(
              Icons.check_circle,
              color: milestone.color,
              size: 20,
            )
          else
            Text(
              '${(milestone.threshold * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WasteAppDesignSystem.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the impact ring
class ImpactRingPainter extends CustomPainter {
  
  ImpactRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.milestones,
    required this.milestoneAnimation,
  });
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final List<ImpactMilestone> milestones;
  final double milestoneAnimation;
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 40) / 2;
    const strokeWidth = 12.0;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(glowIntensity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
    
    // Draw progress arc with gradient effect
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
    
    // Draw milestone markers
    for (final milestone in milestones) {
      _drawMilestoneMarker(
        canvas,
        center,
        radius,
        milestone.threshold,
        milestone.color,
        progress >= milestone.threshold,
      );
    }
  }
  
  void _drawMilestoneMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double threshold,
    Color color,
    bool isReached,
  ) {
    final angle = -math.pi / 2 + 2 * math.pi * threshold;
    final markerRadius = isReached ? 8.0 : 6.0;
    
    final markerCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    
    // Draw marker glow if reached
    if (isReached) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(markerCenter, markerRadius + 2, glowPaint);
    }
    
    // Draw marker
    final markerPaint = Paint()
      ..color = isReached ? color : color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(markerCenter, markerRadius, markerPaint);
    
    // Draw marker border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(markerCenter, markerRadius, borderPaint);
  }
  
  @override
  bool shouldRepaint(ImpactRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.milestoneAnimation != milestoneAnimation;
  }
}
