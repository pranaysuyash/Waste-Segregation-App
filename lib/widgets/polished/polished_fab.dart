import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

/// Enhanced FAB with pulsing animation and modern styling
class PolishedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enablePulse;
  final Duration pulseDuration;
  final Duration pulseInterval;
  final bool isExtended;
  final double? elevation;

  const PolishedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.enablePulse = true,
    this.pulseDuration = const Duration(milliseconds: 800),
    this.pulseInterval = const Duration(seconds: 10),
    this.isExtended = false,
    this.elevation,
  });

  @override
  State<PolishedFAB> createState() => _PolishedFABState();
}

class _PolishedFABState extends State<PolishedFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );
    
    // Press animation controller
    _pressController = AnimationController(
      duration: AppThemePolish.animationFast,
      vsync: this,
    );

    // Pulse animation (scale from 1.0 to 1.05 and back)
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Press animation (scale down when pressed)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppThemePolish.scalePressed,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation if enabled
    if (widget.enablePulse) {
      _startPulseTimer();
    }
  }

  void _startPulseTimer() {
    Future.delayed(widget.pulseInterval, () {
      if (mounted && widget.enablePulse) {
        _pulseController.forward().then((_) {
          _pulseController.reverse().then((_) {
            _startPulseTimer();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? 
        AppThemePolish.accentVibrant;
    final foregroundColor = widget.foregroundColor ?? 
        Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        final combinedScale = _pulseAnimation.value * _scaleAnimation.value;
        
        return Transform.scale(
          scale: combinedScale,
          child: widget.isExtended
              ? _buildExtendedFAB(theme, backgroundColor, foregroundColor)
              : _buildRegularFAB(theme, backgroundColor, foregroundColor),
        );
      },
    );
  }

  Widget _buildRegularFAB(ThemeData theme, Color backgroundColor, Color foregroundColor) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: FloatingActionButton(
        onPressed: _handleTap,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: widget.elevation ?? AppThemePolish.elevationModerate,
        child: Icon(
          widget.icon,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildExtendedFAB(ThemeData theme, Color backgroundColor, Color foregroundColor) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: FloatingActionButton.extended(
        onPressed: _handleTap,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: widget.elevation ?? AppThemePolish.elevationModerate,
        icon: Icon(
          widget.icon,
          size: 24,
        ),
        label: Text(
          widget.label ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

/// Enhanced action button with modern styling and micro-interactions
class PolishedActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const PolishedActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isOutlined = false,
    this.padding,
    this.borderRadius,
  });

  @override
  State<PolishedActionButton> createState() => _PolishedActionButtonState();
}

class _PolishedActionButtonState extends State<PolishedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppThemePolish.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppThemePolish.scalePressed,
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

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: widget.isOutlined
                ? _buildOutlinedButton(theme)
                : _buildFilledButton(theme),
          ),
        );
      },
    );
  }

  Widget _buildFilledButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: widget.foregroundColor ?? theme.colorScheme.onPrimary,
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
        elevation: AppThemePolish.elevationSubtle,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.foregroundColor ?? theme.colorScheme.primary,
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: widget.backgroundColor ?? theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
} 