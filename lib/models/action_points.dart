/// Golden source enum for all pointable actions in the app
/// This ensures consistency between UI and backend point calculations
enum PointableAction {
  classification('classification', 10),
  dailyStreak('daily_streak', 5),
  challengeComplete('challenge_complete', 25),
  badgeEarned('badge_earned', 20),
  achievementClaim('achievement_claim', 0), // Custom points used
  quizCompleted('quiz_completed', 15),
  educationalContent('educational_content', 5),
  perfectWeek('perfect_week', 50),
  communityChallenge('community_challenge', 30),
  streakBonus('streak_bonus', 0), // Variable points based on streak length
  migrationSync('migration_sync', 0), // Custom points for data migration
  retroactiveSync('retroactive_sync', 0), // Custom points for retroactive fixes
  instantAnalysis('instant_analysis', 10), // Same as classification
  manualClassification('manual_classification', 10); // Same as classification

  const PointableAction(this.key, this.defaultPoints);

  /// String key used in storage and analytics
  final String key;

  /// Default points awarded for this action
  final int defaultPoints;

  /// Get action by key (for backwards compatibility)
  static PointableAction? fromKey(String key) {
    for (final action in PointableAction.values) {
      if (action.key == key) {
        return action;
      }
    }
    return null;
  }

  /// Get all action keys (for validation)
  static List<String> get allKeys => PointableAction.values.map((a) => a.key).toList();

  /// Validate if a key is a valid pointable action
  static bool isValidAction(String key) {
    return fromKey(key) != null;
  }

  @override
  String toString() => key;
}

/// Extension to make it easier to work with PointableAction
extension PointableActionExtension on PointableAction {
  /// Check if this action supports custom points
  bool get supportsCustomPoints {
    return this == PointableAction.achievementClaim ||
        this == PointableAction.streakBonus ||
        this == PointableAction.migrationSync ||
        this == PointableAction.retroactiveSync;
  }

  /// Get category for this action (for analytics)
  String get category {
    switch (this) {
      case PointableAction.classification:
      case PointableAction.instantAnalysis:
      case PointableAction.manualClassification:
        return 'classification';
      case PointableAction.dailyStreak:
      case PointableAction.streakBonus:
        return 'streak';
      case PointableAction.challengeComplete:
      case PointableAction.perfectWeek:
      case PointableAction.communityChallenge:
        return 'challenge';
      case PointableAction.badgeEarned:
      case PointableAction.achievementClaim:
        return 'achievement';
      case PointableAction.quizCompleted:
      case PointableAction.educationalContent:
        return 'education';
      case PointableAction.migrationSync:
      case PointableAction.retroactiveSync:
        return 'system';
    }
  }
}
