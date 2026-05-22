import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/waste_components/waste_components.dart';
import '../../helpers/component_test_harness.dart';

void main() {
  group('Waste components', () {
    group('ConfidenceIndicator', () {
      testWidgets('renders high confidence correctly', (tester) async {
        await pumpComponent(
          tester,
          const ConfidenceIndicator(confidencePercent: 89),
        );
        expect(find.text('89%'), findsOneWidget);
        expect(find.byIcon(Icons.verified), findsOneWidget);
      });

      testWidgets('renders low confidence correctly', (tester) async {
        await pumpComponent(
          tester,
          const ConfidenceIndicator(confidencePercent: 34),
        );
        expect(find.text('34%'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('accepts fraction instead of percent', (tester) async {
        await pumpComponent(
          tester,
          const ConfidenceIndicator(confidence: 0.72),
        );
        expect(find.text('72%'), findsOneWidget);
      });

      testWidgets('soft style renders without crashing', (tester) async {
        await pumpComponent(
          tester,
          const ConfidenceIndicator(
            confidencePercent: 72,
            style: ConfidenceIndicatorStyle.soft,
          ),
        );
        expect(find.text('72%'), findsOneWidget);
      });
    });

    group('BinRecommendationChip', () {
      testWidgets('renders from category', (tester) async {
        await pumpComponent(
          tester,
          const BinRecommendationChip(category: 'Wet Waste'),
        );
        expect(find.text('Green Bin'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('renders from explicit binLabel', (tester) async {
        await pumpComponent(
          tester,
          const BinRecommendationChip(binLabel: 'blue', label: 'Blue Bin'),
        );
        expect(find.text('Blue Bin'), findsOneWidget);
      });
    });

    group('PointsRewardChip', () {
      testWidgets('renders points with positive sign', (tester) async {
        await pumpComponent(
          tester,
          const PointsRewardChip(points: 15),
        );
        expect(find.text('+15 pts'), findsOneWidget);
      });

      testWidgets('renders zero without plus sign', (tester) async {
        await pumpComponent(
          tester,
          const PointsRewardChip(points: 0, variant: PointsRewardVariant.dimmed),
        );
        expect(find.text('0 pts'), findsOneWidget);
      });
    });

    group('DisposalWarningCard', () {
      testWidgets('renders warnings', (tester) async {
        await pumpComponent(
          tester,
          const DisposalWarningCard(
            title: 'Hazardous Material',
            warnings: ['Do not mix', 'Use gloves'],
            severity: WarningSeverity.high,
          ),
        );
        expect(find.text('Hazardous Material'), findsOneWidget);
        expect(find.text('Do not mix'), findsOneWidget);
        expect(find.text('Use gloves'), findsOneWidget);
      });

      testWidgets('renders with steps', (tester) async {
        await pumpComponent(
          tester,
          const DisposalWarningCard(
            title: 'Medical Waste',
            warnings: ['Biohazard'],
            steps: ['Seal bag', 'Contact health department'],
            severity: WarningSeverity.critical,
            urgentMessage: 'Dispose within 24 hours',
          ),
        );
        expect(find.text('Medical Waste'), findsOneWidget);
        expect(find.text('Dispose within 24 hours'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });
    });

    group('LocalRuleChip', () {
      testWidgets('renders with authority and label', (tester) async {
        await pumpComponent(
          tester,
          const LocalRuleChip(
            authority: 'BBMP',
            label: 'Daily collection',
          ),
        );
        expect(find.text('BBMP: Daily collection'), findsOneWidget);
      });

      testWidgets('renders with ruleName', (tester) async {
        await pumpComponent(
          tester,
          const LocalRuleChip(
            ruleName: 'BBMP collects daily 6-10 AM',
          ),
        );
        expect(find.text('BBMP collects daily 6-10 AM'), findsOneWidget);
      });
    });

    group('WasteImagePreviewCard', () {
      testWidgets('renders fallback for missing image', (tester) async {
        await pumpComponent(
          tester,
          const WasteImagePreviewCard(
            category: 'Dry Waste',
            size: 80,
          ),
        );
        expect(find.byIcon(Icons.recycling), findsOneWidget);
      });
    });

    group('ClassificationSummaryCard', () {
      testWidgets('renders item name and category', (tester) async {
        await pumpComponent(
          tester,
          const ClassificationSummaryCard(
            itemName: 'Plastic Bottle',
            category: 'Dry Waste',
            confidence: 0.89,
          ),
        );
        expect(find.text('Plastic Bottle'), findsOneWidget);
      });
    });

    group('OfflineQueueStatusCard', () {
      testWidgets('renders pending count', (tester) async {
        await pumpComponent(
          tester,
          const OfflineQueueStatusCard(pendingCount: 5),
        );
        expect(find.text('5 item(s) in queue'), findsOneWidget);
      });

      testWidgets('hides when empty and synced', (tester) async {
        await pumpComponent(
          tester,
          const OfflineQueueStatusCard(pendingCount: 0, isSyncing: false),
        );
        // Card intentionally hides when empty+synced via SizedBox.shrink
        expect(find.byType(Card), findsNothing);
      });
    });

    group('CorrectionPrompt', () {
      testWidgets('renders alternative chips', (tester) async {
        await pumpComponent(
          tester,
          const CorrectionPrompt(
            category: 'Dry Waste',
            alternatives: [
              CorrectionAlternative(label: 'Wet Waste', confidence: 0.12),
              CorrectionAlternative(label: 'Hazardous', confidence: 0.05),
            ],
          ),
        );
        expect(find.text('Wet Waste'), findsOneWidget);
        expect(find.text('12%'), findsOneWidget);
      });
    });

    group('WasteTipCard', () {
      testWidgets('renders tip text', (tester) async {
        await pumpComponent(
          tester,
          const WasteTipCard(
            tip: 'Paper can be recycled several times.',
            category: 'Dry Waste',
          ),
        );
        expect(find.text('Paper can be recycled several times.'), findsOneWidget);
      });
    });
  });
}
