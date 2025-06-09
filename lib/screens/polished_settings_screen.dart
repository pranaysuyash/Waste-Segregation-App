import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../utils/developer_config.dart';
import '../utils/dialog_helper.dart';
import '../utils/settings_performance_monitor.dart';
import '../widgets/settings/settings_widgets.dart';
import '../widgets/settings/responsive_settings_layout.dart';
import '../widgets/settings/animated_setting_tile.dart';

/// Polished settings screen with all Phase 3 enhancements:
/// - Responsive design for all screen sizes
/// - Smooth animations and micro-interactions
/// - Performance monitoring and optimization
/// - Golden test support
/// - Accessibility improvements
class PolishedSettingsScreen extends StatefulWidget {
  const PolishedSettingsScreen({
    super.key,
    this.enableAnimations = true,
    this.enablePerformanceMonitoring = true,
    this.enableResponsiveLayout = true,
  });

  final bool enableAnimations;
  final bool enablePerformanceMonitoring;
  final bool enableResponsiveLayout;

  @override
  State<PolishedSettingsScreen> createState() => _PolishedSettingsScreenState();
}

class _PolishedSettingsScreenState extends State<PolishedSettingsScreen>
    with PerformanceTrackingMixin<PolishedSettingsScreen> {
  bool _showDeveloperOptions = false;
  final ScrollController _scrollController = ScrollController();

  @override
  String get performanceTrackingName => 'PolishedSettingsScreen';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
  Widget buildWithTracking(BuildContext context) {
    Widget content = _buildContent();

    // Wrap with performance monitoring if enabled
    if (widget.enablePerformanceMonitoring) {
      content = PerformanceAwareSettingsScreen(
        enableMonitoring: true,
        child: content,
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: content,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // TODO(i18n): Use AppLocalizations.of(context)!.settingsTitle
      title: const Text('Settings'),
      elevation: 0,
      actions: [
        // Performance metrics button (debug only)
        if (widget.enablePerformanceMonitoring && DeveloperConfig.canShowDeveloperOptions)
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showPerformanceMetrics,
            tooltip: 'Performance Metrics',
          ),
        
        // Developer mode toggle
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
                color: _showDeveloperOptions ? Colors.yellow : null,
              ),
              onPressed: _toggleDeveloperMode,
              // TODO(i18n): Use AppLocalizations.of(context)!.toggleDeveloperMode
              tooltip: 'Toggle Developer Mode',
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    final sections = _buildSections();

    if (widget.enableResponsiveLayout) {
      return ResponsiveSettingsLayout(
        sections: sections,
      );
    } else {
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: ResponsivePadding.of(context),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _interleaveSectionsWithSpacing(sections),
              ),
            ),
          ),
        ],
      );
    }
  }

  List<Widget> _buildSections() {
    final sections = [
      _buildAccountSection(),
      _buildPremiumSection(),
      _buildAppSettingsSection(),
      _buildNavigationSection(),
      _buildFeaturesSection(),
      _buildLegalSupportSection(),
      _buildDeveloperSection(),
    ];

    if (widget.enableAnimations) {
      return [
        StaggeredSettingsAnimation(
          staggerDelay: const Duration(milliseconds: 80),
          children: sections,
        ),
      ];
    } else {
      return sections;
    }
  }

  Widget _buildAccountSection() {
    return _buildAnimatedSection(
      title: 'Account', // TODO(i18n): Localize
      icon: Icons.account_circle,
      child: const AccountSection(),
    );
  }

  Widget _buildPremiumSection() {
    return _buildAnimatedSection(
      title: 'Premium', // TODO(i18n): Localize
      icon: Icons.star,
      child: const PremiumSection(),
    );
  }

  Widget _buildAppSettingsSection() {
    return _buildAnimatedSection(
      title: 'App Settings', // TODO(i18n): Localize
      icon: Icons.settings,
      child: const AppSettingsSection(),
    );
  }

  Widget _buildNavigationSection() {
    return _buildAnimatedSection(
      title: 'Navigation', // TODO(i18n): Localize
      icon: Icons.navigation,
      child: const NavigationSection(),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildAnimatedSection(
      title: 'Features & Tools', // TODO(i18n): Localize
      icon: Icons.extension,
      child: const FeaturesSection(),
    );
  }

  Widget _buildLegalSupportSection() {
    return _buildAnimatedSection(
      title: 'Legal & Support', // TODO(i18n): Localize
      icon: Icons.help,
      child: const LegalSupportSection(),
    );
  }

  Widget _buildDeveloperSection() {
    if (!_showDeveloperOptions) return const SizedBox.shrink();
    
    return _buildAnimatedSection(
      title: 'Developer Options', // TODO(i18n): Localize
      icon: Icons.developer_mode,
      child: DeveloperSection(showDeveloperOptions: _showDeveloperOptions),
      initiallyExpanded: false,
    );
  }

  Widget _buildAnimatedSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = true,
  }) {
    if (widget.enableAnimations) {
      return AnimatedSectionHeader(
        title: title,
        icon: icon,
        initiallyExpanded: initiallyExpanded,
        children: [child],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(title: title),
          child,
        ],
      );
    }
  }

  List<Widget> _interleaveSectionsWithSpacing(List<Widget> sections) {
    final result = <Widget>[];
    
    for (int i = 0; i < sections.length; i++) {
      result.add(sections[i]);
      
      if (i < sections.length - 1) {
        result.add(const SettingsSectionSpacer());
      }
    }
    
    return result;
  }

  void _toggleDeveloperMode() {
    setState(() {
      _showDeveloperOptions = !_showDeveloperOptions;
    });
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
    
    // Track animation performance
    final stopwatch = Stopwatch()..start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      trackAnimation('developer_toggle', stopwatch.elapsed);
    });
    
    // Show feedback
    SettingsTheme.showInfoSnackBar(
      context,
      // TODO(i18n): Localize
      'Developer mode ${_showDeveloperOptions ? 'enabled' : 'disabled'}',
    );
  }

  Future<void> _showPerformanceMetrics() async {
    final monitor = SettingsPerformanceMonitor();
    final metrics = monitor.metrics;
    final frameTimings = monitor.frameTimings;
    
    if (metrics.isEmpty && frameTimings.isEmpty) {
      await DialogHelper.showInfo(
        context,
        title: 'Performance Metrics',
        message: 'No performance data available. Enable monitoring and interact with the settings to collect data.',
        icon: Icons.analytics,
      );
      return;
    }
    
    final buffer = StringBuffer();
    
    // Widget rebuild statistics
    buffer.writeln('Widget Rebuilds:');
    for (final metric in metrics.values) {
      if (metric.rebuildCount > 0) {
        buffer.writeln('• ${metric.name}: ${metric.rebuildCount} rebuilds');
      }
    }
    
    // Animation performance
    buffer.writeln('\nAnimation Performance:');
    for (final metric in metrics.values) {
      if (metric.animationDurations.isNotEmpty) {
        final avgDuration = metric.averageAnimationDuration;
        buffer.writeln('• ${metric.name}: ${avgDuration.inMilliseconds}ms avg');
      }
    }
    
    // Frame timing statistics
    if (frameTimings.isNotEmpty) {
      final slowFrames = frameTimings.where((f) => f.isSlowFrame).length;
      final frameRate = slowFrames / frameTimings.length * 100;
      buffer.writeln('\nFrame Performance:');
      buffer.writeln('• Total frames: ${frameTimings.length}');
      buffer.writeln('• Slow frames: $slowFrames (${frameRate.toStringAsFixed(1)}%)');
    }
    
    await DialogHelper.showInfo(
      context,
      title: 'Performance Metrics',
      message: buffer.toString(),
      icon: Icons.analytics,
    );
  }
}

/// Demo screen showcasing all polished features
class PolishedSettingsDemoScreen extends StatefulWidget {
  const PolishedSettingsDemoScreen({super.key});

  @override
  State<PolishedSettingsDemoScreen> createState() => _PolishedSettingsDemoScreenState();
}

class _PolishedSettingsDemoScreenState extends State<PolishedSettingsDemoScreen> {
  bool _enableAnimations = true;
  bool _enablePerformanceMonitoring = true;
  bool _enableResponsiveLayout = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polished Settings Demo'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'animations',
                checked: _enableAnimations,
                child: const Text('Enable Animations'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'performance',
                checked: _enablePerformanceMonitoring,
                child: const Text('Performance Monitoring'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'responsive',
                checked: _enableResponsiveLayout,
                child: const Text('Responsive Layout'),
              ),
            ],
          ),
        ],
      ),
      body: PolishedSettingsScreen(
        enableAnimations: _enableAnimations,
        enablePerformanceMonitoring: _enablePerformanceMonitoring,
        enableResponsiveLayout: _enableResponsiveLayout,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    setState(() {
      switch (value) {
        case 'animations':
          _enableAnimations = !_enableAnimations;
          break;
        case 'performance':
          _enablePerformanceMonitoring = !_enablePerformanceMonitoring;
          break;
        case 'responsive':
          _enableResponsiveLayout = !_enableResponsiveLayout;
          break;
      }
    });
  }
}

/// Settings screen optimized for golden tests
class GoldenTestSettingsScreen extends StatelessWidget {
  const GoldenTestSettingsScreen({
    super.key,
    this.theme = ThemeMode.light,
    this.deviceSize = const Size(375, 812), // iPhone 11 Pro size
  });

  final ThemeMode theme;
  final Size deviceSize;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: theme,
      home: MediaQuery(
        data: MediaQueryData(size: deviceSize),
        child: const PolishedSettingsScreen(
          enableAnimations: false, // Disable for consistent golden tests
          enablePerformanceMonitoring: false,
          enableResponsiveLayout: true,
        ),
      ),
    );
  }
} 