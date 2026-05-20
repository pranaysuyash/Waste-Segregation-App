import 'package:flutter/material.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

/// A modular component displaying materials and alternative options for classification.
class MaterialsPreview extends StatelessWidget {
  const MaterialsPreview({
    super.key,
    required this.classification,
  });

  final WasteClassification classification;

  static bool hasMaterialsPreview(WasteClassification c) {
    final materials = c.normalizedMaterials;
    return materials.isNotEmpty ||
        (c.alternativeOptions?.isNotEmpty == true) ||
        (c.relatedItems?.isNotEmpty == true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final materials = classification.normalizedMaterials;
    final alternatives = classification.alternativeOptions ?? const <String>[];
    final relatedItems = classification.relatedItems ?? const <String>[];

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Materials & Alternatives',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (materials.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow(context, 'Materials', materials),
            ],
            if (materials.isEmpty) ...[
              const SizedBox(height: 12),
              _buildEmptyFieldNote(context, 'Materials unavailable'),
            ],
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow(context, 'Alternatives', alternatives),
            ],
            if (relatedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow(context, 'Related', relatedItems),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipRow(BuildContext context, String label, List<String> items) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.take(6).map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyFieldNote(BuildContext context, String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
