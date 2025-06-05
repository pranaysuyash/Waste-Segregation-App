import 'package:flutter/material.dart';

/// Extension methods for manipulating ARGB values of a [Color].
extension ColorValues on Color {
  /// Returns a new color with any provided channel values replaced.
  ///
  /// The [alpha] value is expected to be between 0 and 1.
  Color withValues({double? alpha, int? red, int? green, int? blue}) {
    final a = alpha != null
        ? (alpha.clamp(0.0, 1.0) * 255).round()
        : this.alpha;
    return Color.fromARGB(
      a,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}
