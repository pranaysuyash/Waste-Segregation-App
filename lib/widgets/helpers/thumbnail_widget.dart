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
      return _buildNetworkImage(context, dataUrl);
    }
    
    // Handle web image data URLs
    if (path.startsWith('web_image:')) {
      final dataUrl = path.substring('web_image:'.length);
      return _buildNetworkImage(context, dataUrl);
    }

    // Handle HTTP/HTTPS URLs
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return _buildNetworkImage(context, path);
    }

    // Handle local files (mobile platforms)
    if (!kIsWeb) {
      return _buildLocalImage(context, path);
    }

    // Fallback for unsupported formats
    return _buildErrorWidget(context);
  }

  Widget _buildNetworkImage(BuildContext context, String url) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(context, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Network image error: $error');
        return _buildErrorWidget(context);
      },
    );
  }

  Widget _buildLocalImage(BuildContext context, String path) {
    return FutureBuilder<bool>(
      future: File(path).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context);
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            File(path),
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Local image error: $error');
              return _buildErrorWidget(context);
            },
          );
        }
        
        // File doesn't exist, show error
        return _buildErrorWidget(context);
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context, ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
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