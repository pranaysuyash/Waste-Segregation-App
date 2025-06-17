import 'dart:io';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Script to remove unused imports from all Dart files in the project.
/// Usage: dart run scripts/fixes/remove_unused_imports.dart [--dry-run]
void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final projectDir = Directory('.');
  
  if (!await projectDir.exists()) {
    WasteAppLogger.severe('Error: Project directory not found. Run this script from the project root.');
    exit(1);
  }

  WasteAppLogger.info('Searching for Dart files...');
  
  final files = projectDir.listSync(recursive: true)
    .where((entity) => entity is File && entity.path.endsWith('.dart'))
    .cast<File>();
    
  var updatedFiles = 0;
  final unusedImportRegex = RegExp(r"warning • Unused import: '.*' • (.*) • unused_import");

  final analyzeResult = await Process.run('flutter', ['analyze']);
  final lines = (analyzeResult.stdout as String).split('\n');
  
  final filesWithUnusedImports = <String>{};
  for (final line in lines) {
    final match = unusedImportRegex.firstMatch(line);
    if (match != null) {
      final filePath = match.group(1)!.split(' • ')[0];
      filesWithUnusedImports.add(filePath);
    }
  }

  WasteAppLogger.info('Found \\${filesWithUnusedImports.length} files with unused imports.');

  for (final filePath in filesWithUnusedImports) {
    final file = File(filePath);
    if (!await file.exists()) continue;

    WasteAppLogger.info('Processing \\${file.path}');
    var content = await file.readAsString();
    final originalContent = content;
    
    final importLines = content.split('\n').where((l) => l.trim().startsWith('import ')).toList();
    
    for (final importLine in importLines) {
      final importPath = importLine.split(' ')..remove('import')..removeWhere((e) => e.isEmpty);
      final importPackage = importPath.first.replaceAll("'", '').replaceAll('"', '');

      if (!content.contains(importPackage.split('/').last.split('.').first)) {
         content = content.replaceFirst(importLine, '');
      }
    }

    if (originalContent != content) {
      if (dryRun) {
        WasteAppLogger.info('[DRY RUN] Would remove unused imports from \\${file.path}');
      } else {
        await file.writeAsString(content);
        WasteAppLogger.info('Removed unused imports from \\${file.path}');
        updatedFiles++;
      }
    }
  }


  WasteAppLogger.info('\nScan complete.');
  if (updatedFiles > 0) {
    WasteAppLogger.info('\\$updatedFiles file(s) updated.');
  } else {
    WasteAppLogger.info('No files with unused imports found or fixed.');
  }
} 