import 'dart:typed_data';

// ignore_for_file: depend_on_referenced_packages

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/offline_queue_service.dart';

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
    analyticsEvents.clear();
  });

  group('OfflineQueueService', () {
    test('isOffline reports true when connectivity is none', () async {
      expect(await queueService.isOffline, isTrue);
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
      });

      final pending = queueService.getPendingItems();
      expect(pending, hasLength(1));
      expect(pending.single.region, 'BBMP');
      expect(pending.single.userId, 'user-1');
      expect(pending.single.imageName, 'glass-bottle.jpg');
      expect(pending.single.imageBytes, imageBytes);
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
      });
      expect(analyticsEvents, hasLength(2));
      expect(analyticsEvents.last['eventName'], 'queue_cleared');
    });
  });
}
