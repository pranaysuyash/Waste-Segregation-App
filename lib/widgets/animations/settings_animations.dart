import 'package:flutter/material.dart';

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
    _controller = AnimationController(
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      trailing: Switch(
        value: widget.value,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class ProfileUpdateWidget extends StatelessWidget {
  const ProfileUpdateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

class SmartNotificationWidget extends StatelessWidget {
  const SmartNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
