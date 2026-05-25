import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cooperative_mechanics.dart';
import '../models/gamification.dart' show AnalyticsEventTypes;
import '../utils/waste_app_logger.dart';
import 'analytics_service.dart';
import 'firestore_schema_registry.dart';

/// Mechanic-level analytics for the gamification and cooperative features.
///
/// This service is the measurement layer that makes cooperative mechanics
/// provable or removable. Every mechanic tracked here has a corresponding
/// kill criterion in FAMILY_COOPERATIVE_MECHANICS.md.
///
/// Kill criteria to track:
///   - participationRate < 0.3 for family groups after 30 days → demote dashboard
///   - goalCompletionRate < 0.2 → simplify goals or remove
///   - cooperative challenge join rate < 0.4 → remove cooperative challenges
///   - nonPrimaryUserReturn7d < 2/week → cooperative mechanics not driving return
///
/// All events go through the shared AnalyticsService for consent management
/// and Firestore availability gating.
class GamificationAnalyticsService {
  GamificationAnalyticsService({
    required AnalyticsService analyticsService,
    FirebaseFirestore? firestore,
  })  : _analytics = analyticsService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AnalyticsService _analytics;
  final FirebaseFirestore _firestore;

  // ── Goal Events ────────────────────────────────────────────────────────────

  Future<void> trackGoalCreated({
    required String familyId,
    required String goalId,
    required GoalType type,
    required int targetValue,
    required int daysUntilDeadline,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_goal_created',
      parameters: {
        'family_id': familyId,
        'goal_id': goalId,
        'goal_type': type.name,
        'target_value': targetValue,
        'days_until_deadline': daysUntilDeadline,
      },
    );
  }

  Future<void> trackGoalContribution({
    required String familyId,
    required String goalId,
    required String userId,
    required int amount,
    required double newProgressFraction,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_goal_contribution',
      parameters: {
        'family_id': familyId,
        'goal_id': goalId,
        'user_id': userId,
        'amount': amount,
        'progress_pct': (newProgressFraction * 100).round(),
      },
    );
  }

  Future<void> trackGoalCompleted({
    required String familyId,
    required String goalId,
    required GoalType type,
    required int contributorCount,
    required int daysToComplete,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_goal_completed',
      parameters: {
        'family_id': familyId,
        'goal_id': goalId,
        'goal_type': type.name,
        'contributor_count': contributorCount,
        'days_to_complete': daysToComplete,
      },
    );
  }

  Future<void> trackGoalExpired({
    required String familyId,
    required String goalId,
    required double finalProgressFraction,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_goal_expired',
      parameters: {
        'family_id': familyId,
        'goal_id': goalId,
        'final_progress_pct': (finalProgressFraction * 100).round(),
      },
    );
  }

  // ── Task Events ────────────────────────────────────────────────────────────

  Future<void> trackTaskCreated({
    required String familyId,
    required String taskId,
    required TaskTargetRole targetRole,
    required bool isLinkedToGoal,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_task_created',
      parameters: {
        'family_id': familyId,
        'task_id': taskId,
        'target_role': targetRole.name,
        'linked_to_goal': isLinkedToGoal,
      },
    );
  }

  Future<void> trackTaskCompleted({
    required String familyId,
    required String taskId,
    required TaskTargetRole targetRole,
    required String completedByUserId,
    required bool wasOverdue,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'family_task_completed',
      parameters: {
        'family_id': familyId,
        'task_id': taskId,
        'target_role': targetRole.name,
        'completed_by': completedByUserId,
        'was_overdue': wasOverdue,
      },
    );
  }

  // ── Household Streak Events ────────────────────────────────────────────────

  Future<void> trackStreakMaintained({
    required String familyId,
    required int currentStreak,
    required String contributorUserId,
    required bool wasAlreadyActiveToday,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'household_streak_maintained',
      parameters: {
        'family_id': familyId,
        'streak_days': currentStreak,
        'contributor': contributorUserId,
        'already_active': wasAlreadyActiveToday,
      },
    );
  }

  Future<void> trackStreakBroken({
    required String familyId,
    required int lostStreak,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'household_streak_broken',
      parameters: {
        'family_id': familyId,
        'lost_streak': lostStreak,
      },
    );
  }

  // ── Cooperative Challenge Events ───────────────────────────────────────────

  Future<void> trackChallengeCreated({
    required String familyId,
    required String challengeId,
    required CoopChallengeType type,
    required int minParticipants,
    required int durationDays,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'coop_challenge_created',
      parameters: {
        'family_id': familyId,
        'challenge_id': challengeId,
        'type': type.name,
        'min_participants': minParticipants,
        'duration_days': durationDays,
      },
    );
  }

  Future<void> trackChallengeJoined({
    required String familyId,
    required String challengeId,
    required String userId,
    required int currentParticipantCount,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'coop_challenge_joined',
      parameters: {
        'family_id': familyId,
        'challenge_id': challengeId,
        'user_id': userId,
        'participant_count': currentParticipantCount,
      },
    );
  }

  Future<void> trackChallengeCompleted({
    required String familyId,
    required String challengeId,
    required CoopChallengeType type,
    required int participantCount,
    required int daysToComplete,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'coop_challenge_completed',
      parameters: {
        'family_id': familyId,
        'challenge_id': challengeId,
        'type': type.name,
        'participant_count': participantCount,
        'days_to_complete': daysToComplete,
      },
    );
  }

  // ── Parent-Child Mission Events ────────────────────────────────────────────

  Future<void> trackMissionCreated({
    required String familyId,
    required String missionId,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'parent_child_mission_created',
      parameters: {
        'family_id': familyId,
        'mission_id': missionId,
      },
    );
  }

  Future<void> trackMissionCompleted({
    required String familyId,
    required String missionId,
    required int daysToComplete,
  }) async {
    await _analytics.trackEvent(
      eventType: AnalyticsEventTypes.cooperative,
      eventName: 'parent_child_mission_completed',
      parameters: {
        'family_id': familyId,
        'mission_id': missionId,
        'days_to_complete': daysToComplete,
      },
    );
  }

  // ── Aggregate Retention Metrics ────────────────────────────────────────────

  /// Returns the last N snapshots for a family for use in the analytics
  /// dashboard. Callers handle the UI presentation.
  Future<List<CooperativeMechanicSnapshot>> getSnapshotHistory({
    required String familyId,
    int days = 30,
  }) async {
    try {
      final cutoff =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final snap = await _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.cooperativeSnapshots)
          .where('snapshotDate', isGreaterThan: cutoff)
          .orderBy('snapshotDate', descending: false)
          .get();

      return snap.docs
          .map((d) => CooperativeMechanicSnapshot.fromJson(d.data()))
          .toList();
    } catch (e) {
      WasteAppLogger.severe(
          'GamificationAnalytics: getSnapshotHistory failed', error: e);
      return [];
    }
  }

  /// Returns aggregated metrics across all families for the operator
  /// analytics dashboard. Requires admin Firestore rules.
  Future<AggregatedCoopMetrics> getAggregatedMetrics({
    required DateTime since,
  }) async {
    try {
      // Query across all family snapshot docs written after [since].
      // This is a collection-group query: all 'cooperative_snapshots'
      // subcollections across all families.
      final snap = await _firestore
          .collectionGroup(FirestoreCollections.cooperativeSnapshots)
          .where('snapshotDate',
              isGreaterThan: since.toIso8601String())
          .get();

      if (snap.docs.isEmpty) {
        return const AggregatedCoopMetrics(
          familyCount: 0,
          avgParticipationRate: 0.0,
          avgGoalCompletionRate: 0.0,
          avgHouseholdStreak: 0,
          totalChallengesCompleted: 0,
        );
      }

      final snapshots = snap.docs
          .map((d) => CooperativeMechanicSnapshot.fromJson(d.data()))
          .toList();

      final count = snapshots.length;
      final avgParticipation =
          snapshots.fold(0.0, (s, e) => s + e.participationRate) / count;
      final avgCompletion =
          snapshots.fold(0.0, (s, e) => s + e.goalCompletionRate) / count;
      final avgStreak =
          snapshots.fold(0, (s, e) => s + e.householdStreakDays) ~/ count;
      final totalCompleted = snapshots.fold(
          0, (s, e) => s + e.completedCoopChallenges);

      return AggregatedCoopMetrics(
        familyCount: count,
        avgParticipationRate: avgParticipation,
        avgGoalCompletionRate: avgCompletion,
        avgHouseholdStreak: avgStreak,
        totalChallengesCompleted: totalCompleted,
      );
    } catch (e) {
      WasteAppLogger.severe(
          'GamificationAnalytics: getAggregatedMetrics failed', error: e);
      return const AggregatedCoopMetrics(
        familyCount: 0,
        avgParticipationRate: 0.0,
        avgGoalCompletionRate: 0.0,
        avgHouseholdStreak: 0,
        totalChallengesCompleted: 0,
      );
    }
  }
}

/// Internal aggregate result used by the analytics dashboard widget.
class AggregatedCoopMetrics {
  const AggregatedCoopMetrics({
    required this.familyCount,
    required this.avgParticipationRate,
    required this.avgGoalCompletionRate,
    required this.avgHouseholdStreak,
    required this.totalChallengesCompleted,
  });

  final int familyCount;
  final double avgParticipationRate;
  final double avgGoalCompletionRate;
  final int avgHouseholdStreak;
  final int totalChallengesCompleted;
}
