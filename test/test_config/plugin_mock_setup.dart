import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Test configuration to setup plugin mocks and prevent MissingPluginException
class PluginMockSetup {
  /// Setup all plugin mocks for testing
  static void setupAll() {
    setupPathProvider();
    setupSharedPreferences();
    setupDeviceInfo();
    setupPackageInfo();
    setupImagePicker();
    setupCamera();
  }

  /// Mock path_provider plugin
  static void setupPathProvider() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    // Create a temporary directory that actually exists and is writable
    final tempDir = Directory.systemTemp.createTempSync('flutter_test_');
    final testPath = tempDir.path;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return '$testPath/documents';
          case 'getApplicationSupportDirectory':
            return '$testPath/support';
          case 'getTemporaryDirectory':
            return '$testPath/tmp';
          case 'getExternalStorageDirectory':
            return '$testPath/external';
          case 'getDownloadsDirectory':
            return '$testPath/downloads';
          default:
            return null;
        }
      },
    );
  }

  /// Mock shared_preferences plugin
  static void setupSharedPreferences() {
    SharedPreferences.setMockInitialValues({
      'performance_log': '{}',
      'analytics_data': '{}',
      'user_preferences': '{}',
      'educational_progress': '{}',
      'achievements': '[]',
      'points': '0',
      'classification_history': '[]',
    });
  }

  /// Mock device_info plugin
  static void setupDeviceInfo() {
    const channel = MethodChannel('plugins.flutter.io/device_info');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAndroidDeviceInfo':
            return {
              'model': 'Test Device',
              'brand': 'Test Brand',
              'device': 'test_device',
              'hardware': 'test_hardware',
              'androidId': 'test_android_id',
            };
          case 'getIosDeviceInfo':
            return {
              'model': 'Test iPhone',
              'name': 'Test Device',
              'systemName': 'iOS',
              'systemVersion': '15.0',
              'identifierForVendor': 'test_ios_id',
            };
          default:
            return {};
        }
      },
    );
  }

  /// Mock package_info plugin
  static void setupPackageInfo() {
    const channel = MethodChannel('plugins.flutter.io/package_info');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return {
          'appName': 'Waste Segregation App Test',
          'packageName': 'com.example.waste_segregation_app',
          'version': '1.0.0+test',
          'buildNumber': 'test',
        };
      },
    );
  }

  /// Mock image_picker plugin
  static void setupImagePicker() {
    const channel = MethodChannel('plugins.flutter.io/image_picker');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'pickImage':
            // Return mock image path
            return '/mock/test_image.jpg';
          case 'pickVideo':
            return '/mock/test_video.mp4';
          default:
            return null;
        }
      },
    );
  }

  /// Mock camera plugin
  static void setupCamera() {
    const channel = MethodChannel('plugins.flutter.io/camera');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'availableCameras':
            return [
              {
                'name': 'Test Camera',
                'lensDirection': 'back',
                'sensorOrientation': 90,
              }
            ];
          case 'create':
            return {'cameraId': 1};
          case 'initialize':
            return null;
          case 'dispose':
            return null;
          default:
            return null;
        }
      },
    );
  }

  /// Mock Firebase plugins
  static void setupFirebase() {
    // Mock Firebase Core
    const coreChannel = MethodChannel('plugins.flutter.io/firebase_core');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      coreChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'Firebase#initializeCore':
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': 'test-api-key',
                  'appId': 'test-app-id',
                  'projectId': 'test-project',
                },
                'pluginConstants': {},
              }
            ];
          default:
            return null;
        }
      },
    );

    // Mock Firestore
    const firestoreChannel = MethodChannel('plugins.flutter.io/cloud_firestore');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      firestoreChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'DocumentReference#set':
          case 'DocumentReference#update':
          case 'CollectionReference#add':
            return null;
          case 'DocumentReference#get':
            return {
              'path': 'test/doc',
              'data': {},
              'metadata': {
                'hasPendingWrites': false,
                'isFromCache': false,
              },
            };
          case 'Query#get':
            return {
              'paths': [],
              'documents': [],
              'documentChanges': [],
              'metadata': {
                'hasPendingWrites': false,
                'isFromCache': false,
              },
            };
          default:
            return null;
        }
      },
    );
  }

  /// Mock network connectivity
  static void setupConnectivity() {
    const channel = MethodChannel('dev.fluttercommunity/connectivity');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'check':
            return 'wifi';
          case 'wifiName':
            return 'Test WiFi';
          case 'wifiBSSID':
            return '00:00:00:00:00:00';
          case 'wifiIPAddress':
            return '192.168.1.1';
          default:
            return null;
        }
      },
    );
  }

  /// Mock permission handler
  static void setupPermissions() {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkPermissionStatus':
          case 'requestPermissions':
            return {0: 1}; // granted
          case 'shouldShowRequestPermissionRationale':
            return false;
          case 'openAppSettings':
            return true;
          default:
            return null;
        }
      },
    );
  }

  /// Cleanup all mocks after tests
  static void tearDownAll() {
    // Reset all method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/device_info'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/package_info'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/cloud_firestore'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity/connectivity'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  }

  /// Create mock file for testing
  static File createMockImageFile() {
    final file = File('/mock/test_image.jpg');
    return file;
  }

  /// Create mock file bytes for testing
  static List<int> createMockImageBytes() {
    // Simple mock image data (placeholder)
    return List.generate(1024, (index) => index % 256);
  }

  /// Mock HTTP client responses
  static void setupHttpMocks() {
    // This would typically use http_mock_adapter or similar
    // For basic testing, we can mock at the service level
  }
}

/// Test helper for common test setups
class TestHelpers {
  /// Standard test setup that includes all plugin mocks
  static void setUpAll() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PluginMockSetup.setupAll();
  }

  /// Standard test cleanup
  static void tearDownAll() {
    PluginMockSetup.tearDownAll();
  }

  /// Create a test environment with mocked dependencies
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Mock delayed operations for performance testing
  static Future<T> mockAsyncOperation<T>(
    T result, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    await Future.delayed(delay);
    return result;
  }

  /// Mock network operation with controllable latency
  static Future<Map<String, dynamic>> mockNetworkCall({
    Duration delay = const Duration(milliseconds: 500),
    bool shouldFail = false,
  }) async {
    await Future.delayed(delay);

    if (shouldFail) {
      throw Exception('Mock network error');
    }

    return {
      'status': 'success',
      'data': {'message': 'Mock response'},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Mock image classification result
  static Future<Map<String, dynamic>> mockClassificationResult({
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);

    return {
      'category': 'Recyclable',
      'confidence': 0.95,
      'item_name': 'Plastic Bottle',
      'disposal_instructions': 'Place in recycling bin',
      'environmental_impact': 'Can be recycled into new products',
    };
  }
}

/// Performance testing utilities
class PerformanceTestHelpers {
  /// Measure widget build time
  static Future<Duration> measureBuildTime(
    WidgetTester tester,
    Widget widget,
  ) async {
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measure animation performance
  static Future<Map<String, dynamic>> measureAnimationPerformance(
    WidgetTester tester,
    VoidCallback triggerAnimation,
  ) async {
    final frameTimes = <Duration>[];
    final stopwatch = Stopwatch();

    // Start measuring
    stopwatch.start();
    triggerAnimation();

    // Pump frames and measure timing
    while (tester.binding.hasScheduledFrame) {
      final frameStart = stopwatch.elapsed;
      await tester.pump();
      final frameEnd = stopwatch.elapsed;
      frameTimes.add(frameEnd - frameStart);
    }

    stopwatch.stop();

    if (frameTimes.isEmpty) {
      return {'total_time': Duration.zero, 'frame_count': 0, 'avg_frame_time': Duration.zero};
    }

    final totalTime = stopwatch.elapsed;
    final frameCount = frameTimes.length;
    final avgFrameTime = Duration(
      microseconds: frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) ~/ frameCount,
    );

    return {
      'total_time': totalTime,
      'frame_count': frameCount,
      'avg_frame_time': avgFrameTime,
      'frame_times': frameTimes,
    };
  }

  /// Check if performance meets targets
  static bool meetsPerformanceTargets(Map<String, dynamic> metrics) {
    final avgFrameTime = metrics['avg_frame_time'] as Duration;
    final totalTime = metrics['total_time'] as Duration;

    // 60fps = 16.67ms per frame
    const maxFrameTime = Duration(milliseconds: 17);
    const maxTotalTime = Duration(seconds: 1);

    return avgFrameTime <= maxFrameTime && totalTime <= maxTotalTime;
  }
}
