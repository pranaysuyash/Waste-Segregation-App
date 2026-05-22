import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/navigation_settings_service.dart';
import '../../widgets/animations/settings_animations.dart';
import '../../utils/routes.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Navigation settings section for settings screen
class NavigationSection extends StatelessWidget {
  const NavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.navigationSection),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Consumer<NavigationSettingsService>(
            builder: (context, navSettings, child) {
              return ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SettingsTheme.navigationColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: SettingsTheme.navigationColor,
                  ),
                ),
                title: Text(
                  t.navigationSettings,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(t.navigationSettingsSubtitle),
                children: [
                  Semantics(
                    label: t.toggleBottomNavigation,
                    child: AnimatedSettingsToggle(
                      title: t.bottomNavigation,
                      subtitle: t.bottomNavigationSubtitle,
                      value: navSettings.bottomNavEnabled,
                      onChanged: (value) => _toggleBottomNav(
                        context,
                        navSettings,
                        value,
                      ),
                    ),
                  ),
                  Semantics(
                    label: t.toggleFloatingCameraButton,
                    child: SwitchListTile(
                      title: Text(t.cameraButton),
                      subtitle: Text(t.cameraButtonSubtitle),
                      value: navSettings.fabEnabled,
                      onChanged: (value) => _toggleFab(
                        context,
                        navSettings,
                        value,
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(t.navigationStyle),
                    subtitle: Text(
                      t.navigationStyleCurrent(navSettings.navigationStyle),
                    ),
                    trailing: DropdownButton<String>(
                      value: navSettings.navigationStyle,
                      items: [
                        DropdownMenuItem(
                          value: 'glassmorphism',
                          child: Text(t.glassmorphism),
                        ),
                        DropdownMenuItem(
                          value: 'material3',
                          child: Text(t.material3),
                        ),
                        DropdownMenuItem(
                          value: 'floating',
                          child: Text(t.floating),
                        ),
                      ],
                      onChanged: (value) => _changeNavigationStyle(
                        context,
                        navSettings,
                        value,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ],
    );
  }

  Future<void> _toggleBottomNav(
    BuildContext context,
    NavigationSettingsService navSettings,
    bool value,
  ) async {
    await navSettings.setBottomNavEnabled(value);
    if (context.mounted) {
      final t = AppLocalizations.of(context)!;
      SettingsTheme.showInfoSnackBar(
        context,
        t.bottomNavEnabled(value ? t.enabled : t.disabled),
      );
    }
  }

  Future<void> _toggleFab(
    BuildContext context,
    NavigationSettingsService navSettings,
    bool value,
  ) async {
    await navSettings.setFabEnabled(value);
    if (context.mounted) {
      final t = AppLocalizations.of(context)!;
      SettingsTheme.showInfoSnackBar(
        context,
        t.cameraButtonEnabled(value ? t.enabled : t.disabled),
      );
    }
  }

  Future<void> _changeNavigationStyle(
    BuildContext context,
    NavigationSettingsService navSettings,
    String? value,
  ) async {
    if (value != null) {
      await navSettings.setNavigationStyle(value);
      if (context.mounted) {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showInfoSnackBar(
          context,
          t.navigationStyleChanged(value),
        );
      }
    }
  }

  void _navigateToNavigationDemo(BuildContext context) {
    Navigator.pushNamed(context, Routes.navigationDemo);
  }
}
