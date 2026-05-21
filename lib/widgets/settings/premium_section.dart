import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/routes.dart';
import 'setting_tile.dart';
import 'settings_theme.dart';

/// Premium features section for settings screen
class PremiumSection extends StatelessWidget {
  const PremiumSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.premiumSection),
        SettingTile(
          icon: Icons.workspace_premium,
          iconColor: SettingsTheme.premiumColor,
          title: t.premiumFeatures,
          subtitle: t.premiumFeaturesSubtitle,
          onTap: () => _navigateToPremiumFeatures(context),
        ),
      ],
    );
  }

  void _navigateToPremiumFeatures(BuildContext context) {
    Navigator.pushNamed(context, Routes.premiumFeatures);
  }
}
