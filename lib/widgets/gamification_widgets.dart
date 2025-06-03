import 'package:flutter/material.dart';
import '../models/gamification.dart';
import '../utils/constants.dart'; // This imports AppIcons, AppTheme, and AppStrings

/// A widget that displays the user's current streak
class StreakIndicator extends StatelessWidget {

  const StreakIndicator({
    super.key,
    required this.streak,
    this.onTap,
  });
  final Streak streak;
  final VoidCallback? onTap;

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
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: _getStreakColor(streak.current).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
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

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });
  final Challenge challenge;
  final VoidCallback? onTap;

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
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
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
                      AppIcons.fromString(challenge.iconName),
                      color: challenge.color,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Ends in $daysLeft days',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // We now use AppIcons.fromString(iconName) instead of this method
}

/// A widget that displays the user's level and points
class PointsIndicator extends StatelessWidget {

  const PointsIndicator({
    super.key,
    required this.points,
    this.onTap,
  });
  final UserPoints points;
  final VoidCallback? onTap;

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
              decoration: const BoxDecoration(
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
                    const Icon(
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: LinearProgressIndicator(
                      value: (points.total % 100) / 100,
                      minHeight: 4,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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

  const AchievementGrid({
    super.key,
    required this.achievements,
    this.onViewAll,
  });
  final List<Achievement> achievements;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    // Get only earned achievements and take latest 4
    final earnedAchievements = achievements.where((a) => a.isEarned).toList()
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
          AppIcons.fromString(achievement.iconName),
          color: achievement.color,
          size: 32,
        ),
      ),
    );
  }

  // We now use AppIcons.fromString(iconName) instead of this method
}

/// A widget that displays a notification when a user earns an achievement
class AchievementNotification extends StatelessWidget {

  const AchievementNotification({
    super.key,
    required this.achievement,
    this.onDismiss,
  });
  final Achievement achievement;
  final VoidCallback? onDismiss;

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
                    AppIcons.fromString(achievement.iconName),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars,
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 2),
                Text(
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

  // We now use AppIcons.fromString(iconName) instead of this method
}
