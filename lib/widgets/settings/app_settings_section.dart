import 'package:flutter/material.dart';
import '../../screens/theme_settings_screen.dart';
import '../../screens/notification_settings_screen.dart';
import '../../screens/offline_mode_settings_screen.dart';
import '../../screens/data_export_screen.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// App-level settings section for settings screen
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header is handled by parent
        
        SettingTile(
          icon: Icons.palette,
          iconColor: SettingsTheme.themeColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Theme Settings',
          subtitle: 'Customize app appearance',
          onTap: () => _navigateToThemeSettings(context),
        ),
        
        SettingTile(
          icon: Icons.notifications,
          iconColor: Colors.green,
          // TODO(i18n): Localize title and subtitle
          title: 'Notification Settings',
          subtitle: 'Manage notifications and alerts',
          onTap: () => _navigateToNotificationSettings(context),
        ),
        
        SettingTile(
          icon: Icons.cloud_off,
          iconColor: Colors.indigo,
          // TODO(i18n): Localize title and subtitle
          title: 'Offline Mode',
          subtitle: 'Configure offline functionality',
          onTap: () => _navigateToOfflineSettings(context),
        ),
        
        SettingTile(
          icon: Icons.download,
          iconColor: SettingsTheme.dataColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Data Export',
          subtitle: 'Export your data and history',
          onTap: () => _navigateToDataExport(context),
        ),
      ],
    );
  }

  void _navigateToThemeSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThemeSettingsScreen(),
      ),
    );
  }

  void _navigateToNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToOfflineSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineModeSettingsScreen(),
      ),
    );
  }

  void _navigateToDataExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DataExportScreen(),
      ),
    );
  }
} 