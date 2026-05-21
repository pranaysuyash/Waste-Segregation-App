import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// A thumbnail card for displaying a waste classification image with
/// category-coloured border and overlay.
///
/// Example:
/// ```dart
/// WasteImagePreviewCard(
///   imagePath: 'path/to/image.jpg',
///   category: 'Wet Waste',
/// )
/// ```
class WasteImagePreviewCard extends StatelessWidget {
  const WasteImagePreviewCard({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.category,
    this.size = 64.0,
    this.showCategoryOverlay = true,
    this.onTap,
    this.fallbackBuilder,
    this.errorBuilder,
  });

  final String? imagePath;
  final String? imageUrl;
  final String? category;
  final double size;
  final bool showCategoryOverlay;
  final VoidCallback? onTap;
  final Widget Function(Color categoryColor)? fallbackBuilder;
  final Widget Function()? errorBuilder;

  Color get _categoryColor {
    if (category == null) return AppTheme.neutralColor;
    return WasteTheme.categoryColor(category!);
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor;
    final hasImage = imagePath != null || imageUrl != null;

    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: hasImage
          ? _buildImage(context, color)
          : _buildFallback(context, color),
    );

    final result = Semantics(
      label: category != null
          ? 'Image of ${WasteTheme.categoryDisplayLabel(category!)}'
          : 'Waste item image',
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  Widget _buildImage(BuildContext context, Color color) {
    final path = imagePath ?? imageUrl;

    if (path != null && (path.startsWith('http') || path.startsWith('https'))) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, trace) =>
            _buildFallback(context, color),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _buildLoading(context, color);
        },
      );
    }

    if (path != null && path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, trace) =>
            _buildFallback(context, color),
      );
    }

    return _buildFallback(context, color);
  }

  Widget _buildLoading(BuildContext context, Color color) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.3,
        height: size * 0.3,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, Color color) {
    if (fallbackBuilder != null) return fallbackBuilder!(color);
    if (category != null) {
      final icon = WasteTheme.categoryIcon(category!);
      return Center(child: Icon(icon, size: size * 0.45, color: color));
    }
    return Center(
      child: Icon(Icons.image, size: size * 0.45, color: AppTheme.neutralColor),
    );
  }
}
