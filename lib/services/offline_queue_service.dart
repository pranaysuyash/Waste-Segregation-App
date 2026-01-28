import 'dart:async';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/waste_classification.dart';
import 'enhanced_ai_api_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import '../utils/waste_app_logger.dart';

part 'offline_queue_service.g.dart';

/// Queued classification for offline processing
@HiveType(typeId: 100)
class QueuedClassification extends HiveObject {
  QueuedClassification({
    required this.id,
    required this.imageBytes,
    required this.region,
    required this.queuedAt,
    this.retryCount = 0,
    this.userId,
    this.imageName,
  });
  @HiveField(0)
  String id;

  @HiveField(1)
  Uint8List imageBytes;

  @HiveField(2)
  String region;

  @HiveField(3)
  DateTime queuedAt;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  String? imageName;
}

/// Service for managing offline classification queue
///
/// Features:
/// - Automatically queues classifications when offline
/// - Processes queue when connectivity returns
/// - Retries failed items up to 3 times
/// - Provides queue status stream for UI updates
/// - Fail-safe: handles errors gracefully without blocking user
class OfflineQueueService {
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();
  static final OfflineQueueService _instance = OfflineQueueService._internal();

  Box<QueuedClassification>? _queueBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;
  bool _isInitialized = false;

  final _queueCountController = StreamController<int>.broadcast();
  Stream<int> get queueCountStream => _queueCountController.stream;

  /// Initialize the service - call once at app startup
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(100)) {
        Hive.registerAdapter(QueuedClassificationAdapter());
      }

      _queueBox =
          await Hive.openBox<QueuedClassification>('classification_queue');

      // Emit initial count
      _queueCountController.add(_queueBox!.length);

      // Listen for connectivity changes
      _connectivitySub =
          Connectivity().onConnectivityChanged.listen((results) {
        final isOnline =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
        if (isOnline && !_isProcessing) {
          _processQueue();
        }
      });

      // Process queue if we're already online
      final current = await Connectivity().checkConnectivity();
      final isOnline =
          current.isNotEmpty && !current.contains(ConnectivityResult.none);
      if (isOnline) {
        _processQueue();
      }

      _isInitialized = true;

      WasteAppLogger.info('Offline queue service initialized', context: {
        'pending_items': _queueBox!.length,
      });
    } catch (e, stackTrace) {
      WasteAppLogger.severe(
        'Failed to initialize offline queue service',
        error: e,
        stackTrace: stackTrace,
      );

      // Don't mark as initialized on failure - allow retry
      rethrow;
    }
  }

  /// Check if device is currently offline
  Future<bool> get isOffline async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isEmpty || results.contains(ConnectivityResult.none);
    } catch (e) {
      // If connectivity check fails, assume online (fail-safe)
      return false;
    }
  }

  /// Queue a classification for later processing
  Future<void> queue({
    required Uint8List imageBytes,
    required String region,
    String? userId,
    String? imageName,
  }) async {
    if (!_isInitialized) await init();

    if (_queueBox == null) {
      WasteAppLogger.warning(
        'Offline queue unavailable; skipping enqueue',
      );
      return;
    }

    try {
      final item = QueuedClassification(
        id: const Uuid().v4(),
        imageBytes: imageBytes,
        region: region,
        queuedAt: DateTime.now(),
        userId: userId,
        imageName:
            imageName ?? 'offline_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _queueBox!.put(item.id, item);
      _queueCountController.add(_queueBox!.length);

      WasteAppLogger.info('Classification queued for offline processing',
          context: {
            'queue_id': item.id,
            'queue_length': _queueBox!.length,
            'image_size_kb': (imageBytes.length / 1024).toStringAsFixed(1),
          });

      AnalyticsService().trackEvent(
        eventType: 'classification',
        eventName: 'queued_offline',
        parameters: {
          'queue_size': _queueBox!.length,
        },
      );
    } catch (e, stackTrace) {
      WasteAppLogger.severe(
        'Failed to queue classification',
        error: e,
        stackTrace: stackTrace,
      );

      // Don't throw - fail gracefully
    }
  }

  /// Get number of pending items in queue
  int get pendingCount => _queueBox?.length ?? 0;

  /// Process all queued items (called automatically when online)
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    if (_queueBox == null || _queueBox!.isEmpty) return;

    _isProcessing = true;

    WasteAppLogger.info('Processing offline queue', context: {
      'pending_items': _queueBox!.length,
    });

    final startTime = DateTime.now();
    final items = _queueBox!.values.toList();
    var successCount = 0;
    var failCount = 0;
    var permanentFailCount = 0;

    for (final item in items) {
      try {
        // Check connectivity before each item
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity.isEmpty ||
            connectivity.contains(ConnectivityResult.none)) {
          WasteAppLogger.info(
              'Lost connectivity during queue processing, pausing');
          break;
        }

        // Process the classification
        WasteAppLogger.info('Processing queued item', context: {
          'queue_id': item.id,
          'retry_count': item.retryCount,
          'queued_at': item.queuedAt.toIso8601String(),
        });

        final result = await EnhancedAiApiService().analyzeWasteImage(
          imageBytes: item.imageBytes,
          imageName: item.imageName ?? 'offline_item',
          region: item.region,
        );

        // Save to local storage
        await StorageService().saveClassification(result);

        // Remove from queue
        await item.delete();
        successCount++;

        WasteAppLogger.info('Queue item processed successfully', context: {
          'queue_id': item.id,
          'item_name': result.itemName,
          'category': result.category,
        });

        // Optional: Show notification
        // await _notifyCompletion(result);
      } catch (e, stackTrace) {
        item.retryCount++;

        WasteAppLogger.warning(
          'Failed to process queue item',
          error: e,
          stackTrace: stackTrace,
          context: {
            'queue_id': item.id,
            'retry_count': item.retryCount,
          },
        );

        if (item.retryCount >= 3) {
          // Give up after 3 retries
          await item.delete();
          permanentFailCount++;

          AnalyticsService().trackEvent(
            eventType: 'classification',
            eventName: 'queue_permanent_fail',
            parameters: {
              'retry_count': item.retryCount,
              'error': e.toString(),
            },
          );
        } else {
          // Save updated retry count
          await item.save();
          failCount++;
        }
      }
    }

    _queueCountController.add(_queueBox!.length);
    _isProcessing = false;

    final duration = DateTime.now().difference(startTime);

    WasteAppLogger.info('Queue processing complete', context: {
      'duration_seconds': duration.inSeconds,
      'success_count': successCount,
      'fail_count': failCount,
      'permanent_fail_count': permanentFailCount,
      'remaining': _queueBox!.length,
    });

    AnalyticsService().trackEvent(
      eventType: 'classification',
      eventName: 'queue_processed',
      parameters: {
        'success': successCount,
        'failed': failCount,
        'permanent_failures': permanentFailCount,
        'duration_seconds': duration.inSeconds,
      },
    );
  }

  /// Force retry all pending items (user-initiated)
  Future<void> forceRetry() async {
    if (!_isInitialized) await init();
    if (pendingCount == 0) return;

    WasteAppLogger.info('Force retry requested', context: {
      'pending_count': pendingCount,
    });

    // Reset retry counts
    for (final item in _queueBox!.values) {
      item.retryCount = 0;
      await item.save();
    }

    // Process queue
    await _processQueue();
  }

  /// Clear all pending items (user-initiated cancellation)
  Future<void> clearQueue() async {
    if (!_isInitialized) await init();

    final count = pendingCount;
    await _queueBox?.clear();
    _queueCountController.add(0);

    WasteAppLogger.info('Queue cleared', context: {
      'items_cleared': count,
    });

    AnalyticsService().trackEvent(
      eventType: 'classification',
      eventName: 'queue_cleared',
      parameters: {
        'items_cleared': count,
      },
    );
  }

  /// Get list of pending items (for UI display)
  List<QueuedClassification> getPendingItems() {
    if (!_isInitialized || _queueBox == null) return [];
    return _queueBox!.values.toList();
  }

  /// Get queue statistics for impact dashboard
  Map<String, int> getQueueStats() {
    if (!_isInitialized || _queueBox == null) {
      return {
        'totalQueued': 0,
        'processed': 0,
        'pending': 0,
      };
    }
    
    // Note: We only track pending items in the queue box
    // Processed items are removed from the queue
    final pending = _queueBox!.length;
    
    return {
      'totalQueued': pending, // Only pending items remain in queue
      'processed': 0, // Processed items are removed
      'pending': pending,
    };
  }

  /// Dispose resources
  void dispose() {
    _connectivitySub?.cancel();
    _queueCountController.close();
  }
}
