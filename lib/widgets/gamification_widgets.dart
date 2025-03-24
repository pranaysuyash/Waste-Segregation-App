import 'package:flutter/material.dart';
import '../models/gamification.dart';
import '../utils/constants.dart';

/// A widget that displays the user's current streak
class StreakIndicator extends StatelessWidget {
  final Streak streak;
  final VoidCallback? onTap;
  
  const StreakIndicator({
    Key? key,
    required this.streak,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        decoration: BoxDecoration(
          color: _getStreakColor(streak.current).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          border: Border.all(
            color: _getStreakColor(streak.current).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: _getStreakColor(streak.current),
              size: 28,
            ),
            const SizedBox(width: AppTheme.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.dailyStreak,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${streak.current} ${streak.current == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      color: _getStreakColor(streak.current),
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: _getStreakColor(streak.current).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Best: ${streak.longest}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStreakColor(int streakCount) {
    if (streakCount <= 0) {
      return Colors.grey;
    } else if (streakCount < 3) {
      return Colors.amber;
    } else if (streakCount < 7) {
      return Colors.orange;
    } else if (streakCount < 14) {
      return Colors.deepOrange;
    } else if (streakCount < 30) {
      return Colors.red;
    } else {
      return Colors.purple;
    }
  }
}

/// A widget that displays a challenge card
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;
  
  const ChallengeCard({
    Key? key,
    required this.challenge,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final endDate = challenge.endDate;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
              color: challenge.color.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    IconData(
                      _getIconCodePoint(challenge.iconName),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: challenge.color,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Daily Challenge',
                      style: TextStyle(
                        color: challenge.color,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ),
                  if (!challenge.isCompleted) ...[
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: daysLeft < 2 ? Colors.orange : challenge.color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      daysLeft > 0 
                          ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left' 
                          : 'Today',
                      style: TextStyle(
                        fontSize: 10,
                        color: daysLeft < 2 ? Colors.orange : challenge.color,
                      ),
                    ),
                  ] else
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: challenge.color,
                      ),
                    ),
                ],
              ),
            ),
            
            // Challenge content
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    challenge.description,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Progress and reward
                  Row(
                    children: [
                      // Progress bar
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          child: LinearProgressIndicator(
                            value: challenge.progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(challenge.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage
                      Text(
                        '${(challenge.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                          color: challenge.isCompleted 
                              ? challenge.color 
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${challenge.pointsReward}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  int _getIconCodePoint(String iconName) {
    // Map of icon names to code points
    const Map<String, int> iconMap = {
      'emoji_objects': 0xe23e,
      'recycling': 0xe7c0,
      'workspace_premium': 0xef56,
      'category': 0xe574,
      'local_fire_department': 0xe78d,
      'event_available': 0xe614,
      'emoji_events': 0xea65,
      'school': 0xe80c,
      'quiz': 0xf04c,
      'eco': 0xe63f,
      'task_alt': 0xe8fe,
      'shopping_bag': 0xf1cc,
      'restaurant': 0xe56c,
      'compost': 0xe761,
      'warning': 0xe002,
      'medical_services': 0xe95a,
      'autorenew': 0xe5d5,
      'description': 0xe873,
      'water_drop': 0xef71,
      'hardware': 0xe890,
      'devices': 0xe1b4,
      'auto_awesome': 0xe65f,
      'military_tech': 0xe3d0,
      'stars': 0xe8d0,
      'search': 0xe8b6,
      'verified': 0xef76,
      'timer_outlined': 0xef71,
    };
    
    return iconMap[iconName] ?? 0xe5d5; // Default to refresh icon
  }
}

/// A widget that displays the user's level and points
class PointsIndicator extends StatelessWidget {
  final UserPoints points;
  final VoidCallback? onTap;
  
  const PointsIndicator({
    Key? key,
    required this.points,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingSmall),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${points.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${points.total}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: LinearProgressIndicator(
                      value: (points.total % 100) / 100,
                      minHeight: 4,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays achievement badges
class AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final VoidCallback? onViewAll;
  
  const AchievementGrid({
    Key? key,
    required this.achievements,
    this.onViewAll,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get only earned achievements and take latest 4
    final earnedAchievements = achievements
        .where((a) => a.isEarned)
        .toList()
      ..sort((a, b) => b.earnedOn!.compareTo(a.earnedOn!));
    
    final displayAchievements = earnedAchievements.take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.achievements,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (earnedAchievements.length > 4)
              TextButton(
                onPressed: onViewAll,
                child: const Text(AppStrings.viewAll),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        
        if (displayAchievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete challenges to earn badges',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: AppTheme.paddingSmall,
              mainAxisSpacing: AppTheme.paddingSmall,
            ),
            itemCount: displayAchievements.length,
            itemBuilder: (context, index) {
              final achievement = displayAchievements[index];
              return _buildAchievementBadge(achievement);
            },
          ),
      ],
    );
  }
  
  Widget _buildAchievementBadge(Achievement achievement) {
    return Tooltip(
      message: achievement.title,
      child: Container(
        decoration: BoxDecoration(
          color: achievement.color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: achievement.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          IconData(
            _getIconCodePoint(achievement.iconName),
            fontFamily: 'MaterialIcons',
          ),
          color: achievement.color,
          size: 32,
        ),
      ),
    );
  }
  
  int _getIconCodePoint(String iconName) {
    // Map of icon names to code points
    const Map<String, int> iconMap = {
      'emoji_objects': 0xe23e,
      'recycling': 0xe7c0,
      'workspace_premium': 0xef56,
      'category': 0xe574,
      'local_fire_department': 0xe78d,
      'event_available': 0xe614,
      'emoji_events': 0xea65,
      'school': 0xe80c,
      'quiz': 0xf04c,
      'eco': 0xe63f,
      'task_alt': 0xe8fe,
    };
    
    return iconMap[iconName] ?? 0xe5d5; // Default to refresh icon
  }
}

/// A widget that displays a notification when a user earns an achievement
class AchievementNotification extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;
  
  const AchievementNotification({
    Key? key,
    required this.achievement,
    this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Achievement icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: achievement.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(
                      _getIconCodePoint(achievement.iconName),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: achievement.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                // Achievement details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.newAchievement,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            // Achievement description
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            // Points earned
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 2),
                const Text(
                  '+20 Points',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  int _getIconCodePoint(String iconName) {
    // Map of icon names to code points
    const Map<String, int> iconMap = {
      'emoji_objects': 0xe23e,
      'recycling': 0xe7c0,
      'workspace_premium': 0xef56,
      'category': 0xe574,
      'local_fire_department': 0xe78d,
      'event_available': 0xe614,
      'emoji_events': 0xea65,
      'school': 0xe80c,
      'quiz': 0xf04c,
      'eco': 0xe63f,
      'task_alt': 0xe8fe,
    };
    
    return iconMap[iconName] ?? 0xe5d5; // Default to refresh icon
  }
}