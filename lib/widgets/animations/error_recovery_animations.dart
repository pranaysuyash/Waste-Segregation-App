import 'package:flutter/material.dart';
import 'dart:math' as math;

class ErrorRecoveryWidget extends StatefulWidget {
  const ErrorRecoveryWidget({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  State<ErrorRecoveryWidget> createState() => _ErrorRecoveryWidgetState();
}

class _ErrorRecoveryWidgetState extends State<ErrorRecoveryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _play() {
    if (_controller.isAnimating || _controller.isDisposed) {
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = 4 *
                math.sin(_controller.value * 4 * math.pi) *
                (1 - _controller.value);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            _play();
            onRetry();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
