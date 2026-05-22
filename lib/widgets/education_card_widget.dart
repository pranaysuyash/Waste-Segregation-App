import 'package:flutter/material.dart';
import '../models/education_card.dart';
import '../utils/constants.dart';
import 'responsive_text.dart';

class EducationCardWidget extends StatelessWidget {
  const EducationCardWidget({
    super.key,
    required this.card,
    this.onDismiss,
    this.onLearnMore,
  });

  final WasteEducationCard card;
  final VoidCallback? onDismiss;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (Color tint, Color accent) = _variantColors(cs);

    return Card(
      elevation: 0,
      color: tint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.fromString(card.iconName),
                    size: 20, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ReadMoreText(
              card.body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
              trimLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(
                      card.requiresExplicitDismiss ? 'Acknowledge' : 'Got it',
                      style: TextStyle(color: accent),
                    ),
                  ),
                if (onLearnMore != null && card.extendedBody != null)
                  FilledButton.tonalIcon(
                    onPressed: onLearnMore,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Learn more'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _variantColors(ColorScheme cs) {
    switch (card.variant) {
      case EducationCardVariant.story:
        return (cs.primaryContainer.withValues(alpha: 0.25), cs.primary);
      case EducationCardVariant.impact:
        return (Colors.green.withValues(alpha: 0.1), Colors.green.shade700);
      case EducationCardVariant.mistake:
        return (Colors.amber.withValues(alpha: 0.12), Colors.amber.shade800);
      case EducationCardVariant.localRule:
        return (Colors.blue.withValues(alpha: 0.1), Colors.blue.shade700);
      case EducationCardVariant.alternative:
        return (Colors.purple.withValues(alpha: 0.1), Colors.purple.shade700);
    }
  }
}
