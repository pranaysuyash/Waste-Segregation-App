// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../widgets/profile_summary_card.dart';

class AchievementsScreen extends StatefulWidget {

  const AchievementsScreen({
    super.key,
    this.initialTabIndex = 0,
  });
  final int initialTabIndex;

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

  Future<void> _refreshProfile() async {
    setState(() {
      _loadProfile();
    });
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
              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          Text(
                            'Error loading profile',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.paddingSmall),
                          Text(
                            '${snapshot.error}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.paddingLarge),
                          ElevatedButton.icon(
                            onPressed: _refreshProfile,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Text('No profile data available'),
                  ),
                ),
              );
            }

            final profile = snapshot.data!;

            return TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: _buildAchievementsTab(profile),
                ),
                RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: _buildChallengesTab(profile),
                ),
                RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: _buildStatsTab(profile),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(GamificationProfile profile) {
    // Group achievements by type
    final achievementsByType = <AchievementType, List<Achievement>>{};

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
                  const Icon(
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
                        '${_getCurrentStreak(profile)} ${_getCurrentStreak(profile) == 1 ? 'day' : 'days'}',
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
                        '${_getLongestStreak(profile)} ${_getLongestStreak(profile) == 1 ? 'day' : 'days'}',
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
                    return _buildAchievementCard(achievement, profile);
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

  Widget _buildAchievementCard(Achievement achievement, GamificationProfile profile) {
    final isEarned = achievement.isEarned;
    final isClaimable = achievement.isClaimable;
    // FIXED: Check if achievement is locked based on user's current level
    final isLocked = achievement.unlocksAtLevel != null && 
                         achievement.unlocksAtLevel! > profile.points.level;
    
    // DEBUGGING: Log achievement state for "Waste Apprentice"
    if (achievement.id == 'waste_apprentice') {
      debugPrint('🎯 UI DEBUG - Waste Apprentice Display:');
      debugPrint('  - User level: ${profile.points.level}');
      debugPrint('  - Unlocks at level: ${achievement.unlocksAtLevel}');
      debugPrint('  - Is locked: $isLocked');
      debugPrint('  - Is earned: $isEarned');
      debugPrint('  - Progress: ${(achievement.progress * 100).round()}%');
      debugPrint('  - Threshold: ${achievement.threshold}');
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isEarned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        side: isClaimable 
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement, profile),
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
                  child: const Center(
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                      style: const TextStyle(
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
    final brightness = (backgroundColor.r * 0.299 + 
                           backgroundColor.g * 0.587 + 
                           backgroundColor.b * 0.114) / 255;
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  void _showAchievementDetails(Achievement achievement, GamificationProfile profile) {
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    
    // Helper function to handle claiming rewards
    Future<void> claimReward() async {
      try {
        final profile = await gamificationService.getProfile();
        final updatedAchievements = List<Achievement>.from(profile.achievements);
        
        // Find the achievement by ID and update its claim status
        for (var i = 0; i < updatedAchievements.length; i++) {
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
        if (mounted) {
          setState(() {
            _loadProfile();
          });
        }
        
        // Close the dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${achievement.pointsReward} points added to your account!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to claim reward: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                  const Icon(
                    Icons.stars,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${achievement.pointsReward} ${AppStrings.points}',
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
                        icon: const Icon(Icons.redeem),
                        label: const Text('Claim Reward'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                ],
              )
            else if (achievement.unlocksAtLevel != null && 
                     achievement.unlocksAtLevel! > profile.points.level)
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
                    const Text(
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
                        style: const TextStyle(
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
            const Text(
              'Active Challenges',
              style: TextStyle(
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
                        onPressed: () async {
                          // Generate new random challenges for the user
                          try {
                            final gamificationService = Provider.of<GamificationService>(context, listen: false);
                            final profile = await gamificationService.getProfile();
                            
                            // Create sample new challenges
                            final newChallenges = [
                              Challenge(
                                id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
                                title: 'Weekly Recycling Goal',
                                description: 'Recycle 20 items this week',
                                iconName: 'recycle',
                                startDate: DateTime.now(),
                                endDate: DateTime.now().add(const Duration(days: 7)),
                                pointsReward: 100,
                                color: Colors.green,
                                requirements: {'category': 'Dry Waste', 'count': 20},
                              ),
                              Challenge(
                                id: 'challenge_${DateTime.now().millisecondsSinceEpoch + 1}',
                                title: 'Photo Challenge',
                                description: 'Take 10 waste segregation photos',
                                iconName: 'camera_alt',
                                startDate: DateTime.now(),
                                endDate: DateTime.now().add(const Duration(days: 5)),
                                pointsReward: 75,
                                color: Colors.blue,
                                requirements: {'any_item': true, 'count': 10},
                              ),
                            ];
                            
                            // Add the new challenges to the profile
                            final updatedProfile = profile.copyWith(
                              activeChallenges: [...profile.activeChallenges, ...newChallenges],
                            );
                            
                            await gamificationService.saveProfile(updatedProfile);
                            
                            if (mounted) {
                              setState(() {
                                _loadProfile();
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New challenges generated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to generate challenges: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
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
              const Text(
                'Completed Challenges',
                style: TextStyle(
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
                      // Navigate to a screen showing all completed challenges
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('All Completed Challenges'),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 400,
                            child: ListView.builder(
                              itemCount: profile.completedChallenges.length,
                              itemBuilder: (context, index) {
                                final challenge = profile.completedChallenges[index];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: challenge.color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: getAchievementIcon(
                                      challenge.iconName,
                                      color: challenge.color,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(challenge.title),
                                  subtitle: Text(challenge.description),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                                      Text('${challenge.pointsReward}'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
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
                        const Icon(
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
                        '${_getLongestStreak(profile)} days',
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
                  final points = entry.value;
                  final itemCount = (points / 10).round(); // Convert points to item count
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
                          '$itemCount items',
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
      // New achievement types for family features
      case AchievementType.firstClassification:
        return 'First Classification';
      case AchievementType.weekStreak:
        return 'Week Streak';
      case AchievementType.monthStreak:
        return 'Month Streak';
      case AchievementType.recyclingExpert:
        return 'Recycling Expert';
      case AchievementType.compostMaster:
        return 'Compost Master';
      case AchievementType.ecoWarrior:
        return 'Eco Warrior';
      case AchievementType.familyTeamwork:
        return 'Family Teamwork';
      case AchievementType.helpfulMember:
        return 'Helpful Member';
      case AchievementType.educationalContent:
        return 'Educational Content';
    }
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
    // Fix: Count items, not points! Each classification adds 10 points,
    // so we need to divide by 10 to get the actual item count
    var total = 0;
    for (final entry in profile.points.categoryPoints.entries) {
      total += (entry.value / 10).round(); // Convert points back to item count
    }
    return total;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'paper':
        return const Color(0xFF2196F3); // Use direct color instead of deprecated Colors.blue
      case 'plastic':
        return const Color(0xFFE91E63); // Pink
      case 'organic':
        return const Color(0xFF4CAF50); // Use direct color instead of deprecated Colors.green
      case 'hazardous':
        return const Color(0xFFF44336); // Use direct color instead of deprecated Colors.red
      default:
        return Colors.grey;
    }
  }

  // Helper to get a safe icon for achievements (constant for release)
  Icon getAchievementIcon(String iconName, {Color? color, double? size}) {
    // Always use a constant icon for release builds to avoid tree shaking issues
    return Icon(Icons.emoji_events, color: color, size: size);
  }

  // Helper methods for streak access
  int _getCurrentStreak(GamificationProfile profile) {
    // Get the daily classification streak, which is the primary streak
    final dailyStreak = profile.streaks[StreakType.dailyClassification.toString()];
    return dailyStreak?.currentCount ?? 0;
  }

  int _getLongestStreak(GamificationProfile profile) {
    // Get the longest streak from daily classification streak
    final dailyStreak = profile.streaks[StreakType.dailyClassification.toString()];
    return dailyStreak?.longestCount ?? 0;
  }
}
