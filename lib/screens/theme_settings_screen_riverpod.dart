import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'premium_features_screen.dart';

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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  subtitle: const Text('Follow system theme'),
                  value: ThemeMode.system,
                  groupValue: theme.themeMode,
                  onChanged: (mode) => _updateThemeMode(ref, mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  subtitle: const Text('Light theme'),
                  value: ThemeMode.light,
                  groupValue: theme.themeMode,
                  onChanged: (mode) => _updateThemeMode(ref, mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  subtitle: const Text('Dark theme'),
                  value: ThemeMode.dark,
                  groupValue: theme.themeMode,
                  onChanged: (mode) => _updateThemeMode(ref, mode!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumFeaturesScreen(),
                  ),
                );
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
              // Navigate to premium features screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumFeaturesScreen(),
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
} 