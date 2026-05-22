import 'package:image_picker/image_picker.dart';

/// Canonical image picker constraints for waste-capture flows.
///
/// Keep capture flows aligned on one profile so Home, FAB, and fallback
/// capture paths produce consistent source images for classification.
class CaptureImageOptions {
  static const double maxWidth = 1200;
  static const double maxHeight = 1200;
  static const int imageQuality = 85;

  static Future<XFile?> pick(
    ImagePicker picker, {
    required ImageSource source,
  }) {
    return picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}
