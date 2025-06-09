import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/premium_service.dart';
import '../../utils/routes.dart';
import '../../utils/dialog_helper.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Features and tools section for settings screen
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(i18n): Localize section header
        const SettingsSectionHeader(title: 'Features & Tools'),
        
        SettingTile(
          icon: Icons.design_services,
          iconColor: Colors.purple,
          // TODO(i18n): Localize title and subtitle
          title: 'Modern UI Components',
          subtitle: 'Showcase of new design elements',
          trailing: _buildUpdatedBadge(),
          onTap: () => _navigateToModernUIShowcase(context),
        ),
        
        Consumer<PremiumService>(
          builder: (context, premiumService, child) {
            return SettingTile(
              icon: Icons.offline_bolt,
              iconColor: Colors.indigo,
              // TODO(i18n): Localize title and subtitle
              title: 'Offline Mode',
              subtitle: 'Classify items without internet',
              trailing: _buildFeatureIndicator(
                context, 
                premiumService.isPremiumFeature('offline_mode'),
              ),
              onTap: () => _handleOfflineModeNavigation(
                context, 
                premiumService,
              ),
            );
          },
        ),
        
        SettingTile(
          icon: Icons.analytics,
          iconColor: Colors.green,
          // TODO(i18n): Localize title and subtitle
          title: 'Analytics',
          subtitle: 'View your waste classification insights',
          onTap: () => _navigateToAnalytics(context),
        ),
        
        Consumer<PremiumService>(
          builder: (context, premiumService, child) {
            return SettingTile(
              icon: Icons.analytics_outlined,
              iconColor: Colors.teal,
              // TODO(i18n): Localize title and subtitle
              title: 'Advanced Analytics',
              subtitle: 'Detailed insights and trends',
              trailing: _buildFeatureIndicator(
                context, 
                premiumService.isPremiumFeature('advanced_analytics'),
              ),
              onTap: () => _handleAdvancedAnalyticsNavigation(
                context, 
                premiumService,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpdatedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'UPDATED',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildFeatureIndicator(BuildContext context, bool isPremium) {
    if (isPremium) {
      return const Icon(Icons.chevron_right);
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: SettingsTheme.premiumColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SettingsTheme.premiumColor.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: SettingsTheme.premiumColor,
          ),
        ),
      );
    }
  }

  void _navigateToModernUIShowcase(BuildContext context) {
    Navigator.pushNamed(context, Routes.modernUIShowcase);
  }

  void _handleOfflineModeNavigation(
    BuildContext context, 
    PremiumService premiumService,
  ) {
    if (premiumService.isPremiumFeature('offline_mode')) {
      // Navigate to offline mode settings
      // This would be implemented when the screen is available
      SettingsTheme.showInfoSnackBar(
        context,
        'Offline mode settings coming soon!',
      );
    } else {
      _showPremiumFeaturePrompt(context, 'Offline Mode');
    }
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, Routes.wasteDashboard);
  }

  void _handleAdvancedAnalyticsNavigation(
    BuildContext context, 
    PremiumService premiumService,
  ) {
    if (premiumService.isPremiumFeature('advanced_analytics')) {
      // Navigate to advanced analytics
      _navigateToAnalytics(context);
    } else {
      _showPremiumFeaturePrompt(context, 'Advanced Analytics');
    }
  }

  void _showPremiumFeaturePrompt(BuildContext context, String featureName) {
    DialogHelper.showPremiumPrompt(
      context,
      featureName: featureName,
      onUpgrade: () {
        // Navigate to premium features screen
        Navigator.pushNamed(context, Routes.premiumFeatures);
      },
    );
  }
} 