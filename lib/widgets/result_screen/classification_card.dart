import 'package:flutter/material.dart';
import '../../models/waste_classification.dart';
import '../../utils/constants.dart';
import '../interactive_tag.dart';

/// Main classification display card with thumbnail and basic information
class ClassificationCard extends StatelessWidget {
  const ClassificationCard({
    super.key,
    required this.classification,
    required this.thumbnailBuilder,
    required this.tags,
    this.isLoading = false,
  });
  final WasteClassification classification;
  final bool isLoading;
  final Widget Function(double size) thumbnailBuilder;
  final List<TagData> tags;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
      case 'organic':
        return Colors.green;
      case 'dry waste':
      case 'recyclable':
        return Colors.blue;
      case 'hazardous waste':
      case 'hazardous':
        return Colors.red;
      case 'medical waste':
        return Colors.purple;
      case 'e-waste':
      case 'electronic':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [Colors.grey.shade800, Colors.grey.shade900] : [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Classification result header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(classification.category),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(classification.category).withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: thumbnailBuilder(32),
                ),
                const SizedBox(width: AppTheme.paddingRegular),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identified As',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classification.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Interactive Tags Section
            Text(
              'Tags & Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            InteractiveTagCollection(
              tags: tags,
              maxTags: 6,
            ),
          ],
        ),
      ),
    );
  }
}
