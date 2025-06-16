import 'dart:async';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class for image manipulation and hashing
class ImageUtils {
  /// Default dimensions for image normalization
  static const int defaultTargetWidth = 300;
  static const int defaultTargetHeight = 300;

  /// Normalizes image bytes by stripping EXIF data and baking orientation
  /// This ensures consistent hashing regardless of camera orientation
  static Future<Uint8List> _normalizedBytes(Uint8List bytes) async {
    try {
      final raw = img.decodeImage(bytes);
      if (raw == null) return bytes;
      
      // Bake orientation to strip EXIF rotation data
      final fixed = img.bakeOrientation(raw);
      
      // Re-encode with consistent quality
      return Uint8List.fromList(img.encodeJpg(fixed, quality: 95));
    } catch (e) {
      debugPrint('Error normalizing image bytes: $e');
      return bytes; // Return original if normalization fails
    }
  }

  /// Generates both perceptual and content hashes efficiently in isolate
  ///
  /// This method computes both hashes in a single isolate call to minimize
  /// overhead and prevent UI lag on low-end devices.
  ///
  /// [imageBytes]: The raw image data as Uint8List
  ///
  /// Returns a Map with 'perceptualHash' and 'contentHash' keys
  static Future<Map<String, String>> generateDualHashes(Uint8List imageBytes) async {
    try {
      // Normalize bytes first for consistent hashing
      final normalizedBytes = await _normalizedBytes(imageBytes);
      
      // Use compute for better performance and to avoid blocking UI thread
      final result = await compute(_generateDualHashesIsolate, normalizedBytes);
      return result;
    } catch (e) {
      debugPrint('Error generating dual hashes: $e');
      // Fallback to individual hash generation with original bytes
      return {
        'perceptualHash': await generateImageHash(imageBytes),
        'contentHash': await generateContentHash(imageBytes),
      };
    }
  }

  /// Generates both hashes in an isolate for optimal performance
  static Map<String, String> _generateDualHashesIsolate(Uint8List imageBytes) {
    try {
      // Generate content hash first (fastest)
      final contentHash = md5.convert(imageBytes).toString();
      
      // Generate perceptual hash
      String perceptualHash;
      try {
        // Preprocess the image for perceptual hashing
        final image = img.decodeImage(imageBytes);
        if (image == null) {
          throw Exception('Failed to decode image for perceptual hashing');
        }

        // Resize to exactly 8x8 for DCT (Discrete Cosine Transform approximation)
        final smallImage = img.copyResize(img.grayscale(image), width: 8, height: 8);

        // Calculate the average pixel value
        var totalValue = 0;
        final pixelValues = <int>[];

        for (var y = 0; y < smallImage.height; y++) {
          for (var x = 0; x < smallImage.width; x++) {
            final pixel = smallImage.getPixel(x, y);
            final value = img.getLuminance(pixel);
            totalValue += value.toInt();
            pixelValues.add(value.toInt());
          }
        }

        // Calculate the average
        final avgValue = totalValue ~/ (smallImage.width * smallImage.height);

        // Generate the hash by comparing each pixel to the average
        var hashBits = '';
        for (final value in pixelValues) {
          hashBits += (value >= avgValue) ? '1' : '0';
        }

        // Convert binary string to hexadecimal
        var hexHash = '';
        for (var i = 0; i < 64; i += 4) {
          if (i + 4 <= hashBits.length) {
            final chunk = hashBits.substring(i, i + 4);
            final hexDigit = int.parse(chunk, radix: 2).toRadixString(16);
            hexHash += hexDigit;
          }
        }

        perceptualHash = 'phash_$hexHash';
      } catch (e) {
        debugPrint('Error in perceptual hash calculation: $e');
        perceptualHash = 'error_hash_${DateTime.now().millisecondsSinceEpoch}';
      }

      return {
        'perceptualHash': perceptualHash,
        'contentHash': 'md5_$contentHash',
      };
    } catch (e) {
      debugPrint('Error in dual hash generation: $e');
      // Return error hashes that won't match anything
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return {
        'perceptualHash': 'error_phash_$timestamp',
        'contentHash': 'error_md5_$timestamp',
      };
    }
  }

  /// Generates a perceptual hash of the normalized image data
  ///
  /// This method creates a consistent identifier for visually similar images,
  /// making it robust to small variations in camera position, lighting, etc.
  /// Uses normalized bytes to ensure consistent hashing across orientations.
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
      // Normalize bytes first for consistent hashing
      final normalizedBytes = await _normalizedBytes(imageBytes);
      
      // Preprocess the image (smaller size and grayscale for consistent hashing)
      final processedBytes = await preprocessImage(
        normalizedBytes,
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

  /// Generates a content hash (MD5) of the normalized image data
  ///
  /// This method creates an exact fingerprint of the normalized image bytes,
  /// used for precise duplicate detection in dual-hash verification.
  /// Uses normalized bytes to ensure consistent hashing across orientations.
  ///
  /// [imageBytes]: The raw image data as Uint8List
  ///
  /// Returns a String representation of the MD5 hash
  static Future<String> generateContentHash(Uint8List imageBytes) async {
    try {
      // Normalize bytes first for consistent hashing
      final normalizedBytes = await _normalizedBytes(imageBytes);
      final digest = md5.convert(normalizedBytes);
      return 'md5_${digest.toString()}';
    } catch (e) {
      debugPrint('Error generating content hash: $e');
      // Return a unique fallback that won't match anything
      return 'content_error_${DateTime.now().millisecondsSinceEpoch}';
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
      for (final value in pixelValues) {
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

  /// Converts a data URL string to a Uint8List of image bytes.
  /// Handles common data URL formats like "data:image/jpeg;base64,..."
  static Uint8List? dataUrlToBytes(String dataUrl) {
    try {
      if (dataUrl.startsWith('data:image/')) {
        final uri = Uri.parse(dataUrl);
        if (uri.scheme == 'data' && uri.data != null) {
          return uri.data!.contentAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error converting data URL to bytes: $e');
    }
    return null;
  }

  /// Creates the appropriate Image widget based on the image URL/path
  /// 
  /// Automatically detects whether the source is:
  /// - A local file path (file:// URI or absolute path)
  /// - A network URL (http:// or https://)
  /// - An asset path (assets/)
  /// 
  /// Returns the appropriate Image widget with error handling
  static Widget buildImage({
    required String imageSource,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    // Default error widget
    errorWidget ??= Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );

    // Default loading widget
    loadingWidget ??= Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Check if it's a network URL
      if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
        return Image.network(
          imageSource,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingWidget!;
          },
          errorBuilder: (context, error, stackTrace) => errorWidget!,
        );
      }
      
      // Check if it's an asset
      if (imageSource.startsWith('assets/')) {
        return Image.asset(
          imageSource,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => errorWidget!,
        );
      }
      
      // Handle file:// URI or local file path
      var filePath = imageSource;
      if (imageSource.startsWith('file://')) {
        filePath = imageSource.substring(7); // Remove 'file://' prefix
      }
      
      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => errorWidget!,
        );
      } else {
        // File doesn't exist
        return errorWidget;
      }
    } catch (e) {
      // Any other error, return error widget
      return errorWidget;
    }
  }

  /// Creates a circular avatar image with proper source handling
  static Widget buildCircularAvatar({
    required String imageSource,
    required double radius,
    Widget? child,
    Color? backgroundColor,
  }) {
    try {
      ImageProvider? backgroundImage;
      
      // Check if it's a network URL
      if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
        backgroundImage = NetworkImage(imageSource);
      } else if (imageSource.startsWith('assets/')) {
        backgroundImage = AssetImage(imageSource);
      } else {
        // Handle file:// URI or local file path
        var filePath = imageSource;
        if (imageSource.startsWith('file://')) {
          filePath = imageSource.substring(7);
        }
        
        final file = File(filePath);
        if (file.existsSync()) {
          backgroundImage = FileImage(file);
        }
      }
      
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: backgroundImage,
        onBackgroundImageError: backgroundImage != null 
          ? (exception, stackTrace) {
              // Handle image loading error silently
              debugPrint('Avatar image failed to load: $exception');
            }
          : null,
        child: backgroundImage == null ? child : null,
      );
    } catch (e) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: child,
      );
    }
  }

  /// Checks if an image source is valid and accessible
  static Future<bool> isImageSourceValid(String imageSource) async {
    try {
      if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
        // For network images, we'd need to make a HEAD request to check
        // For now, assume network URLs are valid if properly formatted
        return Uri.tryParse(imageSource) != null;
      } else if (imageSource.startsWith('assets/')) {
        // Asset validation would require checking the asset bundle
        // For now, assume assets are valid if properly formatted
        return true;
      } else {
        // Check if local file exists
        var filePath = imageSource;
        if (imageSource.startsWith('file://')) {
          filePath = imageSource.substring(7);
        }
        
        final file = File(filePath);
        return file.existsSync();
      }
    } catch (e) {
      return false;
    }
  }

  /// Extracts the file extension from an image source
  static String? getImageExtension(String imageSource) {
    try {
      final uri = Uri.parse(imageSource);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    } catch (e) {
      // If parsing fails, try simple string manipulation
      final lastDot = imageSource.lastIndexOf('.');
      if (lastDot != -1 && lastDot < imageSource.length - 1) {
        return imageSource.substring(lastDot + 1).toLowerCase();
      }
    }
    return null;
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
