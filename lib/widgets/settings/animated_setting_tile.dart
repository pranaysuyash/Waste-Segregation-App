import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated version of SettingTile with smooth transitions and micro-interactions
class AnimatedSettingTile extends StatefulWidget {
  const AnimatedSettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
    this.iconColor,
    this.titleColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.hoverAnimationDuration = const Duration(milliseconds: 150),
    this.enableHoverAnimation = true,
    this.enableTapAnimation = true,
    this.enableSlideInAnimation = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;
  final Color? iconColor;
  final Color? titleColor;
  final Duration animationDuration;
  final Duration hoverAnimationDuration;
  final bool enableHoverAnimation;
  final bool enableTapAnimation;
  final bool enableSlideInAnimation;

  @override
  State<AnimatedSettingTile> createState() => _AnimatedSettingTileState();
}

class _AnimatedSettingTileState extends State<AnimatedSettingTile>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _hoverController;
  late AnimationController _tapController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverScaleAnimation;
  late Animation<Color?> _hoverColorAnimation;

  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.enableSlideInAnimation) {
      _slideController.forward();
    }
  }

  void _initializeAnimations() {
    // Slide-in animation controller
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Hover animation controller
    _hoverController = AnimationController(
      duration: widget.hoverAnimationDuration,
      vsync: this,
    );

    // Tap animation controller
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Scale animation for tap feedback
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));

    // Hover scale animation
    _hoverScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // Hover color animation
    _hoverColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.blue.withValues(alpha: 0.05),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _hoverController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHoverAnimation || !widget.enabled) return;
    
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _handleFocusChange(bool isFocused) {
    setState(() {
      _isFocused = isFocused;
    });

    if (isFocused) {
      _hoverController.forward();
    } else if (!_isHovered) {
      _hoverController.reverse();
    }
  }

  void _handleTap() {
    if (!widget.enabled) return;

    // Haptic feedback
    HapticFeedback.selectionClick();

    if (widget.enableTapAnimation) {
      _tapController.forward().then((_) {
        _tapController.reverse();
      });
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    var child = _buildTileContent(theme);

    // Apply slide-in animation
    if (widget.enableSlideInAnimation) {
      child = SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        ),
      );
    }

    // Apply hover animation
    if (widget.enableHoverAnimation) {
      child = AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverScaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _hoverColorAnimation.value,
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
          );
        },
        child: child,
      );
    }

    // Apply tap animation
    if (widget.enableTapAnimation) {
      child = AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: child,
      );
    }

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Focus(
        onFocusChange: _handleFocusChange,
        child: GestureDetector(
          onTap: _handleTap,
          child: Semantics(
            button: true,
            label: widget.title,
            hint: widget.subtitle,
            enabled: widget.enabled,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent(ThemeData theme) {
    final effectiveIconColor = widget.iconColor ?? theme.colorScheme.primary;
    final effectiveTitleColor = widget.titleColor ?? 
        (widget.enabled ? theme.colorScheme.onSurface : theme.disabledColor);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: _isHovered || _isFocused ? 4 : 1,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      child: AnimatedContainer(
        duration: widget.hoverAnimationDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: _isFocused 
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: ListTile(
          enabled: widget.enabled,
          leading: _buildAnimatedIcon(effectiveIconColor),
          title: _buildAnimatedTitle(effectiveTitleColor, theme),
          subtitle: widget.subtitle != null
              ? _buildAnimatedSubtitle(theme)
              : null,
          trailing: _buildAnimatedTrailing(),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(Color iconColor) {
    return AnimatedContainer(
      duration: widget.hoverAnimationDuration,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: _isHovered || _isFocused ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedRotation(
        duration: widget.hoverAnimationDuration,
        turns: _isHovered ? 0.05 : 0.0,
        child: Icon(
          widget.icon,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(Color titleColor, ThemeData theme) {
    return AnimatedDefaultTextStyle(
      duration: widget.hoverAnimationDuration,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: _isHovered || _isFocused ? FontWeight.w600 : FontWeight.w500,
        color: titleColor,
      ) ?? TextStyle(color: titleColor),
      child: Text(widget.title),
    );
  }

  Widget _buildAnimatedSubtitle(ThemeData theme) {
    return AnimatedDefaultTextStyle(
      duration: widget.hoverAnimationDuration,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: widget.enabled 
            ? theme.colorScheme.onSurfaceVariant 
            : theme.disabledColor,
      ) ?? const TextStyle(),
      child: Text(widget.subtitle!),
    );
  }

  Widget _buildAnimatedTrailing() {
    if (widget.trailing != null) {
      return widget.trailing!;
    }

    return AnimatedRotation(
      duration: widget.hoverAnimationDuration,
      turns: _isHovered ? 0.25 : 0.0,
      child: const Icon(Icons.chevron_right),
    );
  }
}

/// Staggered animation for multiple setting tiles
class StaggeredSettingsAnimation extends StatefulWidget {
  const StaggeredSettingsAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;

  @override
  State<StaggeredSettingsAnimation> createState() => _StaggeredSettingsAnimationState();
}

class _StaggeredSettingsAnimationState extends State<StaggeredSettingsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimation();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
  }

  void _startStaggeredAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return SlideTransition(
          position: _slideAnimations[index],
          child: FadeTransition(
            opacity: _fadeAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

/// Animated section header with expand/collapse functionality
class AnimatedSectionHeader extends StatefulWidget {
  const AnimatedSectionHeader({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? icon;

  @override
  State<AnimatedSectionHeader> createState() => _AnimatedSectionHeaderState();
}

class _AnimatedSectionHeaderState extends State<AnimatedSectionHeader>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: const Icon(Icons.expand_more),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            children: widget.children,
          ),
        ),
      ],
    );
  }
} 