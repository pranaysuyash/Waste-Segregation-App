import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/gamification.dart';
import '../utils/animation_helpers.dart';
import '../utils/waste_app_logger.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';

/// Enhanced version of the points indicator with animations and level-up effects
class EnhancedPointsIndicator extends StatefulWidget {
  const EnhancedPointsIndicator({
    super.key,
    required this.points,
    this.previousPoints,
    this.onTap,
  });
  final UserPoints points;
  final UserPoints? previousPoints;
  final VoidCallback? onTap;

  @override
  State<EnhancedPointsIndicator> createState() => _EnhancedPointsIndicatorState();
}

class _EnhancedPointsIndicatorState extends State<EnhancedPointsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animate the progress bar
    _progressAnimation = Tween<double>(
      begin: widget.previousPoints != null ? (widget.previousPoints!.total % 100) / 100 : 0.0,
      end: (widget.points.total % 100) / 100,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Animate the level badge scale
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60.0,
      ),
    ]).animate(_animationController);

    // Start the animation
    _animationController.forward();
  }

  @override
  void didUpdateWidget(EnhancedPointsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect level up
    if (oldWidget.points.level != widget.points.level) {
      // Reset and replay animation for level up effect
      _animationController.reset();
      _animationController.forward();
    } else if (oldWidget.points.total != widget.points.total) {
      // Animate to the new progress
      _progressAnimation = Tween<double>(
        begin: (oldWidget.points.total % 100) / 100,
        end: (widget.points.total % 100) / 100,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );

      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLevelUp = widget.previousPoints != null && widget.points.level > widget.previousPoints!.level;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isLevelUp)
            AnimationHelpers.createParticleBurst(
              color: AppTheme.primaryColor,
              size: 150,
              controller: _animationController,
            ),
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated level badge
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isLevelUp ? _scaleAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: isLevelUp
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '${widget.points.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppTheme.paddingSmall / 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.points.total}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.previousPoints != null && widget.points.total > widget.previousPoints!.total)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              ' (+${widget.points.total - widget.previousPoints!.total})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 60,
                      height: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                  child: LinearProgressIndicator(
                                    value: _progressAnimation.value,
                                    minHeight: 4,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!isLevelUp && widget.points.pointsToNextLevel > 0)
                            Positioned(
                              top: 5,
                              right: 0,
                              child: Text(
                                '${widget.points.pointsToNextLevel} to LVL ${widget.points.level + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          if (isLevelUp)
                            const Positioned(
                              top: 5,
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 8,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'LEVEL UP!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A classification feedback effect for immediate user gratification
class ClassificationFeedback extends StatefulWidget {
  const ClassificationFeedback({
    super.key,
    required this.category,
    this.onComplete,
  });
  final String category;
  final VoidCallback? onComplete;

  @override
  State<ClassificationFeedback> createState() => _ClassificationFeedbackState();
}

class _ClassificationFeedbackState extends State<ClassificationFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animationController.forward();

    // Call onComplete when animation finishes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center, // Center stack children
          children: [
            // Success checkmark
            AnimationHelpers.createSuccessCheck(
              color: _getCategoryColor(widget.category),
              controller: _animationController,
              size: 120,
            ),

            // Particle effect
            AnimationHelpers.createParticleBurst(
              color: _getCategoryColor(widget.category),
              size: 200,
              controller: _animationController,
            ),

            // Category text with fade-in animation
            Positioned(
              bottom: 40,
              child: Opacity(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                ).value,
                child: Column(
                  // Removed Center, Positioned handles alignment
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Successfully Classified!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeMedium,
                        color: _getCategoryColor(widget.category),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingRegular,
                        vertical: AppTheme.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(widget.category),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                      ),
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return AppTheme.wetWasteColor;
      case 'dry waste':
        return AppTheme.dryWasteColor;
      case 'hazardous waste':
        return AppTheme.hazardousWasteColor;
      case 'medical waste':
        return AppTheme.medicalWasteColor;
      case 'non-waste':
        return AppTheme.nonWasteColor;
      default:
        return AppTheme.primaryColor; // Fallback to primary color
    }
  }
}

/// A popup that displays when a user earns points.
class PointsEarnedPopup extends StatefulWidget {
  const PointsEarnedPopup({
    super.key,
    required this.points,
    required this.action,
    this.onDismiss,
  });

  final int points;
  final String action;
  final VoidCallback? onDismiss;

  @override
  State<PointsEarnedPopup> createState() => _PointsEarnedPopupState();
}

class _PointsEarnedPopupState extends State<PointsEarnedPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto-dismiss if onDismiss is provided
    if (widget.onDismiss != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          widget.onDismiss!();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${widget.points} Points',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'For ${widget.action}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A popup that displays when a user completes a challenge.
class ChallengeCompletedPopup extends StatefulWidget {
  const ChallengeCompletedPopup({
    super.key,
    required this.challenge,
    this.onDismiss,
  });

  final Challenge challenge;
  final VoidCallback? onDismiss;

  @override
  State<ChallengeCompletedPopup> createState() => _ChallengeCompletedPopupState();
}

class _ChallengeCompletedPopupState extends State<ChallengeCompletedPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    if (widget.onDismiss != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          widget.onDismiss!();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.fromString(widget.challenge.iconName),
                  color: widget.challenge.color,
                  size: 50,
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                const Text(
                  'Challenge Completed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  widget.challenge.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                Text(
                  widget.challenge.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                Chip(
                  avatar: const Icon(Icons.star, color: Colors.amber),
                  label: Text(
                    '+${widget.challenge.pointsReward} Points',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show a floating achievement badge during gameplay
class FloatingAchievementBadge extends StatefulWidget {
  const FloatingAchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
  });
  final Achievement achievement;
  final VoidCallback? onTap;

  @override
  State<FloatingAchievementBadge> createState() => _FloatingAchievementBadgeState();
}

class _FloatingAchievementBadgeState extends State<FloatingAchievementBadge> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Duration for the entire sequence
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        // Bounce in from top
        tween: Tween<double>(begin: -50.0, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)), // Elastic effect
        weight: 30.0, // % of total duration
      ),
      TweenSequenceItem(
        // Hold position
        tween: ConstantTween<double>(0.0),
        weight: 40.0,
      ),
      TweenSequenceItem(
        // Float up and out
        tween: Tween<double>(begin: 0.0, end: -50.0).chain(CurveTween(curve: Curves.easeInBack)), // Smooth exit
        weight: 30.0,
      ),
    ]).animate(_animationController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        // Fade in
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15.0, // Quick fade in
      ),
      TweenSequenceItem(
        // Hold opacity
        tween: ConstantTween<double>(1.0),
        weight: 70.0,
      ),
      TweenSequenceItem(
        // Fade out
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15.0, // Quick fade out
      ),
    ]).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_opacityAnimation.value == 0) {
          return const SizedBox.shrink();
        }
        return Positioned(
          // Use positioned for floating effect if this is in a Stack
          top: 20 + _bounceAnimation.value, // Example positioning
          left: 0,
          right: 0,
          child: Center(
            // Center the badge horizontally
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                // Using translate Y for bounce if not in Positioned top
                offset: Offset(0, _bounceAnimation.value), // If not using Positioned.top, this handles Y movement
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge), // Match container
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingRegular,
                      vertical: AppTheme.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: widget.achievement.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Achievement icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.achievement.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.fromString(widget.achievement.iconName), // Assumes AppIcons.fromString exists
                            color: widget.achievement.color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppTheme.paddingSmall),

                        // Achievement info
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievement Unlocked!',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.achievement.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.achievement.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if (widget.onTap != null) ...[
                          // Show chevron only if tappable
                          const SizedBox(width: AppTheme.paddingSmall),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ]
                      ],
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

/// Enhanced achievement notification dialog
class EnhancedAchievementNotification extends StatefulWidget {
  const EnhancedAchievementNotification({
    super.key,
    required this.achievement,
    this.onDismiss,
  });
  final Achievement achievement;
  final VoidCallback? onDismiss;

  @override
  State<EnhancedAchievementNotification> createState() => _EnhancedAchievementNotificationState();
}

class _EnhancedAchievementNotificationState extends State<EnhancedAchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20.0,
      ),
      TweenSequenceItem(
        // Hold
        tween: ConstantTween<double>(1.0),
        weight: 50.0,
      ),
    ]).animate(_animationController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20.0,
      ),
      TweenSequenceItem(
        // Hold
        tween: ConstantTween<double>(1.0),
        weight: 80.0,
      ),
    ]).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Use Dialog for overlay
      backgroundColor: Colors.transparent, // Make dialog background transparent
      elevation: 0, // No shadow for the dialog itself
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          if (_opacityAnimation.value == 0) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Confetti animation (ensure it has a defined size)
                      const SizedBox(
                        height: 80,
                        width: double.infinity, // Take available width
                        // child: AnimationHelpers.createConfettiEffect( // Commented out this line
                        //   controller: _animationController,
                        // ),
                      ),

                      // Achievement icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.achievement.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.achievement.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            AppIcons.fromString(widget.achievement.iconName), // Assumes AppIcons.fromString exists
                            color: widget.achievement.color,
                            size: 32,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.paddingRegular),

                      // Achievement text
                      Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: widget.achievement.color,
                        ),
                      ),

                      const SizedBox(height: AppTheme.paddingSmall),

                      Text(
                        widget.achievement.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              // Use theme
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.paddingSmall),

                      Text(
                        widget.achievement.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              // Use theme
                              color: AppTheme.textSecondaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.paddingRegular),

                      // Points reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingRegular,
                          vertical: AppTheme.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.paddingSmall),
                            Text(
                              '+${widget.achievement.pointsReward} Points',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    // Use theme
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.paddingLarge), // More space before button

                      // Close button
                      ElevatedButton(
                        onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(), // Default dismiss
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.achievement.color,
                          foregroundColor: Colors.white, // Text color
                          minimumSize: const Size(150, 48), // Larger button
                          textStyle:
                              Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), //Use theme
                        ),
                        child: const Text('Awesome!'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced challenge card component with visual improvement
class EnhancedChallengeCard extends StatelessWidget {
  const EnhancedChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });
  final Challenge challenge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress =
        challenge.progress < 0 ? 0.0 : (challenge.progress > 1 ? 1.0 : challenge.progress); // Clamped progress

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall, horizontal: AppTheme.paddingSmall / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppIcons.fromString(
                        challenge.iconName), // Assuming AppIcons.fromString and challenge.iconName exist
                    color: challenge.color, // Assuming Challenge has a color
                    size: 36,
                  ),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          // Added LayoutBuilder
                          WasteAppLogger.debug('EnhancedChallengeCard rendering', {
                            'challenge_title': challenge.title,
                            'max_width': constraints.maxWidth,
                            'max_height': constraints.maxHeight,
                            'is_completed': challenge.isCompleted
                          });
                          return Text(
                            challenge.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor, // Use theme color
                                ),
                          );
                        }),
                        if (challenge.description.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.paddingMicro),
                          Text(
                            challenge.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (challenge.isCompleted) ...[
                    const SizedBox(width: AppTheme.paddingSmall),
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ] else if (challenge.pointsReward > 0) ...[
                    const SizedBox(width: AppTheme.paddingSmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 16),
                            const SizedBox(width: AppTheme.paddingMicro),
                            Text(
                              '${challenge.pointsReward}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          'Points',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade700,
                              ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              // Progress Bar and Percentage
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor:
                            challenge.color.withValues(alpha: 0.2), // Lighter shade of challenge color for background
                        valueColor: AlwaysStoppedAnimation<Color>(challenge.isCompleted || progress >= 1.0
                                ? AppTheme.successColor // Green for completed
                                : challenge.color // Original challenge color during progress
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor, // Use theme color
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced points indicator that shows lifetime points including archived data
class LifetimePointsIndicator extends StatelessWidget {
  const LifetimePointsIndicator({
    super.key,
    required this.points,
    this.onTap,
    this.showLifetimePoints = false,
  });
  final UserPoints points;
  final VoidCallback? onTap;
  final bool showLifetimePoints;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            if (showLifetimePoints)
              FutureBuilder<int>(
                future: Provider.of<GamificationService>(context, listen: false).getTotalLifetimePoints(),
                builder: (context, snapshot) {
                  final lifetimePoints = snapshot.data ?? points.total;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${points.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (lifetimePoints > points.total)
                        Text(
                          'L: $lifetimePoints',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                },
              )
            else
              Text(
                '${points.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget to show archived points history
class ArchivedPointsHistoryWidget extends StatelessWidget {
  const ArchivedPointsHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gamificationService = Provider.of<GamificationService>(context, listen: false);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: gamificationService.getArchivedPointsHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final archivedHistory = snapshot.data ?? [];

        if (archivedHistory.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No archived points history',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: archivedHistory.length,
          itemBuilder: (context, index) {
            final archive = archivedHistory[index];
            final archivedAt = DateTime.tryParse(archive['archivedAt'] ?? '') ?? DateTime.now();
            final points = archive['totalLifetimePoints'] as int? ?? 0;
            final reason = archive['reason'] as String? ?? 'unknown';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.archive,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  '$points Points Archived',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Reason: ${_formatReason(reason)}\nDate: ${_formatDate(archivedAt)}',
                ),
                trailing: const Icon(Icons.history),
              ),
            );
          },
        );
      },
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'user_data_clear':
        return 'Data Reset';
      case 'app_reinstall':
        return 'App Reinstalled';
      case 'manual_archive':
        return 'Manual Archive';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
