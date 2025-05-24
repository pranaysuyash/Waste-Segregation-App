/// Defines the roles a user can have within a family or team.
enum UserRole {
  /// Can manage family settings and members.
  admin,
  /// Regular family member with standard permissions.
  member,
  /// Limited permissions, typically for younger family members.
  child,
  /// Temporary access, potentially for guests or trial users within a family context.
  guest
}

/// Represents a user's profile information.
///
/// This model stores core user details and information related to their
/// family/team membership and role.
class UserProfile {
  /// The unique identifier for the user, typically from the authentication provider.
  final String id;

  /// The user's display name.
  final String? displayName;

  /// The user's email address.
  final String? email;

  /// The URL of the user's profile photo.
  final String? photoUrl;

  /// The ID of the family or team this user belongs to, if any.
  final String? familyId;

  /// The user's role within their family or team.
  final UserRole? role;
  
  /// Timestamp of when the user profile was created.
  final DateTime? createdAt;

  /// Timestamp of the user's last activity.
  final DateTime? lastActive;
  
  /// User-specific preferences.
  final Map<String, dynamic>? preferences;


  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.familyId,
    this.role,
    this.createdAt,
    this.lastActive,
    this.preferences,
  });

  /// Creates a copy of this UserProfile but with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? familyId,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Converts this UserProfile instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'familyId': familyId,
      'role': role?.toString().split('.').last, // Store enum as string
      'createdAt': createdAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'preferences': preferences,
    };
  }

  /// Creates a UserProfile instance from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      familyId: json['familyId'] as String?,
      role: json['role'] != null
          ? UserRole.values.firstWhere(
              (e) => e.toString().split('.').last == json['role'],
              orElse: () => UserRole.guest, // Default if string doesn't match
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
} 