import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/google_drive_service.dart';
import '../../services/firebase_cleanup_service.dart';
import '../../services/gamification_service.dart';
import '../../utils/dialog_helper.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Account management section for settings screen
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(i18n): Localize section header
        const SettingsSectionHeader(title: 'Account'),
        
        Consumer<GoogleDriveService>(
          builder: (context, googleDriveService, child) {
            return FutureBuilder<bool>(
              future: googleDriveService.isSignedIn(),
              builder: (context, snapshot) {
                final isSignedIn = snapshot.data ?? false;
                
                return SettingTile(
                  icon: isSignedIn ? Icons.logout : Icons.login,
                  iconColor: isSignedIn 
                      ? SettingsTheme.accountSignOutColor 
                      : SettingsTheme.accountSignInColor,
                  titleColor: isSignedIn 
                      ? SettingsTheme.accountSignOutColor 
                      : SettingsTheme.accountSignInColor,
                  // TODO(i18n): Localize title and subtitle
                  title: isSignedIn ? 'Sign Out' : 'Switch to Google Account',
                  subtitle: isSignedIn 
                      ? 'Sign out and return to login screen'
                      : 'Currently in guest mode - sign in to sync data',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isSignedIn 
                        ? SettingsTheme.accountSignOutColor 
                        : SettingsTheme.accountSignInColor,
                  ),
                  onTap: () => _handleAccountAction(
                    context, 
                    isSignedIn, 
                    googleDriveService,
                  ),
                );
              },
            );
          },
        ),
        
        // Simplified Reset
        SettingTile(
          icon: Icons.delete_forever,
          iconColor: SettingsTheme.dangerColor,
          titleColor: SettingsTheme.dangerColor,
          title: 'Reset App Data',
          subtitle: 'Clear all local and cloud data for a fresh start',
          onTap: () => _confirmAndExecuteReset(context),
        ),
      ],
    );
  }

  Future<void> _handleAccountAction(
    BuildContext context,
    bool isSignedIn,
    GoogleDriveService googleDriveService,
  ) async {
    if (isSignedIn) {
      // Show confirmation dialog before signing out
      final shouldSignOut = await _showSignOutConfirmation(context);
      if (shouldSignOut == true) {
        await _signOut(context, googleDriveService);
      }
    } else {
      // Navigate to auth screen for sign in
      await _navigateToAuth(context);
    }
  }

  Future<bool?> _showSignOutConfirmation(BuildContext context) {
    return DialogHelper.confirm(
      context,
      title: 'Sign Out', // TODO(i18n): Localize
      body: 'Are you sure you want to sign out? Your data will remain on this device, '
            'but you won\'t be able to sync with the cloud.', // TODO(i18n): Localize
      okLabel: 'Sign Out', // TODO(i18n): Localize
      isDangerous: true,
    );
  }

  Future<void> _signOut(
    BuildContext context,
    GoogleDriveService googleDriveService,
  ) async {
    try {
      await googleDriveService.signOut();
      
      if (context.mounted) {
        // Navigate to auth screen after successful sign out
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // TODO(i18n): Localize error message
        SettingsTheme.showErrorSnackBar(
          context,
          'Failed to sign out: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _navigateToAuth(BuildContext context) async {
            final result = await Navigator.of(context).pushNamed('/');
    
    // If user successfully signed in, show success message
    if (result == true && context.mounted) {
      // TODO(i18n): Localize success message
      SettingsTheme.showSuccessSnackBar(
        context,
        'Successfully signed in to Google account',
      );
    }
  }

  Future<void> _confirmAndExecuteReset(BuildContext context) async {
    final shouldReset = await DialogHelper.confirm(
      context,
      title: 'Reset All App Data?',
      body: 'This will permanently delete all your classifications, points, and settings from this device and the cloud. This action cannot be undone.',
      okLabel: 'DELETE EVERYTHING',
      isDangerous: true,
    );

    if (shouldReset == true && context.mounted) {
      await _performFullReset(context);
    }
  }

  Future<void> _performFullReset(BuildContext context) async {
    await DialogHelper.loading(
      context,
      () async {
        final cleanupService = FirebaseCleanupService();
        await cleanupService.clearAllDataForFreshInstall();
        
        if (context.mounted) {
          SettingsTheme.showSuccessSnackBar(
            context,
            'All data has been cleared. Please restart the app.',
          );

          await Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      },
      message: 'Resetting all data...',
    ).catchError((e) {
      if (context.mounted) {
        SettingsTheme.showErrorSnackBar(
          context,
          'Error resetting data: ${e.toString()}',
        );
      }
    });
  }
} 