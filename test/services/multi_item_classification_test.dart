import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/models/multi_item_classification_result.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('NormalizedBoundingBox', () {
    test('computes right and bottom correctly', () {
      final box = NormalizedBoundingBox(
        left: 0.1,
        top: 0.2,
        width: 0.5,
        height: 0.6,
      );
      expect(box.right, closeTo(0.6, 0.001));
      expect(box.bottom, closeTo(0.8, 0.001));
    });

    test('computes intersection over union', () {
      final a = NormalizedBoundingBox(
        left: 0.0,
        top: 0.0,
        width: 0.5,
        height: 0.5,
      );
      final b = NormalizedBoundingBox(
        left: 0.25,
        top: 0.25,
        width: 0.5,
        height: 0.5,
      );
      final iou = a.intersectionOverUnion(b);
      expect(iou, greaterThan(0.0));
      expect(iou, lessThan(1.0));
    });

    test('non-overlapping boxes have zero IoU', () {
      final a = NormalizedBoundingBox(
        left: 0.0,
        top: 0.0,
        width: 0.1,
        height: 0.1,
      );
      final b = NormalizedBoundingBox(
        left: 0.8,
        top: 0.8,
        width: 0.1,
        height: 0.1,
      );
      expect(a.intersectionOverUnion(b), 0.0);
    });

    test('clamps right and bottom to 1.0', () {
      final box = NormalizedBoundingBox(
        left: 0.5,
        top: 0.5,
        width: 0.6,
        height: 0.6,
      );
      expect(box.right, 1.0);
      expect(box.bottom, 1.0);
    });

    test('JSON round trip', () {
      final original = NormalizedBoundingBox(
        left: 0.1,
        top: 0.2,
        width: 0.3,
        height: 0.4,
      );
      final json = original.toJson();
      final restored = NormalizedBoundingBox.fromJson(json);
      expect(restored.left, original.left);
      expect(restored.top, original.top);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
    });
  });

  group('DetectedWasteRegion', () {
    test('creates with unique id', () {
      final region = DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
          left: 0.0,
          top: 0.0,
          width: 0.5,
          height: 0.5,
        ),
        label: 'bottle',
        confidence: 0.85,
      );
      expect(region.id, isNotEmpty);
      expect(region.label, 'bottle');
      expect(region.confidence, 0.85);
      expect(region.userConfirmed, false);
    });

    test('copyWith preserves unset fields', () {
      final region = DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
          left: 0.1,
          top: 0.1,
          width: 0.3,
          height: 0.3,
        ),
      );
      final copy = region.copyWith(label: 'can');
      expect(copy.label, 'can');
      expect(copy.boundingBox.left, 0.1);
      expect(copy.id, region.id);
    });

    test('JSON round trip', () {
      final original = DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
          left: 0.2,
          top: 0.3,
          width: 0.4,
          height: 0.5,
        ),
        label: 'paper',
        confidence: 0.9,
        userConfirmed: true,
      );
      final json = original.toJson();
      final restored = DetectedWasteRegion.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.label, 'paper');
      expect(restored.confidence, 0.9);
      expect(restored.userConfirmed, true);
      expect(restored.boundingBox.left, 0.2);
    });
  });

  group('MultiItemClassificationResult', () {
    List<DetectedWasteRegion> _sampleRegions() {
      return [
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.0,
            top: 0.0,
            width: 0.4,
            height: 0.5,
          ),
          classification: WasteClassification(
            itemName: 'Plastic Bottle',
            category: 'Dry Waste',
            explanation: 'PET bottle',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Recycle with plastics',
              steps: ['Rinse and sort'],
              hasUrgentTimeframe: false,
            ),
            visualFeatures: [],
            alternatives: [],
            region: 'Test',
          ),
          label: 'bottle',
          userConfirmed: true,
        ),
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.5,
            top: 0.0,
            width: 0.4,
            height: 0.5,
          ),
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
          label: 'banana peel',
          userConfirmed: true,
        ),
      ];
    }

    test('detects multiple items', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
      );
      expect(result.hasMultipleItems, true);
      expect(result.itemCount, 2);
    });

    test('detects single item', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: [_sampleRegions().first],
      );
      expect(result.hasMultipleItems, false);
      expect(result.itemCount, 1);
    });

    test('detects mixed categories', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
      );
      expect(result.hasMixedCategories, true);
      expect(result.uniqueCategories.length, 2);
    });

    test('groups regions by category', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
      );
      final grouped = result.regionsByCategory;
      expect(grouped.keys.length, 2);
      expect(grouped['Dry Waste']?.length, 1);
      expect(grouped['Wet Waste']?.length, 1);
    });

    test('allConfirmed returns false when some unconfirmed', () {
      final regions = _sampleRegions();
      regions[1] = regions[1].copyWith(userConfirmed: false);
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: regions,
      );
      expect(result.allConfirmed, false);
      expect(result.unconfirmedRegions.length, 1);
    });

    test('allConfirmed returns true when all confirmed', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
      );
      expect(result.allConfirmed, true);
    });

    test('provides primary disposal guidance for mixed waste', () {
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
      );
      final guidance = result.primaryDisposalGuidance;
      expect(guidance, isNotNull);
      expect(guidance!.toLowerCase(), contains('mixed'));
    });

    test('provides primary disposal guidance for single category', () {
      final sameCategory = _sampleRegions()
          .map((r) => r.copyWith(
              classification: r.classification?.copyWith(
                  category: 'Dry Waste')))
          .toList();
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: sameCategory,
      );
      final guidance = result.primaryDisposalGuidance;
      expect(guidance, isNotNull);
      expect(guidance!.toLowerCase(), contains('dry waste'));
    });

    test('inferMixedWasteGuidance detects hazardous + regular mix', () {
      final regions = [
        _sampleRegions()[0],
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.3,
            top: 0.5,
            width: 0.2,
            height: 0.2,
          ),
          classification: WasteClassification(
            itemName: 'Battery',
            category: 'Hazardous Waste',
            explanation: 'Lithium battery',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Special drop-off',
              steps: ['Take to battery recycling center'],
              hasUrgentTimeframe: true,
            ),
            visualFeatures: [],
            alternatives: [],
            region: 'Test',
          ),
          label: 'battery',
          userConfirmed: true,
        ),
      ];
      final guidance =
          MultiItemClassificationResult.inferMixedWasteGuidance(regions);
      expect(guidance.toLowerCase(), contains('hazardous'));
      expect(guidance.toLowerCase(), contains('not be mixed'));
    });

    test('classifiedRegions returns only regions with classifications', () {
      final regions = _sampleRegions();
      regions.add(DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
          left: 0.0,
          top: 0.6,
          width: 0.3,
          height: 0.3,
        ),
        label: 'unknown',
      ));
      final result = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: regions,
      );
      expect(result.classifiedRegions.length, 2);
    });

    test('JSON round trip with regions', () {
      final original = MultiItemClassificationResult(
        sourceImagePath: '/test/image.jpg',
        regions: _sampleRegions(),
        mixedWasteGuidance: 'Separate before disposal',
      );
      final json = original.toJson();
      final restored = MultiItemClassificationResult.fromJson(json);
      expect(restored.sourceImagePath, original.sourceImagePath);
      expect(restored.regions.length, original.regions.length);
      expect(restored.mixedWasteGuidance, isNotEmpty);
    });
  });
}
