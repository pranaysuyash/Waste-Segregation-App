import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'modern_ui/modern_cards.dart';

/// Today's Impact Goal Progress Ring Widget
class TodaysImpactGoal extends StatefulWidget {

  const TodaysImpactGoal({
    super.key,
    required this.currentClassifications,
    this.dailyGoal = 10,
    this.onTap,
  });
  final int currentClassifications;
  final int dailyGoal;
  final VoidCallback? onTap;

  @override
  State<TodaysImpactGoal> createState() => _TodaysImpactGoalState();
}

class _TodaysImpactGoalState extends State<TodaysImpactGoal>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentClassifications / widget.dailyGoal,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressController.forward();
  }

  @override
  void didUpdateWidget(TodaysImpactGoal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentClassifications != widget.currentClassifications) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.currentClassifications / widget.dailyGoal,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (widget.currentClassifications / widget.dailyGoal).clamp(0.0, 1.0);
    final isGoalReached = widget.currentClassifications >= widget.dailyGoal;

    return ModernCard(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            // Title
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '🌍 Today\'s Impact Goal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (isGoalReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'GOAL!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Progress Ring - Reduced size
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: ImpactRingPainter(
                        progress: _progressAnimation.value,
                        primaryColor: AppTheme.primaryColor,
                        secondaryColor: AppTheme.secondaryColor,
                        isGoalReached: isGoalReached,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.currentClassifications}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'of ${widget.dailyGoal}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Motivational message
            Text(
              _getMotivationalMessage(progress, isGoalReached),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage(double progress, bool isGoalReached) {
    if (isGoalReached) return 'Amazing! You\'ve reached your daily goal! 🎉';
    if (progress == 0) return 'Ready to start your green journey? 🌱';
    if (progress < 0.3) return 'Every item classified makes a difference! 💚';
    if (progress < 0.7) return 'You\'re building great habits! 🔥';
    return 'Almost there! You\'ve got this! 💪';
  }
}

/// Custom painter for the impact ring
class ImpactRingPainter extends CustomPainter {

  ImpactRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isGoalReached,
  });
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isGoalReached;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = primaryColor.withValues(alpha:0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: isGoalReached 
            ? [Colors.green, Colors.lightGreen]
            : [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -π/2 (top of circle)
      2 * 3.14159 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    // Goal reached celebration effect
    if (isGoalReached) {
      final celebrationPaint = Paint()
        ..color = Colors.green.withValues(alpha:0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, celebrationPaint);
    }
  }

  @override
  bool shouldRepaint(ImpactRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.isGoalReached != isGoalReached;
  }
}

/// Community Feed Preview Widget
class CommunityFeedPreview extends StatelessWidget {

  const CommunityFeedPreview({
    super.key,
    required this.activities,
    this.onViewAll,
  });
  final List<CommunityActivity> activities;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '🌟 Community Feed',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Activities list
            if (activities.isEmpty)
              _buildEmptyState()
            else
              ...activities.take(3).map((activity) => _buildActivityItem(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'No community activity yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: AppTheme.fontSizeMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Be the first to share your progress!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: AppTheme.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(CommunityActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withValues(alpha:0.1),
            child: Text(
              activity.userName.isNotEmpty ? activity.userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingSm),

          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${activity.action}'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Achievement badge
          if (activity.achievement != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                activity.achievement!,
                style: const TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// Global Impact Meter Widget
class GlobalImpactMeter extends StatefulWidget {

  const GlobalImpactMeter({
    super.key,
    required this.globalCO2Saved,
    required this.globalItemsClassified,
    required this.activeUsers,
  });
  final double globalCO2Saved;
  final int globalItemsClassified;
  final int activeUsers;

  @override
  State<GlobalImpactMeter> createState() => _GlobalImpactMeterState();
}

class _GlobalImpactMeterState extends State<GlobalImpactMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _countAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.public,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '🌍 Global Impact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Impact metrics
            AnimatedBuilder(
              animation: _countAnimation,
              builder: (context, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.eco,
                        value: (widget.globalCO2Saved * _countAnimation.value).toStringAsFixed(1),
                        unit: 'T CO₂',
                        label: 'Saved',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.recycling,
                        value: ((widget.globalItemsClassified * _countAnimation.value) / 1000).toStringAsFixed(0),
                        unit: 'K Items',
                        label: 'Classified',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.people,
                        value: ((widget.activeUsers * _countAnimation.value) / 1000).toStringAsFixed(1),
                        unit: 'K Users',
                        label: 'Active',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Community message
            Text(
              'Together, we\'re making a real difference! 🌱',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        border: Border.all(
          color: color.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for community activities
class CommunityActivity {

  const CommunityActivity({
    required this.userName,
    required this.action,
    required this.timeAgo,
    this.achievement,
  });
  final String userName;
  final String action;
  final String timeAgo;
  final String? achievement;
}

/// Sample data for testing
class DashboardSampleData {
  static List<CommunityActivity> getSampleActivities() {
    return [
      const CommunityActivity(
        userName: 'Alex',
        action: 'classified 15 items today',
        timeAgo: '2 minutes ago',
        achievement: '🔥 Streak',
      ),
      const CommunityActivity(
        userName: 'Sarah',
        action: 'reached daily goal',
        timeAgo: '5 minutes ago',
        achievement: '🎯 Goal',
      ),
      const CommunityActivity(
        userName: 'Mike',
        action: 'saved 2.5kg CO₂',
        timeAgo: '10 minutes ago',
      ),
      const CommunityActivity(
        userName: 'Emma',
        action: 'completed weekly challenge',
        timeAgo: '15 minutes ago',
        achievement: '🏆 Champion',
      ),
    ];
  }
} 