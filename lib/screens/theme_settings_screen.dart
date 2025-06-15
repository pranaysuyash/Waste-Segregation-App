import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../utils/routes.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final premium = ref.read(premiumServiceProvider);
    final isPremium = premium.isPremiumFeature('theme_customization');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          // Theme Mode Selection
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('System Default'),
            subtitle: const Text('Follow system theme settings'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('Light Theme'),
            subtitle: const Text('Always use light theme'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Theme'),
            subtitle: const Text('Always use dark theme'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          const Divider(),

          // Premium Features Navigation
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Premium Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Premium Features Row - Always visible for easy access
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber),
              ),
              title: const Text(
                'Premium Features',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Unlock advanced theme customization and more'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, Routes.premium);
              },
            ),
          ),

          // Custom Themes Section (only for non-premium users)
          if (!isPremium) ...[
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.palette, color: Colors.amber),
                title: const Text('Custom Themes'),
                subtitle: const Text('Create your own theme colors'),
                trailing: const Icon(Icons.workspace_premium, color: Colors.amber),
                onTap: () {
                  _showPremiumFeaturePrompt(context, ref);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateThemeMode(WidgetRef ref, ThemeMode mode) {
    ref.read(themeProvider.notifier).setThemeMode(mode);
  }

  void _showPremiumFeaturePrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Custom themes are available with a premium subscription. Upgrade to unlock this feature!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium features screen using named route
              Navigator.pushNamed(context, Routes.premium);
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
} 