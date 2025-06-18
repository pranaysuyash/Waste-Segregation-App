import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'utils/waste_app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test WasteAppLogger initialization
  try {
    await WasteAppLogger.initialize();
    WasteAppLogger.info('Test app startup initiated');
    if (kDebugMode) {
      print('✅ WasteAppLogger initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ WasteAppLogger failed: $e');
    }
  }
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Test App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Test - Waste Segregation App'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Web Test Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              kIsWeb ? 'Running on Web Platform' : 'Running on Mobile Platform',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                WasteAppLogger.info('Test button pressed');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logger test completed!')),
                );
              },
              child: const Text('Test Logger'),
            ),
          ],
        ),
      ),
    );
  }
} 