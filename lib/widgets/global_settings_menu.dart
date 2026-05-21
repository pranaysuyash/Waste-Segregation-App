import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../utils/simplified_navigation_service.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/waste_app_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GlobalSettingsMenu extends StatelessWidget {
  const GlobalSettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onPrimaryContainer,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'settings':
            try {
              Navigator.pushNamed(context, Routes.settings);
            } catch (e) {
              WasteAppLogger.severe('Failed to navigate to settings screen',
                  error: e);
            }
            break;
          case 'profile':
            try {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            } catch (e) {
              WasteAppLogger.severe('Failed to navigate to profile screen',
                  error: e);
            }
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
          case 'impact_dashboard':
            try {
              Navigator.pushNamed(context, '/impact-dashboard');
            } catch (e) {
              WasteAppLogger.severe('Failed to navigate to impact dashboard',
                  error: e);
            }
            break;
          case 'smart_suggestions':
            try {
              Navigator.pushNamed(context, '/smart-suggestions');
            } catch (e) {
              WasteAppLogger.severe('Failed to navigate to smart suggestions',
                  error: e);
            }
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
        PopupMenuItem(
          value: 'impact_dashboard',
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.green),
              SizedBox(width: 12),
              Text('Impact Dashboard'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'smart_suggestions',
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.purple),
              SizedBox(width: 12),
              Text('Smart Suggestions'),
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
                if (context.mounted) {
                  Navigator.pushNamed(context, Routes.settings);
                }
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
