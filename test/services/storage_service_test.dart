import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

WasteClassification _classification({String itemName = 'Plastic Bottle'}) {
  return WasteClassification(
    itemName: itemName,
    category: 'Dry Waste',
    subCategory: 'Plastic',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Sort'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['plastic', 'bottle'],
    alternatives: [
      AlternativeClassification(
        category: 'Plastic',
        confidence: 0.2,
        reason: 'fallback',
      ),
    ],
    confidence: 0.95,
  );
}

void main() {
  late StorageService storageService;

  setUpAll(() async {
    Hive.init('.');
  });

  tearDownAll(() async {
    // Shared Hive root left open intentionally for the rest of the suite.
  });

  setUp(() async {
    storageService = StorageService();
    await (await Hive.openBox(StorageKeys.settingsBox)).clear();
    await (await Hive.openBox(StorageKeys.cacheBox)).clear();
  });

  group('StorageService', () {
    test('getSettings returns defaults on a fresh box', () async {
      final settings = await storageService.getSettings();

      expect(settings['isGoogleSyncEnabled'], isTrue);
      expect(settings['notifications'], isTrue);
      expect(settings['allowHistoryFeedback'], isTrue);
      expect(settings['feedbackTimeframeDays'], 7);
    });

    test('saveSettings persists updated values and last sync', () async {
      final timestamp = DateTime(2026, 5, 21, 10, 30);

      await storageService.saveSettings(
        isDarkMode: true,
        isGoogleSyncEnabled: false,
        lastCloudSync: timestamp,
        allowHistoryFeedback: false,
        feedbackTimeframeDays: 14,
        notifications: false,
      );

      final settings = await storageService.getSettings();
      expect(settings['isDarkMode'], isTrue);
      expect(settings['isGoogleSyncEnabled'], isFalse);
      expect(settings['lastCloudSync'], timestamp.toIso8601String());
      expect(settings['allowHistoryFeedback'], isFalse);
      expect(settings['feedbackTimeframeDays'], 14);
      expect(settings['notifications'], isFalse);
    });

    test('updateLastCloudSync ignores timestamps far in the future', () async {
      await storageService.saveSettings(
        isDarkMode: false,
        isGoogleSyncEnabled: true,
      );
      final before = await storageService.getLastCloudSync();

      await storageService.updateLastCloudSync(
        DateTime.now().add(const Duration(hours: 2)),
      );

      expect(await storageService.getLastCloudSync(), before);
    });

    test('cached classification round trip uses JSON cache box', () async {
      final classification = _classification(itemName: 'Glass Jar');

      await storageService.saveCachedClassification(
          'cache-key-1', classification);

      final restored =
          await storageService.getCachedClassification('cache-key-1');

      expect(restored, isNotNull);
      expect(restored!.itemName, classification.itemName);
      expect(restored.category, classification.category);
    });

    test('clearClassifications closes the legacy classifications box',
        () async {
      final classificationsBox =
          await Hive.openBox<WasteClassification>('classifications');

      await storageService.clearClassifications();

      expect(classificationsBox.isOpen, isFalse);
    });
  });
}
