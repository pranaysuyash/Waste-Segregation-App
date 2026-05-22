import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../utils/dialog_helper.dart';
import '../utils/routes.dart';
import 'settings/premium_feature_visuals.dart';

/// Premium segmentation toggle widget with visual indicators for free tier users.
class PremiumSegmentationToggle extends StatelessWidget {
  const PremiumSegmentationToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.onUpgradePressed,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final hasAdvancedSegmentation =
            premiumService.isPremiumFeature('advanced_segmentation');
        final t = AppLocalizations.of(context)!;
        final featureLabel = t.advancedSegmentation;
        final featureBenefit = t.advancedSegmentationSubtitle;

        return Semantics(
          label: featureLabel,
          value: PremiumFeatureVisuals.semanticsState(
            context,
            isUnlocked: hasAdvancedSegmentation,
          ),
          hint: hasAdvancedSegmentation
              ? featureBenefit
              : t.upgradeToUse(featureLabel),
          child: Container(
            decoration: BoxDecoration(
              color: hasAdvancedSegmentation
                  ? Colors.blue.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasAdvancedSegmentation
                    ? Colors.blue.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          featureLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasAdvancedSegmentation
                                ? null
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: PremiumFeatureVisuals.buildStatusIndicator(
                          context,
                          isUnlocked: hasAdvancedSegmentation,
                          showChevron: false,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    featureBenefit,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          hasAdvancedSegmentation ? null : Colors.grey.shade500,
                    ),
                  ),
                  value: hasAdvancedSegmentation ? value : false,
                  onChanged: hasAdvancedSegmentation
                      ? onChanged
                      : (bool newValue) {
                          _showPremiumUpgradeDialog(
                            context,
                            featureLabel,
                            featureBenefit,
                          );
                        },
                ),
                if (!hasAdvancedSegmentation)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.amber.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.upgradeToUse(featureLabel),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onUpgradePressed ??
                              () => _showPremiumUpgradeDialog(
                                    context,
                                    featureLabel,
                                    featureBenefit,
                                  ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            t.upgrade,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPremiumUpgradeDialog(
    BuildContext context,
    String featureLabel,
    String featureBenefit,
  ) {
    DialogHelper.showPremiumPrompt(
      context,
      featureName: featureLabel,
      description: PremiumFeatureVisuals.upgradeMessage(
        context,
        featureName: featureLabel,
        benefit: featureBenefit,
      ),
      onUpgrade: () => Navigator.pushNamed(context, Routes.premiumFeatures),
    );
  }
}
