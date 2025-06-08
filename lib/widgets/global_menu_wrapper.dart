import 'package:flutter/material.dart';
import 'global_settings_menu.dart';

class GlobalMenuWrapper extends StatelessWidget {
  const GlobalMenuWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        child,
        SafeArea(
          minimum: const EdgeInsets.all(8.0),
          child: const GlobalSettingsMenu(),
        ),
      ],
    );
  }
}
