import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Simple Local Fresh Start Script
/// 
/// This script provides a quick way to:
/// 1. Clear all local Hive storage
/// 2. Enable fresh start mode
/// 3. Reset app to clean state without touching Firebase
/// 
/// Usage: dart run scripts/local_fresh_start.dart
class LocalFreshStartService {
  // Local Hive boxes to clear
  static const List<String> _hiveBoxes = [
    'classificationsBox',
    'gamificationBox',
    'userBox',
    'settingsBox',
    'cacheBox',
    'familiesBox',
    'invitationsBox',
    'classificationFeedbackBox',
    'classificationHashesBox',
    'communityBox',
  ];

  /// Clear all local Hive storage
  Future<void> clearLocalStorage() async {
    WasteAppLogger.info('💾 Clearing local storage...');
    
    try {
      // Initialize Hive
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
      
      var clearedBoxes = 0;
      
      // Clear each box
      for (final boxName in _hiveBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
            clearedBoxes++;
          } else {
            // Try to open and clear
            try {
              final box = await Hive.openBox(boxName);
              await box.clear();
              await box.close();
              WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
              clearedBoxes++;
            } catch (e) {
              WasteAppLogger.info('   ⚪ Box $boxName not found or already empty');
            }
          }
        } catch (e) {
          WasteAppLogger.severe('   ❌ Failed to clear box $boxName: $e');
        }
      }
      
      WasteAppLogger.info('✅ Local storage cleared successfully! ($clearedBoxes boxes cleared)');
      
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to clear local storage: $e');
    }
  }

  /// Enable fresh start mode
  Future<void> enableFreshStartMode() async {
    WasteAppLogger.info('🔄 Enabling fresh start mode...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fresh_start_mode', true);
      await prefs.setString('fresh_start_date', DateTime.now().toIso8601String());
      
      WasteAppLogger.info('✅ Fresh start mode enabled');
      WasteAppLogger.info('   This will prevent automatic sync for 24 hours');
      
    } catch (e) {
      WasteAppLogger.severe('❌ Error enabling fresh start mode: $e');
    }
  }

  /// Clear SharedPreferences (except fresh start settings)
  Future<void> clearSharedPreferences() async {
    WasteAppLogger.info('🗑️  Clearing SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      
      // Keep fresh start related keys
      final keysToKeep = {
        'fresh_start_mode',
        'fresh_start_date',
        'archive_timestamp',
      };
      
      var clearedKeys = 0;
      for (final key in keys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
          clearedKeys++;
        }
      }
      
      WasteAppLogger.info('✅ SharedPreferences cleared ($clearedKeys keys removed)');
      
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to clear SharedPreferences: $e');
    }
  }

  /// Show current storage status
  Future<void> showStorageStatus() async {
    WasteAppLogger.info('\n📊 Current Storage Status:');
    
    try {
      // Check Hive boxes
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
      
      for (final boxName in _hiveBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            WasteAppLogger.info('   📦 $boxName: \\${box.length} items');
          } else {
            try {
              final box = await Hive.openBox(boxName);
              WasteAppLogger.info('   �� $boxName: \\${box.length} items');
              await box.close();
            } catch (e) {
              WasteAppLogger.info('   📦 $boxName: Not found');
            }
          }
        } catch (e) {
          WasteAppLogger.info('   📦 $boxName: Error reading');
        }
      }
      
      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      WasteAppLogger.info('   🔧 SharedPreferences: \\${keys.length} keys');
      
      // Check fresh start status
      final isFreshStart = prefs.getBool('fresh_start_mode') ?? false;
      final freshStartDate = prefs.getString('fresh_start_date');
      
      WasteAppLogger.info('\n🔄 Fresh Start Status:');
      WasteAppLogger.info('   Mode: \\${isFreshStart ? 'ENABLED' : 'DISABLED'}');
      if (freshStartDate != null) {
        final date = DateTime.tryParse(freshStartDate);
        WasteAppLogger.info('   Started: \\${date?.toString() ?? 'Invalid date'}');
      }
      
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to check storage status: $e');
    }
  }

  /// Main execution method
  Future<void> run(List<String> args) async {
    WasteAppLogger.info('🚀 Local Fresh Start Tool');
    WasteAppLogger.info('This will clear all local app data and enable fresh start mode.\n');
    
    if (args.contains('--status')) {
      await showStorageStatus();
      return;
    }
    
    if (args.contains('--help') || args.contains('-h')) {
      WasteAppLogger.info('''
Usage:
  dart run scripts/local_fresh_start.dart [options]

Options:
  --help, -h     Show this help message
  --status       Show current storage status
  --no-confirm   Skip confirmation prompt

This script will:
  1. Clear all local Hive storage boxes
  2. Clear SharedPreferences (except fresh start settings)
  3. Enable fresh start mode (prevents auto-sync for 24 hours)
  
Firebase data is NOT affected - only local storage is cleared.
''');
      return;
    }
    
    // Show what will be cleared
    await showStorageStatus();
    
    if (!args.contains('--no-confirm')) {
      // Confirm action
      stdout.write('\nAre you sure you want to clear all local data? (yes/no): ');
      final confirmation = stdin.readLineSync();
      
      if (confirmation?.toLowerCase() != 'yes') {
        WasteAppLogger.severe('❌ Operation cancelled');
        return;
      }
    }
    
    print('\n🧹 Starting local fresh start process...');
    
    // Execute cleanup
    await clearLocalStorage();
    await clearSharedPreferences();
    await enableFreshStartMode();
    
    print('\n🎉 Local fresh start completed successfully!');
    print('✨ Your app now has a clean local state');
    print('🔒 Auto-sync is disabled for 24 hours');
    print('');
    print('💡 Next steps:');
    print('   1. Restart your app');
    print('   2. The app will start fresh with no local data');
    print('   3. You can sign in and start using the app normally');
    print('   4. Auto-sync will resume after 24 hours');
    print('');
    print('⚠️  Note: Your Firebase data is safe and untouched');
  }
}

/// Main entry point
Future<void> main(List<String> args) async {
  final service = LocalFreshStartService();
  
  try {
    await service.run(args);
  } catch (e) {
    print('❌ Fatal error: $e');
    exit(1);
  }
} 