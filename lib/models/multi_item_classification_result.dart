import 'detected_waste_region.dart';

class MultiItemClassificationResult {
  MultiItemClassificationResult({
    required this.sourceImagePath,
    this.sourceImageBytes,
    required this.regions,
    this.aggregateWarnings = const [],
    this.mixedWasteGuidance,
  });

  final String sourceImagePath;
  final List<int>? sourceImageBytes;
  final List<DetectedWasteRegion> regions;
  final List<String> aggregateWarnings;
  final String? mixedWasteGuidance;

  int get itemCount => regions.length;
  bool get hasMultipleItems => regions.length > 1;
  bool get allConfirmed =>
      regions.isNotEmpty && regions.every((r) => r.userConfirmed);

  List<DetectedWasteRegion> get unconfirmedRegions =>
      regions.where((r) => !r.userConfirmed).toList();

  List<DetectedWasteRegion> get classifiedRegions =>
      regions.where((r) => r.classification != null).toList();

  Map<String, List<DetectedWasteRegion>> get regionsByCategory {
    final map = <String, List<DetectedWasteRegion>>{};
    for (final region in classifiedRegions) {
      final category = region.classification!.category;
      map.putIfAbsent(category, () => []).add(region);
    }
    return map;
  }

  Set<String> get uniqueCategories =>
      classifiedRegions.map((r) => r.classification!.category).toSet();

  bool get hasMixedCategories => uniqueCategories.length > 1;

  String? get primaryDisposalGuidance {
    if (!hasMultipleItems) {
      return regions.isNotEmpty && regions.first.classification != null
          ? regions.first.classification!.disposalInstructions.primaryMethod
          : null;
    }

    if (hasMixedCategories) {
      final guidance = StringBuffer('Mixed waste detected — ');
      final categories = regionsByCategory;
      final parts = <String>[];
      for (final entry in categories.entries) {
        parts.add('${entry.value.length} ${entry.key.toLowerCase()}');
      }
      guidance.write(parts.join(', '));
      guidance.write(
          '. Separate items before disposal if required by local rules.');
      return guidance.toString();
    }

    final singleCategory = uniqueCategories.first;
    return 'All items classified as $singleCategory. ${regions.length} items to dispose.';
  }

  static String inferMixedWasteGuidance(
      List<DetectedWasteRegion> regions) {
    final categorized =
        regions.where((r) => r.classification != null).toList();
    if (categorized.isEmpty) {
      return 'Classification pending for all items.';
    }

    final categories = <String>{};
    for (final r in categorized) {
      categories.add(r.classification!.category);
    }

    if (categories.length <= 1) {
      final cat = categories.isNotEmpty
          ? categories.first
          : 'unknown';
      return 'All $categorized.length items are $cat. Can be disposed together.';
    }

    final hasHazardous = categories.any((c) =>
        c.toLowerCase().contains('hazard') ||
        c.toLowerCase().contains('medical'));
    final hasWet = categories
        .any((c) => c.toLowerCase().contains('wet'));
    final hasDry = categories
        .any((c) => c.toLowerCase().contains('dry'));

    final warnings = <String>[];
    if (hasHazardous) {
      warnings.add(
          'Hazardous items must NOT be mixed with regular waste.');
    }
    if (hasWet && hasDry) {
      warnings.add(
          'Wet and dry waste require separate bins.');
    }

    return warnings.isNotEmpty
        ? warnings.join(' ')
        : 'Items span multiple categories. Sort before disposal.';
  }

  Map<String, dynamic> toJson() => {
    'sourceImagePath': sourceImagePath,
    'hasSourceImageBytes': sourceImageBytes != null,
    'regions': regions.map((r) => r.toJson()).toList(),
    'aggregateWarnings': aggregateWarnings,
    'mixedWasteGuidance': mixedWasteGuidance ?? inferMixedWasteGuidance(regions),
  };

  factory MultiItemClassificationResult.fromJson(
          Map<String, dynamic> json) =>
      MultiItemClassificationResult(
        sourceImagePath: json['sourceImagePath'],
        sourceImageBytes:
            json['hasSourceImageBytes'] == true ? [] : null,
        regions: (json['regions'] as List)
            .map((r) =>
                DetectedWasteRegion.fromJson(r as Map<String, dynamic>))
            .toList(),
        aggregateWarnings:
            List<String>.from(json['aggregateWarnings'] ?? []),
        mixedWasteGuidance: json['mixedWasteGuidance'],
      );
}
