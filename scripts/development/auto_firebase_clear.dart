#!/usr/bin/env dart

import 'dart:io';

/// Automated Firebase data clearing script
/// This will clear all Firebase data without confirmation prompts
void main() async {
  print('🔥 Automated Firebase Data Clearing');
  print('===================================');
  
  // Check if Firebase CLI is available
  final firebaseResult = await Process.run('firebase', ['--version']);
  if (firebaseResult.exitCode != 0) {
    print('❌ Firebase CLI not found. Please install it first:');
    print('   npm install -g firebase-tools');
    exit(1);
  }
  
  print('✅ Firebase CLI found');
  print('🗑️  Clearing Firebase collections...');
  
  // Collections to clear
  final collections = [
    'users',
    'community_feed', 
    'community_stats',
    'families',
    'invitations',
    'shared_classifications',
    'analytics_events',
    'family_stats',
  ];
  
  for (final collection in collections) {
    print('   Clearing $collection...');
    
    // Use Firebase CLI to delete collection
    final result = await Process.run('firebase', [
      'firestore:delete',
      '--project', 'waste-segregation-app-b6e8b',
      '--recursive',
      '--force',
      collection
    ]);
    
    if (result.exitCode == 0) {
      print('   ✅ Cleared $collection');
    } else {
      print('   ⚠️  Warning: Could not clear $collection');
      print('       ${result.stderr}');
    }
  }
  
  print('\n✅ Firebase data clearing completed!');
  print('\n📱 Next steps:');
  print('   1. Firebase collections have been cleared');
  print('   2. Restart the app for a fresh experience');
  print('   3. All users will start with clean data');
}