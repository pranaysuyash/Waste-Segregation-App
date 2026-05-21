import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// Displays a classification confidence level as a themed pill.
///
/// Accepts either a 0.0-1.0 fraction ([confidence]) or a 0-100 integer
/// ([confidencePercent]). Colour and icon are derived from [WasteTheme].
///
/// Example:
/// ```dart
/// ConfidenceIndicator(confidence: 0.89)
/// ConfidenceIndicator(confidencePercent: 72)
/// ```
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({
    super.key,
    this.confidence,
    this.confidencePercent,
    this.showIcon = true,
    this.showLabel = true,
    this.size = ConfidenceIndicatorSize.medium,
    this.style = ConfidenceIndicatorStyle.filled,
  }) : assert(
          confidence != null || confidencePercent != null,
          'Either confidence or confidencePercent must be provided',
        );

  final double? confidence;
  final int? confidencePercent;
  final bool showIcon;
  final bool showLabel;
  final ConfidenceIndicatorSize size;
  final ConfidenceIndicatorStyle style;

  int get _pct => confidencePercent ?? ((confidence ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = _pct;
    final color = WasteTheme.confidenceColor(pct.toDouble());
    final icon = WasteTheme.confidenceIcon(pct.toDouble());
    final label = showLabel ? '$pct%' : null;
    final semanticsLabel = WasteTheme.confidenceSemanticsLabel(pct.toDouble());

    final textStyle = _textStyle(theme, color);
    final iconSize = _iconSize();

    final pill = _buildPill(theme, color, icon, label, textStyle, iconSize);

    return Semantics(
      label: semanticsLabel,
      child: pill,
    );
  }

  Widget _buildPill(
    ThemeData theme,
    Color color,
    IconData icon,
    String? label,
    TextStyle textStyle,
    double iconSize,
  ) {
    final decoration = _decoration(color);
    final padding = _padding();

    final children = <Widget>[
      if (showIcon) ...[
        Icon(icon, size: iconSize, color: _contentColor(color)),
        if (label != null) const SizedBox(width: 4),
      ],
      if (label != null)
        Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
    ];

    return Container(
      padding: padding,
      decoration: decoration,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  BoxDecoration _decoration(Color color) {
    switch (style) {
      case ConfidenceIndicatorStyle.filled:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ConfidenceIndicatorStyle.soft:
        return BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ConfidenceIndicatorStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
    }
  }

  EdgeInsets _padding() {
    switch (size) {
      case ConfidenceIndicatorSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case ConfidenceIndicatorSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case ConfidenceIndicatorSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 7);
    }
  }

  double _iconSize() {
    switch (size) {
      case ConfidenceIndicatorSize.small:
        return 12;
      case ConfidenceIndicatorSize.medium:
        return 16;
      case ConfidenceIndicatorSize.large:
        return 20;
    }
  }

  TextStyle _textStyle(ThemeData theme, Color color) {
    final base = switch (size) {
      ConfidenceIndicatorSize.small => theme.textTheme.labelSmall,
      ConfidenceIndicatorSize.medium => theme.textTheme.labelMedium,
      ConfidenceIndicatorSize.large => theme.textTheme.labelLarge,
    };
    return (base ?? const TextStyle()).copyWith(
      color: _contentColor(color),
      fontWeight: FontWeight.w600,
      fontSize: switch (size) {
        ConfidenceIndicatorSize.small => 10,
        ConfidenceIndicatorSize.medium => 12,
        ConfidenceIndicatorSize.large => 14,
      },
    );
  }

  Color _contentColor(Color color) {
    return style == ConfidenceIndicatorStyle.filled
        ? Colors.white
        : color;
  }
}

enum ConfidenceIndicatorSize { small, medium, large }

enum ConfidenceIndicatorStyle { filled, soft, outlined }
