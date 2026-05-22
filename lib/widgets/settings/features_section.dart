import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/premium_service.dart';
import '../../utils/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/dialog_helper.dart';
import 'setting_tile.dart';
import 'premium_feature_visuals.dart';
import 'settings_section_header.dart';

/// Features and tools section for settings screen
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.featuresSection),
        Consumer<PremiumService>(
          builder: (context, premiumService, child) {
            final isUnlocked = premiumService.isPremiumFeature('offline_mode');
            return SettingTile(
              icon: Icons.offline_bolt,
              iconColor: Colors.indigo,
              title: t.offlineMode,
              subtitle: t.offlineModeClassify,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: isUnlocked,
              ),
              visuallyDisabled: !isUnlocked,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: isUnlocked,
              ),
              semanticsHint: isUnlocked
                  ? t.offlineModeClassify
                  : t.upgradeToUse(t.offlineMode),
              onTap: () => _handleOfflineModeNavigation(
                context,
                premiumService,
              ),
            );
          },
        ),
        SettingTile(
          icon: Icons.analytics,
          iconColor: Colors.green,
          title: t.analytics,
          subtitle: t.analyticsSubtitle,
          onTap: () => _navigateToAnalytics(context),
        ),
        Consumer<PremiumService>(
          builder: (context, premiumService, child) {
            final isUnlocked =
                premiumService.isPremiumFeature('advanced_analytics');
            return SettingTile(
              icon: Icons.analytics_outlined,
              iconColor: Colors.teal,
              title: t.advancedAnalytics,
              subtitle: t.advancedAnalyticsSubtitle,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: isUnlocked,
              ),
              visuallyDisabled: !isUnlocked,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: isUnlocked,
              ),
              semanticsHint: isUnlocked
                  ? t.advancedAnalyticsSubtitle
                  : t.upgradeToUse(t.advancedAnalytics),
              onTap: () => _handleAdvancedAnalyticsNavigation(
                context,
                premiumService,
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleOfflineModeNavigation(
    BuildContext context,
    PremiumService premiumService,
  ) {
    if (premiumService.isPremiumFeature('offline_mode')) {
      Navigator.pushNamed(context, Routes.offlineModeSettings);
    } else {
      final t = AppLocalizations.of(context)!;
      _showPremiumFeaturePrompt(context, t.offlineMode);
    }
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, Routes.wasteDashboard);
  }

  void _handleAdvancedAnalyticsNavigation(
    BuildContext context,
    PremiumService premiumService,
  ) {
    final t = AppLocalizations.of(context)!;
    if (premiumService.isPremiumFeature('advanced_analytics')) {
      // Navigate to advanced analytics
      _navigateToAnalytics(context);
    } else {
      _showPremiumFeaturePrompt(context, t.advancedAnalytics);
    }
  }

  void _showPremiumFeaturePrompt(BuildContext context, String featureName) {
    final t = AppLocalizations.of(context)!;
    var benefit = t.premiumFeatureBody(featureName);

    if (featureName == t.offlineMode) {
      benefit = t.offlineModeClassify;
    } else if (featureName == t.advancedAnalytics) {
      benefit = t.advancedAnalyticsSubtitle;
    }

    DialogHelper.showPremiumPrompt(
      context,
      featureName: featureName,
      description: PremiumFeatureVisuals.upgradeMessage(
        context,
        featureName: featureName,
        benefit: benefit,
      ),
      onUpgrade: () {
        // Navigate to premium features screen
        Navigator.pushNamed(context, Routes.premiumFeatures);
      },
    );
  }
}
