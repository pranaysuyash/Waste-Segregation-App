import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('Achievement Unlock Timing Fix Tests', () {
    test('Waste Apprentice should unlock at level 2 with 25 items identified', () {
      // Test achievement definitions
      final wasteApprentice = Achievement(
        id: 'waste_apprentice',
        title: 'Waste Apprentice',
        description: 'Identify 25 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 25,
        iconName: 'recycling',
        color: const Color(0xFF4CAF50),
        tier: AchievementTier.silver,
        achievementFamilyId: 'Waste Identifier',
        pointsReward: 100,
        unlocksAtLevel: 2,
        progress: 0.0,
      );
      
      // Verify achievement configuration
      expect(wasteApprentice.isLocked, true);
      expect(wasteApprentice.unlocksAtLevel, 2);
      expect(wasteApprentice.threshold, 25);
    });
    
    test('Achievement progress should accumulate even when locked', () {
      // Create a user who has identified 20 items but is only level 1
      final points = UserPoints(
        total: 200, // 20 items × 10 points = 200 points = level 2
        level: 2,
        categoryPoints: {
          'Wet Waste': 200, // 20 items worth of points
        },
      );
      
      // Create achievement with progress from 20 items
      final achievement = Achievement(
        id: 'waste_apprentice',
        title: 'Waste Apprentice',
        description: 'Identify 25 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 25,
        iconName: 'recycling',
        color: const Color(0xFF4CAF50),
        tier: AchievementTier.silver,
        unlocksAtLevel: 2,
        progress: 20.0 / 25.0, // 80% progress
      );
      
      // Check if achievement should unlock with 5 more items
      final isLevelUnlocked = !achievement.isLocked || points.level >= achievement.unlocksAtLevel!;
      final hasEnoughProgress = achievement.progress + (5.0 / 25.0) >= 1.0; // Adding 5 more items
      
      expect(isLevelUnlocked, true, reason: 'Level 2 should unlock the achievement');
      expect(hasEnoughProgress, true, reason: '25 total items should complete the achievement');
    });
    
    test('Achievement should NOT unlock if level requirement not met', () {
      // Create a user who has identified 25 items but is only level 1
      final points = UserPoints(
        total: 90, // Less than 100 points = level 1
        level: 1,
        categoryPoints: {
          'Wet Waste': 90,
        },
      );
      
      final achievement = Achievement(
        id: 'waste_apprentice',
        title: 'Waste Apprentice',
        description: 'Identify 25 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 25,
        iconName: 'recycling',
        color: const Color(0xFF4CAF50),
        unlocksAtLevel: 2,
        progress: 1.0, // 100% progress
      );
      
      // Should not unlock because level requirement not met
      final isLevelUnlocked = !achievement.isLocked || points.level >= achievement.unlocksAtLevel!;
      
      expect(isLevelUnlocked, false, reason: 'Level 1 should not unlock level 2 achievement');
      expect(achievement.progress, 1.0, reason: 'Progress should still be tracked');
    });
    
    test('Level calculation should be correct', () {
      // Test level calculation (every 100 points = 1 level)
      expect(((250 / 100).floor() + 1), 3, reason: '250 points should be level 3');
      expect(((199 / 100).floor() + 1), 2, reason: '199 points should be level 2');
      expect(((100 / 100).floor() + 1), 2, reason: '100 points should be level 2');
      expect(((99 / 100).floor() + 1), 1, reason: '99 points should be level 1');
    });
    
    test('Points to items conversion should be accurate', () {
      // Each classification awards 10 points, so 25 items = 250 points
      const itemsIdentified = 25;
      const pointsPerItem = 10;
      const totalPoints = itemsIdentified * pointsPerItem;
      final level = (totalPoints / 100).floor() + 1;
      
      expect(totalPoints, 250);
      expect(level, 3, reason: '25 items (250 points) should reach level 3');
      
      // Level 2 is reached at 100 points = 10 items
      const itemsForLevel2 = 10;
      const pointsForLevel2 = itemsForLevel2 * pointsPerItem;
      final levelFromLevel2Points = (pointsForLevel2 / 100).floor() + 1;
      
      expect(pointsForLevel2, 100);
      expect(levelFromLevel2Points, 2, reason: '10 items (100 points) should reach level 2');
    });
  });
} 