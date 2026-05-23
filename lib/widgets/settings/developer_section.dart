import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/classification_migration_service.dart';
import 'package:waste_segregation_app/services/firebase_cleanup_service.dart';
import 'package:waste_segregation_app/utils/developer_config.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/utils/dialog_helper.dart';
import 'package:waste_segregation_app/utils/routes.dart';

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
        _buildDeveloperHeader(context),
        const SizedBox(height: 16),
        _buildFeatureToggles(context),
        const SizedBox(height: 16),
        _buildDevToolTiles(context),
        const SizedBox(height: 16),
        _buildDangerousActions(context),
      ],
    );
  }

  Widget _buildDeveloperHeader(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bug_report, color: SettingsTheme.developerColor),
            const SizedBox(width: 8),
            Text(t.developerOptions,
                style: SettingsTheme.developerModeTitle(context)),
            const Spacer(),
            Consumer<PremiumService>(
              builder: (context, premiumService, child) {
                return TextButton(
                  onPressed: () => _resetAllPremiumFeatures(
                    context,
                    premiumService,
                  ),
                  child: Text(t.resetAll),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(t.toggleFeaturesForTesting,
            style: SettingsTheme.developerModeSubtitle(context)),
      ],
    );
  }

  Widget _buildFeatureToggles(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        return Column(
          children: [
            _buildTestModeFeature(
                context, t.removeAds, 'remove_ads', premiumService),
            _buildTestModeFeature(
              context,
              t.themeCustomization,
              'theme_customization',
              premiumService,
            ),
            _buildTestModeFeature(
                context, t.offlineMode, 'offline_mode', premiumService),
            _buildTestModeFeature(
              context,
              t.advancedAnalyticsFeature,
              'advanced_analytics',
              premiumService,
            ),
            _buildTestModeFeature(
                context, t.exportData, 'export_data', premiumService),
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
    final t = AppLocalizations.of(context)!;
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(t.testModeFeature(featureKey.replaceAll('_', ' '))),
      value: premiumService.isPremiumFeature(featureKey),
      onChanged: (value) async {
        await premiumService.setPremiumFeature(featureKey, value);
        if (context.mounted) {
          SettingsTheme.showInfoSnackBar(
            context,
            t.featureEnabledForTesting(title, value ? t.enabled : t.disabled),
          );
        }
      },
    );
  }

  Widget _buildDevToolTiles(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        SettingTile(
          icon: Icons.design_services,
          iconColor: Colors.purple,
          title: t.modernUIComponents,
          subtitle: t.modernUIComponentsSubtitle,
          onTap: () => Navigator.pushNamed(context, Routes.modernUIShowcase),
        ),
        SettingTile(
          icon: Icons.navigation,
          iconColor: SettingsTheme.navigationColor,
          title: t.navigationStyles,
          subtitle: t.navigationStylesSubtitle,
          onTap: () => Navigator.pushNamed(context, Routes.navigationDemo),
        ),
      ],
    );
  }

  Widget _buildDangerousActions(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Crash test button (secure debug only)
        if (DeveloperConfig.canShowCrashTest)
          _buildDangerButton(
            context,
            icon: Icons.warning,
            label: t.forceCrashTest,
            color: SettingsTheme.dangerColor,
            onPressed: () => _forceCrash(context),
          ),

        const SizedBox(height: 8),

        // Consolidated Data Reset Button
        _buildDangerButton(
          context,
          icon: Icons.delete_forever,
          label: t.clearFirebaseDataFresh,
          color: SettingsTheme.dangerColor,
          onPressed: () => _confirmAndClearAllData(context),
        ),

        const SizedBox(height: 8),

        // Migration button for updating old classifications
        _buildDangerButton(
          context,
          icon: Icons.update,
          label: t.migrateOldClassifications,
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
      final t = AppLocalizations.of(context)!;
      SettingsTheme.showSuccessSnackBar(
        context,
        t.allPremiumFeaturesReset,
      );
    }
  }

  void _forceCrash(BuildContext context) {
    FirebaseCrashlytics.instance.crash();
  }

  void _confirmAndClearAllData(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.clearFirebaseData),
          content: Text(t.clearFirebaseDataBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performFullDataClear(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: SettingsTheme.dangerColor,
              ),
              child: Text(t.clearData),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performFullDataClear(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    await DialogHelper.loading(
      context,
      () async {
        final cleanupService = FirebaseCleanupService();
        await cleanupService.clearAllDataForFreshInstall();
        // Reinitialize Hive boxes after reset to prevent "Box has already been closed" errors
        await StorageService.reinitializeAfterReset();
      },
      message: t.resettingAllData,
    ).then((_) {
      if (context.mounted) {
        SettingsTheme.showSuccessSnackBar(
          context,
          t.allDataClearedSuccessfully,
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showErrorSnackBar(
          context,
          t.dataClearingFailed(e.toString()),
        );
      }
    });
  }

  Future<void> _runClassificationMigration(BuildContext context) async {
    try {
      final t = AppLocalizations.of(context)!;
      final storageService = context.read<StorageService>();
      final cloudStorageService = context.read<CloudStorageService>();
      final migrationService = ClassificationMigrationService(
        storageService,
        cloudStorageService,
      );

      // Run migration to update old classifications with images and sync to cloud
      final result = await migrationService.migrateOldClassifications();

      if (context.mounted) {
        if (result.success) {
          SettingsTheme.showSuccessSnackBar(
            context,
            t.migrationCompleted(
              result.updated,
              result.skipped,
              result.errors,
            ),
          );
        } else {
          SettingsTheme.showErrorSnackBar(
            context,
            t.migrationFailed(result.message),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showErrorSnackBar(
          context,
          t.migrationFailed(e.toString()),
        );
      }
    }
  }
}
