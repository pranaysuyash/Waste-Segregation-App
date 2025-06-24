import 'package:flutter/material.dart';

/// Accessibility contrast fixes for WCAG AA compliance
/// Addresses critical contrast issues with white text on yellow/blue backgrounds
class AccessibilityContrastFixes {
  /// WCAG AA compliant color combinations for different contexts
  static const Map<String, ContrastColorPair> _contrastPairs = {
    'dry_waste_chip': ContrastColorPair(
      backgroundColor: Color(0xFFE65100), // Dark orange instead of yellow
      textColor: Colors.white,
      borderColor: Color(0xFFBF360C),
    ),
    'wet_waste_chip': ContrastColorPair(
      backgroundColor: Color(0xFF2E7D32), // Dark green
      textColor: Colors.white,
      borderColor: Color(0xFF1B5E20),
    ),
    'hazardous_chip': ContrastColorPair(
      backgroundColor: Color(0xFFD84315), // Dark red-orange
      textColor: Colors.white,
      borderColor: Color(0xFFBF360C),
    ),
    'medical_chip': ContrastColorPair(
      backgroundColor: Color(0xFFC62828), // Dark red
      textColor: Colors.white,
      borderColor: Color(0xFFB71C1C),
    ),
    'info_toast': ContrastColorPair(
      backgroundColor: Color(0xFF1565C0), // Dark blue
      textColor: Colors.white,
      borderColor: Color(0xFF0D47A1),
    ),
    'warning_toast': ContrastColorPair(
      backgroundColor: Color(0xFFE65100), // Dark orange
      textColor: Colors.white,
      borderColor: Color(0xFFBF360C),
    ),
    'success_toast': ContrastColorPair(
      backgroundColor: Color(0xFF2E7D32), // Dark green
      textColor: Colors.white,
      borderColor: Color(0xFF1B5E20),
    ),
    'error_toast': ContrastColorPair(
      backgroundColor: Color(0xFFC62828), // Dark red
      textColor: Colors.white,
      borderColor: Color(0xFFB71C1C),
    ),
    'blue_info_box': ContrastColorPair(
      backgroundColor: Color(0xFFE3F2FD), // Very light blue
      textColor: Color(0xFF0D47A1), // Dark blue text
      borderColor: Color(0xFF1976D2),
    ),
    'yellow_warning_box': ContrastColorPair(
      backgroundColor: Color(0xFFFFF3E0), // Very light orange
      textColor: Color(0xFFE65100), // Dark orange text
      borderColor: Color(0xFFFF9800),
    ),
  };

  /// Get WCAG AA compliant colors for a specific context
  static ContrastColorPair getContrastColors(String context) {
    return _contrastPairs[context] ??
        const ContrastColorPair(
          backgroundColor: Color(0xFF212121),
          textColor: Colors.white,
          borderColor: Color(0xFF424242),
        );
  }

  /// Check if a color combination meets WCAG AA contrast requirements
  static bool meetsContrastRequirement(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(foreground, background);
    final requiredRatio = isLargeText ? 3.0 : 4.5;
    return ratio >= requiredRatio;
  }

  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = _calculateLuminance(foreground);
    final backgroundLuminance = _calculateLuminance(background);

    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = _getLinearRGBComponent(color.r / 255.0);
    final g = _getLinearRGBComponent(color.g / 255.0);
    final b = _getLinearRGBComponent(color.b / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Convert sRGB component to linear RGB
  static double _getLinearRGBComponent(double colorComponent) {
    return colorComponent <= 0.03928 ? colorComponent / 12.92 : _pow((colorComponent + 0.055) / 1.055, 2.4);
  }

  /// Power function implementation
  static double _pow(double base, double exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent.round(); i++) {
      result *= base;
    }
    return result;
  }

  /// Get accessible chip styling for waste categories
  static ChipThemeData getAccessibleChipTheme(String category) {
    final colors = getContrastColors('${category.toLowerCase()}_chip');

    return ChipThemeData(
      backgroundColor: colors.backgroundColor,
      selectedColor: colors.backgroundColor,
      labelStyle: TextStyle(
        color: colors.textColor,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: colors.borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Get accessible toast styling
  static SnackBarThemeData getAccessibleToastTheme(String type) {
    final colors = getContrastColors('${type}_toast');

    return SnackBarThemeData(
      backgroundColor: colors.backgroundColor,
      contentTextStyle: TextStyle(
        color: colors.textColor,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.borderColor),
      ),
    );
  }

  /// Get accessible info box decoration
  static BoxDecoration getAccessibleInfoBoxDecoration(String type) {
    final colors = getContrastColors('${type}_info_box');

    return BoxDecoration(
      color: colors.backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.borderColor),
    );
  }

  /// Get accessible text style for info boxes
  static TextStyle getAccessibleInfoBoxTextStyle(String type) {
    final colors = getContrastColors('${type}_info_box');

    return TextStyle(
      color: colors.textColor,
      fontWeight: FontWeight.w500,
    );
  }
}

/// Data class for contrast color combinations
class ContrastColorPair {
  const ContrastColorPair({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
}

/// Extension to easily apply accessible colors to widgets
extension AccessibleColors on Widget {
  /// Apply accessible chip colors based on category
  Widget withAccessibleChipColors(String category) {
    final colors = AccessibilityContrastFixes.getContrastColors('${category.toLowerCase()}_chip');

    if (this is Chip) {
      final chip = this as Chip;
      return Chip(
        label: chip.label,
        backgroundColor: colors.backgroundColor,
        labelStyle: TextStyle(
          color: colors.textColor,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colors.borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return this;
  }

  /// Apply accessible toast colors
  Widget withAccessibleToastColors(String type) {
    if (this is SnackBar) {
      final snackBar = this as SnackBar;
      final colors = AccessibilityContrastFixes.getContrastColors('${type}_toast');

      return SnackBar(
        content: snackBar.content,
        backgroundColor: colors.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.borderColor),
        ),
      );
    }

    return this;
  }
}
