import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A chip indicating that a local regulation / guideline has been applied
/// to the classification result.
///
/// Example:
/// ```dart
/// LocalRuleChip(
///   ruleName: 'BBMP Dry Waste: Mon, Wed, Fri',
///   icon: Icons.schedule,
/// )
/// LocalRuleChip(
///   authority: 'BBMP',
///   label: 'Daily collection 6-10 AM',
///   icon: Icons.schedule,
/// )
/// ```
class LocalRuleChip extends StatelessWidget {
  const LocalRuleChip({
    super.key,
    this.ruleName,
    this.authority,
    this.label,
    this.icon,
    this.color,
    this.size = LocalRuleChipSize.medium,
    this.onTap,
  });

  final String? ruleName;
  final String? authority;
  final String? label;
  final IconData? icon;
  final Color? color;
  final LocalRuleChipSize size;
  final VoidCallback? onTap;

  String get _displayText {
    if (ruleName != null) return ruleName!;
    if (authority != null && label != null) return '$authority: $label';
    if (authority != null) return authority!;
    return label ?? 'Local rule applied';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveIcon = icon ?? Icons.gavel;
    final iconSize = _iconSize();
    final textStyle = _textStyle(theme, effectiveColor);

    final chip = Container(
      padding: _padding(),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: iconSize, color: effectiveColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _displayText,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final result = Semantics(
      label: 'Local rule: $_displayText',
      child: chip,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  EdgeInsets _padding() {
    switch (size) {
      case LocalRuleChipSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case LocalRuleChipSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case LocalRuleChipSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 7);
    }
  }

  double _iconSize() {
    switch (size) {
      case LocalRuleChipSize.small:
        return 12;
      case LocalRuleChipSize.medium:
        return 16;
      case LocalRuleChipSize.large:
        return 20;
    }
  }

  TextStyle _textStyle(ThemeData theme, Color color) {
    final base = switch (size) {
      LocalRuleChipSize.small => theme.textTheme.labelSmall,
      LocalRuleChipSize.medium => theme.textTheme.labelMedium,
      LocalRuleChipSize.large => theme.textTheme.labelLarge,
    };
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );
  }
}

enum LocalRuleChipSize { small, medium, large }
