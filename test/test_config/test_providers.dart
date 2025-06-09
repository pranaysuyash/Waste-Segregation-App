import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import '../../lib/services/ad_service.dart';
import '../../lib/providers/theme_provider.dart';
import '../../lib/providers/data_sync_provider.dart';

// Mock classes for testing
class MockAdService extends Mock implements AdService {}
class MockThemeProvider extends Mock implements ThemeProvider {}
class MockDataSyncProvider extends Mock implements DataSyncProvider {}

/// Test providers configuration for golden tests and widget tests
class TestProviders {
  static List<ChangeNotifierProvider> get allProviders => [
    ChangeNotifierProvider<AdService>(
      create: (_) => MockAdService(),
    ),
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => MockThemeProvider(),
    ),
    ChangeNotifierProvider<DataSyncProvider>(
      create: (_) => MockDataSyncProvider(),
    ),
  ];

  /// Create a test widget wrapper with all providers
  static Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: allProviders,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Create a test widget wrapper with custom theme
  static Widget wrapWithProvidersAndTheme(
    Widget child, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MultiProvider(
      providers: allProviders,
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: child,
      ),
    );
  }

  /// Setup mock behaviors for common test scenarios
  static void setupMockBehaviors() {
    // Setup default mock behaviors here if needed
    // This can be called in setUp() methods of tests
  }
} 