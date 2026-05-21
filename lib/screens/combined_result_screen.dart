import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../utils/constants.dart';
import '../widgets/modern_ui/modern_cards.dart';

/// Screen that shows combined results for multiple classified regions.
///
/// Groups results by category and shows a summary list.
/// MVP: simple list with category grouping.
class CombinedResultScreen extends ConsumerWidget {
  const CombinedResultScreen({
    super.key,
    required this.classifications,
    this.imageName = 'Captured image',
  });

  final List<WasteClassification> classifications;
  final String imageName;

  Map<String, List<WasteClassification>> _groupByCategory() {
    final map = SplayTreeMap<String, List<WasteClassification>>();
    for (final c in classifications) {
      map.putIfAbsent(c.category, () => []).add(c);
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final grouped = _groupByCategory();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Multi-Item Results'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSummaryHeader(cs, theme),
              ),
            ),

            // Grouped results
            ...grouped.entries.expand((entry) {
              final category = entry.key;
              final items = entry.value;
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _categoryColor(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _categoryColor(category),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _categoryColor(
                              category,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${items.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _categoryColor(category),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildItemCard(context, items[index], index),
                      childCount: items.length,
                    ),
                  ),
                ),
              ];
            }),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Another'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryHeader(ColorScheme cs, ThemeData theme) {
    final total = classifications.length;
    final categories = _groupByCategory().keys.toList();

    return ModernCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Analysis Complete',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$total ${total == 1 ? 'item' : 'items'} found in "$imageName"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map<Widget>((cat) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: _categoryColor(cat),
                  radius: 8,
                ),
                label: Text(cat),
                backgroundColor: _categoryColor(cat).withValues(alpha: 0.1),
                side: BorderSide(
                  color: _categoryColor(cat).withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WasteClassification classification,
    int index,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _categoryColor(
              classification.category,
            ).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _categoryColor(classification.category),
              ),
            ),
          ),
        ),
        title: Text(
          classification.displayItemLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          classification.disposalInstructions.primaryMethod,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () {
          // Navigate to individual result for this classification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _IndividualResultPlaceholder(classification: classification),
            ),
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('wet')) return AppTheme.wetWasteColor;
    if (lower.contains('dry')) return AppTheme.dryWasteColor;
    if (lower.contains('hazard')) return AppTheme.hazardousWasteColor;
    if (lower.contains('medical')) return AppTheme.medicalWasteColor;
    if (lower.contains('non')) return AppTheme.nonWasteColor;
    return AppTheme.primaryColor;
  }
}

/// Lightweight placeholder for drilling into a single result from combined view.
/// In a full implementation this would reuse the canonical ResultScreen.
class _IndividualResultPlaceholder extends StatelessWidget {
  const _IndividualResultPlaceholder({required this.classification});

  final WasteClassification classification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(classification.displayItemLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classification.category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(classification.explanation),
            const SizedBox(height: 16),
            Text(
              'Disposal: ${classification.disposalInstructions.primaryMethod}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
