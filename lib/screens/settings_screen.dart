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
import '../utils/developer_config.dart';
import 'premium_features_screen.dart';
import 'theme_settings_screen.dart';
import 'waste_dashboard_screen.dart';
import 'legal_document_screen.dart';
import 'offline_mode_settings_screen.dart';
import 'data_export_screen.dart';
import 'navigation_demo_screen.dart';
import 'modern_ui_showcase_screen.dart';
import 'auth_screen.dart';
import 'notification_settings_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/cloud_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showDeveloperOptions = false;
  bool _isGoogleSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadGoogleSyncSetting();
  }

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
          // Only show developer mode toggle when developer features are enabled
          if (DeveloperConfig.canShowDeveloperOptions)
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
          // Account Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // Sign Out / Switch Account - Moved to top for better accessibility
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: FutureBuilder<bool>(
              future: googleDriveService.isSignedIn(),
              builder: (context, snapshot) {
                final isSignedIn = snapshot.data ?? false;
                
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSignedIn ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSignedIn ? Icons.logout : Icons.login,
                      color: isSignedIn ? Colors.red : Colors.blue,
                    ),
                  ),
                  title: Text(
                    isSignedIn ? 'Sign Out' : 'Switch to Google Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSignedIn ? Colors.red : Colors.blue,
                    ),
                  ),
                  subtitle: Text(
                    isSignedIn 
                        ? 'Sign out and return to login screen'
                        : 'Currently in guest mode - sign in to sync data',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isSignedIn ? Colors.red : Colors.blue,
                  ),
                  onTap: () => _handleAccountAction(context, isSignedIn, googleDriveService),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Premium Features Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Premium',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
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
          ),
          
          const SizedBox(height: 16),
          
          // App Settings Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Developer Options Section (Secure Debug Only)
          if (DeveloperConfig.canShowDeveloperOptions && _showDeveloperOptions) ...[
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
                  // Crash test button (secure debug only)
                  if (DeveloperConfig.canShowCrashTest) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.warning, color: Colors.red),
                      label: const Text('Force Crash (Crashlytics Test)', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        FirebaseCrashlytics.instance.crash();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Factory reset button (secure debug only)
                  if (DeveloperConfig.canShowFactoryReset)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restore, color: Colors.orange),
                      label: const Text('Reset Full Data (Factory Reset)', style: TextStyle(color: Colors.orange)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      onPressed: () {
                        _showFactoryResetDialog(context, storageService, analyticsService, premiumService);
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
          ],

          // Navigation Settings
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Consumer<NavigationSettingsService>(
              builder: (context, navSettings, child) {
                return ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.navigation, color: Colors.blue),
                  ),
                  title: const Text(
                    'Navigation Settings',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
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
          ),

          const SizedBox(height: 8),

          // Theme Settings
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.palette, color: Colors.purple),
              ),
              title: const Text(
                'Theme Settings',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Customize app appearance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          // Notification Settings
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications, color: Colors.orange),
              ),
              title: const Text(
                'Notification Settings',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Manage your notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Features Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Features & Tools',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Navigation Styles Demo
          ListTile(
            leading: const Icon(Icons.navigation, color: Colors.blue),
            title: const Text('Navigation Styles'),
            subtitle: const Text('Try different navigation designs'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
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

          // Google Sync toggle
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: SwitchListTile(
              title: const Text('Google Cloud Sync'),
              subtitle: Text(
                _isGoogleSyncEnabled 
                    ? 'Classifications sync to cloud automatically'
                    : 'Classifications saved locally only',
              ),
              value: _isGoogleSyncEnabled,
              onChanged: (value) async {
                await _toggleGoogleSync(value);
              },
              secondary: Icon(
                _isGoogleSyncEnabled ? Icons.cloud_done : Icons.cloud_off,
                color: _isGoogleSyncEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ),
          
          // Feedback Settings
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedback Settings'),
              subtitle: const Text('Control when you can provide feedback'),
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: Provider.of<StorageService>(context, listen: false).getSettings(),
                  builder: (context, snapshot) {
                    final settings = snapshot.data ?? {};
                    final allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
                    final feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;
                    
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Allow Feedback on Recent History'),
                          subtitle: Text(
                            allowHistoryFeedback 
                                ? 'Can provide feedback on recent classifications from history'
                                : 'Can only provide feedback on new classifications',
                          ),
                          value: allowHistoryFeedback,
                          onChanged: (value) async {
                            await _toggleHistoryFeedback(value);
                            setState(() {}); // Trigger rebuild
                          },
                        ),
                        if (allowHistoryFeedback) ...[
                          ListTile(
                            title: const Text('Feedback Timeframe'),
                            subtitle: Text('Can provide feedback on items from last $feedbackTimeframeDays days'),
                            trailing: DropdownButton<int>(
                              value: feedbackTimeframeDays,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1 day')),
                                DropdownMenuItem(value: 3, child: Text('3 days')),
                                DropdownMenuItem(value: 7, child: Text('7 days')),
                                DropdownMenuItem(value: 14, child: Text('14 days')),
                                DropdownMenuItem(value: 30, child: Text('30 days')),
                              ],
                              onChanged: (value) async {
                                if (value != null) {
                                  await _updateFeedbackTimeframe(value);
                                  setState(() {}); // Trigger rebuild
                                }
                              },
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            allowHistoryFeedback 
                                ? 'Perfect for scanning multiple items quickly and providing feedback later when you have more time!'
                                : 'Feedback is only available immediately after classification.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Sync actions when Google sync is enabled
          if (_isGoogleSyncEnabled) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Sync Local Data to Cloud'),
                    subtitle: const Text('Upload existing local classifications to cloud'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _syncLocalDataToCloud,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('Force Download from Cloud'),
                    subtitle: const Text('Download latest data from cloud'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _forceDownloadFromCloud,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Data Management Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Clear Data
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: const Text(
                'Clear Data',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text('Reset all app data (history, settings, preferences)'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
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
                        
                        // Clear enhanced storage cache if available
                        if (storageService is EnhancedStorageService) {
                          storageService.clearCache();
                        }
                        
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
          ),

          const SizedBox(height: 16),

          // Legal & Support Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Legal & Support',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Legal Documents
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel, color: Colors.brown),
              ),
              title: const Text(
                'Legal',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Privacy Policy and Terms of Service'),
              trailing: const Icon(Icons.chevron_right),
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
          ),

          // About
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: Colors.blue),
              ),
              title: const Text(
                'About',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('App information and credits'),
              trailing: const Icon(Icons.chevron_right),
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
          ),

          const SizedBox(height: 16),
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
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text(
            'Enabled',
            style: TextStyle(color: Colors.green),
          ),
          SizedBox(width: 4),
          Icon(Icons.chevron_right),
        ],
      );
    } else {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Premium',
              style: TextStyle(color: Colors.amber),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.chevron_right),
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
              final currentCapturedContext = context; // Capture context before async gap

              Navigator.pop(currentCapturedContext); // Close confirmation dialog

              // Show loading dialog
              showDialog(
                context: currentCapturedContext, // Use captured context
                barrierDismissible: false,
                builder: (BuildContext dialogContext) { // It's good practice to name this context differently
                  return const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Resetting app to factory settings...'),
                      ],
                    ),
                  );
                },
              );

              String? snackBarMessage;
              Color? snackBarBackgroundColor;
              var success = false;

              try {
                // Clear all analytics data
                analyticsService.clearAnalyticsData();
                
                // Reset all premium features
                await premiumService.resetPremiumFeatures();
                
                // Clear all user data (includes gamification reset)
                await storageService.clearAllUserData();
                
                // Clear enhanced storage cache if available
                if (storageService is EnhancedStorageService) {
                  storageService.clearCache();
                }
                
                success = true;
                snackBarMessage = 'App has been reset to factory settings';
                snackBarBackgroundColor = Colors.green;

              } catch (e) {
                success = false;
                snackBarMessage = 'Error during factory reset: ${e.toString()}';
                snackBarBackgroundColor = Colors.red;
                debugPrint('Factory Reset Error: $e');
              } finally {
                // Pop the loading dialog. Uses currentCapturedContext's navigator.
                // This should happen regardless of success or failure of the try block.
                if (currentCapturedContext.mounted) {
                  Navigator.pop(currentCapturedContext); 
                } else {
                  // If the original context is unmounted, a root navigator pop might be needed
                  // For now, we assume the auth state change might have already rebuilt the tree.
                  // If the dialog is still stuck, a GlobalKey for the Navigator would be the next step.
                  debugPrint('SettingsScreen context was unmounted before trying to pop loading dialog.');
                }

                if (snackBarMessage != null) {
                  // Check mounted status again before showing SnackBar, as state might have changed
                  if (currentCapturedContext.mounted) {
                     ScaffoldMessenger.of(currentCapturedContext).showSnackBar(
                      SnackBar(
                        content: Text(snackBarMessage),
                        backgroundColor: snackBarBackgroundColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                     debugPrint('SettingsScreen context unmounted, cannot show SnackBar: $snackBarMessage');
                  }
                }
                
                // After everything, if successful, navigate to AuthScreen
                // Check mounted status before navigation as well
                if (success && currentCapturedContext.mounted) {
                  Navigator.of(currentCapturedContext).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (Route<dynamic> route) => false,
                  );
                } else if (!success && currentCapturedContext.mounted) {
                  // Stay on settings or current screen if reset failed and screen is still mounted
                  debugPrint('Factory reset failed, staying on current screen.');
                } else if (!currentCapturedContext.mounted) {
                  // If not mounted, assume an auth state listener has already handled navigation
                  debugPrint('SettingsScreen context unmounted, assuming navigation handled by auth listener.');
                }
              }
            },
            child: const Text('FACTORY RESET'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadGoogleSyncSetting() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      setState(() {
        _isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading Google sync setting: $e');
    }
  }

  Future<void> _toggleGoogleSync(bool value) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);
      
      // Update the setting
      final currentSettings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: currentSettings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: value,
      );
      
      setState(() {
        _isGoogleSyncEnabled = value;
      });
      
      if (value) {
        // When enabling sync, offer to upload existing data
        _showSyncEnableDialog(cloudStorageService);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sync disabled. Future classifications will be saved locally only.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle Google sync: $e')),
      );
    }
  }

  void _showSyncEnableDialog(CloudStorageService cloudStorageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sync Enabled'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Google sync is now enabled!'),
            SizedBox(height: 16),
            Text('Would you like to upload your existing local classifications to the cloud?'),
            SizedBox(height: 8),
            Text('This will make them available across all your devices.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _syncLocalDataToCloud();
            },
            child: const Text('Upload Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncLocalDataToCloud() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing data to cloud...'),
            ],
          ),
        ),
      );

      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);
      final syncedCount = await cloudStorageService.syncAllLocalClassificationsToCloud();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('Successfully synced $syncedCount classifications to cloud!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  Future<void> _forceDownloadFromCloud() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading from cloud...'),
            ],
          ),
        ),
      );

      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);
      final classifications = await cloudStorageService.getAllClassificationsWithCloudSync(true);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.white),
                const SizedBox(width: 8),
                Text('Downloaded ${classifications.length} classifications from cloud!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleHistoryFeedback(bool value) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: settings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        allowHistoryFeedback: value,
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle history feedback: $e')),
      );
    }
  }

  Future<void> _updateFeedbackTimeframe(int value) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: settings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        allowHistoryFeedback: settings['allowHistoryFeedback'] ?? true,
        feedbackTimeframeDays: value,
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update feedback timeframe: $e')),
      );
    }
  }
}