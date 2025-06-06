import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';

class SyncSuccessWidget extends StatefulWidget {
  const SyncSuccessWidget({super.key});

  @override
  State<SyncSuccessWidget> createState() => _SyncSuccessWidgetState();
}

class _SyncSuccessWidgetState extends State<SyncSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelpers.createController(vsync: this, duration: const Duration(seconds: 1));
    _controller.forward();
  }

  @override
  void dispose() {
    AnimationHelpers.disposeController(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimationHelpers.createParticleBurst(
            color: Colors.green,
            size: 120,
            controller: _controller,
          ),
          AnimationHelpers.createSuccessCheck(
            color: Colors.green,
            controller: _controller,
          ),
        ],
      ),
    );
  }
}
