import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/action_points.dart';

void main() {
  group('PointableAction', () {
    test('should have correct default points', () {
      expect(PointableAction.classification.defaultPoints, equals(10));
      expect(PointableAction.dailyStreak.defaultPoints, equals(5));
      expect(PointableAction.challengeComplete.defaultPoints, equals(25));
      expect(PointableAction.badgeEarned.defaultPoints, equals(20));
      expect(PointableAction.quizCompleted.defaultPoints, equals(15));
      expect(PointableAction.educationalContent.defaultPoints, equals(5));
      expect(PointableAction.perfectWeek.defaultPoints, equals(50));
      expect(PointableAction.communityChallenge.defaultPoints, equals(30));
    });

    test('should find actions by key', () {
      final action = PointableAction.fromKey('classification');
      expect(action, equals(PointableAction.classification));

      final streakAction = PointableAction.fromKey('daily_streak');
      expect(streakAction, equals(PointableAction.dailyStreak));

      final invalidAction = PointableAction.fromKey('invalid_action');
      expect(invalidAction, isNull);
    });

    test('should validate action keys', () {
      expect(PointableAction.isValidAction('classification'), isTrue);
      expect(PointableAction.isValidAction('daily_streak'), isTrue);
      expect(PointableAction.isValidAction('challenge_complete'), isTrue);
      expect(PointableAction.isValidAction('invalid_action'), isFalse);
      expect(PointableAction.isValidAction(''), isFalse);
    });

    test('should categorize actions correctly', () {
      expect(PointableAction.classification.category, equals('classification'));
      expect(PointableAction.instantAnalysis.category, equals('classification'));
      expect(PointableAction.manualClassification.category, equals('classification'));
      
      expect(PointableAction.dailyStreak.category, equals('streak'));
      expect(PointableAction.streakBonus.category, equals('streak'));
      
      expect(PointableAction.challengeComplete.category, equals('challenge'));
      expect(PointableAction.perfectWeek.category, equals('challenge'));
      expect(PointableAction.communityChallenge.category, equals('challenge'));
      
      expect(PointableAction.badgeEarned.category, equals('achievement'));
      expect(PointableAction.achievementClaim.category, equals('achievement'));
      
      expect(PointableAction.quizCompleted.category, equals('education'));
      expect(PointableAction.educationalContent.category, equals('education'));
      
      expect(PointableAction.migrationSync.category, equals('system'));
      expect(PointableAction.retroactiveSync.category, equals('system'));
    });

    test('should identify custom points support correctly', () {
      // Actions that support custom points
      expect(PointableAction.achievementClaim.supportsCustomPoints, isTrue);
      expect(PointableAction.streakBonus.supportsCustomPoints, isTrue);
      expect(PointableAction.migrationSync.supportsCustomPoints, isTrue);
      expect(PointableAction.retroactiveSync.supportsCustomPoints, isTrue);
      
      // Actions that don't support custom points
      expect(PointableAction.classification.supportsCustomPoints, isFalse);
      expect(PointableAction.dailyStreak.supportsCustomPoints, isFalse);
      expect(PointableAction.challengeComplete.supportsCustomPoints, isFalse);
      expect(PointableAction.badgeEarned.supportsCustomPoints, isFalse);
      expect(PointableAction.quizCompleted.supportsCustomPoints, isFalse);
    });

    test('should return correct string representation', () {
      expect(PointableAction.classification.toString(), equals('classification'));
      expect(PointableAction.dailyStreak.toString(), equals('daily_streak'));
      expect(PointableAction.challengeComplete.toString(), equals('challenge_complete'));
    });

    test('should have all required action keys', () {
      final allKeys = PointableAction.allKeys;
      
      expect(allKeys, contains('classification'));
      expect(allKeys, contains('daily_streak'));
      expect(allKeys, contains('challenge_complete'));
      expect(allKeys, contains('badge_earned'));
      expect(allKeys, contains('achievement_claim'));
      expect(allKeys, contains('quiz_completed'));
      expect(allKeys, contains('educational_content'));
      expect(allKeys, contains('perfect_week'));
      expect(allKeys, contains('community_challenge'));
      expect(allKeys, contains('streak_bonus'));
      expect(allKeys, contains('migration_sync'));
      expect(allKeys, contains('retroactive_sync'));
      expect(allKeys, contains('instant_analysis'));
      expect(allKeys, contains('manual_classification'));
      
      // Should have exactly the expected number of actions
      expect(allKeys.length, equals(PointableAction.values.length));
    });

    test('should maintain consistency between key and enum values', () {
      for (final action in PointableAction.values) {
        // Each action should be findable by its key
        final foundAction = PointableAction.fromKey(action.key);
        expect(foundAction, equals(action));
        
        // Key should be valid
        expect(PointableAction.isValidAction(action.key), isTrue);
        
        // String representation should match key
        expect(action.toString(), equals(action.key));
      }
    });
  });

  group('PointableAction Integration', () {
    test('should handle edge cases gracefully', () {
      // Null and empty string handling
      expect(PointableAction.fromKey(''), isNull);
      expect(PointableAction.isValidAction(''), isFalse);
      
      // Case sensitivity
      expect(PointableAction.fromKey('CLASSIFICATION'), isNull);
      expect(PointableAction.isValidAction('CLASSIFICATION'), isFalse);
      
      // Whitespace handling
      expect(PointableAction.fromKey(' classification '), isNull);
      expect(PointableAction.isValidAction(' classification '), isFalse);
    });

    test('should provide consistent point values', () {
      // Classification actions should have same points
      expect(PointableAction.classification.defaultPoints, 
             equals(PointableAction.instantAnalysis.defaultPoints));
      expect(PointableAction.classification.defaultPoints, 
             equals(PointableAction.manualClassification.defaultPoints));
      
      // Custom point actions should have 0 default points
      expect(PointableAction.achievementClaim.defaultPoints, equals(0));
      expect(PointableAction.streakBonus.defaultPoints, equals(0));
      expect(PointableAction.migrationSync.defaultPoints, equals(0));
      expect(PointableAction.retroactiveSync.defaultPoints, equals(0));
    });
  });
} 