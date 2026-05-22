import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/training_data_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';

class PrivacySection extends StatefulWidget {
  const PrivacySection({super.key});

  @override
  State<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<PrivacySection> {
  bool _isLeaderboardOptOut = false;
  bool _isTrainingConsentEnabled = false;
  bool _isTrainingConsentLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    await Future.wait([
      _loadLeaderboardOptOut(),
      _loadTrainingConsent(),
    ]);
  }

  Future<void> _loadLeaderboardOptOut() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final userProfile = await storageService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          final prefs = userProfile?.preferences;
          _isLeaderboardOptOut = prefs != null &&
              prefs.containsKey(UserPreferenceKeys.leaderboardOptOut) &&
              prefs[UserPreferenceKeys.leaderboardOptOut] == true;
        });
      }
    } catch (e) {
      WasteAppLogger.severe('Error loading leaderboard opt-out setting: $e');
    }
  }

  Future<void> _toggleLeaderboardOptOut(bool value) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);

      final userProfile = await storageService.getCurrentUserProfile();
      if (userProfile == null) {
        if (mounted) {
          SettingsTheme.showErrorSnackBar(
            context,
            'No user profile found. Please sign in first.',
          );
        }
        return;
      }

      final updatedPreferences =
          Map<String, dynamic>.from(userProfile.preferences ?? {});
      updatedPreferences[UserPreferenceKeys.leaderboardOptOut] = value;

      final updatedProfile =
          userProfile.copyWith(preferences: updatedPreferences);

      await storageService.saveUserProfile(updatedProfile);
      await cloudStorageService.saveUserProfileToFirestore(updatedProfile);
      await cloudStorageService
          .updateLeaderboardPrivacyPreference(updatedProfile);

      if (mounted) {
        setState(() {
          _isLeaderboardOptOut = value;
        });
        SettingsTheme.showSuccessSnackBar(
          context,
          value
              ? 'You are now hidden from the leaderboard'
              : 'You are now visible on the leaderboard',
        );
      }
    } catch (e) {
      if (mounted) {
        SettingsTheme.showErrorSnackBar(
          context,
          'Failed to update leaderboard privacy: $e',
        );
      }
    }
  }

  Future<void> _loadTrainingConsent() async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final profile = await storage.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _isTrainingConsentEnabled = profile?.trainingConsent.enabled ?? false;
          _isTrainingConsentLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTrainingConsentEnabled = false;
          _isTrainingConsentLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTrainingConsent(bool enabled) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final service = TrainingDataService(storageService: storage);

    setState(() => _isTrainingConsentLoading = true);
    try {
      if (enabled) {
        await storage.grantTrainingConsent(source: 'settings');
      } else {
        await service.revokeConsentAndRequestDeletion();
      }
      if (mounted) {
        setState(() {
          _isTrainingConsentEnabled = enabled;
          _isTrainingConsentLoading = false;
        });
        SettingsTheme.showSuccessSnackBar(
          context,
          enabled
              ? 'Training consent enabled.'
              : 'Training consent revoked and deletion requested.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTrainingConsentLoading = false);
        SettingsTheme.showErrorSnackBar(
          context,
          'Could not update training consent: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Privacy & Consent'),
        SettingToggleTile(
          icon: _isLeaderboardOptOut ? Icons.visibility_off : Icons.leaderboard,
          iconColor: _isLeaderboardOptOut ? Colors.orange : Colors.green,
          title: 'Hide from Leaderboard',
          subtitle: _isLeaderboardOptOut
              ? 'Your name and photo are hidden on the leaderboard'
              : 'Your name and photo are visible on the leaderboard',
          value: _isLeaderboardOptOut,
          onChanged: _toggleLeaderboardOptOut,
        ),
        SettingToggleTile(
          icon: _isTrainingConsentEnabled
              ? Icons.verified_user
              : Icons.shield_outlined,
          iconColor:
              _isTrainingConsentEnabled ? Colors.green : Colors.grey.shade600,
          title: 'Improve model with my images',
          subtitle: _isTrainingConsentEnabled
              ? 'Enabled. You can revoke anytime and request '
                  'deletion of contributed training candidates.'
              : 'Disabled. No new image/correction enters training candidates.',
          value: _isTrainingConsentEnabled,
          onChanged: _toggleTrainingConsent,
          enabled: !_isTrainingConsentLoading,
        ),
      ],
    );
  }
}
