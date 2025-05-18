import 'share_service.dart';

// Web implementation of share service without using share_plus web
extension ShareServiceImpl on ShareService {
  static Future<void> _importSharePlus(String text, String? subject, List<String>? files) async {
    // Implement a custom web sharing solution
    // For now, just use the basic _shareOnWeb method
    await ShareService._shareOnWeb(text, subject);
  }
}
