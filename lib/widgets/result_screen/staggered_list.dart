import 'package:flutter/material.dart';

/// A widget that displays a list of items with staggered entrance animations
class StaggeredList<T> extends StatelessWidget {
  
  const StaggeredList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialDelay = const Duration(milliseconds: 300),
    this.stepDelay = const Duration(milliseconds: 100),
    this.direction = Axis.vertical,
  });
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Duration initialDelay;
  final Duration stepDelay;
  final Axis direction;
  
  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) {
      return Column(
        children: _buildAnimatedItems(context),
      );
    } else {
      return Row(
        children: _buildAnimatedItems(context),
      );
    }
  }
  
  List<Widget> _buildAnimatedItems(BuildContext context) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return DelayedDisplay(
        delay: initialDelay + stepDelay * index,
        child: itemBuilder(context, item),
      );
    }).toList();
  }
}

/// A widget that displays its child with a delayed fade and slide animation
class DelayedDisplay extends StatefulWidget {
  
  const DelayedDisplay({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = const Offset(0, 20),
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  
  @override
  State<DelayedDisplay> createState() => _DelayedDisplayState();
}

class _DelayedDisplayState extends State<DelayedDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Wrapper for staggered tag animations
class StaggeredTagList extends StatelessWidget {
  
  const StaggeredTagList({
    super.key,
    required this.tags,
  });
  final List<Widget> tags;
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.asMap().entries.map((entry) {
        final index = entry.key;
        final tag = entry.value;
        return DelayedDisplay(
          delay: Duration(milliseconds: 200 + (index * 100)),
          slideOffset: const Offset(0, 10),
          child: tag,
        );
      }).toList(),
    );
  }
} 