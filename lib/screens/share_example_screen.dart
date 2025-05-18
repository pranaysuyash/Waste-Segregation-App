import 'package:flutter/material.dart';
import '../utils/share_service.dart';

class ShareExampleScreen extends StatelessWidget {
  const ShareExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Share with SnackBar notification
                ShareService.share(
                  text: 'Check out this waste segregation app!',
                  subject: 'Waste Segregation App',
                  context: context,
                );
              },
              child: const Text('Share with SnackBar'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Set up callback
                ShareService.onShareComplete = (message) {
                  // Show a custom dialog instead of SnackBar
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Share Complete'),
                      content: Text(message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                };
                
                // Share with callback notification
                ShareService.share(
                  text: 'Check out this waste segregation app!',
                  subject: 'Waste Segregation App',
                );
              },
              child: const Text('Share with Dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
