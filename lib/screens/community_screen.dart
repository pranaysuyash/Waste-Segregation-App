import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_feed.dart';
import '../services/community_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/modern_ui/modern_cards.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityFeedItem> _feedItems = [];
  CommunityStats? _stats;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommunityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityData() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final communityService = Provider.of<CommunityService>(context, listen: false);
      final userProfile = await storageService.getCurrentUserProfile();
      _currentUserId = userProfile?.id ?? 'guest_user';
      
      await communityService.initCommunity();
      
      // Generate sample data if feed is empty
      final existingItems = await communityService.getFeedItems();
      if (existingItems.isEmpty) {
        await communityService.generateSampleCommunityData();
      }
      
      final feedItems = await communityService.getFeedItems();
      final stats = await communityService.getStats();
      
      if (mounted) {
        setState(() {
          _feedItems = feedItems;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading community data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: 'Feed'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Stats'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTab(),
                _buildStatsTab(),
                _buildMembersTab(),
              ],
            ),
    );
  }

  Widget _buildFeedTab() {
    if (_feedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No community activity yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start classifying items to see community activity!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return _buildFeedItem(item);
        },
      ),
    );
  }

  Widget _buildFeedItem(CommunityFeedItem item) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getActivityColor(item.activityType),
                child: Icon(
                  _getActivityIcon(item.activityType),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatRelativeTime(item.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.points > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${item.points} pts',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: Text('No stats available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community overview
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  
                  _buildStatRow('Total Members', '${_stats!.totalUsers}'),
                  _buildStatRow('Total Classifications', '${_stats!.totalClassifications}'),
                  _buildStatRow('Total Points Earned', '${_stats!.totalPoints}'),
                  _buildStatRow('Active Today', '${_stats!.activeToday}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Top categories
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Categories',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  
                  ..._stats!.topCategories.entries.map((entry) {
                    return _buildStatRow(entry.key, '${entry.value} items');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Members Directory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon! View and connect with other community members.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(CommunityActivityType type) {
    switch (type) {
      case CommunityActivityType.classification:
        return Icons.camera_alt;
      case CommunityActivityType.achievement:
        return Icons.emoji_events;
      case CommunityActivityType.streak:
        return Icons.local_fire_department;
      case CommunityActivityType.challenge:
        return Icons.flag;
      case CommunityActivityType.milestone:
        return Icons.star;
      case CommunityActivityType.educational:
        return Icons.school;
    }
  }

  Color _getActivityColor(CommunityActivityType type) {
    switch (type) {
      case CommunityActivityType.classification:
        return AppTheme.primaryColor;
      case CommunityActivityType.achievement:
        return Colors.amber;
      case CommunityActivityType.streak:
        return Colors.orange;
      case CommunityActivityType.challenge:
        return Colors.purple;
      case CommunityActivityType.milestone:
        return Colors.green;
      case CommunityActivityType.educational:
        return Colors.blue;
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
} 