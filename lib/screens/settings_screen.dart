import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/app_version.dart';
import 'premium_features_screen.dart';
import 'theme_settings_screen.dart';
import 'waste_dashboard_screen.dart';
import 'legal_document_screen.dart';
import 'offline_mode_settings_screen.dart';
import 'data_export_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showDeveloperOptions = false;

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
        actions: [
          // Only show developer mode toggle in debug mode
          if (kDebugMode)
            IconButton(
              icon: Icon(
                _showDeveloperOptions ? Icons.developer_mode : Icons.developer_mode_outlined,
                color: _showDeveloperOptions ? Colors.yellow : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showDeveloperOptions = !_showDeveloperOptions;
                });
              },
              tooltip: 'Toggle Developer Mode',
            ),
        ],
      ),
      body: ListView(
        children: [
          // Premium Features Section
          ListTile(
            leading: const Icon(Icons.workspace_premium, color: Colors.amber),
            title: const Text('Premium Features'),
            subtitle: const Text('Unlock advanced features'),
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
          const Divider(),

          // Developer Options Section (Debug Only)
          if (kDebugMode && _showDeveloperOptions) ...[
            Container(
              color: Colors.yellow.shade50,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'DEVELOPER OPTIONS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            await premiumService.resetPremiumFeatures();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All premium features reset')),
                              );
                            }
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Toggle features for testing',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  // --- TEMPORARY: Force Crash button for Crashlytics testing ---
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.warning, color: Colors.red),
                    label: Text('Force Crash (Crashlytics Test)', style: TextStyle(color: Colors.red)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                    onPressed: () {
                      FirebaseCrashlytics.instance.crash();
                    },
                  ),
                  // --- END TEMPORARY ---
                ],
              ),
            ),
            const Divider(),
          ],

          // Theme Settings
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Offline Mode
          ListTile(
            leading: const Icon(Icons.offline_bolt),
            title: const Text('Offline Mode'),
            subtitle: const Text('Classify items without internet'),
            trailing: _buildFeatureIndicator(
              context, 
              premiumService.isPremiumFeature('offline_mode')
            ),
            isThreeLine: false,
            onTap: () {
              if (premiumService.isPremiumFeature('offline_mode')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineModeSettingsScreen(),
                  ),
                );
              } else {
                _showPremiumFeaturePrompt(context, 'Offline Mode');
              }
            },
          ),
          const Divider(),

          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            subtitle: const Text('View detailed insights'),
            trailing: _buildFeatureIndicator(
              context, 
              premiumService.isPremiumFeature('advanced_analytics')
            ),
            isThreeLine: false,
            onTap: () {
              if (premiumService.isPremiumFeature('advanced_analytics')) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const WasteDashboardScreen(),
                  ),
                );
              } else {
                _showPremiumFeaturePrompt(context, 'Advanced Analytics');
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
            trailing: _buildFeatureIndicator(
              context, 
              premiumService.isPremiumFeature('remove_ads')
            ),
            isThreeLine: false,
            onTap: () {
              if (premiumService.isPremiumFeature('remove_ads')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ads are currently disabled')),
                );
              } else {
                _showPremiumFeaturePrompt(context, 'Remove Ads');
              }
            },
          ),
          const Divider(),

          // Data Export
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export your classification history'),
            trailing: _buildFeatureIndicator(
              context, 
              premiumService.isPremiumFeature('export_data')
            ),
            isThreeLine: false,
            onTap: () {
              if (premiumService.isPremiumFeature('export_data')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataExportScreen(),
                  ),
                );
              } else {
                _showPremiumFeaturePrompt(context, 'Data Export');
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

          // Legal Documents
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Legal'),
            subtitle: const Text('Privacy Policy and Terms of Service'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('Privacy Policy'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LegalDocumentScreen(
                                  title: 'Privacy Policy',
                                  assetPath: 'assets/docs/privacy_policy.md',
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Terms of Service'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LegalDocumentScreen(
                                  title: 'Terms of Service',
                                  assetPath: 'assets/docs/terms_of_service.md',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
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
                applicationVersion: AppVersion.displayVersion,
                applicationIcon: const FlutterLogo(size: 64),
                children: [
                  const Text(
                    'Waste Segregation App helps you learn how to properly segregate waste using AI-powered image recognition.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2024 Waste Segregation App. All rights reserved.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LegalDocumentScreen(
                                  title: 'Privacy Policy',
                                  assetPath: 'assets/docs/privacy_policy.md',
                                ),
                              ),
                            );
                          },
                          child: const Text('Privacy Policy'),
                        ),
                      ),
                      const Text(' | '),
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LegalDocumentScreen(
                                  title: 'Terms of Service',
                                  assetPath: 'assets/docs/terms_of_service.md',
                                ),
                              ),
                            );
                          },
                          child: const Text('Terms of Service'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Show a premium feature prompt
  void _showPremiumFeaturePrompt(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Use $featureName'),
        content: Text(
          'This is a premium feature. Upgrade to premium to unlock $featureName and other premium features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumFeaturesScreen(),
                ),
              );
            },
            child: const Text('See Premium Features'),
          ),
        ],
      ),
    );
  }

  // Build a feature indicator based on premium status
  Widget _buildFeatureIndicator(BuildContext context, bool isPremium) {
    if (isPremium) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          const Text(
            'Enabled',
            style: TextStyle(color: Colors.green),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          const Flexible(
            child: Text(
              'Premium',
              style: TextStyle(color: Colors.amber),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      );
    }
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
      activeColor: AppTheme.primaryColor,
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