import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/token_providers.dart';
import '../services/token_service.dart';

/// A bottom sheet shown when a user has insufficient tokens for instant analysis.
///
/// Phase 0: Provides three paths (batch, earn, convert) instead of a hard block.
/// This is part of the "legibility before enforcement" principle:
/// users must always see how to continue, not just that they cannot.
class ZeroBalanceOptionsSheet extends ConsumerWidget {
  const ZeroBalanceOptionsSheet({
    super.key,
    required this.requiredTokens,
    this.onBatchSelected,
    this.onEarnSelected,
    this.onConvertSelected,
  });

  final int requiredTokens;
  final VoidCallback? onBatchSelected;
  final VoidCallback? onEarnSelected;
  final VoidCallback? onConvertSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(tokenWalletProvider);
    final remainingConversions = ref.watch(remainingConversionsProvider);

    return walletAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildContent(
        context,
        currentBalance: 0,
        remainingConversions: remainingConversions,
      ),
      data: (wallet) => _buildContent(
        context,
        currentBalance: wallet?.balance ?? 0,
        remainingConversions: remainingConversions,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int currentBalance,
    required int remainingConversions,
  }) {
    final canConvert = remainingConversions > 0;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.token_outlined,
                  color: theme.colorScheme.error, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Not enough tokens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have $currentBalance token${currentBalance == 1 ? '' : 's'}, '
            'but instant analysis requires $requiredTokens.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Switch to Batch (always available)
          _OptionCard(
            icon: Icons.schedule,
            title: 'Switch to Batch',
            subtitle: '1 token - Results in 2-6 hours',
            onTap: () {
              Navigator.pop(context);
              onBatchSelected?.call();
            },
            highlighted: true,
          ),
          const SizedBox(height: 12),

          // Option 2: Earn Tokens
          _OptionCard(
            icon: Icons.star_outline,
            title: 'Earn Tokens',
            subtitle: 'Daily login: +${TokenService.dailyLoginBonus} tokens',
            onTap: () {
              Navigator.pop(context);
              onEarnSelected?.call();
            },
          ),
          const SizedBox(height: 12),

          // Option 3: Convert Points (only if conversions remaining)
          _OptionCard(
            icon: Icons.swap_horiz,
            title: 'Convert Points',
            subtitle: canConvert
                ? '${TokenService.pointsToTokenRate} points = 1 token '
                    '($remainingConversions left today)'
                : 'Daily conversion limit reached',
            onTap: canConvert
                ? () {
                    Navigator.pop(context);
                    onConvertSelected?.call();
                  }
                : null,
            enabled: canConvert,
          ),

          const SizedBox(height: 16),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }

  /// Show this sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int requiredTokens,
    VoidCallback? onBatchSelected,
    VoidCallback? onEarnSelected,
    VoidCallback? onConvertSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ZeroBalanceOptionsSheet(
        requiredTokens: requiredTokens,
        onBatchSelected: onBatchSelected,
        onEarnSelected: onEarnSelected,
        onConvertSelected: onConvertSelected,
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: highlighted ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: enabled
          ? (highlighted ? theme.colorScheme.primaryContainer : null)
          : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
