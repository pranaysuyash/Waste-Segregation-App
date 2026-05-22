import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/widgets/navigation_wrapper.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';
import 'package:waste_segregation_app/utils/constants.dart';

class NavigationDemoScreen extends StatelessWidget {
  const NavigationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Styles Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Navigation Style',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                const Text(
                  'Select from modern Android navigation styles inspired by popular apps',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge * 2),
                Expanded(
                  child: Consumer<NavigationSettingsService>(
                    builder: (context, navSettings, child) {
                      final currentStyle = navSettings.navigationStyle;
                      return ListView(
                        children: [
                          _buildNavigationStyleCard(
                            context,
                            title: 'Glassmorphism Style',
                            description:
                                'Modern iOS/Android style with glass effect and smooth animations',
                            icon: Icons.blur_on,
                            color: Colors.blue,
                            style: 'glassmorphism',
                            examples:
                                'Used by: Spotify, Instagram, iOS Control Center',
                            isSelected: currentStyle == 'glassmorphism',
                            navSettings: navSettings,
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          _buildNavigationStyleCard(
                            context,
                            title: 'Material 3 Design',
                            description:
                                'Google\'s latest Material Design with elevated surfaces and bold colors',
                            icon: Icons.design_services,
                            color: Colors.green,
                            style: 'material3',
                            examples:
                                'Used by: Google apps, Android 12+, Material You',
                            isSelected: currentStyle == 'material3',
                            navSettings: navSettings,
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          _buildNavigationStyleCard(
                            context,
                            title: 'Floating Navigation',
                            description:
                                'Elevated floating bar with rounded corners and subtle shadows',
                            icon: Icons.fiber_manual_record,
                            color: Colors.purple,
                            style: 'floating',
                            examples:
                                'Used by: Discord, Figma, Modern productivity apps',
                            isSelected: currentStyle == 'floating',
                            navSettings: navSettings,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationWrapper(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to App'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationStyleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String style,
    required String examples,
    required bool isSelected,
    required NavigationSettingsService navSettings,
  }) {
    return Card(
      elevation: isSelected ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          await navSettings.setNavigationStyle(style);
          if (context.mounted) {
            final t = AppLocalizations.of(context)!;
            SettingsTheme.showSuccessSnackBar(
              context,
              t.navigationStyleChanged(
                style == 'glassmorphism'
                    ? t.glassmorphism
                    : style == 'material3'
                        ? t.material3
                        : t.floating,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: AppTheme.paddingRegular),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeRegular,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 24)
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        examples,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
