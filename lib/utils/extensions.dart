import 'package:flutter/material.dart';
import '../models/gamification.dart';
import 'constants.dart';

/// Extension methods for BuildContext to reduce boilerplate
extension BuildContextExtensions on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get media query data
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Check if device is in dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Get app localizations (when available)
  // AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Extension methods for Achievement to improve readability
extension AchievementExtensions on Achievement {
  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercent => progress.clamp(0.0, 1.0);
  
  /// Get progress percentage as integer (0 to 100)
  int get progressPercentInt => (progressPercent * 100).round();
  
  /// Check if achievement is nearly complete (>= 80%)
  bool get isNearlyComplete => progressPercent >= 0.8;
  
  /// Get tier-specific background color with proper opacity
  Color getTierBackgroundColor({double opacity = 0.1}) {
    return getTierColor().withValues(alpha: opacity);
  }
  
  /// Get contrast-safe text color for the achievement
  Color getContrastSafeTextColor(BuildContext context) {
    final backgroundColor = color;
    final luminance = backgroundColor.computeLuminance();
    
    // Use WCAG AA standard for contrast ratio
    if (luminance > 0.5) {
      return context.colorScheme.onSurface;
    } else {
      return context.colorScheme.surface;
    }
  }
  
  /// Get semantic label for accessibility
  String getSemanticLabel() {
    final statusText = isEarned ? 'completed' : 'in progress';
    final progressText = isEarned ? '' : ', ${progressPercentInt}% complete';
    return '$title, $tierName tier, $statusText$progressText';
  }
}

/// Extension methods for Color to improve contrast calculations
extension ColorExtensions on Color {
  /// Calculate contrast ratio with another color using WCAG formula
  double contrastRatio(Color other) {
    final luminance1 = computeLuminance();
    final luminance2 = other.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Check if this color has sufficient contrast with another color
  bool hasGoodContrastWith(Color other) {
    return contrastRatio(other) >= GamificationConfig.kMinContrastRatio;
  }
  
  /// Get a contrasting color that meets WCAG AA standards
  Color getContrastingColor(BuildContext context) {
    final surface = context.colorScheme.surface;
    final onSurface = context.colorScheme.onSurface;
    
    if (hasGoodContrastWith(surface)) {
      return surface;
    } else if (hasGoodContrastWith(onSurface)) {
      return onSurface;
    } else {
      // Fallback to black or white based on luminance
      return computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }
}

/// Extension for String capitalization
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
} 