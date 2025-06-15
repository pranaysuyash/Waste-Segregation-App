import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';

import '../../lib/widgets/classification_card.dart';
import '../../lib/widgets/points_display_widget.dart';
import '../../lib/widgets/achievement_card.dart';
import '../../lib/models/classification.dart';
import '../../lib/models/achievement.dart';
import '../../lib/services/storage_service.dart';
import '../test_helper.dart';

void main() {
  group('Golden Tests - Visual Regression', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens('Classification Card - All States', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ]);

      // Test different classification states
      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: Classification(
              id: 'test-1',
              imagePath: 'test_image.jpg',
              wasteType: 'Plastic',
              confidence: 0.95,
              timestamp: DateTime(2024, 1, 15),
              pointsEarned: 10,
              isCorrect: true,
            ),
            onTap: () {},
          ),
        ),
        name: 'correct_classification',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: Classification(
              id: 'test-2',
              imagePath: 'test_image.jpg',
              wasteType: 'Organic',
              confidence: 0.75,
              timestamp: DateTime(2024, 1, 15),
              pointsEarned: 5,
              isCorrect: false,
            ),
            onTap: () {},
          ),
        ),
        name: 'incorrect_classification',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: Classification(
              id: 'test-3',
              imagePath: 'test_image.jpg',
              wasteType: 'Hazardous',
              confidence: 0.60,
              timestamp: DateTime(2024, 1, 15),
              pointsEarned: 15,
              isCorrect: true,
            ),
            onTap: () {},
          ),
        ),
        name: 'low_confidence_classification',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'classification_card_states');
    });

    testGoldens('Points Display Widget - Various Values', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      builder.addScenario(
        widget: _buildTestWrapper(
          const PointsDisplayWidget(
            points: 0,
            showAnimation: false,
          ),
        ),
        name: 'zero_points',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          const PointsDisplayWidget(
            points: 150,
            showAnimation: false,
          ),
        ),
        name: 'medium_points',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          const PointsDisplayWidget(
            points: 9999,
            showAnimation: false,
          ),
        ),
        name: 'high_points',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'points_display_states');
    });

    testGoldens('Achievement Card - Different States', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletPortrait,
        ]);

      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: Achievement(
              id: 'first_classification',
              title: 'First Classification',
              description: 'Complete your first waste classification',
              iconPath: 'assets/icons/first_classification.png',
              pointsReward: 50,
              isUnlocked: true,
              isClaimed: false,
              unlockedAt: DateTime(2024, 1, 15),
            ),
            onClaim: () {},
          ),
        ),
        name: 'unlocked_unclaimed',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: Achievement(
              id: 'eco_warrior',
              title: 'Eco Warrior',
              description: 'Classify 100 waste items correctly',
              iconPath: 'assets/icons/eco_warrior.png',
              pointsReward: 500,
              isUnlocked: true,
              isClaimed: true,
              unlockedAt: DateTime(2024, 1, 10),
              claimedAt: DateTime(2024, 1, 15),
            ),
            onClaim: () {},
          ),
        ),
        name: 'unlocked_claimed',
      );

      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: Achievement(
              id: 'master_classifier',
              title: 'Master Classifier',
              description: 'Achieve 95% accuracy over 50 classifications',
              iconPath: 'assets/icons/master_classifier.png',
              pointsReward: 1000,
              isUnlocked: false,
              isClaimed: false,
            ),
            onClaim: () {},
          ),
        ),
        name: 'locked',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'achievement_card_states');
    });

    testGoldens('Theme Variations - Light and Dark', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      // Light theme
      builder.addScenario(
        widget: MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PointsDisplayWidget(
                    points: 250,
                    showAnimation: false,
                  ),
                  const SizedBox(height: 20),
                  ClassificationCard(
                    classification: Classification(
                      id: 'theme-test',
                      imagePath: 'test_image.jpg',
                      wasteType: 'Plastic',
                      confidence: 0.90,
                      timestamp: DateTime(2024, 1, 15),
                      pointsEarned: 10,
                      isCorrect: true,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'light_theme',
      );

      // Dark theme
      builder.addScenario(
        widget: MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PointsDisplayWidget(
                    points: 250,
                    showAnimation: false,
                  ),
                  const SizedBox(height: 20),
                  ClassificationCard(
                    classification: Classification(
                      id: 'theme-test',
                      imagePath: 'test_image.jpg',
                      wasteType: 'Plastic',
                      confidence: 0.90,
                      timestamp: DateTime(2024, 1, 15),
                      pointsEarned: 10,
                      isCorrect: true,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'dark_theme',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'theme_variations');
    });

    testGoldens('Text Scale Variations', (tester) async {
      final textScales = [0.8, 1.0, 1.3, 1.6, 2.0];
      
      for (final scale in textScales) {
        await testGoldens('Text Scale $scale', (tester) async {
          await mockNetworkImagesFor(() async {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData().copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PointsDisplayWidget(
                            points: 150,
                            showAnimation: false,
                          ),
                          const SizedBox(height: 20),
                          AchievementCard(
                            achievement: Achievement(
                              id: 'text_scale_test',
                              title: 'Text Scale Test Achievement',
                              description: 'This is a test achievement for text scaling',
                              iconPath: 'assets/icons/test.png',
                              pointsReward: 100,
                              isUnlocked: true,
                              isClaimed: false,
                              unlockedAt: DateTime(2024, 1, 15),
                            ),
                            onClaim: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await screenMatchesGolden(tester, 'text_scale_${scale.toString().replaceAll('.', '_')}');
          });
        });
      }
    });
  });
}

Widget _buildTestWrapper(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    ),
  );
} 