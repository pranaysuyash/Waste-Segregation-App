import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Modern button with multiple styles and animations
class ModernButton extends StatefulWidget {
  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style = ModernButtonStyle.filled,
    this.size = ModernButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.color,
    this.textColor,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ModernButtonStyle style;
  final ModernButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final Color? color;
  final Color? textColor;
  final Widget? child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.backgroundColor ?? widget.color ?? theme.colorScheme.primary;

    // Button styling based on style type
    late ButtonStyle buttonStyle;
    late Widget content;

    switch (widget.style) {
      case ModernButtonStyle.filled:
        buttonStyle = _getFilledButtonStyle(theme, effectiveColor);
        break;
      case ModernButtonStyle.outlined:
        buttonStyle = _getOutlinedButtonStyle(theme, effectiveColor);
        break;
      case ModernButtonStyle.text:
        buttonStyle = _getTextButtonStyle(theme, effectiveColor);
        break;
      case ModernButtonStyle.glassmorphism:
        buttonStyle = _getGlassmorphismButtonStyle(theme, effectiveColor);
        break;
    }

    // Content based on state
    if (widget.isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _getIconSize(),
            height: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.textColor ?? _getTextColor(theme, effectiveColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else if (widget.icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      content = Text(widget.text);
    }

    final Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.isExpanded ? double.infinity : null,
        height: _getButtonHeight(),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: buttonStyle,
          child: content,
        ),
      ),
    );

    Widget finalButton = GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      child: button,
    );

    // Wrap with tooltip if provided
    if (widget.tooltip != null) {
      finalButton = Tooltip(
        message: widget.tooltip!,
        child: finalButton,
      );
    }

    return finalButton;
  }

  ButtonStyle _getFilledButtonStyle(ThemeData theme, Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: widget.foregroundColor ?? widget.textColor ?? Colors.white,
      elevation: widget.style == ModernButtonStyle.glassmorphism ? 0 : 2,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(theme),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ThemeData theme, Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: widget.foregroundColor ?? widget.textColor ?? color,
      side: BorderSide(color: color, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(theme),
    );
  }

  ButtonStyle _getTextButtonStyle(ThemeData theme, Color color) {
    return TextButton.styleFrom(
      foregroundColor: widget.foregroundColor ?? widget.textColor ?? color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(theme),
    );
  }

  ButtonStyle _getGlassmorphismButtonStyle(ThemeData theme, Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.2),
      foregroundColor: widget.textColor ?? color,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(theme),
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return AppTheme.buttonHeightSm;
      case ModernButtonSize.medium:
        return AppTheme.buttonHeightMd;
      case ModernButtonSize.large:
        return AppTheme.buttonHeightLg;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return AppTheme.borderRadiusSm;
      case ModernButtonSize.medium:
        return AppTheme.borderRadiusMd;
      case ModernButtonSize.large:
        return AppTheme.borderRadiusLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ModernButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ModernButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return AppTheme.iconSizeSm;
      case ModernButtonSize.medium:
        return AppTheme.iconSizeMd;
      case ModernButtonSize.large:
        return AppTheme.iconSizeLg;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (widget.size) {
      case ModernButtonSize.small:
        return theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle();
      case ModernButtonSize.medium:
        return theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle();
      case ModernButtonSize.large:
        return theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle();
    }
  }

  Color _getTextColor(ThemeData theme, Color buttonColor) {
    if (widget.style == ModernButtonStyle.filled) {
      return Colors.white;
    }
    return buttonColor;
  }
}

/// Modern search bar with animations
class ModernSearchBar extends StatefulWidget {
  const ModernSearchBar({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });
  final String hint;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });

      if (hasText) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    widget.onChanged?.call(_controller.text);
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _hasText ? _handleClear : null,
                ),
              );
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd,
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button with modern styling
class ModernFAB extends StatefulWidget {
  const ModernFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.showBadge = false,
    this.badgeText,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final bool showBadge;
  final String? badgeText;

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fab = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.backgroundColor ?? theme.colorScheme.primary,
              (widget.backgroundColor ?? theme.colorScheme.primary).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(
            widget.isExtended ? AppTheme.borderRadiusXl : AppTheme.borderRadiusRound,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.backgroundColor ?? theme.colorScheme.primary).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(
              widget.isExtended ? AppTheme.borderRadiusXl : AppTheme.borderRadiusRound,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExtended ? AppTheme.spacingLg : AppTheme.spacingMd,
                vertical: AppTheme.spacingMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                    size: AppTheme.iconSizeMd,
                  ),
                  if (widget.isExtended && widget.label != null) ...[
                    const SizedBox(width: AppTheme.spacingSm),
                    Flexible(
                      child: Text(
                        widget.label!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.showBadge) {
      fab = Badge(
        label: widget.badgeText != null ? Text(widget.badgeText!) : null,
        child: fab,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: fab,
    );
  }
}

/// Button and input field style enums
enum ModernButtonStyle {
  filled,
  outlined,
  text,
  glassmorphism,
}

enum ModernButtonSize {
  small,
  medium,
  large,
}

enum ModernTextFieldStyle {
  outlined,
  filled,
  glassmorphism,
}

/// Enhanced View All Button with overflow protection and responsive layout
class ViewAllButton extends StatelessWidget {
  const ViewAllButton({
    super.key,
    this.text = 'View All',
    required this.onPressed,
    this.icon,
    this.color,
    this.style = ModernButtonStyle.text,
    this.size = ModernButtonSize.small,
  });
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final ModernButtonStyle style;
  final ModernButtonSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we need to show abbreviated text or icon only
        final isVeryNarrow = constraints.maxWidth < 80;
        final isNarrow = constraints.maxWidth < 120;

        if (isVeryNarrow) {
          // Show only icon for very narrow spaces
          return ModernButton(
            text: '', // Empty text for icon-only mode
            icon: icon ?? Icons.arrow_forward,
            style: style,
            size: size,
            onPressed: onPressed,
            tooltip: text,
            foregroundColor: color ?? theme.colorScheme.primary,
          );
        } else if (isNarrow) {
          // Show abbreviated text for narrow spaces
          var abbreviatedText = text;
          if (text.contains(' ')) {
            // Extract last word for abbreviation
            final words = text.split(' ');
            abbreviatedText = words.last;
          } else if (text.length > 4) {
            // Truncate long single words
            abbreviatedText = text.substring(0, 4);
          }

          return ModernButton(
            text: abbreviatedText,
            icon: icon,
            style: style,
            size: size,
            onPressed: onPressed,
            foregroundColor: color ?? theme.colorScheme.primary,
          );
        } else {
          // Show full text for normal spaces
          return ModernButton(
            text: text,
            icon: icon,
            style: style,
            size: size,
            onPressed: onPressed,
            foregroundColor: color ?? theme.colorScheme.primary,
          );
        }
      },
    );
  }
}
