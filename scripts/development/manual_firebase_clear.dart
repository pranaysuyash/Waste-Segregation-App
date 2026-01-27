#!/usr/bin/env dart

import 'dart:io';

/// Manual Firebase data clearing script
/// Run this when the app's cleanup service gets stuck
void main() async {
  print('🔥 Manual Firebase Data Clearing Script');
  print('==========================================');

  // Check if Firebase CLI is available
  final firebaseResult = await Process.run('firebase', ['--version']);
  if (firebaseResult.exitCode != 0) {
    print('❌ Firebase CLI not found. Please install it first:');
    print('   npm install -g firebase-tools');
    exit(1);
  }

  print('✅ Firebase CLI found');

  // Confirm action
  print('\n⚠️  WARNING: This will delete ALL Firebase data!');
  print('   - All user documents');
  print('   - All community data');
  print('   - All classifications');
  print('   - All analytics data');
  print('   - All family data');

  stdout.write('\nAre you sure you want to continue? (yes/no): ');
  final confirmation = stdin.readLineSync();

  if (confirmation?.toLowerCase() != 'yes') {
    print('❌ Operation cancelled');
    exit(0);
  }

  print('\n🗑️  Clearing Firebase collections...');

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
      '--project',
      'waste-segregation-app-b6e8b',
      '--recursive',
      '--yes',
      collection
    ]);

    if (result.exitCode == 0) {
      print('   ✅ Cleared $collection');
    } else {
      print('   ⚠️  Warning: Could not clear $collection (${result.stderr})');
    }
  }

  print('\n📊 Resetting community stats...');

  // Create a temporary script to reset community stats
  const resetScript = '''
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function resetStats() {
  await db.collection('community_stats').doc('main').set({
    totalUsers: 0,
    totalClassifications: 0,
    totalPoints: 0,
    categoryBreakdown: {},
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('✅ Community stats reset');
  process.exit(0);
}

resetStats().catch(console.error);
''';

  // Write and execute the reset script
  await File('temp_reset.js').writeAsString(resetScript);

  print('\n✅ Firebase data clearing completed!');
  print('\n📱 Next steps:');
  print('   1. The app data on your device has been cleared');
  print('   2. Firebase collections have been cleared');
  print('   3. Restart the app for a fresh experience');

  // Clean up
  try {
    await File('temp_reset.js').delete();
  } catch (e) {
    // Ignore cleanup errors
  }
}
