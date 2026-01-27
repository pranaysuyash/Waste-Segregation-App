import 'package:flutter/material.dart';

/// Extension methods for manipulating ARGB values of a [Color].
extension ColorValues on Color {
  /// Back-compat channel accessors (0.0-1.0) used across the codebase.
  ///
  /// Newer Flutter versions expose similar accessors on [Color] directly; on
  /// older versions these come from this extension.
  double get a => alpha / 255.0;
  double get r => red / 255.0;
  double get g => green / 255.0;
  double get b => blue / 255.0;

  /// Returns a new color with any provided channel values replaced.
  ///
  /// The [alpha] value is expected to be between 0 and 1.
  Color withValues({double? alpha, int? red, int? green, int? blue}) {
    final a8 =
        alpha != null ? (alpha.clamp(0.0, 1.0) * 255).round() : this.alpha;
    return Color.fromARGB(
      a8,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }

  /// Back-compat for Flutter versions that don't yet expose `Color.toARGB32()`.
  ///
  /// Newer Flutter versions include `toARGB32()` on `Color`; older versions do
  /// not. Implementing this via channel accessors avoids relying on the
  /// deprecated `Color.value` getter while keeping a single call site API.
  int toARGB32() {
    // 0xAARRGGBB
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
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
