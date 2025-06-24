import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/leaderboard_provider.dart';
import '../../models/leaderboard.dart';
import '../../widgets/production_error_handler.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardDataAsync = ref.watch(leaderboardScreenDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 1,
      ),
      body: leaderboardDataAsync.when(
        data: (data) {
          final topEntries = data.topEntries;
          final currentUserEntry = data.currentUserEntry;
          final currentUserRank = data.currentUserRank;

          if (topEntries.isEmpty && currentUserEntry == null) {
            return const Center(
              child: Text(
                'Leaderboard is empty or data is still loading.\nCheck back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(topLeaderboardEntriesProvider);
              ref.invalidate(currentUserLeaderboardEntryProvider);
              ref.invalidate(currentUserRankProvider);
              await ref.read(leaderboardScreenDataProvider.future);
            },
            child: CustomScrollView(
              slivers: <Widget>[
                if (currentUserEntry != null || currentUserRank != null)
                  SliverToBoxAdapter(
                    child: _buildCurrentUserSection(context, currentUserEntry, currentUserRank),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Text(
                      'Top Performers',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (topEntries.isNotEmpty)
                  _buildLeaderboardList(topEntries)
                else
                  const SliverFillRemaining(
                    child: Center(
                        child: Text('No top performers yet.', style: TextStyle(fontSize: 16, color: Colors.grey))),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingStateHandler(showShimmer: false)),
        error: (error, stackTrace) {
          WasteAppLogger.severe('Error loading leaderboard screen: $error\n$stackTrace');
          return Center(
            child: EmptyStateHandler(
                title: 'Leaderboard Error',
                message: 'Could not load leaderboard. Please try again.',
                icon: Icons.error_outline,
                actionText: 'Retry',
                onAction: () {
                  ref.invalidate(leaderboardScreenDataProvider);
                }),
          );
        },
      ),
    );
  }

  Widget _buildCurrentUserSection(BuildContext context, LeaderboardEntry? currentUserEntry, int? currentUserRank) {
    final rankToShow = currentUserRank ?? currentUserEntry?.rank;
    final pointsToShow = currentUserEntry?.points;

    if (rankToShow == null && pointsToShow == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Position',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (rankToShow != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rank', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
                      Text('$rankToShow',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (pointsToShow != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Points', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
                      Text('$pointsToShow',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            if (currentUserEntry?.displayName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Keep up the great work, ${currentUserEntry!.displayName}!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final entry = entries[index];
          final rank = entry.rank ?? (index + 1);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? ClipOval(child: Image.network(entry.photoUrl!, width: 40, height: 40, fit: BoxFit.cover))
                    : Text(
                        entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                      ),
              ),
              title: Text(
                entry.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${entry.points} points'),
              trailing: Text(
                '#$rank',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }
}
