import 'package:flutter/material.dart';

/// Spacer widget between settings sections
class SettingsSectionSpacer extends StatelessWidget {
  const SettingsSectionSpacer({
    super.key,
    this.height = 16.0,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
