import 'package:share_plus/share_plus.dart';
import 'share_service.dart';

// Native implementation of share service using share_plus
extension ShareServiceImpl on ShareService {
  static Future<void> _importSharePlus(String text, String? subject, List<String>? files) async {
    if (files != null && files.isNotEmpty) {
      await Share.shareFiles(
        files,
        text: text,
        subject: subject,
      );
    } else {
      await Share.share(
        text,
        subject: subject,
      );
    }
  }
}
