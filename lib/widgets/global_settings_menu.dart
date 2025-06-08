import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/simplified_navigation_service.dart';
import '../utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GlobalSettingsMenu extends StatelessWidget {
  const GlobalSettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            try {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            } catch (_) {}
            break;
          case 'profile':
            try {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            } catch (_) {}
            break;
          case 'help':
            _showHelpDialog(context);
            break;
          case 'about':
            _showAboutDialog(context);
            break;
          case 'sign_out':
            SimplifiedNavigationService.showSignOutConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.grey),
              SizedBox(width: 12),
              Text(AppStrings.settings),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 12),
              Text(AppStrings.helpDialogTitle),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Text('About'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Sign Out', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.helpDialogTitle),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.helpDialogTitle}:'),
            SizedBox(height: 8),
            Text(AppStrings.helpStep1),
            Text(AppStrings.helpStep2),
            Text(AppStrings.helpStep3),
            Text(AppStrings.helpStep4),
            SizedBox(height: 16),
            Text(AppStrings.helpFooterText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              });
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('${AppStrings.appName} - ${AppStrings.appTagline}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appDescription),
            const SizedBox(height: 8),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? 'Unknown';
                return Text('Version $version');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
