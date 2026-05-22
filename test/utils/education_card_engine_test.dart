import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waste_segregation_app/data/seed_education_cards.dart';
import 'package:waste_segregation_app/models/education_card.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/education_card_engine.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('EducationCardEngine', () {
    late EducationCardEngine engine;

    setUp(() {
      engine = EducationCardEngine(seedCards: allSeedEducationCards);
    });

    group('cardsForClassification', () {
      test('matches by category (dry waste)', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Plastic',
          materials: ['plastic'],
        );
        final cards = engine.cardsForClassification(classification, 'bangalore');
        expect(cards, isNotEmpty);
        expect(
          cards.any((c) => c.id == 'edu_rinsing_matters'),
          isTrue,
          reason: 'Should match plastic subcategory in dry waste',
        );
        expect(
          cards.any((c) => c.id == 'bbmp_dry_days'),
          isTrue,
          reason: 'Should match dry waste category in Bangalore',
        );
      });

      test('matches by subcategory (plastic)', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Plastic',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        final ids = cards.map((c) => c.id).toSet();
        expect(ids.contains('edu_rinsing_matters'), isTrue);
        expect(ids.contains('impact_plastic_savings'), isTrue);
        expect(ids.contains('mistake_containers_with_food'), isTrue);
      });

      test('matches by material (cardboard)', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Paper',
          materials: ['cardboard'],
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(
          cards.any((c) => c.id == 'edu_greasy_cardboard'),
          isTrue,
        );
      });

      test('matches hazardous waste for battery subcategory', () {
        final classification = _makeClassification(
          category: 'Hazardous Waste',
          subCategory: 'Battery',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(
          cards.any((c) => c.id == 'edu_battery_dropoff'),
          isTrue,
        );
      });

      test('matches e-waste for electronic category', () {
        final classification = _makeClassification(
          category: 'E-Waste',
          subCategory: 'Electronic',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(cards.any((c) => c.id == 'edu_ewhat_is_ewaste'), isTrue);
        expect(cards.any((c) => c.id == 'alt_old_phones'), isTrue);
      });

      test('matches wet waste for composting impact card', () {
        final classification = _makeClassification(
          category: 'Wet Waste',
          subCategory: 'Food Waste',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(cards.any((c) => c.id == 'impact_compost_co2'), isTrue);
      });

      test('matches textile material for clothes donation card', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Textile',
          materials: ['textile'],
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(cards.any((c) => c.id == 'alt_clothes_donate'), isTrue);
      });

      test('excludes dismissed card IDs', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Plastic',
        );
        final cards = engine.cardsForClassification(
          classification,
          'all',
          excludeIds: {'edu_rinsing_matters'},
        );
        expect(cards.any((c) => c.id == 'edu_rinsing_matters'), isFalse);
      });

      test('filters by region (Bangalore-only cards)', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
        );
        final bangaloreCards =
            engine.cardsForClassification(classification, 'bangalore');
        expect(
          bangaloreCards.any((c) => c.id == 'bbmp_dry_days'),
          isTrue,
          reason: 'Bangalore card should match in Bangalore',
        );

        final mumbaiCards =
            engine.cardsForClassification(classification, 'mumbai');
        expect(
          mumbaiCards.any((c) => c.id == 'bbmp_dry_days'),
          isFalse,
          reason: 'Bangalore-only card should not match in Mumbai',
        );
      });

      test('returns cards sorted by priority', () {
        final classification = _makeClassification(
          category: 'Dry Waste',
          subCategory: 'Plastic',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        for (var i = 1; i < cards.length; i++) {
          expect(
            cards[i - 1].priority <= cards[i].priority,
            isTrue,
            reason:
                'Card at index ${i - 1} (${cards[i - 1].id}, priority ${cards[i - 1].priority}) '
                'should sort before index $i (${cards[i].id}, priority ${cards[i].priority})',
          );
        }
      });

      test('returns empty for unknown category with no matches', () {
        final classification = _makeClassification(
          category: 'Unicorn Horns',
          subCategory: 'Magic Dust',
        );
        final cards = engine.cardsForClassification(classification, 'all');
        expect(cards, isEmpty);
      });

      test('matches multiple triggerCategories using alternate names', () {
        final hazardous = _makeClassification(category: 'Hazardous');
        final hazWaste = _makeClassification(category: 'Hazardous Waste');

        final hCards = engine.cardsForClassification(hazardous, 'all');
        final hwCards = engine.cardsForClassification(hazWaste, 'all');

        // Both should match the same cards (triggerCategories includes both)
        expect(
          hCards.any((c) => c.id == 'edu_battery_dropoff'),
          isTrue,
          reason: 'edu_battery_dropoff has triggerCategories: [hazardous, hazardous waste]',
        );
        expect(
          hwCards.any((c) => c.id == 'edu_battery_dropoff'),
          isTrue,
          reason: 'Should also match "Hazardous Waste"',
        );
      });
    });

    group('bestCardFor', () {
      test('returns null when no cards match', () {
        final classification = _makeClassification(
          category: 'Unrelated',
          subCategory: 'None',
        );
        final card = engine.bestCardFor(classification, 'all');
        expect(card, isNull);
      });

      test('returns the highest-priority matching card', () {
        final classification = _makeClassification(
          category: 'Hazardous Waste',
          subCategory: 'Battery',
        );
        final card = engine.bestCardFor(classification, 'all');
        expect(card, isNotNull);
        // edu_battery_dropoff has priority 5 (lowest = highest priority in this set)
        expect(card!.id, 'edu_battery_dropoff');
      });

      test('excludes dismissed cards from best match', () {
        final classification = _makeClassification(
          category: 'Hazardous Waste',
          subCategory: 'Battery',
        );
        final card = engine.bestCardFor(
          classification,
          'all',
          excludeIds: {'edu_battery_dropoff'},
        );
        // Next best in hazardous category should be bbmp_hazardous_kspcb
        // (only if region is bangalore)
        final bangaloreCard = engine.bestCardFor(
          classification,
          'bangalore',
          excludeIds: {'edu_battery_dropoff'},
        );
        expect(bangaloreCard, isNotNull);
        expect(bangaloreCard!.id, 'bbmp_hazardous_kspcb');
      });
    });

    group('cardById', () {
      test('finds existing card by ID', () {
        final card = engine.cardById('edu_rinsing_matters');
        expect(card, isNotNull);
        expect(card!.title, 'Rinse before you recycle');
      });

      test('returns null for unknown ID', () {
        final card = engine.cardById('non_existent_card');
        expect(card, isNull);
      });
    });

    group('card rotation', () {
      setUp(() async {
        final dir = '/tmp/test_hive_${DateTime.now().millisecondsSinceEpoch}';
        Hive.init(dir);
        await Hive.openBox(StorageKeys.settingsBox);
      });

      tearDown(() {
        try {
          Hive.deleteBoxFromDisk(StorageKeys.settingsBox);
        } catch (_) {}
      });

      test('dismissCard records lastSeen and increments dismissCount', () {
        EducationCardEngine.dismissCard('edu_rinsing_matters');
        final seen = EducationCardEngine.readSeenCards();
        final entry = seen['edu_rinsing_matters'];
        expect(entry, isNotNull);
        expect(entry!.dismissCount, 1);
        expect(
          entry.lastSeen.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5),
        );

        EducationCardEngine.dismissCard('edu_rinsing_matters');
        final seen2 = EducationCardEngine.readSeenCards();
        expect(seen2['edu_rinsing_matters']!.dismissCount, 2);
      });

      test('currentCooldownIds returns recently dismissed cards', () {
        EducationCardEngine.dismissCard('edu_rinsing_matters');
        final cooldown = engine.currentCooldownIds();
        expect(cooldown.contains('edu_rinsing_matters'), isTrue);
      });
    });

    group('seed data integrity', () {
      test('all seed cards have unique IDs', () {
        final ids = allSeedEducationCards.map((c) => c.id).toList();
        expect(ids.toSet().length, ids.length);
      });

      test('all seed cards have non-empty title and body', () {
        for (final card in allSeedEducationCards) {
          expect(card.title.trim(), isNotEmpty,
              reason: 'Card ${card.id} has empty title');
          expect(card.body.trim(), isNotEmpty,
              reason: 'Card ${card.id} has empty body');
          expect(card.iconName.trim(), isNotEmpty,
              reason: 'Card ${card.id} has empty iconName');
        }
      });

      test('all seed cards have at least one trigger', () {
        for (final card in allSeedEducationCards) {
          expect(
            card.triggerCategories.isNotEmpty ||
                card.triggerMaterials.isNotEmpty ||
                card.triggerSubcategories.isNotEmpty,
            isTrue,
            reason: 'Card ${card.id} has no triggers',
          );
        }
      });

      test('all region-specific cards have applicableRegions set', () {
        for (final card in allSeedEducationCards) {
          if (card.variant == EducationCardVariant.localRule) {
            expect(
              card.applicableRegions.length == 1 &&
                  !card.applicableRegions.contains('all'),
              isTrue,
              reason:
                  'LocalRule card ${card.id} should have a specific region',
            );
          }
        }
      });

      test('extended cards have relatedCardIds that exist in seed data', () {
        final allIds = allSeedEducationCards.map((c) => c.id).toSet();
        for (final card in allSeedEducationCards) {
          if (card.relatedCardIds != null) {
            for (final relatedId in card.relatedCardIds!) {
              expect(
                allIds.contains(relatedId),
                isTrue,
                reason:
                    'Card ${card.id} references non-existent relatedCardId: $relatedId',
              );
            }
          }
        }
      });
    });
  });
}

WasteClassification _makeClassification({
  String category = 'Dry Waste',
  String subCategory = 'Plastic',
  List<String> materials = const ['plastic'],
}) {
  return WasteClassification(
    id: 'test-id',
    itemName: 'Test Item',
    category: category,
    subCategory: subCategory,
    materials: materials,
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    region: 'Bangalore, IN',
    visualFeatures: [],
    alternatives: [
      AlternativeClassification(
        category: 'Dry Waste',
        confidence: 0.5,
        reason: 'Test',
      ),
    ],
  );
}
