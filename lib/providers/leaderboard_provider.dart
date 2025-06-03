import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';
import '../services/storage_service.dart'; // For getting current user ID

// Provider for LeaderboardService
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(); // Assumes LeaderboardService has no complex dependencies yet
});

// Provider for the list of top N leaderboard entries
final topLeaderboardEntriesProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, int>((ref, limit) async {
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  return leaderboardService.getTopNEntries(limit);
});

// Provider for the current user's leaderboard entry (if they exist on the leaderboard)
final currentUserLeaderboardEntryProvider = FutureProvider.autoDispose<LeaderboardEntry?>((ref) async {
  final storageService = ref.watch(storageServiceProvider); // Assuming storageServiceProvider exists
  final userProfile = await storageService.getCurrentUserProfile();
  
  if (userProfile == null || userProfile.id.isEmpty) {
    return null; // No logged-in user
  }
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  return leaderboardService.getUserEntry(userProfile.id);
});

// Provider for the current user's rank
final currentUserRankProvider = FutureProvider.autoDispose<int?>((ref) async {
  final storageService = ref.watch(storageServiceProvider); // Assuming storageServiceProvider exists
  final userProfile = await storageService.getCurrentUserProfile();
  
  if (userProfile == null || userProfile.id.isEmpty) {
    return null; // No logged-in user
  }
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  return leaderboardService.getCurrentUserRank(userProfile.id);
});

// A combined state provider if needed for a screen that shows both top entries and user rank
class LeaderboardScreenData {
  final List<LeaderboardEntry> topEntries;
  final LeaderboardEntry? currentUserEntry;
  final int? currentUserRank;

  LeaderboardScreenData({
    required this.topEntries,
    this.currentUserEntry,
    this.currentUserRank,
  });
}

final leaderboardScreenDataProvider = FutureProvider.autoDispose<LeaderboardScreenData>((ref) async {
  final topN = 20; // Default number of top entries to show
  // Fetch in parallel
  final topEntriesFuture = ref.watch(topLeaderboardEntriesProvider(topN).future);
  final currentUserEntryFuture = ref.watch(currentUserLeaderboardEntryProvider.future);
  final currentUserRankFuture = ref.watch(currentUserRankProvider.future);

  final results = await Future.wait([
    topEntriesFuture,
    currentUserEntryFuture,
    currentUserRankFuture,
  ]);

  return LeaderboardScreenData(
    topEntries: results[0] as List<LeaderboardEntry>,
    currentUserEntry: results[1] as LeaderboardEntry?,
    currentUserRank: results[2] as int?,
  );
});

// Provider for StorageService (if not already defined elsewhere)
// This is a placeholder - ensure it's correctly defined and provided in your app.
final storageServiceProvider = Provider<StorageService>((ref) {
  // This needs to return your actual StorageService instance.
  // It might be initialized in your main.dart or a similar setup location.
  // For now, this will cause an error if not properly set up.
  throw UnimplementedError('storageServiceProvider needs to be implemented and provide a StorageService instance.');
  // Example: return StorageService(); // if it has a simple constructor and is already initialized (e.g. Hive)
}); 