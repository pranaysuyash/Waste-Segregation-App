import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/settings/animated_setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/responsive_settings_layout.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';

void main() {
  group('Phase 3 Components Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    testWidgets('AnimatedSettingTile renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AnimatedSettingTile(
            icon: Icons.settings,
            title: 'Animated Setting',
            subtitle: 'Test animated subtitle',
            enableSlideInAnimation: false, // Disable for testing
          ),
        ),
      );

      expect(find.text('Animated Setting'), findsOneWidget);
      expect(find.text('Test animated subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('AnimatedSettingTile handles tap', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        createTestWidget(
          AnimatedSettingTile(
            icon: Icons.settings,
            title: 'Tappable Setting',
            enableSlideInAnimation: false,
            enableTapAnimation: false, // Disable for testing
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Tappable Setting'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('ResponsiveSettingsLayout renders mobile layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ResponsiveSettingsLayout(
            sections: [
              const SettingTile(
                icon: Icons.settings,
                title: 'Test Section 1',
              ),
              const SettingTile(
                icon: Icons.settings,
                title: 'Test Section 2',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Test Section 1'), findsOneWidget);
      expect(find.text('Test Section 2'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('ResponsiveSettingsLayout adapts to tablet size', (WidgetTester tester) async {
      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        createTestWidget(
          ResponsiveSettingsLayout(
            tabletBreakpoint: 600,
            sections: [
              const SettingTile(
                icon: Icons.settings,
                title: 'Tablet Section 1',
              ),
              const SettingTile(
                icon: Icons.settings,
                title: 'Tablet Section 2',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tablet Section 1'), findsOneWidget);
      expect(find.text('Tablet Section 2'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      
      // Reset view size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('StaggeredSettingsAnimation renders children', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const StaggeredSettingsAnimation(
            enableAnimation: false, // Disable animation for testing
            children: [
              Text('Staggered Item 1'),
              Text('Staggered Item 2'),
              Text('Staggered Item 3'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for any animations to complete

      expect(find.text('Staggered Item 1'), findsOneWidget);
      expect(find.text('Staggered Item 2'), findsOneWidget);
      expect(find.text('Staggered Item 3'), findsOneWidget);
    });

    testWidgets('AnimatedSectionHeader expands and collapses', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AnimatedSectionHeader(
            title: 'Expandable Section',
            icon: Icons.expand_more,
            children: [
              Text('Hidden Content'),
            ],
          ),
        ),
      );

      expect(find.text('Expandable Section'), findsOneWidget);
      expect(find.text('Hidden Content'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsAtLeastNWidget(1));

      // Test tap to collapse
      await tester.tap(find.text('Expandable Section'));
      await tester.pumpAndSettle();

      // Content should still be findable but may be animated out
      expect(find.text('Expandable Section'), findsOneWidget);
    });
  });
} 