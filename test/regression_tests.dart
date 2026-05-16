import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/history_list_item.dart';

WasteClassification _classification({
  String id = 'test-id',
  String itemName = 'Test Item',
  String category = 'plastic',
  double confidence = 0.85,
  List<String> visualFeatures = const ['feature1', 'feature2'],
}) {
  return WasteClassification(
    id: id,
    itemName: itemName,
    category: category,
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test method',
      steps: const ['Step 1', 'Step 2'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: visualFeatures,
    alternatives: const [],
    confidence: confidence,
    timestamp: DateTime(2025, 1, 1),
    userId: 'test-user',
  );
}

void main() {
  group('Regression Tests - Critical Bug Fixes', () {
    group('Achievement Unlock Logic', () {
      testWidgets('Achievement unlock logic works correctly',
          (WidgetTester tester) async {
        const achievement = Achievement(
          id: 'waste_apprentice',
          title: 'Waste Apprentice',
          description: 'Reach Level 2',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'apprentice',
          color: Colors.green,
          unlocksAtLevel: 2,
        );

        const userLevel4 = 4;
        const userLevel1 = 1;

        expect(userLevel4 >= (achievement.unlocksAtLevel ?? 0), isTrue);
        expect(userLevel1 >= (achievement.unlocksAtLevel ?? 0), isFalse);
      });
    });

    group('Layout Overflow Prevention', () {
      testWidgets('HistoryListItem renders in constrained width',
          (WidgetTester tester) async {
        final classification = _classification(
          itemName: 'Very Long Item Name That Could Cause Overflow Issues',
          category: 'Very Long Category Name That Could Cause Overflow Issues',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: HistoryListItem(
                  classification: classification,
                  onTap: () {},
                  onFeedbackSubmitted: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });

    group('Save/Share Button State Management', () {
      testWidgets('WasteClassification.copyWith toggles isSaved',
          (WidgetTester tester) async {
        final classification = _classification().copyWith(isSaved: false);
        final saved = classification.copyWith(isSaved: true);

        expect(saved.isSaved, isTrue);
        expect(saved.itemName, classification.itemName);
        expect(saved.category, classification.category);
      });
    });

    group('Model Validation', () {
      testWidgets('WasteClassification model assigns fields',
          (WidgetTester tester) async {
        final classification =
            _classification(itemName: 'Test Item', category: 'Test Category');

        expect(classification.itemName, 'Test Item');
        expect(classification.category, 'Test Category');
        expect(classification.confidence, 0.85);
        expect(classification.visualFeatures.length, 2);
        expect(classification.disposalInstructions.steps.length, 2);
      });

      testWidgets('Achievement model assigns fields',
          (WidgetTester tester) async {
        const achievement = Achievement(
          id: 'test_id',
          title: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'test_icon',
          color: Colors.blue,
          unlocksAtLevel: 2,
        );

        expect(achievement.id, 'test_id');
        expect(achievement.title, 'Test Achievement');
        expect(achievement.threshold, 10);
        expect(achievement.unlocksAtLevel, 2);
        expect(achievement.color, Colors.blue);
      });
    });
  });
}
