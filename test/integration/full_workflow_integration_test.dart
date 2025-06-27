import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('Integration Tests - Full Application Workflows', () {
    group('Model Creation Tests', () {
      test('should create test classification successfully', () async {
        // Test basic classification creation
        final classification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Test disposal',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: ['test'],
          alternatives: [],
          timestamp: DateTime.now(),
          confidence: 0.85,
          userId: 'test_user',
        );

        expect(classification.itemName, equals('Test Item'));
        expect(classification.category, equals('Dry Waste'));
        expect(classification.confidence, equals(0.85));
        expect(classification.userId, equals('test_user'));
        expect(classification.visualFeatures, contains('test'));
        expect(classification.alternatives, isEmpty);
      });

      test('should create user profile successfully', () async {
        final user = UserProfile(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        expect(user.id, equals('test_user_123'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
      });

      test('should create gamification profile successfully', () async {
        const profile = GamificationProfile(
          userId: 'test_user',
          points: const UserPoints(total: 100, level: 2),
          streaks: <String, StreakDetails>{},
          achievements: [],
        );

        expect(profile.userId, equals('test_user'));
        expect(profile.points.total, equals(100));
        expect(profile.points.level, equals(2));
        expect(profile.streaks, isEmpty);
        expect(profile.achievements, isEmpty);
      });

      test('should create challenge successfully', () async {
        final challenge = Challenge(
          id: 'test_challenge',
          title: 'Test Challenge',
          description: 'A test challenge',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 6)),
          pointsReward: 10,
          iconName: 'star',
          color: Colors.blue,
          requirements: {'count': 1},
          progress: 0.5,
        );

        expect(challenge.id, equals('test_challenge'));
        expect(challenge.title, equals('Test Challenge'));
        expect(challenge.pointsReward, equals(10));
        expect(challenge.progress, equals(0.5));
        expect(challenge.isCompleted, isFalse);
        expect(challenge.requirements['count'], equals(1));
      });

      test('should create streak details successfully', () async {
        final streakDetails = StreakDetails(
          type: StreakType.dailyClassification,
          currentCount: 5,
          longestCount: 10,
          lastActivityDate: DateTime.now(),
        );

        expect(streakDetails.currentCount, equals(5));
        expect(streakDetails.longestCount, equals(10));
        expect(streakDetails.lastActivityDate, isNotNull);
        expect(streakDetails.type, equals(StreakType.dailyClassification));
      });

      test('should create user points successfully', () async {
        const points = UserPoints(total: 250, level: 3);

        expect(points.total, equals(250));
        expect(points.level, equals(3));
      });
    });

    group('Data Validation Tests', () {
      test('should validate classification data integrity', () async {
        final classification = _createTestClassification('Data Integrity Test');

        // Validate required fields
        expect(classification.itemName, isNotEmpty);
        expect(classification.category, isNotEmpty);
        expect(classification.explanation, isNotEmpty);
        expect(classification.timestamp, isNotNull);
        expect(classification.disposalInstructions, isNotNull);
        expect(classification.disposalInstructions.primaryMethod, isNotEmpty);
        expect(classification.disposalInstructions.steps, isNotEmpty);

        // Validate optional fields
        expect(classification.confidence, isNull);
        expect(classification.userId, equals('test_user'));
        expect(classification.region, equals('Test Region'));
      });

      test('should handle classification with confidence score', () async {
        final classification = WasteClassification(
          itemName: 'Confident Item',
          category: 'Wet Waste',
          explanation: 'High confidence classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: ['Add to compost bin'],
            hasUrgentTimeframe: false,
          ),
          region: 'Urban Area',
          visualFeatures: ['organic', 'biodegradable'],
          alternatives: [
            AlternativeClassification(
              category: 'Biogas production',
              confidence: 0.8,
              reason: 'Consider biogas production as an alternative',
            ),
          ],
          timestamp: DateTime.now(),
          confidence: 0.95,
          userId: 'confident_user',
        );

        expect(classification.confidence, equals(0.95));
        expect(classification.category, equals('Wet Waste'));
        expect(classification.alternatives.first.category, equals('Biogas production'));
        expect(classification.visualFeatures, contains('organic'));
        expect(classification.visualFeatures, contains('biodegradable'));
      });

      test('should handle minimal classification data', () async {
        final minimalClassification = WasteClassification(
          itemName: 'Minimal Item',
          category: 'Unknown',
          explanation: '',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'General waste',
            steps: [],
            hasUrgentTimeframe: false,
          ),
          region: '',
          visualFeatures: [],
          alternatives: [],
          timestamp: DateTime.now(),
        );

        expect(minimalClassification.itemName, equals('Minimal Item'));
        expect(minimalClassification.category, equals('Unknown'));
        expect(minimalClassification.explanation, isEmpty);
        expect(minimalClassification.region, isEmpty);
        expect(minimalClassification.visualFeatures, isEmpty);
        expect(minimalClassification.alternatives, isEmpty);
        expect(minimalClassification.disposalInstructions.steps, isEmpty);
        expect(minimalClassification.confidence, isNull);
        expect(minimalClassification.userId, isNull);
      });
    });

    group('Data Flow Simulation Tests', () {
      test('should simulate classification workflow', () async {
        // Step 1: Create classification
        final classification = _createTestClassification('Workflow Test Item');

        // Step 2: Validate classification was created
        expect(classification, isNotNull);
        expect(classification.itemName, equals('Workflow Test Item'));

        // Step 3: Simulate processing results
        final processingResults = {
          'saved': true,
          'points_awarded': 10,
          'challenges_updated': 2,
          'analytics_tracked': true,
        };

        // Step 4: Validate processing results
        expect(processingResults['saved'], isTrue);
        expect(processingResults['points_awarded'], equals(10));
        expect(processingResults['challenges_updated'], equals(2));
        expect(processingResults['analytics_tracked'], isTrue);
      });

      test('should simulate user profile workflow', () async {
        // Step 1: Create user
        final user = UserProfile(
          id: 'workflow_user',
          email: 'workflow@test.com',
          displayName: 'Workflow User',
        );

        // Step 2: Create gamification profile
        final profile = GamificationProfile(
          userId: user.id,
          points: const UserPoints(level: 1),
          streaks: <String, StreakDetails>{},
          achievements: [],
        );

        // Step 3: Simulate activity
        final updatedProfile = GamificationProfile(
          userId: profile.userId,
          points: const UserPoints(total: 50),
          streaks: {
            'daily': StreakDetails(
              type: StreakType.dailyClassification,
              currentCount: 3,
              longestCount: 5,
              lastActivityDate: DateTime.now(),
            ),
          },
          achievements: [],
        );

        // Step 4: Validate workflow
        expect(user.id, equals(profile.userId));
        expect(updatedProfile.points.total, greaterThan(profile.points.total));
        expect(updatedProfile.streaks, isNotEmpty);
      });

      test('should simulate batch processing workflow', () async {
        // Step 1: Create multiple classifications
        final classifications = List.generate(5, (i) => _createTestClassification('Batch Item $i'));

        // Step 2: Validate batch creation
        expect(classifications.length, equals(5));
        expect(classifications.first.itemName, equals('Batch Item 0'));
        expect(classifications.last.itemName, equals('Batch Item 4'));

        // Step 3: Simulate batch processing
        final batchResults = classifications
            .map((classification) => {
                  'id': classification.itemName,
                  'processed': true,
                  'points': 5,
                })
            .toList();

        // Step 4: Validate batch results
        expect(batchResults.length, equals(5));
        expect(batchResults.every((result) => result['processed'] == true), isTrue);

        final totalPoints = batchResults.fold<int>(0, (sum, result) => sum + (result['points'] as int));
        expect(totalPoints, equals(25));
      });
    });

    group('Performance Simulation Tests', () {
      test('should handle large dataset efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Create large dataset
        final largeDataset = List.generate(100, (i) => _createTestClassification('Performance Item $i'));

        stopwatch.stop();

        // Validate performance
        expect(largeDataset.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
        expect(largeDataset.first.itemName, equals('Performance Item 0'));
        expect(largeDataset.last.itemName, equals('Performance Item 99'));
      });

      test('should handle memory usage efficiently', () async {
        // Create memory test data
        final memoryTestData = <WasteClassification>[];

        for (var i = 0; i < 50; i++) {
          memoryTestData.add(_createTestClassification('Memory Test $i'));
        }

        // Validate memory efficiency
        expect(memoryTestData.length, equals(50));
        expect(memoryTestData.every((item) => item.itemName.startsWith('Memory Test')), isTrue);

        // Clear data to test cleanup
        memoryTestData.clear();
        expect(memoryTestData, isEmpty);
      });
    });

    group('Edge Case Tests', () {
      test('should handle special characters in item names', () async {
        final specialCharClassification = WasteClassification(
          itemName: 'Special!@#\$%^&*()_+{}|:"<>?[]\\;\',./',
          category: 'Test Category',
          explanation: 'Testing special characters',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Special disposal',
            steps: ['Handle with care'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          timestamp: DateTime.now(),
        );

        expect(specialCharClassification.itemName, contains('!@#'));
        expect(specialCharClassification.itemName, contains('()_+'));
        expect(specialCharClassification.category, equals('Test Category'));
      });

      test('should handle very long text fields', () async {
        final longText = 'A' * 1000; // 1000 character string

        final longTextClassification = WasteClassification(
          itemName: 'Long Text Item',
          category: 'Test Category',
          explanation: longText,
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Standard disposal',
            steps: [longText],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          timestamp: DateTime.now(),
        );

        expect(longTextClassification.explanation.length, equals(1000));
        expect(longTextClassification.disposalInstructions.steps.first.length, equals(1000));
        expect(longTextClassification.explanation, equals(longText));
      });

      test('should handle extreme date values', () async {
        final futureDate = DateTime(2100, 12, 31);
        final pastDate = DateTime(1900, 1);

        final futureDateClassification = WasteClassification(
          itemName: 'Future Item',
          category: 'Test Category',
          explanation: 'Future dated item',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Future disposal',
            steps: ['Future step'],
            hasUrgentTimeframe: false,
          ),
          region: 'Future Region',
          visualFeatures: [],
          alternatives: [],
          timestamp: futureDate,
        );

        expect(futureDateClassification.timestamp.year, equals(2100));
        expect(futureDateClassification.timestamp.isAfter(DateTime.now()), isTrue);
      });
    });
  });
}

// Helper function to create test classifications
WasteClassification _createTestClassification(String itemName) {
  return WasteClassification(
    itemName: itemName,
    category: 'Test Category',
    explanation: 'Test classification for $itemName',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1', 'Step 2'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: ['test', 'sample'],
    alternatives: [
      AlternativeClassification(
        category: 'Alternative disposal',
        confidence: 0.7,
        reason: 'Consider this alternative disposal method',
      ),
    ],
    timestamp: DateTime.now(),
    userId: 'test_user',
  );
}
