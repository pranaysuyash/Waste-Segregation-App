import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A card displaying the offline queue status — pending count, sync state,
/// and a retry action.
///
/// Example:
/// ```dart
/// OfflineQueueStatusCard(
///   pendingCount: 5,
///   isSyncing: false,
///   lastSyncAttempt: DateTime.now(),
///   onRetry: () => syncService.retryAll(),
/// )
/// ```
class OfflineQueueStatusCard extends StatelessWidget {
  const OfflineQueueStatusCard({
    super.key,
    required this.pendingCount,
    this.isSyncing = false,
    this.lastSyncAttempt,
    this.lastSyncError,
    this.onRetry,
    this.onDismiss,
  });

  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncAttempt;
  final String? lastSyncError;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  bool get _isEmpty => pendingCount == 0 && !isSyncing;

  @override
  Widget build(BuildContext context) {
    if (_isEmpty && lastSyncError == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label: 'Offline queue: $pendingCount items pending',
      child: Card(
        elevation: 0,
        color: _isEmpty
            ? cs.surfaceContainerHighest
            : cs.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          side: BorderSide(
            color: _isEmpty
                ? cs.outline.withValues(alpha: 0.2)
                : cs.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildIcon(cs),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(theme, cs)),
              const SizedBox(width: 8),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme cs) {
    if (isSyncing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: cs.primary,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isEmpty
            ? cs.surfaceContainerHighest
            : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      child: Icon(
        _isEmpty ? Icons.cloud_done : Icons.cloud_upload_outlined,
        color: _isEmpty ? cs.onSurfaceVariant : cs.primary,
        size: 20,
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEmpty ? 'All synced' : '$pendingCount item(s) in queue',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        if (isSyncing) ...[
          const SizedBox(height: 2),
          Text(
            'Syncing...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.primary,
            ),
          ),
        ] else if (lastSyncError != null) ...[
          const SizedBox(height: 2),
          Text(
            lastSyncError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.error,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else if (lastSyncAttempt != null) ...[
          const SizedBox(height: 2),
          Text(
            'Last sync: ${_formatTime(lastSyncAttempt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final children = <Widget>[];

    if (onRetry != null && !isSyncing && pendingCount > 0) {
      children.add(
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    if (onDismiss != null && _isEmpty) {
      children.add(
        IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'Dismiss',
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
