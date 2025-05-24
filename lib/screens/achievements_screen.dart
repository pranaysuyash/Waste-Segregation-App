import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../widgets/profile_summary_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AchievementsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AchievementsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<GamificationProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _loadProfile();
  }

  void _loadProfile() {
    final gamificationService =
        Provider.of<GamificationService>(context, listen: false);
    _profileFuture = gamificationService.getProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.achievements),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: AppStrings.badges),
              Tab(text: AppStrings.challenges),
              Tab(text: AppStrings.stats),
            ],
          ),
        ),
        body: FutureBuilder<GamificationProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading profile: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('No profile data available'),
              );
            }

            final profile = snapshot.data!;

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAchievementsTab(profile),
                _buildChallengesTab(profile),
                _buildStatsTab(profile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(GamificationProfile profile) {
    // Group achievements by type
    final Map<AchievementType, List<Achievement>> achievementsByType = {};

    for (final achievement in profile.achievements) {
      if (!achievement.isSecret || achievement.isEarned) {
        if (!achievementsByType.containsKey(achievement.type)) {
          achievementsByType[achievement.type] = [];
        }
        achievementsByType[achievement.type]!.add(achievement);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User level and points summary
          ProfileSummaryCard(points: profile.points),
          const SizedBox(height: AppTheme.paddingRegular),

          // Current streak
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(width: AppTheme.paddingRegular),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.dailyStreak,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${profile.streak.current} ${profile.streak.current == 1 ? 'day' : 'days'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Longest',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${profile.streak.longest} ${profile.streak.longest == 1 ? 'day' : 'days'}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Achievement types
          ...achievementsByType.entries.map((entry) {
            final type = entry.key;
            final achievements = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAchievementTypeTitle(type),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.paddingSmall,
                    mainAxisSpacing: AppTheme.paddingSmall,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _buildAchievementCard(achievement);
                  },
                ),
                const SizedBox(height: AppTheme.paddingLarge),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool isEarned = achievement.isEarned;
    final bool isLocked = achievement.isLocked;
    final bool isClaimable = achievement.isClaimable;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isEarned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        side: isClaimable 
            ? BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        child: Stack(
          children: [
            // Tier badge in corner
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: achievement.getTierColor(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.borderRadiusSmall),
                  ),
                ),
                child: Text(
                  achievement.tierName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getContrastColor(achievement.getTierColor()),
                  ),
                ),
              ),
            ),
            
            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Achievement icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? achievement.color.withOpacity(0.2)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isEarned && achievement.tier != AchievementTier.bronze
                        ? Border.all(color: achievement.getTierColor(), width: 2)
                        : null,
                  ),
                  child: getAchievementIcon(achievement.iconName, color: isEarned ? achievement.color : Colors.grey, size: 36),
                ),
                const SizedBox(height: 8),
                // Achievement title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: isEarned ? AppTheme.textPrimaryColor : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // Progress indicator or status
                if (!isEarned && !isLocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.color.withOpacity(0.7)),
                      ),
                    ),
                  )
                else if (isEarned && isClaimable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Claim Reward!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  )
                else if (isEarned)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 10,
                        color: achievement.color,
                      ),
                    ),
                  )
                else if (isLocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Unlocks at level ${achievement.unlocksAtLevel}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
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
  
  // Helper method to determine contrasting text color for tier badges
  Color _getContrastColor(Color backgroundColor) {
    // Calculate perceived brightness using the formula: (R * 0.299 + G * 0.587 + B * 0.114)
    final double brightness = (backgroundColor.red * 0.299 + 
                           backgroundColor.green * 0.587 + 
                           backgroundColor.blue * 0.114) / 255;
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  void _showAchievementDetails(Achievement achievement) {
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    
    // Helper function to handle claiming rewards
    Future<void> claimReward() async {
      try {
        final profile = await gamificationService.getProfile();
        final updatedAchievements = List<Achievement>.from(profile.achievements);
        
        // Find the achievement by ID and update its claim status
        for (int i = 0; i < updatedAchievements.length; i++) {
          if (updatedAchievements[i].id == achievement.id) {
            updatedAchievements[i] = updatedAchievements[i].copyWith(
              claimStatus: ClaimStatus.claimed,
            );
            break;
          }
        }
        
        // Update profile with claimed achievement
        await gamificationService.saveProfile(
          profile.copyWith(achievements: updatedAchievements)
        );
        
        // Add points for claiming achievement
        await gamificationService.addPoints(
          'achievement_claim',
          customPoints: achievement.pointsReward
        );
        
        // Refresh the profile data
        setState(() {
          _loadProfile();
        });
        
        // Close the dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${achievement.pointsReward} points added to your account!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(achievement.title)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: achievement.getTierColor(),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                achievement.tierName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getContrastColor(achievement.getTierColor()),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon with tier-specific styling
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: achievement.isEarned
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: achievement.isEarned && achievement.tier != AchievementTier.bronze
                    ? Border.all(color: achievement.getTierColor(), width: 3)
                    : null,
              ),
              child: getAchievementIcon(achievement.iconName, color: achievement.isEarned ? achievement.color : Colors.grey, size: 48),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            
            // Achievement description
            Text(
              achievement.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            
            // Achievement family ID info (if available)
            if (achievement.achievementFamilyId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                child: Text(
                  'Part of the ${achievement.achievementFamilyId} achievement series',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
            // Achievement points reward info
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${achievement.pointsReward} ${AppStrings.points}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            // Achievement status
            if (achievement.isEarned) 
              Column(
                children: [
                  Text(
                    'Earned on ${_formatDate(achievement.earnedOn!)}',
                    style: TextStyle(
                      color: achievement.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (achievement.isClaimable)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.paddingRegular),
                      child: ElevatedButton.icon(
                        onPressed: claimReward,
                        icon: Icon(Icons.redeem),
                        label: Text('Claim Reward'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                ],
              )
            else if (achievement.isLocked)
              Container(
                margin: const EdgeInsets.only(top: AppTheme.paddingSmall),
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.grey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocks at level ${achievement.unlocksAtLevel}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '${(achievement.progress * 100).round()}% Complete',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(achievement.color),
                    ),
                  ),
                ],
              ),
              
            // Metadata (if any)
            if (achievement.metadata.isNotEmpty && achievement.isEarned)
              Container(
                margin: const EdgeInsets.only(top: AppTheme.paddingRegular),
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...achievement.metadata.entries.map((entry) => 
                      Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(GamificationProfile profile) {
    final activeChallenges = profile.activeChallenges
        .where((challenge) => !challenge.isExpired && !challenge.isCompleted)
        .toList();
    final completedChallenges = profile.completedChallenges
        .take(5) // Show only the 5 most recent
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadProfile();
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active challenges
            Text(
              'Active Challenges',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),

            if (activeChallenges.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.paddingLarge),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        'No active challenges',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: AppTheme.fontSizeMedium,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingSmall),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement challenge generation
                          setState(() {
                            _loadProfile();
                          });
                        },
                        child: const Text('Get New Challenges'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeChallenges.length,
                itemBuilder: (context, index) {
                  final challenge = activeChallenges[index];
                  return _buildChallengeCard(challenge);
                },
              ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Completed challenges
            if (completedChallenges.isNotEmpty) ...[
              Text(
                'Completed Challenges',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedChallenges.length,
                itemBuilder: (context, index) {
                  final challenge = completedChallenges[index];
                  return _buildChallengeCard(challenge, isCompleted: true);
                },
              ),
              if (profile.completedChallenges.length > 5)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to all completed challenges
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View All Completed'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, {bool isCompleted = false}) {
    final endDate = challenge.endDate;
    final daysLeft = endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: challenge.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: getAchievementIcon(challenge.iconName, color: challenge.color, size: 28),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.paddingRegular),

            // Progress indicator and reward
            Row(
              children: [
                // Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted
                            ? 'Completed!'
                            : '${AppStrings.progress}: ${(challenge.progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: isCompleted ? challenge.color : null,
                          fontWeight: isCompleted ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                        child: LinearProgressIndicator(
                          value: isCompleted ? 1.0 : challenge.progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(challenge.color),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.paddingRegular),

                // Reward
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Reward',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.pointsReward} ${AppStrings.points}',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            if (!isCompleted) ...[
              const SizedBox(height: AppTheme.paddingRegular),

              // Time left and action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time remaining
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysLeft > 0
                            ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'
                            : 'Expires today',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: daysLeft < 2
                              ? Colors.orange
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab(GamificationProfile profile) {
    // Get weekly stats
    final weeklyStats = profile.weeklyStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card with overall stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Progress',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),

                  // Stats grid
                  Row(
                    children: [
                      _buildStatItem(
                        'Items Identified',
                        _getTotalItemsIdentified(profile).toString(),
                        Icons.search,
                        AppTheme.primaryColor,
                      ),
                      _buildStatItem(
                        'Categories',
                        profile.points.categoryPoints.length.toString(),
                        Icons.category,
                        AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Row(
                    children: [
                      _buildStatItem(
                        'Achievements',
                        profile.achievements
                            .where((a) => a.isEarned)
                            .length
                            .toString(),
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      _buildStatItem(
                        'Challenges',
                        profile.completedChallenges.length.toString(),
                        Icons.task_alt,
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Row(
                    children: [
                      _buildStatItem(
                        'Longest Streak',
                        '${profile.streak.longest} days',
                        Icons.local_fire_department,
                        Colors.deepOrange,
                      ),
                      _buildStatItem(
                        'Total Points',
                        profile.points.total.toString(),
                        Icons.stars,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Category breakdown
          const Text(
            'Waste Categories',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                children: profile.points.categoryPoints.entries.map((entry) {
                  final categoryName = entry.key;
                  final count = entry.value;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(categoryName),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(categoryName),
                        ),
                        Text(
                          '$count items',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Weekly stats
          const Text(
            'Weekly Progress',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),

          if (weeklyStats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'No weekly data available yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeklyStats.length,
              itemBuilder: (context, index) {
                final stats = weeklyStats[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week header
                        Text(
                          'Week of ${_formatDate(stats.weekStartDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        // Week stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(
                              'Items',
                              stats.itemsIdentified.toString(),
                              Icons.search,
                            ),
                            _buildMiniStat(
                              'Challenges',
                              stats.challengesCompleted.toString(),
                              Icons.task_alt,
                            ),
                            _buildMiniStat(
                              'Streak',
                              stats.streakMaximum.toString(),
                              Icons.local_fire_department,
                            ),
                            _buildMiniStat(
                              'Points',
                              stats.pointsEarned.toString(),
                              Icons.stars,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingSmall),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Helper functions
  String _getAchievementTypeTitle(AchievementType type) {
    switch (type) {
      case AchievementType.wasteIdentified:
        return 'Waste Identification';
      case AchievementType.categoriesIdentified:
        return 'Category Explorer';
      case AchievementType.streakMaintained:
        return 'Consistency';
      case AchievementType.challengesCompleted:
        return 'Challenges';
      case AchievementType.perfectWeek:
        return 'Perfect Weeks';
      case AchievementType.knowledgeMaster:
        return 'Knowledge';
      case AchievementType.quizCompleted:
        return 'Quiz Master';
      case AchievementType.specialItem:
        return 'Special Achievements';
      case AchievementType.communityContribution:
        return 'Community Contributions';
      case AchievementType.metaAchievement:
        return 'Meta Achievements';
      case AchievementType.specialEvent:
        return 'Special Events';
      case AchievementType.userGoal:
        return 'Personal Goals';
      case AchievementType.collectionMilestone:
        return 'Collection Milestones';
    }
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
      'bar_chart': 0xe26b,
    };

    return iconMap[iconName] ?? 0xe5d5; // Default to refresh icon
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  int _getTotalItemsIdentified(GamificationProfile profile) {
    int total = 0;
    for (final entry in profile.points.categoryPoints.entries) {
      total += entry.value;
    }
    return total;
  }

  Color _getCategoryColor(String category) {
    // Standard category colors from app theme
    if (category.toLowerCase().contains('wet')) {
      return AppTheme.wetWasteColor;
    } else if (category.toLowerCase().contains('dry')) {
      return AppTheme.dryWasteColor;
    } else if (category.toLowerCase().contains('hazardous')) {
      return AppTheme.hazardousWasteColor;
    } else if (category.toLowerCase().contains('medical')) {
      return AppTheme.medicalWasteColor;
    } else if (category.toLowerCase().contains('non')) {
      return AppTheme.nonWasteColor;
    }

    // Additional colors for subcategories
    if (category.toLowerCase().contains('paper')) {
      return Colors.blue.shade300;
    } else if (category.toLowerCase().contains('plastic')) {
      return Colors.blue.shade700;
    } else if (category.toLowerCase().contains('glass')) {
      return Colors.lightBlue;
    } else if (category.toLowerCase().contains('metal')) {
      return Colors.blueGrey;
    } else if (category.toLowerCase().contains('electronic')) {
      return Colors.orange;
    } else if (category.toLowerCase().contains('food')) {
      return Colors.green.shade300;
    }

    return Colors.grey; // Default color
  }

  // Helper to get a safe icon for achievements (constant for release)
  Icon getAchievementIcon(String iconName, {Color? color, double? size}) {
    // Always use a constant icon for release builds to avoid tree shaking issues
    return Icon(Icons.emoji_events, color: color, size: size);
  }
}
