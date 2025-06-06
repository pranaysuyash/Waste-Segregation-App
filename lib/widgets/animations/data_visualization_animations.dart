import 'package:flutter/material.dart';

class SortingAnimationWidget extends StatelessWidget {
  const SortingAnimationWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

class AnimatedDashboardWidget extends StatelessWidget {
  const AnimatedDashboardWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with dashboard-specific animation
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

class ProgressTrackingWidget extends StatelessWidget {
  const ProgressTrackingWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: implement progress tracking animation
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
