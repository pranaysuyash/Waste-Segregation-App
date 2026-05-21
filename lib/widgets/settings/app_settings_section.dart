import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/routes.dart';
import '../../services/haptic_settings_service.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// App-level settings section for settings screen
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.appSettingsSection),
        SettingTile(
          icon: Icons.palette,
          iconColor: SettingsTheme.themeColor,
          title: t.themeSettings,
          subtitle: t.themeSettingsSubtitle,
          onTap: () => _navigateToThemeSettings(context),
        ),
        SettingTile(
          icon: Icons.notifications,
          iconColor: Colors.green,
          title: t.notificationSettings,
          subtitle: t.notificationSettingsSubtitle,
          onTap: () => _navigateToNotificationSettings(context),
        ),
        SettingTile(
          icon: Icons.cloud_off,
          iconColor: Colors.indigo,
          title: t.offlineMode,
          subtitle: t.offlineModeSubtitle,
          onTap: () => _navigateToOfflineSettings(context),
        ),
        SettingTile(
          icon: Icons.download,
          iconColor: SettingsTheme.dataColor,
          title: t.dataExport,
          subtitle: t.dataExportSubtitle,
          onTap: () => _navigateToDataExport(context),
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
}
