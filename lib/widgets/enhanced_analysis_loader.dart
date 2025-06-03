import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../utils/performance_optimizer.dart';
import 'gen_z_microinteractions.dart';

/// Enhanced analysis loader that makes 14-20 second waits engaging
/// Provides multi-step progress, educational content, and smooth animations
class EnhancedAnalysisLoader extends StatefulWidget {
  
  const EnhancedAnalysisLoader({
    super.key,
    this.imageName,
    this.onCancel,
    this.estimatedDuration = const Duration(seconds: 17), // Average of 14-20s
    this.showEducationalTips = true,
  });
  final String? imageName;
  final VoidCallback? onCancel;
  final Duration estimatedDuration;
  final bool showEducationalTips;

  @override
  State<EnhancedAnalysisLoader> createState() => _EnhancedAnalysisLoaderState();
}

class _EnhancedAnalysisLoaderState extends State<EnhancedAnalysisLoader>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _stepTimer;
  Timer? _tipTimer;
  
  int _currentStep = 0;
  int _currentTipIndex = 0;
  double _estimatedProgress = 0.0;
  
  final List<AnalysisStep> _analysisSteps = [
    const AnalysisStep(
      title: 'Uploading Image',
      description: 'Securely transferring your image...',
      icon: Icons.cloud_upload_outlined,
      duration: Duration(seconds: 3),
      color: Colors.blue,
    ),
    const AnalysisStep(
      title: 'AI Processing',
      description: 'Our AI is analyzing your waste item...',
      icon: Icons.psychology_outlined,
      duration: Duration(seconds: 8),
      color: AppTheme.primaryColor,
    ),
    const AnalysisStep(
      title: 'Classification',
      description: 'Determining the best disposal method...',
      icon: Icons.category_outlined,
      duration: Duration(seconds: 4),
      color: Colors.orange,
    ),
    const AnalysisStep(
      title: 'Finalizing Results',
      description: 'Preparing your personalized recommendations...',
      icon: Icons.check_circle_outline,
      duration: Duration(seconds: 2),
      color: Colors.green,
    ),
  ];
  
  final List<String> _educationalTips = [
    '💡 Did you know? Recycling one aluminum can saves enough energy to power a TV for 3 hours!',
    '🌱 Composting food waste can reduce methane emissions by up to 50%',
    '♻️ Glass can be recycled infinitely without losing quality or purity',
    '🌍 Proper waste sorting can increase recycling rates by up to 40%',
    '🔋 E-waste contains valuable metals like gold, silver, and copper',
    '🌿 Organic waste makes up about 30% of household garbage',
    '📱 One recycled smartphone can recover enough gold to make a ring',
    '🌊 Plastic bottles can take up to 450 years to decompose naturally',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnalysisSimulation();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: widget.estimatedDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _progressController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();
  }

  void _startAnalysisSimulation() {
    // Simulate step progression
    var totalDuration = 0;
    for (var i = 0; i < _analysisSteps.length; i++) {
      Timer(Duration(seconds: totalDuration), () {
        if (mounted) {
          setState(() {
            _currentStep = i;
          });
        }
      });
      totalDuration += _analysisSteps[i].duration.inSeconds;
    }
    
    // Update progress estimation every 500ms
    _stepTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _estimatedProgress = _progressAnimation.value;
        });
      }
    });
    
    // Rotate educational tips every 4 seconds
    if (widget.showEducationalTips) {
      _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentTipIndex = (_currentTipIndex + 1) % _educationalTips.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _stepTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main analysis animation
          _buildMainAnalysisAnimation(),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Current step indicator
          _buildCurrentStepIndicator(),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Progress bar with steps
          _buildStepProgressBar(),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Educational tip (if enabled)
          if (widget.showEducationalTips)
            _buildEducationalTip(),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Cancel button (if provided)
          if (widget.onCancel != null)
            _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildMainAnalysisAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _particleController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Particle background
            CustomPaint(
              size: const Size(200, 200),
              painter: AnalysisParticlePainter(
                animationValue: _particleController.value,
                color: _getCurrentStepColor(),
              ),
            ),
            
            // Pulsing main circle
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getCurrentStepColor().withOpacity(0.3),
                      _getCurrentStepColor().withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getCurrentStepColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentStepColor().withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCurrentStepIcon(),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStepIndicator() {
    final currentStep = _getCurrentStep();
    
    return GenZMicrointeractions.buildSuccessAnimation(
      isVisible: true,
      child: Column(
        children: [
          Text(
            currentStep.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: currentStep.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          Text(
            currentStep.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade200,
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        _getCurrentStepColor(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: AppTheme.paddingSmall),
        
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_analysisSteps.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isCurrent
                    ? _analysisSteps[index].color
                    : Colors.grey.shade300,
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: _analysisSteps[index].color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        
        const SizedBox(height: AppTheme.paddingSmall),
        
        // Time estimate
        Text(
          '${(_estimatedProgress * 100).round()}% Complete • ${_getRemainingTime()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildEducationalTip() {
    return GenZMicrointeractions.buildSuccessAnimation(
      isVisible: true,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.paddingSmall),
            Expanded(
              child: Text(
                _educationalTips[_currentTipIndex],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return PerformanceOptimizer.buildSnappyButton(
      onPressed: widget.onCancel!,
      backgroundColor: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.close,
            color: Colors.grey.shade600,
            size: 18,
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Text(
            'Cancel Analysis',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  AnalysisStep _getCurrentStep() {
    return _analysisSteps[_currentStep.clamp(0, _analysisSteps.length - 1)];
  }

  Color _getCurrentStepColor() {
    return _getCurrentStep().color;
  }

  IconData _getCurrentStepIcon() {
    return _getCurrentStep().icon;
  }

  String _getRemainingTime() {
    final remainingSeconds = ((1.0 - _estimatedProgress) * widget.estimatedDuration.inSeconds).round();
    if (remainingSeconds <= 0) return 'Almost done...';
    if (remainingSeconds < 60) return '${remainingSeconds}s remaining';
    return '${(remainingSeconds / 60).ceil()}m remaining';
  }
}

/// Data class for analysis steps
class AnalysisStep {

  const AnalysisStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
    required this.color,
  });
  final String title;
  final String description;
  final IconData icon;
  final Duration duration;
  final Color color;
}

/// Custom painter for floating particles around the analysis animation
class AnalysisParticlePainter extends CustomPainter {
  
  AnalysisParticlePainter({
    required this.animationValue,
    required this.color,
  });
  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw floating particles
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) + (animationValue * math.pi * 2);
      final particleRadius = radius * 0.7;
      final particleSize = 3.0 + (math.sin(animationValue * math.pi * 4 + i) * 2);
      
      final particleCenter = Offset(
        center.dx + math.cos(angle) * particleRadius,
        center.dy + math.sin(angle) * particleRadius,
      );
      
      canvas.drawCircle(particleCenter, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(AnalysisParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
} 