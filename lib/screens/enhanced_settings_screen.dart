import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../utils/developer_config.dart';

import '../utils/dialog_helper.dart';
import '../widgets/settings/settings_widgets.dart';

/// Enhanced settings screen demonstrating all improvements:
/// - Internationalization preparation
/// - Named routes
/// - DialogHelper usage
/// - Accessibility enhancements
/// - Performance optimizations
/// - Hover states and keyboard navigation
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
        adService
          ..setInClassificationFlow(false)
          ..setInEducationalContent(false)
          ..setInSettings(true);
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
    return AppBar(
      // TODO(i18n): Use AppLocalizations.of(context)!.settingsTitle
      title: const Text('Settings'),
      actions: [
        // Only show developer mode toggle when developer features are enabled
        if (DeveloperConfig.canShowDeveloperOptions)
          Semantics(
            // TODO(i18n): Use AppLocalizations.of(context)!.toggleDeveloperMode
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
              // TODO(i18n): Use AppLocalizations.of(context)!.toggleDeveloperMode
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
      
      // Demo section showing enhanced features
      _buildEnhancedFeaturesDemo(),
    ];
  }

  /// Demo section showcasing enhanced features
  Widget _buildEnhancedFeaturesDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionSpacer(),
        // TODO(i18n): Use AppLocalizations.of(context)!.enhancedFeaturesDemo
        const SettingsSectionHeader(title: 'Enhanced Features Demo'),
        
        // Hover state demo
        SettingTile(
          icon: Icons.mouse,
          iconColor: Colors.blue,
          // TODO(i18n): Localize
          title: 'Hover State Demo',
          subtitle: 'Hover over this tile to see cursor change',
          onTap: () => _showHoverDemo(context),
        ),
        
        // Keyboard navigation demo
        SettingTile(
          icon: Icons.keyboard,
          iconColor: Colors.green,
          // TODO(i18n): Localize
          title: 'Keyboard Navigation',
          subtitle: 'Press Tab to focus, Enter to activate',
          onTap: () => _showKeyboardDemo(context),
        ),
        
        // Dialog helper demo
        SettingTile(
          icon: Icons.chat_bubble,
          iconColor: Colors.orange,
          // TODO(i18n): Localize
          title: 'Dialog Helper Demo',
          subtitle: 'Demonstrates consistent dialog patterns',
          onTap: () => _showDialogDemo(context),
        ),
        
        // Loading demo
        SettingTile(
          icon: Icons.hourglass_empty,
          iconColor: Colors.purple,
          // TODO(i18n): Localize
          title: 'Loading Dialog Demo',
          subtitle: 'Shows loading dialog with async operation',
          onTap: () => _showLoadingDemo(context),
        ),
        
        // Semantic labels demo
        Semantics(
          // TODO(i18n): Localize semantic label
          label: 'Premium feature badge example',
          child: SettingTile(
            icon: Icons.star,
            iconColor: Colors.amber,
            // TODO(i18n): Localize
            title: 'Semantic Labels Demo',
            subtitle: 'Screen readers will announce the badge',
            trailing: Semantics(
              // TODO(i18n): Localize
              label: 'Premium feature',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            onTap: () => _showSemanticDemo(context),
          ),
        ),
      ],
    );
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

  Future<void> _showHoverDemo(BuildContext context) async {
    await DialogHelper.showInfo(
      context,
      // TODO(i18n): Localize
      title: 'Hover State Demo',
      message: 'This tile changes cursor to pointer on hover and provides '
               'visual feedback on desktop and web platforms.',
      icon: Icons.mouse,
    );
  }

  Future<void> _showKeyboardDemo(BuildContext context) async {
    await DialogHelper.showInfo(
      context,
      // TODO(i18n): Localize
      title: 'Keyboard Navigation',
      message: 'Use Tab to navigate between settings, Enter or Space to '
               'activate. This improves accessibility for keyboard users.',
      icon: Icons.keyboard,
    );
  }

  Future<void> _showDialogDemo(BuildContext context) async {
    final confirmed = await DialogHelper.confirm(
      context,
      // TODO(i18n): Localize
      title: 'Confirmation Dialog',
      body: 'This demonstrates the consistent dialog pattern using DialogHelper. '
            'All dialogs in the app use the same styling and behavior.',
      okLabel: 'Confirm',
      cancelLabel: 'Cancel',
    );
    
    if (confirmed && context.mounted) {
      SettingsTheme.showSuccessSnackBar(
        context,
        // TODO(i18n): Localize
        'Dialog confirmed!',
      );
    }
  }

  Future<void> _showLoadingDemo(BuildContext context) async {
    try {
      final result = await DialogHelper.loading<String>(
        context,
        () async {
          // Simulate async operation
          await Future.delayed(const Duration(seconds: 2));
          return 'Operation completed successfully!';
        },
        // TODO(i18n): Localize
        message: 'Processing your request...',
      );
      
      if (context.mounted) {
        SettingsTheme.showSuccessSnackBar(context, result);
      }
    } catch (e) {
      if (context.mounted) {
        SettingsTheme.showErrorSnackBar(
          context,
          // TODO(i18n): Localize
          'Operation failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _showSemanticDemo(BuildContext context) async {
    await DialogHelper.showInfo(
      context,
      // TODO(i18n): Localize
      title: 'Semantic Labels',
      message: 'Screen readers will announce "Premium feature" when focusing '
               'on the badge, making the app more accessible to users with '
               'visual impairments.',
      icon: Icons.accessibility,
    );
  }
} 