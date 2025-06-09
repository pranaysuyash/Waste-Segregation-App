import 'package:flutter/material.dart';
import '../../screens/legal_document_screen.dart';
import '../../utils/app_version.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Legal and support section for settings screen
class LegalSupportSection extends StatelessWidget {
  const LegalSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(i18n): Localize section header
        const SettingsSectionHeader(title: 'Legal & Support'),
        
        SettingTile(
          icon: Icons.privacy_tip,
          iconColor: SettingsTheme.legalColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          onTap: () => _navigateToLegalDocument(
            context, 
            'Privacy Policy',
            'assets/docs/privacy_policy.md',
          ),
        ),
        
        SettingTile(
          icon: Icons.description,
          iconColor: SettingsTheme.legalColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          onTap: () => _navigateToLegalDocument(
            context, 
            'Terms of Service',
            'assets/docs/terms_of_service.md',
          ),
        ),
        
        SettingTile(
          icon: Icons.help,
          iconColor: Colors.blue,
          // TODO(i18n): Localize title and subtitle
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () => _showSupportOptions(context),
        ),
        
        SettingTile(
          icon: Icons.info_outline,
          iconColor: Colors.indigo,
          // TODO(i18n): Localize title and subtitle
          title: 'About',
          subtitle: 'App version and information',
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
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO(i18n): Localize support options
              Text(
                'Help & Support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Contact Support'),
                subtitle: const Text('Send us an email'),
                onTap: () {
                  Navigator.pop(context);
                  _contactSupport(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Report a Bug'),
                subtitle: const Text('Help us improve the app'),
                onTap: () {
                  Navigator.pop(context);
                  _reportBug(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Rate the App'),
                subtitle: const Text('Leave a review'),
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
        // TODO(i18n): Localize about dialog content
        const Text(
          'A comprehensive Flutter application for proper waste identification, '
          'segregation guidance, and environmental education.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with Flutter and powered by AI for accurate waste classification.',
        ),
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