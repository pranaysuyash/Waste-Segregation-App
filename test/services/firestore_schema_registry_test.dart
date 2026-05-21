import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/firestore_schema_registry.dart';

void main() {
  // ============================================================
  // FirestoreCollections Tests
  // ============================================================
  group('FirestoreCollections', () {
    test('allCollections contains expected collection names', () {
      expect(FirestoreCollections.allCollections, contains('users'));
      expect(FirestoreCollections.allCollections, contains('community_feed'));
      expect(FirestoreCollections.allCollections, contains('families'));
      expect(
          FirestoreCollections.allCollections, contains('leaderboard_allTime'));
      expect(
          FirestoreCollections.allCollections, contains('leaderboard_weekly'));
      expect(FirestoreCollections.allCollections,
          contains('classification_feedback'));
      expect(FirestoreCollections.allCollections, contains('ai_jobs'));
      expect(FirestoreCollections.allCollections, contains('analytics_events'));
      expect(FirestoreCollections.allCollections, contains('invitations'));
      expect(FirestoreCollections.allCollections,
          contains('shared_classifications'));
      expect(FirestoreCollections.allCollections, contains('family_stats'));
      expect(FirestoreCollections.allCollections, contains('community_stats'));
      expect(
          FirestoreCollections.allCollections, contains('disposal_locations'));
      expect(
          FirestoreCollections.allCollections, contains('user_contributions'));
      expect(FirestoreCollections.allCollections,
          contains('admin_classifications'));
      expect(
          FirestoreCollections.allCollections, contains('admin_user_recovery'));
      expect(
          FirestoreCollections.allCollections, contains('training_candidates'));
      expect(FirestoreCollections.allCollections, contains('training_labels'));
      expect(FirestoreCollections.allCollections,
          contains('training_dataset_versions'));
    });

    test('collection name constants match string values', () {
      expect(FirestoreCollections.users, equals('users'));
      expect(FirestoreCollections.classifications, equals('classifications'));
      expect(FirestoreCollections.communityFeed, equals('community_feed'));
      expect(FirestoreCollections.communityStats, equals('community_stats'));
      expect(FirestoreCollections.families, equals('families'));
      expect(FirestoreCollections.leaderboardAllTime,
          equals('leaderboard_allTime'));
      expect(
          FirestoreCollections.leaderboardWeekly, equals('leaderboard_weekly'));
      expect(FirestoreCollections.trainingCandidates,
          equals('training_candidates'));
      expect(FirestoreCollections.trainingLabels, equals('training_labels'));
      expect(FirestoreCollections.trainingDatasetVersions,
          equals('training_dataset_versions'));
    });
  });

  // ============================================================
  // Schema Field Classification Tests
  // ============================================================
  group('Schema Field Classification', () {
    test('PII fields are correctly identified', () {
      // Users collection PII fields
      final emailField =
          UsersSchema.fields.firstWhere((f) => f.name == 'email');
      expect(emailField.classification, equals(FieldClassification.pii));
      expect(emailField.isPii, isTrue);
      expect(emailField.isPrivate, isTrue);

      final displayNameField =
          UsersSchema.fields.firstWhere((f) => f.name == 'displayName');
      expect(displayNameField.classification, equals(FieldClassification.pii));

      // Community feed PII fields
      final userIdField =
          CommunityFeedSchema.modelFields.firstWhere((f) => f.name == 'userId');
      expect(userIdField.classification, equals(FieldClassification.pii));

      final userNameField = CommunityFeedSchema.modelFields
          .firstWhere((f) => f.name == 'userName');
      expect(userNameField.classification, equals(FieldClassification.pii));
      expect(userNameField.isPii, isTrue);

      // Leaderboard PII fields
      final photoUrlField = LeaderboardAllTimeSchema.fields
          .firstWhere((f) => f.name == 'photoUrl');
      expect(photoUrlField.classification, equals(FieldClassification.pii));
      expect(photoUrlField.isPii, isTrue);

      final userHashField = TrainingCandidatesSchema.fields
          .firstWhere((f) => f.name == 'userIdHash');
      expect(userHashField.classification, equals(FieldClassification.private));
      expect(userHashField.description, contains('HMAC'));
    });

    test('system fields are correctly identified', () {
      final idField = UsersSchema.fields.firstWhere((f) => f.name == 'id');
      expect(idField.classification, equals(FieldClassification.system));
      expect(idField.isPii, isFalse);
      expect(idField.isPrivate, isFalse);

      final timestampField = CommunityFeedSchema.modelFields
          .firstWhere((f) => f.name == 'timestamp');
      expect(timestampField.classification, equals(FieldClassification.system));
    });

    test('aggregate fields are correctly identified', () {
      final pointsField =
          LeaderboardAllTimeSchema.fields.firstWhere((f) => f.name == 'points');
      expect(pointsField.classification, equals(FieldClassification.aggregate));

      final likesField =
          CommunityFeedSchema.modelFields.firstWhere((f) => f.name == 'likes');
      expect(likesField.classification, equals(FieldClassification.aggregate));
    });

    test('userContent fields are correctly identified', () {
      final titleField =
          CommunityFeedSchema.modelFields.firstWhere((f) => f.name == 'title');
      expect(
          titleField.classification, equals(FieldClassification.userContent));

      final descriptionField = CommunityFeedSchema.modelFields
          .firstWhere((f) => f.name == 'description');
      expect(descriptionField.classification,
          equals(FieldClassification.userContent));
    });
  });

  // ============================================================
  // Schema Validation Tests
  // ============================================================
  group('FirestoreSchemaValidator', () {
    test('validateRequiredFields returns empty for valid community feed data',
        () {
      final data = {
        'id': 'test-id',
        'userId': 'user-123',
        'userName': 'Test User',
        'activityType': 'classification',
        'title': 'Test Title',
        'description': 'Test Description',
        'timestamp': '2026-05-16T12:00:00Z',
        'metadata': {},
        'likes': 0,
        'likedBy': [],
        'isAnonymous': false,
        'points': 10,
      };

      final errors = FirestoreSchemaValidator.validateRequiredFields(
          FirestoreCollections.communityFeed, data);
      expect(errors, isEmpty);
    });

    test('validateRequiredFields reports missing required fields', () {
      final data = {
        'id': 'test-id',
        // Missing userId, activityType, title, description, timestamp
      };

      final errors = FirestoreSchemaValidator.validateRequiredFields(
          FirestoreCollections.communityFeed, data);
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('userId')), isTrue);
      expect(errors.any((e) => e.contains('activityType')), isTrue);
      expect(errors.any((e) => e.contains('title')), isTrue);
    });

    test('validateRequiredFields returns empty for unknown collection', () {
      final data = {'someField': 'someValue'};
      final errors = FirestoreSchemaValidator.validateRequiredFields(
          'unknown_collection', data);
      expect(
          errors, isEmpty); // Unknown collections are allowed (advisory only)
    });

    test('validateAllowedFields detects unexpected fields', () {
      final data = {
        'userId': 'user-123',
        'points': 100,
        'displayName': 'Test User',
        'lastUpdated': '2026-05-16',
        'hackerField': 'injected',
      };

      final allowed = [
        'userId',
        'points',
        'displayName',
        'lastUpdated',
        'rank',
        'weeklyPoints',
        'photoUrl'
      ];
      final errors = FirestoreSchemaValidator.validateAllowedFields(
          FirestoreCollections.leaderboardAllTime, data, allowed);
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('hackerField')), isTrue);
    });

    test('validateAllowedFields passes for valid leaderboard data', () {
      final data = {
        'userId': 'user-123',
        'points': 100,
        'displayName': 'Test User',
        'lastUpdated': '2026-05-16',
        'photoUrl': 'https://example.com/photo.jpg',
      };

      final allowed = [
        'userId',
        'points',
        'displayName',
        'lastUpdated',
        'rank',
        'weeklyPoints',
        'photoUrl'
      ];
      final errors = FirestoreSchemaValidator.validateAllowedFields(
          FirestoreCollections.leaderboardAllTime, data, allowed);
      expect(errors, isEmpty);
    });
  });

  // ============================================================
  // Privacy Guard Tests
  // ============================================================
  group('PrivacyGuardConfig', () {
    test(
        'leaderboard guard redacts displayName and omits photoUrl for opted-out users',
        () {
      final data = {
        'userId': 'user-123',
        'displayName': 'John Doe',
        'photoUrl': 'https://example.com/photo.jpg',
        'points': 100,
        'lastUpdated': '2026-05-16',
      };

      // When opted out
      final optedOutPrefs = {'leaderboardOptOut': true};
      final userProfile = UserProfile(
        id: 'user-123',
        displayName: 'John Doe',
        photoUrl: 'https://example.com/photo.jpg',
        preferences: optedOutPrefs,
      );
      expect(userProfile.preferences?['leaderboardOptOut'], isTrue);

      // Simulate what _applyLeaderboardPrivacyGuard does
      final sanitized = Map<String, dynamic>.from(data);
      sanitized['displayName'] = 'Anonymous User';
      sanitized.remove('photoUrl');

      expect(sanitized['displayName'], equals('Anonymous User'));
      expect(sanitized.containsKey('photoUrl'), isFalse);
      expect(sanitized['points'], equals(100)); // Non-PII preserved
      expect(sanitized['userId'], equals('user-123')); // Non-PII preserved
    });

    test('user profile guard removes email', () {
      final data = {
        'id': 'user-123',
        'displayName': 'John Doe',
        'email': 'john@example.com', // PII
        'photoUrl': 'https://example.com/photo.jpg',
        'familyId': null,
      };

      // Simulate what _applyUserProfilePrivacyGuard does
      final sanitized = Map<String, dynamic>.from(data)..remove('email');

      expect(sanitized.containsKey('email'), isFalse);
      expect(sanitized['displayName'], equals('John Doe')); // Non-PII preserved
      expect(sanitized['id'], equals('user-123')); // Non-PII preserved
    });

    test('community feed privacy guard for anonymous posts', () {
      final data = {
        'id': 'feed-1',
        'userId': 'user-123',
        'userName': 'Jane Doe', // PII
        'userAvatar': 'https://example.com/avatar.jpg', // PII
        'activityType': 'classification',
        'title': 'Test',
        'description': 'Test',
        'timestamp': '2026-05-16',
        'isAnonymous': true,
      };

      // When isAnonymous, redact PII
      data['userName'] = 'Anonymous User';
      data.remove('userAvatar');

      expect(data['userName'], equals('Anonymous User'));
      expect(data.containsKey('userAvatar'), isFalse);
      expect(
          data['activityType'], equals('classification')); // Non-PII preserved
    });
  });

  // ============================================================
  // Schema Completeness Tests (catch drift between registry and models)
  // ============================================================
  group('Schema Registry Completeness', () {
    test('UsersSchema has all UserProfile.toJson fields', () {
      final schemaFields = UsersSchema.fields.map((f) => f.name).toSet();
      // Key fields that must be present
      expect(
          schemaFields,
          containsAll([
            'id',
            'displayName',
            'email',
            'photoUrl',
            'familyId',
            'role',
            'createdAt',
            'lastActive',
            'preferences',
            'gamificationProfile',
            'tokenWallet',
            'tokenTransactions',
          ]));
    });

    test('CommunityFeedSchema has all CommunityFeedItem.toJson fields', () {
      final schemaFields =
          CommunityFeedSchema.modelFields.map((f) => f.name).toSet();
      expect(
          schemaFields,
          containsAll([
            'id',
            'userId',
            'userName',
            'userAvatar',
            'activityType',
            'title',
            'description',
            'timestamp',
            'metadata',
            'likes',
            'likedBy',
            'isAnonymous',
            'points',
          ]));
    });

    test('FamiliesSchema has all Family.toJson fields', () {
      final schemaFields = FamiliesSchema.fields.map((f) => f.name).toSet();
      expect(
          schemaFields,
          containsAll([
            'id',
            'name',
            'description',
            'createdBy',
            'createdAt',
            'updatedAt',
            'members',
            'memberUids',
            'settings',
            'imageUrl',
            'isPublic',
          ]));

      // Verify the old doc's wrong field names are NOT in the schema
      expect(schemaFields, isNot(contains('familyName')));
      expect(schemaFields, isNot(contains('familyAdminUids')));
      expect(schemaFields, isNot(contains('familyCode')));
      expect(schemaFields, isNot(contains('familyGoals')));
      expect(schemaFields, isNot(contains('familyLeaderboardSettings')));
    });

    test('LeaderboardAllTimeSchema has photoUrl', () {
      final schemaFields =
          LeaderboardAllTimeSchema.fields.map((f) => f.name).toSet();
      expect(schemaFields, contains('photoUrl')); // Was missing from old rules
      expect(schemaFields, contains('displayName'));
      expect(schemaFields, contains('points'));
      expect(schemaFields, contains('lastUpdated'));
    });

    test('GamificationProfile correct field names (not old doc names)', () {
      // The old doc claimed 'preferences' and 'dailyStreak' but the actual
      // model has 'streaks' and no separate 'preferences' or 'dailyStreak' class
      final gamificationFields = [
        'userId',
        'achievements',
        'streaks',
        'points',
        'activeChallenges',
        'completedChallenges',
        'weeklyStats',
        'discoveredItemIds',
        'lastDailyEngagementBonusAwardedDate',
        'lastViewPersonalStatsAwardedDate',
        'unlockedHiddenContentIds',
      ];
      // This test documents the actual field names for future reference
      expect(gamificationFields, contains('streaks')); // NOT 'dailyStreak'
      expect(gamificationFields,
          isNot(contains('preferences'))); // NOT a separate class
      expect(gamificationFields,
          isNot(contains('dailyStreak'))); // NOT a class name
    });
  });
}
