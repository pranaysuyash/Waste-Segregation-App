import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ActionRow provides secondary actions for the result screen
/// Implements the evenly-spaced icon buttons design from the plan
class ActionRow extends ConsumerWidget {
  const ActionRow({
    super.key,
    required this.onShare,
    required this.onCorrect,
    required this.onSave,
    this.isSaved = false,
    this.isLoading = false,
  });

  final VoidCallback onShare;
  final VoidCallback onCorrect;
  final VoidCallback onSave;
  final bool isSaved;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.share_rounded,
            label: 'Share',
            onPressed: onShare,
            semanticLabel: 'Share result',
          ),
          _buildActionButton(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.edit_rounded,
            label: 'Correct',
            onPressed: onCorrect,
            semanticLabel: 'Correct classification',
          ),
          _buildActionButton(
            context: context,
            colorScheme: colorScheme,
            icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: isSaved ? 'Saved' : 'Save',
            onPressed: isLoading ? null : onSave,
            semanticLabel: isSaved ? 'Already saved' : 'Save result',
            isLoading: isLoading && !isSaved,
            isPrimary: !isSaved,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required String semanticLabel,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPrimary
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed != null
                      ? () {
                          HapticFeedback.lightImpact();
                          onPressed();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Semantics(
                    label: semanticLabel,
                    button: true,
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              icon,
                              color: onPressed != null
                                  ? (isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Label
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onPressed != null
                        ? (isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
