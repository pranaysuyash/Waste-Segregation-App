/// Points earned popup widget
/// 
/// Displays animated points earned with celebratory effects.
/// Matches Legacy ResultScreen behavior.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/haptic_settings_service.dart';

/// Animated popup showing points earned
class PointsEarnedPopup extends StatefulWidget {
  const PointsEarnedPopup({
    super.key,
    required this.points,
    required this.onDismiss,
    this.duration = const Duration(seconds: 2),
  });

  final int points;
  final VoidCallback onDismiss;
  final Duration duration;

  @override
  State<PointsEarnedPopup> createState() => _PointsEarnedPopupState();
}

class _PointsEarnedPopupState extends State<PointsEarnedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 10,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _controller.forward();
    
    // Auto-dismiss after display duration
    await Future.delayed(widget.duration);
    
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sparkle icon
            Icon(
              Icons.auto_awesome,
              color: Colors.yellow.shade300,
              size: 32,
            ),
            const SizedBox(height: 8),
            // Points text
            Text(
              '+${widget.points}',
              style: theme.textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              'Points Earned!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay widget that manages showing/hiding points popup
class PointsPopupOverlay extends StatelessWidget {
  const PointsPopupOverlay({
    super.key,
    required this.points,
    required this.isVisible,
    required this.onDismiss,
  });

  final int points;
  final bool isVisible;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!isVisible || points <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: PointsEarnedPopup(
            points: points,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }
}

/// Extension to show points popup as overlay
extension PointsPopupExtension on BuildContext {
  void showPointsPopup(int points) {
    final overlay = Overlay.of(this);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => PointsPopupOverlay(
        points: points,
        isVisible: true,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Trigger haptic feedback
    HapticFeedback.lightImpact();
  }
}
