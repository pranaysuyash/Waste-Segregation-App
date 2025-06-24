import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Animated empty state widget that provides engaging visuals and helpful messaging
/// when no content is available, encouraging user engagement.
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconSize = 64.0,
    this.actionButton,
    this.actionText,
    this.onActionPressed,
    this.animationType = EmptyStateAnimationType.fadeInScale,
    this.educationalTip,
    this.showPulsingIcon = true,
    this.iconColor,
    this.customAnimation,
  });

  final String title;
  final String message;
  final IconData? icon;
  final double iconSize;
  final Widget? actionButton;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final EmptyStateAnimationType animationType;
  final String? educationalTip;
  final bool showPulsingIcon;
  final Color? iconColor;
  final Widget? customAnimation;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _pulseController;
  late AnimationController _tipController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tipFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Primary animation controller for entrance
    _primaryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse animation controller for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Tip animation controller for educational tips
    _tipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Slide animation (from bottom)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // Pulse animation for icon
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Educational tip fade animation
    _tipFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tipController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    _primaryController.forward();

    if (widget.showPulsingIcon) {
      // Start pulse animation after entrance completes
      _primaryController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.repeat(reverse: true);
        }
      });
    }

    // Show educational tip after a delay
    if (widget.educationalTip != null) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _tipController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _pulseController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: _buildAnimatedContent(),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    switch (widget.animationType) {
      case EmptyStateAnimationType.fadeInScale:
        return _buildFadeInScaleContent();
      case EmptyStateAnimationType.slideUp:
        return _buildSlideUpContent();
      case EmptyStateAnimationType.bounceIn:
        return _buildBounceInContent();
      case EmptyStateAnimationType.custom:
        return widget.customAnimation ?? _buildFadeInScaleContent();
    }
  }

  Widget _buildFadeInScaleContent() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildSlideUpContent() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildBounceInContent() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated icon
        if (widget.icon != null) ...[
          _buildAnimatedIcon(),
          const SizedBox(height: AppTheme.paddingLarge),
        ],

        // Title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.paddingSmall),

        // Message
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: AppTheme.fontSizeRegular,
            height: 1.4,
          ),
        ),

        // Educational tip
        if (widget.educationalTip != null) ...[
          const SizedBox(height: AppTheme.paddingRegular),
          _buildEducationalTip(),
        ],

        // Action button
        if (widget.actionButton != null || widget.actionText != null) ...[
          const SizedBox(height: AppTheme.paddingLarge),
          _buildActionButton(),
        ],
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    if (!widget.showPulsingIcon) {
      return Icon(
        widget.icon,
        size: widget.iconSize,
        color: widget.iconColor ?? Colors.grey.shade400,
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor ?? Colors.grey.shade400,
          ),
        );
      },
    );
  }

  Widget _buildEducationalTip() {
    return AnimatedBuilder(
      animation: _tipController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _tipFadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                    widget.educationalTip!,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    if (widget.actionButton != null) {
      return widget.actionButton!;
    }

    if (widget.actionText != null && widget.onActionPressed != null) {
      return ElevatedButton.icon(
        onPressed: widget.onActionPressed,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(widget.actionText!),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingRegular,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Animation types for empty state widgets
enum EmptyStateAnimationType {
  fadeInScale,
  slideUp,
  bounceIn,
  custom,
}

/// Specific empty state widgets for different use cases

/// Empty state for history screen when no classifications exist
class EmptyHistoryStateWidget extends StatelessWidget {
  const EmptyHistoryStateWidget({
    super.key,
    this.onStartClassifying,
  });

  final VoidCallback? onStartClassifying;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No History Yet',
      message:
          'Start classifying items to build your waste history.\nEvery classification helps you learn and track your environmental impact!',
      icon: Icons.history_toggle_off_outlined,
      educationalTip: 'Tip: Take photos of different waste items to learn proper disposal methods',
      actionText: 'Start Classifying',
      onActionPressed: onStartClassifying,
    );
  }
}

/// Empty state for achievements screen when no achievements are unlocked
class EmptyAchievementsStateWidget extends StatelessWidget {
  const EmptyAchievementsStateWidget({
    super.key,
    this.onStartEarning,
  });

  final VoidCallback? onStartEarning;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Your Journey Starts Here',
      message:
          'Complete waste classifications to unlock achievements and earn points.\nEvery small action makes a big difference!',
      icon: Icons.emoji_events_outlined,
      iconColor: Colors.amber.shade600,
      animationType: EmptyStateAnimationType.bounceIn,
      educationalTip: 'First achievement unlocked after just 3 classifications!',
      actionText: 'Start Earning',
      onActionPressed: onStartEarning,
    );
  }
}

/// Empty state for search results
class EmptySearchResultsWidget extends StatelessWidget {
  const EmptySearchResultsWidget({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
    this.onTryDifferentSearch,
  });

  final String searchQuery;
  final VoidCallback? onClearSearch;
  final VoidCallback? onTryDifferentSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Results Found',
      message:
          'We couldn\'t find any items matching "$searchQuery".\nTry adjusting your search terms or explore different categories.',
      icon: Icons.search_off_outlined,
      animationType: EmptyStateAnimationType.slideUp,
      educationalTip: 'Try searching for broader terms like "plastic" or "paper"',
      actionText: 'Clear Search',
      onActionPressed: onClearSearch,
    );
  }
}

/// Empty state for filtered results
class EmptyFilteredResultsWidget extends StatelessWidget {
  const EmptyFilteredResultsWidget({
    super.key,
    this.onClearFilters,
    this.activeFiltersCount = 0,
  });

  final VoidCallback? onClearFilters;
  final int activeFiltersCount;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Results Found',
      message:
          'Your current filters don\'t match any items.\nTry adjusting or clearing your filters to see more results.',
      icon: Icons.filter_alt_off_outlined,
      educationalTip: activeFiltersCount > 1
          ? 'Try removing some filters to expand your results'
          : 'Different categories might have the content you\'re looking for',
      actionText: 'Clear Filters',
      onActionPressed: onClearFilters,
    );
  }
}

/// Empty state for educational content
class EmptyEducationalContentWidget extends StatelessWidget {
  const EmptyEducationalContentWidget({
    super.key,
    this.onExploreCategories,
    this.category,
  });

  final VoidCallback? onExploreCategories;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final message = category != null
        ? 'No content available for "$category" yet.\nExplore other categories or check back later for new content.'
        : 'Educational content is being prepared.\nCheck back soon for helpful waste management tips and guides.';

    return EmptyStateWidget(
      title: 'Content Coming Soon',
      message: message,
      icon: Icons.school_outlined,
      iconColor: AppTheme.primaryColor,
      animationType: EmptyStateAnimationType.slideUp,
      educationalTip: 'New content is added regularly based on user feedback',
      actionText: category != null ? 'Explore Categories' : 'Browse Available Content',
      onActionPressed: onExploreCategories,
    );
  }
}

/// Refresh/Loading empty state for pull-to-refresh scenarios
class RefreshLoadingWidget extends StatefulWidget {
  const RefreshLoadingWidget({
    super.key,
    this.message = 'Syncing your data...',
    this.showSteps = true,
    this.showEducationalTips = true,
  });

  final String message;
  final bool showSteps;
  final bool showEducationalTips;

  @override
  State<RefreshLoadingWidget> createState() => _RefreshLoadingWidgetState();
}

class _RefreshLoadingWidgetState extends State<RefreshLoadingWidget> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _stepController;
  late AnimationController _tipController;

  late Animation<double> _particleAnimation;
  late Animation<double> _stepAnimation;

  int _currentStep = 0;
  int _currentTipIndex = 0;

  final List<String> _loadingSteps = [
    'Syncing...',
    'Loading...',
    'Almost ready...',
    'Complete!',
  ];

  final List<String> _educationalTips = [
    'Did you know? Proper waste sorting can reduce landfill waste by 30%',
    'Tip: Rinse containers before recycling for better quality materials',
    'Fact: Composting food waste creates nutrient-rich soil for plants',
    'Remember: Small actions lead to big environmental changes',
  ];

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _tipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _stepAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stepController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    _particleController.repeat();

    if (widget.showSteps) {
      _stepController.forward();
      _stepController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && _currentStep < _loadingSteps.length - 1) {
              setState(() {
                _currentStep++;
              });
              _stepController.reset();
              _stepController.forward();
            }
          });
        }
      });
    }

    if (widget.showEducationalTips) {
      _startTipRotation();
    }
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _tipController.forward().then((_) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _tipController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _currentTipIndex = (_currentTipIndex + 1) % _educationalTips.length;
                  });
                  _startTipRotation();
                }
              });
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _stepController.dispose();
    _tipController.dispose();
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
            // Animated particle trail
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer circle
                    Transform.scale(
                      scale: 0.5 + (_particleAnimation.value * 0.5),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 1.0 - _particleAnimation.value,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Inner refreshing icon
                    Transform.rotate(
                      angle: _particleAnimation.value * 2 * 3.14159,
                      child: const Icon(
                        Icons.refresh,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Loading message
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),

            // Step indicators
            if (widget.showSteps) ...[
              const SizedBox(height: AppTheme.paddingRegular),
              AnimatedBuilder(
                animation: _stepController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _stepAnimation,
                    child: Text(
                      _loadingSteps[_currentStep],
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Educational tips
            if (widget.showEducationalTips) ...[
              const SizedBox(height: AppTheme.paddingLarge),
              AnimatedBuilder(
                animation: _tipController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _tipController,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.paddingRegular),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
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
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
