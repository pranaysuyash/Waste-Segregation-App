/// Points earned popup widget
///
/// Displays animated points earned with celebratory effects.
/// Matches Legacy ResultScreen behavior.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated popup showing points earned
class PointsEarnedPopup extends StatefulWidget {
  const PointsEarnedPopup({
    super.key,
    required this.points,
    required this.onDismiss,
    this.actionLabel,
    this.impactLabel,
    this.duration = const Duration(seconds: 2),
  });

  final int points;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final String? impactLabel;
  final Duration duration;

  @override
  State<PointsEarnedPopup> createState() => _PointsEarnedPopupState();
}

class _PointsEarnedPopupState extends State<PointsEarnedPopup>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _coinController;
  late AnimationController _actionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCollected = false;
  final List<_CoinSpec> _coins = const [
    _CoinSpec(dx: -78, dy: -66, delay: 0.00),
    _CoinSpec(dx: -50, dy: -88, delay: 0.06),
    _CoinSpec(dx: -16, dy: -98, delay: 0.10),
    _CoinSpec(dx: 16, dy: -98, delay: 0.14),
    _CoinSpec(dx: 50, dy: -88, delay: 0.18),
    _CoinSpec(dx: 78, dy: -66, delay: 0.22),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1050),
      vsync: this,
    );
    _actionController = AnimationController(
      duration: const Duration(milliseconds: 950),
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
    await Future.wait([
      _controller.forward(),
      _coinController.forward(),
      _actionController.forward(),
    ]);

    // Auto-dismiss after display duration
    await Future.delayed(widget.duration);

    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _coinController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  void _collectNow() {
    if (_isCollected) return;
    setState(() => _isCollected = true);
    HapticFeedback.mediumImpact();
    _coinController.animateTo(1.0, duration: const Duration(milliseconds: 240));
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
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
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _buildWasteActionVisual(),
                  ..._buildCoins(),
                  GestureDetector(
                    onTap: _collectNow,
                    behavior: HitTestBehavior.translucent,
                    child: child,
                  ),
                ],
              ),
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
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.tertiary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.recycling, color: colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            // Points text
            Text(
              '+${widget.points}',
              style: theme.textTheme.displayLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              'Eco Points Earned!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.actionLabel != null || widget.impactLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (widget.actionLabel != null) widget.actionLabel!,
                  if (widget.impactLabel != null) widget.impactLabel!,
                ].join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWasteActionVisual() {
    return AnimatedBuilder(
      animation: _actionController,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_actionController.value);
        final dropY = -56 + (66 * t);
        final burstOpacity = (t > 0.55 ? ((t - 0.55) / 0.45) : 0.0).clamp(
          0.0,
          1.0,
        );
        final iconScale = (1.0 - (0.2 * t)).clamp(0.78, 1.0);
        final cs = Theme.of(context).colorScheme;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 52,
              child: Container(
                width: 44,
                height: 20,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.tertiary.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.delete_outline, size: 14, color: cs.tertiary),
              ),
            ),
            Positioned(
              top: dropY,
              child: Transform.scale(
                scale: iconScale,
                child: Icon(Icons.recycling, size: 18, color: cs.primary),
              ),
            ),
            Positioned(
              top: 40 - (18 * burstOpacity),
              child: Opacity(
                opacity: burstOpacity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 12, color: cs.secondary),
                    const SizedBox(width: 4),
                    Icon(Icons.water_drop_outlined,
                        size: 12, color: cs.primary),
                    const SizedBox(width: 4),
                    Icon(Icons.bolt, size: 12, color: cs.tertiary),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCoins() {
    return _coins.map((coin) {
      return AnimatedBuilder(
        animation: _coinController,
        builder: (context, _) {
          final progress =
              ((_coinController.value - coin.delay) / (1 - coin.delay))
                  .clamp(0.0, 1.0);
          final curved = Curves.easeOutCubic.transform(progress);
          final retreat =
              _isCollected ? Curves.easeInBack.transform(progress) : 0.0;
          final x = coin.dx * (1 - curved) + (coin.dx * 0.12 * retreat);
          final y = coin.dy * curved + (86 * retreat);
          final opacity = (1 - progress).clamp(0.0, 1.0);
          final scale = 0.62 + (0.38 * (1 - progress)) - (0.2 * retreat);

          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale.clamp(0.2, 1.0),
                child:
                    _CoinPill(points: (widget.points / _coins.length).ceil()),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _CoinSpec {
  const _CoinSpec({required this.dx, required this.dy, required this.delay});
  final double dx;
  final double dy;
  final double delay;
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer,
            colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: colorScheme.tertiary),
          const SizedBox(width: 4),
          Text(
            '+$points',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay widget that manages showing/hiding points popup
class PointsPopupOverlay extends StatelessWidget {
  const PointsPopupOverlay({
    super.key,
    required this.points,
    this.actionLabel,
    this.impactLabel,
    required this.isVisible,
    required this.onDismiss,
  });

  final int points;
  final String? actionLabel;
  final String? impactLabel;
  final bool isVisible;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!isVisible || points <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        child: Center(
          child: PointsEarnedPopup(
            points: points,
            actionLabel: actionLabel,
            impactLabel: impactLabel,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }
}

/// Extension to show points popup as overlay
extension PointsPopupExtension on BuildContext {
  void showPointsPopup(
    int points, {
    String? actionLabel,
    String? impactLabel,
  }) {
    final overlay = Overlay.of(this);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => PointsPopupOverlay(
        points: points,
        actionLabel: actionLabel,
        impactLabel: impactLabel,
        isVisible: true,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Trigger haptic feedback
    HapticFeedback.lightImpact();
  }
}
