import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/multi_item_region_review.dart';

void main() {
  group('MultiItemRegionReview', () {
    List<DetectedWasteRegion> sampleRegions() {
      return [
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.1, top: 0.1, width: 0.4, height: 0.4,
          ),
          label: 'Bottle',
          classification: WasteClassification(
            itemName: 'Plastic Bottle',
            category: 'Dry Waste',
            explanation: 'PET bottle',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Recycle',
              steps: ['Rinse and sort'],
              hasUrgentTimeframe: false,
            ),
            visualFeatures: [],
            alternatives: [],
            region: 'Test',
          ),
        ),
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.6, top: 0.1, width: 0.3, height: 0.3,
          ),
          label: 'Banana Peel',
          classification: WasteClassification(
            itemName: 'Banana Peel',
            category: 'Wet Waste',
            explanation: 'Organic waste',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Compost',
              steps: ['Add to compost bin'],
              hasUrgentTimeframe: false,
            ),
            visualFeatures: [],
            alternatives: [],
            region: 'Test',
          ),
        ),
      ];
    }

    testWidgets('shows header with region count', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: sampleRegions(),
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.textContaining('2 possible items'), findsWidgets);
      expect(find.text('Tap each one to confirm'), findsOneWidget);
    });

    testWidgets('shows all items in list', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: sampleRegions(),
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.text('Bottle'), findsOneWidget);
      expect(find.text('Banana Peel'), findsOneWidget);
    });

    testWidgets('shows confirmed count in header', (tester) async {
      final regions = sampleRegions();
      regions[0] = regions[0].copyWith(userConfirmed: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: regions,
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('shows all confirmed state', (tester) async {
      final regions = sampleRegions();
      regions[0] = regions[0].copyWith(userConfirmed: true);
      regions[1] = regions[1].copyWith(userConfirmed: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: regions,
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.text('All items confirmed'), findsOneWidget);
    });

    testWidgets('shows add region button when under max', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: sampleRegions(),
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            onAddRegion: () {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.text('Add region'), findsOneWidget);
    });

    testWidgets('hides add region button at max', (tester) async {
      final regions = List.generate(
        8,
        (i) => DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
              left: 0.1 * i, top: 0.1, width: 0.1, height: 0.1),
          label: 'Item $i',
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: regions,
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            onAddRegion: () {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.text('Add region'), findsNothing);
    });

    testWidgets('calls onToggleConfirm when tapping item', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: sampleRegions(),
            onToggleConfirm: (id) => toggled.add(id),
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      await tester.tap(find.text('Bottle'));
      expect(toggled.length, 1);
    });

    testWidgets('calls onRemoveRegion when tapping remove on confirmed',
        (tester) async {
      final removed = <String>[];
      final regions = sampleRegions();
      regions[0] = regions[0].copyWith(userConfirmed: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: regions,
            onToggleConfirm: (_) {},
            onRemoveRegion: (id) => removed.add(id),
            maxRegions: 8,
          ),
        ),
      ));

      // Find the close icon on the confirmed item
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows empty state with unconfirmed items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MultiItemRegionReview(
            regions: sampleRegions(),
            onToggleConfirm: (_) {},
            onRemoveRegion: (_) {},
            maxRegions: 8,
          ),
        ),
      ));

      expect(find.byIcon(Icons.radio_button_unchecked),
          findsNWidgets(2));
    });
  });
}
