import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'premium_features_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final storageService = Provider.of<StorageService>(context);
    final adService = Provider.of<AdService>(context, listen: false);
    
    // Set context for ads
    adService.setInClassificationFlow(false);
    adService.setInEducationalContent(false);
    adService.setInSettings(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Premium Features Section
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Premium Features'),
            subtitle: const Text('Unlock advanced features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumFeaturesScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Test Mode Section (Development Only)
          if (const bool.fromEnvironment('dart.vm.product') == false) ...[
            const ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Test Mode'),
              subtitle: Text('Development features'),
            ),
            _buildTestModeFeature(
              context,
              'Remove Ads',
              'remove_ads',
              premiumService,
            ),
            _buildTestModeFeature(
              context,
              'Theme Customization',
              'theme_customization',
              premiumService,
            ),
            _buildTestModeFeature(
              context,
              'Offline Mode',
              'offline_mode',
              premiumService,
            ),
            _buildTestModeFeature(
              context,
              'Advanced Analytics',
              'advanced_analytics',
              premiumService,
            ),
            _buildTestModeFeature(
              context,
              'Data Export',
              'export_data',
              premiumService,
            ),
            const Divider(),
          ],

          // Theme Settings
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Light or dark mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (premiumService.isPremiumFeature('theme_customization')) {
                // TODO: Implement theme settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme settings coming soon!')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Offline Mode
          ListTile(
            leading: const Icon(Icons.offline_bolt),
            title: const Text('Offline Mode'),
            subtitle: const Text('Classify items without internet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (premiumService.isPremiumFeature('offline_mode')) {
                // TODO: Implement offline mode settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline mode settings coming soon!')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            subtitle: const Text('View detailed insights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (premiumService.isPremiumFeature('advanced_analytics')) {
                // TODO: Implement analytics screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics coming soon!')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Ad Settings
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Ad Settings'),
            subtitle: premiumService.isPremiumFeature('remove_ads') 
                ? const Text('Ads are disabled')
                : const Text('Manage ad preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (premiumService.isPremiumFeature('remove_ads')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ads are currently disabled')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Data Export
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export your classification history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (premiumService.isPremiumFeature('export_data')) {
                // TODO: Implement data export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data export coming soon!')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Clear Data
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear Data'),
            subtitle: const Text('Reset your classification history'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Data'),
                  content: const Text(
                    'Are you sure you want to clear all your classification history? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await storageService.clearClassifications();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data cleared successfully')),
                          );
                        }
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App information and credits'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppStrings.appName,
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text(
                    'Waste Segregation App helps you learn how to properly segregate waste using AI-powered image recognition.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    '© 2024 Waste Segregation App. All rights reserved.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestModeFeature(
    BuildContext context,
    String title,
    String featureId,
    PremiumService premiumService,
  ) {
    final isEnabled = premiumService.isPremiumFeature(featureId);

    return SwitchListTile(
      title: Text(title),
      subtitle: Text(isEnabled ? 'Enabled' : 'Disabled'),
      value: isEnabled,
      onChanged: (bool value) async {
        await premiumService.setPremiumFeature(featureId, value);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title ${value ? 'enabled' : 'disabled'}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
} 