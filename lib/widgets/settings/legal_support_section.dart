import 'package:flutter/material.dart';
import '../../screens/legal_document_screen.dart';
import '../../utils/app_version.dart';
import 'setting_tile.dart';
import '../../l10n/app_localizations.dart';
import 'settings_theme.dart';

/// Legal and support section for settings screen
class LegalSupportSection extends StatelessWidget {
  const LegalSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.legalSupportSection),
        SettingTile(
          icon: Icons.privacy_tip,
          iconColor: SettingsTheme.legalColor,
          title: t.privacyPolicy,
          subtitle: t.privacyPolicySubtitle,
          onTap: () => _navigateToLegalDocument(
            context,
            t.privacyPolicy,
            'assets/docs/privacy_policy.md',
          ),
        ),
        SettingTile(
          icon: Icons.description,
          iconColor: SettingsTheme.legalColor,
          title: t.termsOfService,
          subtitle: t.termsOfServiceSubtitle,
          onTap: () => _navigateToLegalDocument(
            context,
            t.termsOfService,
            'assets/docs/terms_of_service.md',
          ),
        ),
        SettingTile(
          icon: Icons.help,
          iconColor: Colors.blue,
          title: t.helpSupport,
          subtitle: t.helpSupportSubtitle,
          onTap: () => _showSupportOptions(context),
        ),
        SettingTile(
          icon: Icons.info_outline,
          iconColor: Colors.indigo,
          title: t.about,
          subtitle: t.aboutSubtitle,
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  void _navigateToLegalDocument(
    BuildContext context,
    String title,
    String assetPath,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.helpSupport,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: Text(t.contactSupport),
                subtitle: Text(t.contactSupportSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  _contactSupport(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: Text(t.reportBug),
                subtitle: Text(t.reportBugSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  _reportBug(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(t.rateApp),
                subtitle: Text(t.rateAppSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  _rateApp(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Waste Segregation App',
      applicationVersion: AppVersion.displayVersion,
      applicationIcon: const Icon(
        Icons.recycling,
        size: 48,
        color: Colors.green,
      ),
      children: [
        const Text(
            'A smart waste classification app that helps you sort waste correctly and track your environmental impact.'),
        const SizedBox(height: 16),
        const Text('Built with Flutter and powered by AI to make waste management easier and more effective.'),
      ],
    );
  }

  void _contactSupport(BuildContext context) {
    // TODO: Implement email support functionality
    SettingsTheme.showInfoSnackBar(
      context,
      'Support contact feature coming soon!',
    );
  }

  void _reportBug(BuildContext context) {
    // TODO: Implement bug reporting functionality
    SettingsTheme.showInfoSnackBar(
      context,
      'Bug reporting feature coming soon!',
    );
  }

  void _rateApp(BuildContext context) {
    // TODO: Implement app rating functionality
    SettingsTheme.showInfoSnackBar(
      context,
      'App rating feature coming soon!',
    );
  }
}
