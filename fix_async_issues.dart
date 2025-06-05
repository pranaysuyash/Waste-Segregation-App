import 'dart:io';

void main() async {
  print('🔧 Starting async issues fix...');
  
  // List of common patterns to fix
  final fixes = [
    // Missing await patterns
    {
      'pattern': r'(\s+)([a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\([^)]*\));(\s*//.*)?$',
      'description': 'Potential missing await for method calls',
    },
    
    // BuildContext across async gaps
    {
      'pattern': r'(await\s+[^;]+;\s*)(.*context\.[^;]+;)',
      'description': 'BuildContext usage after await',
    },
  ];
  
  // Files to check
  final filesToCheck = [
    'lib/main.dart',
    'lib/screens/auth_screen.dart',
    'lib/screens/content_detail_screen.dart',
    'lib/screens/family_creation_screen.dart',
    'lib/screens/image_capture_screen.dart',
    'lib/screens/modern_home_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/utils/share_service.dart',
  ];
  
  for (final filePath in filesToCheck) {
    final file = File(filePath);
    if (await file.exists()) {
      print('📁 Checking $filePath...');
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Check for common async issues
        if (line.contains('Navigator.') && 
            i > 0 && 
            lines[i-1].contains('await')) {
          print('⚠️  Line ${i+1}: Potential BuildContext issue after await');
        }
        
        if (line.contains('.then(') || 
            line.contains('.catchError(')) {
          print('💡 Line ${i+1}: Consider using await instead of .then()');
        }
      }
    }
  }
  
  print('✅ Analysis complete. Manual fixes may be needed.');
} 