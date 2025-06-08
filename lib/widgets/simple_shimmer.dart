import 'package:flutter/material.dart';

/// A simple shimmer effect widget for loading states.
/// Provides a smooth animated placeholder without requiring external dependencies.
class SimpleShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SimpleShimmer({
    super.key, 
    this.width = double.infinity, 
    this.height = 16,
    this.borderRadius,
  });
  
  @override
  State<SimpleShimmer> createState() => _SimpleShimmerState();
}

class _SimpleShimmerState extends State<SimpleShimmer> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade100;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
        ),
        child: ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment(-1 - _animation.value, 0),
              end: Alignment(1 + _animation.value, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            color: baseColor,
            width: widget.width,
            height: widget.height,
          ),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for card-like content
class ShimmerCard extends StatelessWidget {
  final double height;
  
  const ShimmerCard({super.key, this.height = 200});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SimpleShimmer(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SimpleShimmer(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SimpleShimmer(
                        width: 150,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SimpleShimmer(
              width: double.infinity,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SimpleShimmer(
              width: double.infinity,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SimpleShimmer(
              width: 200,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SimpleShimmer(
                    height: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SimpleShimmer(
                    height: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 