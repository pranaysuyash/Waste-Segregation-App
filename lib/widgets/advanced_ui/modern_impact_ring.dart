import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../utils/design_system.dart';

/// Modern, engaging impact ring designed specifically for waste segregation
/// Features smooth animations and environmental theming without going overboard
class ModernImpactRing extends StatefulWidget {
  final double progress;
  final double targetValue;
  final double currentValue;
  final String unit;
  final Color primaryColor;
  final Color accentColor;
  final String centerText;
  final String title;
  final String subtitle;
  final List<EnvironmentalMilestone> milestones;
  final bool showParticles;
  
  const ModernImpactRing({
    Key? key,
    required this.progress,
    required this.targetValue,
    required this.currentValue,
    this.unit = 'items',
    this.primaryColor = const Color(0xFF2E7D4A), // Your existing green
    this.accentColor = const Color(0xFF52C41A),
    this.centerText = '',
    this.title = 'Daily Goal',
    this.subtitle = 'Items classified today',
    this.milestones = const [],
    this.showParticles = false, // Subtle, not over the top
  }) : super(key: key);
  
  @override
  _ModernImpactRingState createState() => _ModernImpactRingState();
}

class _ModernImpactRingState extends State<ModernImpactRing>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Smooth but not excessive
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic, // Smooth, professional curve
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03, // Very subtle pulse
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }
  
  @override
  void didUpdateWidget(ModernImpactRing oldWidget) {
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
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _pulseController]),
      builder: (context, child) {
        return Column(
          children: [
            // Clean, professional title
            if (widget.title.isNotEmpty) ...[
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WasteAppDesignSystem.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
            ],
            
            // Main impact ring - clean and focused
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress ring
                    CustomPaint(
                      painter: CleanRingPainter(
                        progress: _progressAnimation.value,
                        primaryColor: widget.primaryColor,
                        accentColor: widget.accentColor,
                        milestones: widget.milestones,
                      ),\n                      size: const Size(200, 200),\n                    ),\n                    \n                    // Center content - clean and readable\n                    Container(\n                      width: 120,\n                      height: 120,\n                      decoration: BoxDecoration(\n                        shape: BoxShape.circle,\n                        color: Colors.white,\n                        boxShadow: [\n                          BoxShadow(\n                            color: Colors.black.withOpacity(0.08),\n                            blurRadius: 15,\n                            offset: const Offset(0, 5),\n                          ),\n                        ],\n                      ),\n                      child: Column(\n                        mainAxisAlignment: MainAxisAlignment.center,\n                        children: [\n                          // Current value - prominent but not flashy\n                          Text(\n                            widget.currentValue.toInt().toString(),\n                            style: TextStyle(\n                              fontSize: 32,\n                              fontWeight: FontWeight.w700,\n                              color: widget.primaryColor,\n                            ),\n                          ),\n                          \n                          // Target and unit\n                          Text(\n                            'of ${widget.targetValue.toInt()} ${widget.unit}',\n                            style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: WasteAppDesignSystem.darkGray,\n                              fontWeight: FontWeight.w500,\n                            ),\n                            textAlign: TextAlign.center,\n                          ),\n                          \n                          const SizedBox(height: 4),\n                          \n                          // Percentage - clean design\n                          Container(\n                            padding: const EdgeInsets.symmetric(\n                              horizontal: 8,\n                              vertical: 2,\n                            ),\n                            decoration: BoxDecoration(\n                              color: widget.accentColor.withOpacity(0.1),\n                              borderRadius: BorderRadius.circular(12),\n                            ),\n                            child: Text(\n                              '${(widget.progress * 100).toInt()}%',\n                              style: TextStyle(\n                                fontSize: 14,\n                                fontWeight: FontWeight.w600,\n                                color: widget.accentColor,\n                              ),\n                            ),\n                          ),\n                          \n                          // Center text if provided\n                          if (widget.centerText.isNotEmpty) ..[\n                            const SizedBox(height: 4),\n                            Text(\n                              widget.centerText,\n                              style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                                color: WasteAppDesignSystem.darkGray,\n                                fontSize: 10,\n                              ),\n                              textAlign: TextAlign.center,\n                            ),\n                          ],\n                        ],\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ),\n            \n            // Environmental milestones - relevant to waste management\n            if (widget.milestones.isNotEmpty) ..[\n              const SizedBox(height: 24),\n              _buildMilestonesSection(),\n            ],\n          ],\n        );\n      },\n    );\n  }\n  \n  Widget _buildMilestonesSection() {\n    return Container(\n      padding: const EdgeInsets.all(16),\n      decoration: BoxDecoration(\n        color: Colors.white,\n        borderRadius: BorderRadius.circular(16),\n        boxShadow: [\n          BoxShadow(\n            color: Colors.black.withOpacity(0.05),\n            blurRadius: 10,\n            offset: const Offset(0, 2),\n          ),\n        ],\n      ),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Row(\n            children: [\n              Icon(\n                Icons.eco,\n                color: widget.primaryColor,\n                size: 20,\n              ),\n              const SizedBox(width: 8),\n              Text(\n                'Environmental Impact',\n                style: Theme.of(context).textTheme.titleMedium?.copyWith(\n                  fontWeight: FontWeight.w600,\n                  color: widget.primaryColor,\n                ),\n              ),\n            ],\n          ),\n          const SizedBox(height: 12),\n          ...widget.milestones.map((milestone) => _buildMilestoneItem(milestone)),\n        ],\n      ),\n    );\n  }\n  \n  Widget _buildMilestoneItem(EnvironmentalMilestone milestone) {\n    final isReached = widget.progress >= milestone.threshold;\n    \n    return Padding(\n      padding: const EdgeInsets.symmetric(vertical: 6),\n      child: Row(\n        children: [\n          // Simple, clean milestone icon\n          Container(\n            padding: const EdgeInsets.all(6),\n            decoration: BoxDecoration(\n              color: isReached \n                  ? widget.primaryColor\n                  : WasteAppDesignSystem.lightGray,\n              shape: BoxShape.circle,\n            ),\n            child: Icon(\n              milestone.icon,\n              color: isReached \n                  ? Colors.white\n                  : WasteAppDesignSystem.darkGray,\n              size: 14,\n            ),\n          ),\n          \n          const SizedBox(width: 12),\n          \n          // Milestone info\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Text(\n                  milestone.title,\n                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                    fontWeight: FontWeight.w600,\n                    color: isReached \n                        ? widget.primaryColor\n                        : WasteAppDesignSystem.textBlack,\n                  ),\n                ),\n                Text(\n                  milestone.description,\n                  style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                    color: WasteAppDesignSystem.darkGray,\n                  ),\n                ),\n              ],\n            ),\n          ),\n          \n          // Simple progress indicator\n          if (isReached)\n            Icon(\n              Icons.check_circle,\n              color: widget.primaryColor,\n              size: 18,\n            )\n          else\n            Text(\n              '${(milestone.threshold * 100).toInt()}%',\n              style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                color: WasteAppDesignSystem.darkGray,\n                fontWeight: FontWeight.w500,\n              ),\n            ),\n        ],\n      ),\n    );\n  }\n}\n\n// Environmental milestone - relevant to waste management\nclass EnvironmentalMilestone {\n  final double threshold;\n  final String title;\n  final String description;\n  final IconData icon;\n\n  const EnvironmentalMilestone({\n    required this.threshold,\n    required this.title,\n    required this.description,\n    required this.icon,\n  });\n}\n\n// Clean, professional ring painter\nclass CleanRingPainter extends CustomPainter {\n  final double progress;\n  final Color primaryColor;\n  final Color accentColor;\n  final List<EnvironmentalMilestone> milestones;\n  \n  CleanRingPainter({\n    required this.progress,\n    required this.primaryColor,\n    required this.accentColor,\n    required this.milestones,\n  });\n  \n  @override\n  void paint(Canvas canvas, Size size) {\n    final center = Offset(size.width / 2, size.height / 2);\n    final radius = (size.width - 30) / 2;\n    final strokeWidth = 8.0;\n    \n    // Background ring - subtle\n    final backgroundPaint = Paint()\n      ..color = primaryColor.withOpacity(0.1)\n      ..style = PaintingStyle.stroke\n      ..strokeWidth = strokeWidth\n      ..strokeCap = StrokeCap.round;\n    \n    canvas.drawCircle(center, radius, backgroundPaint);\n    \n    // Progress ring - clean gradient\n    final progressPaint = Paint()\n      ..shader = LinearGradient(\n        colors: [primaryColor, accentColor],\n        begin: Alignment.topLeft,\n        end: Alignment.bottomRight,\n      ).createShader(Rect.fromCircle(center: center, radius: radius))\n      ..style = PaintingStyle.stroke\n      ..strokeWidth = strokeWidth\n      ..strokeCap = StrokeCap.round;\n    \n    canvas.drawArc(\n      Rect.fromCircle(center: center, radius: radius),\n      -math.pi / 2,\n      2 * math.pi * progress,\n      false,\n      progressPaint,\n    );\n    \n    // Simple milestone markers\n    for (final milestone in milestones) {\n      _drawMilestoneMarker(\n        canvas,\n        center,\n        radius,\n        milestone.threshold,\n        progress >= milestone.threshold,\n      );\n    }\n  }\n  \n  void _drawMilestoneMarker(\n    Canvas canvas,\n    Offset center,\n    double radius,\n    double threshold,\n    bool isReached,\n  ) {\n    final angle = -math.pi / 2 + 2 * math.pi * threshold;\n    final markerRadius = 4.0;\n    \n    final markerCenter = Offset(\n      center.dx + radius * math.cos(angle),\n      center.dy + radius * math.sin(angle),\n    );\n    \n    final markerPaint = Paint()\n      ..color = isReached ? accentColor : primaryColor.withOpacity(0.3)\n      ..style = PaintingStyle.fill;\n    \n    canvas.drawCircle(markerCenter, markerRadius, markerPaint);\n    \n    // Simple white border\n    final borderPaint = Paint()\n      ..color = Colors.white\n      ..style = PaintingStyle.stroke\n      ..strokeWidth = 2;\n    \n    canvas.drawCircle(markerCenter, markerRadius, borderPaint);\n  }\n  \n  @override\n  bool shouldRepaint(CleanRingPainter oldDelegate) {\n    return oldDelegate.progress != progress;\n  }\n}\n\n/// Clean, appropriate configurations for waste segregation app\nclass WasteImpactConfigurations {\n  \n  // Daily waste classification goal - clean and focused\n  static ModernImpactRing dailyWasteGoal({\n    required double itemsClassified,\n    required double dailyTarget,\n  }) {\n    return ModernImpactRing(\n      progress: itemsClassified / dailyTarget,\n      currentValue: itemsClassified,\n      targetValue: dailyTarget,\n      unit: 'items',\n      primaryColor: WasteAppDesignSystem.primaryGreen,\n      accentColor: WasteAppDesignSystem.secondaryGreen,\n      title: 'Daily Goal',\n      subtitle: 'Items classified today',\n      centerText: itemsClassified >= dailyTarget ? 'Goal achieved!' : 'Keep going!',\n      milestones: [\n        EnvironmentalMilestone(\n          threshold: 0.5,\n          title: 'Halfway There',\n          description: 'You\\'re making a difference!',\n          icon: Icons.trending_up,\n        ),\n        EnvironmentalMilestone(\n          threshold: 1.0,\n          title: 'Goal Complete',\n          description: 'Daily target achieved!',\n          icon: Icons.check_circle,\n        ),\n      ],\n    );\n  }\n  \n  // Environmental impact - appropriate messaging\n  static ModernImpactRing environmentalImpact({\n    required double co2Saved,\n    required double monthlyTarget,\n  }) {\n    return ModernImpactRing(\n      progress: co2Saved / monthlyTarget,\n      currentValue: co2Saved,\n      targetValue: monthlyTarget,\n      unit: 'kg CO\u2082 saved',\n      primaryColor: WasteAppDesignSystem.wetWasteColor,\n      accentColor: const Color(0xFF2E7D32),\n      title: 'Environmental Impact',\n      subtitle: 'CO\u2082 emissions prevented',\n      centerText: 'Helping the planet!',\n      milestones: [\n        EnvironmentalMilestone(\n          threshold: 0.25,\n          title: 'Great Start',\n          description: 'Every bit helps the environment',\n          icon: Icons.eco,\n        ),\n        EnvironmentalMilestone(\n          threshold: 0.75,\n          title: 'Eco Champion',\n          description: 'Significant environmental contribution',\n          icon: Icons.park,\n        ),\n      ],\n    );\n  }\n  \n  // Weekly progress - simple and clean\n  static ModernImpactRing weeklyProgress({\n    required double itemsThisWeek,\n    required double weeklyTarget,\n  }) {\n    return ModernImpactRing(\n      progress: itemsThisWeek / weeklyTarget,\n      currentValue: itemsThisWeek,\n      targetValue: weeklyTarget,\n      unit: 'items this week',\n      primaryColor: WasteAppDesignSystem.dryWasteColor,\n      accentColor: const Color(0xFF1976D2),\n      title: 'Weekly Progress',\n      subtitle: 'Items classified this week',\n    );\n  }\n}", "oldText": "                      size: const Size(200, 200),\n                    ),\n                    \n                    // Center content - clean and readable\n                    Container(\n                      width: 120,\n                      height: 120,\n                      decoration: BoxDecoration(\n                        shape: BoxShape.circle,\n                        color: Colors.white,\n                        boxShadow: [\n                          BoxShadow(\n                            color: Colors.black.withOpacity(0.08),\n                            blurRadius: 15,\n                            offset: const Offset(0, 5),\n                          ),\n                        ],\n                      ),\n                      child: Column(\n                        mainAxisAlignment: MainAxisAlignment.center,\n                        children: [\n                          // Current value - prominent but not flashy\n                          Text(\n                            widget.currentValue.toInt().toString(),\n                            style: TextStyle(\n                              fontSize: 32,\n                              fontWeight: FontWeight.w700,\n                              color: widget.primaryColor,\n                            ),\n                          ),\n                          \n                          // Target and unit\n                          Text(\n                            'of ${widget.targetValue.toInt()} ${widget.unit}',\n                            style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: WasteAppDesignSystem.darkGray,\n                              fontWeight: FontWeight.w500,\n                            ),\n                            textAlign: TextAlign.center,\n                          ),\n                          \n                          const SizedBox(height: 4),\n                          \n                          // Percentage - clean design\n                          Container(\n                            padding: const EdgeInsets.symmetric(\n                              horizontal: 8,\n                              vertical: 2,\n                            ),\n                            decoration: BoxDecoration(\n                              color: widget.accentColor.withOpacity(0.1),\n                              borderRadius: BorderRadius.circular(12),\n                            ),\n                            child: Text(\n                              '${(widget.progress * 100).toInt()}%',\n                              style: TextStyle(\n                                fontSize: 14,\n                                fontWeight: FontWeight.w600,\n                                color: widget.accentColor,\n                              ),\n                            ),\n                          ),\n                          \n                          // Center text if provided\n                          if (widget.centerText.isNotEmpty) ..[\n                            const SizedBox(height: 4),\n                            Text(\n                              widget.centerText,\n                              style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                                color: WasteAppDesignSystem.darkGray,\n                                fontSize: 10,\n                              ),\n                              textAlign: TextAlign.center,\n                            ),\n                          ],\n                        ],\n                      ),\n                    ),"}]