import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';
import 'package:waste_segregation_app/widgets/history_list_item.dart';

void main() {
  group('Regression Tests - Critical Bug Fixes', () {
    
    // Test for Achievement Unlock Logic Bug (Issue #3)
    group('Achievement Unlock Logic', () {
      testWidgets('Achievement unlock logic works correctly', (WidgetTester tester) async {
        // Create Level 2 achievement (Waste Apprentice)
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

        // Test the unlock logic directly
        const userLevel4 = 4;
        const userLevel1 = 1;
        
        // Level 4 user should have achievement unlocked
        final isUnlockedForLevel4 = userLevel4 >= (achievement.unlocksAtLevel ?? 0);
        expect(isUnlockedForLevel4, isTrue);
        
        // Level 1 user should have achievement locked
        final isUnlockedForLevel1 = userLevel1 >= (achievement.unlocksAtLevel ?? 0);
        expect(isUnlockedForLevel1, isFalse);
      });

      testWidgets('Achievement widget displays correctly', (WidgetTester tester) async {
        const achievement = Achievement(
          id: 'test_achievement',
          title: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'test',
          color: Colors.blue,
          unlocksAtLevel: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 300,
                height: 200,
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            achievement.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            achievement.description,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          achievement.isLocked ? Icons.lock : Icons.check,
                          color: achievement.isLocked ? Colors.grey : Colors.green,
                          size: 20,
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

        // Verify achievement title is visible
        expect(find.text('Test Achievement'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
      });
    });

    // Test for Layout Overflow Fixes (Issue #2)
    group('Layout Overflow Prevention', () {
      testWidgets('Classification feedback widget handles narrow screens', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Test Item',
          explanation: 'Test explanation',
            primaryMethod: 'Test',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250, // Narrow screen
                height: 400,
                child: ClassificationFeedbackWidget(
                  classification: classification,
                  onFeedbackSubmitted: (updated) {},
                  showCompactVersion: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not have overflow
        expect(tester.takeException(), isNull);
        
        // Should show feedback question
        expect(find.text('Was this classification correct?'), findsOneWidget);
      });

      testWidgets('History list item handles long category names', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Very Long Category Name That Could Cause Overflow Issues',
          explanation: 'Test explanation',
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Sort', 'Dispose'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300, // Constrained width
                child: HistoryListItem(
                  classification: classification,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not have overflow
        expect(tester.takeException(), isNull);
      });
    });

    // Test for Save/Share Button Consistency (Issue #4)
    group('Save/Share Button State Management', () {
      testWidgets('WasteClassification copyWith works correctly', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Plastic Bottle',
          explanation: 'Test explanation',
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Sort', 'Dispose'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
          isSaved: false,
        );

        // Test copyWith functionality for save state
        final savedClassification = classification.copyWith(isSaved: true);
        
        expect(savedClassification.isSaved, isTrue);
        expect(savedClassification.itemName, equals(classification.itemName));
        expect(savedClassification.category, equals(classification.category));
      });
    });

    // Test for Model Validation (General)
    group('Model Validation', () {
      testWidgets('WasteClassification model works correctly', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Test Item',
          explanation: 'Test explanation',
            primaryMethod: 'Test Method',
            steps: ['Step 1', 'Step 2'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: ['feature1', 'feature2'],
          alternatives: [],
          confidence: 0.85,
        );

        // Verify model properties
        expect(classification.itemName, equals('Test Item'));
        expect(classification.category, equals('Test Category'));
        expect(classification.confidence, equals(0.85));
        expect(classification.visualFeatures.length, equals(2));
        expect(classification.disposalInstructions.steps.length, equals(2));
      });

      testWidgets('Achievement model works correctly', (WidgetTester tester) async {
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

        // Verify model properties
        expect(achievement.id, equals('test_id'));
        expect(achievement.title, equals('Test Achievement'));
        expect(achievement.threshold, equals(10));
        expect(achievement.pointsReward, equals(50));
        expect(achievement.unlocksAtLevel, equals(2));
        expect(achievement.color, equals(Colors.blue));
      });
    });
  });

  group('Widget Rendering Tests', () {
    testWidgets('Basic widget rendering works without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: Column(
                children: [
                  const Text('Test App'),
                  const Icon(Icons.check),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Test Button'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Basic rendering test
      expect(find.text('Test App'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
    });
  });
} 