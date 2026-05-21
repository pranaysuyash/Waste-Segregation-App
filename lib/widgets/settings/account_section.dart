import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/google_drive_service.dart';
import '../../services/firebase_cleanup_service.dart';
import '../../services/storage_service.dart';
import '../../utils/routes.dart';
import '../../utils/dialog_helper.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Account management section for settings screen
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.accountSection),

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
                  title: isSignedIn ? t.signOut : t.switchToGoogle,
                  subtitle:
                      isSignedIn ? t.signOutSubtitle : t.guestModeSubtitle,
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
          title: t.resetAppData,
          subtitle: t.resetAppDataSubtitle,
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
        if (!context.mounted) return;
        await _signOut(context, googleDriveService);
      }
    } else {
      // Navigate to auth screen for sign in
      await _navigateToAuth(context);
    }
  }

  Future<bool?> _showSignOutConfirmation(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DialogHelper.confirm(
      context,
      title: t.signOutConfirmTitle,
      body: t.signOutConfirmBody,
      okLabel: t.signOut,
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
        await Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.auth,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showErrorSnackBar(
          context,
          t.signOutFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _navigateToAuth(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final result = await Navigator.of(context).pushNamed(Routes.auth);

    if (result == true && context.mounted) {
      SettingsTheme.showSuccessSnackBar(
        context,
        t.successfullySignedIn,
      );
    }
  }

  Future<void> _confirmAndExecuteReset(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final shouldReset = await DialogHelper.confirm(
      context,
      title: t.factoryReset,
      body: t.factoryResetBody,
      okLabel: t.clearData,
      isDangerous: true,
    );

    if (shouldReset == true && context.mounted) {
      await _performFullReset(context);
    }
  }

  Future<void> _performFullReset(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    await DialogHelper.loading(
      context,
      () async {
        final cleanupService = FirebaseCleanupService();
        await cleanupService.clearAllDataForFreshInstall();
        // Reinitialize Hive boxes after reset to prevent "Box has already been closed" errors
        await StorageService.reinitializeAfterReset();

        if (context.mounted) {
          SettingsTheme.showSuccessSnackBar(
            context,
            t.allDataClearedSuccessfully,
          );

          await Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.auth,
            (route) => false,
          );
        }
      },
      message: t.resettingAllData,
    ).catchError((e) {
      if (context.mounted) {
        final t = AppLocalizations.of(context)!;
        SettingsTheme.showErrorSnackBar(
          context,
          t.dataClearingFailed(e.toString()),
        );
      }
    });
  }
}
