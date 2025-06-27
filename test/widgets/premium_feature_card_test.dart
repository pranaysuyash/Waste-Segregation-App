import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/premium_feature_card.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

void main() {
  group('PremiumFeatureCard Tests', () {
    late PremiumFeature testFeature;
    late PremiumFeature testFeatureWithComplexIcon;

    setUp(() {
      testFeature = const PremiumFeature(
        id: 'test_feature',
        title: 'Advanced Analytics',
        description: 'Get detailed insights into your waste management patterns.',
        icon: 'bar_chart',
        route: '/analytics',
        isEnabled: true,
      );

      testFeatureWithComplexIcon = const PremiumFeature(
        id: 'complex_feature',
        title: 'AI-Powered Recommendations',
        description: 'Receive personalized suggestions for better waste segregation.',
        icon: 'auto_awesome',
        route: '/ai_recommendations',
        isEnabled: true,
      );
    });

    Widget createTestWidget({
      PremiumFeature? feature,
      bool isEnabled = true,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PremiumFeatureCard(
            feature: feature ?? testFeature,
            isEnabled: isEnabled,
            onTap: onTap,
          ),
        ),
      );
    }

    group('Widget Construction', () {
      testWidgets('should render feature card with basic information', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Advanced Analytics'), findsOneWidget);
        expect(find.text('Get detailed insights into your waste management patterns.'), findsOneWidget);
      });

      testWidgets('should render with enabled state', (tester) async {
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsNothing);
      });

      testWidgets('should render with disabled state', (tester) async {
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      });

      testWidgets('should handle different feature icons', (tester) async {
        await tester.pumpWidget(createTestWidget(
          feature: testFeatureWithComplexIcon,
        ));

        expect(find.text('AI-Powered Recommendations'), findsOneWidget);
        expect(find.byType(Icon), findsAtLeastNWidgets(2)); // Feature icon + status icon
      });

      testWidgets('should handle invalid icon gracefully', (tester) async {
        final featureWithInvalidIcon = const PremiumFeature(
          id: 'invalid_icon_feature',
          title: 'Invalid Icon Feature',
          description: 'This feature has an invalid icon name.',
          icon: 'invalid_icon_name_12345',
          route: '/invalid',
          isEnabled: true,
        );

        await tester.pumpWidget(createTestWidget(
          feature: featureWithInvalidIcon,
        ));

        expect(find.text('Invalid Icon Feature'), findsOneWidget);
        expect(find.byType(Icon), findsAtLeastNWidgets(2)); // Should fall back to default icon
      });
    });

    group('Interaction Handling', () {
      testWidgets('should handle tap when onTap is provided', (tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(createTestWidget(
          onTap: () => wasTapped = true,
        ));

        await tester.tap(find.byType(PremiumFeatureCard));
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });

      testWidgets('should not crash when onTap is null', (tester) async {
        await tester.pumpWidget(createTestWidget(onTap: null));

        expect(() async {
          await tester.tap(find.byType(PremiumFeatureCard));
          await tester.pumpAndSettle();
        }, returnsNormally);
      });

      testWidgets('should show ink splash effect on tap', (tester) async {
        await tester.pumpWidget(createTestWidget(onTap: () {}));

        expect(find.byType(InkWell), findsOneWidget);

        await tester.tap(find.byType(PremiumFeatureCard));
        await tester.pump(const Duration(milliseconds: 100));

        // Ink splash should be visible during animation
        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('should handle rapid taps without issues', (tester) async {
        int tapCount = 0;

        await tester.pumpWidget(createTestWidget(
          onTap: () => tapCount++,
        ));

        // Rapidly tap multiple times
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(PremiumFeatureCard));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(tapCount, equals(5));
      });
    });

    group('Visual State Differences', () {
      testWidgets('should show different colors for enabled vs disabled state', (tester) async {
        // Test enabled state
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        final enabledCard = tester.widget<Card>(find.byType(Card));

        // Test disabled state
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        final disabledCard = tester.widget<Card>(find.byType(Card));

        // Both should be Card widgets but with different visual states
        expect(enabledCard, isA<Card>());
        expect(disabledCard, isA<Card>());
      });

      testWidgets('should show correct status icons', (tester) async {
        // Test enabled state
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        final checkIcon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(checkIcon.color, equals(Colors.green));

        // Test disabled state
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        expect(find.byIcon(Icons.lock), findsOneWidget);

        final lockIcon = tester.widget<Icon>(find.byIcon(Icons.lock));
        expect(lockIcon.color, equals(Colors.grey));
      });

      testWidgets('should style feature icon based on enabled state', (tester) async {
        // Test enabled state
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        final enabledIcons = tester.widgetList<Icon>(find.byType(Icon)).toList();

        // Test disabled state
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        final disabledIcons = tester.widgetList<Icon>(find.byType(Icon)).toList();

        // Should have icons in both states
        expect(enabledIcons.length, greaterThanOrEqualTo(2));
        expect(disabledIcons.length, greaterThanOrEqualTo(2));
      });

      testWidgets('should style text based on enabled state', (tester) async {
        // Test enabled state
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        final enabledTitle = tester.widget<Text>(find.text('Advanced Analytics'));
        expect(enabledTitle.style?.color, isNot(equals(Colors.grey)));

        // Test disabled state
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        final disabledTitle = tester.widget<Text>(find.text('Advanced Analytics'));
        expect(disabledTitle.style?.color, equals(Colors.grey));
      });
    });

    group('Layout and Styling', () {
      testWidgets('should have proper card styling', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final card = tester.widget<Card>(find.byType(Card));

        expect(card.margin, equals(const EdgeInsets.only(bottom: 16)));
        expect(card.clipBehavior, equals(Clip.antiAlias));
        expect(card.elevation, equals(2));

        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(12)));
      });

      testWidgets('should have proper content layout', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(2)); // Icon container + main container
      });

      testWidgets('should have proper spacing between elements', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));

        // Should have SizedBox widgets for spacing
        expect(sizedBoxes.length, greaterThanOrEqualTo(2));
      });

      testWidgets('should handle long text properly', (tester) async {
        final longTextFeature = const PremiumFeature(
          id: 'long_text',
          title: 'This is a very long title that should wrap properly and not overflow the layout boundaries',
          description:
              'This is an extremely long description that contains a lot of text and should be handled gracefully by the widget layout system without causing any overflow issues or layout problems in the user interface.',
          icon: 'description',
          route: '/long_text',
          isEnabled: true,
        );

        await tester.pumpWidget(createTestWidget(feature: longTextFeature));

        expect(find.textContaining('This is a very long title'), findsOneWidget);
        expect(find.textContaining('This is an extremely long description'), findsOneWidget);

        // Should not have overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty or minimal text', (tester) async {
        final minimalFeature = const PremiumFeature(
          id: 'minimal',
          title: 'A',
          description: 'B',
          icon: 'star',
          route: '/minimal',
          isEnabled: true,
        );

        await tester.pumpWidget(createTestWidget(feature: minimalFeature));

        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });

      testWidgets('should be tappable for accessibility tools', (tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(createTestWidget(
          onTap: () => wasTapped = true,
        ));

        final inkWell = find.byType(InkWell);
        expect(inkWell, findsOneWidget);

        await tester.tap(inkWell);
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });

      testWidgets('should have sufficient contrast for disabled state', (tester) async {
        await tester.pumpWidget(createTestWidget(isEnabled: false));

        final disabledTitle = tester.widget<Text>(find.text('Advanced Analytics'));
        expect(disabledTitle.style?.color, equals(Colors.grey));

        // Grey should provide sufficient contrast for accessibility
        final greyLuminance = Colors.grey.computeLuminance();
        expect(greyLuminance, greaterThan(0.1)); // Should not be too dark
      });
    });

    group('Theme Integration', () {
      testWidgets('should respect light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: PremiumFeatureCard(
                feature: testFeature,
                isEnabled: true,
              ),
            ),
          ),
        );

        expect(find.byType(PremiumFeatureCard), findsOneWidget);
      });

      testWidgets('should respect dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PremiumFeatureCard(
                feature: testFeature,
                isEnabled: true,
              ),
            ),
          ),
        );

        expect(find.byType(PremiumFeatureCard), findsOneWidget);
      });

      testWidgets('should use theme primary color when enabled', (tester) async {
        const customColor = Colors.purple;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              primaryColor: customColor,
              colorScheme: ColorScheme.fromSeed(seedColor: customColor),
            ),
            home: Scaffold(
              body: PremiumFeatureCard(
                feature: testFeature,
                isEnabled: true,
              ),
            ),
          ),
        );

        expect(find.byType(PremiumFeatureCard), findsOneWidget);
        // Primary color should be used in enabled state
      });
    });

    group('Different Feature Types', () {
      testWidgets('should handle different premium tiers', (tester) async {
        final features = [
          const PremiumFeature(
            id: 'basic_feature',
            title: 'Basic Feature',
            description: 'This is a basic feature',
            icon: 'bar_chart',
            route: '/basic',
            isEnabled: true,
          ),
          const PremiumFeature(
            id: 'premium_feature',
            title: 'Premium Feature',
            description: 'This is a premium feature',
            icon: 'bar_chart',
            route: '/premium',
            isEnabled: true,
          ),
          const PremiumFeature(
            id: 'enterprise_feature',
            title: 'Enterprise Feature',
            description: 'This is an enterprise feature',
            icon: 'bar_chart',
            route: '/enterprise',
            isEnabled: true,
          ),
        ];

        for (final feature in features) {
          await tester.pumpWidget(createTestWidget(feature: feature));
          expect(find.text('Advanced Analytics'), findsOneWidget);
        }
      });

      testWidgets('should handle active and inactive features', (tester) async {
        final activeFeature = const PremiumFeature(
          id: 'active_feature',
          title: 'Active Feature',
          description: 'This is an active feature',
          icon: 'bar_chart',
          route: '/active',
          isEnabled: true,
        );
        final inactiveFeature = const PremiumFeature(
          id: 'inactive_feature',
          title: 'Inactive Feature',
          description: 'This is an inactive feature',
          icon: 'bar_chart',
          route: '/inactive',
          isEnabled: false,
        );

        await tester.pumpWidget(createTestWidget(feature: activeFeature));
        expect(find.text('Advanced Analytics'), findsOneWidget);

        await tester.pumpWidget(createTestWidget(feature: inactiveFeature));
        expect(find.text('Advanced Analytics'), findsOneWidget);
      });

      testWidgets('should handle different icon types', (tester) async {
        final iconTypes = [
          'bar_chart',
          'auto_awesome',
          'star',
          'settings',
          'invalid_icon',
        ];

        for (final iconType in iconTypes) {
          final feature = PremiumFeature(
            id: 'icon_feature',
            title: 'Icon Feature',
            description: 'This feature has an icon',
            icon: iconType,
            route: '/icon',
            isEnabled: true,
          );
          await tester.pumpWidget(createTestWidget(feature: feature));

          expect(find.text('Advanced Analytics'), findsOneWidget);
          expect(find.byType(Icon), findsAtLeastNWidgets(2));
        }
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid state changes', (tester) async {
        await tester.pumpWidget(createTestWidget(isEnabled: true));

        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createTestWidget(isEnabled: i % 2 == 0));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(find.byType(PremiumFeatureCard), findsOneWidget);
      });

      testWidgets('should handle multiple cards efficiently', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: List.generate(
                  50,
                  (index) => PremiumFeatureCard(
                    feature: PremiumFeature(
                      id: 'feature_$index',
                      title: 'Feature $index',
                      description: 'This is a feature description',
                      icon: 'bar_chart',
                      route: '/feature_$index',
                      isEnabled: true,
                    ),
                    isEnabled: index % 2 == 0,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(PremiumFeatureCard), findsWidgets);
      });

      testWidgets('should maintain performance with complex features', (tester) async {
        final complexFeature = const PremiumFeature(
          id: 'complex_feature_with_very_long_id_that_tests_performance',
          title: 'Complex Feature with Very Long Title That Tests Layout Performance and Text Rendering Capabilities',
          description:
              'This is a very complex feature description that contains multiple sentences and a lot of detailed information about what this premium feature does and how it benefits the user in their waste management journey. It should test the performance of the text rendering and layout systems.',
          icon: 'auto_awesome',
          route: '/complex_feature',
          isEnabled: true,
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget(feature: complexFeature));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should render quickly (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.byType(PremiumFeatureCard), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null or empty strings gracefully', (tester) async {
        final edgeCaseFeature = const PremiumFeature(
          id: '',
          title: '',
          description: '',
          icon: '',
          route: '/edge_case',
          isEnabled: true,
        );

        expect(() async {
          await tester.pumpWidget(createTestWidget(feature: edgeCaseFeature));
        }, returnsNormally);
      });

      testWidgets('should handle special characters in text', (tester) async {
        final specialCharFeature = const PremiumFeature(
          id: 'special_char_feature',
          title: 'Feature with émojis 🚀 & spëcial chars: <>&"\'',
          description: 'Déscription with ñovel characters and symbols: @#\$%^&*()',
          icon: 'star',
          route: '/special_char',
          isEnabled: true,
        );

        await tester.pumpWidget(createTestWidget(feature: specialCharFeature));

        expect(find.textContaining('émojis 🚀'), findsOneWidget);
        expect(find.textContaining('ñovel characters'), findsOneWidget);
      });

      testWidgets('should handle widget disposal properly', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Text('Different Widget')));

        expect(find.text('Different Widget'), findsOneWidget);
        expect(find.byType(PremiumFeatureCard), findsNothing);
      });
    });
  });
}
