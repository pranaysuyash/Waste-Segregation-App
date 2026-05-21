import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// A chip that indicates which bin (green/blue/black/red/yellow) to use
/// for disposal of a waste item.
///
/// Colour is resolved from [WasteTheme.binColorForCategory] or
/// [WasteTheme.binColor] when an explicit [binLabel] is provided.
///
/// Example:
/// ```dart
/// BinRecommendationChip(category: 'Wet Waste')
/// BinRecommendationChip(binLabel: 'green', label: 'Green Bin')
/// ```
class BinRecommendationChip extends StatelessWidget {
  const BinRecommendationChip({
    super.key,
    this.category,
    this.binLabel,
    this.label,
    this.showIcon = true,
    this.size = BinChipSize.medium,
    this.onTap,
  }) : assert(
          category != null || binLabel != null,
          'Either category or binLabel must be provided',
        );

  final String? category;
  final String? binLabel;
  final String? label;
  final bool showIcon;
  final BinChipSize size;
  final VoidCallback? onTap;

  Color get _color {
    if (category != null) return WasteTheme.binColorForCategory(category!);
    return WasteTheme.binColor(binLabel ?? 'black');
  }

  String get _displayLabel {
    if (label != null) return label!;
    if (binLabel != null) return '${_capitalize(binLabel!)} Bin';
    return _defaultLabelForCategory(category!);
  }

  String _defaultLabelForCategory(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'wet waste':
      case 'organic':
        return 'Green Bin';
      case 'dry waste':
      case 'recyclable':
      case 'e-waste':
      case 'electronic':
        return 'Blue Bin';
      case 'hazardous waste':
      case 'hazardous':
        return 'Red Bin';
      case 'medical waste':
      case 'medical':
        return 'Yellow Bin';
      default:
        return 'Black Bin';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    final displayLabel = _displayLabel;
    final semanticsLabel = WasteTheme.binSemanticsLabel(
      displayLabel.toLowerCase(),
    );
    final iconSize = _iconSize();
    final textStyle = _textStyle(theme, color);

    final chip = Container(
      padding: _padding(),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.delete_outline, size: iconSize, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              displayLabel,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    final result = Semantics(label: semanticsLabel, child: chip);

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  EdgeInsets _padding() {
    switch (size) {
      case BinChipSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BinChipSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BinChipSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _iconSize() {
    switch (size) {
      case BinChipSize.small:
        return 14;
      case BinChipSize.medium:
        return 18;
      case BinChipSize.large:
        return 22;
    }
  }

  TextStyle _textStyle(ThemeData theme, Color color) {
    final base = switch (size) {
      BinChipSize.small => theme.textTheme.labelSmall,
      BinChipSize.medium => theme.textTheme.labelMedium,
      BinChipSize.large => theme.textTheme.labelLarge,
    };
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
  }
}

enum BinChipSize { small, medium, large }
