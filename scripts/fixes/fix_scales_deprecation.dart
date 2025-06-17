import 'dart:io';

/// Script to replace deprecated 'scales' with 'min' and 'max' in TextScaleAddon.
/// Usage: dart run scripts/fixes/fix_scales_deprecation.dart [--dry-run]
void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final dirsToScan = [Directory('lib'), Directory('widgetbook'), Directory('test')];
  
  for (final dir in dirsToScan) {
    if (!await dir.exists()) {
      print('Warning: "${dir.path}" directory not found. Skipping.');
      continue;
    }

    print('Searching for files with "scales" usage in ${dir.path}...');
    
    final files = dir.listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>();
      
    var updatedFiles = 0;
    for (final file in files) {
      var content = await file.readAsString();
      final regex = RegExp(r'scales: \[(.*)\]');
      
      if (content.contains(regex)) {
        print('Found deprecated usage in: ${file.path}');
        
        content = content.replaceAllMapped(regex, (match) {
          final scaleValues = match.group(1)!.split(',').map((e) => e.trim()).toList();
          if (scaleValues.length >= 2) {
            return 'min: ${scaleValues.first}, max: ${scaleValues.last}';
          }
          return match.group(0)!; // Return original if format is unexpected
        });
        
        if (dryRun) {
          print('[DRY RUN] Would update ${file.path}');
        } else {
          await file.writeAsString(content);
          print('Updated ${file.path}');
          updatedFiles++;
        }
      }
    }
    
    print('\nScan of ${dir.path} complete.');
    if (updatedFiles > 0) {
      print('$updatedFiles file(s) updated in ${dir.path}.');
    } else {
      print('No files with deprecated "scales" usage found in ${dir.path}.');
    }
  }
} 