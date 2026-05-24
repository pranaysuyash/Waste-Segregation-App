import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/visual_feedback_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../../utils/waste_theme.dart';

/// ResultHeader displays the hero image, classification info, and key metrics
/// This is the above-the-fold content (≈60% viewport) as per the design spec
class ResultHeader extends ConsumerWidget {
  const ResultHeader({
    super.key,
    required this.classification,
    required this.pointsEarned,
    required this.onDisposeCorrectly,
    this.heroTag,
  });

  final WasteClassification classification;
  final int pointsEarned;
  final VoidCallback onDisposeCorrectly;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero thumbnail with visual continuity
          _buildHeroThumbnail(context),

          const SizedBox(height: 16),

          // Category chip + confidence bar for instant feedback
          _buildCategoryConfidenceRow(context, colorScheme),

          const SizedBox(height: 12),

          // Item name - readable and prominent
          _buildItemName(context, theme),

          const SizedBox(height: 16),

          // KPI chips: points earned & environmental impact
          _buildKPIChips(context, colorScheme),

          const SizedBox(height: 20),

          // Primary CTA: Dispose correctly
          _buildPrimaryCTA(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeroThumbnail(BuildContext context) {
    final imageWidget = classification.imageUrl != null
        ? Image.network(
            classification.imageUrl!,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        : _buildPlaceholderImage();

    return Hero(
      tag: heroTag ?? 'photo-${classification.id}',
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildCategoryConfidenceRow(
      BuildContext context, ColorScheme colorScheme) {
    final confidence = classification.confidence;
    final category = classification.category;
    final needsReview = classification.clarificationNeeded == true;
    final hasLowConfidence = (confidence ?? 1.0) < 0.7;

    return Row(
      children: [
        // Category chip with semantic color
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getCategoryColor(category).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 16,
                color: _getCategoryColor(category),
              ),
              const SizedBox(width: 6),
              Text(
                classification.displayCategoryLabel,
                style: TextStyle(
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Confidence bar with animated width
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${((confidence ?? 0.0) * 100).round()}% confidence',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (needsReview || hasLowConfidence)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 10, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            needsReview ? 'Needs Review' : 'Low Conf.',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: confidence ?? 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          _getConfidenceColor(confidence ?? 0.0),
                          _getConfidenceColor(confidence ?? 0.0)
                              .withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemName(BuildContext context, ThemeData theme) {
    return Text(
      classification.displayItemLabel,
      style: theme.textTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildKPIChips(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        // Points earned chip with animated counter
        Expanded(
          child: _buildKPIChip(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.stars_rounded,
            label: 'Points',
            value: '+$pointsEarned XP',
            color: Colors.amber,
            animate: pointsEarned > 0,
          ),
        ),

        const SizedBox(width: 16),

        // Environmental impact chip
        Expanded(
          child: _buildKPIChip(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.eco_rounded,
            label: 'Impact',
            value: _getEnvironmentalImpact(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIChip({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool animate = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCTA(BuildContext context, ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: () {
        // Haptic feedback as per design spec
        VisualFeedbackService.instance.mediumImpact();
        onDisposeCorrectly();
      },
      icon: const Icon(Icons.recycling_rounded),
      label: const Text(
        'Dispose Correctly',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  // Helper methods for semantic colors and icons
  Color _getCategoryColor(String category) =>
      WasteTheme.categoryColor(category);

  IconData _getCategoryIcon(String category) =>
      WasteTheme.categoryIcon(category);

  Color _getConfidenceColor(double confidence) =>
      WasteTheme.confidenceColorFromFraction(confidence);

  String _getEnvironmentalImpact() {
    // Calculate environmental impact based on category
    final category = classification.category.toLowerCase();
    switch (category) {
      case 'recyclable':
        return '−3g CO₂e';
      case 'organic':
      case 'compostable':
        return '−2g CO₂e';
      case 'plastic':
        return '−1g CO₂e';
      default:
        return '−1g CO₂e';
    }
  }
}
