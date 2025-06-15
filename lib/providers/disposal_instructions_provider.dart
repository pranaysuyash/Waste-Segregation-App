import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../services/disposal_instructions_service.dart';

/// Provider for the disposal instructions service
final disposalInstructionsServiceProvider = Provider<DisposalInstructionsService>((ref) {
  return DisposalInstructionsService();
});

/// Provider for fetching disposal instructions for a specific material
final disposalInstructionsProvider = FutureProvider.family<DisposalInstructions, DisposalInstructionsRequest>((ref, request) async {
  final service = ref.read(disposalInstructionsServiceProvider);
  
  return service.getDisposalInstructions(
    material: request.material,
    category: request.category,
    subcategory: request.subcategory,
    lang: request.lang,
  );
});

/// Request object for disposal instructions
class DisposalInstructionsRequest {

  const DisposalInstructionsRequest({
    required this.material,
    this.category,
    this.subcategory,
    this.lang = 'en',
  });
  final String material;
  final String? category;
  final String? subcategory;
  final String lang;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisposalInstructionsRequest &&
        other.material == material &&
        other.category == category &&
        other.subcategory == subcategory &&
        other.lang == lang;
  }

  @override
  int get hashCode {
    return Object.hash(material, category, subcategory, lang);
  }

  @override
  String toString() {
    return 'DisposalInstructionsRequest(material: $material, category: $category, subcategory: $subcategory, lang: $lang)';
  }
}

/// Provider for preloading common disposal instructions
final preloadDisposalInstructionsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(disposalInstructionsServiceProvider);
  await service.preloadCommonMaterials();
});

/// Provider to clear disposal instructions cache
final clearDisposalCacheProvider = Provider<void Function()>((ref) {
  return () {
    final service = ref.read(disposalInstructionsServiceProvider);
    service.clearCache();
  };
}); 