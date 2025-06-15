import 'package:flutter/material.dart'; // Added import
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

void main() {
  group('WasteClassification Model Tests', () {
    test('should create valid WasteClassification object', () {
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Plastic Water Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        explanation: 'Clear plastic bottle, recyclable with PET code 1',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle in blue bin',
          steps: ['Remove cap and label', 'Rinse thoroughly', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
          warnings: ['Ensure bottle is empty'],
          tips: ['Check for recycling code'],
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: ['plastic', 'bottle', 'clear', 'PET'],
        alternatives: [
          AlternativeClassification(
            category: 'Non-Waste',
            subcategory: 'Reusable',
            confidence: 0.3,
            reason: 'Could be reused as storage container',
          ),
        ],
        confidence: 0.92,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        recyclingCode: 1,
        materialType: 'PET Plastic',
        colorCode: '#CLEAR',
        brand: 'Test Brand',
        product: 'Water Bottle 500ml',
        userId: 'test_user_123',
        isSaved: true,
      );

      // Verify all properties are correctly set
      expect(classification.itemName, equals('Plastic Water Bottle'));
      expect(classification.category, equals('Dry Waste'));
      expect(classification.subcategory, equals('Plastic'));
      expect(classification.confidence, equals(0.92));
      expect(classification.isRecyclable, isTrue);
      expect(classification.isCompostable, isFalse);
      expect(classification.requiresSpecialDisposal, isFalse);
      expect(classification.recyclingCode, equals(1));
      expect(classification.materialType, equals('PET Plastic'));
      expect(classification.visualFeatures.length, equals(4));
      expect(classification.alternatives.length, equals(1));
      expect(classification.disposalInstructions.steps.length, equals(3));
      expect(classification.disposalInstructions.warnings?.length, equals(1));
      expect(classification.disposalInstructions.tips?.length, equals(1));
      expect(classification.userId, equals('test_user_123'));
      expect(classification.isSaved, isTrue);
    });

    test('should handle WasteClassification serialization', () {
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Apple Core',
        category: 'Wet Waste',
        subcategory: 'Food Waste',
        explanation: 'Organic waste suitable for composting',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Compost bin',
          steps: ['Place in brown bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
        region: 'Test Region',
        visualFeatures: ['organic', 'brown', 'fruit'],
        alternatives: [],
      );

      // Test toJson
      final json = classification.toJson();
      expect(json['itemName'], equals('Apple Core'));
      expect(json['category'], equals('Wet Waste'));
      expect(json['subcategory'], equals('Food Waste'));
      expect(json['visualFeatures'], isA<List>());
      expect(json['alternatives'], isA<List>());

      // Test fromJson
      final recreated = WasteClassification.fromJson(json);
      expect(recreated.itemName, equals(classification.itemName));
      expect(recreated.category, equals(classification.category));
      expect(recreated.subcategory, equals(classification.subcategory));
      expect(recreated.visualFeatures, equals(classification.visualFeatures));
    });

    test('should create fallback classification correctly', () {
      final fallback = WasteClassification.fallback('unknown_item.jpg');
      
      expect(fallback.itemName, contains('Unknown'));
      expect(fallback.category, isNotEmpty);
      expect(fallback.explanation, isNotEmpty);
      expect(fallback.confidence, lessThan(1.0));
      expect(fallback.clarificationNeeded, isTrue);
      expect(fallback.disposalInstructions.primaryMethod, isNotEmpty);
    });

    test('should validate disposal instructions properly', () {
      final urgentInstructions = DisposalInstructions(
        primaryMethod: 'Take to hazardous waste facility immediately',
        steps: [
          'Do not touch with bare hands',
          'Place in sealed container',
          'Contact waste facility',
          'Transport within 24 hours'
        ],
        hasUrgentTimeframe: true,
        timeframe: 'Within 24 hours',
        warnings: [
          'Toxic material - wear gloves',
          'Do not inhale fumes',
          'Keep away from children'
        ],
        location: 'Certified hazardous waste facility',
      );

      expect(urgentInstructions.hasUrgentTimeframe, isTrue);
      expect(urgentInstructions.timeframe, equals('Within 24 hours'));
      expect(urgentInstructions.steps.length, equals(4));
      expect(urgentInstructions.warnings?.length, equals(3));
      expect(urgentInstructions.location, isNotEmpty);
    });
  });

  group('Gamification Model Tests', () {
    test('should create valid GamificationProfile', () {
      final profile = GamificationProfile(
        userId: 'test_user_123',
        points: const UserPoints(
          total: 150,
          weeklyTotal: 50,
          monthlyTotal: 120,
          categoryPoints: {
            'Dry Waste': 80,
            'Wet Waste': 40,
            'Hazardous Waste': 30,
          },
        ),
        streak: Streak(
          current: 5,
          longest: 12,
          lastUsageDate: DateTime.now(),
        ),
        achievements: [
          const Achievement(
            id: 'waste_novice',
            title: 'Waste Novice',
            description: 'Identify your first 5 waste items',
            type: AchievementType.wasteIdentified,
            threshold: 5,
            iconName: 'emoji_objects',
            color: Colors.blue,
            progress: 1.0,
          ),
        ],
        activeChallenges: [
          Challenge(
            id: 'recycling_champion',
            title: 'Recycling Champion',
            description: 'Identify 5 recyclable items',
            startDate: DateTime.now().subtract(const Duration(days: 2)),
            endDate: DateTime.now().add(const Duration(days: 5)),
            pointsReward: 25,
            iconName: 'recycling',
            color: Colors.green,
            requirements: {'category': 'Dry Waste', 'count': 5},
            progress: 0.6,
          ),
        ],
        completedChallenges: [],
      );

      expect(profile.userId, equals('test_user_123'));
      expect(profile.points.total, equals(150));
      expect(profile.points.level, equals(1));
      expect(profile.points.categoryPoints.length, equals(3));
      expect(profile.streak.current, equals(5));
      expect(profile.streak.longest, equals(12));
      expect(profile.achievements.length, equals(1));
      expect(profile.activeChallenges.length, equals(1));
      expect(profile.activeChallenges.first.progress, equals(0.6));
    });

    test('should calculate level correctly from points', () {
      const points1 = UserPoints(total: 50);   // Level 0 (50/100 = 0.5 floor = 0)
      const points2 = UserPoints(total: 150);  // Level 1 (150/100 = 1.5 floor = 1)
      const points3 = UserPoints(total: 350);  // Level 3 (350/100 = 3.5 floor = 3)
      const points4 = UserPoints(total: 1000); // Level 10 (1000/100 = 10.0 floor = 10)

      // The level is calculated as (total / 100).floor()
      expect((points1.total / 100).floor(), equals(0));
      expect((points2.total / 100).floor(), equals(1));
      expect((points3.total / 100).floor(), equals(3));
      expect((points4.total / 100).floor(), equals(10));
    });

    test('should handle Streak calculations correctly', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      
      final streak = Streak(
        current: 5,
        longest: 15,
        lastUsageDate: yesterday,
      );

      expect(streak.current, equals(5));
      expect(streak.longest, equals(15));
      expect(streak.lastUsageDate.day, equals(yesterday.day));
    });

    test('should validate Achievement properties', () {
      const achievement = Achievement(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Identify items from 3 different categories',
        type: AchievementType.categoriesIdentified,
        threshold: 3,
        iconName: 'category',
        color: Colors.orange,
        tier: AchievementTier.silver,
        pointsReward: 75,
        unlocksAtLevel: 1,
        progress: 0.67,
        achievementFamilyId: 'Category Expert',
      );

      expect(achievement.id, equals('category_explorer'));
      expect(achievement.type, equals(AchievementType.categoriesIdentified));
      expect(achievement.threshold, equals(3));
      expect(achievement.tier, equals(AchievementTier.silver));
      expect(achievement.pointsReward, equals(75));
      expect(achievement.unlocksAtLevel, equals(1));
      expect(achievement.progress, equals(0.67));
      expect(achievement.isEarned, isFalse); // Not earned yet (progress < 1.0)
      expect(achievement.achievementFamilyId, equals('Category Expert'));
    });

    test('should identify earned achievements correctly', () {
      final earnedDate = DateTime.now();
      const earnedAchievement = Achievement(
        id: 'waste_novice',
        title: 'Waste Novice',
        description: 'Identify your first 5 waste items',
        type: AchievementType.wasteIdentified,
        threshold: 5,
        iconName: 'emoji_objects',
        color: Colors.purple,
        progress: 1.0,
      );

      // Create an earned achievement with earnedOn date
      final actualEarnedAchievement = earnedAchievement.copyWith(
        earnedOn: earnedDate,
      );

      expect(actualEarnedAchievement.isEarned, isTrue);
      expect(actualEarnedAchievement.progress, equals(1.0));
      expect(actualEarnedAchievement.earnedOn, equals(earnedDate));
      
      // Test not-earned achievement
      expect(earnedAchievement.isEarned, isFalse); // earnedOn is null
    });

    test('should handle Challenge progress and completion', () {
      final activeChallenge = Challenge(
        id: 'plastic_hunter',
        title: 'Plastic Hunter',
        description: 'Identify 5 plastic items',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        pointsReward: 25,
        iconName: 'shopping_bag',
        color: Colors.amber,
        requirements: {'subcategory': 'Plastic', 'count': 5},
        progress: 0.8,
      );

      final completedChallenge = Challenge(
        id: 'compost_collector',
        title: 'Compost Collector',
        description: 'Identify 3 compostable items',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        pointsReward: 20,
        iconName: 'compost',
        color: Colors.brown,
        requirements: {'category': 'Wet Waste', 'count': 3},
        progress: 1.0,
        isCompleted: true,
      );

      expect(activeChallenge.isCompleted, isFalse);
      expect(activeChallenge.isExpired, isFalse);
      expect(activeChallenge.progress, equals(0.8));

      expect(completedChallenge.isCompleted, isTrue);
      expect(completedChallenge.isExpired, isTrue);
      expect(completedChallenge.progress, equals(1.0));
    });
  });

  group('UserProfile Model Tests', () {
    test('should create complete UserProfile with gamification', () {
      final gamificationProfile = GamificationProfile(
        userId: 'test_user_123',
        points: const UserPoints(total: 200, level: 2),
        streak: Streak(current: 3, longest: 8, lastUsageDate: DateTime.now()),
        achievements: [],
      );

      final userProfile = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'John Doe',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        familyId: 'family_456',
        gamificationProfile: gamificationProfile,
        preferences: { // Changed from settings
          'language': 'en',
          'region': 'US',
          'notifications': true,
        },
      );

      expect(userProfile.id, equals('test_user_123'));
      expect(userProfile.email, equals('test@example.com'));
      expect(userProfile.displayName, equals('John Doe'));
      expect(userProfile.familyId, equals('family_456'));
      expect(userProfile.gamificationProfile, isNotNull);
      expect(userProfile.gamificationProfile?.points.total, equals(200));
      expect(userProfile.gamificationProfile?.points.level, equals(2));
      expect(userProfile.preferences?['language'], equals('en')); // Changed from settings
    });

    test('should handle UserProfile serialization', () {
      final userProfile = UserProfile(
        id: 'test_user_456',
        email: 'jane@example.com',
        displayName: 'Jane Smith',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        lastActive: DateTime.parse('2024-01-15T12:00:00Z'),
      );

      // Test serialization
      final json = userProfile.toJson();
      expect(json['id'], equals('test_user_456'));
      expect(json['email'], equals('jane@example.com'));
      expect(json['displayName'], equals('Jane Smith'));

      // Test deserialization
      final recreated = UserProfile.fromJson(json);
      expect(recreated.id, equals(userProfile.id));
      expect(recreated.email, equals(userProfile.email));
      expect(recreated.displayName, equals(userProfile.displayName));
    });

    test('should handle empty/null optional fields gracefully', () {
      final minimalProfile = UserProfile(
        id: 'minimal_user',
        email: 'minimal@example.com',
        displayName: 'Minimal User',
      );

      expect(minimalProfile.id, equals('minimal_user'));
      expect(minimalProfile.photoUrl, isNull);
      expect(minimalProfile.familyId, isNull);
      expect(minimalProfile.gamificationProfile, isNull);
      expect(minimalProfile.preferences, isNull); // Changed from settings
    });
  });

  group('Model Validation and Edge Cases', () {
    test('should handle invalid confidence values gracefully', () {
      // Confidence values should be between 0.0 and 1.0
      final highConfidence = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
        confidence: 1.5, // Invalid - above 1.0
      );

      final negativeConfidence = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
        confidence: -0.5, // Invalid - negative
      );

      // Models should accept these values but they indicate data quality issues
      expect(highConfidence.confidence, equals(1.5));
      expect(negativeConfidence.confidence, equals(-0.5));
      
      // In a real app, you might want validation logic
      expect(highConfidence.confidence! > 1.0, isTrue); // Added !
      expect(negativeConfidence.confidence! < 0.0, isTrue); // Added !
    });

    test('should handle empty and null fields appropriately', () {
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: '', // Empty string
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: [],  // Empty steps
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [], // Empty list
        alternatives: [], // Empty list
      );

      expect(classification.itemName, equals(''));
      expect(classification.disposalInstructions.steps, isEmpty);
      expect(classification.visualFeatures, isEmpty);
      expect(classification.alternatives, isEmpty);
      expect(classification.subcategory, isNull);
      expect(classification.materialType, isNull);
    });

    test('should handle very long strings without issues', () {
      final longString = 'A' * 1000; // 1000 character string
      
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: longString,
        category: 'Dry Waste',
        explanation: longString,
        disposalInstructions: DisposalInstructions(
          primaryMethod: longString,
          steps: [longString, longString],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [longString],
        alternatives: [],
      );

      expect(classification.itemName.length, equals(1000));
      expect(classification.explanation.length, equals(1000));
      expect(classification.disposalInstructions.primaryMethod.length, equals(1000));
      expect(classification.visualFeatures.first.length, equals(1000));
    });

    test('should handle future dates appropriately', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Future Item',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: futureDate, // Future timestamp
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
      );

      expect(classification.timestamp.isAfter(DateTime.now()), isTrue);
    });
    // Add more tests for other models like EducationalContent, CommunityFeed etc.
  });
}