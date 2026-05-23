import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// A detected face region in an image.
class DetectedFace {
  const DetectedFace({required this.bounds});

  final ui.Rect bounds;
}

/// Result of face detection and blurring.
class FaceDetectionResult {
  const FaceDetectionResult({
    required this.processedImageBytes,
    required this.facesDetected,
    required this.facesBlurred,
  });

  final Uint8List processedImageBytes;
  final int facesDetected;
  final int facesBlurred;
}

/// Detects and blurs faces in images before community upload.
///
/// Phase 1 uses a simple pixelation approach (no ML dependency).
/// Phase 2 can swap in google_mlkit_face_detection for real detection.
class FaceDetectionService {
  /// Detect faces in image bytes.
  ///
  /// Phase 1: Returns empty list (no ML detection yet).
  /// Phase 2: Use google_mlkit_face_detection for real detection.
  Future<List<DetectedFace>> detectFaces(Uint8List imageBytes) async {
    // Phase 2: uncomment when google_mlkit_face_detection is added.
    // final inputImage = InputImage.fromBytes(bytes: imageBytes, ...);
    // final faces = await FaceDetector(options: ...).processImage(inputImage);
    // return faces.map((f) => DetectedFace(bounds: f.boundingBox)).toList();
    return [];
  }

  /// Blur detected face regions in the image.
  ///
  /// Uses pixelation (mosaic blur) to obscure face regions.
  /// Returns the original bytes unchanged if no faces are detected.
  Future<FaceDetectionResult> blurFaces(Uint8List imageBytes) async {
    final faces = await detectFaces(imageBytes);

    if (faces.isEmpty) {
      return FaceDetectionResult(
        processedImageBytes: imageBytes,
        facesDetected: 0,
        facesBlurred: 0,
      );
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      WasteAppLogger.warning('face_blur_decode_failed');
      return FaceDetectionResult(
        processedImageBytes: imageBytes,
        facesDetected: faces.length,
        facesBlurred: 0,
      );
    }

    var blurred = 0;
    for (final face in faces) {
      final x = face.bounds.left.toInt().clamp(0, decoded.width - 1);
      final y = face.bounds.top.toInt().clamp(0, decoded.height - 1);
      final w = face.bounds.width.toInt().clamp(1, decoded.width - x);
      final h = face.bounds.height.toInt().clamp(1, decoded.height - y);

      _pixelate(decoded, x, y, w, h, blockSize: 10);
      blurred++;
    }

    final encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));

    WasteAppLogger.info('faces_blurred', context: {
      'faces_detected': faces.length,
      'faces_blurred': blurred,
    });

    return FaceDetectionResult(
      processedImageBytes: encoded,
      facesDetected: faces.length,
      facesBlurred: blurred,
    );
  }

  /// Pixelate a region of the image (mosaic blur).
  void _pixelate(img.Image image, int x, int y, int w, int h,
      {int blockSize = 10}) {
    for (var by = y; by < y + h; by += blockSize) {
      for (var bx = x; bx < x + w; bx += blockSize) {
        // Average the block.
        var r = 0, g = 0, b = 0, count = 0;
        for (var dy = 0; dy < blockSize && by + dy < y + h; dy++) {
          for (var dx = 0; dx < blockSize && bx + dx < x + w; dx++) {
            if (bx + dx < image.width && by + dy < image.height) {
              final pixel = image.getPixel(bx + dx, by + dy);
              r += pixel.r.toInt();
              g += pixel.g.toInt();
              b += pixel.b.toInt();
              count++;
            }
          }
        }
        if (count == 0) continue;
        final avgR = r ~/ count;
        final avgG = g ~/ count;
        final avgB = b ~/ count;

        // Fill the block with the average color.
        for (var dy = 0; dy < blockSize && by + dy < y + h; dy++) {
          for (var dx = 0; dx < blockSize && bx + dx < x + w; dx++) {
            if (bx + dx < image.width && by + dy < image.height) {
              image.setPixelRgba(bx + dx, by + dy, avgR, avgG, avgB, 255);
            }
          }
        }
      }
    }
  }
}
