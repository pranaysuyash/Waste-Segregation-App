import 'package:flutter/material.dart';

/// Banner shown on ResultScreen when a classification was produced offline
/// from a Layer 0 hint (deterministic best guess pending cloud verification).
class OfflineResultBanner extends StatelessWidget {
  const OfflineResultBanner({super.key, this.isAccepted = false});

  /// Whether Layer 0 accepted this item (high confidence) vs hinted.
  final bool isAccepted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAccepted ? Icons.cloud_done : Icons.cloud_off,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAccepted
                      ? 'Analysed offline'
                      : 'Best guess — will verify when connected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAccepted
                      ? 'Classified using on-device pattern matching'
                      : 'This is a preliminary result. Connect to the internet '
                          'for a more accurate classification.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
