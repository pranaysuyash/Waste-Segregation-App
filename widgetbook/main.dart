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
import 'package:waste_segregation_app/widgets/animations/enhanced_loading_states.dart';
import 'package:waste_segregation_app/widgets/animations/error_recovery_animations.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/impact_dashboard_example.dart';
import 'package:waste_segregation_app/widgets/advanced_ui/cyberpunk_dashboard_example.dart';
import 'package:waste_segregation_app/models/gamification.dart';

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
                    isPositiveTrend: true,
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
                    isSelected: false,
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

void _noop() {}

void _onToggleChanged(bool _) {}

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
