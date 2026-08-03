import 'dart:async';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'queue_image_storage.dart';
import 'storage_service.dart';
import 'cloud_storage_service.dart';
import 'token_service.dart';
import 'scan_orchestrator.dart';
import '../models/token_wallet.dart';
import 'analytics_service.dart';
import '../utils/waste_app_logger.dart';
import '../utils/production_safety_config.dart';

part 'offline_queue_service.g.dart';

/// Typed failure classification — never inspect error message strings
/// for core routing decisions.
enum QueueItemFailureType {
  retryableNetwork,
  authentication,
  insufficientCredits,
  permanentInvalidImage,
  configurationSafety,
  userCancellation,
  privacyRejection,
  unknown,
}

/// PRIVACY-09: Maximum age for active queue items before auto-expiry.
const Duration kQueueRetentionLimit = Duration(hours: 24);

/// PRIVACY-09: Maximum age for dead-letter items before auto-expiry.
const Duration kDeadLetterRetentionLimit = Duration(hours: 72);

/// PRIVACY-09: Redacted error placeholder — never store raw error strings
/// in analytics or dead-letter records.
const String kRedactedError = '[redacted]';

typedef OfflineQueueAnalyticsTracker = Future<void> Function({
  required String eventType,
  required String eventName,
  Map<String, dynamic> parameters,
});

/// A classification that permanently failed processing and was moved
/// to the dead-letter queue for audit and potential manual retry.
///
/// PRIVACY-09: For new items, image data is stored in an OS-sandbox-protected
/// temp file. Hive stores only the file reference, SHA-256 content hash, byte
/// length, and queue metadata.
/// Old Uint8List imageBytes field is preserved as nullable for migration.
@HiveType(typeId: 101)
class DeadLetterClassification extends HiveObject {
  DeadLetterClassification({
    required this.id,
    required this.region,
    required this.queuedAt,
    required this.failedAt,
    required this.retryCount,
    required this.lastError,
    this.imageBytes,
    this.imageRefPath,
    this.imageRefHash,
    this.imageRefByteLength,
    this.userId,
    this.imageName,
    this.expiresAt,
    this.consentVersion,
    this.failureType,
    this.purpose,
  });
  @HiveField(0)
  String id;

  /// PRIVACY-09: Legacy raw bytes — field index 1 is preserved from the
  /// pre-migration schema (legacy records stored Uint8List here).
  /// Null for new items; populated only on unmigrated legacy records.
  @HiveField(1)
  Uint8List? imageBytes;

  /// PRIVACY-09: Path to an OS-sandbox-protected temp file (not raw bytes).
  /// Nullable so legacy records (which predate this field) read safely.
  @HiveField(9)
  String? imageRefPath;

  /// PRIVACY-09: SHA-256 content hash for integrity verification.
  @HiveField(10)
  String? imageRefHash;

  /// PRIVACY-09: Original byte length (for logging/quotas).
  @HiveField(11)
  int? imageRefByteLength;

  @HiveField(2)
  String region;

  @HiveField(3)
  DateTime queuedAt;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  String lastError;

  @HiveField(6)
  DateTime failedAt;

  @HiveField(7)
  String? userId;

  @HiveField(8)
  String? imageName;

  /// PRIVACY-09: When this item should be auto-deleted.
  @HiveField(12)
  DateTime? expiresAt;

  /// PRIVACY-09: Consent version at time of queue entry.
  @HiveField(13)
  String? consentVersion;

  /// PRIVACY-09: Typed failure classification (no error string inspection).
  @HiveField(14)
  String? failureType;

  /// PRIVACY-09: Purpose of the queued image (e.g. 'classification').
  @HiveField(15)
  String? purpose;

  /// Whether this item still uses the legacy raw-bytes format.
  ///
  /// Keyed on [imageBytes] alone (not ref-path emptiness): an item that was
  /// partially migrated (bytes still set after a failed save) must still be
  /// picked up by migration/age-expiry rather than silently evading both.
  bool get isLegacyFormat => imageBytes != null;

  /// PRIVACY-09: Read image bytes from the sandboxed temp file.
  /// Falls back to imageBytes for unmigrated legacy items.
  Future<Uint8List?> readImageBytes() async {
    if (isLegacyFormat) return imageBytes;
    final path = imageRefPath;
    if (path == null || path.isEmpty) return null;
    return QueueImageStorage().readImage(QueueImageReference(
      filePath: path,
      contentHash: imageRefHash ?? '',
      byteLength: imageRefByteLength ?? 0,
    ));
  }
}

/// Queued classification for offline processing
///
/// PRIVACY-09: For new items, image data is stored in an OS-sandbox-protected
/// temp file. Hive stores only the file reference, SHA-256 content hash, byte
/// length, and queue metadata.
/// Old Uint8List imageBytes field is preserved as nullable for migration.
@HiveType(typeId: 100)
class QueuedClassification extends HiveObject {
  QueuedClassification({
    required this.id,
    required this.region,
    required this.queuedAt,
    this.imageBytes,
    this.imageRefPath,
    this.imageRefHash,
    this.imageRefByteLength,
    this.retryCount = 0,
    this.userId,
    this.imageName,
    this.expiresAt,
    this.consentVersion,
    this.purpose,
  });
  @HiveField(0)
  String id;

  /// PRIVACY-09: Legacy raw bytes — field index 1 is preserved from the
  /// pre-migration schema (legacy records stored Uint8List here).
  /// Null for new items; populated only on unmigrated legacy records.
  @HiveField(1)
  Uint8List? imageBytes;

  /// PRIVACY-09: Path to an OS-sandbox-protected temp file (not raw bytes).
  /// Nullable so legacy records (which predate this field) read safely.
  @HiveField(7)
  String? imageRefPath;

  /// PRIVACY-09: SHA-256 content hash for integrity verification.
  @HiveField(8)
  String? imageRefHash;

  /// PRIVACY-09: Original byte length (for logging/quotas).
  @HiveField(9)
  int? imageRefByteLength;

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

  /// PRIVACY-09: When this item should be auto-deleted.
  @HiveField(10)
  DateTime? expiresAt;

  /// PRIVACY-09: Consent version at time of queue entry.
  @HiveField(11)
  String? consentVersion;

  /// PRIVACY-09: Purpose of the queued image (e.g. 'classification').
  @HiveField(12)
  String? purpose;

  /// Whether this item still uses the legacy raw-bytes format.
  ///
  /// Keyed on [imageBytes] alone (not ref-path emptiness): an item that was
  /// partially migrated (bytes still set after a failed save) must still be
  /// picked up by migration/age-expiry rather than silently evading both.
  bool get isLegacyFormat => imageBytes != null;

  /// PRIVACY-09: Read image bytes from the sandboxed temp file.
  /// Falls back to imageBytes for unmigrated legacy items.
  Future<Uint8List?> readImageBytes() async {
    if (isLegacyFormat) return imageBytes;
    final path = imageRefPath;
    if (path == null || path.isEmpty) return null;
    return QueueImageStorage().readImage(QueueImageReference(
      filePath: path,
      contentHash: imageRefHash ?? '',
      byteLength: imageRefByteLength ?? 0,
    ));
  }
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

  @visibleForTesting
  static OfflineQueueAnalyticsTracker? analyticsTrackerOverride;

  /// PRIVACY-09: Test hook to run the legacy raw-bytes → file-reference
  /// migration outside of [init] (init already runs it). Mirrors the
  /// [analyticsTrackerOverride] test seam pattern.
  @visibleForTesting
  Future<void> runLegacyMigrationForTesting() => _migrateLegacyItems();

  /// PRIVACY-09: Test hook to run retention expiry outside of [init].
  @visibleForTesting
  Future<void> runExpiryForTesting() => _expireOldItems();

  Box<QueuedClassification>? _queueBox;
  Box<DeadLetterClassification>? _deadLetterBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;
  bool _isInitialized = false;
  ScanOrchestrator? _scanOrchestrator;
  final QueueImageStorage _imageStorage = QueueImageStorage();

  final _queueCountController = StreamController<int>.broadcast();
  Stream<int> get queueCountStream => _queueCountController.stream;

  /// Bind queued work to the same scan composition as foreground work.
  ///
  /// The queue intentionally has no independent AI fallback. If this is not
  /// configured, queued work remains pending rather than being processed with
  /// different persistence and policy semantics.
  void configureScanOrchestrator(ScanOrchestrator orchestrator) {
    _scanOrchestrator = orchestrator;
  }

  /// Initialize the service - call once at app startup
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(100)) {
        Hive.registerAdapter(QueuedClassificationAdapter());
      }
      if (!Hive.isAdapterRegistered(101)) {
        Hive.registerAdapter(DeadLetterClassificationAdapter());
      }

      _queueBox =
          await Hive.openBox<QueuedClassification>('classification_queue');
      _deadLetterBox = await Hive.openBox<DeadLetterClassification>(
          'classification_dead_letter');

      // Emit initial count
      _queueCountController.add(_queueBox!.length);

      // PRIVACY-09: Migrate legacy raw-bytes items to file references
      await _migrateLegacyItems();

      // PRIVACY-09: Expire old items on startup (deletes files too)
      await _expireOldItems();

      // PRIVACY-09: Clean orphaned image files on startup
      await _cleanOrphanedFiles();

      // Listen for connectivity changes
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final isOnline =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
        if (isOnline && !_isProcessing) {
          unawaited(_processQueue());
        }
      });

      // Process queue if we're already online
      final current = await Connectivity().checkConnectivity();
      final isOnline =
          current.isNotEmpty && !current.contains(ConnectivityResult.none);
      if (isOnline) {
        unawaited(_processQueue());
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

  /// PRIVACY-09: Expire items that have exceeded their retention limit.
  /// Deletes both Hive metadata and sandboxed image files.
  ///
  /// Legacy raw-bytes items whose migration failed have no [expiresAt].
  /// They are still expired by age ([queuedAt]/[failedAt] vs the retention
  /// limit) so a failed migration degrades into expiry rather than leaving
  /// raw image bytes in Hive forever.
  Future<void> _expireOldItems() async {
    final now = DateTime.now();
    var expiredCount = 0;
    final expiredFilePaths = <String>{};

    // Expire active queue items
    if (_queueBox != null) {
      final expiredKeys = <dynamic>[];
      for (final item in _queueBox!.values) {
        final pastExpiry =
            item.expiresAt != null && item.expiresAt!.isBefore(now);
        final legacyTooOld = item.isLegacyFormat &&
            now.difference(item.queuedAt) > kQueueRetentionLimit;
        if (pastExpiry || legacyTooOld) {
          expiredKeys.add(item.id);
          final path = item.imageRefPath;
          if (path != null && path.isNotEmpty) expiredFilePaths.add(path);
        }
      }
      for (final key in expiredKeys) {
        await _queueBox!.delete(key);
        expiredCount++;
      }
    }

    // Expire dead-letter items
    if (_deadLetterBox != null) {
      final expiredKeys = <dynamic>[];
      for (final item in _deadLetterBox!.values) {
        final pastExpiry =
            item.expiresAt != null && item.expiresAt!.isBefore(now);
        final legacyTooOld = item.isLegacyFormat &&
            now.difference(item.failedAt) > kDeadLetterRetentionLimit;
        if (pastExpiry || legacyTooOld) {
          expiredKeys.add(item.id);
          final path = item.imageRefPath;
          if (path != null && path.isNotEmpty) expiredFilePaths.add(path);
        }
      }
      for (final key in expiredKeys) {
        await _deadLetterBox!.delete(key);
        expiredCount++;
      }
    }

    // PRIVACY-09: Delete image files for expired items
    if (expiredFilePaths.isNotEmpty) {
      await _imageStorage.deleteForUser(expiredFilePaths);
    }

    if (expiredCount > 0) {
      _queueCountController.add(_queueBox?.length ?? 0);
      WasteAppLogger.info('Expired old queue items', context: {
        'expired_count': expiredCount,
        'files_deleted': expiredFilePaths.length,
      });
    }
  }

  /// PRIVACY-09: Delete all queue items for a specific user.
  /// Called on logout or account switch.
  Future<void> purgeForUser(String uid) async {
    if (!_isInitialized) await init();

    var purgedCount = 0;
    final filePaths = <String>{};

    // Collect file paths before deleting metadata
    if (_queueBox != null) {
      for (final item in _queueBox!.values) {
        if (item.userId == uid) {
          final path = item.imageRefPath;
          if (path != null && path.isNotEmpty) filePaths.add(path);
        }
      }
    }
    if (_deadLetterBox != null) {
      for (final item in _deadLetterBox!.values) {
        if (item.userId == uid) {
          final path = item.imageRefPath;
          if (path != null && path.isNotEmpty) filePaths.add(path);
        }
      }
    }

    // Delete image files
    await _imageStorage.deleteForUser(filePaths);

    // Purge active queue items for this user
    if (_queueBox != null) {
      final userKeys = <dynamic>[];
      for (final item in _queueBox!.values) {
        if (item.userId == uid) {
          userKeys.add(item.id);
        }
      }
      for (final key in userKeys) {
        await _queueBox!.delete(key);
        purgedCount++;
      }
    }

    // Purge dead-letter items for this user
    if (_deadLetterBox != null) {
      final userKeys = <dynamic>[];
      for (final item in _deadLetterBox!.values) {
        if (item.userId == uid) {
          userKeys.add(item.id);
        }
      }
      for (final key in userKeys) {
        await _deadLetterBox!.delete(key);
        purgedCount++;
      }
    }

    _queueCountController.add(_queueBox?.length ?? 0);
    WasteAppLogger.info('Purged queue items for user', context: {
      'uid': uid,
      'purged_count': purgedCount,
      'files_deleted': filePaths.length,
    });
  }

  /// PRIVACY-09: Purge all queue items and their image files (full logout).
  Future<void> purgeAll() async {
    if (!_isInitialized) await init();
    final queueCount = _queueBox?.length ?? 0;
    final deadLetterCount = _deadLetterBox?.length ?? 0;

    // Delete all image files first
    final filesDeleted = await _imageStorage.deleteAll();

    await _queueBox?.clear();
    await _deadLetterBox?.clear();
    _queueCountController.add(0);
    WasteAppLogger.info('Purged all queue items', context: {
      'queue_count': queueCount,
      'dead_letter_count': deadLetterCount,
      'files_deleted': filesDeleted,
    });
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

  /// PRIVACY-09: Queue a classification for later processing.
  ///
  /// Image bytes are written to an OS-sandbox-protected temp file. Hive stores
  /// only the file reference, SHA-256 content hash, byte length, and metadata.
  Future<void> queue({
    required Uint8List imageBytes,
    required String region,
    String? userId,
    String? imageName,
    String? consentVersion,
  }) async {
    if (!_isInitialized) await init();

    if (_queueBox == null) {
      WasteAppLogger.warning(
        'Offline queue unavailable; skipping enqueue',
      );
      return;
    }

    try {
      // PRIVACY-09: Write image bytes to sandboxed temp file.
      final imageRef = await _imageStorage.writeImage(imageBytes);

      final item = QueuedClassification(
        id: const Uuid().v4(),
        imageRefPath: imageRef.filePath,
        imageRefHash: imageRef.contentHash,
        imageRefByteLength: imageRef.byteLength,
        region: region,
        queuedAt: DateTime.now(),
        userId: userId,
        imageName:
            imageName ?? 'offline_${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now().add(kQueueRetentionLimit),
        consentVersion: consentVersion,
      );

      await _queueBox!.put(item.id, item);
      _queueCountController.add(_queueBox!.length);

      WasteAppLogger.info('Classification queued for offline processing',
          context: {
            'queue_id': item.id,
            'queue_length': _queueBox!.length,
            'image_size_kb': (imageBytes.length / 1024).toStringAsFixed(1),
          });

      await _trackQueueAnalyticsEvent(
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

    final orchestrator = _scanOrchestrator;
    if (orchestrator == null) {
      WasteAppLogger.warning(
        'Offline queue paused because the canonical scan orchestrator is not configured',
        context: {'service': 'offline_queue'},
      );
      _isProcessing = false;
      return;
    }

    WasteAppLogger.info('Processing offline queue', context: {
      'pending_items': _queueBox!.length,
    });

    final startTime = DateTime.now();
    final items = _queueBox!.values.toList();
    final backendRoutingEnabled = orchestrator.isBackendRoutingEnabled;
    final tokenService =
        TokenService(StorageService(), CloudStorageService(StorageService()));
    await tokenService.initialize();
    var successCount = 0;
    var failCount = 0;
    var permanentFailCount = 0;
    var insufficientTokenBlocks = 0;

    try {
      for (final item in items) {
        var tokenSpentForItem = false;
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

          if (!backendRoutingEnabled) {
            try {
              await tokenService.spendAnalysisTokens(
                AnalysisSpeed.batch,
                isPremiumUser: false,
                description: 'Offline queued analysis',
                reference: item.id,
                metadata: {
                  'source': 'offline_queue',
                  'queued_at': item.queuedAt.toIso8601String(),
                  'retry_count': item.retryCount,
                },
              );
              tokenSpentForItem = true;
            } catch (spendError, spendStackTrace) {
              final message = spendError.toString();
              if (message.contains('Insufficient tokens')) {
                insufficientTokenBlocks++;
                WasteAppLogger.warning(
                  'Queue processing paused due to insufficient tokens',
                  error: spendError,
                  stackTrace: spendStackTrace,
                  context: {
                    'queue_id': item.id,
                    'remaining': _queueBox!.length,
                  },
                );
                await _trackQueueAnalyticsEvent(
                  eventType: 'classification',
                  eventName: 'queue_blocked_insufficient_tokens',
                  parameters: {
                    'queue_id': item.id,
                    'remaining': _queueBox!.length,
                  },
                );
                break;
              }
              rethrow;
            }
          }

          // PRIVACY-09: Read image bytes from sandboxed temp file.
          final imageBytes = await item.readImageBytes();
          if (imageBytes == null) {
            WasteAppLogger.warning(
              'Queue item image file missing — skipping',
              context: {'queue_id': item.id},
            );
            await _moveToDeadLetter(item, lastError: 'image_file_missing');
            await item.delete();
            permanentFailCount++;
            continue;
          }

          final result = await orchestrator.analyzeBytes(
            imageBytes,
            item.imageName ?? 'offline_item',
            region: item.region,
          );

          // Reconcile: remove any offline hint classification for the same image
          // so the fresh cloud result replaces it (avoids duplicate history entries).
          if (result.imageHash != null && result.imageHash!.isNotEmpty) {
            final removed = await StorageService()
                .classificationStorage
                .removeOfflineHintsByImageHash(result.imageHash!);
            if (removed > 0) {
              WasteAppLogger.info('offline_hint_reconciled', context: {
                'queue_id': item.id,
                'hints_removed': removed,
              });
            }
          }

          // Complete through the canonical result pipeline so queued scans
          // receive the same policy, taxonomy, deduplication, gamification,
          // training, analytics, and optional sync side effects as foreground
          // scans.
          await orchestrator.complete(
            result,
            autoAnalyze: true,
            manageLifecycle: false,
          );

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
          // PRIVACY-09: Safety exceptions are build-level, not item-level.
          // Mark this item as blocked_configuration WITHOUT clearing
          // unrelated items. Configuration/safety failures do NOT consume
          // retry count. Server/backend route can resume later.
          if (e is ProductionSafetyException) {
            WasteAppLogger.severe(
              '[PRODUCTION_SAFETY] Queue item blocked: client AI disabled in build.',
              error: e,
              stackTrace: stackTrace,
              context: {
                'queue_id': item.id,
              },
            );
            if (tokenSpentForItem) {
              try {
                await tokenService.earnTokens(
                  AnalysisSpeed.batch.cost,
                  TokenTransactionType.refund,
                  'Queue item blocked — client AI disabled in build',
                  reference: item.id,
                  metadata: {
                    'source': 'offline_queue',
                    'reason': 'blocked_configuration',
                  },
                );
              } catch (refundError) {
                WasteAppLogger.warning(
                  'Failed to refund token after safety block',
                  error: refundError,
                  context: {'queue_id': item.id},
                );
              }
            }
            // Mark as blocked_configuration, do NOT clear other items
            item.retryCount = 0; // Config failures don't consume retry count
            await item.save();
            failCount++;
            break; // Stop processing; other items may succeed later
          }
          if (tokenSpentForItem) {
            try {
              await tokenService.earnTokens(
                AnalysisSpeed.batch.cost,
                TokenTransactionType.refund,
                'Offline queue processing failed - token refund',
                reference: item.id,
                metadata: {
                  'source': 'offline_queue',
                  'retry_count': item.retryCount,
                  'error': e.toString(),
                },
              );
            } catch (refundError, refundStackTrace) {
              WasteAppLogger.severe(
                'Failed to refund offline queue token after processing failure',
                error: refundError,
                stackTrace: refundStackTrace,
                context: {'queue_id': item.id},
              );
            }
          }

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
            // Give up after 3 retries — move to dead-letter queue for audit
            await _moveToDeadLetter(item, lastError: e.toString());
            await item.delete();
            permanentFailCount++;

            await _trackQueueAnalyticsEvent(
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
    } finally {
      _queueCountController.add(_queueBox?.length ?? 0);
      _isProcessing = false;
    }

    final duration = DateTime.now().difference(startTime);

    WasteAppLogger.info('Queue processing complete', context: {
      'duration_seconds': duration.inSeconds,
      'success_count': successCount,
      'fail_count': failCount,
      'permanent_fail_count': permanentFailCount,
      'insufficient_token_blocks': insufficientTokenBlocks,
      'remaining': _queueBox!.length,
    });

    await _trackQueueAnalyticsEvent(
      eventType: 'classification',
      eventName: 'queue_processed',
      parameters: {
        'success': successCount,
        'failed': failCount,
        'permanent_failures': permanentFailCount,
        'insufficient_token_blocks': insufficientTokenBlocks,
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

  /// Clear all pending items (user-initiated cancellation).
  /// PRIVACY-09: Also deletes sandboxed image files.
  Future<void> clearQueue() async {
    if (!_isInitialized) await init();

    final count = pendingCount;

    // Collect and delete image files before clearing metadata
    final filePaths = _queueBox?.values
            .map((item) => item.imageRefPath)
            .whereType<String>()
            .toSet() ??
        {};
    if (filePaths.isNotEmpty) {
      await _imageStorage.deleteForUser(filePaths);
    }

    await _queueBox?.clear();
    _queueCountController.add(0);

    WasteAppLogger.info('Queue cleared', context: {
      'items_cleared': count,
      'files_deleted': filePaths.length,
    });

    await _trackQueueAnalyticsEvent(
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
        'deadLetter': 0,
      };
    }

    // Note: We only track pending items in the queue box
    // Processed items are removed from the queue
    final pending = _queueBox!.length;
    final deadLetter = _deadLetterBox?.length ?? 0;

    return {
      'totalQueued': pending, // Only pending items remain in queue
      'processed': 0, // Processed items are removed
      'pending': pending,
      'deadLetter': deadLetter,
    };
  }

  /// PRIVACY-09: Classify error into typed failure category.
  QueueItemFailureType _classifyFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('timeout') || message.contains('network')) {
      return QueueItemFailureType.retryableNetwork;
    }
    if (message.contains('auth') || message.contains('unauthenticated')) {
      return QueueItemFailureType.authentication;
    }
    if (message.contains('insufficient') || message.contains('token')) {
      return QueueItemFailureType.insufficientCredits;
    }
    if (message.contains('invalid') || message.contains('corrupt')) {
      return QueueItemFailureType.permanentInvalidImage;
    }
    if (error is ProductionSafetyException) {
      return QueueItemFailureType.configurationSafety;
    }
    return QueueItemFailureType.unknown;
  }

  /// PRIVACY-09: Move a permanently-failed item to the dead-letter queue.
  ///
  /// Transfers the file reference (not the bytes) — no data duplication.
  Future<void> _moveToDeadLetter(
    QueuedClassification item, {
    required String lastError,
  }) async {
    if (_deadLetterBox == null) return;
    try {
      final deadLetter = DeadLetterClassification(
        id: item.id,
        imageBytes: item.imageBytes, // Preserve bytes for legacy items
        imageRefPath: item.imageRefPath,
        imageRefHash: item.imageRefHash,
        imageRefByteLength: item.imageRefByteLength,
        region: item.region,
        queuedAt: item.queuedAt,
        failedAt: DateTime.now(),
        retryCount: item.retryCount,
        lastError: kRedactedError, // PRIVACY-09: Never store raw error strings
        userId: item.userId,
        imageName: item.imageName,
        expiresAt: DateTime.now().add(kDeadLetterRetentionLimit),
        consentVersion: item.consentVersion,
        failureType: _classifyFailure(Exception(lastError)).name,
        purpose: item.purpose,
      );
      await _deadLetterBox!.put(deadLetter.id, deadLetter);
      WasteAppLogger.info('Item moved to dead-letter queue', context: {
        'queue_id': item.id,
        'retry_count': item.retryCount,
        'error': lastError,
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to move item to dead-letter queue',
          error: e, context: {'queue_id': item.id});
    }
  }

  /// Get all dead-letter items for audit / manual retry.
  List<DeadLetterClassification> getDeadLetterItems() {
    if (!_isInitialized || _deadLetterBox == null) return [];
    return _deadLetterBox!.values.toList();
  }

  /// PRIVACY-09: Retry a dead-letter item — transfers file reference back.
  Future<bool> retryDeadLetter(String id) async {
    if (_deadLetterBox == null || !_deadLetterBox!.containsKey(id)) {
      return false;
    }
    try {
      final item = _deadLetterBox!.get(id)!;
      final queued = QueuedClassification(
        id: const Uuid().v4(),
        imageBytes: item.imageBytes, // Preserve bytes for legacy items
        imageRefPath: item.imageRefPath,
        imageRefHash: item.imageRefHash,
        imageRefByteLength: item.imageRefByteLength,
        region: item.region,
        queuedAt: DateTime.now(),
        userId: item.userId,
        imageName: item.imageName,
        expiresAt: DateTime.now().add(kQueueRetentionLimit),
        consentVersion: item.consentVersion,
        purpose: item.purpose,
      );
      await _queueBox!.put(queued.id, queued);
      await _deadLetterBox!.delete(id);
      _queueCountController.add(_queueBox!.length);
      WasteAppLogger.info('Dead-letter item retried', context: {
        'dead_letter_id': id,
        'new_queue_id': queued.id,
      });
      return true;
    } catch (e) {
      WasteAppLogger.warning('Failed to retry dead-letter item',
          error: e, context: {'dead_letter_id': id});
      return false;
    }
  }

  /// Clear all dead-letter items.
  /// PRIVACY-09: Also deletes sandboxed image files.
  Future<void> clearDeadLetterQueue() async {
    if (!_isInitialized) await init();
    final count = _deadLetterBox?.length ?? 0;

    // Collect and delete image files before clearing metadata
    final filePaths = _deadLetterBox?.values
            .map((item) => item.imageRefPath)
            .whereType<String>()
            .toSet() ??
        {};
    if (filePaths.isNotEmpty) {
      await _imageStorage.deleteForUser(filePaths);
    }

    await _deadLetterBox?.clear();
    WasteAppLogger.info('Dead-letter queue cleared', context: {
      'items_cleared': count,
      'files_deleted': filePaths.length,
    });
  }

  /// PRIVACY-09: Migrate legacy raw-bytes items to file references.
  ///
  /// Old items stored Uint8List imageBytes at field index 1. This method
  /// writes those bytes to OS-sandbox-protected temp files and updates the
  /// metadata.
  /// After migration, imageBytes is set to null. Legacy records also have no
  /// expiry metadata, so an expiry is assigned here to honour the retention
  /// contract (24h active queue / 72h dead-letter).
  Future<void> _migrateLegacyItems() async {
    var migratedCount = 0;

    // Migrate active queue items
    if (_queueBox != null) {
      for (final item in _queueBox!.values.toList()) {
        if (item.isLegacyFormat) {
          try {
            final ref = await _imageStorage.writeImage(item.imageBytes!);
            item.imageRefPath = ref.filePath;
            item.imageRefHash = ref.contentHash;
            item.imageRefByteLength = ref.byteLength;
            item.imageBytes = null; // Clear legacy field
            // PRIVACY-09: Legacy records have no expiry — assign now.
            item.expiresAt ??= DateTime.now().add(kQueueRetentionLimit);
            await item.save();
            migratedCount++;
          } catch (e) {
            WasteAppLogger.warning('Failed to migrate legacy queue item',
                error: e, context: {'queue_id': item.id});
          }
        }
      }
    }

    // Migrate dead-letter items
    if (_deadLetterBox != null) {
      for (final item in _deadLetterBox!.values.toList()) {
        if (item.isLegacyFormat) {
          try {
            final ref = await _imageStorage.writeImage(item.imageBytes!);
            item.imageRefPath = ref.filePath;
            item.imageRefHash = ref.contentHash;
            item.imageRefByteLength = ref.byteLength;
            item.imageBytes = null; // Clear legacy field
            // PRIVACY-09: Legacy records have no expiry — assign now.
            item.expiresAt ??= DateTime.now().add(kDeadLetterRetentionLimit);
            await item.save();
            migratedCount++;
          } catch (e) {
            WasteAppLogger.warning('Failed to migrate legacy dead-letter item',
                error: e, context: {'queue_id': item.id});
          }
        }
      }
    }

    if (migratedCount > 0) {
      WasteAppLogger.info('Migrated legacy queue items to file references',
          context: {
            'migrated_count': migratedCount,
          });
    }
  }

  /// PRIVACY-09: Clean orphaned image files that have no Hive metadata.
  /// Runs on init to prevent unbounded disk usage from crashed writes.
  Future<void> _cleanOrphanedFiles() async {
    final activePaths = <String>{};
    if (_queueBox != null) {
      for (final item in _queueBox!.values) {
        final path = item.imageRefPath;
        if (path != null && path.isNotEmpty) activePaths.add(path);
      }
    }
    if (_deadLetterBox != null) {
      for (final item in _deadLetterBox!.values) {
        final path = item.imageRefPath;
        if (path != null && path.isNotEmpty) activePaths.add(path);
      }
    }
    final cleaned = await _imageStorage.cleanOrphaned(activePaths);
    if (cleaned > 0) {
      WasteAppLogger.info('Cleaned orphaned queue image files on init',
          context: {
            'count': cleaned,
          });
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySub?.cancel();
    _queueCountController.close();
  }

  Future<void> _trackQueueAnalyticsEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) async {
    final tracker = analyticsTrackerOverride;
    if (tracker != null) {
      await tracker(
        eventType: eventType,
        eventName: eventName,
        parameters: parameters,
      );
      return;
    }

    await AnalyticsService(StorageService()).trackEvent(
      eventType: eventType,
      eventName: eventName,
      parameters: parameters,
    );
  }
}
