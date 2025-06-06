import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';

class AnimatedSettingsToggle extends StatefulWidget {
  const AnimatedSettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;

  @override
  State<AnimatedSettingsToggle> createState() => _AnimatedSettingsToggleState();
}

class _AnimatedSettingsToggleState extends State<AnimatedSettingsToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelpers.createController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.value) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSettingsToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    AnimationHelpers.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      trailing: ScaleTransition(
        scale: animation,
        child: Switch(
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class ProfileUpdateWidget extends StatefulWidget {
  const ProfileUpdateWidget({super.key});

  @override
  State<ProfileUpdateWidget> createState() => _ProfileUpdateWidgetState();
}

class _ProfileUpdateWidgetState extends State<ProfileUpdateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelpers.createController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    AnimationHelpers.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.refresh,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class SmartNotificationWidget extends StatelessWidget {
  const SmartNotificationWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FadeSlideAnimation(
      startOffset: const Offset(0, 0.1),
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
