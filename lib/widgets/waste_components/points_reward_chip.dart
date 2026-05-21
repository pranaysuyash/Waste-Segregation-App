import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// A chip displaying points earned or a reward amount.
///
/// Example:
/// ```dart
/// PointsRewardChip(points: 15)
/// PointsRewardChip(points: 25, label: 'Eco Points')
/// PointsRewardChip(points: 0, variant: PointsRewardVariant.dimmed)
/// ```
class PointsRewardChip extends StatelessWidget {
  const PointsRewardChip({
    super.key,
    required this.points,
    this.label,
    this.showIcon = true,
    this.icon = Icons.stars,
    this.size = PointsChipSize.medium,
    this.variant = PointsRewardVariant.defaultStyle,
    this.onTap,
  });

  final int points;
  final String? label;
  final bool showIcon;
  final IconData icon;
  final PointsChipSize size;
  final PointsRewardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = variant == PointsRewardVariant.dimmed
        ? AppTheme.neutralColor
        : WasteTheme.pointsColor;
    final displayLabel = label ?? '$points pts';
    final iconSize = _iconSize();
    final textStyle = _textStyle(theme, color);

    final chip = Container(
      padding: _padding(),
      decoration: BoxDecoration(
        color: color.withValues(alpha: variant == PointsRewardVariant.dimmed
            ? 0.08
            : 0.15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        border: Border.all(
          color: color.withValues(alpha:
              variant == PointsRewardVariant.dimmed ? 0.2 : 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              points > 0 ? '+$displayLabel' : displayLabel,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    final result = Semantics(
      label: '$points points earned',
      child: chip,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  EdgeInsets _padding() {
    switch (size) {
      case PointsChipSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case PointsChipSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case PointsChipSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 7);
    }
  }

  double _iconSize() {
    switch (size) {
      case PointsChipSize.small:
        return 12;
      case PointsChipSize.medium:
        return 16;
      case PointsChipSize.large:
        return 20;
    }
  }

  TextStyle _textStyle(ThemeData theme, Color color) {
    final base = switch (size) {
      PointsChipSize.small => theme.textTheme.labelSmall,
      PointsChipSize.medium => theme.textTheme.labelMedium,
      PointsChipSize.large => theme.textTheme.labelLarge,
    };
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
  }
}

enum PointsChipSize { small, medium, large }

enum PointsRewardVariant { defaultStyle, dimmed }
