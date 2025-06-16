import 'package:firebase_core/firebase_core.dart';
import 'package:waste_segregation_app/services/firebase_cleanup_service.dart';
import 'dart:io';

// IMPORTANT: This script is intended for administrative use only.
// It performs a hard deletion of a user's data from Firestore.
// This action is irreversible.

// --- HOW TO RUN ---
// 1. Make sure you are authenticated with Firebase. Run `firebase login`.
// 2. You must be signed into the app on a simulator/device as the admin user
//    (e.g., pranaysuyash@gmail.com) for the admin check to pass.
// 3. Run the script from the root of the project with a user ID as an argument:
//    dart run scripts/admin_delete_user.dart <USER_ID_TO_DELETE>
//
// Example:
// dart run scripts/admin_delete_user.dart 'some_firebase_user_id'

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: Please provide a User ID to delete.');
    print('Usage: dart run scripts/admin_delete_user.dart <USER_ID_TO_DELETE>');
    exit(1);
  }

  final userIdToDelete = args[0];
  print('--- Admin User Deletion Script ---');
  print('WARNING: This will permanently delete all Firestore data for user:');
  print('USER ID: $userIdToDelete');
  print('------------------------------------');
  print('You have 5 seconds to cancel (Ctrl+C)...');

  await Future.delayed(const Duration(seconds: 5));

  print('\nProceeding with deletion...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized.');

    final cleanupService = FirebaseCleanupService();
    
    print('🔑 Verifying admin credentials...');
    // The service method will handle the admin check.
    // Ensure you are logged into the app as the admin user.

    await cleanupService.adminDeleteUser(userIdToDelete);

    print('\n------------------------------------');
    print('✅ SUCCESS: All Firestore data for user $userIdToDelete has been deleted.');
    print('------------------------------------');
    exit(0);
  } catch (e) {
    print('\n❌ An error occurred:');
    print(e);
    print('\nDeletion failed. Please check the logs and ensure you are running this script with proper admin credentials.');
    exit(1);
  }
} 