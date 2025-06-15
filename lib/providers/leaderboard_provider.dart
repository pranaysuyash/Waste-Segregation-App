import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/leaderboard.dart';
import '../services/storage_service.dart';
import '../services/leaderboard_service.dart';
import 'app_providers.dart'; // Import central providers

/// Provider for LeaderboardService
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

/// Provider for leaderboard data (using LeaderboardEntry model)
final leaderboardEntriesProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  
  try {
    // Get top 100 leaderboard entries
    final entries = await leaderboardService.getTopNEntries(100);
    return entries;
  } catch (e) {
    // If fails, return empty list
    return <LeaderboardEntry>[];
  }
});

/// Provider for user's leaderboard position
final userLeaderboardPositionProvider = FutureProvider<int?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  
  try {
    final currentUser = await storageService.getCurrentUserProfile();
    if (currentUser == null) return null;
    
    // Get user's rank directly from leaderboard service
    final rank = await leaderboardService.getCurrentUserRank(currentUser.id);
    return rank;
  } catch (e) {
    return null;
  }
});

/// Provider for current user's leaderboard entry
final currentUserLeaderboardEntryProvider = FutureProvider<LeaderboardEntry?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  
  try {
    final currentUser = await storageService.getCurrentUserProfile();
    if (currentUser == null) return null;
    
    // Get user's entry from leaderboard service
    final entry = await leaderboardService.getUserEntry(currentUser.id);
    return entry;
  } catch (e) {
    return null;
  }
});

/// Provider for top 3 leaderboard entries
final topThreeLeaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  final leaderboardAsync = ref.watch(leaderboardEntriesProvider);
  
  return leaderboardAsync.when(
    data: (entries) => entries.take(3).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for leaderboard statistics
final leaderboardStatsProvider = Provider<LeaderboardStats>((ref) {
  final leaderboardAsync = ref.watch(leaderboardEntriesProvider);
  
  return leaderboardAsync.when(
    data: (entries) {
      if (entries.isEmpty) {
        return const LeaderboardStats(
          totalUsers: 0,
          averagePoints: 0,
          topScore: 0,
        );
      }
      
      final totalUsers = entries.length;
      final totalPoints = entries.fold<int>(0, (sum, entry) => sum + entry.points);
      final averagePoints = totalPoints / totalUsers;
      final topScore = entries.first.points;
      
      return LeaderboardStats(
        totalUsers: totalUsers,
        averagePoints: averagePoints.round(),
        topScore: topScore,
      );
    },
    loading: () => const LeaderboardStats(
      totalUsers: 0,
      averagePoints: 0,
      topScore: 0,
    ),
    error: (_, __) => const LeaderboardStats(
      totalUsers: 0,
      averagePoints: 0,
      topScore: 0,
    ),
  );
});

/// Data class for leaderboard statistics
class LeaderboardStats {
  const LeaderboardStats({
    required this.totalUsers,
    required this.averagePoints,
    required this.topScore,
  });

  final int totalUsers;
  final int averagePoints;
  final int topScore;
}

// REMOVED: Duplicate provider declarations that were causing the issue
// These are now imported from app_providers.dart 