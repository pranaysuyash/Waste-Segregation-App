import 'dart:io';

/// Script to replace deprecated 'dart:js' with 'dart:js_interop'.
/// Usage: dart run scripts/fixes/fix_dart_js_deprecation.dart [--dry-run]
void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final libDir = Directory('lib');
  
  if (!await libDir.exists()) {
    print('Error: "lib" directory not found. Run this script from the project root.');
    exit(1);
  }

  print('Searching for files with "dart:js" import...');
  
  final files = libDir.listSync(recursive: true)
    .where((entity) => entity is File && entity.path.endsWith('.dart'))
    .cast<File>();
    
  var updatedFiles = 0;
  for (final file in files) {
    var content = await file.readAsString();
    if (content.contains("'dart:js'")) {
      print('Found deprecated import in: ${file.path}');
      
      content = content.replaceAll("'dart:js'", "'dart:js_interop'");
      
      if (dryRun) {
        print('[DRY RUN] Would update ${file.path}');
      } else {
        await file.writeAsString(content);
        print('Updated ${file.path}');
        updatedFiles++;
      }
    }
  }

  print('\nScan complete.');
  if (updatedFiles > 0) {
    print('$updatedFiles file(s) updated.');
  } else {
    print('No files with deprecated "dart:js" import found.');
  }
} 