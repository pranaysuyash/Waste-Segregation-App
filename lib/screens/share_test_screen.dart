import 'package:flutter/material.dart';
import 'package:waste_segregation_app/utils/share.dart';

class ShareTestScreen extends StatelessWidget {
  const ShareTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Service Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                ShareService.share(
                  text: 'Testing the cross-platform share service!',
                  subject: 'Waste Segregation App',
                );
              },
              child: const Text('Share Text'),
            ),
            const SizedBox(height: 20),
            const Text(
              'This test verifies that sharing works on both native platforms and web.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
