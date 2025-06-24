import 'package:flutter/material.dart';

/// Helper extension providing a stable API for adjusting opacity.
extension ColorOpacityFix on Color {
  /// Wraps [Color.withValues] so calls remain consistent across the codebase.
  Color withOpacityFixed(double opacity) {
    return withValues(alpha: opacity);
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
