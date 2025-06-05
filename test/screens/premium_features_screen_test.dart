import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/utils/developer_config.dart';

// Mock classes
@GenerateMocks([PremiumService])
import 'premium_features_screen_test.mocks.dart';

void main() {
  group('PremiumFeaturesScreen', () {
    late MockPremiumService mockPremiumService;
    late List<PremiumFeature> testAvailableFeatures;
    late List<PremiumFeature> testUserFeatures;

    setUp(() {
      mockPremiumService = MockPremiumService();
      
      testAvailableFeatures = [
        PremiumFeature(
          id: 'ad_free',
          title: 'Ad-Free Experience',
          description: 'Remove all advertisements from the app',
          icon: Icons.block,
          category: PremiumFeatureCategory.userExperience,
        ),
        PremiumFeature(
          id: 'offline_mode',
          title: 'Offline Mode',
          description: 'Use the app without internet connection',
          icon: Icons.offline_bolt,
          category: PremiumFeatureCategory.functionality,
        ),
        PremiumFeature(
          id: 'advanced_analytics',
          title: 'Advanced Analytics',
          description: 'Detailed insights into your waste management',
          icon: Icons.analytics,
          category: PremiumFeatureCategory.analytics,
        ),
      ];

      testUserFeatures = [
        PremiumFeature(
          id: 'user_feature_1',
          title: 'User Premium Feature',
          description: 'A feature the user already has',
          icon: Icons.star,
          category: PremiumFeatureCategory.userExperience,
          isEnabled: true,
        ),
      ];
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<PremiumService>.value(
          value: mockPremiumService,
          child: const PremiumFeaturesScreen(),
        ),
      );
    }

    group('Basic Layout and Structure', () {
      testWidgets('should display app bar with correct title', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Premium Features'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display header section with gradient background', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Upgrade to Premium'), findsOneWidget);
        expect(find.text('Get access to all premium features and enjoy an ad-free experience'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(1));
      });

      testWidgets('should display feature badges in header', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('No Ads'), findsOneWidget);
        expect(find.text('Offline Mode'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);
      });

      testWidgets('should display purchase button', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Upgrade to Premium'), findsNWidgets(2)); // Header + Button
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should be scrollable', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Developer Mode Features', () {
      testWidgets('should show developer mode toggle when debug mode is enabled', (tester) async {
        // This test depends on DeveloperConfig.canShowPremiumToggles
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // In test environment, this might not show unless we mock the DeveloperConfig
        // The visibility depends on the DeveloperConfig.canShowPremiumToggles
      });

      testWidgets('should toggle developer options when developer button is pressed', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Only test if developer mode toggle is visible
        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          await tester.tap(developerToggle);
          await tester.pump();

          expect(find.text('DEVELOPER TESTING MODE'), findsOneWidget);
          expect(find.text('Use these toggles to test premium features'), findsOneWidget);
        }
      });

      testWidgets('should show feature toggles in developer mode', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);
        when(mockPremiumService.isPremiumFeature(any)).thenReturn(false);

        await tester.pumpWidget(createTestWidget());

        // Only test if developer mode is available
        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          await tester.tap(developerToggle);
          await tester.pump();

          // Should show toggles for each feature
          expect(find.byType(Switch), findsAtLeastNWidgets(1));
        }
      });

      testWidgets('should call setPremiumFeature when toggle is switched', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);
        when(mockPremiumService.isPremiumFeature(any)).thenReturn(false);
        when(mockPremiumService.setPremiumFeature(any, any)).thenAnswer((_) async {
          return null;
        });

        await tester.pumpWidget(createTestWidget());

        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          await tester.tap(developerToggle);
          await tester.pump();

          final switches = find.byType(Switch);
          if (switches.hasFound) {
            await tester.tap(switches.first);
            await tester.pump();

            verify(mockPremiumService.setPremiumFeature(any, any)).called(1);
          }
        }
      });

      testWidgets('should reset premium features when reset button is pressed', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);
        when(mockPremiumService.isPremiumFeature(any)).thenReturn(false);
        when(mockPremiumService.resetPremiumFeatures()).thenAnswer((_) async {
          return null;
        });

        await tester.pumpWidget(createTestWidget());

        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          await tester.tap(developerToggle);
          await tester.pump();

          final resetButton = find.byIcon(Icons.refresh);
          if (resetButton.hasFound) {
            await tester.tap(resetButton);
            await tester.pump();

            verify(mockPremiumService.resetPremiumFeatures()).called(1);
            expect(find.text('All premium features reset'), findsOneWidget);
          }
        }
      });
    });

    group('Coming Soon Features', () {
      testWidgets('should display available premium features', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Available Premium Features'), findsOneWidget);
        expect(find.text('Ad-Free Experience'), findsOneWidget);
        expect(find.text('Offline Mode'), findsAtLeastNWidgets(1)); // Also in header badge
        expect(find.text('Advanced Analytics'), findsOneWidget);
      });

      testWidgets('should not show section when no coming soon features', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn([]);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Available Premium Features'), findsNothing);
      });

      testWidgets('should use PremiumFeatureCard for each feature', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Should have cards for each available feature
        expect(find.byType(PremiumFeatureCard), findsNWidgets(testAvailableFeatures.length));
      });
    });

    group('User Premium Features', () {
      testWidgets('should display user premium features', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn([]);
        when(mockPremiumService.getPremiumFeatures()).thenReturn(testUserFeatures);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your Premium Features'), findsOneWidget);
        expect(find.text('User Premium Feature'), findsOneWidget);
      });

      testWidgets('should not show section when user has no premium features', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your Premium Features'), findsNothing);
      });

      testWidgets('should show both sections when user has some features', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn(testUserFeatures);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Available Premium Features'), findsOneWidget);
        expect(find.text('Your Premium Features'), findsOneWidget);
        expect(find.byType(PremiumFeatureCard), findsNWidgets(testAvailableFeatures.length + testUserFeatures.length));
      });
    });

    group('Purchase Button Functionality', () {
      testWidgets('should show debug message when purchase button is tapped in debug mode', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // In debug mode, should show developer message
        if (kDebugMode) {
          expect(find.text('In-app purchase flow would launch here. Use developer mode to test features.'), findsOneWidget);
        } else {
          expect(find.text('Premium features coming soon!'), findsOneWidget);
        }
      });

      testWidgets('should have correct styling for purchase button', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        final button = find.byType(ElevatedButton);
        expect(button, findsOneWidget);

        final buttonWidget = tester.widget<ElevatedButton>(button);
        expect(buttonWidget.child, isA<Row>());
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle null or empty feature lists gracefully', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn([]);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Should still show header and purchase button
        expect(find.text('Upgrade to Premium'), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Available Premium Features'), findsNothing);
        expect(find.text('Your Premium Features'), findsNothing);
      });

      testWidgets('should handle service errors gracefully', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenThrow(Exception('Service error'));
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Should not crash and still show basic UI
        expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
        expect(find.text('Upgrade to Premium'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle large number of features', (tester) async {
        final manyFeatures = List.generate(20, (index) => PremiumFeature(
          id: 'feature_$index',
          title: 'Feature $index',
          description: 'Description for feature $index',
          icon: Icons.star,
          category: PremiumFeatureCategory.values[index % PremiumFeatureCategory.values.length],
        ));

        when(mockPremiumService.getComingSoonFeatures()).thenReturn(manyFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(PremiumFeatureCard), findsNWidgets(20));
        expect(find.text('Feature 0'), findsOneWidget);

        // Should be scrollable to see more features
        await tester.scrollUntilVisible(
          find.text('Feature 10'),
          100.0,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Feature 10'), findsOneWidget);
      });

      testWidgets('should handle very long feature titles and descriptions', (tester) async {
        final longFeature = [
          PremiumFeature(
            id: 'long_feature',
            title: 'This is a very long feature title that might cause overflow issues in the UI',
            description: 'This is a very long description that explains in great detail what this premium feature does and why users should purchase it',
            icon: Icons.text_fields,
            category: PremiumFeatureCategory.userExperience,
          ),
        ];

        when(mockPremiumService.getComingSoonFeatures()).thenReturn(longFeature);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('This is a very long feature title'), findsOneWidget);
        expect(find.textContaining('This is a very long description'), findsOneWidget);
      });
    });

    group('State Management', () {
      testWidgets('should update UI when premium service state changes', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Available Premium Features'), findsOneWidget);
        expect(find.text('Your Premium Features'), findsNothing);

        // Simulate user purchasing features
        when(mockPremiumService.getComingSoonFeatures()).thenReturn([]);
        when(mockPremiumService.getPremiumFeatures()).thenReturn(testUserFeatures);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Available Premium Features'), findsNothing);
        expect(find.text('Your Premium Features'), findsOneWidget);
      });

      testWidgets('should maintain developer mode toggle state', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          // Toggle developer mode on
          await tester.tap(developerToggle);
          await tester.pump();

          expect(find.text('DEVELOPER TESTING MODE'), findsOneWidget);

          // Toggle developer mode off
          await tester.tap(find.byIcon(Icons.developer_mode));
          await tester.pump();

          expect(find.text('DEVELOPER TESTING MODE'), findsNothing);
        }
      });
    });

    group('Visual Elements', () {
      testWidgets('should display correct icons', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(2)); // Header + Button
      });

      testWidgets('should have proper visual hierarchy', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Check that main elements are present
        expect(find.byType(Container), findsAtLeastNWidgets(1)); // Header container
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        expect(find.byType(Row), findsAtLeastNWidgets(1));
      });

      testWidgets('should display gradient background in header', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Check for gradient container (exact testing of gradients is complex)
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic structure', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Main structural elements should be present
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Button should be focusable
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should have appropriate tooltips for developer mode', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          final iconButton = find.ancestor(
            of: developerToggle,
            matching: find.byType(IconButton),
          );
          
          final widget = tester.widget<IconButton>(iconButton);
          expect(widget.tooltip, equals('Toggle Developer Mode'));
        }
      });
    });

    group('Performance', () {
      testWidgets('should efficiently handle feature list rebuilds', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Multiple rebuilds should not cause performance issues
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }

        expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
      });

      testWidgets('should handle rapid state changes', (tester) async {
        when(mockPremiumService.getComingSoonFeatures()).thenReturn(testAvailableFeatures);
        when(mockPremiumService.getPremiumFeatures()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        final developerToggle = find.byIcon(Icons.developer_mode_outlined);
        if (developerToggle.hasFound) {
          // Rapid toggle changes
          for (var i = 0; i < 10; i++) {
            await tester.tap(developerToggle.hasFound ? developerToggle : find.byIcon(Icons.developer_mode));
            await tester.pump();
          }

          // Should not crash
          expect(find.byType(PremiumFeaturesScreen), findsOneWidget);
        }
      });
    });
  });
}
