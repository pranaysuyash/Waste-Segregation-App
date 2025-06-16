import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Enhanced divider with modern styling and better visual hierarchy
class PolishedDivider extends StatelessWidget {

  const PolishedDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.indent = 16.0,
    this.endIndent = 16.0,
    this.color,
    this.style = DividerStyle.solid,
  });

  /// Creates a subtle divider with minimal visual impact
  const PolishedDivider.subtle({
    super.key,
    this.height = 1.0,
    this.thickness = 0.5,
    this.indent = 16.0,
    this.endIndent = 16.0,
    this.color,
    this.style = DividerStyle.solid,
  });

  /// Creates a section divider with more visual weight
  const PolishedDivider.section({
    super.key,
    this.height = AppThemePolish.spacingGenerous,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
    this.style = DividerStyle.solid,
  });

  /// Creates a dotted divider for texture
  const PolishedDivider.dotted({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.indent = 16.0,
    this.endIndent = 16.0,
    this.color,
    this.style = DividerStyle.dotted,
  });
  final double height;
  final double thickness;
  final double indent;
  final double endIndent;
  final Color? color;
  final DividerStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? 
        theme.colorScheme.outline.withValues(alpha: 0.3);

    switch (style) {
      case DividerStyle.solid:
        return Container(
          height: height,
          margin: EdgeInsets.only(left: indent, right: endIndent),
          child: Divider(
            height: height,
            thickness: thickness,
            color: dividerColor,
          ),
        );

      case DividerStyle.dotted:
        return Container(
          height: height,
          margin: EdgeInsets.only(left: indent, right: endIndent),
          child: CustomPaint(
            painter: DottedLinePainter(
              color: dividerColor,
              thickness: thickness,
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
            ),
          ),
        );

      case DividerStyle.dashed:
        return Container(
          height: height,
          margin: EdgeInsets.only(left: indent, right: endIndent),
          child: CustomPaint(
            painter: DashedLinePainter(
              color: dividerColor,
              thickness: thickness,
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
            ),
          ),
        );
    }
  }
}

enum DividerStyle {
  solid,
  dotted,
  dashed,
}

/// Custom painter for dotted lines
class DottedLinePainter extends CustomPainter {

  DottedLinePainter({
    required this.color,
    required this.thickness,
    this.dotRadius = 1.0,
    this.spacing = 4.0,
  });
  final Color color;
  final double thickness;
  final double dotRadius;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.fill;

    final y = size.height / 2;
    var x = dotRadius;

    while (x < size.width - dotRadius) {
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
      x += dotRadius * 2 + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {

  DashedLinePainter({
    required this.color,
    required this.thickness,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
  });
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    double x = 0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dashWidth, y),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 