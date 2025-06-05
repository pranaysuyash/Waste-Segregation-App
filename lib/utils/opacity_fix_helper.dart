import 'package:flutter/material.dart';

/// Helper extension to replace deprecated withOpacity calls
extension ColorOpacityFix on Color {
  /// Modern replacement for deprecated withOpacity
  Color withOpacityFixed(double opacity) {
    return withOpacity(opacity);
  }
}

/// Helper class for common opacity values
class OpacityValues {
  static const double subtle = 0.1;
  static const double light = 0.2;
  static const double medium = 0.3;
  static const double visible = 0.5;
  static const double strong = 0.7;
  static const double prominent = 0.8;
  static const double almostOpaque = 0.9;
} 