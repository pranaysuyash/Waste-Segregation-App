import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/premium_service.dart';
import '../../utils/routes.dart';
import 'premium_feature_visuals.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Premium features section for settings screen
class PremiumSection extends StatelessWidget {
  const PremiumSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final hasPremiumPlan = premiumService.hasActivePremiumPlan();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: t.premiumSection),
            SettingTile(
              icon: Icons.workspace_premium,
              iconColor: SettingsTheme.premiumColor,
              title: t.premiumFeatures,
              subtitle: t.premiumFeaturesSubtitle,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: hasPremiumPlan,
              ),
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: hasPremiumPlan,
              ),
              semanticsHint: hasPremiumPlan
                  ? t.premiumFeaturesSubtitle
                  : t.upgradeToUse(t.premiumFeatures),
              onTap: () => _navigateToPremiumFeatures(context),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPremiumFeatures(BuildContext context) {
    Navigator.pushNamed(context, Routes.premiumFeatures);
  }
}
