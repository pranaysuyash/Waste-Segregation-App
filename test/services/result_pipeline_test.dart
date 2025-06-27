import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';
import 'package:waste_segregation_app/models/gamification.dart';

/// Tests for ResultPipelineState data class
///
/// Note: The current copyWith implementation uses the null-aware operator (??)
/// which means passing null explicitly preserves the existing value rather than
/// clearing it. This affects nullable fields like 'error' and 'completedChallenge'.
/// The service code expects error: null to clear the error, suggesting a potential
/// mismatch in the copyWith implementation.
void main() {
  group('ResultPipelineState Tests', () {
    group('Initial State', () {
      test('creates with correct default values', () {
        const state = ResultPipelineState();

        expect(state.isProcessing, isFalse);
        expect(state.pointsEarned, equals(0));
        expect(state.newAchievements, isEmpty);
        expect(state.isSaved, isFalse);
        expect(state.error, isNull);
      });
    });

    group('CopyWith Method', () {
      test('copyWith creates new instance with updated values', () {
        const originalState = ResultPipelineState();

        final newState = originalState.copyWith(
          isProcessing: true,
          pointsEarned: 50,
          isSaved: true,
          error: 'Test error',
        );

        // Verify new state has updated values
        expect(newState.isProcessing, isTrue);
        expect(newState.pointsEarned, equals(50));
        expect(newState.isSaved, isTrue);
        expect(newState.error, equals('Test error'));

        // Verify original state unchanged
        expect(originalState.isProcessing, isFalse);
        expect(originalState.pointsEarned, equals(0));
        expect(originalState.isSaved, isFalse);
        expect(originalState.error, isNull);

        // Verify they are different instances
        expect(identical(originalState, newState), isFalse);
      });

      test('copyWith preserves unchanged fields', () {
        final achievement = Achievement(
          id: 'test-achievement',
          title: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'test_icon',
          color: const Color(0xFF4CAF50),
        );

        final originalState = const ResultPipelineState().copyWith(
          pointsEarned: 25,
          isSaved: true,
          error: 'Initial error',
          newAchievements: [achievement],
        );

        // Update only one field
        final newState = originalState.copyWith(pointsEarned: 50);

        // Verify updated field
        expect(newState.pointsEarned, equals(50));

        // Verify other fields preserved
        expect(newState.isSaved, isTrue);
        expect(newState.error, equals('Initial error'));
        expect(newState.isProcessing, isFalse);
        expect(newState.newAchievements, hasLength(1));
        expect(newState.newAchievements.first.id, equals('test-achievement'));
      });

      test('copyWith with explicit null preserves existing value', () {
        final originalState = const ResultPipelineState().copyWith(
          error: 'Some error',
          pointsEarned: 50,
        );

        // Passing null explicitly preserves existing value due to ?? operator
        final stateWithNullAttempt = originalState.copyWith(error: null);

        expect(stateWithNullAttempt.error, equals('Some error')); // Preserved due to ?? operator
        expect(stateWithNullAttempt.pointsEarned, equals(50)); // Other fields preserved
      });

      test('copyWith with achievements', () {
        const originalState = ResultPipelineState();

        final achievement1 = Achievement(
          id: 'achievement-1',
          title: 'First Achievement',
          description: 'Description 1',
          type: AchievementType.wasteIdentified,
          threshold: 5,
          iconName: 'icon1',
          color: const Color(0xFF4CAF50),
        );

        final achievement2 = Achievement(
          id: 'achievement-2',
          title: 'Second Achievement',
          description: 'Description 2',
          type: AchievementType.streakMaintained,
          threshold: 10,
          iconName: 'icon2',
          color: const Color(0xFF2196F3),
        );

        final stateWithAchievements = originalState.copyWith(
          newAchievements: [achievement1, achievement2],
        );

        expect(stateWithAchievements.newAchievements, hasLength(2));
        expect(stateWithAchievements.newAchievements[0].id, equals('achievement-1'));
        expect(stateWithAchievements.newAchievements[1].id, equals('achievement-2'));

        // Clear achievements
        final clearedState = stateWithAchievements.copyWith(newAchievements: []);
        expect(clearedState.newAchievements, isEmpty);
      });
    });

    group('State Immutability', () {
      test('state objects are immutable', () {
        final achievement = Achievement(
          id: 'test',
          title: 'Test',
          description: 'Test',
          type: AchievementType.wasteIdentified,
          threshold: 1,
          iconName: 'test',
          color: Colors.green,
        );

        final state1 = const ResultPipelineState().copyWith(
          pointsEarned: 100,
          newAchievements: [achievement],
        );

        final state2 = state1.copyWith(pointsEarned: 200);

        // Original state should be unchanged
        expect(state1.pointsEarned, equals(100));
        expect(state2.pointsEarned, equals(200));

        // Achievements should be preserved in both
        expect(state1.newAchievements, hasLength(1));
        expect(state2.newAchievements, hasLength(1));
        expect(state1.newAchievements.first.id, equals('test'));
        expect(state2.newAchievements.first.id, equals('test'));
      });
    });

    group('Error Handling', () {
      test('error state can be set', () {
        const state = ResultPipelineState();

        // Set error
        final stateWithError = state.copyWith(error: 'Test error message');
        expect(stateWithError.error, equals('Test error message'));

        // Attempting to clear with null preserves existing value
        final attemptToClear = stateWithError.copyWith(error: null);
        expect(attemptToClear.error, equals('Test error message')); // Still preserved

        // To clear error, create new state (as done in reset method)
        const clearedState = ResultPipelineState();
        expect(clearedState.error, isNull);
      });

      test('error state preserves other fields', () {
        final stateWithData = const ResultPipelineState().copyWith(
          pointsEarned: 75,
          isSaved: true,
          isProcessing: true,
        );

        final stateWithError = stateWithData.copyWith(error: 'Something went wrong');

        expect(stateWithError.error, equals('Something went wrong'));
        expect(stateWithError.pointsEarned, equals(75));
        expect(stateWithError.isSaved, isTrue);
        expect(stateWithError.isProcessing, isTrue);
      });
    });

    group('Processing State', () {
      test('processing state can be toggled', () {
        const state = ResultPipelineState();

        // Start processing
        final processingState = state.copyWith(isProcessing: true);
        expect(processingState.isProcessing, isTrue);

        // Stop processing
        final completedState = processingState.copyWith(isProcessing: false);
        expect(completedState.isProcessing, isFalse);
      });

      test('processing workflow simulation', () {
        const initialState = ResultPipelineState();

        // Start processing
        final processingState = initialState.copyWith(isProcessing: true);
        expect(processingState.isProcessing, isTrue);
        expect(processingState.isSaved, isFalse);
        expect(processingState.pointsEarned, equals(0));

        // Complete processing with results
        final completedState = processingState.copyWith(
          isProcessing: false,
          isSaved: true,
          pointsEarned: 30,
        );

        expect(completedState.isProcessing, isFalse);
        expect(completedState.isSaved, isTrue);
        expect(completedState.pointsEarned, equals(30));
      });
    });

    group('Achievement Management', () {
      test('achievements can be added incrementally', () {
        const state = ResultPipelineState();

        final achievement1 = Achievement(
          id: 'first',
          title: 'First',
          description: 'First achievement',
          type: AchievementType.wasteIdentified,
          threshold: 1,
          iconName: 'first',
          color: Colors.blue,
        );

        final stateWithOne = state.copyWith(newAchievements: [achievement1]);
        expect(stateWithOne.newAchievements, hasLength(1));

        final achievement2 = Achievement(
          id: 'second',
          title: 'Second',
          description: 'Second achievement',
          type: AchievementType.streakMaintained,
          threshold: 2,
          iconName: 'second',
          color: Colors.red,
        );

        final stateWithTwo = stateWithOne.copyWith(
          newAchievements: [...stateWithOne.newAchievements, achievement2],
        );

        expect(stateWithTwo.newAchievements, hasLength(2));
        expect(stateWithTwo.newAchievements[0].id, equals('first'));
        expect(stateWithTwo.newAchievements[1].id, equals('second'));
      });
    });

    group('Complex State Transitions', () {
      test('full workflow state transition', () {
        // Initial state
        const initialState = ResultPipelineState();
        expect(initialState.isProcessing, isFalse);
        expect(initialState.isSaved, isFalse);
        expect(initialState.pointsEarned, equals(0));
        expect(initialState.newAchievements, isEmpty);
        expect(initialState.error, isNull);

        // Start processing
        final processingState = initialState.copyWith(isProcessing: true);
        expect(processingState.isProcessing, isTrue);

        // Complete with achievements and points
        final achievement = Achievement(
          id: 'milestone',
          title: 'Milestone',
          description: 'Reached milestone',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'milestone',
          color: const Color(0xFFFFD700),
        );

        final completedState = processingState.copyWith(
          isProcessing: false,
          isSaved: true,
          pointsEarned: 50,
          newAchievements: [achievement],
        );

        expect(completedState.isProcessing, isFalse);
        expect(completedState.isSaved, isTrue);
        expect(completedState.pointsEarned, equals(50));
        expect(completedState.newAchievements, hasLength(1));
        expect(completedState.newAchievements.first.title, equals('Milestone'));
        expect(completedState.error, isNull);

        // Reset state
        const resetState = ResultPipelineState();
        expect(resetState.isProcessing, isFalse);
        expect(resetState.isSaved, isFalse);
        expect(resetState.pointsEarned, equals(0));
        expect(resetState.newAchievements, isEmpty);
        expect(resetState.error, isNull);
      });
    });
  });
}
