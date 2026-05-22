import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/education_card.dart';
import '../models/waste_classification.dart';
import '../data/seed_education_cards.dart';
import '../utils/constants.dart';

class EducationCardEngine {
  EducationCardEngine({
    List<WasteEducationCard>? seedCards,
    this.cooldownDays = 30,
  }) : _seedCards = seedCards ?? allSeedEducationCards;

  final List<WasteEducationCard> _seedCards;
  final int cooldownDays;

  static const _seenKey = 'seenEducationCards';

  static Map<String, SeenEducationCard> readSeenCards() {
    try {
      final box = Hive.box(StorageKeys.settingsBox);
      final raw = box.get(_seenKey, defaultValue: <String, dynamic>{});
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(
            k as String,
            SeenEducationCard.fromJson(
                v is String ? jsonDecode(v) as Map<String, dynamic> : v as Map<String, dynamic>)));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  static void persistSeenCard(SeenEducationCard card) {
    try {
      final box = Hive.box(StorageKeys.settingsBox);
      final raw = box.get(_seenKey, defaultValue: <String, dynamic>{});
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      map[card.cardId] = jsonEncode(card.toJson());
      box.put(_seenKey, map);
    } catch (_) {}
  }

  static void dismissCard(String cardId) {
    final seenCards = readSeenCards();
    final existing = seenCards[cardId];
    persistSeenCard(SeenEducationCard(
      cardId: cardId,
      lastSeen: DateTime.now(),
      dismissCount: (existing?.dismissCount ?? 0) + 1,
      permanentlyDismissed: existing?.permanentlyDismissed ?? false,
    ));
  }

  Set<String> currentCooldownIds() {
    final seenCards = readSeenCards();
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: cooldownDays));
    final ids = <String>{};
    for (final entry in seenCards.entries) {
      if (entry.value.permanentlyDismissed) {
        ids.add(entry.key);
      } else if (entry.value.lastSeen.isAfter(cutoff)) {
        ids.add(entry.key);
      }
    }
    return ids;
  }

  List<WasteEducationCard> cardsForClassification(
    WasteClassification classification,
    String region, {
    Set<String> excludeIds = const {},
  }) {
    final cat = classification.category.toLowerCase();
    final sub = classification.normalizedSubcategory?.toLowerCase();
    final materials = classification.normalizedMaterials
        .map((m) => m.toLowerCase())
        .toSet();

    final matches = <WasteEducationCard>[];

    for (final card in _seedCards) {
      if (excludeIds.contains(card.id)) continue;

      final regionMatch = card.applicableRegions.contains('all') ||
          card.applicableRegions.contains(region.toLowerCase());

      if (!regionMatch) continue;

      final catMatch = card.triggerCategories.any(
          (t) => t.toLowerCase() == cat);
      final subMatch = sub != null &&
          card.triggerSubcategories.any((t) => t.toLowerCase() == sub);
      final matMatch = materials.isNotEmpty &&
          card.triggerMaterials
              .any((t) => materials.contains(t.toLowerCase()));

      if (catMatch || subMatch || matMatch) {
        matches.add(card);
      }
    }

    matches.sort((a, b) => a.priority.compareTo(b.priority));
    return matches;
  }

  WasteEducationCard? bestCardFor(
    WasteClassification classification,
    String region, {
    Set<String> excludeIds = const {},
  }) {
    final matches = cardsForClassification(
      classification,
      region,
      excludeIds: excludeIds,
    );
    return matches.isNotEmpty ? matches.first : null;
  }

  WasteEducationCard? cardById(String id) {
    for (final card in _seedCards) {
      if (card.id == id) return card;
    }
    return null;
  }
}
