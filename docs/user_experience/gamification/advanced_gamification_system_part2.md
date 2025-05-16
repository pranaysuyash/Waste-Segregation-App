### 3.2 Challenge System

**Daily Challenges**:
- Dynamic daily tasks based on user behavior and local waste issues
- Streak bonuses for consecutive days of completion
- Varied difficulty levels with appropriate rewards

**Weekly Challenges**:
- More complex tasks requiring sustained effort
- Themed around specific waste types or environmental issues
- Higher-value rewards for completion

**Special Event Challenges**:
- Limited-time challenges aligned with environmental events
- Collaborative community goals with shared rewards
- Seasonal themes with unique collectibles

**Challenge Implementation**:

```dart
class ChallengeSystem {
  final UserRepository _userRepository;
  final ChallengeRepository _challengeRepository;
  final AnalyticsService _analyticsService;
  
  ChallengeSystem({
    required UserRepository userRepository,
    required ChallengeRepository challengeRepository,
    required AnalyticsService analyticsService,
  }) : 
    _userRepository = userRepository,
    _challengeRepository = challengeRepository,
    _analyticsService = analyticsService;
  
  /// Get active challenges for a user
  Future<List<Challenge>> getActiveChallenges(String userId) async {
    final user = await _userRepository.getUser(userId);
    final userLevel = user.level;
    final preferences = user.preferences;
    final recentActivity = await _userRepository.getUserRecentActivity(userId);
    
    // Fetch available challenges
    final availableChallenges = await _challengeRepository.getAvailableChallenges(
      userLevel: userLevel,
      preferences: preferences,
    );
    
    // Filter and personalize challenges
    return _personalizeAndFilterChallenges(
      availableChallenges,
      recentActivity,
      user.completedChallenges,
    );
  }
  
  /// Update challenge progress based on user action
  Future<List<ChallengeProgress>> updateChallengeProgress(
    String userId,
    UserAction action,
  ) async {
    // Get active challenges
    final activeChallenges = await _challengeRepository.getUserActiveChallenges(userId);
    final updatedChallenges = <ChallengeProgress>[];
    
    // Update progress for each relevant challenge
    for (final challenge in activeChallenges) {
      if (challenge.appliesTo(action)) {
        final updatedProgress = await _challengeRepository.updateChallengeProgress(
          userId: userId,
          challengeId: challenge.id,
          action: action,
        );
        
        updatedChallenges.add(updatedProgress);
        
        // Check if challenge completed
        if (updatedProgress.isCompleted && !updatedProgress.rewardClaimed) {
          await _handleChallengeCompletion(userId, challenge);
        }
      }
    }
    
    // Track analytics
    _analyticsService.trackChallengeProgress(
      userId: userId,
      challengeUpdates: updatedChallenges,
      triggeredByAction: action,
    );
    
    return updatedChallenges;
  }
  
  /// Claim reward for completed challenge
  Future<RewardResult> claimChallengeReward(
    String userId,
    String challengeId,
  ) async {
    final challenge = await _challengeRepository.getChallenge(challengeId);
    final progress = await _challengeRepository.getChallengeProgress(userId, challengeId);
    
    if (!progress.isCompleted) {
      throw Exception('Cannot claim reward for incomplete challenge');
    }
    
    if (progress.rewardClaimed) {
      throw Exception('Reward already claimed');
    }
    
    // Grant reward to user
    final reward = await _userRepository.grantReward(
      userId: userId,
      rewardType: challenge.rewardType,
      rewardValue: challenge.rewardValue,
    );
    
    // Mark reward as claimed
    await _challengeRepository.markRewardClaimed(userId, challengeId);
    
    // Track analytics
    _analyticsService.trackRewardClaimed(
      userId: userId,
      challengeId: challengeId,
      rewardType: challenge.rewardType,
      rewardValue: challenge.rewardValue,
    );
    
    return reward;
  }
  
  /// Handle challenge completion
  Future<void> _handleChallengeCompletion(String userId, Challenge challenge) async {
    // Send notification
    NotificationService().sendChallengeCompletionNotification(
      userId: userId,
      challenge: challenge,
    );
    
    // Check for achievement unlocks
    AchievementSystem().checkChallengeRelatedAchievements(
      userId: userId,
      completedChallenge: challenge,
    );
    
    // Update user statistics
    await _userRepository.incrementUserStat(
      userId: userId,
      stat: 'challenges_completed',
      increment: 1,
    );
  }
  
  /// Filter and personalize challenges for user
  List<Challenge> _personalizeAndFilterChallenges(
    List<Challenge> availableChallenges,
    List<UserAction> recentActivity,
    List<String> completedChallenges,
  ) {
    // Implementation for personalizing challenges
    // ...
  }
}
```
