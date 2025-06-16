import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Unified thumbnail widget that handles both local files and network URLs
/// with proper error handling, caching, and orientation support
class ThumbnailWidget extends StatelessWidget {
  const ThumbnailWidget({
    super.key,
    required this.imagePath,
    this.size = 64,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String? imagePath;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImageWidget(context),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    final path = imagePath!;
    
    // Handle web thumbnail data URLs
    if (path.startsWith('web_thumbnail:')) {
      final dataUrl = path.substring('web_thumbnail:'.length);
      return Image.network(
        dataUrl,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
      );
    }
    
    // Handle web image data URLs
    if (path.startsWith('web_image:')) {
      final dataUrl = path.substring('web_image:'.length);
      return Image.network(
        dataUrl,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
      );
    }

    // Handle HTTP/HTTPS URLs
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
      );
    }

    // Handle local files (mobile platforms)
    if (!kIsWeb) {
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
      );
    }

    // Fallback for unsupported formats
    return _buildErrorWidget(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.image,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: size * 0.4,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Theme.of(context).colorScheme.onErrorContainer,
        size: size * 0.4,
      ),
    );
  }
}

/// Helper function to build thumbnails with consistent styling
Widget buildThumbnail(String? path, {double size = 64, double borderRadius = 12}) {
  return ThumbnailWidget(
    imagePath: path,
    size: size,
    borderRadius: borderRadius,
  );
} 