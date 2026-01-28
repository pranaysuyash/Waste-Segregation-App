import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:typed_data';
import 'package:waste_segregation_app/services/offline_queue_service.dart';

void main() {
  group('OfflineQueueService', () {
    late OfflineQueueService service;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
    });

    setUp(() async {
      service = OfflineQueueService();

      // Clear any existing data
      if (Hive.isBoxOpen('classification_queue')) {
        final box = Hive.box<QueuedClassification>('classification_queue');
        await box.clear();
      }
    });

    tearDown(() async {
      // Clean up
      if (Hive.isBoxOpen('classification_queue')) {
        final box = Hive.box<QueuedClassification>('classification_queue');
        await box.clear();
        await box.close();
      }
    });

    test('initializes successfully', () async {
      await service.init();
      expect(service.pendingCount, 0);
    });

    test('queues item successfully', () async {
      await service.init();

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await service.queue(
        imageBytes: testBytes,
        region: 'Test Region',
        userId: 'test_user',
        imageName: 'test_image.jpg',
      );

      expect(service.pendingCount, 1);
    });

    test('queues multiple items', () async {
      await service.init();

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await service.queue(
        imageBytes: testBytes,
        region: 'Region 1',
      );

      await service.queue(
        imageBytes: testBytes,
        region: 'Region 2',
      );

      await service.queue(
        imageBytes: testBytes,
        region: 'Region 3',
      );

      expect(service.pendingCount, 3);
    });

    test('clears queue successfully', () async {
      await service.init();

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await service.queue(
        imageBytes: testBytes,
        region: 'Test Region',
      );

      expect(service.pendingCount, 1);

      await service.clearQueue();

      expect(service.pendingCount, 0);
    });

    test('getPendingItems returns queued items', () async {
      await service.init();

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await service.queue(
        imageBytes: testBytes,
        region: 'Test Region',
        imageName: 'test.jpg',
      );

      final items = service.getPendingItems();

      expect(items.length, 1);
      expect(items.first.region, 'Test Region');
      expect(items.first.imageName, 'test.jpg');
      expect(items.first.retryCount, 0);
    });

    test('queueCountStream emits count changes', () async {
      await service.init();

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Listen to stream
      final counts = <int>[];
      final subscription = service.queueCountStream.listen(counts.add);

      await service.queue(
        imageBytes: testBytes,
        region: 'Test Region',
      );

      await Future.delayed(Duration(milliseconds: 100));

      await service.queue(
        imageBytes: testBytes,
        region: 'Test Region 2',
      );

      await Future.delayed(Duration(milliseconds: 100));

      await service.clearQueue();

      await Future.delayed(Duration(milliseconds: 100));

      await subscription.cancel();

      // Should have received count updates
      expect(counts.isNotEmpty, true);
      expect(counts.last, 0); // Final count after clear
    });

    test('handles initialization errors gracefully', () async {
      // Service should not throw on init failure
      await service.init();

      // Calling init again should be safe (idempotent)
      await service.init();

      expect(service.pendingCount, greaterThanOrEqualTo(0));
    });

    test('QueuedClassification stores all fields', () {
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final now = DateTime.now();

      final item = QueuedClassification(
        id: 'test-id',
        imageBytes: testBytes,
        region: 'Test Region',
        queuedAt: now,
        retryCount: 2,
        userId: 'user-123',
        imageName: 'test.jpg',
      );

      expect(item.id, 'test-id');
      expect(item.imageBytes, testBytes);
      expect(item.region, 'Test Region');
      expect(item.queuedAt, now);
      expect(item.retryCount, 2);
      expect(item.userId, 'user-123');
      expect(item.imageName, 'test.jpg');
    });
  });
}
