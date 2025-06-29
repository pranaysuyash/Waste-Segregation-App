/// Firebase configuration for tests
/// This file is generated by CI to enable Firebase emulator usage

// Set to true when running in CI with Firebase emulator
const bool useFirebaseEmulator = false;

// Emulator configuration
const String emulatorHost = 'localhost';
const int firestoreEmulatorPort = 8080;
const int authEmulatorPort = 9099;
const int storageEmulatorPort = 9199;

/// Helper function to configure Firebase for tests
/// Call this in your test setUpAll() method
Future<void> configureFirebaseForTesting() async {
  if (useFirebaseEmulator) {
    // Configure Firebase to use emulators
    print('🧪 Configuring Firebase emulators for testing...');

    // Note: Actual Firebase initialization should be done in your test setup
    // This is just a configuration helper
    print('🔥 Firestore emulator: $emulatorHost:$firestoreEmulatorPort');
    print('🔐 Auth emulator: $emulatorHost:$authEmulatorPort');
    print('📦 Storage emulator: $emulatorHost:$storageEmulatorPort');
  } else {
    print('🧪 Using mock Firebase services for testing');
  }
}
