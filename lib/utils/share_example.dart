import 'package:flutter/material.dart';
import 'share.dart';

// Example widget showing how to use the ShareService
class ShareExample extends StatelessWidget {
  const ShareExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Use the ShareService instead of Share.share directly
        ShareService.share(
          text: 'Check out this waste segregation app!',
          subject: 'Great App for Waste Management',
          // Optional file paths
          // files: ['/path/to/image.jpg'],
        );
      },
      child: const Text('Share This App'),
    );
  }
}

// Example of how to refactor existing Share.share calls:
/*
// BEFORE:
import 'package:share_plus/share_plus.dart';

void shareContent() {
  Share.share(
    'Check out this app!',
    subject: 'Great App',
  );
}

// AFTER:
import 'package:your_app/utils/share.dart';

void shareContent() {
  ShareService.share(
    text: 'Check out this app!',
    subject: 'Great App',
  );
}
*/
