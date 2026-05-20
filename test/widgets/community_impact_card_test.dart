import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/community_impact_card.dart';
import 'package:waste_segregation_app/screens/waste_dashboard_screen.dart';

WasteClassification _makeClassification({
  required String id,
  required String itemName,
  required String category,
  double? co2Impact,
  int? waterPollutionLevel,
  bool? isRecyclable,
  DateTime? timestamp,
}) {
  return WasteClassification(
    id: id,
    itemName: itemName,
    category: category,
    explanation: 'Test',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test',
      steps: const ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test',
    visualFeatures: const [],
    alternatives: const [],
    co2Impact: co2Impact,
    waterPollutionLevel: waterPollutionLevel,
    isRecyclable: isRecyclable,
    timestamp: timestamp ?? DateTime.now(),
    userId: 'u1',
  );
}

void main() {
  group('CommunityImpactCard', () {
    testWidgets('shows empty state when no classifications', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommunityImpactCard(classifications: []),
          ),
        ),
      );

      expect(find.text('Your Impact'), findsOneWidget);
      expect(find.text('No scans yet'), findsOneWidget);
      expect(find.textContaining('Start classifying waste'), findsOneWidget);
    });

    testWidgets('shows stats with fake classification history', (tester) async {
      final now = DateTime.now();
      final classifications = [
        _makeClassification(
          id: '1',
          itemName: 'Bottle',
          category: 'Dry Waste',
          co2Impact: 1.2,
          waterPollutionLevel: 2,
          isRecyclable: true,
          timestamp: now,
        ),
        _makeClassification(
          id: '2',
          itemName: 'Banana Peel',
          category: 'Wet Waste',
          co2Impact: 0.4,
          waterPollutionLevel: 1,
          isRecyclable: false,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityImpactCard(classifications: classifications),
          ),
        ),
      );

      expect(find.text('Your Impact'), findsOneWidget);
      expect(find.text('2 items classified'), findsOneWidget);
      expect(find.text('Est. CO₂ saved'), findsOneWidget);
      expect(find.text('1.6 kg'), findsOneWidget); // 1.2 + 0.4
      expect(find.text('Water saved'), findsOneWidget);
      expect(find.text('60 L'), findsOneWidget); // (2+1)*20
      expect(find.text('Most common'), findsOneWidget);
      expect(find.text('Dry Waste'), findsOneWidget);
      expect(find.text("This week's progress"), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('tap navigates to WasteDashboardScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityImpactCard(classifications: [
              _makeClassification(
                id: '1',
                itemName: 'Paper',
                category: 'Dry Waste',
                timestamp: DateTime.now(),
              ),
            ]),
          ),
        ),
      );

      await tester.tap(find.byType(CommunityImpactCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(WasteDashboardScreen), findsOneWidget);
    });

    testWidgets('custom onTap overrides default navigation', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityImpactCard(
              classifications: const [],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CommunityImpactCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
