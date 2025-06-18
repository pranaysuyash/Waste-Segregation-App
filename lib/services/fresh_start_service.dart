import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Service to manage fresh start mode and prevent unwanted data restoration
class FreshStartService {
  static const String _freshStartKey = 'fresh_start_mode';
  static const String _archiveTimestampKey = 'archive_timestamp';
  static const String _freshStartDateKey = 'fresh_start_date';
  
  /// Check if app is in fresh start mode
  static Future<bool> isFreshStartMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_freshStartKey) ?? false;
    } catch (e) {
      WasteAppLogger.severe('❌ Error checking fresh start mode: $e');
      return false;
    }
  }
  
  /// Enable fresh start mode
  static Future<void> enableFreshStartMode({String? archiveTimestamp}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_freshStartKey, true);
      await prefs.setString(_freshStartDateKey, DateTime.now().toIso8601String());
      
      if (archiveTimestamp != null) {
        await prefs.setString(_archiveTimestampKey, archiveTimestamp);
      }
      
      WasteAppLogger.info('✅ Fresh start mode enabled');
    } catch (e) {
      WasteAppLogger.severe('❌ Error enabling fresh start mode: $e');
    }
  }
  
  /// Disable fresh start mode (when user wants to restore normal operation)
  static Future<void> disableFreshStartMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_freshStartKey, false);
      WasteAppLogger.info('✅ Fresh start mode disabled');
    } catch (e) {
      WasteAppLogger.severe('❌ Error disabling fresh start mode: $e');
    }
  }
  
  /// Get archive timestamp if available
  static Future<String?> getArchiveTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_archiveTimestampKey);
    } catch (e) {
      WasteAppLogger.severe('❌ Error getting archive timestamp: $e');
      return null;
    }
  }
  
  /// Get fresh start date
  static Future<DateTime?> getFreshStartDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_freshStartDateKey);
      return dateString != null ? DateTime.tryParse(dateString) : null;
    } catch (e) {
      WasteAppLogger.severe('❌ Error getting fresh start date: $e');
      return null;
    }
  }
  
  /// Clear all local storage (Hive boxes)
  static Future<void> clearLocalStorage() async {
    WasteAppLogger.info('💾 Clearing local storage for fresh start...');
    
    final boxesToClear = [
      StorageKeys.classificationsBox,
      StorageKeys.gamificationBox,
      StorageKeys.userBox,
      StorageKeys.settingsBox,
      StorageKeys.cacheBox,
      StorageKeys.familiesBox,
      StorageKeys.invitationsBox,
      StorageKeys.classificationFeedbackBox,
      'classificationHashesBox',
      'communityBox',
    ];
    
    for (final boxName in boxesToClear) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
        } else {
          try {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
            WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
          } catch (e) {
            WasteAppLogger.info('   ⚪ Box $boxName not found or already empty');
          }
        }
      } catch (e) {
        WasteAppLogger.severe('   ❌ Failed to clear box $boxName: $e');
      }
    }
    
    WasteAppLogger.info('✅ Local storage cleared successfully!');
  }
  
  /// Check if we should prevent automatic sync (during fresh start period)
  static Future<bool> shouldPreventAutoSync() async {
    if (!await isFreshStartMode()) return false;
    
    final freshStartDate = await getFreshStartDate();
    if (freshStartDate == null) return false;
    
    // Prevent auto-sync for 24 hours after fresh start
    final now = DateTime.now();
    final hoursSinceFreshStart = now.difference(freshStartDate).inHours;
    
    return hoursSinceFreshStart < 24;
  }
  
  /// Get fresh start status info
  static Future<Map<String, dynamic>> getFreshStartInfo() async {
    final isFreshStart = await isFreshStartMode();
    final archiveTimestamp = await getArchiveTimestamp();
    final freshStartDate = await getFreshStartDate();
    final shouldPreventSync = await shouldPreventAutoSync();
    
    return {
      'isFreshStartMode': isFreshStart,
      'archiveTimestamp': archiveTimestamp,
      'freshStartDate': freshStartDate?.toIso8601String(),
      'shouldPreventAutoSync': shouldPreventSync,
      'canRestore': archiveTimestamp != null,
    };
  }
  
  /// Show fresh start status
  static Future<void> showFreshStartStatus() async {
    final info = await getFreshStartInfo();
    
    WasteAppLogger.info('🔄 Fresh Start Status:');
    WasteAppLogger.info('   Mode: ${info['isFreshStartMode'] ? 'ENABLED' : 'DISABLED'}');
    WasteAppLogger.info('   Archive: ${info['archiveTimestamp'] ?? 'None'}');
    WasteAppLogger.info('   Started: ${info['freshStartDate'] ?? 'Never'}');
    WasteAppLogger.info('   Prevent Sync: ${info['shouldPreventAutoSync']}');
    WasteAppLogger.info('   Can Restore: ${info['canRestore']}');
  }
} 