import 'package:flutter_test/flutter_test.dart';
import 'test_config/plugin_mock_setup.dart';

/// Main test runner that sets up all plugin mocks
void main() {
  // Set up plugin mocks before any tests run
  setUpAll(() {
    // Initialize Flutter binding first
    TestWidgetsFlutterBinding.ensureInitialized();
    PluginMockSetup.setupAll();
    TestHelpers.setUpAll();
  });

  // Clean up after all tests
  tearDownAll(() {
    TestHelpers.tearDownAll();
  });

  // This file can be used to run specific test suites
  // or as a template for individual test files
} 