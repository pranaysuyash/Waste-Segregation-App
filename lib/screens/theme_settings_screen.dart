import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../utils/routes.dart';
import '../utils/dialog_helper.dart';
import '../widgets/settings/premium_feature_visuals.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final premium = ref.read(premiumServiceProvider);
    final isPremium = premium.isPremiumFeature('theme_customization');

    return Scaffold(
      appBar: AppBar(
        title: Text(t.themeSettings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(t.systemDefault),
            subtitle: Text(t.followSystemTheme),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: Text(t.lightTheme),
            subtitle: Text(t.alwaysUseLight),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(t.darkTheme),
            subtitle: Text(t.alwaysUseDark),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: theme.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  _updateThemeMode(ref, value);
                }
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              t.premiumFeatures,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber),
              ),
              title: Text(
                t.premiumFeatures,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(t.premiumFeaturesSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, Routes.premiumFeatures);
              },
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: t.themeCustomization,
            value: PremiumFeatureVisuals.semanticsState(
              context,
              isUnlocked: isPremium,
            ),
            hint: isPremium
                ? t.themeSettingsSubtitle
                : t.upgradeToUse(t.themeCustomization),
            button: true,
            excludeSemantics: true,
            onTap: () {
              if (isPremium) {
                _showThemeCustomizationEnabledInfo(context, t);
              } else {
                _showPremiumFeaturePrompt(
                  context,
                  t,
                  featureName: t.themeCustomization,
                  benefit: t.themeSettingsSubtitle,
                );
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.palette,
                  color: isPremium ? Colors.green : Colors.amber,
                ),
                title: Text(
                  t.themeCustomization,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isPremium ? null : Colors.grey.shade700,
                  ),
                ),
                subtitle: Text(
                  t.themeSettingsSubtitle,
                  style: TextStyle(
                    color: isPremium ? null : Colors.grey.shade600,
                  ),
                ),
                trailing: PremiumFeatureVisuals.buildStatusIndicator(
                  context,
                  isUnlocked: isPremium,
                  showChevron: false,
                ),
                onTap: () {
                  if (isPremium) {
                    _showThemeCustomizationEnabledInfo(context, t);
                  } else {
                    _showPremiumFeaturePrompt(
                      context,
                      t,
                      featureName: t.themeCustomization,
                      benefit: t.themeSettingsSubtitle,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateThemeMode(WidgetRef ref, ThemeMode mode) {
    ref.read(themeProvider.notifier).setThemeMode(mode);
  }

  void _showPremiumFeaturePrompt(
    BuildContext context,
    AppLocalizations t, {
    required String featureName,
    required String benefit,
  }) {
    DialogHelper.showPremiumPrompt(
      context,
      featureName: featureName,
      description: PremiumFeatureVisuals.upgradeMessage(
        context,
        featureName: featureName,
        benefit: benefit,
      ),
      onUpgrade: () => Navigator.pushNamed(context, Routes.premiumFeatures),
    );
  }

  void _showThemeCustomizationEnabledInfo(
      BuildContext context, AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.themeSettingsSubtitle)),
    );
  }
}
