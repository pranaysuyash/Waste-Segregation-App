import 'dart:typed_data';

import '../ai_flywheel/segmentation_contract.dart';

class SegmentationRouteResult {
  const SegmentationRouteResult({
    required this.items,
    required this.aggregateWarnings,
    required this.modelRoute,
  });

  final List<SegmentationItemExpectation> items;
  final List<String> aggregateWarnings;
  final String modelRoute;
}

abstract class SegmentationRouteService {
  Future<SegmentationRouteResult> segment({
    required Uint8List imageBytes,
    required String region,
    required String fallbackCategory,
  });
}

class StubSegmentationRouteService implements SegmentationRouteService {
  const StubSegmentationRouteService();

  @override
  Future<SegmentationRouteResult> segment({
    required Uint8List imageBytes,
    required String region,
    required String fallbackCategory,
  }) async {
    return SegmentationRouteResult(
      items: <SegmentationItemExpectation>[
        SegmentationItemExpectation(
          itemName: fallbackCategory,
          category: fallbackCategory,
        ),
      ],
      aggregateWarnings: <String>[
        'Separate mixed waste before disposal when multiple materials are visible',
      ],
      modelRoute: 'segmentation_stub_v1',
    );
  }
}

