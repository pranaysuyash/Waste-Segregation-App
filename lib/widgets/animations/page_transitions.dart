import 'package:flutter/material.dart';

/// Provides custom page transitions.
class PageTransitionBuilder {
  static Route<T> slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// Controller for animated tabs.
class AnimatedTabController extends StatefulWidget {
  const AnimatedTabController({
    super.key,
    required this.length,
    required this.builder,
  });

  final int length;
  final Widget Function(BuildContext, TabController) builder;

  @override
  State<AnimatedTabController> createState() => _AnimatedTabControllerState();
}

class _AnimatedTabControllerState extends State<AnimatedTabController> with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: widget.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}
