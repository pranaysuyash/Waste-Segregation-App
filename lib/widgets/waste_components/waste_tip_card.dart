import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A lightweight card displaying a waste-related educational tip.
///
/// Example:
/// ```dart
/// WasteTipCard(
///   tip: 'Paper can be recycled 5-7 times before fibers become too short.',
///   category: 'Dry Waste',
/// )
/// WasteTipCard(
///   title: 'Did you know?',
///   tip: 'Composting organic waste reduces methane emissions by up to 50%.',
///   showCategoryColor: false,
/// )
/// ```
class WasteTipCard extends StatelessWidget {
  const WasteTipCard({
    super.key,
    required this.tip,
    this.title,
    this.icon = Icons.lightbulb,
    this.iconColor,
    this.category,
    this.showCategoryColor = true,
    this.onTap,
  });

  final String tip;
  final String? title;
  final IconData icon;
  final Color? iconColor;
  final String? category;
  final bool showCategoryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color accentColor;
    if (iconColor != null) {
      accentColor = iconColor!;
    } else if (showCategoryColor && category != null) {
      accentColor = _categoryColorForTip(category!);
    } else {
      accentColor = Colors.amber.shade600;
    }

    return Semantics(
      label: 'Tip: $tip',
      child: Card(
        elevation: 0,
        color: accentColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSm),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) ...[
                        Text(
                          title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        tip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColorForTip(String category) {
    switch (category.toLowerCase().trim()) {
      case 'wet waste':
      case 'organic':
        return Colors.green.shade600;
      case 'dry waste':
      case 'recyclable':
        return Colors.blue.shade600;
      case 'hazardous waste':
      case 'hazardous':
        return Colors.orange.shade600;
      case 'medical waste':
        return Colors.purple.shade600;
      default:
        return Colors.amber.shade600;
    }
  }
}
