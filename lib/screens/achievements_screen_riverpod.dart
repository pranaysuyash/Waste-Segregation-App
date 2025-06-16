import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../providers/gamification_provider.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../widgets/advanced_ui/achievement_celebration.dart';

/// Improved AchievementsScreen using Riverpod with better architecture
class AchievementsScreenRiverpod extends ConsumerStatefulWidget {
  const AchievementsScreenRiverpod({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  ConsumerState<AchievementsScreenRiverpod> createState() => _AchievementsScreenRiverpodState();
}

class _AchievementsScreenRiverpodState extends ConsumerState<AchievementsScreenRiverpod>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  
  // Achievement celebration state
  bool _showCelebration = false;
  Achievement? _celebrationAchievement;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    final notifier = ref.read(gamificationProvider.notifier);
    await notifier.refresh();
  }

  void _showAchievementCelebration(Achievement achievement) {
    setState(() {
      _celebrationAchievement = achievement;
      _showCelebration = true;
    });
  }

  void _onCelebrationDismissed() {
    setState(() {
      _showCelebration = false;
      _celebrationAchievement = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.achievements),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.badges),
            Tab(text: AppStrings.challenges),
            Tab(text: AppStrings.stats),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _AchievementsTab(onCelebration: _showAchievementCelebration),
              _ChallengesTab(),
              _StatsTab(),
            ],
          ),
          if (_showCelebration && _celebrationAchievement != null)
            AchievementCelebration(
              achievement: _celebrationAchievement!,
              onDismiss: _onCelebrationDismissed,
            ),
        ],
      ),
    );
  }
}

/// Achievements tab with improved accessibility and performance
class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab({required this.onCelebration});

  final void Function(Achievement) onCelebration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(gamificationProvider);
    final stats = ref.watch(achievementStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(gamificationProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: _StatsOverview(stats: stats),
            ),
          ),
          profileAsync.when(
            data: (profile) => _AchievementGrid(
              achievements: profile.achievements,
              onCelebration: onCelebration,
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _ErrorView(
                error: error,
                onRetry: () => ref.read(gamificationProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats overview widget with accessibility
class _StatsOverview extends StatelessWidget {
  const _StatsOverview({required this.stats});

  final AchievementStats stats;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Achievement statistics: ${stats.earned} of ${stats.total} achievements earned, ${stats.totalPoints} total points',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.progress,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Earned',
                    value: '${stats.earned}',
                    color: context.colorScheme.primary,
                  ),
                  _StatItem(
                    label: 'Claimable',
                    value: '${stats.claimable}',
                    color: context.colorScheme.secondary,
                  ),
                  _StatItem(
                    label: 'Total ${AppStrings.points}',
                    value: '${stats.totalPoints}',
                    color: context.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              LinearProgressIndicator(
                value: stats.total > 0 ? stats.earned / stats.total : 0,
                backgroundColor: context.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(context.colorScheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                '${stats.completionPercentage}% ${AppStrings.complete}',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual stat item with accessibility
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Achievement grid with improved accessibility and performance
class _AchievementGrid extends ConsumerWidget {
  const _AchievementGrid({
    required this.achievements,
    required this.onCelebration,
  });

  final List<Achievement> achievements;
  final void Function(Achievement) onCelebration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final achievement = achievements[index];
            return _AchievementCard(
              achievement: achievement,
              onCelebration: onCelebration,
            );
          },
          childCount: achievements.length,
        ),
      ),
    );
  }
}

/// Individual achievement card with accessibility and proper contrast
class _AchievementCard extends ConsumerWidget {
  const _AchievementCard({
    required this.achievement,
    required this.onCelebration,
  });

  final Achievement achievement;
  final void Function(Achievement) onCelebration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClaimable = achievement.isClaimable;
    final backgroundColor = achievement.getTierBackgroundColor();
    final textColor = achievement.getContrastSafeTextColor(context);

    return Semantics(
      button: isClaimable,
      label: achievement.getSemanticLabel(),
      child: Card(
        color: backgroundColor,
        elevation: achievement.isEarned ? AppTheme.elevationMd : AppTheme.elevationSm,
        child: InkWell(
          onTap: isClaimable ? () => _claimReward(ref, achievement) : null,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconData(achievement.iconName),
                      color: achievement.getTierColor(),
                      size: AppTheme.iconSizeLg,
                    ),
                    const Spacer(),
                    if (achievement.isEarned)
                      Icon(
                        Icons.check_circle,
                        color: context.colorScheme.primary,
                        size: AppTheme.iconSizeMd,
                      ),
                    if (isClaimable)
                      Icon(
                        Icons.card_giftcard,
                        color: context.colorScheme.secondary,
                        size: AppTheme.iconSizeMd,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  achievement.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  achievement.description,
                  style: context.textTheme.bodySmall?.copyWith(color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (!achievement.isEarned) ...[
                  LinearProgressIndicator(
                    value: achievement.progressPercent,
                    backgroundColor: textColor.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(achievement.getTierColor()),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${achievement.progressPercentInt}%',
                    style: context.textTheme.bodySmall?.copyWith(color: textColor),
                  ),
                ],
                if (isClaimable)
                  Container(
                    width: double.infinity,
                    height: AppTheme.buttonHeightSm,
                    margin: const EdgeInsets.only(top: AppTheme.spacingXs),
                    child: ElevatedButton(
                      onPressed: () => _claimReward(ref, achievement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                      ),
                      child: const Text('Claim'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _claimReward(WidgetRef ref, Achievement achievement) async {
    final notifier = ref.read(gamificationProvider.notifier);
    final result = await notifier.claimReward(achievement.id);
    
    result.when(
      success: (_) => onCelebration(achievement),
      failure: (error) {
        // Show error snackbar
        // TODO: Use proper context and localization
      },
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to actual IconData
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'recycling':
        return Icons.recycling;
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'badge':
        return Icons.military_tech;
      default:
        return Icons.emoji_events;
    }
  }
}

/// Challenges tab placeholder
class _ChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('${AppStrings.challenges} coming soon!'),
    );
  }
}

/// Stats tab placeholder
class _StatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Detailed ${AppStrings.stats} coming soon!'),
    );
  }
}

/// Error view with retry functionality
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorMessage = error is AppException 
        ? (error as AppException).message 
        : AppStrings.errorGeneral;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppTheme.iconSizeXl,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to load ${AppStrings.achievements}',
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              errorMessage,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
} 