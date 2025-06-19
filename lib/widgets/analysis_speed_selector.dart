import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/token_wallet.dart';
import '../providers/token_providers.dart';
import '../utils/constants.dart';

class AnalysisSpeedSelector extends ConsumerWidget {
  const AnalysisSpeedSelector({
    super.key,
    required this.selectedSpeed,
    required this.onSpeedChanged,
  });

  final AnalysisSpeed selectedSpeed;
  final ValueChanged<AnalysisSpeed> onSpeedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(tokenWalletProvider);
    
    return walletAsync.when(
      data: (wallet) {
        final tokenBalance = wallet?.balance ?? 0;
        final canAffordInstant = tokenBalance >= AnalysisSpeed.instant.cost;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analysis Speed',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Token balance display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: Theme.of(context).colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$tokenBalance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Speed options
              Row(
                children: [
                  Expanded(
                    child: _buildSpeedOption(
                      context,
                      speed: AnalysisSpeed.batch,
                      title: 'Batch',
                      subtitle: '2-6 hours',
                      icon: Icons.schedule,
                      tokenCost: AnalysisSpeed.batch.cost,
                      isSelected: selectedSpeed == AnalysisSpeed.batch,
                      canAfford: tokenBalance >= AnalysisSpeed.batch.cost,
                      onTap: () => onSpeedChanged(AnalysisSpeed.batch),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSpeedOption(
                      context,
                      speed: AnalysisSpeed.instant,
                      title: 'Instant',
                      subtitle: '~30 seconds',
                      icon: Icons.flash_on,
                      tokenCost: AnalysisSpeed.instant.cost,
                      isSelected: selectedSpeed == AnalysisSpeed.instant,
                      canAfford: canAffordInstant,
                      onTap: canAffordInstant 
                          ? () => onSpeedChanged(AnalysisSpeed.instant)
                          : () => _showInsufficientTokensDialog(context),
                    ),
                  ),
                ],
              ),
              
              // Cost savings message
              if (selectedSpeed == AnalysisSpeed.batch)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.savings,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '80% cost savings vs instant analysis',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Unable to load token balance',
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }

  Widget _buildSpeedOption(
    BuildContext context, {
    required AnalysisSpeed speed,
    required String title,
    required String subtitle,
    required IconData icon,
    required int tokenCost,
    required bool isSelected,
    required bool canAfford,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.1)
              : canAfford 
                  ? colorScheme.surface
                  : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary
                : canAfford
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? colorScheme.primary
                  : canAfford
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? colorScheme.primary
                    : canAfford
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: canAfford
                    ? colorScheme.onSurface.withValues(alpha: 0.7)
                    : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // Token cost
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  color: canAfford
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '$tokenCost',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: canAfford
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInsufficientTokensDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Tokens'),
        content: const Text(
          'You need 5 tokens for instant analysis. Earn more tokens through daily login bonuses, classifications, or convert eco-points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to token wallet/earning screen
            },
            child: const Text('Earn Tokens'),
          ),
        ],
      ),
    );
  }
} 