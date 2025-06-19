import './gamification.dart';
import './token_wallet.dart';
import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Defines the roles a user can have within a family or team.
@HiveType(typeId: 3)
enum UserRole {
  /// Can manage family settings and members.
  @HiveField(0)
  admin,
  /// Regular family member with standard permissions.
  @HiveField(1)
  member,
  /// Limited permissions, typically for younger family members.
  @HiveField(2)
  child,
  /// Temporary access, potentially for guests or trial users within a family context.
  @HiveField(3)
  guest
}

/// Represents a user's profile information.
///
/// This model stores core user details and information related to their
/// family/team membership and role.
@HiveType(typeId: 4)
class UserProfile {


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
    this.gamificationProfile,
    this.tokenWallet,
    this.tokenTransactions,
  });

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
      gamificationProfile: json['gamificationProfile'] != null
          ? GamificationProfile.fromJson(json['gamificationProfile'] as Map<String, dynamic>)
          : null,
      tokenWallet: json['tokenWallet'] != null
          ? TokenWallet.fromJson(json['tokenWallet'] as Map<String, dynamic>)
          : null,
      tokenTransactions: json['tokenTransactions'] != null
          ? (json['tokenTransactions'] as List)
              .map((e) => TokenTransaction.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
  /// The unique identifier for the user, typically from the authentication provider.
  @HiveField(0)
  final String id;

  /// The user's display name.
  @HiveField(1)
  final String? displayName;

  /// The user's email address.
  @HiveField(2)
  final String? email;

  /// The URL of the user's profile photo.
  @HiveField(3)
  final String? photoUrl;

  /// The ID of the family or team this user belongs to, if any.
  @HiveField(4)
  final String? familyId;

  /// The user's role within their family or team.
  @HiveField(5)
  final UserRole? role;
  
  /// Timestamp of when the user profile was created.
  @HiveField(6)
  final DateTime? createdAt;

  /// Timestamp of the user's last activity.
  @HiveField(7)
  final DateTime? lastActive;
  
  /// User-specific preferences.
  @HiveField(8)
  final Map<String, dynamic>? preferences;

  /// User's gamification data.
  @HiveField(9)
  final GamificationProfile? gamificationProfile;

  /// User's token wallet for AI micro-economy.
  @HiveField(10)
  final TokenWallet? tokenWallet;

  /// User's token transaction history.
  @HiveField(11)
  final List<TokenTransaction>? tokenTransactions;

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
    GamificationProfile? gamificationProfile,
    TokenWallet? tokenWallet,
    List<TokenTransaction>? tokenTransactions,
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
      gamificationProfile: gamificationProfile ?? this.gamificationProfile,
      tokenWallet: tokenWallet ?? this.tokenWallet,
      tokenTransactions: tokenTransactions ?? this.tokenTransactions,
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
      'gamificationProfile': gamificationProfile?.toJson(),
      'tokenWallet': tokenWallet?.toJson(),
      'tokenTransactions': tokenTransactions?.map((e) => e.toJson()).toList(),
    };
  }
} 