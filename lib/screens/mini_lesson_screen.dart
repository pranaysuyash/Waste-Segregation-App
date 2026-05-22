import 'package:flutter/material.dart';
import '../models/education_card.dart';
import '../utils/constants.dart';
import '../widgets/education_card_widget.dart';

class MiniLessonScreen extends StatelessWidget {
  const MiniLessonScreen({
    super.key,
    required this.card,
    this.relatedCards = const [],
    this.onDismissParent,
  });

  final WasteEducationCard card;
  final List<WasteEducationCard> relatedCards;
  final VoidCallback? onDismissParent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (_, Color accent) = _variantColors(cs);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accent.withValues(alpha: 0.1),
        foregroundColor: accent,
        title: Text(
          card.title,
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: accent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.fromString(card.iconName),
                            size: 28, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            card.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (card.extendedBody != null) ...[
              const SizedBox(height: 24),
              Text(
                'Learn More',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card.extendedBody!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ],
            if (relatedCards.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Related Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...relatedCards.map(
                (related) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EducationCardWidget(
                    card: related,
                  ),
                ),
              ),
            ],
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
