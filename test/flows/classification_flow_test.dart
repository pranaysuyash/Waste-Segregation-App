import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('Classification model sanity checks', () {
    test('constructs with expected fields', () {
      final classification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'plastic',
        explanation: 'Clear plastic bottle, recyclable',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Remove cap', 'Rinse', 'Place in bin'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: const ['plastic', 'bottle'],
        alternatives: const [],
      );

      expect(classification.itemName, equals('Plastic Bottle'));
      expect(classification.disposalInstructions.steps.length, equals(3));
    });

    test('fallback factory produces defaults', () {
      final fallback = WasteClassification.fallback('path/to/image.jpg');

      expect(fallback, isNotNull);
      expect(fallback.disposalInstructions.steps, isA<List<String>>());
    });
  });

  group('Gamification profile basics', () {
    test('profile model carries expected fields', () {
      final profile = GamificationProfile(
        userId: 'test_user',
        points: const UserPoints(total: 5, level: 1),
        streaks: {
          'daily_classification': StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 2,
            longestCount: 4,
            lastActivityDate: DateTime.now(),
          ),
        },
      );

      expect(profile.userId, equals('test_user'));
      expect(profile.streaks.keys, contains('daily_classification'));
    });
  });
}
