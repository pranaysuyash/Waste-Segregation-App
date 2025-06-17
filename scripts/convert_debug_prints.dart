import 'dart:io';

/// Script to automatically convert debugPrint calls to WasteAppLogger calls
/// Usage: dart run scripts/convert_debug_prints.dart [--dry-run] [--file=path] [--priority=1-3]
void main(List<String> args) async {
  final converter = DebugPrintConverter();
  
  // Parse command line arguments
  final dryRun = args.contains('--dry-run');
  final fileArg = args.where((arg) => arg.startsWith('--file=')).firstOrNull;
  final priorityArg = args.where((arg) => arg.startsWith('--priority=')).firstOrNull;
  
  if (fileArg != null) {
    // Convert single file
    final filePath = fileArg.split('=')[1];
    await converter.convertFile(filePath, dryRun: dryRun);
  } else if (priorityArg != null) {
    // Convert by priority level
    final priority = int.parse(priorityArg.split('=')[1]);
    await converter.convertByPriority(priority, dryRun: dryRun);
  } else {
    // Convert all files
    await converter.convertAll(dryRun: dryRun);
  }
}

class DebugPrintConverter {
  final Map<String, List<String>> priorityFiles = {
    '1': [
      'lib/services/gamification_service.dart',
      'lib/services/ai_service.dart',
      'lib/services/cloud_storage_service.dart',
      'lib/services/storage_service.dart',
      'lib/services/cache_service.dart',
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
    ]
  };

  /// Convert files by priority level (1=highest, 3=lowest)
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

  /// Convert all files with debugPrint calls
  Future<void> convertAll({bool dryRun = false}) async {
    print('🚀 Starting comprehensive debugPrint conversion...');
    
    // Get all Dart files with debugPrint calls
    final result = await Process.run('grep', [
      '-R', '-l', 'debugPrint(', 'lib/',
      '--include=*.dart'
    ]);
    
    if (result.exitCode != 0) {
      print('❌ Error finding files with debugPrint calls');
      return;
    }
    
    final files = (result.stdout as String)
        .split('\n')
        .where((line) => line.isNotEmpty && !line.contains('test/'))
        .toList();
    
    print('📁 Found ${files.length} files with debugPrint calls');
    
    var totalConverted = 0;
    for (final filePath in files) {
      final converted = await convertFile(filePath, dryRun: dryRun);
      totalConverted += converted;
    }
    
    print('🎉 Conversion complete: $totalConverted total conversions across ${files.length} files');
  }

  /// Convert debugPrint calls in a single file
  Future<int> convertFile(String filePath, {bool dryRun = false}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print('❌ File not found: $filePath');
      return 0;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');
    
    // Check if WasteAppLogger import exists
    final hasWasteAppLoggerImport = content.contains("import '../utils/waste_app_logger.dart'") ||
                                   content.contains("import '../../utils/waste_app_logger.dart'") ||
                                   content.contains("import 'package:waste_segregation_app/utils/waste_app_logger.dart'");
    
    var newContent = content;
    var conversions = 0;
    
    // Add WasteAppLogger import if needed
    if (!hasWasteAppLoggerImport && content.contains('debugPrint(')) {
      newContent = _addWasteAppLoggerImport(newContent, filePath);
      print('📦 Added WasteAppLogger import to $filePath');
    }
    
    // Convert each debugPrint call
    final debugPrintRegex = RegExp(r"debugPrint\('([^']*)'(?:, (.+))?\);?");
    final matches = debugPrintRegex.allMatches(newContent).toList();
    
    // Process matches in reverse order to maintain string positions
    for (final match in matches.reversed) {
      final originalCall = match.group(0)!;
      final message = match.group(1)!;
      final additionalArgs = match.group(2);
      
      final replacement = _generateWasteAppLoggerCall(message, filePath, additionalArgs);
      newContent = newContent.replaceRange(match.start, match.end, replacement);
      conversions++;
    }
    
    // Handle debugPrint calls with string interpolation and complex patterns
    newContent = _handleComplexDebugPrints(newContent, filePath);
    
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

  /// Add WasteAppLogger import to file
  String _addWasteAppLoggerImport(String content, String filePath) {
    final lines = content.split('\n');
    var importInserted = false;
    
    // Find the right place to insert the import
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Insert after the last import statement
      if (line.startsWith('import ') && 
          (i + 1 >= lines.length || !lines[i + 1].startsWith('import '))) {
        
        // Determine the correct relative path
        final depth = filePath.split('/').length - 2; // lib/ is depth 1
        final relativePath = '../' * depth + 'utils/waste_app_logger.dart';
        
        lines.insert(i + 1, "import '$relativePath';");
        importInserted = true;
        break;
      }
    }
    
    // If no imports found, add at the beginning
    if (!importInserted) {
      final depth = filePath.split('/').length - 2;
      final relativePath = '../' * depth + 'utils/waste_app_logger.dart';
      lines.insert(0, "import '$relativePath';");
    }
    
    return lines.join('\n');
  }

  /// Generate appropriate WasteAppLogger call based on message content
  String _generateWasteAppLoggerCall(String message, String filePath, String? additionalArgs) {
    final fileName = filePath.split('/').last.replaceAll('.dart', '');
    final serviceType = _getServiceType(filePath);
    
    // Determine log level based on message content
    if (message.contains('Error') || message.contains('❌') || message.contains('🔥') || 
        message.contains('Failed') || message.contains('Exception')) {
      return _generateSevereCall(message, fileName, serviceType, additionalArgs);
    } else if (message.contains('Warning') || message.contains('⚠️') || 
               message.contains('Skipped') || message.contains('Missing')) {
      return _generateWarningCall(message, fileName, serviceType, additionalArgs);
    } else if (message.contains('Cache') || message.contains('🔍') || 
               message.contains('hit') || message.contains('miss')) {
      return _generateCacheEventCall(message, fileName, serviceType, additionalArgs);
    } else if (message.contains('Performance') || message.contains('📊') || 
               message.contains('Analytics') || message.contains('timing')) {
      return _generatePerformanceCall(message, fileName, serviceType, additionalArgs);
    } else if (message.contains('AI') || message.contains('OpenAI') || 
               message.contains('GPT') || message.contains('tokens')) {
      return _generateAIEventCall(message, fileName, serviceType, additionalArgs);
    } else if (message.contains('User') || message.contains('🎮') || 
               message.contains('action') || message.contains('interaction')) {
      return _generateUserActionCall(message, fileName, serviceType, additionalArgs);
    } else {
      return _generateInfoCall(message, fileName, serviceType, additionalArgs);
    }
  }

  /// Generate severe error log call
  String _generateSevereCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.severe('$cleanMessage', ${additionalArgs ?? 'null'}, null, {'service': '$serviceType', 'file': '$fileName', 'action': 'error_handling'});";
  }

  /// Generate warning log call
  String _generateWarningCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.warning('$cleanMessage', ${additionalArgs ?? 'null'}, null, {'service': '$serviceType', 'file': '$fileName'});";
  }

  /// Generate cache event log call
  String _generateCacheEventCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    final eventType = message.contains('hit') ? 'cache_hit' : 
                     message.contains('miss') ? 'cache_miss' : 'cache_operation';
    
    return "WasteAppLogger.cacheEvent('$eventType', 'classification', context: {'message': '$cleanMessage', 'service': '$serviceType', 'file': '$fileName'});";
  }

  /// Generate performance log call
  String _generatePerformanceCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.performanceLog('$serviceType', 0, context: {'message': '$cleanMessage', 'file': '$fileName', 'operation': '$serviceType'});";
  }

  /// Generate AI event log call
  String _generateAIEventCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.aiEvent('$cleanMessage', null, null, {'service': '$serviceType', 'file': '$fileName', 'event_type': 'ai_processing'});";
  }

  /// Generate user action log call
  String _generateUserActionCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.userAction('$cleanMessage', context: {'service': '$serviceType', 'file': '$fileName'});";
  }

  /// Generate info log call
  String _generateInfoCall(String message, String fileName, String serviceType, String? additionalArgs) {
    final cleanMessage = _cleanMessage(message);
    return "WasteAppLogger.info('$cleanMessage', null, null, {'service': '$serviceType', 'file': '$fileName'});";
  }

  /// Handle complex debugPrint patterns with string interpolation
  String _handleComplexDebugPrints(String content, String filePath) {
    final fileName = filePath.split('/').last.replaceAll('.dart', '');
    final serviceType = _getServiceType(filePath);
    
    // A simpler regex to capture the message inside debugPrint()
    final complexRegex = RegExp(r'debugPrint\((.*)\);');
    
    content = content.replaceAllMapped(complexRegex, (match) {
      final fullMatch = match.group(0)!;
      // Avoid replacing our own logger calls if they get caught
      if (fullMatch.contains('WasteAppLogger')) return fullMatch;
      
      final messageExpression = match.group(1)!;

      // Handle simple strings separately
      if ((messageExpression.startsWith("'") && messageExpression.endsWith("'")) ||
          (messageExpression.startsWith('"') && messageExpression.endsWith('"'))) {
        final message = messageExpression.substring(1, messageExpression.length - 1);
        final cleanMessage = _cleanMessage(message);
        return "WasteAppLogger.info('$cleanMessage', null, null, {'service': '$serviceType', 'file': '$fileName'});";
      }

      // For interpolated strings or variables, wrap them
      return "WasteAppLogger.info(($messageExpression).toString(), null, null, {'service': '$serviceType', 'file': '$fileName'});";
    });
    
    return content;
  }

  /// Clean message by removing emojis and extra formatting
  String _cleanMessage(String message) {
    return message
        .replaceAll(RegExp(r'[🔥🚨⚠️✅❌📊🎮🔍🛡️💾⏭️🔄🌍🖼️📁🎯🚀📈🔧]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Determine service type from file path
  String _getServiceType(String filePath) {
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

extension _ListExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
} 