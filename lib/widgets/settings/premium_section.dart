import 'package:flutter/material.dart';
import '../../screens/premium_features_screen.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Premium features section for settings screen
class PremiumSection extends StatelessWidget {
  const PremiumSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header is handled by parent
        
        SettingTile(
          icon: Icons.workspace_premium,
          iconColor: SettingsTheme.premiumColor,
          // TODO(i18n): Localize title and subtitle
          title: 'Premium Features',
          subtitle: 'Unlock advanced features',
          onTap: () => _navigateToPremiumFeatures(context),
        ),
      ],
    );
  }

  void _navigateToPremiumFeatures(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumFeaturesScreen(),
      ),
    );
  }
} 