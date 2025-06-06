import 'package:uuid/uuid.dart';
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
  /// Invitation has been cancelled by the inviter.
  cancelled,
}

/// How an invitation was sent.
enum InvitationMethod {
  /// Invitation sent directly via email.
  email,

  /// Invitation generated as a shareable link or QR code.
  qr,
}

/// Represents an invitation to join a family.
class FamilyInvitation {

  FamilyInvitation({
    String? id,
    required this.familyId,
    required this.familyName,
    required this.inviterUserId,
    this.inviterName,
    required this.invitedEmail,
    this.invitedUserId,
    this.status = InvitationStatus.pending,
    this.roleToAssign = UserRole.member,
    this.method = InvitationMethod.email,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.respondedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? (createdAt ?? DateTime.now()).add(const Duration(days: 7));

  /// Creates a FamilyInvitation instance from a JSON map.
  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyInvitation(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      familyName: json['familyName'] as String? ?? 'Unknown Family',
      inviterUserId: json['inviterUserId'] as String,
      inviterName: json['inviterName'] as String?,
      invitedEmail: json['invitedEmail'] as String,
      invitedUserId: json['invitedUserId'] as String?,
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      method: InvitationMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (json['method'] ?? 'email'),
        orElse: () => InvitationMethod.email,
      ),
      roleToAssign: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['roleToAssign'],
        orElse: () => UserRole.member,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }
  /// The unique identifier for the invitation.
  final String id;

  /// The ID of the family being joined.
  final String familyId;

  /// The name of the family being joined.
  final String familyName;

  /// The user ID of who created the invitation.
  final String inviterUserId;

  /// The name of the inviter.
  final String? inviterName;

  /// The email address of the person being invited.
  final String invitedEmail;

  /// The user ID of the invited person (if they accept).
  String? invitedUserId;

  /// How the invitation was sent.
  final InvitationMethod method;

  /// Current status of the invitation.
  InvitationStatus status;

  /// The role the invitee will have in the family.
  final UserRole roleToAssign;

  /// When the invitation was created.
  final DateTime createdAt;

  /// When the invitation expires.
  final DateTime expiresAt;

  /// When the invitation was accepted/declined (if applicable).
  DateTime? respondedAt;

  /// Creates a copy of this FamilyInvitation with the given fields replaced.
  FamilyInvitation copyWith({
    String? id,
    String? familyId,
    String? familyName,
    String? inviterUserId,
    String? inviterName,
    String? invitedEmail,
    String? invitedUserId,
    InvitationStatus? status,
    UserRole? roleToAssign,
    InvitationMethod? method,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    bool? clearRespondedAt, // Special flag to nullify respondedAt
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      inviterName: inviterName ?? this.inviterName,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      status: status ?? this.status,
      roleToAssign: roleToAssign ?? this.roleToAssign,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: clearRespondedAt == true ? null : (respondedAt ?? this.respondedAt),
    );
  }

  /// Converts this FamilyInvitation instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'familyName': familyName,
      'inviterUserId': inviterUserId,
      'inviterName': inviterName,
      'invitedEmail': invitedEmail,
      'invitedUserId': invitedUserId,
      'status': status.toString().split('.').last,
      'method': method.toString().split('.').last,
      'roleToAssign': roleToAssign.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  /// Checks if the invitation is still valid.
  bool get isValid {
    return status == InvitationStatus.pending && 
           DateTime.now().isBefore(expiresAt) &&
           (invitedUserId == null || invitedUserId!.isNotEmpty);
  }

  /// Checks if the invitation has expired.
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt) && status == InvitationStatus.pending;
  }

  /// Checks if the invitation can still be used.
  bool get canBeUsed {
    return isValid && (invitedUserId == null || invitedUserId!.isNotEmpty);
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

  String get displayStatus {
    switch (status) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.declined:
        return 'Declined';
      case InvitationStatus.expired:
        return 'Expired';
      case InvitationStatus.revoked:
        return 'Revoked';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FamilyInvitation &&
        other.id == id &&
        other.familyId == familyId &&
        other.familyName == familyName &&
        other.inviterUserId == inviterUserId &&
        other.inviterName == inviterName &&
        other.invitedEmail == invitedEmail &&
        other.invitedUserId == invitedUserId &&
        other.method == method &&
        other.status == status &&
        other.roleToAssign == roleToAssign &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.respondedAt == respondedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        familyId.hashCode ^
        familyName.hashCode ^
        inviterUserId.hashCode ^
        inviterName.hashCode ^
        invitedEmail.hashCode ^
        invitedUserId.hashCode ^
        method.hashCode ^
        status.hashCode ^
        roleToAssign.hashCode ^
        createdAt.hashCode ^
        expiresAt.hashCode ^
        respondedAt.hashCode;
  }
}

/// Represents a batch invitation for multiple email addresses.
class BatchInvitation {

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
}

/// Status summary for a batch invitation.
class BatchInvitationStatus {

  BatchInvitationStatus({
    required this.totalSent,
    this.accepted = 0,
    this.declined = 0,
    this.pending = 0,
    this.expired = 0,
  });

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
