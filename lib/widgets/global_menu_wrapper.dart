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
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const GlobalSettingsMenu(),
            ),
          ),
        ),
      ],
    );
  }
}
