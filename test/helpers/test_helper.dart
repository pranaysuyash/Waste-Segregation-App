import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

/// Setup Firebase for testing
Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with test configuration
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  } catch (e) {
    // Firebase already initialized
  }
}

/// Create a test widget with minimal providers for golden tests
Widget createTestWidget({
  required Widget child,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: child,
    debugShowCheckedModeBanner: false,
  );
}

/// Create a test widget with Riverpod providers for golden tests
Widget createRiverpodTestWidget({
  required Widget child,
  ThemeData? theme,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: child,
      debugShowCheckedModeBanner: false,
    ),
  );
} 