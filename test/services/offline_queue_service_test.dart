// ignore_for_file: depend_on_referenced_packages

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/offline_queue_service.dart';

const _kPathProviderChannel = 'plugins.flutter.io/path_provider';

class _OfflineConnectivityPlatform extends ConnectivityPlatform {
  _OfflineConnectivityPlatform();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.none];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream<List<ConnectivityResult>>.empty();
}

void main() {
  late ConnectivityPlatform originalPlatform;
  final queueService = OfflineQueueService();
  final analyticsEvents = <Map<String, dynamic>>[];

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // PRIVACY-09: Mock path_provider for QueueImageStorage temp directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(_kPathProviderChannel),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return '/tmp/test_queue_images';
        }
        return null;
      },
    );
    Hive.init('.');
    originalPlatform = ConnectivityPlatform.instance;
    ConnectivityPlatform.instance = _OfflineConnectivityPlatform();
    OfflineQueueService.analyticsTrackerOverride = ({
      required String eventType,
      required String eventName,
      Map<String, dynamic> parameters = const {},
    }) async {
      analyticsEvents.add({
        'eventType': eventType,
        'eventName': eventName,
        'parameters': parameters,
      });
    };
  });

  tearDownAll(() {
    ConnectivityPlatform.instance = originalPlatform;
    OfflineQueueService.analyticsTrackerOverride = null;
    queueService.dispose();
  });

  setUp(() async {
    await queueService.init();
    await queueService.clearQueue();
    // Keep both boxes clean between tests (dead-letter migration tests
    // leave migrated records behind).
    await queueService.clearDeadLetterQueue();
    analyticsEvents.clear();
  });

  group('OfflineQueueService', () {
    test('isOffline reports true when connectivity is none', () async {
      expect(await queueService.isOffline, isTrue);
    });

    test('legacy-format items are read and migrated without crashing',
        () async {
      final legacyBytes = Uint8List.fromList([11, 22, 33, 44, 55]);

      // Simulate a genuine pre-migration Hive record: raw bytes at field 1,
      // no file-reference fields, no expiry metadata.
      final box = Hive.box<QueuedClassification>('classification_queue');
      await box.put(
        'legacy-item',
        QueuedClassification(
          id: 'legacy-item',
          imageBytes: legacyBytes,
          region: 'BBMP',
          queuedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );

      // Reading the legacy record must not throw (imageRefPath was String in
      // the broken schema; the corrected schema keeps Uint8List at field 1).
      final readBack = box.get('legacy-item')!;
      expect(readBack.isLegacyFormat, isTrue);
      expect(readBack.imageBytes, equals(legacyBytes));
      expect(await readBack.readImageBytes(), equals(legacyBytes));

      // Migration must move bytes to a file reference and assign an expiry.
      await queueService.runLegacyMigrationForTesting();
      final migrated = box.get('legacy-item')!;
      expect(migrated.isLegacyFormat, isFalse);
      expect(migrated.imageBytes, isNull);
      expect(migrated.imageRefPath, isNotNull);
      expect(migrated.imageRefPath, isNotEmpty);
      expect(migrated.imageRefByteLength, equals(legacyBytes.length));
      expect(migrated.expiresAt, isNotNull);
      expect(await migrated.readImageBytes(), equals(legacyBytes));
    });

    test('legacy-format dead-letter items are migrated without crashing',
        () async {
      final legacyBytes = Uint8List.fromList([66, 77, 88, 99]);

      // Simulate a pre-migration dead-letter record: raw bytes at field 1,
      // no file-reference fields, no expiry metadata.
      final deadLetterBox =
          Hive.box<DeadLetterClassification>('classification_dead_letter');
      await deadLetterBox.put(
        'legacy-dead-letter',
        DeadLetterClassification(
          id: 'legacy-dead-letter',
          imageBytes: legacyBytes,
          region: 'BBMP',
          queuedAt: DateTime.now().subtract(const Duration(hours: 2)),
          failedAt: DateTime.now().subtract(const Duration(hours: 1)),
          retryCount: 3,
          lastError: '[redacted]',
        ),
      );

      // Reading must not throw and must detect legacy format.
      final readBack = deadLetterBox.get('legacy-dead-letter')!;
      expect(readBack.isLegacyFormat, isTrue);
      expect(readBack.imageBytes, equals(legacyBytes));

      // Migration must move bytes to a file reference and assign expiry.
      await queueService.runLegacyMigrationForTesting();
      final migrated = deadLetterBox.get('legacy-dead-letter')!;
      expect(migrated.isLegacyFormat, isFalse);
      expect(migrated.imageBytes, isNull);
      expect(migrated.imageRefPath, isNotNull);
      expect(migrated.imageRefPath, isNotEmpty);
      expect(migrated.imageRefByteLength, equals(legacyBytes.length));
      expect(migrated.expiresAt, isNotNull);
      expect(await migrated.readImageBytes(), equals(legacyBytes));
    });

    test('legacy items whose migration failed still expire by age', () async {
      // A legacy record whose writeImage failed during migration stays
      // isLegacyFormat with expiresAt == null. PRIVACY-09 requires these to
      // expire by age (queuedAt) so raw bytes never linger in Hive forever.
      final box = Hive.box<QueuedClassification>('classification_queue');
      await box.put(
        'legacy-stuck',
        QueuedClassification(
          id: 'legacy-stuck',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          region: 'BBMP',
          queuedAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      );

      // Force expiry by age even without expiresAt metadata.
      await queueService.runExpiryForTesting();

      expect(box.get('legacy-stuck'), isNull);
      expect(queueService.pendingCount, 0);
    });

    test('legacy dead-letter items whose migration failed expire by failedAt',
        () async {
      // Symmetric branch: dead-letter legacy items age-expire using failedAt
      // vs the 72h dead-letter limit.
      final deadLetterBox =
          Hive.box<DeadLetterClassification>('classification_dead_letter');
      await deadLetterBox.put(
        'legacy-deadletter-stuck',
        DeadLetterClassification(
          id: 'legacy-deadletter-stuck',
          imageBytes: Uint8List.fromList([7, 8, 9]),
          region: 'BBMP',
          queuedAt: DateTime.now().subtract(const Duration(hours: 80)),
          failedAt: DateTime.now().subtract(const Duration(hours: 73)),
          retryCount: 3,
          lastError: '[redacted]',
        ),
      );

      await queueService.runExpiryForTesting();

      expect(deadLetterBox.get('legacy-deadletter-stuck'), isNull);
      expect(queueService.getQueueStats()['deadLetter'], 0);
    });

    test('retryDeadLetter preserves legacy imageBytes for unmigrated items',
        () async {
      final legacyBytes = Uint8List.fromList([21, 22, 23, 24]);
      final deadLetterBox =
          Hive.box<DeadLetterClassification>('classification_dead_letter');
      await deadLetterBox.put(
        'legacy-retry',
        DeadLetterClassification(
          id: 'legacy-retry',
          imageBytes: legacyBytes,
          region: 'BBMP',
          queuedAt: DateTime.now().subtract(const Duration(hours: 2)),
          failedAt: DateTime.now().subtract(const Duration(hours: 1)),
          retryCount: 3,
          lastError: '[redacted]',
        ),
      );

      final retried = await queueService.retryDeadLetter('legacy-retry');
      expect(retried, isTrue);
      expect(deadLetterBox.get('legacy-retry'), isNull);

      // setUp guarantees an empty queue, so the retried item is the only one.
      final queued = queueService.getPendingItems().single;
      // A legacy dead-letter item retried back into the queue keeps its raw
      // bytes (isLegacyFormat true) so they are not lost before migration.
      expect(queued.isLegacyFormat, isTrue);
      expect(await queued.readImageBytes(), equals(legacyBytes));
    });

    test('queue stores a classification and emits analytics', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      await queueService.queue(
        imageBytes: imageBytes,
        region: 'BBMP',
        userId: 'user-1',
        imageName: 'glass-bottle.jpg',
      );

      expect(queueService.pendingCount, 1);
      expect(queueService.getQueueStats(), {
        'totalQueued': 1,
        'processed': 0,
        'pending': 1,
        'deadLetter': 0,
      });

      final pending = queueService.getPendingItems();
      expect(pending, hasLength(1));
      expect(pending.single.region, 'BBMP');
      expect(pending.single.userId, 'user-1');
      expect(pending.single.imageName, 'glass-bottle.jpg');
      // PRIVACY-09: imageBytes is now stored as a file reference, not raw bytes
      expect(pending.single.imageRefPath, isNotNull);
      expect(pending.single.imageRefPath, isNotEmpty);
      expect(pending.single.imageRefByteLength, equals(imageBytes.length));
      expect(pending.single.isLegacyFormat, isFalse);
      expect(analyticsEvents, hasLength(1));
      expect(analyticsEvents.single['eventName'], 'queued_offline');
    });

    test('clearQueue removes pending items and emits analytics', () async {
      await queueService.queue(
        imageBytes: Uint8List.fromList([9, 8, 7]),
        region: 'Test Region',
        imageName: 'queued-item.jpg',
      );

      expect(queueService.pendingCount, 1);

      await queueService.clearQueue();

      expect(queueService.pendingCount, 0);
      expect(queueService.getPendingItems(), isEmpty);
      expect(queueService.getQueueStats(), {
        'totalQueued': 0,
        'processed': 0,
        'pending': 0,
        'deadLetter': 0,
      });
      expect(analyticsEvents, hasLength(2));
      expect(analyticsEvents.last['eventName'], 'queue_cleared');
    });
  });
}
