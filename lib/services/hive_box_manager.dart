import 'package:hive_flutter/hive_flutter.dart';
import '../utils/waste_app_logger.dart';

/// OPTIMIZATION: Manager for Hive box lifecycle
///
/// Provides centralized management of Hive boxes with proper initialization,
/// lazy loading, and cleanup. Prevents memory leaks from unclosed boxes.
///
/// Benefits:
/// - Automatic box lifecycle management
/// - Lazy initialization of boxes
/// - Proper cleanup on app shutdown
/// - Prevention of duplicate box openings
/// - Memory leak prevention
class HiveBoxManager {
  HiveBoxManager._();
  static final HiveBoxManager _instance = HiveBoxManager._();
  static HiveBoxManager get instance => _instance;

  final Map<String, Box> _openBoxes = {};
  final Map<String, Future<Box>> _pendingBoxes = {};
  bool _isInitialized = false;

  /// Initialize Hive and register adapters
  /// Should be called once during app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      WasteAppLogger.debug('HiveBoxManager already initialized');
      return;
    }

    try {
      // Hive initialization is handled by StorageService.initializeHive()
      // This just marks the manager as ready
      _isInitialized = true;
      WasteAppLogger.info('HiveBoxManager initialized');
    } catch (e, s) {
      WasteAppLogger.severe('Failed to initialize HiveBoxManager',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get or open a Hive box
  ///
  /// Uses lazy loading - box is only opened when first accessed.
  /// Subsequent calls return the cached instance.
  ///
  /// [boxName] - Name of the Hive box
  /// [lazy] - Whether to use lazy box (default: false)
  Future<Box<T>> getBox<T>(String boxName, {bool lazy = false}) async {
    if (!_isInitialized) {
      throw StateError(
          'HiveBoxManager not initialized. Call initialize() first.');
    }

    // Return cached box if already open
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName] as Box<T>;
    }

    // If box opening is in progress, wait for it
    if (_pendingBoxes.containsKey(boxName)) {
      return await _pendingBoxes[boxName] as Box<T>;
    }

    // Open the box
    final openFuture = _openBox<T>(boxName, lazy: lazy);
    _pendingBoxes[boxName] = openFuture;

    try {
      final box = await openFuture;
      _openBoxes[boxName] = box;
      _pendingBoxes.remove(boxName);

      WasteAppLogger.info('Opened Hive box: $boxName (${box.length} entries)');
      return box;
    } catch (e, s) {
      _pendingBoxes.remove(boxName);
      WasteAppLogger.severe('Failed to open Hive box: $boxName',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Internal method to open a box
  Future<Box<T>> _openBox<T>(String boxName, {bool lazy = false}) async {
    try {
      if (lazy) {
        return await Hive.openLazyBox<T>(boxName) as Box<T>;
      } else {
        return await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      // If box is already open, get it
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }
      rethrow;
    }
  }

  /// Check if a box is currently open
  bool isBoxOpen(String boxName) {
    return _openBoxes.containsKey(boxName);
  }

  /// Get list of all open box names
  List<String> get openBoxNames => _openBoxes.keys.toList();

  /// Get total number of open boxes
  int get openBoxCount => _openBoxes.length;

  /// Close a specific box
  ///
  /// [boxName] - Name of the box to close
  /// [deleteFromDisk] - Whether to delete the box file (default: false)
  Future<void> closeBox(String boxName, {bool deleteFromDisk = false}) async {
    if (!_openBoxes.containsKey(boxName)) {
      WasteAppLogger.debug('Box $boxName is not open');
      return;
    }

    try {
      final box = _openBoxes[boxName]!;

      if (deleteFromDisk) {
        await box.deleteFromDisk();
        WasteAppLogger.info('Deleted Hive box from disk: $boxName');
      } else {
        await box.close();
        WasteAppLogger.info('Closed Hive box: $boxName');
      }

      _openBoxes.remove(boxName);
    } catch (e, s) {
      WasteAppLogger.severe('Error closing Hive box: $boxName',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Close all open boxes
  ///
  /// Should be called during app shutdown or when clearing all data.
  ///
  /// [deleteFromDisk] - Whether to delete box files (default: false)
  Future<void> closeAllBoxes({bool deleteFromDisk = false}) async {
    final boxNames = _openBoxes.keys.toList();

    WasteAppLogger.info('Closing ${boxNames.length} Hive boxes',
        context: {'deleteFromDisk': deleteFromDisk});

    for (final boxName in boxNames) {
      try {
        await closeBox(boxName, deleteFromDisk: deleteFromDisk);
      } catch (e) {
        WasteAppLogger.severe('Error closing box $boxName', error: e);
        // Continue closing other boxes
      }
    }

    _openBoxes.clear();
    _pendingBoxes.clear();

    WasteAppLogger.info('All Hive boxes closed');
  }

  /// Compact a box to reduce file size
  ///
  /// [boxName] - Name of the box to compact
  Future<void> compactBox(String boxName) async {
    if (!_openBoxes.containsKey(boxName)) {
      throw StateError('Box $boxName is not open');
    }

    try {
      final box = _openBoxes[boxName]!;
      await box.compact();
      WasteAppLogger.info('Compacted Hive box: $boxName');
    } catch (e, s) {
      WasteAppLogger.severe('Error compacting Hive box: $boxName',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get statistics about all open boxes
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'totalBoxes': _openBoxes.length,
      'boxes': <String, dynamic>{},
    };

    var totalEntries = 0;
    for (final entry in _openBoxes.entries) {
      final boxName = entry.key;
      final box = entry.value;
      final entryCount = box.length;
      totalEntries += entryCount;

      stats['boxes'][boxName] = {
        'entries': entryCount,
        'isOpen': box.isOpen,
        'lazy': box is LazyBox,
      };
    }

    stats['totalEntries'] = totalEntries;
    return stats;
  }

  /// OPTIMIZATION: Cleanup method for app shutdown
  /// Call this during app lifecycle termination
  Future<void> dispose() async {
    WasteAppLogger.info('Disposing HiveBoxManager');
    await closeAllBoxes();
    _isInitialized = false;
  }
}
