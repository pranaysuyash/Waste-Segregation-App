import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';
import 'confidence_indicator.dart';
import 'bin_recommendation_chip.dart';
import 'points_reward_chip.dart';
import 'waste_image_preview_card.dart';

/// A reusable card that presents a classification summary — category badge,
/// confidence, bin recommendation, and optional image thumbnail — in a
/// consistent layout suitable for history lists, result screens, and
/// dashboard widgets.
///
/// Example:
/// ```dart
/// ClassificationSummaryCard(
///   itemName: 'Plastic Bottle',
///   category: 'Dry Waste',
///   confidence: 0.92,
///   imagePath: 'path/to/thumb.jpg',
///   onTap: () => navigateToDetails(),
/// )
/// ```
class ClassificationSummaryCard extends StatelessWidget {
  const ClassificationSummaryCard({
    super.key,
    required this.itemName,
    required this.category,
    this.subCategory,
    this.confidence,
    this.disposalMethod,
    this.pointsAwarded,
    this.imagePath,
    this.imageUrl,
    this.timestamp,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.onTap,
    this.compact = false,
    this.showCategoryBadge = true,
    this.showConfidence = true,
    this.showBinChip = true,
    this.showPoints = true,
    this.showImage = true,
  });

  final String itemName;
  final String category;
  final String? subCategory;
  final double? confidence;
  final String? disposalMethod;
  final int? pointsAwarded;
  final String? imagePath;
  final String? imageUrl;
  final DateTime? timestamp;
  final bool? isRecyclable;
  final bool? isCompostable;
  final bool? requiresSpecialDisposal;
  final VoidCallback? onTap;
  final bool compact;
  final bool showCategoryBadge;
  final bool showConfidence;
  final bool showBinChip;
  final bool showPoints;
  final bool showImage;

  Color get _catColor => WasteTheme.categoryColor(category);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _catColor;

    return Semantics(
      label: 'Classification: $itemName, category: ${WasteTheme.categoryDisplayLabel(category)}',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          side: BorderSide(color: color.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10.0 : 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showImage) ...[
                  WasteImagePreviewCard(
                    imagePath: imagePath,
                    imageUrl: imageUrl,
                    category: category,
                    size: compact ? 48 : 60,
                    showCategoryOverlay: false,
                  ),
                  SizedBox(width: compact ? 10 : 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: compact ? 4 : 8),
                      _buildChipsRow(context),
                    ],
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipsRow(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (showCategoryBadge)
          _CategoryPill(category: category, compact: compact),
        if (showConfidence && confidence != null)
          ConfidenceIndicator(
            confidence: confidence,
            size: compact
                ? ConfidenceIndicatorSize.small
                : ConfidenceIndicatorSize.medium,
            style: ConfidenceIndicatorStyle.soft,
          ),
        if (showBinChip)
          BinRecommendationChip(
            category: category,
            size: compact ? BinChipSize.small : BinChipSize.medium,
            showIcon: !compact,
          ),
        if (showPoints && pointsAwarded != null && pointsAwarded! > 0)
          PointsRewardChip(
            points: pointsAwarded!,
            size: compact ? PointsChipSize.small : PointsChipSize.medium,
          ),
        if (timestamp != null)
          _DatePill(timestamp: timestamp!, compact: compact),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, required this.compact});
  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = WasteTheme.categoryColor(category);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 1 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(WasteTheme.categoryIcon(category),
              size: compact ? 12 : 14, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              WasteTheme.categoryDisplayLabel(category),
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.timestamp, this.compact = false});
  final DateTime timestamp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _formatRelative(timestamp);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time,
              size: compact ? 10 : 12,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${ts.day}/${ts.month}/${ts.year}';
  }
}
