import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';

import '../test_config/test_providers.dart';
import '../../lib/widgets/settings/setting_tile.dart';
import '../../lib/widgets/settings/settings_theme.dart';
import '../../lib/widgets/settings/account_section.dart';
import '../../lib/widgets/settings/premium_section.dart';
import '../../lib/widgets/settings/app_settings_section.dart';

void main() {
  group('Settings Golden Tests', () {
    testGoldens('SettingTile variants', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: _buildSettingTileVariants(),
          name: 'setting_tile_variants',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/setting_tile_variants');
    });

    testGoldens('SettingTile states', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: _buildSettingTileStates(),
          name: 'setting_tile_states',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/setting_tile_states');
    });

    testGoldens('Settings sections light theme', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: _buildSettingsSections(ThemeMode.light),
          name: 'settings_sections_light',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/sections_light_theme');
    });

    testGoldens('Settings sections dark theme', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: _buildSettingsSections(ThemeMode.dark),
          name: 'settings_sections_dark',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/sections_dark_theme');
    });

    testGoldens('Settings accessibility features', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: _buildAccessibilityFeatures(),
          name: 'accessibility_features',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/accessibility_features');
    });

    testGoldens('Settings responsive design', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletPortrait,
          Device.tabletLandscape,
        ])
        ..addScenario(
          widget: _buildResponsiveSettings(),
          name: 'responsive_settings',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'settings/responsive_design');
    });
  });
}

Widget _buildSettingTileVariants() {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic tile
          SettingTile(
            icon: Icons.settings,
            title: 'Basic Setting',
            subtitle: 'Simple setting with icon',
            onTap: () {},
          ),
          
          // Tile with custom colors
          SettingTile(
            icon: Icons.palette,
            iconColor: Colors.purple,
            titleColor: Colors.purple,
            title: 'Custom Colors',
            subtitle: 'Setting with custom colors',
            onTap: () {},
          ),
          
          // Disabled tile
          SettingTile(
            icon: Icons.block,
            title: 'Disabled Setting',
            subtitle: 'This setting is disabled',
            enabled: false,
            onTap: () {},
          ),
          
          // Tile with custom trailing
          SettingTile(
            icon: Icons.star,
            title: 'Premium Feature',
            subtitle: 'Requires premium subscription',
            trailing: Container(
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
            onTap: () {},
          ),
          
          // Toggle tile
          SettingToggleTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Enable push notifications',
            value: true,
            onChanged: (value) {},
          ),
          
          // Toggle tile disabled
          SettingToggleTile(
            icon: Icons.wifi,
            title: 'Offline Mode',
            subtitle: 'Work without internet',
            value: false,
            enabled: false,
            onChanged: (value) {},
          ),
        ],
      ),
    ),
  );
}

Widget _buildSettingTileStates() {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const Text('Normal State'),
          SettingTile(
            icon: Icons.settings,
            title: 'Normal Setting',
            subtitle: 'Default state',
            onTap: () {},
          ),
          
          const SizedBox(height: 16),
          const Text('Focused State (simulated)'),
          Focus(
            autofocus: true,
            child: SettingTile(
              icon: Icons.keyboard,
              title: 'Focused Setting',
              subtitle: 'This tile has focus',
              onTap: () {},
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Disabled State'),
          SettingTile(
            icon: Icons.block,
            title: 'Disabled Setting',
            subtitle: 'Cannot be interacted with',
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}

Widget _buildSettingsSections(ThemeMode themeMode) {
  return MultiProvider(
    providers: TestProviders.allProviders,
    child: MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const SingleChildScrollView(
          child: Column(
            children: [
              AccountSection(),
              SizedBox(height: 16),
              PremiumSection(),
              SizedBox(height: 16),
              AppSettingsSection(),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAccessibilityFeatures() {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          // Semantic labels demo
          Semantics(
            label: 'Premium feature setting',
            hint: 'Tap to upgrade to premium',
            child: SettingTile(
              icon: Icons.star,
              title: 'Premium Analytics',
              subtitle: 'Advanced insights and trends',
              trailing: Semantics(
                label: 'Premium feature badge',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('PRO'),
                ),
              ),
              onTap: () {},
            ),
          ),
          
          // High contrast example
          Container(
            color: Colors.black,
            child: SettingTile(
              icon: Icons.contrast,
              iconColor: Colors.white,
              titleColor: Colors.white,
              title: 'High Contrast Mode',
              subtitle: 'Better visibility for low vision users',
              onTap: () {},
            ),
          ),
          
          // Large text example
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: SettingTile(
              icon: Icons.text_fields,
              title: 'Large Text Example',
              subtitle: 'This shows how the tile adapts to large text',
              onTap: () {},
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildResponsiveSettings() {
  return MaterialApp(
    home: Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          
          if (isTablet) {
            // Two-column layout for tablets
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.account_circle,
                        title: 'Account Settings',
                        subtitle: 'Manage your account',
                        onTap: () {},
                      ),
                      SettingTile(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Configure alerts',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.palette,
                        title: 'Theme Settings',
                        subtitle: 'Customize appearance',
                        onTap: () {},
                      ),
                      SettingTile(
                        icon: Icons.security,
                        title: 'Privacy & Security',
                        subtitle: 'Protect your data',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Single column for phones
            return Column(
              children: [
                SettingTile(
                  icon: Icons.account_circle,
                  title: 'Account Settings',
                  subtitle: 'Manage your account',
                  onTap: () {},
                ),
                SettingTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Configure alerts',
                  onTap: () {},
                ),
                SettingTile(
                  icon: Icons.palette,
                  title: 'Theme Settings',
                  subtitle: 'Customize appearance',
                  onTap: () {},
                ),
                SettingTile(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Protect your data',
                  onTap: () {},
                ),
              ],
            );
          }
        },
      ),
    ),
  );
} 