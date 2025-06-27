import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/ui_consistency_utils.dart';

/// Enhanced empty state widgets with engaging illustrations and animations
class EnhancedEmptyState extends StatefulWidget {
  const EnhancedEmptyState({
    super.key,
    required this.type,
    this.customTitle,
    this.customMessage,
    this.customAction,
    this.onAction,
  });
  final EmptyStateType type;
  final String? customTitle;
  final String? customMessage;
  final Widget? customAction;
  final VoidCallback? onAction;

  @override
  State<EnhancedEmptyState> createState() => _EnhancedEmptyStateState();
}

class _EnhancedEmptyStateState extends State<EnhancedEmptyState> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getEmptyStateConfig(widget.type);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration
            _buildAnimatedIllustration(config),

            const SizedBox(height: AppTheme.spacingXl),

            // Title
            Text(
              widget.customTitle ?? config.title,
              style: UIConsistency.headingMedium(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Message
            Text(
              widget.customMessage ?? config.message,
              style: UIConsistency.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Action button
            if (widget.customAction != null || config.actionText != null)
              widget.customAction ?? _buildActionButton(config),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIllustration(EmptyStateConfig config) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: config.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: config.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                config.icon,
                size: 60,
                color: config.iconColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(EmptyStateConfig config) {
    if (config.actionText == null) return const SizedBox.shrink();

    return UIConsistency.primaryButton(
      text: config.actionText!,
      icon: config.actionIcon,
      onPressed: widget.onAction,
    );
  }

  EmptyStateConfig _getEmptyStateConfig(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noHistory:
        return EmptyStateConfig(
          icon: Icons.history_toggle_off,
          backgroundColor: Colors.blue.shade100,
          iconColor: Colors.blue.shade600,
          title: 'No Classifications Yet',
          message:
              'Start scanning items to build your waste classification history and track your environmental impact!',
          actionText: 'Start Scanning',
          actionIcon: Icons.camera_alt,
        );

      case EmptyStateType.noResults:
        return EmptyStateConfig(
          icon: Icons.search_off,
          backgroundColor: Colors.orange.shade100,
          iconColor: Colors.orange.shade600,
          title: 'No Results Found',
          message: 'Try adjusting your filters or search terms to find what you\'re looking for.',
          actionText: 'Clear Filters',
          actionIcon: Icons.clear_all,
        );

      case EmptyStateType.noFavorites:
        return EmptyStateConfig(
          icon: Icons.favorite_border,
          backgroundColor: Colors.pink.shade100,
          iconColor: Colors.pink.shade600,
          title: 'No Favorites Yet',
          message: 'Mark items as favorites to easily access your most important classifications.',
          actionText: 'Explore Content',
          actionIcon: Icons.explore,
        );

      case EmptyStateType.noAchievements:
        return EmptyStateConfig(
          icon: Icons.emoji_events_outlined,
          backgroundColor: Colors.amber.shade100,
          iconColor: Colors.amber.shade700,
          title: 'No Achievements Yet',
          message: 'Complete your first classification to start earning badges and tracking your progress!',
          actionText: 'Start Earning',
          actionIcon: Icons.play_arrow,
        );

      case EmptyStateType.noEducationalContent:
        return EmptyStateConfig(
          icon: Icons.school_outlined,
          backgroundColor: Colors.green.shade100,
          iconColor: Colors.green.shade600,
          title: 'No Content Available',
          message: 'Educational content is being prepared. Check back soon for tips on waste segregation!',
          actionText: 'Refresh',
          actionIcon: Icons.refresh,
        );

      case EmptyStateType.offline:
        return EmptyStateConfig(
          icon: Icons.cloud_off,
          backgroundColor: Colors.grey.shade200,
          iconColor: Colors.grey.shade600,
          title: 'You\'re Offline',
          message: 'Some features require an internet connection. Connect to access all features.',
          actionText: 'Retry Connection',
          actionIcon: Icons.wifi,
        );

      case EmptyStateType.error:
        return EmptyStateConfig(
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade100,
          iconColor: Colors.red.shade600,
          title: 'Something Went Wrong',
          message: 'We encountered an issue loading this content. Please try again.',
          actionText: 'Try Again',
          actionIcon: Icons.refresh,
        );

      case EmptyStateType.maintenance:
        return EmptyStateConfig(
          icon: Icons.construction,
          backgroundColor: Colors.orange.shade100,
          iconColor: Colors.orange.shade600,
          title: 'Under Maintenance',
          message: 'This feature is temporarily unavailable while we make improvements.',
        );

      case EmptyStateType.comingSoon:
        return EmptyStateConfig(
          icon: Icons.rocket_launch,
          backgroundColor: Colors.purple.shade100,
          iconColor: Colors.purple.shade600,
          title: 'Coming Soon',
          message: 'We\'re working hard to bring you this exciting new feature. Stay tuned!',
        );
    }
  }
}

/// Specialized empty state for camera/scanning features
class ScanningEmptyState extends StatefulWidget {
  const ScanningEmptyState({
    super.key,
    this.onStartScanning,
    this.onLearnMore,
  });
  final VoidCallback? onStartScanning;
  final VoidCallback? onLearnMore;

  @override
  State<ScanningEmptyState> createState() => _ScanningEmptyStateState();
}

class _ScanningEmptyStateState extends State<ScanningEmptyState> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _scanController.repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated scanning illustration
            _buildScanningAnimation(),

            const SizedBox(height: AppTheme.spacingXl),

            Text(
              'Ready to Scan!',
              style: UIConsistency.headingLarge(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text(
              'Point your camera at any item to instantly learn how to dispose of it properly and help protect the environment.',
              style: UIConsistency.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Action buttons
            UIConsistency.primaryButton(
              text: 'Start Scanning',
              icon: Icons.camera_alt,
              onPressed: widget.onStartScanning,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            UIConsistency.viewAllButton(
              text: 'Learn How It Works',
              onPressed: widget.onLearnMore ?? () {},
              icon: Icons.help_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.primaryColor.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scanning ring
              Container(
                width: 100 + (_scanAnimation.value * 30),
                height: 100 + (_scanAnimation.value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 1.0 - _scanAnimation.value),
                    width: 2,
                  ),
                ),
              ),

              // Camera icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Progress-based empty state for loading content
class ProgressEmptyState extends StatefulWidget {
  const ProgressEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.progress,
    this.isIndeterminate = true,
  });
  final String title;
  final String message;
  final double? progress;
  final bool isIndeterminate;

  @override
  State<ProgressEmptyState> createState() => _ProgressEmptyStateState();
}

class _ProgressEmptyStateState extends State<ProgressEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isIndeterminate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress animation
            _buildProgressAnimation(),

            const SizedBox(height: AppTheme.spacingXl),

            Text(
              widget.title,
              style: UIConsistency.headingMedium(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text(
              widget.message,
              style: UIConsistency.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            if (!widget.isIndeterminate && widget.progress != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                '${(widget.progress! * 100).toInt()}% Complete',
                style: UIConsistency.caption(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 100,
          height: 100,
          child: widget.isIndeterminate
              ? CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                )
              : CircularProgressIndicator(
                  value: widget.progress ?? 0.0,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
        );
      },
    );
  }
}

// ==================== SUPPORTING CLASSES ====================

enum EmptyStateType {
  noHistory,
  noResults,
  noFavorites,
  noAchievements,
  noEducationalContent,
  offline,
  error,
  maintenance,
  comingSoon,
}

class EmptyStateConfig {
  const EmptyStateConfig({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionText,
    this.actionIcon,
  });
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionText;
  final IconData? actionIcon;
}
