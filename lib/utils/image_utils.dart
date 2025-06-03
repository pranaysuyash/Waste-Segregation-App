import 'dart:async';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utility class for image manipulation and hashing
class ImageUtils {
  /// Default dimensions for image normalization
  static const int defaultTargetWidth = 300;
  static const int defaultTargetHeight = 300;

  /// Generates a perceptual hash of the image data
  ///
  /// This method creates a consistent identifier for visually similar images,
  /// making it robust to small variations in camera position, lighting, etc.
  ///
  /// [imageBytes]: The raw image data as Uint8List
  /// [normalize]: Whether to normalize the image before hashing (recommended)
  ///
  /// Returns a String representation of the hash
  static Future<String> generateImageHash(
    Uint8List imageBytes, {
    bool normalize = true,
  }) async {
    try {
      // Preprocess the image (smaller size and grayscale for consistent hashing)
      final processedBytes = await preprocessImage(
        imageBytes,
        targetWidth: 32, // Much smaller size for perceptual hashing
        targetHeight: 32, // Small square image
        applyStrongerBlur: true, // Apply stronger blur to reduce noise
      );

      // Generate a perceptual hash (pHash) from the image
      // This is more robust to minor variations than cryptographic hashing
      final pHash = await compute(_generatePerceptualHash, processedBytes);

      return pHash;
    } catch (e) {
      debugPrint('Error generating perceptual image hash: $e');

      // Fallback to a simpler hash if perceptual hashing fails
      try {
        // Generate a simple average hash as fallback
        final bytesToHash = await preprocessImage(imageBytes,
            targetWidth: 16, targetHeight: 16);

        // Use SHA-256 on the preprocessed image
        final digest = sha256.convert(bytesToHash);
        return 'fallback_${digest.toString()}';
      } catch (e2) {
        // Last resort fallback
        debugPrint('Error in fallback hash generation: $e2');
        final simpleHash = imageBytes.length.toString() +
            imageBytes[0].toString() +
            imageBytes[imageBytes.length ~/ 2].toString() +
            imageBytes[imageBytes.length - 1].toString();
        return 'simple_$simpleHash';
      }
    }
  }

  /// Generates a perceptual hash (pHash) for an image
  /// This runs in an isolate for better performance
  static String _generatePerceptualHash(Uint8List processedImageBytes) {
    try {
      // Decode the image
      final image = img.decodeImage(processedImageBytes);
      if (image == null) {
        throw Exception('Failed to decode image for perceptual hashing');
      }

      // Ensure we're working with a grayscale image
      final grayImage = img.grayscale(image);

      // Resize to exactly 8x8 for DCT (Discrete Cosine Transform approximation)
      final smallImage = img.copyResize(grayImage, width: 8, height: 8);

      // Calculate the average pixel value
      var totalValue = 0;
      final pixelValues = <int>[];

      for (var y = 0; y < smallImage.height; y++) {
        for (var x = 0; x < smallImage.width; x++) {
          final pixel = smallImage.getPixel(x, y);
          // Get grayscale value (all channels should be the same in grayscale)
          final value = img.getLuminance(pixel);
          totalValue += value.toInt();
          pixelValues.add(value.toInt());
        }
      }

      // Calculate the average
      final avgValue = totalValue ~/ (smallImage.width * smallImage.height);

      // Generate the hash by comparing each pixel to the average
      // Result is a 64-bit hash (8x8 grid)
      var hashBits = '';
      for (var value in pixelValues) {
        hashBits += (value >= avgValue) ? '1' : '0';
      }

      // Convert binary string to hexadecimal for easier storage and comparison
      // (16 hex characters to represent 64 bits)
      var hexHash = '';
      for (var i = 0; i < 64; i += 4) {
        if (i + 4 <= hashBits.length) {
          final chunk = hashBits.substring(i, i + 4);
          final hexDigit = int.parse(chunk, radix: 2).toRadixString(16);
          hexHash += hexDigit;
        }
      }

      return 'phash_$hexHash';
    } catch (e) {
      debugPrint('Error in perceptual hash calculation: $e');
      // Return a consistent error string that won't match actual hashes
      return 'error_hash_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Preprocesses an image for consistent hashing
  ///
  /// This method normalizes images by:
  /// 1. Resizing to standard dimensions
  /// 2. Converting to grayscale (optional)
  /// 3. Applying blur to reduce noise sensitivity
  ///
  /// [imageBytes]: The raw image data
  /// [targetWidth]: Target width for resizing
  /// [targetHeight]: Target height for resizing
  /// [convertToGrayscale]: Whether to convert to grayscale
  /// [applyStrongerBlur]: Whether to apply stronger blur for more robust hashing
  ///
  /// Returns preprocessed image bytes
  static Future<Uint8List> preprocessImage(
    Uint8List imageBytes, {
    int targetWidth = defaultTargetWidth,
    int targetHeight = defaultTargetHeight,
    bool convertToGrayscale = true,
    bool applyStrongerBlur = false,
  }) async {
    // Use compute for better performance on large images
    return compute(
        _preprocessImageIsolate,
        _PreprocessImageArgs(
          imageBytes: imageBytes,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          convertToGrayscale: convertToGrayscale,
          applyStrongerBlur: applyStrongerBlur,
        ));
  }

  /// Helper method to run image preprocessing in an isolate
  static Future<Uint8List> _preprocessImageIsolate(
      _PreprocessImageArgs args) async {
    try {
      // Decode the image
      final image = img.decodeImage(args.imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize the image to standard dimensions
      final resizedImage = img.copyResize(
        image,
        width: args.targetWidth,
        height: args.targetHeight,
        interpolation: img.Interpolation.average,
      );

      // Convert to grayscale if requested
      final processedImage =
          args.convertToGrayscale ? img.grayscale(resizedImage) : resizedImage;

      // Apply blur to reduce noise sensitivity
      // Use stronger blur for perceptual hashing to be more robust to small changes
      // Increased from 2 to 3 for perceptual hashing to handle angle variations better
      final blurRadius = args.applyStrongerBlur ? 3 : 1;
      final finalImage = img.gaussianBlur(processedImage, radius: blurRadius);

      // Encode back to PNG format for consistent results
      return Uint8List.fromList(img.encodePng(finalImage));
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      // Return original bytes if preprocessing fails
      return args.imageBytes;
    }
  }

  /// Crops an image to a specified region
  ///
  /// This method is useful for extracting a specific area of an image,
  /// such as a waste item from a larger scene.
  ///
  /// [imageBytes]: The raw image data
  /// [rect]: The normalized rectangle (values 0-1) defining the crop region
  ///
  /// Returns cropped image bytes or null if cropping fails
  static Future<Uint8List?> cropImage(
    Uint8List imageBytes,
    Rect rect,
  ) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return null;
      }

      // Convert normalized rect (0-1) to pixel coordinates
      final x = (rect.left * image.width).round();
      final y = (rect.top * image.height).round();
      final width = (rect.width * image.width).round();
      final height = (rect.height * image.height).round();

      // Ensure coordinates are valid
      if (x < 0 ||
          y < 0 ||
          width <= 0 ||
          height <= 0 ||
          x + width > image.width ||
          y + height > image.height) {
        return null;
      }

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // Encode back to PNG format
      return Uint8List.fromList(img.encodePng(croppedImage));
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }
}

/// Arguments for preprocessing image in isolate
class _PreprocessImageArgs {

  _PreprocessImageArgs({
    required this.imageBytes,
    required this.targetWidth,
    required this.targetHeight,
    required this.convertToGrayscale,
    this.applyStrongerBlur = false,
  });
  final Uint8List imageBytes;
  final int targetWidth;
  final int targetHeight;
  final bool convertToGrayscale;
  final bool applyStrongerBlur;
}

/// Rectangle class for defining crop regions
class Rect {

  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  // Factory constructor from Flutter's Rect
  factory Rect.fromFlutterRect(dynamic flutterRect) {
    return Rect(
      left: flutterRect.left,
      top: flutterRect.top,
      width: flutterRect.width,
      height: flutterRect.height,
    );
  }

  // Factory constructor from left, top, width, height values
  factory Rect.fromLTWH(double left, double top, double width, double height) {
    return Rect(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
  final double left;
  final double top;
  final double width;
  final double height;

  // Method to convert to Flutter's Rect
  ui.Rect toFlutterRect() {
    return ui.Rect.fromLTWH(left, top, width, height);
  }
}
