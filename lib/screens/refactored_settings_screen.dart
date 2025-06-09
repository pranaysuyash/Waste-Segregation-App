import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../utils/developer_config.dart';
import '../widgets/settings/account_section.dart';
import '../widgets/settings/premium_section.dart';
import '../widgets/settings/app_settings_section.dart';
import '../widgets/settings/navigation_section.dart';
import '../widgets/settings/features_section.dart';
import '../widgets/settings/legal_support_section.dart';
import '../widgets/settings/developer_section.dart';
import '../widgets/settings/settings_theme.dart';

/// Refactored settings screen demonstrating clean, modular architecture
class RefactoredSettingsScreen extends StatefulWidget {
  const RefactoredSettingsScreen({super.key});

  @override
  State<RefactoredSettingsScreen> createState() => _RefactoredSettingsScreenState();
}

class _RefactoredSettingsScreenState extends State<RefactoredSettingsScreen> {
  bool _showDeveloperOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeAdService();
  }

  void _initializeAdService() {
    // Move side-effects out of build() as recommended
    final adService = context.read<AdService>();
    adService
      ..setInClassificationFlow(false)
      ..setInEducationalContent(false)
      ..setInSettings(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // TODO(i18n): Localize app bar title
      title: const Text('Settings'),
      actions: [
        // Only show developer mode toggle when developer features are enabled
        if (DeveloperConfig.canShowDeveloperOptions)
          IconButton(
            icon: Icon(
              _showDeveloperOptions 
                  ? Icons.developer_mode 
                  : Icons.developer_mode_outlined,
              color: _showDeveloperOptions ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleDeveloperMode,
            // TODO(i18n): Localize tooltip
            tooltip: 'Toggle Developer Mode',
          ),
      ],
    );
  }

  Widget _buildBody() {
    // Use ListView.separated for clean section separation
    final sections = _buildSections();
    
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SettingsSectionSpacer(),
      itemBuilder: (_, index) => sections[index],
    );
  }

  List<Widget> _buildSections() {
    return [
      const AccountSection(),
      const PremiumSection(),
      const AppSettingsSection(),
      const NavigationSection(),
      const FeaturesSection(),
      const LegalSupportSection(),
      DeveloperSection(showDeveloperOptions: _showDeveloperOptions),
    ];
  }

  void _toggleDeveloperMode() {
    setState(() {
      _showDeveloperOptions = !_showDeveloperOptions;
    });
  }
} 