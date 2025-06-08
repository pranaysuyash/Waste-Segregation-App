import 'package:flutter/material.dart';
import 'global_settings_menu.dart';

class GlobalMenuWrapper extends StatelessWidget {
  const GlobalMenuWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: const GlobalSettingsMenu(),
        ),
      ],
    );
  }
}
