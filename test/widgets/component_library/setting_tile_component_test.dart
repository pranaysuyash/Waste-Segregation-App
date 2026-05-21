import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';

import '../../helpers/component_test_harness.dart';

void main() {
  group('Setting tile component library', () {
    testWidgets('renders enabled SettingTile', (tester) async {
      await pumpComponent(
        tester,
        const SettingTile(
          icon: Icons.settings,
          title: 'General',
          subtitle: 'Manage app preferences',
          onTap: _noop,
        ),
      );

      expect(find.text('General'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders disabled SettingTile', (tester) async {
      await pumpComponent(
        tester,
        const SettingTile(
          icon: Icons.sync_disabled,
          title: 'Cloud Sync',
          subtitle: 'Unavailable offline',
          enabled: false,
        ),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.enabled, isFalse);
      expect(find.text('Cloud Sync'), findsOneWidget);
    });

    testWidgets('renders SettingToggleTile and toggles', (tester) async {
      var value = false;
      await pumpComponent(
        tester,
        SettingToggleTile(
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          value: value,
          onChanged: (next) => value = next,
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(value, isTrue);
    });
  });
}

void _noop() {}
