import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/premium_feature.dart';
import '../utils/constants.dart';
import 'premium_lock_wrapper.dart';
import 'settings/premium_feature_visuals.dart';

class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.isEnabled,
    this.onTap,
  });
  final PremiumFeature feature;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = AppIcons.fromString(feature.icon);
    final t = AppLocalizations.of(context)!;

    return Semantics(
      label: feature.title,
      value: PremiumFeatureVisuals.semanticsState(
        context,
        isUnlocked: isEnabled,
      ),
      hint: isEnabled
          ? feature.description
          : t.upgradeToUse(feature.title),
      button: onTap != null,
      child: PremiumLockWrapper(
        isLocked: !isEnabled,
        absorbInteractions: false,
        lockedOverlayMessage: feature.title,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [
                          Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.05),
                          Colors.grey.withValues(alpha: 0.1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      size: 28,
                      color: isEnabled
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.description,
                          style: TextStyle(
                            color: isEnabled ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: PremiumFeatureVisuals.buildStatusIndicator(
                      context,
                      isUnlocked: isEnabled,
                      showChevron: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
