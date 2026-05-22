import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Shared visual and semantic helpers for premium-locked feature entry points.
class PremiumFeatureVisuals {
  const PremiumFeatureVisuals._();

  static Widget buildStatusIndicator(
    BuildContext context, {
    required bool isUnlocked,
    bool showChevron = true,
  }) {
    final t = AppLocalizations.of(context)!;

    final statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? Colors.green.withValues(alpha: 0.35)
              : Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        isUnlocked ? t.enabled.toUpperCase() : 'PRO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isUnlocked ? Colors.green.shade700 : Colors.amber.shade800,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUnlocked ? Icons.check_circle : Icons.workspace_premium,
          size: 16,
          color: isUnlocked ? Colors.green : Colors.amber,
          semanticLabel: isUnlocked ? t.enabled : t.premiumFeatureBadge,
        ),
        const SizedBox(width: 6),
        statusPill,
        if (showChevron) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ],
    );
  }

  static String semanticsState(
    BuildContext context, {
    required bool isUnlocked,
  }) {
    final t = AppLocalizations.of(context)!;
    return isUnlocked ? t.enabled : '${t.premiumFeatureBadge}, ${t.disabled}';
  }

  static String upgradeMessage(
    BuildContext context, {
    required String featureName,
    required String benefit,
  }) {
    final t = AppLocalizations.of(context)!;
    return '$benefit. ${t.premiumFeatureBody(featureName)}';
  }
}
