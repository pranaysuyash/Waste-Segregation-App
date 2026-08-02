import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:waste_segregation_app/services/recycling_taxonomy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RecyclingTaxonomyService', () {
    test('resolves the packaged taxonomy asset', () async {
      final packaged = await rootBundle.loadString(
        'lib/data/recycling_taxonomy.json',
      );
      expect(packaged, contains('recycling-taxonomy-v1.0.0'));
      final service = RecyclingTaxonomyService();

      final resolution = await service.resolve(itemName: 'aluminum can');

      expect(resolution.version, isNotEmpty);
      expect(resolution.categoryId, equals('metal.aluminum'));
      expect(resolution.familyId, equals('metal'));
      expect(resolution.source, equals('unknown'));
    });

    test(
        'supports deterministic test catalogs without production fallback data',
        () async {
      final service = RecyclingTaxonomyService(
        fallbackJsonOverride: '{"version":"test-v1","families":['
            '{"id":"plastic","name":"Plastic"}],"categories":['
            '{"id":"plastic.pet","name":"PET","familyId":"plastic",'
            '"ricCodes":["pet"],"aliases":["bottle"],"signals":{}}],'
            '"fallbackCategoryIds":{}}',
      );

      final resolution = await service.resolve(itemName: 'bottle');

      expect(resolution.version, equals('test-v1'));
      expect(resolution.categoryId, equals('plastic.pet'));
    });

    test('degrades explicitly when the taxonomy asset is unavailable',
        () async {
      final service = RecyclingTaxonomyService(
        assetPath: 'assets/does-not-exist.json',
        allowDefaultAssetCandidates: false,
      );

      final resolution = await service.resolve(itemName: 'unknown item');

      expect(resolution.categoryId, isNull);
      expect(resolution.source, equals('taxonomy_unavailable'));
      expect(resolution.method, equals('asset_missing'));
      expect(resolution.confidence, equals(0));
    });
  });
}
