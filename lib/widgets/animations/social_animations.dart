import 'package:flutter/material.dart';

class CommunityFeedWidget extends StatefulWidget {
  const CommunityFeedWidget({super.key, required this.child});
  final Widget child;

  @override
  State<CommunityFeedWidget> createState() => _CommunityFeedWidgetState();
}

class _CommunityFeedWidgetState extends State<CommunityFeedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return SlideTransition(position: slide, child: widget.child);
  }
}

class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
