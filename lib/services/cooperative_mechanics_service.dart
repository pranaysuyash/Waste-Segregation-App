import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cooperative_mechanics.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

/// Service for all cooperative-mechanics operations.
///
/// Owns shared goals, role-based tasks, household streaks, cooperative
/// challenges, and parent-child missions. All writes go through the
/// FirestoreCollections registry so collection names stay consistent.
///
/// Design notes:
///   - Subcollections live under families/{familyId}/ to keep Firestore
///     rules inheritance simple.
///   - Snapshot generation is cheap: called after each write that changes
///     participationRate-relevant state.
///   - No caching layer here — callers that need reactive state should use
///     the stream variants and maintain local state in their providers/screens.
class CooperativeMechanicsService {
  CooperativeMechanicsService({FirebaseFirestore? firestore})
      : _explicitFirestore = firestore;

  final FirebaseFirestore? _explicitFirestore;

  // Lazy so that tests injecting subclasses don't trigger Firebase.instance
  // at construction time (mirrors FirebaseFamilyService's pattern).
  late final FirebaseFirestore _firestore =
      _explicitFirestore ?? FirebaseFirestore.instance;

  // ── Subcollection helpers ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _goalsCol(String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.familyGoals);

  CollectionReference<Map<String, dynamic>> _tasksCol(String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.familyTasks);

  DocumentReference<Map<String, dynamic>> _streakDoc(String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.householdStreaks)
          .doc('current');

  CollectionReference<Map<String, dynamic>> _coopChallengesCol(
          String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.cooperativeChallenges);

  CollectionReference<Map<String, dynamic>> _missionsCol(String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.parentChildMissions);

  CollectionReference<Map<String, dynamic>> _snapshotsCol(String familyId) =>
      _firestore
          .collection(FirestoreCollections.families)
          .doc(familyId)
          .collection(FirestoreCollections.cooperativeSnapshots);

  // ── Shared Goals ──────────────────────────────────────────────────────────

  Future<FamilyGoal> createGoal(FamilyGoal goal) async {
    try {
      await _goalsCol(goal.familyId).doc(goal.id).set(goal.toJson());
      WasteAppLogger.info('CoopMechanics: created goal ${goal.id}');
      return goal;
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: createGoal failed', error: e);
      rethrow;
    }
  }

  Future<FamilyGoal?> getGoal(String familyId, String goalId) async {
    try {
      final doc = await _goalsCol(familyId).doc(goalId).get();
      if (!doc.exists || doc.data() == null) return null;
      return FamilyGoal.fromJson(doc.data()!);
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: getGoal failed', error: e);
      return null;
    }
  }

  Stream<List<FamilyGoal>> watchActiveGoals(String familyId) {
    return _goalsCol(familyId)
        .where('status', isEqualTo: GoalStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FamilyGoal.fromJson(d.data()))
            .toList());
  }

  /// Records one member's contribution to a shared goal and updates totals.
  ///
  /// Uses a Firestore transaction to ensure currentValue stays accurate
  /// under concurrent writes from multiple household members.
  Future<void> contributeToGoal({
    required String familyId,
    required String goalId,
    required GoalContribution contribution,
  }) async {
    final goalRef = _goalsCol(familyId).doc(goalId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(goalRef);
        if (!snap.exists || snap.data() == null) return;

        final goal = FamilyGoal.fromJson(snap.data()!);
        if (goal.status != GoalStatus.active) return;

        final updatedContributions = [...goal.contributions, contribution];
        final newValue = goal.currentValue + contribution.amount;
        final newStatus = newValue >= goal.targetValue
            ? GoalStatus.completed
            : GoalStatus.active;

        txn.update(goalRef, {
          'currentValue': newValue,
          'status': newStatus.name,
          'contributions': updatedContributions.map((c) => c.toJson()).toList(),
        });
      });
      WasteAppLogger.info(
          'CoopMechanics: contribution recorded for goal $goalId');
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: contributeToGoal failed', error: e);
      rethrow;
    }
  }

  Future<void> cancelGoal(String familyId, String goalId) async {
    try {
      await _goalsCol(familyId)
          .doc(goalId)
          .update({'status': GoalStatus.cancelled.name});
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: cancelGoal failed', error: e);
      rethrow;
    }
  }

  // ── Role-Based Tasks ───────────────────────────────────────────────────────

  Future<FamilyTask> createTask(FamilyTask task) async {
    try {
      await _tasksCol(task.familyId).doc(task.id).set(task.toJson());
      WasteAppLogger.info('CoopMechanics: created task ${task.id}');
      return task;
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: createTask failed', error: e);
      rethrow;
    }
  }

  Stream<List<FamilyTask>> watchPendingTasks(String familyId) {
    return _tasksCol(familyId)
        .where('status', whereIn: [
          TaskStatus.pending.name,
          TaskStatus.inProgress.name,
        ])
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FamilyTask.fromJson(d.data())).toList());
  }

  /// Marks a task completed by the given user.
  ///
  /// If the task is linked to a goal, automatically records a contribution.
  Future<void> completeTask({
    required String familyId,
    required String taskId,
    required String completedByUserId,
    String? completedByDisplayName,
  }) async {
    final taskRef = _tasksCol(familyId).doc(taskId);
    try {
      final snap = await taskRef.get();
      if (!snap.exists || snap.data() == null) return;

      final task = FamilyTask.fromJson(snap.data()!);
      final now = DateTime.now();

      await taskRef.update({
        'status': TaskStatus.completed.name,
        'completedBy': completedByUserId,
        'completedAt': now.toIso8601String(),
      });

      // If task is linked to a goal, add a contribution automatically.
      if (task.linkedGoalId != null) {
        final contribution = GoalContribution(
          userId: completedByUserId,
          amount: task.minClassifications,
          contributedAt: now,
          displayName: completedByDisplayName,
        );
        await contributeToGoal(
          familyId: familyId,
          goalId: task.linkedGoalId!,
          contribution: contribution,
        );
      }

      WasteAppLogger.info('CoopMechanics: task $taskId completed');
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: completeTask failed', error: e);
      rethrow;
    }
  }

  // ── Household Streak ───────────────────────────────────────────────────────

  Future<HouseholdStreak> getOrInitStreak(String familyId) async {
    try {
      final doc = await _streakDoc(familyId).get();
      if (doc.exists && doc.data() != null) {
        return HouseholdStreak.fromJson(doc.data()!);
      }
      final initial = HouseholdStreak.initial(familyId);
      await _streakDoc(familyId).set(initial.toJson());
      return initial;
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: getOrInitStreak failed', error: e);
      return HouseholdStreak.initial(familyId);
    }
  }

  Stream<HouseholdStreak?> watchStreak(String familyId) {
    return _streakDoc(familyId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HouseholdStreak.fromJson(snap.data()!);
    });
  }

  /// Records that a member was active today, advancing the streak if needed.
  ///
  /// The household streak increments once per calendar day regardless of
  /// how many members contribute. If the last active date was more than
  /// 1 day ago, the streak resets to 1.
  Future<HouseholdStreak> recordMemberActivity({
    required String familyId,
    required String userId,
  }) async {
    final ref = _streakDoc(familyId);
    try {
      return await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final existing = snap.exists && snap.data() != null
            ? HouseholdStreak.fromJson(snap.data()!)
            : HouseholdStreak.initial(familyId);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final last = existing.lastActiveDate;
        final lastDay = DateTime(last.year, last.month, last.day);

        // Already counted today — just add contributor.
        if (lastDay == today) {
          if (existing.contributorToday.contains(userId)) {
            return existing;
          }
          final updated = existing.copyWith(
            contributorToday: [...existing.contributorToday, userId],
            updatedAt: now,
          );
          txn.set(ref, updated.toJson());
          return updated;
        }

        final daysDiff = today.difference(lastDay).inDays;
        final newStreak = daysDiff == 1 ? existing.currentStreak + 1 : 1;
        final newBest =
            newStreak > existing.bestStreak ? newStreak : existing.bestStreak;

        final updated = existing.copyWith(
          currentStreak: newStreak,
          bestStreak: newBest,
          lastActiveDate: today,
          updatedAt: now,
          contributorToday: [userId],
          streakStartDate: daysDiff == 1
              ? (existing.streakStartDate ?? today)
              : today,
        );
        txn.set(ref, updated.toJson());
        return updated;
      });
    } catch (e) {
      WasteAppLogger.severe(
          'CoopMechanics: recordMemberActivity failed', error: e);
      return HouseholdStreak.initial(familyId);
    }
  }

  // ── Cooperative Challenges ─────────────────────────────────────────────────

  Future<CooperativeChallenge> createCoopChallenge(
      CooperativeChallenge challenge) async {
    try {
      await _coopChallengesCol(challenge.familyId)
          .doc(challenge.id)
          .set(challenge.toJson());
      WasteAppLogger.info('CoopMechanics: created challenge ${challenge.id}');
      return challenge;
    } catch (e) {
      WasteAppLogger.severe(
          'CoopMechanics: createCoopChallenge failed', error: e);
      rethrow;
    }
  }

  Stream<List<CooperativeChallenge>> watchActiveChallenges(String familyId) {
    return _coopChallengesCol(familyId)
        .where('status', isEqualTo: CoopChallengeStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CooperativeChallenge.fromJson(d.data()))
            .toList());
  }

  /// Joins a cooperative challenge: adds the member to memberProgress if not
  /// already present.
  Future<void> joinChallenge({
    required String familyId,
    required String challengeId,
    required String userId,
    String? displayName,
  }) async {
    final ref = _coopChallengesCol(familyId).doc(challengeId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists || snap.data() == null) return;

        final challenge = CooperativeChallenge.fromJson(snap.data()!);
        if (challenge.memberProgress.any((p) => p.userId == userId)) return;

        final updated = challenge.copyWith(
          memberProgress: [
            ...challenge.memberProgress,
            MemberChallengeProgress(
              userId: userId,
              currentValue: 0,
              joinedAt: DateTime.now(),
              displayName: displayName,
            ),
          ],
        );
        txn.update(ref, {'memberProgress': updated.memberProgress
            .map((p) => p.toJson())
            .toList()});
      });
      WasteAppLogger.info(
          'CoopMechanics: user $userId joined challenge $challengeId');
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: joinChallenge failed', error: e);
      rethrow;
    }
  }

  /// Records progress for one member in a cooperative challenge.
  Future<void> recordChallengeProgress({
    required String familyId,
    required String challengeId,
    required String userId,
    required int amount,
  }) async {
    final ref = _coopChallengesCol(familyId).doc(challengeId);
    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists || snap.data() == null) return;

        final challenge = CooperativeChallenge.fromJson(snap.data()!);
        if (challenge.status != CoopChallengeStatus.active) return;

        final now = DateTime.now();
        final updatedProgress = challenge.memberProgress.map((p) {
          if (p.userId != userId) return p;
          return p.copyWith(
            currentValue: p.currentValue + amount,
            lastContributedAt: now,
          );
        }).toList();

        final updatedChallenge = challenge.copyWith(
          memberProgress: updatedProgress,
        );

        var newStatus = CoopChallengeStatus.active;
        if (updatedChallenge.totalProgress >= challenge.targetValue) {
          newStatus = CoopChallengeStatus.completed;
        }

        txn.update(ref, {
          'memberProgress':
              updatedProgress.map((p) => p.toJson()).toList(),
          'status': newStatus.name,
        });
      });
    } catch (e) {
      WasteAppLogger.severe(
          'CoopMechanics: recordChallengeProgress failed', error: e);
      rethrow;
    }
  }

  // ── Parent-Child Missions ──────────────────────────────────────────────────

  Future<ParentChildMission> createMission(ParentChildMission mission) async {
    try {
      await _missionsCol(mission.familyId).doc(mission.id).set(mission.toJson());
      WasteAppLogger.info('CoopMechanics: created mission ${mission.id}');
      return mission;
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: createMission failed', error: e);
      rethrow;
    }
  }

  Stream<List<ParentChildMission>> watchActiveMissions(String familyId) {
    return _missionsCol(familyId)
        .where('status', isEqualTo: MissionStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ParentChildMission.fromJson(d.data()))
            .toList());
  }

  Future<void> completeMission(String familyId, String missionId) async {
    try {
      await _missionsCol(familyId)
          .doc(missionId)
          .update({'status': MissionStatus.completed.name});
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: completeMission failed', error: e);
      rethrow;
    }
  }

  // ── Analytics Snapshot ─────────────────────────────────────────────────────

  /// Writes a mechanic-level snapshot for external analytics.
  ///
  /// Call this after any write that changes participationRate-relevant state.
  /// The snapshot collection is cheap to read from the analytics dashboard
  /// without re-aggregating live subcollections.
  Future<void> writeSnapshot(CooperativeMechanicSnapshot snapshot) async {
    try {
      await _snapshotsCol(snapshot.familyId)
          .doc(snapshot.snapshotDate.toIso8601String().split('T').first)
          .set(snapshot.toJson());
    } catch (e) {
      // Snapshot failures are non-fatal: log and continue.
      WasteAppLogger.warning(
          'CoopMechanics: snapshot write failed (non-fatal): $e');
    }
  }

  /// Fetches the last N snapshots for a family, newest first.
  Future<List<CooperativeMechanicSnapshot>> getRecentSnapshots(
      String familyId, {int limit = 30}) async {
    try {
      final query = await _snapshotsCol(familyId)
          .orderBy('snapshotDate', descending: true)
          .limit(limit)
          .get();
      return query.docs
          .map((d) => CooperativeMechanicSnapshot.fromJson(d.data()))
          .toList();
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: getRecentSnapshots failed',
          error: e);
      return [];
    }
  }

  /// Builds a snapshot by querying live subcollection counts.
  ///
  /// Intended to be called after significant state changes (goal completed,
  /// challenge joined, etc.). Not for high-frequency calls.
  Future<CooperativeMechanicSnapshot> buildSnapshot({
    required String familyId,
    required int totalMembers,
    required int activeLastWeek,
    required int nonPrimaryReturns,
  }) async {
    try {
      final goalSnap = await _goalsCol(familyId).get();
      final taskSnap = await _tasksCol(familyId).get();
      final challengeSnap = await _coopChallengesCol(familyId).get();
      final streakDoc = await _streakDoc(familyId).get();

      final goals = goalSnap.docs.map((d) => FamilyGoal.fromJson(d.data()));
      final activeGoals =
          goals.where((g) => g.status == GoalStatus.active).length;
      final completedGoals =
          goals.where((g) => g.status == GoalStatus.completed).length;
      final totalFinishedGoals =
          goals.where((g) => g.status != GoalStatus.active).length;
      final completionRate = totalFinishedGoals > 0
          ? completedGoals / totalFinishedGoals
          : 0.0;

      final tasks = taskSnap.docs.map((d) => FamilyTask.fromJson(d.data()));
      final activeTasks = tasks
          .where((t) =>
              t.status == TaskStatus.pending ||
              t.status == TaskStatus.inProgress)
          .length;
      final completedTasks =
          tasks.where((t) => t.status == TaskStatus.completed).length;

      final challenges = challengeSnap.docs
          .map((d) => CooperativeChallenge.fromJson(d.data()));
      final activeChallenges = challenges
          .where((c) => c.status == CoopChallengeStatus.active)
          .length;
      final completedChallenges = challenges
          .where((c) => c.status == CoopChallengeStatus.completed)
          .length;

      var streakDays = 0;
      if (streakDoc.exists && streakDoc.data() != null) {
        streakDays =
            HouseholdStreak.fromJson(streakDoc.data()!).currentStreak;
      }

      final participationRate =
          totalMembers > 0 ? activeLastWeek / totalMembers : 0.0;

      final snapshot = CooperativeMechanicSnapshot(
        familyId: familyId,
        snapshotDate: DateTime.now(),
        activeGoalCount: activeGoals,
        completedGoalCount: completedGoals,
        activeTaskCount: activeTasks,
        completedTaskCount: completedTasks,
        householdStreakDays: streakDays,
        activeCoopChallenges: activeChallenges,
        completedCoopChallenges: completedChallenges,
        participationRate: participationRate.clamp(0.0, 1.0),
        nonPrimaryUserReturnCount: nonPrimaryReturns,
        goalCompletionRate: completionRate.clamp(0.0, 1.0),
      );

      await writeSnapshot(snapshot);
      return snapshot;
    } catch (e) {
      WasteAppLogger.severe('CoopMechanics: buildSnapshot failed', error: e);
      rethrow;
    }
  }
}
