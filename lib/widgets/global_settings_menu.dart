import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/simplified_navigation_service.dart';

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
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
              Text('Settings'),
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
              Text('Help & Support'),
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
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use WasteWise:'),
            SizedBox(height: 8),
            Text('1. Take a photo or upload an image of waste'),
            Text('2. Get AI-powered classification'),
            Text('3. Follow disposal instructions'),
            Text('4. Earn points and achievements'),
            SizedBox(height: 16),
            Text('Need more help? Check the Settings for tutorials and guides.'),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
        title: const Text('About WasteWise'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WasteWise - Smart Waste Classification'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('An AI-powered app to help you classify and manage waste properly.'),
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
