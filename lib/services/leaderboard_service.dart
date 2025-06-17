import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/leaderboard.dart'; // Assuming this is where LeaderboardEntry is defined
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _leaderboardCollection = 'leaderboard_allTime';

  /// Fetches the top N leaderboard entries.
  Future<List<LeaderboardEntry>> getTopNEntries(int limit) async {
    if (limit <= 0) return [];

    try {
      final querySnapshot = await _firestore
          .collection(_leaderboardCollection)
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      final entries = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          // Add the document ID as userId if it's not explicitly in the data, 
          // or ensure the existing userId matches.
          // The schema for leaderboard_allTime uses userId as document ID.
          data['userId'] = doc.id; 
          return LeaderboardEntry.fromJson(data);
        } catch (e) {
          WasteAppLogger.severe('Error parsing leaderboard entry with id ${doc.id}: $e');
          return null; // Skip entries that fail to parse
        }
      }).where((entry) => entry != null).cast<LeaderboardEntry>().toList();
      
      // Assign ranks based on sorted order
      for (var i = 0; i < entries.length; i++) {
        entries[i] = entries[i].copyWith(rank: i + 1);
      }
      
      return entries;
    } catch (e) {
      WasteAppLogger.severe('Error fetching top N leaderboard entries: $e');
      return []; // Return empty list on error
    }
  }

  /// Fetches the leaderboard entry for a specific user.
  /// This can be used to get the user's current points and potentially their rank.
  /// Note: Calculating exact rank might require a more complex query or client-side logic
  /// if not querying the entire leaderboard.
  Future<LeaderboardEntry?> getUserEntry(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final docSnapshot = await _firestore.collection(_leaderboardCollection).doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          data['userId'] = docSnapshot.id; // Ensure userId is set from doc ID
          // Rank is not directly stored per user in this model, typically derived from a full query.
          // For now, the rank field in the returned entry will be null unless set by getTopNEntries.
          return LeaderboardEntry.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      WasteAppLogger.severe('Error fetching user leaderboard entry for $userId: $e');
      return null;
    }
  }

  /// Fetches the current user's rank.
  /// This is a potentially expensive operation as it might need to count documents.
  /// Consider if this is needed frequently or if an approximate rank is acceptable.
  Future<int?> getCurrentUserRank(String userId) async {
    if (userId.isEmpty) return null;

    try {
      // Get the user's points first
      final userDoc = await _firestore.collection(_leaderboardCollection).doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        WasteAppLogger.info('User $userId not found in leaderboard_allTime.');
        return null; // User not on the leaderboard
      }
      final userPoints = userDoc.data()!['points'] as int? ?? 0;

      // Count users with more points
      final querySnapshot = await _firestore
          .collection(_leaderboardCollection)
          .where('points', isGreaterThan: userPoints)
          .count()
          .get();
      
      // Rank is 1 (if no one has more points) + count of users with more points
      final rank = (querySnapshot.count ?? 0) + 1;
      return rank;

    } catch (e) {
      WasteAppLogger.severe('Error fetching current user rank for $userId: $e');
      return null;
    }
  }

  // TODO: Potentially add methods for weekly/monthly leaderboards if those collections are created.
} 