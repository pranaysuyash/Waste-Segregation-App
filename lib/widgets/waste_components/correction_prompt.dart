import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// A lightweight correction prompt that shows alternative classifications
/// and invites the user to indicate whether the AI result was correct.
///
/// Designed to be embedded inline in result cards rather than as a separate
/// dialog. For full correction flows with text input and submission, see the
/// CorrectionDialog in `lib/widgets/correction_dialog.dart`.
///
/// Example:
/// ```dart
/// CorrectionPrompt(
///   category: 'Dry Waste',
///   alternatives: [
///     _Alternative(label: 'Wet Waste', confidence: 0.12),
///     _Alternative(label: 'Hazardous Waste', confidence: 0.05),
///   ],
///   onConfirm: () => submitFeedback(confirmed: true),
///   onCorrect: () => _showCorrectionDialog(),
/// )
/// ```
class CorrectionPrompt extends StatelessWidget {
  const CorrectionPrompt({
    super.key,
    this.category,
    this.alternatives = const [],
    this.onConfirm,
    this.onCorrect,
    this.compact = false,
  });

  final String? category;
  final List<CorrectionAlternative> alternatives;
  final VoidCallback? onConfirm;
  final VoidCallback? onCorrect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Was this classification correct?',
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10.0 : 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Is this correct?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.thumb_up,
                    label: 'Yes',
                    color: AppTheme.successColor,
                    onTap: onConfirm,
                    compact: compact,
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.thumb_down,
                    label: 'Fix it',
                    color: AppTheme.errorColor,
                    onTap: onCorrect,
                    compact: compact,
                  ),
                ],
              ),
              if (alternatives.isNotEmpty) ...[
                SizedBox(height: compact ? 6 : 10),
                Text(
                  'Other possibilities:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: alternatives
                      .map((alt) => _AlternativeChip(
                            label: alt.label,
                            confidence: alt.confidence,
                            compact: compact,
                            onTap: alt.onTap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CorrectionAlternative {
  const CorrectionAlternative({
    required this.label,
    this.confidence,
    this.onTap,
  });

  final String label;
  final double? confidence;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: compact ? 20 : 24),
              SizedBox(height: compact ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativeChip extends StatelessWidget {
  const _AlternativeChip({
    required this.label,
    this.confidence,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final double? confidence;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = WasteTheme.categoryColor(label);

    return Semantics(
      label: 'Alternative: $label'
          '${confidence != null ? ', ${(confidence! * 100).round()}% confidence' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: compact ? 10 : 12,
                ),
              ),
              if (confidence != null) ...[
                const SizedBox(width: 4),
                Text(
                  '${(confidence! * 100).round()}%',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
