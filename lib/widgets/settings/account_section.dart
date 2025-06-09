import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/google_drive_service.dart';
import '../../services/firebase_cleanup_service.dart';
import '../../utils/routes.dart';
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
        
        // Reset Account
        SettingTile(
          icon: Icons.refresh,
          iconColor: SettingsTheme.dataColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Reset Account',
          subtitle: 'Archive & clear your data, keep login credentials',
          onTap: () => _confirmReset(context),
        ),
        
        // Delete Account
        SettingTile(
          icon: Icons.delete_forever,
          iconColor: SettingsTheme.dangerColor,
          titleColor: SettingsTheme.dangerColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Delete Account',
          subtitle: 'Archive & clear all data, then delete your account',
          onTap: () => _confirmDelete(context),
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
          Routes.auth,
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
    final result = await Navigator.of(context).pushNamed(Routes.auth);
    
    // If user successfully signed in, show success message
    if (result == true && context.mounted) {
      // TODO(i18n): Localize success message
      SettingsTheme.showSuccessSnackBar(
        context,
        'Successfully signed in to Google account',
      );
    }
  }

  /// Show confirmation dialog for account reset
  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reset Account?'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will archive and clear your data but keep you signed out. You can sign back in with the same credentials.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text('• All classification history will be archived'),
              Text('• All gamification progress will be archived'),
              Text('• All settings and preferences will be archived'),
              Text('• Local data will be cleared'),
              Text('• You will be signed out'),
              SizedBox(height: 12),
              Text(
                'You can sign back in anytime with the same account.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset Account'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true && context.mounted) {
      await _performReset(context);
    }
  }

  /// Show confirmation dialog for account deletion
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account?'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will archive all your data and delete your account permanently.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• All data will be archived for admin purposes'),
              Text('• Your account will be permanently deleted'),
              Text('• You will NOT be able to sign in again'),
              Text('• Local data will be cleared'),
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await _performDelete(context);
    }
  }

  /// Perform account reset
  Future<void> _performReset(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Resetting account...'),
              ],
            ),
          );
        },
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final cleanupService = FirebaseCleanupService();
      await cleanupService.resetAccount(currentUser.uid);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message and navigate to auth screen
        SettingsTheme.showSuccessSnackBar(
          context,
          'Account reset successfully. You can sign back in anytime.',
        );

        // Navigate to auth screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.auth,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        SettingsTheme.showErrorSnackBar(
          context,
          'Error resetting account: ${e.toString()}',
        );
      }
    }
  }

  /// Perform account deletion
  Future<void> _performDelete(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final cleanupService = FirebaseCleanupService();
      await cleanupService.deleteAccount(currentUser.uid);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message and navigate to welcome screen
        SettingsTheme.showSuccessSnackBar(
          context,
          'Account deleted successfully.',
        );

        // Navigate to welcome/auth screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.auth,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        SettingsTheme.showErrorSnackBar(
          context,
          'Error deleting account: ${e.toString()}',
        );
      }
    }
  }
} 