import 'package:uuid/uuid.dart';

// ============================================================
// Cooperative Mechanics Model
//
// This is the behavioral contract for family/team cooperative features.
// It lives alongside enhanced_family.dart (structural) and supplements
// the v1 gamification system (individual-only) with household-level
// mechanics.
//
// Kill criteria (tracked in FAMILY_COOPERATIVE_MECHANICS.md):
//   - If shared goals do not raise household participation rate in 30 days,
//     simplify to household streak only.
//   - If cooperative challenges do not improve 28-day family retention,
//     remove and redirect to individual challenges with family leaderboard.
// ============================================================

// --------------- Enums ---------------

/// What type of shared goal this is.
enum GoalType {
  /// Fixed number of scans across all household members.
  scanCount,

  /// Fixed number of correct disposals verified by users.
  disposalCount,

  /// Collectively classify items in a specific waste category.
  categoryFocus,

  /// Earn a total number of points across all members.
  pointsTarget,

  /// Complete a set of educational modules.
  educationCompletion,

  /// Custom goal defined by the family admin.
  custom,
}

/// Status of a shared goal.
enum GoalStatus {
  active,
  completed,
  failed,
  cancelled,
}

/// Who a family task is intended for.
enum TaskTargetRole {
  /// Any adult member (admin or regular member).
  anyAdult,

  /// Only the family admin.
  adminOnly,

  /// Child-safe task suitable for minors.
  child,

  /// Any member regardless of role.
  anyMember,

  /// A specific named member (userId stored separately).
  specificMember,
}

/// Status of a family task.
enum TaskStatus {
  pending,
  inProgress,
  completed,
  skipped,
  expired,
}

/// Type of cooperative challenge requiring multiple members.
enum CoopChallengeType {
  /// Every member must scan at least one item per day for N days.
  allMembersDaily,

  /// Combined classifications reach a total target.
  combinedCount,

  /// A relay where one member's completion unlocks the next member's task.
  relay,

  /// A specific category must be covered by different members.
  categoryDiversity,
}

/// Status of a cooperative challenge.
enum CoopChallengeStatus {
  draft,
  active,
  completed,
  failed,
  cancelled,
}

// --------------- Models ---------------

/// A shared goal that every household member contributes toward.
///
/// Goals are additive: each member's actions count toward the shared total.
/// Progress is always visible to all members; individual contribution is
/// opt-in and always shown positively (no shame design).
class FamilyGoal {
  const FamilyGoal({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.createdBy,
    required this.createdAt,
    required this.deadline,
    required this.status,
    this.contributions = const [],
    this.rewardPoints = 0,
    this.iconEmoji = '🎯',
    this.categoryFilter,
  });

  factory FamilyGoal.create({
    required String familyId,
    required String title,
    required String description,
    required GoalType type,
    required int targetValue,
    required String createdBy,
    required DateTime deadline,
    int rewardPoints = 0,
    String iconEmoji = '🎯',
    String? categoryFilter,
  }) {
    return FamilyGoal(
      id: const Uuid().v4(),
      familyId: familyId,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      currentValue: 0,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      deadline: deadline,
      status: GoalStatus.active,
      rewardPoints: rewardPoints,
      iconEmoji: iconEmoji,
      categoryFilter: categoryFilter,
    );
  }

  factory FamilyGoal.fromJson(Map<String, dynamic> json) {
    return FamilyGoal(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.scanCount,
      ),
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      contributions: (json['contributions'] as List<dynamic>? ?? [])
          .map((e) => GoalContribution.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '🎯',
      categoryFilter: json['categoryFilter'] as String?,
    );
  }

  final String id;
  final String familyId;
  final String title;
  final String description;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final String createdBy;
  final DateTime createdAt;
  final DateTime deadline;
  final GoalStatus status;
  final List<GoalContribution> contributions;
  final int rewardPoints;
  final String iconEmoji;

  /// For categoryFocus goals: which waste category to target.
  final String? categoryFilter;

  double get progressFraction =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isExpired =>
      DateTime.now().isAfter(deadline) && status == GoalStatus.active;

  bool get isCompleted => currentValue >= targetValue;

  FamilyGoal copyWith({
    int? currentValue,
    GoalStatus? status,
    List<GoalContribution>? contributions,
  }) {
    return FamilyGoal(
      id: id,
      familyId: familyId,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdBy: createdBy,
      createdAt: createdAt,
      deadline: deadline,
      status: status ?? this.status,
      contributions: contributions ?? this.contributions,
      rewardPoints: rewardPoints,
      iconEmoji: iconEmoji,
      categoryFilter: categoryFilter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'contributions': contributions.map((c) => c.toJson()).toList(),
      'rewardPoints': rewardPoints,
      'iconEmoji': iconEmoji,
      'categoryFilter': categoryFilter,
    };
  }
}

/// A single member's contribution to a shared family goal.
///
/// Stored inside the goal document. userId is always present for deduplication;
/// display is opt-in via showInFeed. This lets us show aggregate progress
/// without shaming non-contributors.
class GoalContribution {
  const GoalContribution({
    required this.userId,
    required this.amount,
    required this.contributedAt,
    this.displayName,
    this.showInFeed = true,
    this.classificationId,
  });

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      userId: json['userId'] as String,
      amount: json['amount'] as int,
      contributedAt: DateTime.parse(json['contributedAt'] as String),
      displayName: json['displayName'] as String?,
      showInFeed: json['showInFeed'] as bool? ?? true,
      classificationId: json['classificationId'] as String?,
    );
  }

  final String userId;
  final int amount;
  final DateTime contributedAt;
  final String? displayName;
  final bool showInFeed;

  /// Optional: link to the classification that generated this contribution.
  final String? classificationId;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'contributedAt': contributedAt.toIso8601String(),
      'displayName': displayName,
      'showInFeed': showInFeed,
      'classificationId': classificationId,
    };
  }
}

/// A role-based task assigned to one or more household members.
///
/// Tasks are designed to match member capability: child-safe tasks for kids,
/// full tasks for adults. Completion is celebrated, not failure.
class FamilyTask {
  const FamilyTask({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.targetRole,
    required this.createdBy,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.assignedTo,
    this.completedBy,
    this.completedAt,
    this.pointsReward = 0,
    this.iconEmoji = '✅',
    this.linkedGoalId,
    this.requiresCategory,
    this.minClassifications = 1,
  });

  factory FamilyTask.create({
    required String familyId,
    required String title,
    required String description,
    required TaskTargetRole targetRole,
    required String createdBy,
    required DateTime dueDate,
    String? assignedTo,
    int pointsReward = 0,
    String iconEmoji = '✅',
    String? linkedGoalId,
    String? requiresCategory,
    int minClassifications = 1,
  }) {
    return FamilyTask(
      id: const Uuid().v4(),
      familyId: familyId,
      title: title,
      description: description,
      targetRole: targetRole,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      status: TaskStatus.pending,
      assignedTo: assignedTo,
      pointsReward: pointsReward,
      iconEmoji: iconEmoji,
      linkedGoalId: linkedGoalId,
      requiresCategory: requiresCategory,
      minClassifications: minClassifications,
    );
  }

  factory FamilyTask.fromJson(Map<String, dynamic> json) {
    return FamilyTask(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetRole: TaskTargetRole.values.firstWhere(
        (e) => e.name == json['targetRole'],
        orElse: () => TaskTargetRole.anyMember,
      ),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      assignedTo: json['assignedTo'] as String?,
      completedBy: json['completedBy'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      pointsReward: json['pointsReward'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '✅',
      linkedGoalId: json['linkedGoalId'] as String?,
      requiresCategory: json['requiresCategory'] as String?,
      minClassifications: json['minClassifications'] as int? ?? 1,
    );
  }

  final String id;
  final String familyId;
  final String title;
  final String description;
  final TaskTargetRole targetRole;
  final String createdBy;
  final DateTime createdAt;
  final DateTime dueDate;
  final TaskStatus status;

  /// Specific userId when targetRole == TaskTargetRole.specificMember.
  final String? assignedTo;
  final String? completedBy;
  final DateTime? completedAt;
  final int pointsReward;
  final String iconEmoji;

  /// If set, completing this task also contributes to the linked goal.
  final String? linkedGoalId;

  /// If set, the task requires classifying items in this waste category.
  final String? requiresCategory;
  final int minClassifications;

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status == TaskStatus.pending;

  FamilyTask copyWith({
    TaskStatus? status,
    String? completedBy,
    DateTime? completedAt,
  }) {
    return FamilyTask(
      id: id,
      familyId: familyId,
      title: title,
      description: description,
      targetRole: targetRole,
      createdBy: createdBy,
      createdAt: createdAt,
      dueDate: dueDate,
      status: status ?? this.status,
      assignedTo: assignedTo,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      pointsReward: pointsReward,
      iconEmoji: iconEmoji,
      linkedGoalId: linkedGoalId,
      requiresCategory: requiresCategory,
      minClassifications: minClassifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'targetRole': targetRole.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'completedAt': completedAt?.toIso8601String(),
      'pointsReward': pointsReward,
      'iconEmoji': iconEmoji,
      'linkedGoalId': linkedGoalId,
      'requiresCategory': requiresCategory,
      'minClassifications': minClassifications,
    };
  }
}

/// Household-level streak: maintained when ANY member contributes on a given day.
///
/// This is the no-shame version of the individual streak. If one person scans
/// today, the whole household streak stays alive. This reduces anxiety pressure
/// on individual members while still rewarding consistent household engagement.
class HouseholdStreak {
  const HouseholdStreak({
    required this.familyId,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastActiveDate,
    required this.updatedAt,
    this.contributorToday = const [],
    this.streakStartDate,
  });

  factory HouseholdStreak.initial(String familyId) {
    final now = DateTime.now();
    return HouseholdStreak(
      familyId: familyId,
      currentStreak: 0,
      bestStreak: 0,
      lastActiveDate: DateTime(now.year, now.month, now.day),
      updatedAt: now,
    );
  }

  factory HouseholdStreak.fromJson(Map<String, dynamic> json) {
    return HouseholdStreak(
      familyId: json['familyId'] as String,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      contributorToday: (json['contributorToday'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      streakStartDate: json['streakStartDate'] != null
          ? DateTime.parse(json['streakStartDate'] as String)
          : null,
    );
  }

  final String familyId;
  final int currentStreak;
  final int bestStreak;

  /// The most recent day the household was active (date only, no time).
  final DateTime lastActiveDate;
  final DateTime updatedAt;

  /// UserIds who have contributed today. Reset daily.
  final List<String> contributorToday;

  /// When the current streak began.
  final DateTime? streakStartDate;

  bool get isActiveToday {
    final today = DateTime.now();
    return lastActiveDate.year == today.year &&
        lastActiveDate.month == today.month &&
        lastActiveDate.day == today.day;
  }

  HouseholdStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastActiveDate,
    DateTime? updatedAt,
    List<String>? contributorToday,
    DateTime? streakStartDate,
  }) {
    return HouseholdStreak(
      familyId: familyId,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      updatedAt: updatedAt ?? this.updatedAt,
      contributorToday: contributorToday ?? this.contributorToday,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familyId': familyId,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'contributorToday': contributorToday,
      'streakStartDate': streakStartDate?.toIso8601String(),
    };
  }
}

/// A challenge that requires multiple household members to complete together.
///
/// Each member has their own progress tracked independently but the challenge
/// succeeds or fails as a household unit.
class CooperativeChallenge {
  const CooperativeChallenge({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.createdBy,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.memberProgress = const [],
    this.minParticipants = 2,
    this.rewardPoints = 0,
    this.iconEmoji = '🤝',
    this.linkedGoalId,
  });

  factory CooperativeChallenge.create({
    required String familyId,
    required String title,
    required String description,
    required CoopChallengeType type,
    required int targetValue,
    required String createdBy,
    required DateTime startDate,
    required DateTime endDate,
    int minParticipants = 2,
    int rewardPoints = 0,
    String iconEmoji = '🤝',
    String? linkedGoalId,
  }) {
    return CooperativeChallenge(
      id: const Uuid().v4(),
      familyId: familyId,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      status: CoopChallengeStatus.active,
      minParticipants: minParticipants,
      rewardPoints: rewardPoints,
      iconEmoji: iconEmoji,
      linkedGoalId: linkedGoalId,
    );
  }

  factory CooperativeChallenge.fromJson(Map<String, dynamic> json) {
    return CooperativeChallenge(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: CoopChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CoopChallengeType.combinedCount,
      ),
      targetValue: json['targetValue'] as int,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: CoopChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CoopChallengeStatus.active,
      ),
      memberProgress: (json['memberProgress'] as List<dynamic>? ?? [])
          .map((e) =>
              MemberChallengeProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      minParticipants: json['minParticipants'] as int? ?? 2,
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '🤝',
      linkedGoalId: json['linkedGoalId'] as String?,
    );
  }

  final String id;
  final String familyId;
  final String title;
  final String description;
  final CoopChallengeType type;
  final int targetValue;
  final String createdBy;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final CoopChallengeStatus status;
  final List<MemberChallengeProgress> memberProgress;
  final int minParticipants;
  final int rewardPoints;
  final String iconEmoji;
  final String? linkedGoalId;

  int get totalProgress =>
      memberProgress.fold(0, (sum, p) => sum + p.currentValue);

  double get progressFraction =>
      targetValue > 0 ? (totalProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  int get participantCount => memberProgress.length;

  bool get hasMinParticipants => participantCount >= minParticipants;

  CooperativeChallenge copyWith({
    CoopChallengeStatus? status,
    List<MemberChallengeProgress>? memberProgress,
  }) {
    return CooperativeChallenge(
      id: id,
      familyId: familyId,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      createdBy: createdBy,
      createdAt: createdAt,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
      memberProgress: memberProgress ?? this.memberProgress,
      minParticipants: minParticipants,
      rewardPoints: rewardPoints,
      iconEmoji: iconEmoji,
      linkedGoalId: linkedGoalId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'memberProgress': memberProgress.map((p) => p.toJson()).toList(),
      'minParticipants': minParticipants,
      'rewardPoints': rewardPoints,
      'iconEmoji': iconEmoji,
      'linkedGoalId': linkedGoalId,
    };
  }
}

/// Per-member progress within a cooperative challenge.
class MemberChallengeProgress {
  const MemberChallengeProgress({
    required this.userId,
    required this.currentValue,
    required this.joinedAt,
    this.displayName,
    this.lastContributedAt,
  });

  factory MemberChallengeProgress.fromJson(Map<String, dynamic> json) {
    return MemberChallengeProgress(
      userId: json['userId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      displayName: json['displayName'] as String?,
      lastContributedAt: json['lastContributedAt'] != null
          ? DateTime.parse(json['lastContributedAt'] as String)
          : null,
    );
  }

  final String userId;
  final int currentValue;
  final DateTime joinedAt;
  final String? displayName;
  final DateTime? lastContributedAt;

  MemberChallengeProgress copyWith({int? currentValue, DateTime? lastContributedAt}) {
    return MemberChallengeProgress(
      userId: userId,
      currentValue: currentValue ?? this.currentValue,
      joinedAt: joinedAt,
      displayName: displayName,
      lastContributedAt: lastContributedAt ?? this.lastContributedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentValue': currentValue,
      'joinedAt': joinedAt.toIso8601String(),
      'displayName': displayName,
      'lastContributedAt': lastContributedAt?.toIso8601String(),
    };
  }
}

/// A paired mission for an adult and a child to complete together.
///
/// The adult role and child role each have their own task; the mission
/// succeeds only when both complete their part. Designed to create shared
/// moments and reinforce learning between generations.
class ParentChildMission {
  const ParentChildMission({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.adultTask,
    required this.childTask,
    required this.createdBy,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.adultUserId,
    this.childUserId,
    this.rewardPoints = 0,
    this.bonusPoints = 0,
    this.iconEmoji = '👨‍👧',
  });

  factory ParentChildMission.create({
    required String familyId,
    required String title,
    required String description,
    required String adultTask,
    required String childTask,
    required String createdBy,
    required DateTime dueDate,
    String? adultUserId,
    String? childUserId,
    int rewardPoints = 0,
    int bonusPoints = 0,
    String iconEmoji = '👨‍👧',
  }) {
    return ParentChildMission(
      id: const Uuid().v4(),
      familyId: familyId,
      title: title,
      description: description,
      adultTask: adultTask,
      childTask: childTask,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      status: MissionStatus.active,
      adultUserId: adultUserId,
      childUserId: childUserId,
      rewardPoints: rewardPoints,
      bonusPoints: bonusPoints,
      iconEmoji: iconEmoji,
    );
  }

  factory ParentChildMission.fromJson(Map<String, dynamic> json) {
    return ParentChildMission(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      adultTask: json['adultTask'] as String,
      childTask: json['childTask'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: MissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MissionStatus.active,
      ),
      adultUserId: json['adultUserId'] as String?,
      childUserId: json['childUserId'] as String?,
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      bonusPoints: json['bonusPoints'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '👨‍👧',
    );
  }

  final String id;
  final String familyId;
  final String title;
  final String description;

  /// What the adult member needs to do.
  final String adultTask;

  /// What the child member needs to do (simplified, age-appropriate).
  final String childTask;

  final String createdBy;
  final DateTime createdAt;
  final DateTime dueDate;
  final MissionStatus status;
  final String? adultUserId;
  final String? childUserId;

  /// Base reward when both complete their part.
  final int rewardPoints;

  /// Bonus on top of rewardPoints for completing within the time window.
  final int bonusPoints;
  final String iconEmoji;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'adultTask': adultTask,
      'childTask': childTask,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'adultUserId': adultUserId,
      'childUserId': childUserId,
      'rewardPoints': rewardPoints,
      'bonusPoints': bonusPoints,
      'iconEmoji': iconEmoji,
    };
  }
}

enum MissionStatus { active, completed, failed, cancelled }

// --------------- Analytics Snapshot ---------------

/// Mechanic-level engagement snapshot for one family.
///
/// This is what the gamification analytics dashboard reads to decide
/// whether cooperative mechanics are worth keeping.
class CooperativeMechanicSnapshot {
  const CooperativeMechanicSnapshot({
    required this.familyId,
    required this.snapshotDate,
    required this.activeGoalCount,
    required this.completedGoalCount,
    required this.activeTaskCount,
    required this.completedTaskCount,
    required this.householdStreakDays,
    required this.activeCoopChallenges,
    required this.completedCoopChallenges,
    required this.participationRate,
    required this.nonPrimaryUserReturnCount,
    this.challengeJoinCount = 0,
    this.goalCompletionRate = 0.0,
  });

  factory CooperativeMechanicSnapshot.fromJson(Map<String, dynamic> json) {
    return CooperativeMechanicSnapshot(
      familyId: json['familyId'] as String,
      snapshotDate: DateTime.parse(json['snapshotDate'] as String),
      activeGoalCount: json['activeGoalCount'] as int? ?? 0,
      completedGoalCount: json['completedGoalCount'] as int? ?? 0,
      activeTaskCount: json['activeTaskCount'] as int? ?? 0,
      completedTaskCount: json['completedTaskCount'] as int? ?? 0,
      householdStreakDays: json['householdStreakDays'] as int? ?? 0,
      activeCoopChallenges: json['activeCoopChallenges'] as int? ?? 0,
      completedCoopChallenges: json['completedCoopChallenges'] as int? ?? 0,
      participationRate: (json['participationRate'] as num?)?.toDouble() ?? 0.0,
      nonPrimaryUserReturnCount:
          json['nonPrimaryUserReturnCount'] as int? ?? 0,
      challengeJoinCount: json['challengeJoinCount'] as int? ?? 0,
      goalCompletionRate:
          (json['goalCompletionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String familyId;
  final DateTime snapshotDate;
  final int activeGoalCount;
  final int completedGoalCount;
  final int activeTaskCount;
  final int completedTaskCount;
  final int householdStreakDays;
  final int activeCoopChallenges;
  final int completedCoopChallenges;

  /// Fraction of household members active in the last 7 days (0.0–1.0).
  final double participationRate;

  /// How many times non-primary members returned in the last 7 days.
  final int nonPrimaryUserReturnCount;
  final int challengeJoinCount;

  /// Completed / (completed + failed + active-expired).
  final double goalCompletionRate;

  Map<String, dynamic> toJson() {
    return {
      'familyId': familyId,
      'snapshotDate': snapshotDate.toIso8601String(),
      'activeGoalCount': activeGoalCount,
      'completedGoalCount': completedGoalCount,
      'activeTaskCount': activeTaskCount,
      'completedTaskCount': completedTaskCount,
      'householdStreakDays': householdStreakDays,
      'activeCoopChallenges': activeCoopChallenges,
      'completedCoopChallenges': completedCoopChallenges,
      'participationRate': participationRate,
      'nonPrimaryUserReturnCount': nonPrimaryUserReturnCount,
      'challengeJoinCount': challengeJoinCount,
      'goalCompletionRate': goalCompletionRate,
    };
  }
}
