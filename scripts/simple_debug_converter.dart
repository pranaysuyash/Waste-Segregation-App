import 'dart:io';

/// Simple script to convert debugPrint calls to WasteAppLogger calls
/// Usage: dart run scripts/simple_debug_converter.dart [--dry-run] [--priority=1-3]
void main(List<String> args) async {
  final converter = SimpleDebugPrintConverter();
  
  final dryRun = args.contains('--dry-run');
  final priorityArg = args.where((arg) => arg.startsWith('--priority=')).firstOrNull;
  
  if (priorityArg != null) {
    final priority = int.parse(priorityArg.split('=')[1]);
    await converter.convertByPriority(priority, dryRun: dryRun);
  } else {
    print('Usage: dart run scripts/simple_debug_converter.dart --priority=1|2|3 [--dry-run]');
    print('Priority 1: Critical services (gamification, AI, storage)');
    print('Priority 2: User-facing screens');
    print('Priority 3: Widgets and utilities');
  }
}

class SimpleDebugPrintConverter {
  final Map<String, List<String>> priorityFiles = {
    '1': [
      'lib/services/gamification_service.dart',
      'lib/services/ai_service.dart',
      'lib/services/cloud_storage_service.dart',
      'lib/services/storage_service.dart',
    ],
    '2': [
      'lib/screens/home_screen.dart',
      'lib/screens/result_screen.dart',
      'lib/screens/image_capture_screen.dart',
      'lib/screens/achievements_screen.dart',
    ],
    '3': [
      'lib/widgets/history_list_item.dart',
      'lib/widgets/share_button.dart',
      'lib/providers/points_manager.dart',
      'lib/providers/gamification_provider.dart',
    ],
    '4': [ // High-impact services
      'lib/services/gamification_service.dart',
      'lib/services/ai_service.dart',
      'lib/services/cloud_storage_service.dart',
      'lib/services/storage_service.dart',
      'lib/services/cache_service.dart',
    ],
  };

  Future<void> convertByPriority(int priority, {bool dryRun = false}) async {
    print('🎯 Converting priority $priority files...');
    
    final files = priorityFiles[priority.toString()] ?? [];
    var totalConverted = 0;
    
    for (final filePath in files) {
      final file = File(filePath);
      if (await file.exists()) {
        final converted = await convertFile(filePath, dryRun: dryRun);
        totalConverted += converted;
      } else {
        print('⚠️  File not found: $filePath');
      }
    }
    
    print('✅ Priority $priority complete: $totalConverted conversions');
  }

  Future<int> convertFile(String filePath, {bool dryRun = false}) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    // Check if WasteAppLogger import exists
    final hasImport = content.contains('waste_app_logger.dart');
    
    var newContent = content;
    var conversions = 0;
    
    // Add import if needed
    if (!hasImport && content.contains('debugPrint(')) {
      newContent = addImport(newContent, filePath);
      print('📦 Added import to $filePath');
    }
    
    // Convert debugPrint calls
    final lines = newContent.split('\n');
    final newLines = <String>[];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.contains('debugPrint(')) {
        final converted = convertDebugPrintLine(line, filePath);
        newLines.add(converted);
        conversions++;
      } else {
        newLines.add(line);
      }
    }
    
    newContent = newLines.join('\n');
    
    if (conversions > 0) {
      if (dryRun) {
        print('🔍 [DRY RUN] $filePath: $conversions conversions would be made');
      } else {
        await file.writeAsString(newContent);
        print('✅ $filePath: $conversions conversions completed');
      }
    }
    
    return conversions;
  }

  String addImport(String content, String filePath) {
    final lines = content.split('\n');
    
    // Find last import line
    var lastImportIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        lastImportIndex = i;
      }
    }
    
    // Calculate relative path
    final depth = filePath.split('/').length - 2;
    final relativePath = '../' * depth + 'utils/waste_app_logger.dart';
    
    if (lastImportIndex >= 0) {
      lines.insert(lastImportIndex + 1, "import '$relativePath';");
    } else {
      lines.insert(0, "import '$relativePath';");
    }
    
    return lines.join('\n');
  }

  String convertDebugPrintLine(String line, String filePath) {
    final indent = getIndent(line);
    final serviceType = getServiceType(filePath);
    final fileName = filePath.split('/').last.replaceAll('.dart', '');
    
    // Simple pattern matching for common debugPrint patterns
    if (line.contains('Error') || line.contains('Failed') || line.contains('❌') || line.contains('🔥')) {
      return '${indent}WasteAppLogger.severe(\'Error occurred\', null, null, {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    } else if (line.contains('Warning') || line.contains('⚠️')) {
      return '${indent}WasteAppLogger.warning(\'Warning occurred\', null, null, {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    } else if (line.contains('Cache') || line.contains('🔍')) {
      return '${indent}WasteAppLogger.cacheEvent(\'cache_operation\', \'classification\', context: {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    } else if (line.contains('AI') || line.contains('OpenAI') || line.contains('GPT')) {
      return '${indent}WasteAppLogger.aiEvent(\'AI operation\', null, null, {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    } else if (line.contains('Performance') || line.contains('📊')) {
      return '${indent}WasteAppLogger.performanceLog(\'$serviceType\', 0, context: {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    } else {
      return '${indent}WasteAppLogger.info(\'Operation completed\', null, null, {\'service\': \'$serviceType\', \'file\': \'$fileName\'});';
    }
  }

  String getIndent(String line) {
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }

  String getServiceType(String filePath) {
    if (filePath.contains('services/')) {
      return filePath.split('/').last.replaceAll('_service.dart', '').replaceAll('.dart', '');
    } else if (filePath.contains('providers/')) {
      return filePath.split('/').last.replaceAll('_provider.dart', '').replaceAll('.dart', '');
    } else if (filePath.contains('screens/')) {
      return 'screen';
    } else if (filePath.contains('widgets/')) {
      return 'widget';
    } else {
      return 'utility';
    }
  }
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
} 