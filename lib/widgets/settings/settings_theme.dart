import 'package:flutter/material.dart';

/// Centralized theme and styling constants for settings screens
class SettingsTheme {
  // Spacing constants
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  static const double sectionSpacing = 16.0;
  static const double tileSpacing = 4.0;

  // Typography styles
  static TextStyle sectionHeadingStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    ) ?? const TextStyle();
  }

  static TextStyle tileTitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    ) ?? const TextStyle();
  }

  static TextStyle tileSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ) ?? const TextStyle();
  }

  static TextStyle developerModeTitle(BuildContext context) {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.orange,
    );
  }

  static TextStyle developerModeSubtitle(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    );
  }

  // Color constants
  static const Color accountSignOutColor = Colors.red;
  static const Color accountSignInColor = Colors.blue;
  static const Color premiumColor = Colors.amber;
  static const Color navigationColor = Colors.blue;
  static const Color themeColor = Colors.purple;
  static const Color dataColor = Colors.orange;
  static const Color legalColor = Colors.grey;
  static const Color developerColor = Colors.orange;
  static const Color dangerColor = Colors.red;
  static const Color successColor = Colors.green;

  // Developer mode styling
  static BoxDecoration get developerModeDecoration {
    return BoxDecoration(
      color: Colors.yellow.shade50,
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(8),
    );
  }

  // Helper methods for consistent feedback
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Widget for consistent section headers in settings
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? SettingsTheme.sectionPadding,
      child: Text(
        title,
        style: SettingsTheme.sectionHeadingStyle(context),
      ),
    );
  }
}

/// Widget for consistent spacing between sections
class SettingsSectionSpacer extends StatelessWidget {
  const SettingsSectionSpacer({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? SettingsTheme.sectionSpacing);
  }
} 