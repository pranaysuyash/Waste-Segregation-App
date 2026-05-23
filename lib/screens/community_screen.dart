import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_feed.dart';
import '../services/community_service.dart';
import '../services/moderation_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/modern_ui/modern_cards.dart';
import 'package:flutter/foundation.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityFeedItem> _feedItems = [];
  CommunityStats? _stats;
  bool _isLoading = true;
  String _loadingMessage = 'Loading community data';

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Syncing your scans';
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final communityService = Provider.of<CommunityService>(
        context,
        listen: false,
      );
      final userProfile = await storageService.getCurrentUserProfile();

      await communityService.initCommunity();

      // Sync with real user data first
      final userClassifications = await storageService.getAllClassifications();
      await communityService.syncWithUserData(userClassifications, userProfile);

      final feedItems = await communityService.getFeedItems();
      final stats = await communityService.getStats();
      await communityService.reconcileCommunityStats(
        runDriftCheck: kDebugMode,
      );

      if (mounted) {
        setState(() {
          _feedItems = feedItems;
          _stats = stats;
          _isLoading = false;
          _loadingMessage = 'Done';
        });
      }
    } catch (e) {
      WasteAppLogger.severe('Error loading community data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Failed to load community data';
        });
      }
    }
  }

  Future<void> _forceSyncCommunityData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Syncing your scans';
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final communityService = Provider.of<CommunityService>(
        context,
        listen: false,
      );
      final userProfile = await storageService.getCurrentUserProfile();

      if (userProfile != null) {
        // Capture stats before sync for delta calculation
        final statsBefore = _stats;

        // Force sync all historical data
        final userClassifications =
            await storageService.getAllClassifications();
        WasteAppLogger.info(
          '🔄 FORCE SYNC: Starting with ${userClassifications.length} classifications',
        );

        await communityService.syncWithUserData(
          userClassifications,
          userProfile,
        );

        // Reload data after sync
        final feedItems = await communityService.getFeedItems();
        final stats = await communityService.getStats();
        final reconciliation = await communityService.reconcileCommunityStats(
          runDriftCheck: kDebugMode,
        );

        if (mounted) {
          setState(() {
            _feedItems = feedItems;
            _stats = stats;
            _isLoading = false;
          });

          // Calculate delta for feedback
          final userDelta = (stats.totalUsers) - (statsBefore?.totalUsers ?? 0);
          final classDelta = (stats.totalClassifications) -
              (statsBefore?.totalClassifications ?? 0);
          final pointsDelta =
              (stats.totalPoints) - (statsBefore?.totalPoints ?? 0);

          // Show detailed success message with delta
          String deltaMessage = '✅ Sync Complete!';
          if (classDelta > 0 || pointsDelta > 0 || userDelta > 0) {
            final parts = <String>[];
            if (classDelta > 0) parts.add('+$classDelta classifications');
            if (pointsDelta > 0) parts.add('+$pointsDelta points');
            if (userDelta > 0) parts.add('+$userDelta users');
            deltaMessage = '✅ Synced: ${parts.join(', ')}';
          } else if (reconciliation.isInSync && feedItems.isNotEmpty) {
            deltaMessage = '✅ Synced ${feedItems.length} community activities';
          } else if (!reconciliation.isInSync) {
            deltaMessage =
                '⚠️ Sync complete, but stats reconciliation flagged drift';
          } else {
            deltaMessage = '✅ Sync complete';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(deltaMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      WasteAppLogger.severe('❌ Error force syncing community data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Sync failed';
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
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Community'),
              centerTitle: false,
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync All Data',
                  onPressed: _forceSyncCommunityData,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.feed), text: 'Feed'),
                  Tab(icon: Icon(Icons.leaderboard), text: 'Stats'),
                  Tab(icon: Icon(Icons.people), text: 'Members'),
                ],
              ),
            )
          : null,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_loadingMessage),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildFeedTab(), _buildStatsTab(), _buildMembersTab()],
            ),
    );
  }

  Widget _buildFeedTab() {
    if (_feedItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCommunityData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          children: const [
            SizedBox(height: 160),
            Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
                    'Pull to refresh',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start classifying items or sync your data to see community activity.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
          return RepaintBoundary(
            key: ValueKey<String>(item.id),
            child: _buildFeedItem(item),
          );
        },
        // Add key to each item for proper widget tracking
        findChildIndexCallback: (Key key) {
          final valueKey = key as ValueKey<String>;
          final id = valueKey.value;
          return _feedItems.indexWhere((item) => item.id == id);
        },
      ),
    );
  }

  Widget _buildFeedItem(CommunityFeedItem item) {
    return ModernCard(
      key: ValueKey<String>(item.id),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.activityColor,
                child: Icon(item.activityIcon, color: Colors.white, size: 20),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.relativeTime,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          '+${item.points} pts',
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onSelected: (value) {
                  if (value == 'report') {
                    _showReportDialog(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Report', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog(CommunityFeedItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Report Post',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              ...ReportReason.values.map(
                (reason) => ListTile(
                  leading: Icon(_reasonIcon(reason), size: 20),
                  title: Text(_reasonLabel(reason),
                      style: const TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await ModerationService().reportPost(
                        postId: item.id,
                        reason: reason,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report submitted. Thank you.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _reasonIcon(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriate:
        return Icons.block;
      case ReportReason.spam:
        return Icons.report;
      case ReportReason.misinformation:
        return Icons.error_outline;
      case ReportReason.harmful:
        return Icons.warning;
      case ReportReason.privacy:
        return Icons.visibility_off;
      case ReportReason.other:
        return Icons.more_horiz;
    }
  }

  String _reasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriate:
        return 'Inappropriate content';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.misinformation:
        return 'Incorrect classification';
      case ReportReason.harmful:
        return 'Harmful or dangerous';
      case ReportReason.privacy:
        return 'Privacy concern';
      case ReportReason.other:
        return 'Other';
    }
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: Text('No stats available'));
    }

    // Empty state: when no community activity exists (source: real Firestore data)
    if (_stats!.totalUsers == 0 && _stats!.totalClassifications == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No community activity yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Pull to refresh or sync your data to see community stats.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _forceSyncCommunityData,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Data Now'),
            ),
          ],
        ),
      );
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Since you\'re the only user, community stats should match your personal stats exactly.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                  size: 16,
                                ),
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

          // Community overview - with source of truth annotation
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Stats',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Community activity summary from all users',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                if (_stats!.lastUpdated != null) ...[
                  Text(
                    'Last updated: ${_formatDateTime(_stats!.lastUpdated!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildStatRow('Total Users', '${_stats!.totalUsers}'),
                _buildStatRow(
                  'Total Classifications',
                  '${_stats!.totalClassifications}',
                ),
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 16),
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
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final classifications = await storageService.getAllClassifications();
      // Expected activity count should be at least the number of classifications
      // plus any achievements (rough estimate)
      return classifications.length;
    } catch (e) {
      WasteAppLogger.severe('Error getting expected activity count: $e');
      return 0;
    }
  }

  /// Format DateTime for display (e.g., "2 hours ago", "Today at 3:30 PM")
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 0) {
      return 'Today at ${_timeOfDay(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_timeOfDay(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Format time of day (e.g., "3:30 PM")
  String _timeOfDay(DateTime dateTime) {
    final hours = dateTime.hour;
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
    return '$displayHours:$minutes $period';
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
            Icon(Icons.construction, size: 64, color: Colors.grey),
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
