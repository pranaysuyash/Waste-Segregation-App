import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/routes.dart';
import '../utils/developer_config.dart';

import '../widgets/settings/settings_widgets.dart';

/// Canonical settings screen for the modular settings surface.
///
/// This is the production route target for `Routes.settings`. It composes the
/// extracted settings sections, keeps route wiring centralized, and moves the
/// settings-side ad-state updates out of build-time work.
class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  bool _showDeveloperOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Move side-effects out of build() for better performance
  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final adService = context.read<AdService>();
        adService.setInClassificationFlow(false);
        adService.setInEducationalContent(false);
        adService.setInSettings(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(l10n.settingsTitle),
      actions: [
        // Only show developer mode toggle when developer features are enabled
        if (DeveloperConfig.canShowDeveloperOptions)
          Semantics(
            label: 'Toggle Developer Mode',
            button: true,
            child: IconButton(
              icon: Icon(
                _showDeveloperOptions
                    ? Icons.developer_mode
                    : Icons.developer_mode_outlined,
                color: _showDeveloperOptions ? Colors.yellow : Colors.white,
              ),
              onPressed: _toggleDeveloperMode,
              tooltip: 'Toggle Developer Mode',
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    // Use CustomScrollView for better performance with large lists
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(_buildSections()),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSections() {
    return [
      const AccountSection(),
      const SettingsSectionSpacer(),
      const PremiumSection(),
      const SettingsSectionSpacer(),
      const AppSettingsSection(),
      const SettingsSectionSpacer(),
      const NavigationSection(),
      const SettingsSectionSpacer(),
      const FeaturesSection(),
      const SettingsSectionSpacer(),
      const LegalSupportSection(),
      const SettingsSectionSpacer(),
      DeveloperSection(showDeveloperOptions: _showDeveloperOptions),
      if (DeveloperConfig.canShowDeveloperOptions && _showDeveloperOptions) ...[
        const SettingsSectionSpacer(),
        SettingTile(
          icon: Icons.fact_check,
          iconColor: Colors.blue,
          title: 'Training Review Queue',
          subtitle: 'Review pending training samples and labels',
          onTap: () => Navigator.pushNamed(
            context,
            Routes.trainingReviewQueue,
          ),
        ),
      ],
    ];
  }

  void _toggleDeveloperMode() {
    setState(() {
      _showDeveloperOptions = !_showDeveloperOptions;
    });

    // Provide haptic feedback
    HapticFeedback.selectionClick();

    // Show feedback
    SettingsTheme.showInfoSnackBar(
      context,
      // TODO(i18n): Localize
      'Developer mode ${_showDeveloperOptions ? 'enabled' : 'disabled'}',
    );
  }
}
