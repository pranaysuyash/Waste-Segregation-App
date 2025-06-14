import 'package:flutter/material.dart';

/// Extension methods for manipulating ARGB values of a [Color].
extension ColorValues on Color {
  /// Returns a new color with any provided channel values replaced.
  ///
  /// The [alpha] value is expected to be between 0 and 1.
  Color withValues({double? alpha, int? red, int? green, int? blue}) {
    final a = alpha != null
        ? (alpha.clamp(0.0, 1.0) * 255).round()
        : (value >> 24) & 0xff;
    return Color.fromARGB(
      a,
      red ?? (value >> 16) & 0xff,
      green ?? (value >> 8) & 0xff,
      blue ?? value & 0xff,
    );
  }
}

/// Extension to apply fractional opacity to a Color in a const-friendly way.
extension ColorOpacity on Color {
  /// Returns this color with a fractional alpha, where [fraction] is a
  /// value between 0.0 (transparent) and 1.0 (opaque).
  Color withAlphaFraction(double fraction) {
    // Clamping to ensure the fraction is within the valid range.
    final clampedFraction = fraction.clamp(0.0, 1.0);
    final alpha = (clampedFraction * 255).round();
    return withAlpha(alpha);
  }
}
