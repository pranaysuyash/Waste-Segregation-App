import 'package:flutter/material.dart';

/// Animated illustration shown when history is empty.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No History Yet'),
        ],
      ),
    );
  }
}

/// Shown when achievements list has no entries.
class EmptyAchievementsWidget extends StatelessWidget {
  const EmptyAchievementsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.amber),
          SizedBox(height: 16),
          Text('Your journey starts here'),
        ],
      ),
    );
  }
}
