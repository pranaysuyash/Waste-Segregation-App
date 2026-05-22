import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../utils/routes.dart';

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
                Navigator.pushNamed(context, Routes.premium);
              },
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.palette, color: Colors.amber),
                title: const Text('Custom Themes'),
                subtitle: const Text('Create your own theme colors'),
                trailing:
                    const Icon(Icons.workspace_premium, color: Colors.amber),
                onTap: () {
                  _showPremiumFeaturePrompt(context, ref, t);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateThemeMode(WidgetRef ref, ThemeMode mode) {
    ref.read(themeProvider.notifier).setThemeMode(mode);
  }

  void _showPremiumFeaturePrompt(
      BuildContext context, WidgetRef ref, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.premiumFeatureTitle('Custom Themes')),
        content: Text(t.premiumCustomThemesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.notNow),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.premium);
            },
            child: Text(t.upgrade),
          ),
        ],
      ),
    );
  }
}
