import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/detected_waste_region.dart';

class MultiItemRegionReview extends StatelessWidget {
  const MultiItemRegionReview({
    super.key,
    this.imageFile,
    this.webImageBytes,
    required this.regions,
    required this.onToggleConfirm,
    required this.onRemoveRegion,
    this.onAddRegion,
    this.maxRegions = 8,
  });

  final String? imageFile;
  final Uint8List? webImageBytes;
  final List<DetectedWasteRegion> regions;
  final void Function(String id) onToggleConfirm;
  final void Function(String id) onRemoveRegion;
  final VoidCallback? onAddRegion;
  final int maxRegions;

  int get confirmedCount => regions.where((r) => r.userConfirmed).length;
  int get unconfirmedCount => regions.length - confirmedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 12),
        _buildRegionList(theme),
        if (regions.length < maxRegions && onAddRegion != null) ...[
          const SizedBox(height: 8),
          _buildAddButton(theme),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final allConfirmed =
        regions.isNotEmpty && regions.every((r) => r.userConfirmed);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allConfirmed
            ? Colors.green.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allConfirmed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allConfirmed ? Icons.check_circle : Icons.touch_app,
            color: allConfirmed ? Colors.green : Colors.teal,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allConfirmed
                      ? 'All items confirmed'
                      : 'I see ${regions.length} possible items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allConfirmed
                      ? 'Tap any to review details'
                      : 'Tap each one to confirm',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!allConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$confirmedCount/${regions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionList(ThemeData theme) {
    return Column(
      children: regions.asMap().entries.map((entry) {
        final index = entry.key;
        final region = entry.value;
        return _buildRegionItem(region, index, theme);
      }).toList(),
    );
  }

  Widget _buildRegionItem(
      DetectedWasteRegion region, int index, ThemeData theme) {
    final isConfirmed = region.userConfirmed;
    final classification = region.classification;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isConfirmed
          ? Colors.green.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isConfirmed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onToggleConfirm(region.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildRegionNumber(index, isConfirmed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.label ?? 'Item ${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      classification != null
                          ? classification.category
                          : isConfirmed
                              ? 'Confirmed — classifying...'
                              : 'Tap to confirm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: classification != null
                            ? _categoryColor(classification.category)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConfirmed)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                Icon(Icons.radio_button_unchecked,
                    color: theme.colorScheme.onSurfaceVariant, size: 20),
              if (isConfirmed) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemoveRegion(region.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionNumber(int index, bool isConfirmed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green : Colors.teal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: onAddRegion,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add region'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.teal,
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('wet')) return Colors.green;
    if (lower.contains('dry')) return Colors.blue;
    if (lower.contains('hazard')) return Colors.red;
    if (lower.contains('medical')) return Colors.purple;
    if (lower.contains('non')) return Colors.deepPurple;
    return Colors.grey;
  }
}
