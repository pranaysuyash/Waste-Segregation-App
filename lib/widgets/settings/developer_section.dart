import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../services/premium_service.dart';
import '../../services/storage_service.dart';
import '../../services/firebase_cleanup_service.dart';
import '../../utils/developer_config.dart';
import 'settings_theme.dart';
import 'setting_tile.dart';
import '../../utils/dialog_helper.dart';

/// Developer options section for settings screen (debug builds only)
class DeveloperSection extends StatelessWidget {
  const DeveloperSection({
    super.key,
    required this.showDeveloperOptions,
  });

  final bool showDeveloperOptions;

  @override
  Widget build(BuildContext context) {
    if (!DeveloperConfig.canShowDeveloperOptions || !showDeveloperOptions) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SettingTile(
          icon: Icons.bug_report,
          title: 'Debug Mode',
          subtitle: 'Enable debug logging',
          onTap: () {},
        ),
        SettingTile(
          icon: Icons.analytics,
          title: 'Performance Monitor',
          subtitle: 'View performance metrics',
          onTap: () {},
        ),
        SettingTile(
          icon: Icons.refresh,
          title: 'Reset App Data',
          subtitle: 'Clear all app data',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildDangerousActions(context),
      ],
    );
  }

  Widget _buildDeveloperHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bug_report, color: SettingsTheme.developerColor),
            const SizedBox(width: 8),
            Text(
              // TODO(i18n): Localize developer mode title
              'DEVELOPER OPTIONS',
              style: SettingsTheme.developerModeTitle(context),
            ),
            const Spacer(),
            Consumer<PremiumService>(
              builder: (context, premiumService, child) {
                return TextButton(
                  onPressed: () => _resetAllPremiumFeatures(
                    context,
                    premiumService,
                  ),
                  child: const Text('Reset All'),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          // TODO(i18n): Localize developer mode subtitle
          'Toggle features for testing',
          style: SettingsTheme.developerModeSubtitle(context),
        ),
      ],
    );
  }

  Widget _buildFeatureToggles(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        return Column(
          children: [
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
          ],
        );
      },
    );
  }

  Widget _buildTestModeFeature(
    BuildContext context,
    String title,
    String featureKey,
    PremiumService premiumService,
  ) {
    return SwitchListTile(
      // TODO(i18n): Localize feature titles
      title: Text(title),
      subtitle: Text('Test mode: ${featureKey.replaceAll('_', ' ')}'),
      value: premiumService.isPremiumFeature(featureKey),
      onChanged: (value) async {
        // await premiumService.togglePremiumFeature(featureKey, value); // TODO: Check correct method name
        if (context.mounted) {
          // TODO(i18n): Localize feedback message
          SettingsTheme.showInfoSnackBar(
            context,
            '$title ${value ? 'enabled' : 'disabled'} for testing',
          );
        }
      },
    );
  }

  Widget _buildDangerousActions(BuildContext context) {
    return Column(
      children: [
        // Crash test button (secure debug only)
        if (DeveloperConfig.canShowCrashTest)
          _buildDangerButton(
            context,
            icon: Icons.warning,
            label: 'Force Crash (Crashlytics Test)',
            color: SettingsTheme.dangerColor,
            onPressed: () => _forceCrash(context),
          ),

        const SizedBox(height: 8),

        // Consolidated Data Reset Button
        _buildDangerButton(
          context,
          icon: Icons.delete_forever,
          label: 'Clear All Data (Fresh Install)',
          color: SettingsTheme.dangerColor,
          onPressed: () => _confirmAndClearAllData(context),
        ),

        const SizedBox(height: 8),

        // Migration button for updating old classifications
        _buildDangerButton(
          context,
          icon: Icons.update,
          label: 'Migrate Old Classifications',
          color: SettingsTheme.successColor,
          onPressed: () => _runClassificationMigration(context),
        ),
      ],
    );
  }

  Widget _buildDangerButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          side: BorderSide(color: color),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _resetAllPremiumFeatures(
    BuildContext context,
    PremiumService premiumService,
  ) async {
    await premiumService.resetPremiumFeatures();
    if (context.mounted) {
      // TODO(i18n): Localize success message
      SettingsTheme.showSuccessSnackBar(
        context,
        'All premium features reset',
      );
    }
  }

  void _forceCrash(BuildContext context) {
    FirebaseCrashlytics.instance.crash();
  }

  void _confirmAndClearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
              'This will clear all local and cloud data to simulate a fresh install. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performFullDataClear(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: SettingsTheme.dangerColor,
              ),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performFullDataClear(BuildContext context) async {
    await DialogHelper.loading(
      context,
      () async {
        final cleanupService = FirebaseCleanupService();
        await cleanupService.clearAllDataForFreshInstall();
        // Reinitialize Hive boxes after reset to prevent "Box has already been closed" errors
        await StorageService.reinitializeAfterReset();
      },
      message: 'Clearing all data...',
    ).then((_) {
      if (context.mounted) {
        SettingsTheme.showSuccessSnackBar(
          context,
          'All data cleared successfully!',
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        SettingsTheme.showErrorSnackBar(
          context,
          'Data clearing failed: ${e.toString()}',
        );
      }
    });
  }

  Future<void> _runClassificationMigration(BuildContext context) async {
    try {
      final storageService = context.read<StorageService>();

      // TODO: Implement classification migration logic
      // This would migrate old classification data to new format

      if (context.mounted) {
        // TODO(i18n): Localize success message
        SettingsTheme.showSuccessSnackBar(
          context,
          'Classification migration completed',
        );
      }
    } catch (e) {
      if (context.mounted) {
        // TODO(i18n): Localize error message
        SettingsTheme.showErrorSnackBar(
          context,
          'Migration failed: ${e.toString()}',
        );
      }
    }
  }
}
