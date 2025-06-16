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
        // Position global menu with improved styling to reduce visual conflicts
        SafeArea(
          minimum: const EdgeInsets.all(12.0),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const GlobalSettingsMenu(),
            ),
          ),
        ),
      ],
    );
  }
}
