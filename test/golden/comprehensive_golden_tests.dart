import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';

import '../../lib/models/waste_classification.dart';
import '../../lib/models/gamification.dart';
import '../../lib/widgets/enhanced_gamification_widgets.dart';
import '../../lib/widgets/result_screen/classification_card.dart';
import '../../lib/widgets/modern_ui/modern_cards.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/utils/constants.dart';

void main() {
  group('Comprehensive Golden Tests - App Components', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens('Classification Results - All Categories', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ]);

      // Wet Waste Classification
      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: _createTestClassification(
              'Apple Core',
              'Wet Waste',
              'Food Waste',
              0.95,
            ),
          ),
        ),
        name: 'wet_waste_classification',
      );

      // Dry Waste Classification
      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: _createTestClassification(
              'Plastic Bottle',
              'Dry Waste',
              'Plastic',
              0.88,
            ),
          ),
        ),
        name: 'dry_waste_classification',
      );

      // Hazardous Waste Classification
      builder.addScenario(
        widget: _buildTestWrapper(
          ClassificationCard(
            classification: _createTestClassification(
              'Battery',
              'Hazardous Waste',
              'Battery',
              0.92,
              hasUrgent: true,
            ),
          ),
        ),
        name: 'hazardous_waste_classification',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'classification_results_all_categories');
    });

    testGoldens('Gamification Components - Achievement States', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletPortrait,
        ]);

      // Unlocked Achievement
      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: _createTestAchievement(
              'First Classification',
              'Complete your first waste classification',
              AchievementType.firstClassification,
              AchievementTier.bronze,
              isUnlocked: true,
              claimStatus: ClaimStatus.unclaimed,
            ),
          ),
        ),
        name: 'unlocked_achievement',
      );

      // Claimed Achievement
      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: _createTestAchievement(
              'Eco Warrior',
              'Classify 100 waste items correctly',
              AchievementType.classificationCount,
              AchievementTier.gold,
              isUnlocked: true,
              claimStatus: ClaimStatus.claimed,
            ),
          ),
        ),
        name: 'claimed_achievement',
      );

      // Locked Achievement
      builder.addScenario(
        widget: _buildTestWrapper(
          AchievementCard(
            achievement: _createTestAchievement(
              'Master Classifier',
              'Achieve 95% accuracy over 50 classifications',
              AchievementType.accuracy,
              AchievementTier.platinum,
              isUnlocked: false,
              claimStatus: ClaimStatus.locked,
              progress: 0.7,
            ),
          ),
        ),
        name: 'locked_achievement',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'gamification_achievement_states');
    });

    testGoldens('Points and Statistics Display', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      // Low Points (Beginner)
      builder.addScenario(
        widget: _buildTestWrapper(
          PointsDisplay(
            points: 50,
            showAnimation: false,
          ),
        ),
        name: 'beginner_points',
      );

      // Medium Points (Intermediate)
      builder.addScenario(
        widget: _buildTestWrapper(
          PointsDisplay(
            points: 1250,
            showAnimation: false,
          ),
        ),
        name: 'intermediate_points',
      );

      // High Points (Expert)
      builder.addScenario(
        widget: _buildTestWrapper(
          PointsDisplay(
            points: 15750,
            showAnimation: false,
          ),
        ),
        name: 'expert_points',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'points_statistics_display');
    });

    testGoldens('Modern UI Cards - Data Visualization', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletPortrait,
        ]);

      // Statistics Card
      builder.addScenario(
        widget: _buildTestWrapper(
          StatsCard(
            title: 'Total Classifications',
            value: '234',
            subtitle: 'This month',
            trend: Trend.up,
            trendValue: '+12%',
            icon: Icons.analytics,
          ),
        ),
        name: 'stats_card_up_trend',
      );

      // Downward Trend
      builder.addScenario(
        widget: _buildTestWrapper(
          StatsCard(
            title: 'Error Rate',
            value: '3.2%',
            subtitle: 'Last 30 days',
            trend: Trend.down,
            trendValue: '-0.8%',
            icon: Icons.error_outline,
          ),
        ),
        name: 'stats_card_down_trend',
      );

      // Neutral Trend
      builder.addScenario(
        widget: _buildTestWrapper(
          StatsCard(
            title: 'Weekly Goal',
            value: '85%',
            subtitle: 'Progress',
            trend: Trend.neutral,
            trendValue: '±0%',
            icon: Icons.track_changes,
          ),
        ),
        name: 'stats_card_neutral_trend',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'modern_ui_cards_visualization');
    });

    testGoldens('App Themes - Light and Dark Mode', (tester) async {
      final lightTheme = ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.seedColor),
      );
      final darkTheme = ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.seedColor,
          brightness: Brightness.dark,
        ),
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      // Light Theme
      builder.addScenario(
        widget: MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Waste Classification'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ClassificationCard(
                    classification: _createTestClassification(
                      'Plastic Bottle',
                      'Dry Waste',
                      'Plastic',
                      0.92,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PointsDisplay(
                    points: 1520,
                    showAnimation: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'light_theme_app',
      );

      // Dark Theme
      builder.addScenario(
        widget: MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Waste Classification'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ClassificationCard(
                    classification: _createTestClassification(
                      'Plastic Bottle',
                      'Dry Waste',
                      'Plastic',
                      0.92,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PointsDisplay(
                    points: 1520,
                    showAnimation: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        name: 'dark_theme_app',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'app_themes_light_dark');
    });

    testGoldens('Accessibility - Text Scale Variations', (tester) async {
      final textScales = [0.8, 1.0, 1.3, 1.6];

      for (final scale in textScales) {
        await testGoldens('Text Scale $scale', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData().copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClassificationCard(
                            classification: _createTestClassification(
                              'Orange Peel',
                              'Wet Waste',
                              'Food Waste',
                              0.88,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AchievementCard(
                            achievement: _createTestAchievement(
                              'Text Scale Achievement',
                              'Testing accessibility with different text scales',
                              AchievementType.firstClassification,
                              AchievementTier.bronze,
                              isUnlocked: true,
                              claimStatus: ClaimStatus.unclaimed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await screenMatchesGolden(
            tester,
            'accessibility_text_scale_${scale.toString().replaceAll('.', '_')}',
          );
        });
      }
    });
  });
}

Widget _buildTestWrapper(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.seedColor),
    ),
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

WasteClassification _createTestClassification(
  String itemName,
  String category,
  String subcategory,
  double confidence, {
  bool hasUrgent = false,
}) {
  return WasteClassification(
    itemName: itemName,
    category: category,
    subcategory: subcategory,
    explanation: 'This is a test $itemName for golden test purposes.',
    disposalInstructions: DisposalInstructions(
      primaryMethod: hasUrgent ? 'Immediate Special Handling' : 'Standard Disposal',
      steps: hasUrgent
          ? ['Handle with care', 'Take to hazardous waste facility immediately']
          : ['Clean if necessary', 'Place in appropriate bin'],
      hasUrgentTimeframe: hasUrgent,
      warnings: hasUrgent ? ['Contains hazardous materials'] : null,
    ),
    region: 'Test Region',
    visualFeatures: [subcategory.toLowerCase(), itemName.toLowerCase()],
    alternatives: [],
    confidence: confidence,
    timestamp: DateTime(2024, 6, 24, 12, 0),
    imageUrl: 'test_image.jpg',
  );
}

Achievement _createTestAchievement(
  String title,
  String description,
  AchievementType type,
  AchievementTier tier, {
  required bool isUnlocked,
  required ClaimStatus claimStatus,
  double progress = 1.0,
}) {
  return Achievement(
    id: 'test_${title.toLowerCase().replaceAll(' ', '_')}',
    type: type,
    tier: tier,
    title: title,
    description: description,
    iconPath: 'assets/icons/achievement_test.png',
    pointsReward: tier == AchievementTier.bronze
        ? 50
        : tier == AchievementTier.gold
            ? 200
            : 500,
    isUnlocked: isUnlocked,
    claimStatus: claimStatus,
    progress: progress,
    targetValue: 100,
    currentValue: (progress * 100).round(),
    unlockedAt: isUnlocked ? DateTime(2024, 6, 24, 10, 0) : null,
    claimedAt: claimStatus == ClaimStatus.claimed ? DateTime(2024, 6, 24, 11, 0) : null,
  );
}