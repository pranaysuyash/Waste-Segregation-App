/// Firestore Schema Registry
///
/// Canonical single source of truth for all Firestore collection schemas,
/// field classifications, and validation rules. Every service that writes to
/// Firestore should reference this registry for field names and privacy
/// classifications.
///
/// This file replaces scattered string literals and the stale
/// docs/guides/development/data_storage/firestore_schema.md as the
/// authoritative schema definition. The documentation should be regenerated
/// from this file when it changes.
///
/// GENERATED FROM: Actual model toJson() methods, verified 2026-05-16
/// AUDIT TRAIL: Random Document Audit of firestore_schema.md

library;

// ============================================================
// SECTION 1: Collection Names
// ============================================================

/// All Firestore collection names used by the app.
///
/// Add new collections here BEFORE writing code that references them.
/// This prevents typo-driven bugs and makes grep-able audits possible.
class FirestoreCollections {
  // --- User-scoped collections ---
  static const String users = 'users';
  static const String classifications =
      'classifications'; // subcollection of users
  static const String gamification = 'gamification';

  // --- Leaderboard collections ---
  static const String leaderboardAllTime = 'leaderboard_allTime';
  static const String leaderboardWeekly =
      'leaderboard_weekly'; // defined in rules, not yet in service code

  // --- Community collections ---
  static const String communityFeed = 'community_feed';
  static const String communityStats = 'community_stats';
  static const String communityChallenges = 'community_challenges';

  // --- Family collections ---
  static const String families = 'families';
  static const String invitations = 'invitations';
  static const String sharedClassifications = 'shared_classifications';
  static const String familyStats = 'family_stats';

  // --- Classification feedback ---
  static const String classificationFeedback = 'classification_feedback';

  // --- AI & Token collections ---
  static const String aiJobs = 'ai_jobs';

  // --- Analytics ---
  static const String analyticsEvents = 'analytics_events';

  // --- Admin collections ---
  static const String adminClassifications = 'admin_classifications';
  static const String adminUserRecovery = 'admin_user_recovery';
  static const String admin = 'admin'; // wildcard collection

  // --- Reference data collections ---
  static const String disposalInstructions = 'disposal_instructions';
  static const String disposalLocations = 'disposal_locations';

  // --- User contributions ---
  static const String userContributions = 'user_contributions';

  /// All collection names for iteration/validation
  static const Set<String> allCollections = {
    users,
    classifications,
    gamification,
    leaderboardAllTime,
    leaderboardWeekly,
    communityFeed,
    communityStats,
    communityChallenges,
    families,
    invitations,
    sharedClassifications,
    familyStats,
    classificationFeedback,
    aiJobs,
    analyticsEvents,
    adminClassifications,
    adminUserRecovery,
    admin,
    disposalInstructions,
    disposalLocations,
    userContributions,
  };
}

// ============================================================
// SECTION 2: Field Classifications
// ============================================================

/// Privacy classification for Firestore fields.
///
/// Used to determine what PII handling, Firestore rule validation,
/// and documentation requirements apply to each field.
enum FieldClassification {
  /// Public-facing data that any authenticated user can see (e.g., displayName on leaderboard)
  public,

  /// User-owned data visible only to the user themselves (e.g., email, points)
  private,

  /// PII that requires special handling — must not appear in public-facing
  /// collections without explicit consent or anonymization (e.g., email, phone)
  pii,

  /// System-generated metadata (timestamps, IDs, counters) — not user content
  system,

  /// User-authored content (classification names, feedback text, community posts)
  userContent,

  /// Aggregated/anonymized statistics — safe for public display
  aggregate,
}

/// Schema field definition with type and classification.
class SchemaField {
  const SchemaField({
    required this.name,
    required this.type,
    required this.classification,
    this.required = true,
    this.defaultValue,
    this.description,
  });

  final String name;
  final String type; // e.g., 'String', 'int', 'Map<String, int>', 'List<Map>'
  final FieldClassification classification;
  final bool required;
  final dynamic defaultValue;
  final String? description;

  /// Whether this field contains PII that should be redacted in public collections.
  bool get isPii => classification == FieldClassification.pii;

  /// Whether this field should be omitted from leaderboard/public collections.
  bool get isPrivate =>
      classification == FieldClassification.private ||
      classification == FieldClassification.pii;
}

// ============================================================
// SECTION 3: Collection Schemas
// ============================================================

/// Canonical schema for the `users` collection.
///
/// Source: UserProfile.toJson() + gamificationProfile embedding
class UsersSchema {
  static const String collection = FirestoreCollections.users;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Firebase Auth UID, same as document ID',
    ),
    SchemaField(
      name: 'displayName',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
      description: 'User-chosen display name',
    ),
    SchemaField(
      name: 'email',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
      description:
          'User email from auth provider. PII — consider redacting before Firestore write.',
    ),
    SchemaField(
      name: 'photoUrl',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
      description: 'Profile photo URL. Written to leaderboard — needs opt-out.',
    ),
    SchemaField(
      name: 'familyId',
      type: 'String?',
      classification: FieldClassification.private,
      required: false,
      description: 'ID of the family the user belongs to',
    ),
    SchemaField(
      name: 'role',
      type: 'String?',
      classification: FieldClassification.private,
      required: false,
      description: 'UserRole enum as string',
    ),
    SchemaField(
      name: 'createdAt',
      type: 'String?',
      classification: FieldClassification.system,
      required: false,
      description: 'ISO 8601 timestamp',
    ),
    SchemaField(
      name: 'lastActive',
      type: 'String?',
      classification: FieldClassification.system,
      required: false,
      description: 'ISO 8601 timestamp',
    ),
    SchemaField(
      name: 'preferences',
      type: 'Map<String, dynamic>?',
      classification: FieldClassification.private,
      required: false,
      description: 'User preferences map (NOT a separate UserSettings class)',
    ),
    SchemaField(
      name: 'gamificationProfile',
      type: 'Map',
      classification: FieldClassification.private,
      required: false,
      description: 'Embedded GamificationProfile.toJson()',
    ),
    SchemaField(
      name: 'tokenWallet',
      type: 'Map?',
      classification: FieldClassification.private,
      required: false,
      description: 'Embedded TokenWallet.toJson()',
    ),
    SchemaField(
      name: 'tokenTransactions',
      type: 'List<Map>?',
      classification: FieldClassification.private,
      required: false,
      description: 'Embedded token transaction history',
    ),
  ];
}

/// Canonical schema for `users/{userId}/classifications` subcollection.
///
/// Source: WasteClassification.toJson()
/// NOTE: This model has 70+ fields. Only the most important are listed here.
/// See WasteClassification.fromJson for the complete list.
class ClassificationsSchema {
  static const String collection = FirestoreCollections.classifications;

  static const List<SchemaField> keyFields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
      description: 'UUID, same as document ID',
    ),
    SchemaField(
      name: 'itemName',
      type: 'String',
      classification: FieldClassification.userContent,
      description: 'Name of classified waste item',
    ),
    SchemaField(
      name: 'category',
      type: 'String',
      classification: FieldClassification.userContent,
      description: 'Waste category (Wet, Dry, Hazardous, Medical, Non-waste)',
    ),
    SchemaField(
      name: 'confidence',
      type: 'double?',
      classification: FieldClassification.system,
      required: false,
      description:
          'AI confidence score 0.0-1.0. NOTE: doc previously called this "accuracy" — incorrect.',
    ),
    SchemaField(
      name: 'timestamp',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601 timestamp',
    ),
    SchemaField(
      name: 'userId',
      type: 'String?',
      classification: FieldClassification.private,
      required: false,
      description: 'Owning user ID',
    ),
    SchemaField(
      name: 'imageUrl',
      type: 'String?',
      classification: FieldClassification.private,
      required: false,
      description: 'Cloud storage URL for classification image',
    ),
    SchemaField(
      name: 'source',
      type: 'String?',
      classification: FieldClassification.system,
      required: false,
      description: 'Classification source (e.g., "ai", "manual")',
    ),
  ];

  // Full field count: 70+ fields in WasteClassification
  // Key deprecated fields:
  // - 'subcategory' (deprecated, use 'subCategory' for AI v2.0)
  // - 'materialType' (deprecated, use 'materials' list for AI v2.0)
}

/// Canonical schema for `community_feed` collection.
///
/// Source: CommunityFeedItem.toJson()
/// CRITICAL: The Firestore rules currently validate a DIFFERENT schema
/// (userId, content, timestamp, type, imageUrl, likes, comments, tags).
/// This must be reconciled. See ISSUE-001 in audit report.
class CommunityFeedSchema {
  static const String collection = FirestoreCollections.communityFeed;

  // What the MODEL actually writes:
  static const List<SchemaField> modelFields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
    ),
    SchemaField(
      name: 'userId',
      type: 'String',
      classification: FieldClassification.pii,
    ),
    SchemaField(
      name: 'userName',
      type: 'String',
      classification: FieldClassification.pii,
      description: 'Display name — PII, written to public collection',
    ),
    SchemaField(
      name: 'userAvatar',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
      description: 'Avatar URL — PII, written to public collection',
    ),
    SchemaField(
      name: 'activityType',
      type: 'String',
      classification: FieldClassification.system,
      description:
          'Enum name: classification|achievement|streak|challenge|milestone|educational',
    ),
    SchemaField(
      name: 'title',
      type: 'String',
      classification: FieldClassification.userContent,
    ),
    SchemaField(
      name: 'description',
      type: 'String',
      classification: FieldClassification.userContent,
    ),
    SchemaField(
      name: 'timestamp',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'metadata',
      type: 'Map<String, dynamic>',
      classification: FieldClassification.userContent,
      required: false,
      description: 'Arbitrary metadata, may contain category etc.',
    ),
    SchemaField(
      name: 'likes',
      type: 'int',
      classification: FieldClassification.aggregate,
      required: false,
      defaultValue: 0,
    ),
    SchemaField(
      name: 'likedBy',
      type: 'List<String>',
      classification: FieldClassification.private,
      required: false,
      description: 'User IDs who liked — PII concern',
    ),
    SchemaField(
      name: 'isAnonymous',
      type: 'bool',
      classification: FieldClassification.system,
      required: false,
      defaultValue: false,
    ),
    SchemaField(
      name: 'points',
      type: 'int',
      classification: FieldClassification.aggregate,
      required: false,
      defaultValue: 0,
    ),
  ];

  // What the FIRESTORE RULES currently expect (MISMATCH):
  // Required: userId, content, timestamp, type
  // Allowed:  userId, content, timestamp, type, imageUrl, likes, comments, tags
  // The model uses activityType/title/description but rules expect type/content
  // The model uses userName/userAvatar/likedBy/isAnonymous/points but rules don't allow them
  // This MUST be reconciled before community feed writes will succeed.
}

/// Canonical schema for `families` collection.
///
/// Source: Family.toJson() from enhanced_family.dart
/// Fields: id, name, description, createdBy, createdAt, updatedAt,
/// members (list of embedded FamilyMember), memberUids (flat List<String> for rules),
/// settings (embedded FamilySettings), imageUrl, isPublic.
/// memberUids is derived from members[].userId for Firestore rules membership checks.
/// Legacy docs without memberUids can derive it from members on read (fromJson).
class FamiliesSchema {
  static const String collection = FirestoreCollections.families;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
      description: 'UUID, same as document ID',
    ),
    SchemaField(
      name: 'name',
      type: 'String',
      classification: FieldClassification.userContent,
      description: 'Family name (NOT "familyName")',
    ),
    SchemaField(
      name: 'description',
      type: 'String?',
      classification: FieldClassification.userContent,
      required: false,
    ),
    SchemaField(
      name: 'createdBy',
      type: 'String',
      classification: FieldClassification.system,
      description: 'User ID who created the family',
    ),
    SchemaField(
      name: 'createdAt',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'updatedAt',
      type: 'String?',
      classification: FieldClassification.system,
      required: false,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'members',
      type: 'List<Map>',
      classification: FieldClassification.private,
      description: 'Embedded list of FamilyMember objects',
    ),
    SchemaField(
      name: 'settings',
      type: 'Map',
      classification: FieldClassification.private,
      required: false,
      description:
          'Embedded FamilySettings object. Contains leaderboardVisibility (stable wire values: public/membersOnly/adminsOnly) that controls family_stats read access.',
    ),
    SchemaField(
      name: 'imageUrl',
      type: 'String?',
      classification: FieldClassification.private,
      required: false,
    ),
    SchemaField(
      name: 'isPublic',
      type: 'bool',
      classification: FieldClassification.system,
      required: false,
      defaultValue: false,
    ),
    SchemaField(
      name: 'memberUids',
      type: 'List<String>',
      classification: FieldClassification.system,
      required: false,
      description:
          'Flat list of member user IDs for Firestore rules membership checks. Derived from members[].userId.',
    ),
  ];
}

/// Canonical schema for `leaderboard_allTime` collection.
///
/// Source: cloud_storage_service.dart write + LeaderboardEntry model
/// CRITICAL: photoUrl is written by code but was NOT in the Firestore rules
/// hasOnly whitelist. It must be added to the rules.
class LeaderboardAllTimeSchema {
  static const String collection = FirestoreCollections.leaderboardAllTime;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'userId',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Same as document ID and auth UID',
    ),
    SchemaField(
      name: 'displayName',
      type: 'String',
      classification: FieldClassification.pii,
      description:
          'User display name — PII in public collection, needs opt-out',
    ),
    SchemaField(
      name: 'photoUrl',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
      description:
          'Profile photo URL — PII in public collection, needs opt-out',
    ),
    SchemaField(
      name: 'points',
      type: 'int',
      classification: FieldClassification.aggregate,
      description: 'Total points from gamification',
    ),
    SchemaField(
      name: 'lastUpdated',
      type: 'Timestamp',
      classification: FieldClassification.system,
      description: 'Server timestamp via FieldValue.serverTimestamp()',
    ),
    SchemaField(
      name: 'rank',
      type: 'int?',
      classification: FieldClassification.aggregate,
      required: false,
      description: 'Computed rank, not always stored',
    ),
    SchemaField(
      name: 'weeklyPoints',
      type: 'int?',
      classification: FieldClassification.aggregate,
      required: false,
      description: 'Weekly points subtotal, if stored',
    ),
  ];

  // Fields in LeaderboardEntry model but NOT currently written to Firestore:
  // - previousRank, categoryBreakdown, recentAchievements, stats,
  //   isCurrentUser, familyId, familyName
  // These are populated client-side from other sources, not stored directly.
}

/// Canonical schema for `community_stats` collection (singleton document).
///
/// Source: community_service.dart writes and CommunityStats model
class CommunityStatsSchema {
  static const String collection = FirestoreCollections.communityStats;
  static const String mainDocId = 'main';

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'totalUsers',
      type: 'int',
      classification: FieldClassification.aggregate,
      defaultValue: 0,
    ),
    SchemaField(
      name: 'totalClassifications',
      type: 'int',
      classification: FieldClassification.aggregate,
      defaultValue: 0,
    ),
    SchemaField(
      name: 'totalPoints',
      type: 'int',
      classification: FieldClassification.aggregate,
      defaultValue: 0,
    ),
    SchemaField(
      name: 'categoryBreakdown',
      type: 'Map<String, int>',
      classification: FieldClassification.aggregate,
      required: false,
    ),
    SchemaField(
      name: 'lastUpdated',
      type: 'Timestamp',
      classification: FieldClassification.system,
      required: false,
      description: 'Server timestamp',
    ),
  ];
}

/// Canonical schema for `classification_feedback` collection.
///
/// Source: classification_feedback.dart model
class ClassificationFeedbackSchema {
  static const String collection = FirestoreCollections.classificationFeedback;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'userId',
      type: 'String',
      classification: FieldClassification.pii,
      description: 'Auth UID of feedback submitter',
    ),
    SchemaField(
      name: 'originalClassificationId',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Reference to original classification document',
    ),
    SchemaField(
      name: 'feedbackTimestamp',
      type: 'Timestamp',
      classification: FieldClassification.system,
    ),
    // Additional fields from model: correctedCategory, userNotes, etc.
  ];
}

/// Canonical schema for `invitations` collection.
///
/// Source: FamilyInvitation.toJson() from family_invitation.dart
class InvitationsSchema {
  static const String collection = FirestoreCollections.invitations;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
      description: 'UUID, same as document ID',
    ),
    SchemaField(
      name: 'familyId',
      type: 'String',
      classification: FieldClassification.system,
    ),
    SchemaField(
      name: 'familyName',
      type: 'String',
      classification: FieldClassification.userContent,
    ),
    SchemaField(
      name: 'inviterUserId',
      type: 'String',
      classification: FieldClassification.pii,
      description: 'Auth UID of inviter',
    ),
    SchemaField(
      name: 'inviterName',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
    ),
    SchemaField(
      name: 'invitedEmail',
      type: 'String',
      classification: FieldClassification.pii,
      description: 'Email of invitee — PII, not for public exposure',
    ),
    SchemaField(
      name: 'invitedUserId',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
    ),
    SchemaField(
      name: 'status',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Enum: pending|accepted|declined|expired|revoked|cancelled',
    ),
    SchemaField(
      name: 'roleToAssign',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Enum: admin|member|child|guest',
    ),
    SchemaField(
      name: 'method',
      type: 'String',
      classification: FieldClassification.system,
      description: 'Enum: email|qr',
    ),
    SchemaField(
      name: 'createdAt',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'expiresAt',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'respondedAt',
      type: 'String?',
      classification: FieldClassification.system,
      required: false,
      description: 'ISO 8601',
    ),
  ];
}

/// Canonical schema for `shared_classifications` collection.
///
/// Source: SharedWasteClassification.toJson() from shared_waste_classification.dart
class SharedClassificationsSchema {
  static const String collection = FirestoreCollections.sharedClassifications;

  static const List<SchemaField> fields = [
    SchemaField(
      name: 'id',
      type: 'String',
      classification: FieldClassification.system,
    ),
    SchemaField(
      name: 'classification',
      type: 'Map',
      classification: FieldClassification.userContent,
      description: 'Embedded WasteClassification.toJson()',
    ),
    SchemaField(
      name: 'sharedBy',
      type: 'String',
      classification: FieldClassification.pii,
      description: 'Auth UID of sharer',
    ),
    SchemaField(
      name: 'sharedByDisplayName',
      type: 'String',
      classification: FieldClassification.pii,
    ),
    SchemaField(
      name: 'sharedByPhotoUrl',
      type: 'String?',
      classification: FieldClassification.pii,
      required: false,
    ),
    SchemaField(
      name: 'sharedAt',
      type: 'String',
      classification: FieldClassification.system,
      description: 'ISO 8601',
    ),
    SchemaField(
      name: 'familyId',
      type: 'String',
      classification: FieldClassification.system,
    ),
    SchemaField(
      name: 'reactions',
      type: 'List<Map>',
      classification: FieldClassification.userContent,
      required: false,
      defaultValue: '[]',
    ),
    SchemaField(
      name: 'comments',
      type: 'List<Map>',
      classification: FieldClassification.userContent,
      required: false,
      defaultValue: '[]',
    ),
    SchemaField(
      name: 'location',
      type: 'Map?',
      classification: FieldClassification.userContent,
      required: false,
    ),
    SchemaField(
      name: 'isVisible',
      type: 'bool',
      classification: FieldClassification.system,
      required: false,
      defaultValue: true,
    ),
    SchemaField(
      name: 'familyTags',
      type: 'List<String>',
      classification: FieldClassification.userContent,
      required: false,
      defaultValue: '[]',
    ),
  ];
}

// ============================================================
// SECTION 4: Privacy Guards
// ============================================================

/// Privacy guard configuration for Firestore collections.
///
/// Defines which PII fields should be redacted or omitted when writing
/// to public-facing collections (leaderboards, community feed, etc.).
class PrivacyGuardConfig {
  const PrivacyGuardConfig({
    required this.collection,
    required this.piiFieldsToRedact,
    required this.piiFieldsToOmit,
    this.optOutField,
    this.description,
  });

  final String collection;
  final List<String> piiFieldsToRedact;
  final List<String> piiFieldsToOmit;
  final String? optOutField; // e.g., 'leaderboardOptOut' in UserProfile
  final String? description;

  /// All configured privacy guards.
  static const List<PrivacyGuardConfig> allGuards = [
    PrivacyGuardConfig(
      collection: FirestoreCollections.leaderboardAllTime,
      piiFieldsToRedact: ['displayName'], // hash or anonymize if user opts out
      piiFieldsToOmit: ['photoUrl'], // omit if user opts out
      // optOutField references UserPreferenceKeys.leaderboardOptOut in constants.dart
      // Kept as string literal here for schema documentation; service code uses the constant.
      optOutField: 'preferences.leaderboardOptOut',
      description: 'Leaderboard displays name/photo unless user opts out',
    ),
    PrivacyGuardConfig(
      collection: FirestoreCollections.communityFeed,
      piiFieldsToRedact: ['userName'], // anonymize if isAnonymous
      piiFieldsToOmit: ['userAvatar'], // omit if isAnonymous
      optOutField: 'isAnonymous', // model field, not a user preference
      description: 'Community feed respects isAnonymous flag',
    ),
    PrivacyGuardConfig(
      collection: FirestoreCollections.users,
      piiFieldsToRedact: [],
      piiFieldsToOmit: [
        'email',
      ], // email should not be stored in Firestore in production
      description: 'Email should come from Firebase Auth, not Firestore',
    ),
  ];

  /// Check if a field in a collection should be redacted.
  static bool shouldRedact(String collection, String field) {
    for (final guard in allGuards) {
      if (guard.collection == collection &&
          guard.piiFieldsToRedact.contains(field)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a field in a collection should be omitted entirely.
  static bool shouldOmit(String collection, String field) {
    for (final guard in allGuards) {
      if (guard.collection == collection &&
          guard.piiFieldsToOmit.contains(field)) {
        return true;
      }
    }
    return false;
  }
}

// ============================================================
// SECTION 5: Schema Validation Helpers
// ============================================================

/// Validates that a data map conforms to the expected schema for a collection.
///
/// This is the runtime validation layer that catches schema drift before
/// data reaches Firestore. Used by services before writing.
class FirestoreSchemaValidator {
  /// Validate that a data map contains all required fields for a collection.
  ///
  /// Returns a list of validation errors (empty if valid).
  static List<String> validateRequiredFields(
    String collection,
    Map<String, dynamic> data,
  ) {
    final errors = <String>[];
    final schema = _getSchemaForCollection(collection);

    if (schema == null) {
      // Unknown collection — allow but warn
      return errors;
    }

    for (final field in schema) {
      if (field.required && !data.containsKey(field.name)) {
        errors.add('Missing required field "${field.name}" in $collection');
      }
    }

    return errors;
  }

  /// Validate that no unexpected fields are present (against Firestore rules).
  ///
  /// This mirrors the hasOnly() validation in Firestore rules but runs
  /// client-side for faster feedback.
  static List<String> validateAllowedFields(
    String collection,
    Map<String, dynamic> data,
    List<String> allowedFields,
  ) {
    final errors = <String>[];
    final dataKeys = data.keys.toSet();
    final allowedSet = allowedFields.toSet();
    final unexpected = dataKeys.difference(allowedSet);

    if (unexpected.isNotEmpty) {
      errors.add(
        'Unexpected fields in $collection: $unexpected. '
        'Allowed: $allowedSet',
      );
    }

    return errors;
  }

  /// Check PII fields before writing to a public collection.
  ///
  /// Returns a map with PII fields redacted/omitted as configured.
  static Map<String, dynamic> applyPrivacyGuard(
    String collection,
    Map<String, dynamic> data,
  ) {
    final sanitized = Map<String, dynamic>.from(data);

    for (final guard in PrivacyGuardConfig.allGuards) {
      if (guard.collection != collection) continue;

      for (final field in guard.piiFieldsToOmit) {
        sanitized.remove(field);
      }
      for (final field in guard.piiFieldsToRedact) {
        if (sanitized.containsKey(field) && sanitized[field] is String) {
          sanitized[field] = 'Anonymous';
        }
      }
    }

    return sanitized;
  }

  static List<SchemaField>? _getSchemaForCollection(String collection) {
    switch (collection) {
      case FirestoreCollections.users:
        return UsersSchema.fields;
      case FirestoreCollections.communityFeed:
        return CommunityFeedSchema.modelFields;
      case FirestoreCollections.families:
        return FamiliesSchema.fields;
      case FirestoreCollections.leaderboardAllTime:
        return LeaderboardAllTimeSchema.fields;
      case FirestoreCollections.invitations:
        return InvitationsSchema.fields;
      case FirestoreCollections.sharedClassifications:
        return SharedClassificationsSchema.fields;
      default:
        return null;
    }
  }
}
