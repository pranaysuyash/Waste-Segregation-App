import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  late StorageService storageService;

  setUpAll(() async {
    Hive.init('.');
    await Hive.openBox(StorageKeys.settingsBox);
  });

  setUp(() async {
    storageService = StorageService();
    await Hive.box(StorageKeys.settingsBox).clear();
  });

  group('StorageService boundary', () {
    test('saveSettings updates the canonical settings map and legacy flags',
        () async {
      final timestamp = DateTime(2026, 5, 21, 10, 30);

      await storageService.saveSettings(
        isDarkMode: true,
        isGoogleSyncEnabled: false,
        lastCloudSync: timestamp,
        allowHistoryFeedback: false,
        feedbackTimeframeDays: 14,
        notifications: false,
      );

      final settingsBox = Hive.box(StorageKeys.settingsBox);
      final settings = Map<String, dynamic>.from(settingsBox.get('settings'));

      expect(settings['isDarkMode'], isTrue);
      expect(settings['isGoogleSyncEnabled'], isFalse);
      expect(settings['lastCloudSync'], timestamp.toIso8601String());
      expect(settings['allowHistoryFeedback'], isFalse);
      expect(settings['feedbackTimeframeDays'], 14);
      expect(settings['notifications'], isFalse);
      expect(settingsBox.get(StorageKeys.isDarkModeKey), isTrue);
      expect(settingsBox.get(StorageKeys.isGoogleSyncEnabledKey), isFalse);
    });

    test('updateLastCloudSync writes a parseable canonical timestamp', () async {
      final timestamp = DateTime(2026, 5, 22, 8, 15);

      await storageService.saveSettings(
        isDarkMode: false,
        isGoogleSyncEnabled: true,
      );
      await storageService.updateLastCloudSync(timestamp);

      final settingsBox = Hive.box(StorageKeys.settingsBox);
      final settings = Map<String, dynamic>.from(settingsBox.get('settings'));

      expect(settings['lastCloudSync'], timestamp.toIso8601String());
      expect(await storageService.getLastCloudSync(), timestamp);
    });
  });
}
