import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<WeeklyStats>> _weeklyStatsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWeeklyStats();
  }

  void _loadWeeklyStats() {
    final gamificationService =
        Provider.of<GamificationService>(context, listen: false);
    _weeklyStatsFuture = gamificationService.getWeeklyStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: FutureBuilder<List<WeeklyStats>>(
        future: _weeklyStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leaderboard: ${snapshot.error}'),
            );
          }

          // For demonstration purposes, create sample leaderboard data
          // In a real app, this would come from a backend service
          final List<UserStats> weeklyLeaders = _generateSampleLeaderboard();
          final List<UserStats> monthlyLeaders = _generateSampleLeaderboard();
          final List<ChallengeLeaderboard> challengeLeaders =
              _generateSampleChallengeLeaderboard();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardTab(weeklyLeaders, 'Weekly Points'),
              _buildLeaderboardTab(monthlyLeaders, 'Monthly Points'),
              _buildChallengeLeaderboardTab(challengeLeaders),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTab(List<UserStats> leaders, String title) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.paddingSmall),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Refresh leaderboard
                  setState(() {
                    _loadWeeklyStats();
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // Top 3 podium
        if (leaders.length >= 3)
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                _buildPodiumPosition(
                  leaders[1],
                  position: 2,
                  height: 90,
                  color: Colors.grey.shade400,
                ),

                // 1st place
                _buildPodiumPosition(
                  leaders[0],
                  position: 1,
                  height: 120,
                  color: Colors.amber,
                ),

                // 3rd place
                _buildPodiumPosition(
                  leaders[2],
                  position: 3,
                  height: 70,
                  color: Colors.brown.shade300,
                ),
              ],
            ),
          ),

        // Rest of leaderboard
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
            itemCount: leaders.length > 3 ? leaders.length - 3 : 0,
            itemBuilder: (context, index) {
              final actualIndex = index + 3; // Skip first 3 shown in podium
              final user = leaders[actualIndex];
              return _buildLeaderboardItem(user, actualIndex + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPosition(
    UserStats user, {
    required int position,
    required double height,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User avatar
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: position == 1 ? 32 : 24,
                backgroundColor: color.withOpacity(0.3),
                child: CircleAvatar(
                  radius: position == 1 ? 28 : 20,
                  backgroundColor: color,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: position == 1 ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Position badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: position == 1 ? Colors.amber : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Username
          Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Points
          Text(
            '${user.points} pts',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),

          const SizedBox(height: 8),

          // Podium
          Container(
            width: 60,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusSmall),
                topRight: Radius.circular(AppTheme.borderRadiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(UserStats user, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingSmall),
        child: Row(
          children: [
            // Position
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$position',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: AppTheme.paddingSmall),

            // User avatar
            CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              radius: 16,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: AppTheme.paddingSmall),

            // User name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.rank,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Points
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                '${user.points} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeLeaderboardTab(List<ChallengeLeaderboard> challenges) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge header
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                decoration: BoxDecoration(
                  color: challenge.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusRegular),
                    topRight: Radius.circular(AppTheme.borderRadiusRegular),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      IconData(
                        _getIconCodePoint(challenge.iconName),
                        fontFamily: 'MaterialIcons',
                      ),
                      color: challenge.color,
                    ),
                    const SizedBox(width: AppTheme.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeMedium,
                            ),
                          ),
                          Text(
                            '${challenge.participantCount} participants • ${_getRemainingTime(challenge.endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!challenge.isCompleted && !challenge.isExpired)
                      ElevatedButton(
                        onPressed: () {
                          // Join challenge
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: challenge.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingSmall,
                            vertical: 4,
                          ),
                        ),
                        child: const Text('Join'),
                      ),
                  ],
                ),
              ),

              // Top participants
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                itemCount: challenge.topParticipants.length,
                itemBuilder: (context, index) {
                  final participant = challenge.topParticipants[index];
                  return _buildLeaderboardItem(participant, index + 1);
                },
              ),

              // See more button
              Padding(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // View full leaderboard
                    },
                    child: const Text('View Full Leaderboard'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods
  List<UserStats> _generateSampleLeaderboard() {
    return [
      UserStats(name: 'EcoWarrior', rank: 'Sustainability Sage', points: 2145),
      UserStats(name: 'GreenThumb', rank: 'Eco Champion', points: 1872),
      UserStats(name: 'RecycleHero', rank: 'Waste Warrior', points: 1654),
      UserStats(
          name: 'EarthProtector', rank: 'Segregation Specialist', points: 1427),
      UserStats(name: 'ZeroWaste', rank: 'Waste Warrior', points: 1289),
      UserStats(name: 'EcoFriendly', rank: 'Recycling Rookie', points: 983),
      UserStats(name: 'PlanetSaver', rank: 'Waste Warrior', points: 876),
      UserStats(
          name: 'SustainableLiving', rank: 'Recycling Rookie', points: 724),
      UserStats(name: 'GreenLiving', rank: 'Recycling Rookie', points: 512),
      UserStats(name: 'EcoConscious', rank: 'Recycling Rookie', points: 345),
    ];
  }

  List<ChallengeLeaderboard> _generateSampleChallengeLeaderboard() {
    return [
      ChallengeLeaderboard(
        title: 'Community Cleanup',
        description:
            'Join the leaderboard competition for most waste items identified',
        iconName: 'public',
        color: Colors.purple,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        participantCount: 42,
        isCompleted: false,
        isExpired: false,
        topParticipants: [
          UserStats(
              name: 'EcoWarrior', rank: 'Sustainability Sage', points: 87),
          UserStats(name: 'GreenThumb', rank: 'Eco Champion', points: 65),
          UserStats(name: 'RecycleHero', rank: 'Waste Warrior', points: 52),
        ],
      ),
      ChallengeLeaderboard(
        title: 'Plastic Reduction',
        description: 'Identify the most plastic items for recycling',
        iconName: 'shopping_bag',
        color: Colors.blue,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        participantCount: 56,
        isCompleted: true,
        isExpired: true,
        topParticipants: [
          UserStats(name: 'RecycleHero', rank: 'Waste Warrior', points: 94),
          UserStats(
              name: 'EarthProtector',
              rank: 'Segregation Specialist',
              points: 82),
          UserStats(name: 'GreenThumb', rank: 'Eco Champion', points: 71),
        ],
      ),
    ];
  }

  int _getIconCodePoint(String iconName) {
    // Map of icon names to code points
    const Map<String, int> iconMap = {
      'public': 0xe894,
      'group': 0xe7ef,
      'shopping_bag': 0xf1cc,
      'recycling': 0xe7c0,
    };

    return iconMap[iconName] ?? 0xe5d5; // Default to refresh icon
  }

  String _getRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return '$days days left';
    } else {
      return '$hours hours left';
    }
  }
}

class UserStats {
  final String name;
  final String rank;
  final int points;

  UserStats({
    required this.name,
    required this.rank,
    required this.points,
  });
}

class ChallengeLeaderboard {
  final String title;
  final String description;
  final String iconName;
  final Color color;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final bool isCompleted;
  final bool isExpired;
  final List<UserStats> topParticipants;

  ChallengeLeaderboard({
    required this.title,
    required this.description,
    required this.iconName,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    required this.isCompleted,
    required this.isExpired,
    required this.topParticipants,
  });
}
