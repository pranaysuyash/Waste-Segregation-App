#!/usr/bin/env dart

import 'dart:io';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Custom overflow detection tool for Flutter widgets
/// Scans for common overflow patterns in widget files
void main(List<String> args) {
  if (args.isEmpty) {
    WasteAppLogger.info('Usage: dart tool/check_overflows.dart <file_path>');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    WasteAppLogger.severe('File not found: $filePath');
    exit(1);
  }

  final content = file.readAsStringSync();
  final lines = content.split('\n');
  
  var hasOverflowIssues = false;
  final issues = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNumber = i + 1;

    // Check for common overflow patterns
    if (_checkForOverflowPatterns(line, lineNumber, issues)) {
      hasOverflowIssues = true;
    }
  }

  if (hasOverflowIssues) {
    WasteAppLogger.info('🚨 Layout overflow issues detected in $filePath:');
    for (final issue in issues) {
      WasteAppLogger.info('  $issue');
    }
    exit(1);
  } else {
    WasteAppLogger.info('✅ No overflow issues detected in $filePath');
    exit(0);
  }
}

bool _checkForOverflowPatterns(String line, int lineNumber, List<String> issues) {
  var foundIssue = false;

  // Pattern 1: Fixed width/height without Flexible/Expanded
  if (line.contains(RegExp(r'width:\s*\d+')) && 
      !line.contains('Flexible') && 
      !line.contains('Expanded')) {
    issues.add('Line $lineNumber: Fixed width without Flexible/Expanded wrapper');
    foundIssue = true;
  }

  // Pattern 2: Large padding values that might cause overflow
  final paddingMatch = RegExp(r'padding:\s*EdgeInsets\.all\((\d+)\)').firstMatch(line);
  if (paddingMatch != null) {
    final paddingValue = int.tryParse(paddingMatch.group(1) ?? '0') ?? 0;
    if (paddingValue > 24) {
      issues.add('Line $lineNumber: Large padding value ($paddingValue) may cause overflow');
      foundIssue = true;
    }
  }

  // Pattern 3: Row with multiple fixed-width children
  if (line.contains('Row(') && line.contains('children:')) {
    // This is a simplified check - in a real implementation, you'd parse the widget tree
    issues.add('Line $lineNumber: Row detected - ensure children are wrapped in Flexible/Expanded');
    foundIssue = true;
  }

  // Pattern 4: Text without overflow handling
  if (line.contains('Text(') && 
      !line.contains('overflow:') && 
      !line.contains('maxLines:')) {
    issues.add('Line $lineNumber: Text widget without overflow handling');
    foundIssue = true;
  }

  // Pattern 5: Container with fixed dimensions in a scrollable context
  if (line.contains('Container(') && 
      (line.contains('width:') || line.contains('height:'))) {
    issues.add('Line $lineNumber: Container with fixed dimensions - consider using constraints');
    foundIssue = true;
  }

  return foundIssue;
} 