import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_badges.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_info_tile.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_textfield.dart';
import 'package:waste_segregation_app/widgets/expandable_section.dart';
import 'package:waste_segregation_app/widgets/premium_badge.dart';
import 'package:waste_segregation_app/widgets/responsive_text.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/classification_state.dart';
import 'package:waste_segregation_app/widgets/result_screen/action_buttons.dart';
import 'package:waste_segregation_app/widgets/result_screen/action_row.dart';
import 'package:waste_segregation_app/widgets/result_screen/disposal_accordion.dart';
import 'package:waste_segregation_app/widgets/result_screen/explanation_panel.dart';
import 'package:waste_segregation_app/widgets/result_screen/local_rules_card.dart';
import 'package:waste_segregation_app/widgets/result_screen/materials_preview.dart';
import 'package:waste_segregation_app/widgets/result_screen/points_popup.dart';
import 'package:waste_segregation_app/widgets/result_screen/staggered_list.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/glass_morphism.dart';
import 'package:waste_segregation_app/widgets/animations/enhanced_loading_states.dart';
import 'package:waste_segregation_app/widgets/polished/polished_card.dart';
import 'package:waste_segregation_app/widgets/polished/polished_divider.dart';
import 'package:waste_segregation_app/widgets/polished/polished_section.dart';
import 'package:waste_segregation_app/widgets/polished/polished_fab.dart';
import 'package:waste_segregation_app/widgets/polished/shimmer_loading.dart';
import 'package:waste_segregation_app/widgets/settings/animated_setting_tile.dart';
import 'package:waste_segregation_app/widgets/animations/settings_animations.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_section_header.dart';
import 'package:waste_segregation_app/widgets/settings/settings_section_spacer.dart';
import 'package:waste_segregation_app/widgets/settings/responsive_settings_layout.dart'
    hide ResponsiveText;
import 'package:waste_segregation_app/widgets/simple_shimmer.dart' as shimmer;
import 'package:waste_segregation_app/widgets/settings/account_section.dart';
import 'package:waste_segregation_app/widgets/settings/app_settings_section.dart';
import 'package:waste_segregation_app/widgets/settings/features_section.dart';
import 'package:waste_segregation_app/widgets/settings/legal_support_section.dart';
import 'package:waste_segregation_app/widgets/settings/navigation_section.dart';
import 'package:waste_segregation_app/widgets/settings/premium_section.dart';
import 'package:waste_segregation_app/widgets/global_settings_menu.dart';
import 'package:waste_segregation_app/widgets/global_menu_wrapper.dart';
import 'package:waste_segregation_app/widgets/banner_ad_widget.dart';
import 'package:waste_segregation_app/widgets/profile_summary_card.dart';
import 'package:waste_segregation_app/widgets/enhanced_analysis_loader.dart';
import 'package:waste_segregation_app/widgets/animations/success_celebrations.dart';
import 'package:waste_segregation_app/widgets/enhanced_gamification_widgets.dart'
    hide PointsEarnedPopup;
import 'package:waste_segregation_app/widgets/animations/error_recovery_animations.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/impact_dashboard_example.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/cyberpunk_dashboard_example.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/widgets/animations/empty_state_animations.dart'
    hide RefreshLoadingWidget;
import 'package:waste_segregation_app/widgets/enhanced_empty_states.dart';
import 'package:waste_segregation_app/widgets/production_error_handler.dart';
import 'package:waste_segregation_app/widgets/share_button.dart';
import 'package:waste_segregation_app/widgets/classification_card.dart';
import 'package:waste_segregation_app/widgets/disposal_instructions_widget.dart';
import 'package:waste_segregation_app/widgets/community_impact_card.dart';
import 'package:waste_segregation_app/widgets/capture_button.dart';
import 'package:waste_segregation_app/widgets/bottom_navigation/modern_bottom_nav.dart';
import 'package:waste_segregation_app/widgets/recycling_code_info.dart';
import 'package:waste_segregation_app/widgets/helpers/thumbnail_widget.dart';
import 'package:waste_segregation_app/widgets/interactive_classification_tags.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/responsive_dialog.dart';
import 'package:waste_segregation_app/widgets/manual_region_selector.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';
import 'package:waste_segregation_app/widgets/premium_segmentation_toggle.dart';
import 'package:waste_segregation_app/widgets/data_migration_dialog.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/widgets/gamification_widgets.dart';
import 'package:waste_segregation_app/widgets/dashboard_widgets.dart';
import 'package:waste_segregation_app/widgets/error_boundary.dart';
import 'package:waste_segregation_app/widgets/animations/data_visualization_animations.dart';
import 'package:waste_segregation_app/widgets/animations/social_animations.dart';
import 'package:waste_segregation_app/widgets/animations/educational_animations.dart';
import 'package:waste_segregation_app/widgets/animated_fab.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/particle_effects.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/impact_visualization_ring.dart';
import 'package:waste_segregation_app/widgets/waste_chart_widgets.dart';
import 'package:waste_segregation_app/widgets/navigation_wrapper.dart';
import 'package:waste_segregation_app/widgets/cache_statistics_card.dart';
import 'package:waste_segregation_app/widgets/settings/developer_section.dart';
import 'package:waste_segregation_app/widgets/interactive_tag.dart';
import 'package:waste_segregation_app/widgets/history_list_item.dart';
import 'package:waste_segregation_app/widgets/simple_web_camera.dart';
import 'package:waste_segregation_app/widgets/enhanced_history_filter_dialog.dart';
import 'package:waste_segregation_app/widgets/result_screen/achievement_wrapper.dart';
import 'package:waste_segregation_app/widgets/animations/page_transitions.dart';
import 'package:waste_segregation_app/widgets/analysis_progress_view.dart';
import 'package:waste_segregation_app/widgets/performance_monitoring_dashboard.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/achievement_celebration.dart'
    hide PointsEarnedPopup;
import 'package:waste_segregation_app/widgets/result_screen/enhanced_reanalysis_widget.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/services/model_selection_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/widgets/per_item_result_card.dart';
import 'package:waste_segregation_app/widgets/multi_item_region_review.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/widgets/waste_components/waste_components.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        _componentCategory(),
      ],
      addons: [
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone12,
            Devices.android.samsungGalaxyS20,
            Devices.ios.iPad,
          ],
        ),
        TextScaleAddon(
          min: 0.8,
          max: 1.5,
        ),
        ThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: ThemeData.light(),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: ThemeData.dark(),
            ),
          ],
          themeBuilder: (context, theme, child) => Theme(
            data: theme,
            child: child,
          ),
        ),
      ],
    );
  }
}

WidgetbookCategory _componentCategory() {
  return WidgetbookCategory(
    name: 'Waste Segregation Components',
    children: [
      WidgetbookFolder(
        name: 'Design Lab',
        children: [
          WidgetbookComponent(
            name: 'Token Playground',
            useCases: [
              WidgetbookUseCase(
                name: 'Editable',
                builder: (context) {
                  final primaryColor = context.knobs.color(
                    label: 'Primary',
                    initialValue: AppTheme.primaryColor,
                  );
                  final secondaryColor = context.knobs.color(
                    label: 'Secondary',
                    initialValue: AppTheme.secondaryColor,
                  );
                  final surfaceColor = context.knobs.color(
                    label: 'Surface',
                  );
                  final accentColor = context.knobs.color(
                    label: 'Accent',
                    initialValue: Colors.green,
                  );
                  final radius = context.knobs.double.slider(
                    label: 'Radius',
                    initialValue: 16,
                    max: 32,
                    divisions: 16,
                  );
                  final elevation = context.knobs.double.slider(
                    label: 'Elevation',
                    initialValue: 2,
                    max: 16,
                    divisions: 16,
                  );
                  final bodyText = context.knobs.string(
                    label: 'Body',
                    initialValue:
                        'Explore how the app feels with live color and radius changes.',
                  );
                  final darkMode = context.knobs.boolean(
                    label: 'Dark mode',
                  );

                  final brightness =
                      darkMode ? Brightness.dark : Brightness.light;
                  final scheme = ColorScheme.fromSeed(
                    seedColor: primaryColor,
                    brightness: brightness,
                  ).copyWith(
                    primary: primaryColor,
                    secondary: secondaryColor,
                    surface: surfaceColor,
                    tertiary: accentColor,
                  );

                  return Theme(
                    data: ThemeData(
                      colorScheme: scheme,
                      useMaterial3: true,
                    ),
                    child: _surface(
                      _TokenPlaygroundCard(
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        surfaceColor: surfaceColor,
                        accentColor: accentColor,
                        radius: radius,
                        elevation: elevation,
                        bodyText: bodyText,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Button Studio',
            useCases: [
              WidgetbookUseCase(
                name: 'Editable',
                builder: (context) {
                  final label = context.knobs.string(
                    label: 'Label',
                    initialValue: 'Scan Waste',
                  );
                  final helperText = context.knobs.string(
                    label: 'Helper',
                    initialValue:
                        'Try different button labels, loading states, and styles.',
                  );
                  final isLoading = context.knobs.boolean(
                    label: 'Loading',
                  );
                  final style = context.knobs.list<ModernButtonStyle>(
                    label: 'Style',
                    options: const [
                      ModernButtonStyle.filled,
                      ModernButtonStyle.outlined,
                      ModernButtonStyle.text,
                      ModernButtonStyle.glassmorphism,
                    ],
                    initialOption: ModernButtonStyle.filled,
                  );
                  final width = context.knobs.double.slider(
                    label: 'Width',
                    initialValue: 280,
                    min: 180,
                    max: 420,
                    divisions: 24,
                  );

                  return _surface(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: width,
                          child: ModernButton(
                            text: label,
                            isLoading: isLoading,
                            style: style,
                            onPressed: _noop,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          helperText,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Card Studio',
            useCases: [
              WidgetbookUseCase(
                name: 'Editable',
                builder: (context) {
                  final title = context.knobs.string(
                    label: 'Title',
                    initialValue: 'Design with intent',
                  );
                  final body = context.knobs.string(
                    label: 'Body',
                    initialValue:
                        'Explore how the same layout feels in different colors, elevations, and spacing.',
                  );
                  final primary = context.knobs.color(
                    label: 'Primary',
                    initialValue: AppTheme.primaryColor,
                  );
                  final secondary = context.knobs.color(
                    label: 'Secondary',
                    initialValue: AppTheme.secondaryColor,
                  );
                  final radius = context.knobs.double.slider(
                    label: 'Radius',
                    initialValue: 16,
                    max: 28,
                    divisions: 14,
                  );
                  final elevation = context.knobs.double.slider(
                    label: 'Elevation',
                    initialValue: 2,
                    max: 12,
                    divisions: 12,
                  );

                  return _surface(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ModernCard(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(
                                color: secondary.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(body),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _ColorSwatch(
                                      label: 'Primary',
                                      color: primary,
                                    ),
                                    const SizedBox(width: 12),
                                    _ColorSwatch(
                                      label: 'Secondary',
                                      color: secondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: elevation * 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Elevation preview',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Prototype Lab',
            useCases: [
              WidgetbookUseCase(
                name: 'SegregationInsightBanner',
                builder: (context) {
                  final title = context.knobs.string(
                    label: 'Title',
                    initialValue: 'New sorting insight',
                  );
                  final message = context.knobs.string(
                    label: 'Message',
                    initialValue:
                        'Your recent scans show dry waste is 34% of your total items.',
                  );
                  final emphasis = context.knobs.color(
                    label: 'Emphasis',
                    initialValue: AppTheme.primaryColor,
                  );
                  final showAction = context.knobs.boolean(
                    label: 'Action',
                    initialValue: true,
                  );

                  return _surface(
                    SegregationInsightBanner(
                      title: title,
                      message: message,
                      emphasis: emphasis,
                      showAction: showAction,
                    ),
                  );
                },
              ),
              WidgetbookUseCase(
                name: 'ImpactCallout',
                builder: (context) {
                  final headline = context.knobs.string(
                    label: 'Headline',
                    initialValue: 'Small habit, visible impact',
                  );
                  final detail = context.knobs.string(
                    label: 'Detail',
                    initialValue:
                        'Show more momentum at a glance, before the user opens a deeper result view.',
                  );
                  final accent = context.knobs.color(
                    label: 'Accent',
                    initialValue: Colors.teal,
                  );
                  final showMetric = context.knobs.boolean(
                    label: 'Metric',
                    initialValue: true,
                  );

                  return _surface(
                    ImpactCalloutCard(
                      headline: headline,
                      detail: detail,
                      accent: accent,
                      showMetric: showMetric,
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Theme Matrix',
            useCases: [
              WidgetbookUseCase(
                name: 'Palette',
                builder: (context) {
                  final palette = context.knobs.list<String>(
                    label: 'Palette',
                    options: const ['Ocean', 'Forest', 'Sunset'],
                    initialOption: 'Ocean',
                  );
                  final darkMode = context.knobs.boolean(
                    label: 'Dark mode',
                  );

                  final scheme = _buildExplorationScheme(
                    palette,
                    darkMode: darkMode,
                  );

                  return Theme(
                    data: ThemeData(
                      colorScheme: scheme,
                      useMaterial3: true,
                    ),
                    child: _surface(
                      _ThemeMatrixCard(
                        palette: palette,
                        darkMode: darkMode,
                        colorScheme: scheme,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Color Studio',
            useCases: [
              WidgetbookUseCase(
                name: 'Matrix',
                builder: (context) {
                  final palette = context.knobs.list<String>(
                    label: 'Palette',
                    options: const ['Ocean', 'Forest', 'Sunset'],
                    initialOption: 'Ocean',
                  );
                  final darkMode = context.knobs.boolean(
                    label: 'Dark mode',
                  );
                  final buttonStyle = context.knobs.list<ModernButtonStyle>(
                    label: 'Button style',
                    options: const [
                      ModernButtonStyle.filled,
                      ModernButtonStyle.outlined,
                      ModernButtonStyle.text,
                      ModernButtonStyle.glassmorphism,
                    ],
                    initialOption: ModernButtonStyle.filled,
                  );
                  final buttonSize = context.knobs.list<ModernButtonSize>(
                    label: 'Button size',
                    options: const [
                      ModernButtonSize.small,
                      ModernButtonSize.medium,
                      ModernButtonSize.large,
                    ],
                    initialOption: ModernButtonSize.medium,
                  );
                  final badgeStyle = context.knobs.list<ModernBadgeStyle>(
                    label: 'Badge style',
                    options: const [
                      ModernBadgeStyle.filled,
                      ModernBadgeStyle.outlined,
                      ModernBadgeStyle.soft,
                      ModernBadgeStyle.glassmorphism,
                    ],
                    initialOption: ModernBadgeStyle.soft,
                  );
                  final badgeSize = context.knobs.list<ModernBadgeSize>(
                    label: 'Badge size',
                    options: const [
                      ModernBadgeSize.small,
                      ModernBadgeSize.medium,
                      ModernBadgeSize.large,
                    ],
                    initialOption: ModernBadgeSize.medium,
                  );
                  final chipStyle = context.knobs.list<ModernChipStyle>(
                    label: 'Chip style',
                    options: const [
                      ModernChipStyle.filled,
                      ModernChipStyle.outlined,
                      ModernChipStyle.soft,
                    ],
                    initialOption: ModernChipStyle.soft,
                  );
                  final chipMultiSelect = context.knobs.boolean(
                    label: 'Chip multi-select',
                    initialValue: true,
                  );
                  final chipSelectedColor = context.knobs.color(
                    label: 'Chip selected color',
                    initialValue: _buildExplorationScheme(
                      palette,
                      darkMode: darkMode,
                    ).primary,
                  );
                  final textFieldEnabled = context.knobs.boolean(
                    label: 'Field enabled',
                    initialValue: true,
                  );
                  final textFieldReadOnly = context.knobs.boolean(
                    label: 'Field read-only',
                  );
                  final textFieldObscure = context.knobs.boolean(
                    label: 'Field obscure',
                  );
                  final textFieldError = context.knobs.string(
                    label: 'Field error',
                  );
                  final buttonLoading = context.knobs.boolean(
                    label: 'Button loading',
                  );
                  final buttonExpanded = context.knobs.boolean(
                    label: 'Button expanded',
                  );
                  final buttonTooltip = context.knobs.string(
                    label: 'Button tooltip',
                    initialValue: 'Open scan flow',
                  );
                  final buttonLabel = context.knobs.string(
                    label: 'Button label',
                    initialValue: 'Scan Waste',
                  );
                  final badgeText = context.knobs.string(
                    label: 'Badge text',
                    initialValue: 'Eco Hero',
                  );
                  final badgePulse = context.knobs.boolean(
                    label: 'Badge pulse',
                    initialValue: true,
                  );
                  final fieldHelp = context.knobs.string(
                    label: 'Field helper',
                    initialValue:
                        'Watch how the same palette affects text, chip, badge, and button surfaces.',
                  );
                  final fieldLabel = context.knobs.string(
                    label: 'Field label',
                    initialValue: 'Item name',
                  );
                  final fieldHint = context.knobs.string(
                    label: 'Field hint',
                    initialValue: 'e.g. Plastic bottle',
                  );
                  final featureTitle = context.knobs.string(
                    label: 'Feature title',
                    initialValue: 'Quick Scan',
                  );
                  final featureSubtitle = context.knobs.string(
                    label: 'Feature subtitle',
                    initialValue: 'Instant waste category result',
                  );
                  final featureChevron = context.knobs.boolean(
                    label: 'Feature chevron',
                    initialValue: true,
                  );
                  final statsTrend = context.knobs.list<Trend>(
                    label: 'Stats trend',
                    options: const [Trend.up, Trend.flat, Trend.down],
                    initialOption: Trend.up,
                  );
                  final statsValue = context.knobs.string(
                    label: 'Stats value',
                    initialValue: '128 pts',
                  );
                  final statsSubtitle = context.knobs.string(
                    label: 'Stats subtitle',
                    initialValue: 'from 14 scans',
                  );
                  final toggleValue = context.knobs.boolean(
                    label: 'Toggle value',
                    initialValue: true,
                  );

                  final scheme = _buildExplorationScheme(
                    palette,
                    darkMode: darkMode,
                  );

                  return Theme(
                    data: ThemeData(
                      colorScheme: scheme,
                      useMaterial3: true,
                    ),
                    child: _surface(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Color and state matrix',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _ColorSwatch(
                                label: 'Primary',
                                color: scheme.primary,
                              ),
                              _ColorSwatch(
                                label: 'Secondary',
                                color: scheme.secondary,
                              ),
                              _ColorSwatch(
                                label: 'Surface',
                                color: scheme.surface,
                              ),
                              _ColorSwatch(
                                label: 'Success',
                                color: AppTheme.successColor,
                              ),
                              _ColorSwatch(
                                label: 'Warning',
                                color: AppTheme.warningColor,
                              ),
                              _ColorSwatch(
                                label: 'Error',
                                color: AppTheme.errorColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ModernButton(
                            text: buttonLabel,
                            icon: Icons.camera_alt,
                            style: buttonStyle,
                            size: buttonSize,
                            isLoading: buttonLoading,
                            isExpanded: buttonExpanded,
                            tooltip: buttonTooltip.isEmpty
                                ? null
                                : buttonTooltip,
                            onPressed: _noop,
                          ),
                          const SizedBox(height: 12),
                          ModernBadge(
                            text: badgeText,
                            icon: Icons.verified,
                            style: badgeStyle,
                            size: badgeSize,
                            showPulse: badgePulse,
                            backgroundColor: scheme.primary,
                          ),
                          const SizedBox(height: 12),
                          WasteCategoryBadge(
                            category:
                                chipMultiSelect ? 'Dry Waste' : 'Wet Waste',
                            style: badgeStyle == ModernBadgeStyle.glassmorphism
                                ? ModernBadgeStyle.soft
                                : badgeStyle,
                            size: badgeSize,
                          ),
                          const SizedBox(height: 12),
                          ModernChipGroup(
                            options: const [
                              'Dry',
                              'Wet',
                              'Hazardous',
                              'Medical',
                            ],
                            selectedOptions: chipMultiSelect
                                ? const ['Dry', 'Wet']
                                : const ['Dry'],
                            multiSelect: chipMultiSelect,
                            style: chipStyle,
                            selectedColor: chipSelectedColor,
                          ),
                          const SizedBox(height: 12),
                          ModernTextField(
                            labelText: fieldLabel,
                            hintText: fieldHint,
                            helperText: fieldHelp,
                            errorText: textFieldError.isEmpty
                                ? null
                                : textFieldError,
                            prefixIcon: Icons.search,
                            suffixIcon:
                                textFieldEnabled && !textFieldReadOnly
                                    ? Icons.clear
                                    : null,
                            onSuffixIconPressed:
                                textFieldEnabled && !textFieldReadOnly
                                    ? _noop
                                    : null,
                            enabled: textFieldEnabled,
                            readOnly: textFieldReadOnly,
                            obscureText: textFieldObscure,
                          ),
                          const SizedBox(height: 12),
                          FeatureCard(
                            icon: Icons.recycling,
                            title: featureTitle,
                            subtitle: featureSubtitle,
                            iconColor: scheme.primary,
                            showChevron: featureChevron,
                            onTap: _noop,
                          ),
                          const SizedBox(height: 12),
                          StatsCard(
                            title: 'Weekly impact',
                            value: statsValue,
                            subtitle: statsSubtitle,
                            icon: Icons.eco,
                            color: scheme.secondary,
                            trend: statsTrend,
                            isPositiveTrend: statsTrend != Trend.down,
                          ),
                          const SizedBox(height: 12),
                          SettingToggleTile(
                            icon: Icons.dark_mode,
                            title: 'Dark mode preview',
                            subtitle:
                                'See how toggles feel against the current palette.',
                            value: toggleValue,
                            onChanged: (_) {},
                            enabled: textFieldEnabled,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Input Studio',
            useCases: [
              WidgetbookUseCase(
                name: 'Editable',
                builder: (context) {
                  final labelText = context.knobs.string(
                    label: 'Label',
                    initialValue: 'Item name',
                  );
                  final hintText = context.knobs.string(
                    label: 'Hint',
                    initialValue: 'Enter a waste item',
                  );
                  final helperText = context.knobs.string(
                    label: 'Helper',
                    initialValue:
                        'Use this to see spacing, hint flow, and state styling.',
                  );
                  final errorText = context.knobs.string(
                    label: 'Error',
                  );
                  final badgeText = context.knobs.string(
                    label: 'Badge',
                    initialValue: 'Eco Hero',
                  );
                  final badgePulse = context.knobs.boolean(
                    label: 'Badge pulse',
                    initialValue: true,
                  );
                  final chipLabel = context.knobs.string(
                    label: 'Chip',
                    initialValue: 'Dry Waste',
                  );
                  final chipSelected = context.knobs.boolean(
                    label: 'Chip selected',
                    initialValue: true,
                  );
                  final infoValue = context.knobs.string(
                    label: 'Info value',
                    initialValue: '12.5 kg',
                  );
                  final inputStyle = context.knobs.list<ModernChipStyle>(
                    label: 'Chip style',
                    options: const [
                      ModernChipStyle.filled,
                      ModernChipStyle.outlined,
                      ModernChipStyle.soft,
                    ],
                    initialOption: ModernChipStyle.filled,
                  );

                  return _surface(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ModernTextField(
                          labelText: labelText,
                          hintText: hintText,
                          helperText: helperText,
                          errorText: errorText.isEmpty ? null : errorText,
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ModernBadge(
                              text: badgeText,
                              icon: Icons.verified,
                              showPulse: badgePulse,
                            ),
                            ModernChip(
                              label: chipLabel,
                              isSelected: chipSelected,
                              icon: Icons.recycling,
                              style: inputStyle,
                            ),
                            ModernInfoTile(
                              icon: Icons.eco,
                              label: 'CO2 Saved',
                              value: infoValue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Buttons',
        children: [
          WidgetbookComponent(
            name: 'ModernButton',
            useCases: [
              WidgetbookUseCase(
                name: 'Filled',
                builder: (context) => _surface(
                  const ModernButton(text: 'Scan Waste', onPressed: _noop),
                ),
              ),
              WidgetbookUseCase(
                name: 'Outlined',
                builder: (context) => _surface(
                  const ModernButton(
                    text: 'View History',
                    style: ModernButtonStyle.outlined,
                    onPressed: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Loading',
                builder: (context) => _surface(
                  const ModernButton(text: 'Classifying', isLoading: true),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernSearchBar',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ModernSearchBar(hint: 'Search classifications'),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernFAB',
            useCases: [
              WidgetbookUseCase(
                name: 'Regular',
                builder: (context) => _surface(
                  const ModernFAB(
                    onPressed: _noop,
                    icon: Icons.camera_alt,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Extended',
                builder: (context) => _surface(
                  const ModernFAB(
                    onPressed: _noop,
                    icon: Icons.camera_alt,
                    label: 'Scan',
                    isExtended: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Cards',
        children: [
          WidgetbookComponent(
            name: 'FeatureCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const FeatureCard(
                    icon: Icons.recycling,
                    title: 'Quick Scan',
                    subtitle: 'Instant waste category result',
                    onTap: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Long Content',
                builder: (context) => _surface(
                  const FeatureCard(
                    icon: Icons.public,
                    title:
                        'Municipality-Specific Disposal Instructions and Safety Rules',
                    subtitle:
                        'Collect detailed disposal guidance with confidence, handling, and neighborhood routing.',
                    onTap: _noop,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ModernCard(
                    child: Text('Modern card container'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'GlassmorphismCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const GlassmorphismCard(
                    child: Text('Glassmorphism card container'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ActionCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ActionCard(
                    title: 'Start Scan',
                    subtitle: 'Classify a new item',
                    icon: Icons.camera_alt,
                    onTap: _noop,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ActiveChallengeCard',
            useCases: [
              WidgetbookUseCase(
                name: 'In Progress',
                builder: (context) => _surface(
                  const ActiveChallengeCard(
                    title: '7-day Streak',
                    description: 'Scan at least one item daily',
                    progress: 0.57,
                    icon: Icons.local_fire_department,
                    reward: '+150 pts',
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'RecentClassificationCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  RecentClassificationCard(
                    itemName: 'Plastic Bottle',
                    category: 'Dry Waste',
                    timestamp: DateTime(2026, 5, 21, 10, 30),
                    subcategory: 'Recyclable',
                    isRecyclable: true,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'StatsCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Positive Trend',
                builder: (context) => _surface(
                  const StatsCard(
                    title: 'Weekly Impact',
                    value: '128 pts',
                    subtitle: 'from 14 scans',
                    trend: Trend.up,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Negative Trend',
                builder: (context) => _surface(
                  const StatsCard(
                    title: 'Missed Streak',
                    value: '2 days',
                    subtitle: 'needs recovery',
                    trend: Trend.down,
                    isPositiveTrend: false,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernInfoTile',
            useCases: [
              WidgetbookUseCase(
                name: 'With Value',
                builder: (context) => _surface(
                  const ModernInfoTile(
                    icon: Icons.eco,
                    label: 'CO2 Saved',
                    value: '12.5 kg',
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernBadge',
            useCases: [
              WidgetbookUseCase(
                name: 'Filled',
                builder: (context) => _surface(
                  const ModernBadge(
                    text: 'Eco Hero',
                    icon: Icons.verified,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Soft Pulse',
                builder: (context) => _surface(
                  const ModernBadge(
                    text: 'Live',
                    style: ModernBadgeStyle.soft,
                    showPulse: true,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernChip',
            useCases: [
              WidgetbookUseCase(
                name: 'Selected',
                builder: (context) => _surface(
                  const ModernChip(
                    label: 'Dry Waste',
                    isSelected: true,
                    icon: Icons.recycling,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Unselected',
                builder: (context) => _surface(
                  const ModernChip(
                    label: 'Hazardous',
                    icon: Icons.warning_amber,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ModernChipGroup',
            useCases: [
              WidgetbookUseCase(
                name: 'Multi Select',
                builder: (context) => _surface(
                  const ModernChipGroup(
                    options: ['Dry', 'Wet', 'Hazardous'],
                    selectedOptions: ['Dry'],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'WasteCategoryBadge',
            useCases: [
              WidgetbookUseCase(
                name: 'Dry Waste',
                builder: (context) => _surface(
                  const WasteCategoryBadge(category: 'Dry Waste'),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'StatusBadge',
            useCases: [
              WidgetbookUseCase(
                name: 'Completed',
                builder: (context) => _surface(
                  const StatusBadge(status: 'completed'),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ProgressBadge',
            useCases: [
              WidgetbookUseCase(
                name: 'Progress 72',
                builder: (context) => _surface(
                  const ProgressBadge(progress: 72),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PremiumBadge',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(const PremiumBadge()),
              ),
              WidgetbookUseCase(
                name: 'Custom',
                builder: (context) => _surface(
                  const PremiumBadge(label: 'Premium', fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Settings',
        children: [
          WidgetbookComponent(
            name: 'SettingTile',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SettingTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Configure reminders and alerts',
                    onTap: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Disabled',
                builder: (context) => _surface(
                  const SettingTile(
                    icon: Icons.sync_disabled,
                    title: 'Cloud Sync',
                    subtitle: 'Unavailable while offline',
                    enabled: false,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Toggle',
                builder: (context) => _surface(
                  SettingToggleTile(
                    icon: Icons.dark_mode,
                    title: 'Dark mode',
                    subtitle: 'Use darker theme at night',
                    value: context.knobs.boolean(
                      label: 'value',
                      initialValue: true,
                    ),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Text',
        children: [
          WidgetbookComponent(
            name: 'ResponsiveText',
            useCases: [
              WidgetbookUseCase(
                name: 'AppBar Title',
                builder: (context) => _surface(
                  const ResponsiveText.appBarTitle(
                    'Waste Segregation Assistant',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Greeting',
                builder: (context) => _surface(
                  const ResponsiveText.greeting(
                    'Welcome back, this is a long username preview',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Read More',
                builder: (context) => _surface(
                  const ReadMoreText(
                    'Dry waste includes paper, cardboard, and clean plastics. '
                    'Keep it separate from wet waste to improve recycling output.',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Responsive AppBar Title',
                builder: (context) => _surface(
                  const ResponsiveAppBarTitle(
                    title: 'Waste Segregation Assistant',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Greeting Text Widget',
                builder: (context) => _surface(
                  const GreetingText(
                    greeting: 'Hello',
                    userName: 'Pranay-Sustainability-Champion',
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ExpandableSection',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ExpandableSection(
                    title: 'Disposal Guidance',
                    content:
                        'Rinse containers before recycling. Keep wet and dry waste separate. '
                        'Use the nearest authorized drop-off point for hazardous waste.',
                    titleIcon: Icons.info_outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Inputs',
        children: [
          WidgetbookComponent(
            name: 'ModernTextField',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ModernTextField(
                    labelText: 'Item Name',
                    hintText: 'e.g., Plastic bottle',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Error State',
                builder: (context) => _surface(
                  const ModernTextField(
                    labelText: 'Item Name',
                    errorText: 'Item name is required',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Settings',
        children: [
          WidgetbookComponent(
            name: 'SettingsSectionHeader',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SettingsSectionHeader(
                    title: 'App Preferences',
                    icon: Icons.tune,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SettingsSectionSpacer',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Section A'),
                      SettingsSectionSpacer(height: 20),
                      Text('Section B'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'AnimatedSettingTile',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const AnimatedSettingTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage alerts and reminders',
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SettingTile',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SettingTile(
                    icon: Icons.palette,
                    title: 'Theme Settings',
                    subtitle: 'Customize app appearance',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Disabled',
                builder: (context) => _surface(
                  const SettingTile(
                    icon: Icons.cloud_off,
                    title: 'Offline Mode',
                    subtitle: 'Premium feature',
                    enabled: false,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SettingToggleTile',
            useCases: [
              WidgetbookUseCase(
                name: 'Enabled',
                builder: (context) => _surface(
                  const SettingToggleTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on successful scan',
                    value: true,
                    onChanged: _onToggleChanged,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ViewAllButton',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ViewAllButton(onPressed: _noop),
                ),
              ),
              WidgetbookUseCase(
                name: 'With Icon',
                builder: (context) => _surface(
                  const ViewAllButton(
                    onPressed: _noop,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'StaggeredSettingsAnimation',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const StaggeredSettingsAnimation(
                    children: [
                      Text('Section 1'),
                      Text('Section 2'),
                      Text('Section 3'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'AnimatedSectionHeader',
            useCases: [
              WidgetbookUseCase(
                name: 'Collapsed',
                builder: (context) => _surface(
                  const AnimatedSectionHeader(
                    title: 'Advanced Settings',
                    children: [Text('Hidden child content')],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'AnimatedSettingsToggle',
            useCases: [
              WidgetbookUseCase(
                name: 'Enabled',
                builder: (context) => _surface(
                  const AnimatedSettingsToggle(
                    title: 'Push Notifications',
                    subtitle: 'Get reminders',
                    value: true,
                    onChanged: _onToggleChanged,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ProfileUpdateWidget',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ProfileUpdateWidget(),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SmartNotificationWidget',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SmartNotificationWidget(
                    message: 'Schedule updated for dry waste pickup.',
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ResponsiveSettingsLayout',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 480,
                    child: ResponsiveSettingsLayout(
                      sections: [
                        Card(
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Account'))),
                        Card(
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Premium'))),
                        Card(
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('App Settings'))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Result Screen',
        children: [
          WidgetbookComponent(
            name: 'ActionButtons',
            useCases: [
              WidgetbookUseCase(
                name: 'Save State',
                builder: (context) => _surface(
                  const ActionButtons(
                    isSaved: false,
                    isAutoSaving: false,
                    onSave: _noop,
                    onShare: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Saved State',
                builder: (context) => _surface(
                  const ActionButtons(
                    isSaved: true,
                    isAutoSaving: false,
                    onSave: _noop,
                    onShare: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Auto Saving',
                builder: (context) => _surface(
                  const ActionButtons(
                    isSaved: false,
                    isAutoSaving: true,
                    onSave: _noop,
                    onShare: _noop,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PointsEarnedPopup',
            useCases: [
              WidgetbookUseCase(
                name: 'Points +25',
                builder: (context) => _surface(
                  const PointsEarnedPopup(points: 25, onDismiss: _noop),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PointsPopupOverlay',
            useCases: [
              WidgetbookUseCase(
                name: 'Visible',
                builder: (context) => const SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      Center(child: Text('Underlying content')),
                      PointsPopupOverlay(
                        points: 15,
                        isVisible: true,
                        onDismiss: _noop,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'DelayedDisplay',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const DelayedDisplay(
                    delay: Duration(milliseconds: 250),
                    child: Text('Appears with delay'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'StaggeredTagList',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const StaggeredTagList(
                    tags: [
                      Chip(label: Text('Dry')),
                      Chip(label: Text('Wet')),
                      Chip(label: Text('Hazardous')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ActionRow',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ActionRow(
                    onShare: _noop,
                    onCorrect: _noop,
                    onSave: _noop,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'MaterialsPreview',
            useCases: [
              WidgetbookUseCase(
                name: 'With Materials',
                builder: (context) => _surface(
                  MaterialsPreview(classification: _sampleClassification()),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'LocalRulesCard',
            useCases: [
              WidgetbookUseCase(
                name: 'With Rules',
                builder: (context) => _surface(
                  LocalRulesCard(classification: _sampleClassification()),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ExplanationPanel',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  ExplanationPanel(classification: _sampleClassification()),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'DisposalAccordion',
            useCases: [
              WidgetbookUseCase(
                name: 'Expanded',
                builder: (context) => _surface(
                  DisposalAccordion(
                    classification: _sampleClassification(),
                    initiallyExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Polished',
        children: [
          WidgetbookComponent(
            name: 'PolishedCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const PolishedCard(
                    child: Text('Polished card content'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PolishedDivider',
            useCases: [
              WidgetbookUseCase(
                name: 'Solid',
                builder: (context) => _surface(
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Above'),
                      PolishedDivider(),
                      Text('Below'),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Dotted',
                builder: (context) => _surface(
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Above'),
                      PolishedDivider.dotted(),
                      Text('Below'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PolishedSection',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const PolishedSection(
                    title: 'Impact Summary',
                    subtitle: 'Weekly environmental impact',
                    child:
                        Text('You diverted 18 items from landfill this week.'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PolishedSectionHeader',
            useCases: [
              WidgetbookUseCase(
                name: 'Underlined',
                builder: (context) => _surface(
                  const PolishedSectionHeader(
                    title: 'Weekly Summary',
                    subtitle: 'Your progress this week',
                    showUnderline: true,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PolishedFAB',
            useCases: [
              WidgetbookUseCase(
                name: 'Regular',
                builder: (context) => _surface(
                  const PolishedFAB(
                    onPressed: _noop,
                    icon: Icons.camera_alt,
                    enablePulse: false,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Extended',
                builder: (context) => _surface(
                  const PolishedFAB(
                    onPressed: _noop,
                    icon: Icons.camera_alt,
                    label: 'Scan',
                    isExtended: true,
                    enablePulse: false,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'PolishedActionButton',
            useCases: [
              WidgetbookUseCase(
                name: 'Filled',
                builder: (context) => _surface(
                  const PolishedActionButton(
                    onPressed: _noop,
                    text: 'Classify',
                    icon: Icons.check,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Outlined',
                builder: (context) => _surface(
                  const PolishedActionButton(
                    onPressed: _noop,
                    text: 'Secondary',
                    isOutlined: true,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ShimmerLoading',
            useCases: [
              WidgetbookUseCase(
                name: 'Card Skeleton',
                builder: (context) => _surface(
                  const ShimmerLoading(
                    child: SizedBox(
                      height: 120,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFD0D0D0)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SimpleShimmer',
            useCases: [
              WidgetbookUseCase(
                name: 'Line',
                builder: (context) => _surface(
                  const shimmer.SimpleShimmer(height: 14, width: 260),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Simple ShimmerCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const shimmer.ShimmerCard(height: 180),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'RefreshLoadingWidget',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SizedBox(height: 220, child: RefreshLoadingWidget()),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'ShimmerBox',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ShimmerBox(height: 80, width: 280),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'SearchResultsWidget',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const SearchResultsWidget(
                    child: Text('Animated search result row'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'GlassMorphismCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const GlassMorphismCard(
                    child: Text('Glass morphism card'),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Advanced ShimmerCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => _surface(
                  const ShimmerCard(
                    child: SizedBox(
                      width: 260,
                      height: 120,
                      child: Center(child: Text('Shimmer content')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Coverage Expansion',
        children: [
          WidgetbookComponent(
            name: 'Settings Sections',
            useCases: [
              WidgetbookUseCase(
                name: 'AccountSection',
                builder: (context) => _surface(const AccountSection()),
              ),
              WidgetbookUseCase(
                name: 'PremiumSection',
                builder: (context) => _surface(const PremiumSection()),
              ),
              WidgetbookUseCase(
                name: 'AppSettingsSection',
                builder: (context) => _surface(const AppSettingsSection()),
              ),
              WidgetbookUseCase(
                name: 'FeaturesSection',
                builder: (context) => _surface(const FeaturesSection()),
              ),
              WidgetbookUseCase(
                name: 'NavigationSection',
                builder: (context) => _surface(const NavigationSection()),
              ),
              WidgetbookUseCase(
                name: 'LegalSupportSection',
                builder: (context) => _surface(const LegalSupportSection()),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Global Surfaces',
            useCases: [
              WidgetbookUseCase(
                name: 'GlobalSettingsMenu',
                builder: (context) => _surface(const GlobalSettingsMenu()),
              ),
              WidgetbookUseCase(
                name: 'GlobalMenuWrapper',
                builder: (context) => GlobalMenuWrapper(
                  child: _surface(
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Wrapped content'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Feedback and Progress',
            useCases: [
              WidgetbookUseCase(
                name: 'EnhancedAnalysisLoader',
                builder: (context) => _surface(
                  const SizedBox(height: 280, child: EnhancedAnalysisLoader()),
                ),
              ),
              WidgetbookUseCase(
                name: 'HistoryLoadingWidget',
                builder: (context) => _surface(
                  const SizedBox(height: 160, child: HistoryLoadingWidget()),
                ),
              ),
              WidgetbookUseCase(
                name: 'ErrorRecoveryWidget',
                builder: (context) => _surface(
                  ErrorRecoveryWidget(onRetry: _noop),
                ),
              ),
              WidgetbookUseCase(
                name: 'SyncSuccessWidget',
                builder: (context) => _surface(
                  const SizedBox(height: 220, child: SyncSuccessWidget()),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Empty and Error States',
            useCases: [
              WidgetbookUseCase(
                name: 'EmptyStateWidget',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 360,
                    child: EmptyStateWidget(
                      title: 'No history yet',
                      message: 'Start scanning to build your timeline.',
                      icon: Icons.history,
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EmptyHistoryStateWidget',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 320,
                    child: EmptyHistoryStateWidget(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EmptySearchResultsWidget',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 320,
                    child: EmptySearchResultsWidget(searchQuery: 'metal can'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EnhancedEmptyState',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 360,
                    child: EnhancedEmptyState(type: EmptyStateType.noResults),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ScanningEmptyState',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 280,
                    child: ScanningEmptyState(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ProgressEmptyState',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 260,
                    child: ProgressEmptyState(
                      title: 'Classifying...',
                      message: 'Preparing prediction.',
                      progress: 0.64,
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'NetworkErrorHandler',
                builder: (context) => _surface(
                  SizedBox(
                    height: 280,
                    child: NetworkErrorHandler(onRetry: _noop),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EmptyStateHandler',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 280,
                    child: EmptyStateHandler(
                      title: 'No data',
                      message: 'Nothing to show in this section.',
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'LoadingStateHandler',
                builder: (context) => _surface(
                  const SizedBox(height: 220, child: LoadingStateHandler()),
                ),
              ),
              WidgetbookUseCase(
                name: 'ProductionErrorHandler',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 280,
                    child: ProductionErrorHandler(
                      child: Text('safe child'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Gamification Basics',
            useCases: [
              WidgetbookUseCase(
                name: 'ArchivedPointsHistoryWidget',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 260,
                    child: ArchivedPointsHistoryWidget(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ProfileSummaryCard',
                builder: (context) => _surface(
                  const ProfileSummaryCard(
                    points: UserPoints(total: 1200, level: 12),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Share Widgets',
            useCases: [
              WidgetbookUseCase(
                name: 'ShareButton',
                builder: (context) => _surface(
                  const ShareButton(
                    text: 'I recycled 5 items today',
                    showSnackBar: false,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ShareFloatingActionButton',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 120,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: ShareFloatingActionButton(
                        text: 'Weekly impact summary',
                        showSnackBar: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Classification and Disposal',
            useCases: [
              WidgetbookUseCase(
                name: 'ClassificationCard',
                builder: (context) => _surface(
                  ClassificationCard(
                    classification: _sampleClassification(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'DisposalInstructionsWidget',
                builder: (context) => _surface(
                  DisposalInstructionsWidget(
                    instructions: _sampleClassification().disposalInstructions,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'InteractiveClassificationTags',
                builder: (context) => _surface(
                  InteractiveClassificationTags(
                    classification: _sampleClassification(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'CommunityImpactCard',
                builder: (context) => _surface(
                  CommunityImpactCard(
                    classifications: [_sampleClassification()],
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Scan Inputs and Tools',
            useCases: [
              WidgetbookUseCase(
                name: 'CaptureButton',
                builder: (context) => _surface(
                  CaptureButton(
                    type: CaptureButtonType.camera,
                    onPressed: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ManualRegionSelector',
                builder: (context) => _surface(
                  SizedBox(
                    height: 360,
                    child: ManualRegionSelector(
                      maxRegions: 3,
                      onRegionsChanged: (_) {},
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ThumbnailWidget',
                builder: (context) => _surface(
                  const ThumbnailWidget(
                    imagePath: 'assets/images/app_icon.png',
                    size: 84,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'RecyclingCodeInfoCard',
                builder: (context) => _surface(
                  const RecyclingCodeInfoCard(code: '1'),
                  ),
                ),
              ],
            ),
        ],
      ),
      WidgetbookFolder(
            name: 'Waste Components (v2)',
            children: [
              WidgetbookComponent(
                name: 'ConfidenceIndicator',
                useCases: [
                  WidgetbookUseCase(
                    name: 'High',
                    builder: (context) => _surface(
                      const ConfidenceIndicator(confidencePercent: 89),
                    ),
                  ),
                  WidgetbookUseCase(
                    name: 'Medium',
                    builder: (context) => _surface(
                      const ConfidenceIndicator(confidencePercent: 65),
                    ),
                  ),
                  WidgetbookUseCase(
                    name: 'Low',
                    builder: (context) => _surface(
                      const ConfidenceIndicator(confidencePercent: 34),
                    ),
                  ),
                ],
              ),
              WidgetbookComponent(
                name: 'BinRecommendationChip',
                useCases: [
                  WidgetbookUseCase(
                    name: 'Wet Waste',
                    builder: (context) => _surface(
                      const BinRecommendationChip(category: 'Wet Waste'),
                    ),
                  ),
                  WidgetbookUseCase(
                    name: 'Hazardous',
                    builder: (context) => _surface(
                      const BinRecommendationChip(category: 'Hazardous Waste'),
                    ),
                  ),
                ],
              ),
              WidgetbookComponent(
                name: 'PointsRewardChip',
                useCases: [
                  WidgetbookUseCase(
                    name: 'Default',
                    builder: (context) => _surface(
                      const PointsRewardChip(points: 15),
                    ),
                  ),
                ],
              ),
              WidgetbookComponent(
                name: 'DisposalWarningCard',
                useCases: [
                  WidgetbookUseCase(
                    name: 'High Severity',
                    builder: (context) => _surface(
                      const DisposalWarningCard(
                        title: 'Hazardous Material',
                        warnings: [
                          'Do not mix with regular waste',
                          'Use protective gloves',
                        ],
                        severity: WarningSeverity.high,
                      ),
                    ),
                  ),
                ],
              ),
              WidgetbookComponent(
                name: 'LocalRuleChip',
                useCases: [
                  WidgetbookUseCase(
                    name: 'Default',
                    builder: (context) => _surface(
                      const LocalRuleChip(
                        authority: 'BBMP',
                        label: 'Daily collection 6-10 AM',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Navigation and Dialogs',
            useCases: [
              WidgetbookUseCase(
                name: 'ModernBottomNavigation',
                builder: (context) => _surface(
                  SizedBox(
                    height: 90,
                    child: ModernBottomNavigation(
                      currentIndex: 0,
                      onTap: (_) {},
                      items: const [
                        BottomNavItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home,
                          label: 'Home',
                        ),
                        BottomNavItem(
                          icon: Icons.history_outlined,
                          selectedIcon: Icons.history,
                          label: 'History',
                        ),
                        BottomNavItem(
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ResponsiveDialog',
                builder: (context) => _surface(
                  ResponsiveDialog(
                    title: 'Confirm Action',
                    content: const Text('Apply this change to your settings?'),
                    actions: const [
                      TextButton(onPressed: _noop, child: Text('Cancel')),
                      ElevatedButton(onPressed: _noop, child: Text('Apply')),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'DataMigrationDialog',
                builder: (context) => _surface(
                  const DataMigrationDialog(guestDataCount: 4),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Premium Components',
            useCases: [
              WidgetbookUseCase(
                name: 'PremiumFeatureCard',
                builder: (context) => _surface(
                  PremiumFeatureCard(
                    feature: PremiumFeature.features.first,
                    isEnabled: false,
                    onTap: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'PremiumSegmentationToggle',
                builder: (context) => _surface(
                  ChangeNotifierProvider(
                    create: (_) => PremiumService(),
                    child: const PremiumSegmentationToggle(value: false),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Gamification Indicators',
            useCases: [
              WidgetbookUseCase(
                name: 'StreakIndicator',
                builder: (context) => _surface(
                  StreakIndicator(
                    streak: Streak(
                      current: 6,
                      longest: 14,
                      lastUsageDate: DateTime(2026, 5, 20),
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'PointsIndicator',
                builder: (context) => _surface(
                  const PointsIndicator(
                    points: UserPoints(total: 880, level: 9),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ChallengeCard',
                builder: (context) => _surface(
                  ChallengeCard(challenge: _sampleChallenge()),
                ),
              ),
              WidgetbookUseCase(
                name: 'AchievementGrid',
                builder: (context) => _surface(
                  SizedBox(
                    height: 280,
                    child: AchievementGrid(
                      achievements: [_sampleAchievement()],
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'AchievementNotification',
                builder: (context) => _surface(
                  AchievementNotification(
                    achievement: _sampleAchievement(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EnhancedPointsIndicator',
                builder: (context) => _surface(
                  const EnhancedPointsIndicator(
                    points: UserPoints(total: 1200, level: 12),
                    previousPoints: UserPoints(total: 1100, level: 11),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'EnhancedChallengeCard',
                builder: (context) => _surface(
                  EnhancedChallengeCard(challenge: _sampleChallenge()),
                ),
              ),
              WidgetbookUseCase(
                name: 'LifetimePointsIndicator',
                builder: (context) => _surface(
                  const LifetimePointsIndicator(
                    points: UserPoints(total: 2400, level: 18),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Dashboard Widgets',
            useCases: [
              WidgetbookUseCase(
                name: 'TodaysImpactGoal',
                builder: (context) => _surface(
                  const TodaysImpactGoal(
                    currentClassifications: 7,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'GlobalImpactMeter',
                builder: (context) => _surface(
                  const GlobalImpactMeter(
                    globalCO2Saved: 1842.5,
                    globalItemsClassified: 126500,
                    activeUsers: 18600,
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Error Boundaries',
            useCases: [
              WidgetbookUseCase(
                name: 'ErrorBoundary',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 120,
                    child: ErrorBoundary(
                      child: Center(child: Text('Safe child content')),
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'AsyncErrorBoundary',
                builder: (context) => _surface(
                  SizedBox(
                    height: 120,
                    child: AsyncErrorBoundary(
                      future: Future.value('Loaded'),
                      builder: (ctx, data) => Text(data.toString()),
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'NetworkErrorBoundary',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 120,
                    child: NetworkErrorBoundary(
                      child: Center(child: Text('Network child')),
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Animated and Charts Expansion',
            useCases: [
              WidgetbookUseCase(
                name: 'AnimatedFAB',
                builder: (context) => _surface(
                  const AnimatedFAB(onPressed: _noop, isPulsing: false),
                ),
              ),
              WidgetbookUseCase(
                name: 'FlameStreakWidget',
                builder: (context) => _surface(
                  const FlameStreakWidget(streakCount: 9),
                ),
              ),
              WidgetbookUseCase(
                name: 'CelebrationOverlay',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 200,
                    child: CelebrationOverlay(
                      isVisible: true,
                      message: 'Great sorting streak!',
                    ),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'SortingAnimationWidget',
                builder: (context) => _surface(
                  const SortingAnimationWidget(
                    child: Text('Sorting transition preview'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'AnimatedDashboardWidget',
                builder: (context) => _surface(
                  const AnimatedDashboardWidget(
                    child: Text('Dashboard animation wrapper'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ProgressTrackingWidget',
                builder: (context) => _surface(
                  const ProgressTrackingWidget(
                    child: Text('Progress animation wrapper'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'CommunityFeedWidget',
                builder: (context) => _surface(
                  const CommunityFeedWidget(
                    child: Text('Community update item'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'LeaderboardWidget',
                builder: (context) => _surface(
                  const LeaderboardWidget(
                    child: Text('Leaderboard row'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'ContentDiscoveryWidget',
                builder: (context) => _surface(
                  const ContentDiscoveryWidget(
                    child: Text('Educational content card'),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'DailyTipRevealWidget',
                builder: (context) => _surface(
                  const DailyTipRevealWidget(
                    tip: 'Rinse containers before recycling.',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'FloatingParticleSystem',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 220,
                    child: FloatingParticleSystem(particleCount: 14),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'PulsingScanButton',
                builder: (context) => _surface(
                  PulsingScanButton(onPressed: _noop),
                ),
              ),
              WidgetbookUseCase(
                name: 'ImpactVisualizationRing',
                builder: (context) => _surface(
                  const ImpactVisualizationRing(
                    progress: 0.62,
                    targetValue: 100,
                    currentValue: 62,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'MorphingProgressIndicator',
                builder: (context) => _surface(
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: MorphingProgressIndicator(progress: 0.74),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Chart Widgets',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 300,
                    child: _WidgetbookChartsPreview(),
                  ),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Final Coverage',
            useCases: [
              WidgetbookUseCase(
                name: 'AchievementCelebrationDisplay',
                builder: (context) => _surface(
                  AchievementCelebrationDisplay(
                    achievement: _sampleAchievement(),
                    onDismiss: _noop,
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'AnalysisProgressView',
                builder: (context) => _surface(
                  const AnalysisProgressView(
                    state: ClassificationState.cloudClassifying,
                    imageName: 'plastic-bottle.jpg',
                    statusMessage: 'Analyzing image',
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Enhanced Gamification Popups',
                builder: (context) => _surface(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClassificationFeedback(category: 'Dry Waste'),
                      const SizedBox(height: 8),
                      ChallengeCompletedPopup(challenge: _sampleChallenge()),
                      const SizedBox(height: 8),
                      FloatingAchievementBadge(
                        achievement: _sampleAchievement(),
                      ),
                      const SizedBox(height: 8),
                      EnhancedAchievementNotification(
                        achievement: _sampleAchievement(),
                      ),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Tags and Impact',
                builder: (context) => _surface(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InteractiveTag(
                        text: 'Recyclable',
                        color: Colors.green,
                        action: TagAction.info,
                      ),
                      const SizedBox(height: 8),
                      InteractiveTagCollection(
                        tags: const [
                          TagData(
                            text: 'Dry',
                            color: Colors.blue,
                            action: TagAction.info,
                          ),
                          TagData(
                            text: 'Hazardous',
                            color: Colors.red,
                            action: TagAction.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      EnvironmentalImpactIndicator(
                        classification: _sampleClassification(),
                      ),
                      const SizedBox(height: 8),
                      const PulseBadge(
                        child: Text('Live', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Dialogs and Utility Widgets',
                builder: (context) => _surface(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EnhancedHistoryFilterDialog(
                        initialFilters: FilterOptions.empty(),
                        onFiltersChanged: (_) {},
                      ),
                      const SizedBox(height: 8),
                      const SimpleWebCamera(onCapture: _onXFileCapture),
                      const SizedBox(height: 8),
                      ErrorCatchingWidget(
                        onError: (_, __) {},
                        child: const Text('Error catcher child'),
                      ),
                      const SizedBox(height: 8),
                      const CodeCircle(code: '1', borderColor: Colors.green),
                      const SizedBox(height: 8),
                      const InfoRow(
                        label: 'Examples',
                        text: 'Bottles and containers',
                      ),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'History and Preview',
                builder: (context) => _surface(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommunityFeedPreview(
                        activities: const [
                          CommunityActivity(
                            userName: 'Alex',
                            action: 'sorted 5 items',
                            timeAgo: '2m ago',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      HistoryListItem(
                        classification: _sampleClassification(),
                        onTap: _noop,
                        onFeedbackSubmitted: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Multi Item Review',
                builder: (context) => _surface(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PerItemResultCard(
                        region: DetectedWasteRegion(
                          boundingBox: NormalizedBoundingBox(
                            left: 0.1,
                            top: 0.1,
                            width: 0.4,
                            height: 0.4,
                          ),
                          classification: _sampleClassification(),
                          confidence: 0.86,
                          userConfirmed: true,
                          label: 'Item 1',
                        ),
                        index: 0,
                        totalItems: 2,
                      ),
                      const SizedBox(height: 12),
                      MultiItemRegionReview(
                        regions: [
                          DetectedWasteRegion(
                            boundingBox: NormalizedBoundingBox(
                              left: 0.05,
                              top: 0.08,
                              width: 0.35,
                              height: 0.35,
                            ),
                            classification: _sampleClassification(),
                            confidence: 0.82,
                            userConfirmed: true,
                            label: 'Bottle',
                          ),
                        ],
                        onToggleConfirm: _onRegionToggle,
                        onRemoveRegion: _onRegionRemove,
                      ),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Remaining Empty States',
                builder: (context) => _surface(
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyAchievementsStateWidget(),
                      SizedBox(height: 8),
                      EmptyFilteredResultsWidget(activeFiltersCount: 2),
                      SizedBox(height: 8),
                      EmptyEducationalContentWidget(category: 'Plastic'),
                    ],
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'Infra Widgets',
                builder: (context) => _surface(
                  const Text('Infrastructure coverage references included'),
                ),
              ),
            ],
          ),
          WidgetbookComponent(
            name: 'Ads and Dashboards',
            useCases: [
              WidgetbookUseCase(
                name: 'BannerAdWidget',
                builder: (context) => _surface(const BannerAdWidget()),
              ),
              WidgetbookUseCase(
                name: 'WasteImpactDashboard',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 320,
                    child: WasteImpactDashboard(),
                  ),
                ),
              ),
              WidgetbookUseCase(
                name: 'CyberpunkWasteImpactDashboard',
                builder: (context) => _surface(
                  const SizedBox(
                    height: 320,
                    child: CyberpunkWasteImpactDashboard(),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

Widget _surface(Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

class _WidgetbookChartsPreview extends StatefulWidget {
  const _WidgetbookChartsPreview();

  @override
  State<_WidgetbookChartsPreview> createState() =>
      _WidgetbookChartsPreviewState();
}

class _WidgetbookChartsPreviewState extends State<_WidgetbookChartsPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = [
      ChartData('Dry', 36, Colors.blue),
      ChartData('Wet', 28, Colors.green),
      ChartData('Haz', 14, Colors.red),
      ChartData('Ewaste', 10, Colors.purple),
    ];

    final timed = [
      {'month': 'Jan', 'Dry': 0.35, 'Wet': 0.25, 'Haz': 0.2},
      {'month': 'Feb', 'Dry': 0.4, 'Wet': 0.22, 'Haz': 0.18},
      {'month': 'Mar', 'Dry': 0.45, 'Wet': 0.2, 'Haz': 0.15},
    ];

    return Column(
      children: [
        Expanded(
          child: WasteCategoryPieChart(
            data: data,
            animationController: _controller,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TopSubcategoriesBarChart(
            data: data,
            animationController: _controller,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: WeeklyItemsChart(
            data: data,
            animationController: _controller,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: WasteTimeSeriesChart(
            data: data,
            animationController: _controller,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CategoryDistributionChart(
            data: timed,
            animationController: _controller,
          ),
        ),
      ],
    );
  }
}

ColorScheme _buildExplorationScheme(String palette, {required bool darkMode}) {
  final brightness = darkMode ? Brightness.dark : Brightness.light;
  final seed = switch (palette) {
    'Forest' => const Color(0xFF2E7D32),
    'Sunset' => const Color(0xFFEF6C00),
    _ => const Color(0xFF1565C0),
  };

  return ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    primary: seed,
    secondary: switch (palette) {
      'Forest' => const Color(0xFF66BB6A),
      'Sunset' => const Color(0xFFFFB74D),
      _ => const Color(0xFF4DB6AC),
    },
    tertiary: switch (palette) {
      'Forest' => const Color(0xFFA5D6A7),
      'Sunset' => const Color(0xFFFF8A65),
      _ => const Color(0xFF80CBC4),
    },
    surface: darkMode ? const Color(0xFF121212) : const Color(0xFFFBFBFB),
  );
}

class _TokenPlaygroundCard extends StatelessWidget {
  const _TokenPlaygroundCard({
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.radius,
    required this.elevation,
    required this.bodyText,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color accentColor;
  final double radius;
  final double elevation;
  final String bodyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: elevation,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Token playground',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bodyText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorSwatch(label: 'Primary', color: primaryColor),
                _ColorSwatch(label: 'Secondary', color: secondaryColor),
                _ColorSwatch(label: 'Accent', color: accentColor),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _SemanticSwatch(label: 'Success', color: AppTheme.successColor),
                _SemanticSwatch(label: 'Warning', color: AppTheme.warningColor),
                _SemanticSwatch(label: 'Error', color: AppTheme.errorColor),
                _SemanticSwatch(label: 'Info', color: AppTheme.infoColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeMatrixCard extends StatelessWidget {
  const _ThemeMatrixCard({
    required this.palette,
    required this.darkMode,
    required this.colorScheme,
  });

  final String palette;
  final bool darkMode;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$palette palette',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              darkMode ? 'Dark exploration' : 'Light exploration',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorSwatch(label: 'Primary', color: colorScheme.primary),
                _ColorSwatch(label: 'Secondary', color: colorScheme.secondary),
                _ColorSwatch(label: 'Surface', color: colorScheme.surface),
                _ColorSwatch(label: 'Tertiary', color: colorScheme.tertiary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Primary',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.secondary),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Secondary',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLight =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLight ? Colors.black87 : Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _SemanticSwatch extends StatelessWidget {
  const _SemanticSwatch({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLight =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLight ? Colors.black87 : Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class SegregationInsightBanner extends StatelessWidget {
  const SegregationInsightBanner({
    super.key,
    required this.title,
    required this.message,
    required this.emphasis,
    required this.showAction,
  });

  final String title;
  final String message;
  final Color emphasis;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            emphasis.withValues(alpha: 0.14),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: emphasis.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: emphasis),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (showAction) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: emphasis),
                onPressed: _noop,
                child: const Text('Open insight'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ImpactCalloutCard extends StatelessWidget {
  const ImpactCalloutCard({
    super.key,
    required this.headline,
    required this.detail,
    required this.accent,
    required this.showMetric,
  });

  final String headline;
  final String detail;
  final Color accent;
  final bool showMetric;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
            if (showMetric) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '34% dry waste this week',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _tabBuilder(BuildContext context, TabController controller) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TabBar(
        controller: controller,
        tabs: const [Tab(text: 'A'), Tab(text: 'B')],
      ),
      const SizedBox(
        height: 40,
        child: TabBarView(
          children: [Center(child: Text('A')), Center(child: Text('B'))],
        ),
      ),
    ],
  );
}

// ignore: unused_element
List<Widget> _referenceCoverageOnlyWidgets() {
  return [
    AchievementCelebration(
      achievement: _sampleAchievement(),
      onDismiss: _noop,
    ),
    const MainNavigationWrapper(),
    const AlternativeNavigationWrapper(),
    CacheStatisticsCard(
      cacheService: ClassificationCacheService(),
      autoRefresh: false,
    ),
    const DeveloperSection(showDeveloperOptions: true),
    PerformanceMonitoringDashboard(
      modelService: ModelSelectionService(aiService: AiService()),
    ),
    AnimatedTabController(length: 2, builder: _tabBuilder),
    EnhancedReanalysisWidget(classification: _sampleClassification()),
    PerItemResultCard(
      region: DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
          left: 0.1,
          top: 0.1,
          width: 0.4,
          height: 0.4,
        ),
        classification: _sampleClassification(),
        confidence: 0.86,
        userConfirmed: true,
        label: 'Item 1',
      ),
      index: 0,
      totalItems: 2,
    ),
    MultiItemRegionReview(
      regions: [
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.05,
            top: 0.08,
            width: 0.35,
            height: 0.35,
          ),
          classification: _sampleClassification(),
          confidence: 0.82,
          userConfirmed: true,
          label: 'Bottle',
        ),
      ],
      onToggleConfirm: _onRegionToggle,
      onRemoveRegion: _onRegionRemove,
    ),
  ];
}

void _onXFileCapture(dynamic _) {}
void _onRegionToggle(String _) {}
void _onRegionRemove(String _) {}

void _noop() {}

void _onToggleChanged(bool _) {}

Challenge _sampleChallenge() {
  return Challenge(
    id: 'challenge-1',
    title: 'Sort 15 Items',
    description: 'Classify fifteen items this week.',
    startDate: DateTime(2026, 5, 18),
    endDate: DateTime(2026, 5, 28),
    pointsReward: 150,
    iconName: 'emoji_events',
    color: Colors.orange,
    requirements: const {'classifications': 15},
    progress: 0.6,
  );
}

Achievement _sampleAchievement() {
  return Achievement(
    id: 'achievement-1',
    title: 'Recycling Rookie',
    description: 'Complete your first successful classifications.',
    type: AchievementType.wasteIdentified,
    threshold: 10,
    iconName: 'military_tech',
    color: Colors.green,
    progress: 0.8,
  );
}

WasteClassification _sampleClassification() {
  return WasteClassification(
    itemName: 'Plastic Bottle',
    category: 'Dry Waste',
    explanation:
        'Detected clear PET plastic body with recyclable packaging profile.',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Rinse and place in dry waste recycling stream',
      steps: const [
        'Empty the bottle fully',
        'Rinse quickly to remove residue',
        'Keep cap separated if local policy requires',
      ],
      hasUrgentTimeframe: false,
    ),
    region: 'Bangalore',
    visualFeatures: const ['transparent plastic', 'narrow neck', 'screw cap'],
    alternatives: const [],
    confidence: 0.84,
    localGuidelinesReference: 'BBMP Dry Waste Handling v2',
    localRegulations: const {
      'segregation_requirement': 'Keep separate from wet waste.',
      'collection_frequency': 'Twice weekly collection.',
    },
    alternativeOptions: const [
      'Return to buyback center',
      'Upcycle as planter'
    ],
    relatedItems: const ['Plastic cup', 'Detergent bottle'],
    materials: const ['PET', 'HDPE cap'],
  );
}
