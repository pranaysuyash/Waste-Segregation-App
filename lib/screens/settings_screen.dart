import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../services/enhanced_storage_service.dart';
import '../services/analytics_service.dart';
import '../services/google_drive_service.dart';
import '../services/navigation_settings_service.dart';
import '../utils/constants.dart';
import '../utils/app_version.dart';
import 'premium_features_screen.dart';
import 'theme_settings_screen.dart';
import 'waste_dashboard_screen.dart';
import 'legal_document_screen.dart';
import 'offline_mode_settings_screen.dart';
import 'data_export_screen.dart';
import 'navigation_demo_screen.dart';
import 'modern_ui_showcase_screen.dart';
import 'auth_screen.dart';
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
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
    
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
                  const SizedBox(height: 8),
                  // Reset Full Data button for testing
                  ElevatedButton.icon(
                    icon: Icon(Icons.restore, color: Colors.orange),
                    label: Text('Reset Full Data (Factory Reset)', style: TextStyle(color: Colors.orange)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                    ),
                    onPressed: () {
                      _showFactoryResetDialog(context, storageService, analyticsService, premiumService);
                    },
                  ),
                  // --- END TEMPORARY ---
                ],
              ),
            ),
            const Divider(),
          ],

          // Navigation Settings
          Consumer<NavigationSettingsService>(
            builder: (context, navSettings, child) {
              return ExpansionTile(
                leading: const Icon(Icons.navigation),
                title: const Text('Navigation Settings'),
                subtitle: const Text('Customize navigation behavior'),
                children: [
                  SwitchListTile(
                    title: const Text('Bottom Navigation'),
                    subtitle: const Text('Show bottom navigation bar'),
                    value: navSettings.bottomNavEnabled,
                    onChanged: (value) async {
                      await navSettings.setBottomNavEnabled(value);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bottom navigation ${value ? 'enabled' : 'disabled'}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Camera Button (FAB)'),
                    subtitle: const Text('Show floating camera button'),
                    value: navSettings.fabEnabled,
                    onChanged: (value) async {
                      await navSettings.setFabEnabled(value);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Camera button ${value ? 'enabled' : 'disabled'}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
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
                      onChanged: (value) async {
                        if (value != null) {
                          await navSettings.setNavigationStyle(value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Navigation style changed to $value'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),

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

          // Navigation Styles Demo
          ListTile(
            leading: const Icon(Icons.navigation, color: Colors.blue),
            title: const Text('Navigation Styles'),
            subtitle: const Text('Try different navigation designs'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NavigationDemoScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Modern UI Showcase
          ListTile(
            leading: const Icon(Icons.design_services, color: Colors.purple),
            title: const Text('Modern UI Components'),
            subtitle: const Text('Showcase of new design elements'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: const Text(
                'UPDATED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernUIShowcaseScreen(),
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

          // Sign Out / Switch Account
          FutureBuilder<bool>(
            future: googleDriveService.isSignedIn(),
            builder: (context, snapshot) {
              final bool isSignedIn = snapshot.data ?? false;
              
              return ListTile(
                leading: Icon(
                  isSignedIn ? Icons.logout : Icons.account_circle_outlined,
                  color: isSignedIn ? Colors.red : Colors.blue,
                ),
                title: Text(isSignedIn ? 'Sign Out' : 'Switch to Google Account'),
                subtitle: Text(
                  isSignedIn 
                      ? 'Sign out and return to login screen'
                      : 'Currently in guest mode - sign in to sync data',
                ),
                onTap: () => _handleAccountAction(context, isSignedIn, googleDriveService),
              );
            },
          ),
          const Divider(),

          // Clear Data
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear Data'),
            subtitle: const Text('Reset all app data (history, settings, preferences)'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Data'),
                  content: const Text(
                    'Are you sure you want to clear ALL your data including classification history, settings, and preferences? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Clear analytics data first
                        analyticsService.clearAnalyticsData();
                        
                        // Clear all user data (includes proper gamification reset)
                        await storageService.clearAllUserData();
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data cleared successfully')),
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

  // Handle account actions (sign in/sign out)
  Future<void> _handleAccountAction(
    BuildContext context, 
    bool isSignedIn, 
    GoogleDriveService googleDriveService,
  ) async {
    if (isSignedIn) {
      // Show sign out confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out? You can sign back in anytime to sync your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Signing out...'),
                        ],
                      ),
                    ),
                  );
                  
                  // Perform sign out
                  await googleDriveService.signOut();
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    // Navigate back to auth screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Currently in guest mode, show sign in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch to Google Account'),
          content: const Text(
            'You are currently using the app in guest mode. Would you like to sign in with your Google account to sync your data across devices?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay in Guest Mode'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                
                // Navigate to auth screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }
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

  void _showFactoryResetDialog(
    BuildContext context,
    StorageService storageService,
    AnalyticsService analyticsService,
    PremiumService premiumService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Factory Reset'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will completely reset the app to factory settings and delete ALL data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• All classification history'),
            Text('• All gamification progress (points, streaks, achievements)'),
            Text('• All user preferences and settings'),
            Text('• All cached data'),
            Text('• All premium feature settings'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Resetting app to factory settings...'),
                    ],
                  ),
                ),
              );
              
              try {
                // Clear all analytics data
                analyticsService.clearAnalyticsData();
                
                // Reset all premium features
                await premiumService.resetPremiumFeatures();
                
                // Clear all user data (includes gamification reset)
                await storageService.clearAllUserData();
                
                // Clear enhanced storage cache if available
                if (storageService is EnhancedStorageService) {
                  (storageService as EnhancedStorageService).clearCache();
                }
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App has been reset to factory settings'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error during factory reset: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('FACTORY RESET'),
          ),
        ],
      ),
    );
  }
}