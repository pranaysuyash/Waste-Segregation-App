import 'package:flutter/material.dart';
import '../models/detected_waste_region.dart';
import '../models/waste_classification.dart';

class PerItemResultCard extends StatelessWidget {
  const PerItemResultCard({
    super.key,
    required this.region,
    required this.index,
    this.totalItems,
    this.onTap,
  });

  final DetectedWasteRegion region;
  final int index;
  final int? totalItems;
  final VoidCallback? onTap;

  WasteClassification? get classification => region.classification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(
        classification?.category ?? 'pending');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: catColor.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(catColor, theme),
              const SizedBox(height: 12),
              if (classification != null) ...[
                _buildItemName(theme),
                const SizedBox(height: 8),
                _buildCategoryBadge(catColor, theme),
                const SizedBox(height: 8),
                _buildDisposalInfo(theme),
              ] else ...[
                Text(
                  'Classification pending...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (region.confidence != null) ...[
                const SizedBox(height: 8),
                _buildConfidenceBar(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color catColor, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: catColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            region.label ?? 'Item ${index + 1}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (totalItems != null)
          Text(
            '${index + 1} / $totalItems',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildItemName(ThemeData theme) {
    return Text(
      classification!.displayItemLabel,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryBadge(Color catColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        classification!.category,
        style: TextStyle(
          color: catColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDisposalInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.delete_outline,
            size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            classification!.disposalInstructions.primaryMethod,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBar(ThemeData theme) {
    final confidence = region.confidence ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              confidence > 0.7
                  ? Colors.green
                  : confidence > 0.4
                      ? Colors.orange
                      : Colors.red,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(confidence * 100).round()}% confidence',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('wet')) return Colors.green;
    if (lower.contains('dry')) return Colors.blue;
    if (lower.contains('hazard')) return Colors.red;
    if (lower.contains('medical')) return Colors.purple;
    if (lower.contains('e-waste') || lower.contains('electronic')) {
      return Colors.orange;
    }
    return Colors.grey;
  }
}
