import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';

class SyncSection extends StatefulWidget {
  const SyncSection({super.key});

  @override
  State<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<SyncSection> {
  bool _isGoogleSyncEnabled = true;
  DateTime? _lastCloudSync;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoogleSyncSetting();
  }

  Future<void> _loadGoogleSyncSetting() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      final lastSync = await storageService.getLastCloudSync();
      if (mounted) {
        setState(() {
          _isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? true;
          _lastCloudSync = lastSync;
          _isLoading = false;
        });
      }
    } catch (e) {
      WasteAppLogger.severe('Error loading Google sync setting: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleGoogleSync(bool value) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);

      final currentSettings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: currentSettings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: value,
      );

      setState(() => _isGoogleSyncEnabled = value);

      if (value) {
        _showSyncEnableDialog(cloudStorageService);
      } else {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showInfoSnackBar(context, t.googleSyncDisabled);
      }
    } catch (e) {
      final t = AppLocalizations.of(context)!;
      SettingsTheme.showErrorSnackBar(
          context, t.failedToToggleGoogleSync(e.toString()));
    }
  }

  void _showSyncEnableDialog(CloudStorageService cloudStorageService) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.googleSyncEnabled),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.googleSyncEnabledMessage),
            const SizedBox(height: 16),
            const Text(
                'Would you like to upload your existing local classifications to the cloud?'),
            const SizedBox(height: 8),
            const Text(
                'This will make them available across all your devices.'),
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

      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);
      final syncedCount =
          await cloudStorageService.syncAllLocalClassificationsToCloud();

      if (syncedCount > 0) {
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        final lastSync = await storageService.getLastCloudSync();
        if (mounted) {
          setState(() => _lastCloudSync = lastSync);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        if (syncedCount > 0) {
          SettingsTheme.showSuccessSnackBar(
            context,
            'Successfully synced $syncedCount classifications to cloud!',
          );
        } else {
          SettingsTheme.showInfoSnackBar(
            context,
            'No classifications were synced.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SettingsTheme.showErrorSnackBar(context, 'Sync failed: $e');
      }
    }
  }

  Future<void> _forceDownloadFromCloud() async {
    try {
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

      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);
      final downloadedCount = await cloudStorageService.syncCloudToLocal();

      if (mounted) {
        Navigator.pop(context);
        if (downloadedCount > 0) {
          SettingsTheme.showSuccessSnackBar(
            context,
            'Downloaded $downloadedCount classifications from cloud!',
          );
        } else {
          SettingsTheme.showInfoSnackBar(
            context,
            'No classifications were downloaded.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SettingsTheme.showErrorSnackBar(context, 'Download failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.googleCloudSync),
        SettingToggleTile(
          icon: _isGoogleSyncEnabled ? Icons.cloud_done : Icons.cloud_off,
          iconColor:
              _isGoogleSyncEnabled ? SettingsTheme.successColor : Colors.grey,
          title: t.googleCloudSync,
          subtitle: _isGoogleSyncEnabled
              ? 'Classifications sync to cloud automatically'
              : 'Classifications saved locally only',
          value: _isGoogleSyncEnabled,
          onChanged: _toggleGoogleSync,
        ),
        if (_isGoogleSyncEnabled) ...[
          if (_lastCloudSync != null)
            SettingTile(
              icon: Icons.cloud_done,
              iconColor: SettingsTheme.successColor,
              title: t.lastCloudSync,
              subtitle: DateFormat.yMd().add_Hm().format(_lastCloudSync!),
            ),
          SettingTile(
            icon: Icons.cloud_upload,
            iconColor: SettingsTheme.themeColor,
            title: t.syncLocalDataToCloud,
            subtitle: t.syncLocalDataSubtitle,
            onTap: _syncLocalDataToCloud,
          ),
          SettingTile(
            icon: Icons.cloud_download,
            iconColor: SettingsTheme.themeColor,
            title: t.forceDownloadFromCloud,
            subtitle: t.forceDownloadSubtitle,
            onTap: _forceDownloadFromCloud,
          ),
        ],
      ],
    );
  }
}
