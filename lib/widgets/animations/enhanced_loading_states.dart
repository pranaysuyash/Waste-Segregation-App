import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';

/// Widget shown when user triggers a refresh operation.
class RefreshLoadingWidget extends StatefulWidget {
  const RefreshLoadingWidget({super.key});

  @override
  State<RefreshLoadingWidget> createState() => _RefreshLoadingWidgetState();
}

class _RefreshLoadingWidgetState extends State<RefreshLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelpers.createController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    AnimationHelpers.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimationHelpers.createParticleBurst(
            color: Theme.of(context).colorScheme.primary,
            size: 60,
            controller: _controller,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading…',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}

/// Loading placeholder for history data.
class HistoryLoadingWidget extends StatelessWidget {
  const HistoryLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const ShimmerBox(height: 80, width: double.infinity),
        );
      },
    );
  }
}

/// Simple shimmer box used for skeleton loading.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, required this.height, required this.width});
  final double height;
  final double width;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelpers.createController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    AnimationHelpers.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              begin: Alignment(-1.0 + _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
            ),
          ),
        );
      },
    );
  }
}

/// Animation when search results appear.
class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
