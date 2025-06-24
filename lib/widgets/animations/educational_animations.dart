import 'package:flutter/material.dart';

/// Animated card reveal for educational content.
class ContentDiscoveryWidget extends StatelessWidget {
  const ContentDiscoveryWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
}

class DailyTipRevealWidget extends StatefulWidget {
  const DailyTipRevealWidget({super.key, required this.tip});
  final String tip;

  @override
  State<DailyTipRevealWidget> createState() => _DailyTipRevealWidgetState();
}

class _DailyTipRevealWidgetState extends State<DailyTipRevealWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Text(widget.tip),
        ],
      ),
    );
  }
}
