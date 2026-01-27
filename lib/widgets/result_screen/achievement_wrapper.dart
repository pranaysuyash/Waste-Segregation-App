/// Achievement celebration wrapper for ResultScreen V2
/// 
/// Bridges the existing AchievementCelebration widget with V2's state management.
/// Ensures celebrations are shown once and only for qualifying achievements.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../services/result_pipeline.dart';
import '../advanced_ui/achievement_celebration.dart';
import '../../utils/waste_app_logger.dart';

/// Manages achievement celebration state and display
class AchievementCelebrationWrapper extends ConsumerStatefulWidget {
  const AchievementCelebrationWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AchievementCelebrationWrapper> createState() =>
      _AchievementCelebrationWrapperState();
}

class _AchievementCelebrationWrapperState
    extends ConsumerState<AchievementCelebrationWrapper> {
  bool _hasProcessedCelebrations = false;
  Achievement? _celebrationAchievement;

  @override
  Widget build(BuildContext context) {
    final pipelineState = ref.watch(resultPipelineProvider);

    // Process achievements when pipeline completes
    if (!_hasProcessedCelebrations &&
        !pipelineState.isProcessing &&
        pipelineState.newAchievements.isNotEmpty) {
      // Schedule processing after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processAchievements(pipelineState.newAchievements);
      });
    }

    return Stack(
      children: [
        widget.child,
        if (_celebrationAchievement != null)
          AchievementCelebration(
            achievement: _celebrationAchievement!,
            onDismiss: () {
              setState(() {
                _celebrationAchievement = null;
              });
            },
          ),
      ],
    );
  }

  void _processAchievements(List<Achievement> achievements) {
    if (_hasProcessedCelebrations) return;

    _hasProcessedCelebrations = true;

    // Select the most significant achievement to celebrate
    // Matches Legacy logic: prefer non-bronze or high-point achievements
    final achievementToShow = achievements.firstWhere(
      (a) => a.tier != AchievementTier.bronze || a.pointsReward >= 25,
      orElse: () => achievements.first,
    );

    setState(() {
      _celebrationAchievement = achievementToShow;
    });

    // Log analytics event
    WasteAppLogger.aiEvent('achievement_celebration_shown', context: {
      'achievementId': achievementToShow.id,
      'achievementTitle': achievementToShow.title,
      'tier': achievementToShow.tier.name,
      'pointsReward': achievementToShow.pointsReward,
      'version': 'v2',
    });
  }
}

/// Provider to track if celebration has been shown for current classification
final celebrationShownProvider = StateProvider<bool>((ref) => false);

/// Hook to show achievement celebration programmatically
/// 
/// Usage in V2 screen:
/// ```dart
/// ref.read(achievementCelebrationProvider).show(achievement);
/// ```
class AchievementCelebrationController {
  Achievement? _currentAchievement;
  VoidCallback? _onDismiss;

  void show(Achievement achievement, {VoidCallback? onDismiss}) {
    _currentAchievement = achievement;
    _onDismiss = onDismiss;
  }

  void dismiss() {
    _currentAchievement = null;
    _onDismiss?.call();
  }

  Achievement? get currentAchievement => _currentAchievement;
  bool get hasAchievement => _currentAchievement != null;
}

final achievementCelebrationProvider = Provider<AchievementCelebrationController>(
  (ref) => AchievementCelebrationController(),
);

/// Widget that displays achievement celebration with proper lifecycle
class AchievementCelebrationDisplay extends StatelessWidget {
  const AchievementCelebrationDisplay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  final Achievement achievement;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AchievementCelebration(
      achievement: achievement,
      onDismiss: onDismiss,
    );
  }
}

/// Mixin for screens that need achievement celebration
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with AchievementCelebrationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Stack(
///       children: [
///         // main content
///         if (showingCelebration)
///           buildAchievementCelebration(),
///       ],
///     );
///   }
/// }
/// ```
mixin AchievementCelebrationMixin<T extends StatefulWidget> on State<T> {
  Achievement? _celebrationAchievement;
  bool _hasShownCelebration = false;

  bool get showingCelebration => _celebrationAchievement != null;

  void showAchievementCelebration(List<Achievement> achievements) {
    if (_hasShownCelebration || achievements.isEmpty) return;

    _hasShownCelebration = true;

    final majorAchievement = achievements.firstWhere(
      (a) => a.tier != AchievementTier.bronze || a.pointsReward >= 25,
      orElse: () => achievements.first,
    );

    setState(() {
      _celebrationAchievement = majorAchievement;
    });

    // Log analytics
    WasteAppLogger.aiEvent('achievement_celebration_shown', context: {
      'achievementId': majorAchievement.id,
      'achievementTitle': majorAchievement.title,
      'tier': majorAchievement.tier.name,
      'version': 'v2',
    });
  }

  void dismissAchievementCelebration() {
    setState(() {
      _celebrationAchievement = null;
    });
  }

  Widget buildAchievementCelebration() {
    if (_celebrationAchievement == null) return const SizedBox.shrink();

    return AchievementCelebration(
      achievement: _celebrationAchievement!,
      onDismiss: dismissAchievementCelebration,
    );
  }
}
