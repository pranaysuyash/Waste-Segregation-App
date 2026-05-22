import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/premium_service.dart';
import '../../utils/routes.dart';
import '../../utils/dialog_helper.dart';
import '../../services/haptic_settings_service.dart';
import 'setting_tile.dart';
import 'premium_feature_visuals.dart';
import 'settings_theme.dart';

/// App-level settings section for settings screen
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final hasThemeCustomization =
            premiumService.isPremiumFeature('theme_customization');
        final hasOfflineMode = premiumService.isPremiumFeature('offline_mode');
        final hasDataExport = premiumService.isPremiumFeature('export_data');
        final hasRemoveAds = premiumService.isPremiumFeature('remove_ads');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: t.appSettingsSection),
            SettingTile(
              icon: Icons.palette,
              iconColor: SettingsTheme.themeColor,
              title: t.themeSettings,
              subtitle: t.themeSettingsSubtitle,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: hasThemeCustomization,
              ),
              visuallyDisabled: !hasThemeCustomization,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: hasThemeCustomization,
              ),
              semanticsHint: hasThemeCustomization
                  ? t.themeSettingsSubtitle
                  : t.upgradeToUse(t.themeCustomization),
              onTap: () => hasThemeCustomization
                  ? _navigateToThemeSettings(context)
                  : _showPremiumFeaturePrompt(
                      context,
                      featureName: t.themeCustomization,
                      benefit: t.themeSettingsSubtitle,
                    ),
            ),
            SettingTile(
              icon: Icons.notifications,
              iconColor: Colors.green,
              title: t.notificationSettings,
              subtitle: t.notificationSettingsSubtitle,
              onTap: () => _navigateToNotificationSettings(context),
            ),
            SettingTile(
              icon: Icons.block,
              iconColor: Colors.redAccent,
              title: t.removeAds,
              subtitle:
                  hasRemoveAds ? t.adsCurrentlyDisabled : t.manageAdPreferences,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: hasRemoveAds,
              ),
              visuallyDisabled: !hasRemoveAds,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: hasRemoveAds,
              ),
              semanticsHint: hasRemoveAds
                  ? t.adsCurrentlyDisabled
                  : t.upgradeToUse(t.removeAds),
              onTap: () => _showPremiumFeaturePrompt(
                context,
                featureName: t.removeAds,
                benefit: t.manageAdPreferences,
              ),
            ),
            SettingTile(
              icon: Icons.cloud_off,
              iconColor: Colors.indigo,
              title: t.offlineMode,
              subtitle: t.offlineModeSubtitle,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: hasOfflineMode,
              ),
              visuallyDisabled: !hasOfflineMode,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: hasOfflineMode,
              ),
              semanticsHint: hasOfflineMode
                  ? t.offlineModeSubtitle
                  : t.upgradeToUse(t.offlineMode),
              onTap: () => hasOfflineMode
                  ? _navigateToOfflineSettings(context)
                  : _showPremiumFeaturePrompt(
                      context,
                      featureName: t.offlineMode,
                      benefit: t.offlineModeClassify,
                    ),
            ),
            SettingTile(
              icon: Icons.download,
              iconColor: SettingsTheme.dataColor,
              title: t.dataExport,
              subtitle: t.dataExportSubtitle,
              trailing: PremiumFeatureVisuals.buildStatusIndicator(
                context,
                isUnlocked: hasDataExport,
              ),
              visuallyDisabled: !hasDataExport,
              semanticsValue: PremiumFeatureVisuals.semanticsState(
                context,
                isUnlocked: hasDataExport,
              ),
              semanticsHint: hasDataExport
                  ? t.dataExportSubtitle
                  : t.upgradeToUse(t.exportData),
              onTap: () => hasDataExport
                  ? _navigateToDataExport(context)
                  : _showPremiumFeaturePrompt(
                      context,
                      featureName: t.exportData,
                      benefit: t.exportDataSubtitle,
                    ),
            ),
            Consumer<HapticSettingsService>(
              builder: (context, hapticSettings, child) {
                return SettingToggleTile(
                  icon: Icons.vibration,
                  iconColor: Colors.orange,
                  title: t.hapticFeedback,
                  subtitle: t.hapticFeedbackSubtitle,
                  value: hapticSettings.enabled,
                  onChanged: hapticSettings.setEnabled,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToThemeSettings(BuildContext context) {
    Navigator.pushNamed(context, Routes.themeSettings);
  }

  void _navigateToNotificationSettings(BuildContext context) {
    Navigator.pushNamed(context, Routes.notificationSettings);
  }

  void _navigateToOfflineSettings(BuildContext context) {
    Navigator.pushNamed(context, Routes.offlineModeSettings);
  }

  void _navigateToDataExport(BuildContext context) {
    Navigator.pushNamed(context, Routes.dataExport);
  }

  void _showPremiumFeaturePrompt(
    BuildContext context, {
    required String featureName,
    required String benefit,
  }) {
    DialogHelper.showPremiumPrompt(
      context,
      featureName: featureName,
      description: PremiumFeatureVisuals.upgradeMessage(
        context,
        featureName: featureName,
        benefit: benefit,
      ),
      onUpgrade: () => Navigator.pushNamed(context, Routes.premiumFeatures),
    );
  }
}
