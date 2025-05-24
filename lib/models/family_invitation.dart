import 'user_profile.dart';

/// Status of a family invitation.
enum InvitationStatus {
  /// Invitation has been sent but not yet accepted.
  pending,
  /// Invitation has been accepted by the recipient.
  accepted,
  /// Invitation has been declined by the recipient.
  declined,
  /// Invitation has expired.
  expired,
  /// Invitation has been revoked by the sender.
  revoked,
}

/// Represents an invitation to join a family.
class FamilyInvitation {
  /// The unique identifier for the invitation.
  final String id;

  /// The ID of the family being joined.
  final String familyId;

  /// The user ID of who created the invitation.
  final String createdBy;

  /// The email address of the person being invited.
  final String email;

  /// The role the invitee will have in the family.
  final UserRole role;

  /// When the invitation was created.
  final DateTime createdAt;

  /// When the invitation expires.
  final DateTime expiresAt;

  /// Current status of the invitation.
  final InvitationStatus status;

  /// When the invitation was accepted/declined (if applicable).
  final DateTime? respondedAt;

  /// The user ID of who responded to the invitation (if accepted).
  final String? respondedBy;

  /// Optional message from the inviter.
  final String? message;

  /// Invitation code for quick joining.
  final String inviteCode;

  /// Whether this invitation can be used multiple times.
  final bool isReusable;

  /// How many times this invitation has been used (for reusable invitations).
  final int usageCount;

  /// Maximum number of uses (for reusable invitations).
  final int? maxUses;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    this.status = InvitationStatus.pending,
    this.respondedAt,
    this.respondedBy,
    this.message,
    required this.inviteCode,
    this.isReusable = false,
    this.usageCount = 0,
    this.maxUses,
  });

  /// Creates a copy of this FamilyInvitation with the given fields replaced.
  FamilyInvitation copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? expiresAt,
    InvitationStatus? status,
    DateTime? respondedAt,
    String? respondedBy,
    String? message,
    String? inviteCode,
    bool? isReusable,
    int? usageCount,
    int? maxUses,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      message: message ?? this.message,
      inviteCode: inviteCode ?? this.inviteCode,
      isReusable: isReusable ?? this.isReusable,
      usageCount: usageCount ?? this.usageCount,
      maxUses: maxUses ?? this.maxUses,
    );
  }

  /// Converts this FamilyInvitation instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'createdBy': createdBy,
      'email': email,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'respondedAt': respondedAt?.toIso8601String(),
      'respondedBy': respondedBy,
      'message': message,
      'inviteCode': inviteCode,
      'isReusable': isReusable,
      'usageCount': usageCount,
      'maxUses': maxUses,
    };
  }

  /// Creates a FamilyInvitation instance from a JSON map.
  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyInvitation(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      createdBy: json['createdBy'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.member,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      respondedBy: json['respondedBy'] as String?,
      message: json['message'] as String?,
      inviteCode: json['inviteCode'] as String,
      isReusable: json['isReusable'] as bool? ?? false,
      usageCount: json['usageCount'] as int? ?? 0,
      maxUses: json['maxUses'] as int?,
    );
  }

  /// Checks if the invitation is still valid.
  bool get isValid {
    return status == InvitationStatus.pending && 
           DateTime.now().isBefore(expiresAt) &&
           (!isReusable || maxUses == null || usageCount < maxUses!);
  }

  /// Checks if the invitation has expired.
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt) || 
           status == InvitationStatus.expired;
  }

  /// Checks if the invitation can still be used.
  bool get canBeUsed {
    return isValid && (isReusable || usageCount == 0);
  }

  /// Gets the number of days until expiration.
  int get daysUntilExpiration {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Gets the hours until expiration.
  int get hoursUntilExpiration {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inHours;
  }
}

/// Represents a batch invitation for multiple email addresses.
class BatchInvitation {
  /// The unique identifier for the batch.
  final String id;

  /// The ID of the family being joined.
  final String familyId;

  /// The user ID of who created the batch invitation.
  final String createdBy;

  /// List of email addresses being invited.
  final List<String> emails;

  /// The role all invitees will have in the family.
  final UserRole role;

  /// When the batch invitation was created.
  final DateTime createdAt;

  /// When all invitations in this batch expire.
  final DateTime expiresAt;

  /// Optional message for all invitees.
  final String? message;

  /// Individual invitations created from this batch.
  final List<FamilyInvitation> invitations;

  /// Status summary of the batch.
  final BatchInvitationStatus status;

  BatchInvitation({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.emails,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.invitations = const [],
    required this.status,
  });

  /// Converts this BatchInvitation instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'createdBy': createdBy,
      'emails': emails,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'message': message,
      'invitations': invitations.map((inv) => inv.toJson()).toList(),
      'status': status.toJson(),
    };
  }

  /// Creates a BatchInvitation instance from a JSON map.
  factory BatchInvitation.fromJson(Map<String, dynamic> json) {
    return BatchInvitation(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      createdBy: json['createdBy'] as String,
      emails: List<String>.from(json['emails'] as List),
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.member,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      message: json['message'] as String?,
      invitations: (json['invitations'] as List<dynamic>?)
              ?.map((inv) => FamilyInvitation.fromJson(inv as Map<String, dynamic>))
              .toList() ??
          [],
      status: BatchInvitationStatus.fromJson(json['status'] as Map<String, dynamic>),
    );
  }
}

/// Status summary for a batch invitation.
class BatchInvitationStatus {
  /// Total number of invitations sent.
  final int totalSent;

  /// Number of invitations accepted.
  final int accepted;

  /// Number of invitations declined.
  final int declined;

  /// Number of invitations still pending.
  final int pending;

  /// Number of invitations expired.
  final int expired;

  BatchInvitationStatus({
    required this.totalSent,
    this.accepted = 0,
    this.declined = 0,
    this.pending = 0,
    this.expired = 0,
  });

  /// Converts this BatchInvitationStatus instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalSent': totalSent,
      'accepted': accepted,
      'declined': declined,
      'pending': pending,
      'expired': expired,
    };
  }

  /// Creates a BatchInvitationStatus instance from a JSON map.
  factory BatchInvitationStatus.fromJson(Map<String, dynamic> json) {
    return BatchInvitationStatus(
      totalSent: json['totalSent'] as int,
      accepted: json['accepted'] as int? ?? 0,
      declined: json['declined'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      expired: json['expired'] as int? ?? 0,
    );
  }

  /// Gets the completion percentage (accepted + declined / total).
  double get completionPercentage {
    if (totalSent == 0) return 0.0;
    return (accepted + declined) / totalSent;
  }

  /// Gets the acceptance rate (accepted / total responded).
  double get acceptanceRate {
    final totalResponded = accepted + declined;
    if (totalResponded == 0) return 0.0;
    return accepted / totalResponded;
  }
}
