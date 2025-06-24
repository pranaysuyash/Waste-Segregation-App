import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'utils/waste_app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    await WasteAppLogger.initialize();
    WasteAppLogger.info(
        '🌐 Starting simplified web debug mode', null, null, {'platform': kIsWeb ? 'web' : 'mobile', 'mode': 'debug'});
  }

  runApp(const DebugWasteApp());
}

class DebugWasteApp extends StatelessWidget {
  const DebugWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Segregation App - Debug',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const DebugHomePage(),
    );
  }
}

class DebugHomePage extends StatelessWidget {
  const DebugHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Waste Segregation App'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Debug Mode - Web Rendering Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              kIsWeb ? '✅ Running on Web Platform' : '❌ Not on Web Platform',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                WasteAppLogger.userAction('debug_button_pressed',
                    context: {'screen': 'debug_home', 'test_type': 'rendering'});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug test successful!')),
                );
              },
              child: const Text('Test Rendering'),
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: const Center(
                child: Text(
                  'If you can see this box,\nrendering is working!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
