class SegmentationItemExpectation {
  const SegmentationItemExpectation({
    required this.itemName,
    required this.category,
    this.subcategory,
    this.safetyCritical = false,
  });

  final String itemName;
  final String category;
  final String? subcategory;
  final bool safetyCritical;
}

class SegmentationRouteContract {
  const SegmentationRouteContract({
    required this.caseId,
    required this.enabled,
    required this.expectedItems,
    required this.expectedAggregateWarnings,
    this.route = 'future_segmentation_route',
  });

  final String caseId;
  final bool enabled;
  final List<SegmentationItemExpectation> expectedItems;
  final List<String> expectedAggregateWarnings;
  final String route;
}

