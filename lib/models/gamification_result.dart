import 'gamification.dart';

/// Data structure to pass gamification results back through navigation
class GamificationResult {
  const GamificationResult({
    required this.pointsEarned,
    this.newlyEarnedAchievements = const [],
    this.completedChallenge,
    this.action = 'classification',
  });

  final int pointsEarned;
  final List<Achievement> newlyEarnedAchievements;
  final Challenge? completedChallenge;
  final String action;

  bool get hasRewards => pointsEarned > 0 || newlyEarnedAchievements.isNotEmpty || completedChallenge != null;
}
