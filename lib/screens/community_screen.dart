import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_feed.dart';
import '../services/community_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/modern_ui/modern_cards.dart';

class CommunityScreen extends StatefulWidget {

  const CommunityScreen({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityFeedItem> _feedItems = [];
  CommunityStats? _stats;
  bool _isLoading = true;

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
      
      await communityService.initCommunity();
      
      // Sync with real user data first
      final userClassifications = await storageService.getAllClassifications();
      await communityService.syncWithUserData(userClassifications, userProfile);
      
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

  Future<void> _forceSyncCommunityData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final communityService = Provider.of<CommunityService>(context, listen: false);
      final userProfile = await storageService.getCurrentUserProfile();
      
      if (userProfile != null) {
        // Force sync all historical data
        final userClassifications = await storageService.getAllClassifications();
        debugPrint('🔄 FORCE SYNC: Starting with ${userClassifications.length} classifications');
        
        await communityService.syncWithUserData(userClassifications, userProfile);
        
        // Reload data after sync
        final feedItems = await communityService.getFeedItems();
        final stats = await communityService.getStats();
        
        if (mounted) {
          setState(() {
            _feedItems = feedItems;
            _stats = stats;
            _isLoading = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Synced ${feedItems.length} community activities'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error force syncing community data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync All Data',
            onPressed: _forceSyncCommunityData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: 'Feed'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Stats'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
          ],
        ),
      ) : null,
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

    const bottomPadding = AppTheme.paddingRegular + 56.0;

    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.paddingRegular,
          AppTheme.paddingRegular,
          AppTheme.paddingRegular,
          bottomPadding,
        ),
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
                backgroundColor: item.activityColor,
                child: Icon(
                  item.activityIcon,
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
                      item.displayName,
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
                      item.relativeTime,
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
                          color: AppTheme.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                        ),
                        child: Text(
                          '+${item.points} pts',
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
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

    const bottomPadding = AppTheme.paddingRegular + 56.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.paddingRegular,
        AppTheme.paddingRegular,
        AppTheme.paddingRegular,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Reconciliation Status
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data Reconciliation',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Since you\'re the only user, community stats should match your personal stats exactly.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Community Feed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_feedItems.length} activities',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Expected Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<int>(
                              future: _getExpectedActivityCount(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  '$count activities',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                FutureBuilder<int>(
                  future: _getExpectedActivityCount(),
                  builder: (context, snapshot) {
                    final expectedCount = snapshot.data ?? 0;
                    if (_feedItems.length < expectedCount) {
                      return Column(
                        children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap the sync button above to reconcile all historical data',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Community overview
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Stats',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Users', '${_stats!.totalUsers}'),
                _buildStatRow('Total Classifications', '${_stats!.totalClassifications}'),
                _buildStatRow('Total Points Earned', '${_stats!.totalPoints}'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          // Top Categories
          if (_stats!.categoryBreakdown.isNotEmpty)
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

  Future<int> _getExpectedActivityCount() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final classifications = await storageService.getAllClassifications();
      // Expected activity count should be at least the number of classifications
      // plus any achievements (rough estimate)
      return classifications.length;
    } catch (e) {
      debugPrint('Error getting expected activity count: $e');
      return 0;
    }
  }

  Widget _buildMembersTab() {
    return const SafeArea(
      top: false,
      left: false,
      right: false,
      child: Center(
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
      ),
    );
  }
} 