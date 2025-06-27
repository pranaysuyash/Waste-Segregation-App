import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/navigation_settings_service.dart';
import '../../widgets/animations/settings_animations.dart';
import '../../screens/navigation_demo_screen.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Navigation settings section for settings screen
class NavigationSection extends StatelessWidget {
  const NavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header is handled by parent

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
                // TODO(i18n): Localize title and subtitle
                title: const Text(
                  'Navigation Settings',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Customize navigation behavior'),
                children: [
                  Semantics(
                    // TODO(i18n): Localize semantic label
                    label: 'Toggle bottom navigation bar',
                    child: AnimatedSettingsToggle(
                      // TODO(i18n): Localize title and subtitle
                      title: 'Bottom Navigation',
                      subtitle: 'Show bottom navigation bar',
                      value: navSettings.bottomNavEnabled,
                      onChanged: (value) => _toggleBottomNav(
                        context,
                        navSettings,
                        value,
                      ),
                    ),
                  ),
                  Semantics(
                    // TODO(i18n): Localize semantic label
                    label: 'Toggle floating camera button',
                    child: SwitchListTile(
                      // TODO(i18n): Localize title and subtitle
                      title: const Text('Camera Button (FAB)'),
                      subtitle: const Text('Show floating camera button'),
                      value: navSettings.fabEnabled,
                      onChanged: (value) => _toggleFab(
                        context,
                        navSettings,
                        value,
                      ),
                    ),
                  ),
                  ListTile(
                    // TODO(i18n): Localize title and subtitle
                    title: const Text('Navigation Style'),
                    subtitle: Text('Current: ${navSettings.navigationStyle}'),
                    trailing: DropdownButton<String>(
                      value: navSettings.navigationStyle,
                      items: const [
                        DropdownMenuItem(
                          value: 'glassmorphism',
                          child: Text('Glassmorphism'),
                        ),
                        DropdownMenuItem(
                          value: 'material3',
                          child: Text('Material 3'),
                        ),
                        DropdownMenuItem(
                          value: 'floating',
                          child: Text('Floating'),
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

        // Navigation Demo
        SettingTile(
          icon: Icons.navigation,
          iconColor: SettingsTheme.navigationColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Navigation Styles',
          subtitle: 'Try different navigation designs',
          trailing: _buildNewBadge(),
          onTap: () => _navigateToNavigationDemo(context),
        ),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SettingsTheme.navigationColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SettingsTheme.navigationColor.withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: SettingsTheme.navigationColor,
        ),
      ),
    );
  }

  Future<void> _toggleBottomNav(
    BuildContext context,
    NavigationSettingsService navSettings,
    bool value,
  ) async {
    await navSettings.setBottomNavEnabled(value);
    if (context.mounted) {
      // TODO(i18n): Localize feedback message
      SettingsTheme.showInfoSnackBar(
        context,
        'Bottom navigation ${value ? 'enabled' : 'disabled'}',
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
      // TODO(i18n): Localize feedback message
      SettingsTheme.showInfoSnackBar(
        context,
        'Camera button ${value ? 'enabled' : 'disabled'}',
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
        // TODO(i18n): Localize feedback message
        SettingsTheme.showInfoSnackBar(
          context,
          'Navigation style changed to $value',
        );
      }
    }
  }

  void _navigateToNavigationDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NavigationDemoScreen(),
      ),
    );
  }
}
