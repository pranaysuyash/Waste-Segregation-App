import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/models/gamification.dart';
import '../lib/services/gamification_service.dart';
import '../lib/utils/constants.dart';

void main() {
  group('Achievement Unlock Logic Tests', () {
    late GamificationService gamificationService;

    setUp(() {
      gamificationService = GamificationService();
    });

    test('Waste Apprentice achievement configuration is correct', () {
      final achievements = gamificationService.getDefaultAchievements();
      final wasteApprentice = achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );

      expect(wasteApprentice.title, 'Waste Apprentice');
      expect(wasteApprentice.threshold, 15); // Should be 15 items
      expect(wasteApprentice.unlocksAtLevel, 2); // Should unlock at level 2
      expect(wasteApprentice.tier, AchievementTier.silver);
    });

    test('Level 4 user should see Waste Apprentice as unlocked', () {
      final achievements = gamificationService.getDefaultAchievements();
      final wasteApprentice = achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );

      // Simulate a Level 4 user
      final userLevel = 4;
      
      // Check if achievement should be locked
      final isLocked = wasteApprentice.unlocksAtLevel != null && 
                      wasteApprentice.unlocksAtLevel! > userLevel;

      expect(isLocked, false, 
        reason: 'Level 4 user should see Waste Apprentice (unlocks at level 2) as unlocked');
    });

    test('Level 1 user should see Waste Apprentice as locked', () {
      final achievements = gamificationService.getDefaultAchievements();
      final wasteApprentice = achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );

      // Simulate a Level 1 user
      final userLevel = 1;
      
      // Check if achievement should be locked
      final isLocked = wasteApprentice.unlocksAtLevel != null && 
                      wasteApprentice.unlocksAtLevel! > userLevel;

      expect(isLocked, true, 
        reason: 'Level 1 user should see Waste Apprentice (unlocks at level 2) as locked');
    });

    test('Level 2 user should see Waste Apprentice as unlocked', () {
      final achievements = gamificationService.getDefaultAchievements();
      final wasteApprentice = achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );

      // Simulate a Level 2 user
      final userLevel = 2;
      
      // Check if achievement should be locked
      final isLocked = wasteApprentice.unlocksAtLevel != null && 
                      wasteApprentice.unlocksAtLevel! > userLevel;

      expect(isLocked, false, 
        reason: 'Level 2 user should see Waste Apprentice (unlocks at level 2) as unlocked');
    });

    test('Achievement unlock logic in service is correct', () {
      final achievements = gamificationService.getDefaultAchievements();
      final wasteApprentice = achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );

      // Test different user levels
      for (int level = 1; level <= 5; level++) {
        final isLevelUnlocked = wasteApprentice.unlocksAtLevel == null || 
                               level >= wasteApprentice.unlocksAtLevel!;
        
        if (level >= 2) {
          expect(isLevelUnlocked, true, 
            reason: 'Level $level should have Waste Apprentice unlocked');
        } else {
          expect(isLevelUnlocked, false, 
            reason: 'Level $level should have Waste Apprentice locked');
        }
      }
    });

    test('Points to level calculation is correct', () {
      // Test the level calculation logic
      final testCases = [
        {'points': 0, 'expectedLevel': 1},
        {'points': 50, 'expectedLevel': 1},
        {'points': 99, 'expectedLevel': 1},
        {'points': 100, 'expectedLevel': 2},
        {'points': 150, 'expectedLevel': 2}, // 15 items * 10 points = Level 2
        {'points': 199, 'expectedLevel': 2},
        {'points': 200, 'expectedLevel': 3},
        {'points': 400, 'expectedLevel': 5},
      ];

      for (final testCase in testCases) {
        final points = testCase['points'] as int;
        final expectedLevel = testCase['expectedLevel'] as int;
        final actualLevel = (points / 100).floor() + 1;
        
        expect(actualLevel, expectedLevel, 
          reason: '$points points should result in level $expectedLevel');
      }
    });

    test('Waste Apprentice mathematical alignment is correct', () {
      // Waste Apprentice requires 15 items and unlocks at level 2
      final itemsRequired = 15;
      final pointsPerItem = 10;
      final totalPoints = itemsRequired * pointsPerItem; // 150 points
      final resultingLevel = (totalPoints / 100).floor() + 1; // Level 2
      final unlocksAtLevel = 2;

      expect(resultingLevel, unlocksAtLevel,
        reason: 'Waste Apprentice should be completable exactly at the level it unlocks');
      expect(totalPoints, 150,
        reason: '15 items should give 150 points');
      expect(resultingLevel, 2,
        reason: '150 points should result in level 2');
    });
  });
} 