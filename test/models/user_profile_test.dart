import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    group('UserProfile Model', () {
      test('should create UserProfile with all required properties', () {
        final profile = UserProfile(
          id: 'user_123',
          email: 'john.doe@example.com',
          displayName: 'John Doe',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
        );

        expect(profile.id, 'user_123');
        expect(profile.email, 'john.doe@example.com');
        expect(profile.displayName, 'John Doe');
        expect(profile.createdAt, DateTime(2024, 1, 1, 10, 0));
        expect(profile.lastActiveAt, DateTime(2024, 1, 15, 10, 30));
      });

      test('should create UserProfile with optional properties', () {
        final profile = UserProfile(
          id: 'user_456',
          email: 'jane.smith@example.com',
          displayName: 'Jane Smith',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
          firstName: 'Jane',
          lastName: 'Smith',
          avatar: 'https://example.com/avatar.jpg',
          bio: 'Environmental enthusiast and waste reduction advocate',
          location: 'San Francisco, CA',
          dateOfBirth: DateTime(1990, 5, 15),
          phoneNumber: '+1-555-123-4567',
          preferences: UserPreferences(
            theme: 'dark',
            language: 'en',
            notifications: true,
            emailUpdates: false,
            privacyLevel: PrivacyLevel.friends,
          ),
          statistics: UserStatistics(
            totalClassifications: 150,
            accurateClassifications: 142,
            streakDays: 12,
            pointsEarned: 1250,
            badgesEarned: 5,
            level: 8,
          ),
          familyId: 'family_789',
          isPremium: true,
          premiumExpiresAt: DateTime(2024, 12, 31),
          isEmailVerified: true,
          isPhoneVerified: false,
          accountStatus: AccountStatus.active,
          roles: [UserRole.member, UserRole.contributor],
          achievements: ['first_classification', 'week_streak', 'eco_warrior'],
          socialLinks: {
            'twitter': '@janedoe',
            'instagram': 'jane.eco.warrior',
          },
          settings: UserSettings(
            enableAnalytics: true,
            enableLocationServices: false,
            autoBackup: true,
            syncAcrossDevices: true,
          ),
        );

        expect(profile.firstName, 'Jane');
        expect(profile.lastName, 'Smith');
        expect(profile.avatar, 'https://example.com/avatar.jpg');
        expect(profile.bio, 'Environmental enthusiast and waste reduction advocate');
        expect(profile.location, 'San Francisco, CA');
        expect(profile.dateOfBirth, DateTime(1990, 5, 15));
        expect(profile.phoneNumber, '+1-555-123-4567');
        expect(profile.preferences?.theme, 'dark');
        expect(profile.statistics?.totalClassifications, 150);
        expect(profile.familyId, 'family_789');
        expect(profile.isPremium, true);
        expect(profile.isEmailVerified, true);
        expect(profile.accountStatus, AccountStatus.active);
        expect(profile.roles, contains(UserRole.member));
        expect(profile.achievements, contains('eco_warrior'));
        expect(profile.socialLinks?['twitter'], '@janedoe');
        expect(profile.settings?.enableAnalytics, true);
      });

      test('should serialize UserProfile to JSON correctly', () {
        final profile = UserProfile(
          id: 'user_789',
          email: 'alice.brown@example.com',
          displayName: 'Alice Brown',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
          firstName: 'Alice',
          lastName: 'Brown',
          avatar: 'https://example.com/alice.jpg',
          bio: 'Sustainability expert',
          location: 'New York, NY',
          isPremium: true,
          isEmailVerified: true,
          accountStatus: AccountStatus.active,
          roles: [UserRole.moderator],
        );

        final json = profile.toJson();

        expect(json['id'], 'user_789');
        expect(json['email'], 'alice.brown@example.com');
        expect(json['displayName'], 'Alice Brown');
        expect(json['createdAt'], isA<String>());
        expect(json['lastActiveAt'], isA<String>());
        expect(json['firstName'], 'Alice');
        expect(json['lastName'], 'Brown');
        expect(json['avatar'], 'https://example.com/alice.jpg');
        expect(json['bio'], 'Sustainability expert');
        expect(json['location'], 'New York, NY');
        expect(json['isPremium'], true);
        expect(json['isEmailVerified'], true);
        expect(json['accountStatus'], 'active');
        expect(json['roles'], ['moderator']);
      });

      test('should deserialize UserProfile from JSON correctly', () {
        final json = {
          'id': 'user_012',
          'email': 'bob.wilson@example.com',
          'displayName': 'Bob Wilson',
          'createdAt': '2024-01-01T10:00:00.000',
          'lastActiveAt': '2024-01-15T10:30:00.000',
          'firstName': 'Bob',
          'lastName': 'Wilson',
          'avatar': 'https://example.com/bob.jpg',
          'bio': 'Waste reduction advocate',
          'location': 'Austin, TX',
          'dateOfBirth': '1985-03-20T00:00:00.000',
          'phoneNumber': '+1-555-987-6543',
          'familyId': 'family_456',
          'isPremium': false,
          'isEmailVerified': true,
          'isPhoneVerified': false,
          'accountStatus': 'active',
          'roles': ['member', 'contributor'],
          'achievements': ['first_classification', 'week_streak'],
          'socialLinks': {
            'linkedin': 'bobwilson',
          },
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'user_012');
        expect(profile.email, 'bob.wilson@example.com');
        expect(profile.displayName, 'Bob Wilson');
        expect(profile.createdAt, DateTime(2024, 1, 1, 10, 0));
        expect(profile.lastActiveAt, DateTime(2024, 1, 15, 10, 30));
        expect(profile.firstName, 'Bob');
        expect(profile.lastName, 'Wilson');
        expect(profile.avatar, 'https://example.com/bob.jpg');
        expect(profile.bio, 'Waste reduction advocate');
        expect(profile.location, 'Austin, TX');
        expect(profile.dateOfBirth, DateTime(1985, 3, 20));
        expect(profile.phoneNumber, '+1-555-987-6543');
        expect(profile.familyId, 'family_456');
        expect(profile.isPremium, false);
        expect(profile.isEmailVerified, true);
        expect(profile.isPhoneVerified, false);
        expect(profile.accountStatus, AccountStatus.active);
        expect(profile.roles, [UserRole.member, UserRole.contributor]);
        expect(profile.achievements, ['first_classification', 'week_streak']);
        expect(profile.socialLinks?['linkedin'], 'bobwilson');
      });

      test('should calculate user age correctly', () {
        final profile = UserProfile(
          id: 'user_age_test',
          email: 'test@example.com',
          displayName: 'Age Test',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          dateOfBirth: DateTime(1990, 6, 15),
        );

        final expectedAge = DateTime.now().year - 1990;
        // Account for birthday not having occurred this year yet
        final actualAge = profile.age;
        
        expect(actualAge, anyOf(expectedAge - 1, expectedAge));
      });

      test('should handle missing date of birth for age calculation', () {
        final profile = UserProfile(
          id: 'user_no_dob',
          email: 'test@example.com',
          displayName: 'No DOB',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        expect(profile.age, null);
      });

      test('should calculate account age correctly', () {
        final profile = UserProfile(
          id: 'user_account_age',
          email: 'test@example.com',
          displayName: 'Account Age Test',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          lastActiveAt: DateTime.now(),
        );

        expect(profile.accountAgeInDays, 365);
      });

      test('should check if user is recently active', () {
        final recentlyActiveProfile = UserProfile(
          id: 'user_recent',
          email: 'recent@example.com',
          displayName: 'Recently Active',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        final inactiveProfile = UserProfile(
          id: 'user_inactive',
          email: 'inactive@example.com',
          displayName: 'Inactive User',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastActiveAt: DateTime.now().subtract(const Duration(days: 15)),
        );

        expect(recentlyActiveProfile.isRecentlyActive, true);
        expect(inactiveProfile.isRecentlyActive, false);
      });

      test('should check if user is new user', () {
        final newProfile = UserProfile(
          id: 'user_new',
          email: 'new@example.com',
          displayName: 'New User',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          lastActiveAt: DateTime.now(),
        );

        final oldProfile = UserProfile(
          id: 'user_old',
          email: 'old@example.com',
          displayName: 'Old User',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          lastActiveAt: DateTime.now(),
        );

        expect(newProfile.isNewUser, true);
        expect(oldProfile.isNewUser, false);
      });

      test('should get full name correctly', () {
        final profileWithBothNames = UserProfile(
          id: 'user_full_name',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          firstName: 'John',
          lastName: 'Doe',
        );

        final profileWithDisplayName = UserProfile(
          id: 'user_display_name',
          email: 'test@example.com',
          displayName: 'Jane Smith',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        expect(profileWithBothNames.fullName, 'John Doe');
        expect(profileWithDisplayName.fullName, 'Jane Smith');
      });

      test('should get initials correctly', () {
        final profile = UserProfile(
          id: 'user_initials',
          email: 'test@example.com',
          displayName: 'John Doe',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(profile.initials, 'JD');
      });

      test('should handle single name for initials', () {
        final profile = UserProfile(
          id: 'user_single_name',
          email: 'test@example.com',
          displayName: 'Madonna',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        expect(profile.initials, 'M');
      });

      test('should check premium status correctly', () {
        final premiumProfile = UserProfile(
          id: 'user_premium',
          email: 'premium@example.com',
          displayName: 'Premium User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isPremium: true,
          premiumExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        final expiredPremiumProfile = UserProfile(
          id: 'user_expired_premium',
          email: 'expired@example.com',
          displayName: 'Expired Premium',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isPremium: true,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        final freeProfile = UserProfile(
          id: 'user_free',
          email: 'free@example.com',
          displayName: 'Free User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isPremium: false,
        );

        expect(premiumProfile.isActivePremium, true);
        expect(expiredPremiumProfile.isActivePremium, false);
        expect(freeProfile.isActivePremium, false);
      });

      test('should calculate days until premium expires', () {
        final premiumProfile = UserProfile(
          id: 'user_premium_expiry',
          email: 'premium@example.com',
          displayName: 'Premium User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isPremium: true,
          premiumExpiresAt: DateTime.now().add(const Duration(days: 15)),
        );

        expect(premiumProfile.daysUntilPremiumExpires, 15);
      });

      test('should check verification status', () {
        final fullyVerifiedProfile = UserProfile(
          id: 'user_verified',
          email: 'verified@example.com',
          displayName: 'Verified User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isEmailVerified: true,
          isPhoneVerified: true,
        );

        final partiallyVerifiedProfile = UserProfile(
          id: 'user_partial_verified',
          email: 'partial@example.com',
          displayName: 'Partial Verified',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isEmailVerified: true,
          isPhoneVerified: false,
        );

        final unverifiedProfile = UserProfile(
          id: 'user_unverified',
          email: 'unverified@example.com',
          displayName: 'Unverified User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isEmailVerified: false,
          isPhoneVerified: false,
        );

        expect(fullyVerifiedProfile.isFullyVerified, true);
        expect(partiallyVerifiedProfile.isFullyVerified, false);
        expect(unverifiedProfile.isFullyVerified, false);
      });

      test('should check user permissions based on roles', () {
        final adminProfile = UserProfile(
          id: 'user_admin',
          email: 'admin@example.com',
          displayName: 'Admin User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          roles: [UserRole.admin],
        );

        final moderatorProfile = UserProfile(
          id: 'user_moderator',
          email: 'mod@example.com',
          displayName: 'Moderator User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          roles: [UserRole.moderator],
        );

        final memberProfile = UserProfile(
          id: 'user_member',
          email: 'member@example.com',
          displayName: 'Member User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          roles: [UserRole.member],
        );

        expect(adminProfile.hasRole(UserRole.admin), true);
        expect(adminProfile.canModerate, true);
        expect(moderatorProfile.canModerate, true);
        expect(memberProfile.canModerate, false);
      });

      test('should calculate completion percentage', () {
        final completeProfile = UserProfile(
          id: 'user_complete',
          email: 'complete@example.com',
          displayName: 'Complete User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          firstName: 'John',
          lastName: 'Doe',
          avatar: 'https://example.com/avatar.jpg',
          bio: 'Complete bio',
          location: 'City, State',
          dateOfBirth: DateTime(1990, 1, 1),
          phoneNumber: '+1-555-123-4567',
        );

        final incompleteProfile = UserProfile(
          id: 'user_incomplete',
          email: 'incomplete@example.com',
          displayName: 'Incomplete User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        expect(completeProfile.profileCompletionPercentage, greaterThan(0.8));
        expect(incompleteProfile.profileCompletionPercentage, lessThan(0.5));
      });
    });

    group('UserPreferences Model', () {
      test('should create UserPreferences with all properties', () {
        final preferences = UserPreferences(
          theme: 'dark',
          language: 'en',
          notifications: true,
          emailUpdates: false,
          privacyLevel: PrivacyLevel.friends,
        );

        expect(preferences.theme, 'dark');
        expect(preferences.language, 'en');
        expect(preferences.notifications, true);
        expect(preferences.emailUpdates, false);
        expect(preferences.privacyLevel, PrivacyLevel.friends);
      });

      test('should create default preferences', () {
        final defaultPrefs = UserPreferences.defaultPreferences();

        expect(defaultPrefs.theme, 'light');
        expect(defaultPrefs.language, 'en');
        expect(defaultPrefs.notifications, true);
        expect(defaultPrefs.emailUpdates, true);
        expect(defaultPrefs.privacyLevel, PrivacyLevel.public);
      });

      test('should serialize UserPreferences to JSON correctly', () {
        final preferences = UserPreferences(
          theme: 'dark',
          language: 'es',
          notifications: false,
          emailUpdates: true,
          privacyLevel: PrivacyLevel.private,
        );

        final json = preferences.toJson();

        expect(json['theme'], 'dark');
        expect(json['language'], 'es');
        expect(json['notifications'], false);
        expect(json['emailUpdates'], true);
        expect(json['privacyLevel'], 'private');
      });
    });

    group('UserStatistics Model', () {
      test('should create UserStatistics with all properties', () {
        final stats = UserStatistics(
          totalClassifications: 150,
          accurateClassifications: 142,
          streakDays: 12,
          pointsEarned: 1250,
          badgesEarned: 5,
          level: 8,
        );

        expect(stats.totalClassifications, 150);
        expect(stats.accurateClassifications, 142);
        expect(stats.streakDays, 12);
        expect(stats.pointsEarned, 1250);
        expect(stats.badgesEarned, 5);
        expect(stats.level, 8);
      });

      test('should calculate accuracy rate correctly', () {
        final stats = UserStatistics(
          totalClassifications: 100,
          accurateClassifications: 85,
          streakDays: 5,
          pointsEarned: 500,
          badgesEarned: 3,
          level: 5,
        );

        expect(stats.accuracyRate, 0.85);
      });

      test('should handle zero classifications gracefully', () {
        final stats = UserStatistics(
          totalClassifications: 0,
          accurateClassifications: 0,
          streakDays: 0,
          pointsEarned: 0,
          badgesEarned: 0,
          level: 1,
        );

        expect(stats.accuracyRate, 0.0);
      });

      test('should serialize UserStatistics to JSON correctly', () {
        final stats = UserStatistics(
          totalClassifications: 75,
          accurateClassifications: 68,
          streakDays: 8,
          pointsEarned: 625,
          badgesEarned: 4,
          level: 6,
        );

        final json = stats.toJson();

        expect(json['totalClassifications'], 75);
        expect(json['accurateClassifications'], 68);
        expect(json['streakDays'], 8);
        expect(json['pointsEarned'], 625);
        expect(json['badgesEarned'], 4);
        expect(json['level'], 6);
      });
    });

    group('UserSettings Model', () {
      test('should create UserSettings with all properties', () {
        final settings = UserSettings(
          enableAnalytics: true,
          enableLocationServices: false,
          autoBackup: true,
          syncAcrossDevices: true,
        );

        expect(settings.enableAnalytics, true);
        expect(settings.enableLocationServices, false);
        expect(settings.autoBackup, true);
        expect(settings.syncAcrossDevices, true);
      });

      test('should create default settings', () {
        final defaultSettings = UserSettings.defaultSettings();

        expect(defaultSettings.enableAnalytics, false);
        expect(defaultSettings.enableLocationServices, false);
        expect(defaultSettings.autoBackup, true);
        expect(defaultSettings.syncAcrossDevices, false);
      });

      test('should serialize UserSettings to JSON correctly', () {
        final settings = UserSettings(
          enableAnalytics: false,
          enableLocationServices: true,
          autoBackup: false,
          syncAcrossDevices: true,
        );

        final json = settings.toJson();

        expect(json['enableAnalytics'], false);
        expect(json['enableLocationServices'], true);
        expect(json['autoBackup'], false);
        expect(json['syncAcrossDevices'], true);
      });
    });

    group('Enums and Types', () {
      test('should handle all account statuses', () {
        expect(AccountStatus.active.displayName, 'Active');
        expect(AccountStatus.inactive.displayName, 'Inactive');
        expect(AccountStatus.suspended.displayName, 'Suspended');
        expect(AccountStatus.banned.displayName, 'Banned');
        expect(AccountStatus.pending.displayName, 'Pending Verification');
      });

      test('should handle all user roles', () {
        expect(UserRole.guest.displayName, 'Guest');
        expect(UserRole.member.displayName, 'Member');
        expect(UserRole.contributor.displayName, 'Contributor');
        expect(UserRole.moderator.displayName, 'Moderator');
        expect(UserRole.admin.displayName, 'Administrator');
      });

      test('should handle all privacy levels', () {
        expect(PrivacyLevel.public.displayName, 'Public');
        expect(PrivacyLevel.friends.displayName, 'Friends Only');
        expect(PrivacyLevel.family.displayName, 'Family Only');
        expect(PrivacyLevel.private.displayName, 'Private');
      });

      test('should check role hierarchy', () {
        expect(UserRole.admin.level > UserRole.moderator.level, true);
        expect(UserRole.moderator.level > UserRole.contributor.level, true);
        expect(UserRole.contributor.level > UserRole.member.level, true);
        expect(UserRole.member.level > UserRole.guest.level, true);
      });
    });

    group('Validation', () {
      test('should validate required fields', () {
        expect(() => UserProfile(
          id: '', // Empty ID
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ), throwsArgumentError);

        expect(() => UserProfile(
          id: 'user_123',
          email: '', // Empty email
          displayName: 'Test User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ), throwsArgumentError);

        expect(() => UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          displayName: '', // Empty display name
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ), throwsArgumentError);
      });

      test('should validate email format', () {
        expect(() => UserProfile(
          id: 'user_123',
          email: 'invalid_email', // Invalid email format
          displayName: 'Test User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ), throwsArgumentError);

        // Valid email should not throw
        expect(() => UserProfile(
          id: 'user_123',
          email: 'valid@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ), returnsNormally);
      });

      test('should validate statistics values', () {
        expect(() => UserStatistics(
          totalClassifications: -5, // Negative value
          accurateClassifications: 10,
          streakDays: 5,
          pointsEarned: 100,
          badgesEarned: 2,
          level: 3,
        ), throwsArgumentError);

        expect(() => UserStatistics(
          totalClassifications: 10,
          accurateClassifications: 15, // More accurate than total
          streakDays: 5,
          pointsEarned: 100,
          badgesEarned: 2,
          level: 3,
        ), throwsArgumentError);
      });
    });

    group('Copy and Update', () {
      test('should create copy with updated properties', () {
        final original = UserProfile(
          id: 'user_original',
          email: 'original@example.com',
          displayName: 'Original User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now().subtract(const Duration(hours: 1)),
          isPremium: false,
        );

        final updated = original.copyWith(
          displayName: 'Updated User',
          lastActiveAt: DateTime.now(),
          isPremium: true,
          premiumExpiresAt: DateTime.now().add(const Duration(days: 365)),
        );

        expect(updated.id, original.id);
        expect(updated.email, original.email);
        expect(updated.displayName, 'Updated User');
        expect(updated.isPremium, true);
        expect(updated.premiumExpiresAt, isNotNull);
        expect(original.displayName, 'Original User'); // Original unchanged
        expect(original.isPremium, false); // Original unchanged
      });
    });

    group('Equality and Comparison', () {
      test('should compare UserProfile for equality', () {
        final profile1 = UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
        );

        final profile2 = UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
        );

        final profile3 = UserProfile(
          id: 'user_456',
          email: 'different@example.com',
          displayName: 'Different User',
          createdAt: DateTime(2024, 1, 2, 10, 0),
          lastActiveAt: DateTime(2024, 1, 16, 10, 30),
        );

        expect(profile1 == profile2, true);
        expect(profile1 == profile3, false);
        expect(profile1.hashCode == profile2.hashCode, true);
      });

      test('should sort profiles by level', () {
        final profiles = [
          UserProfile(
            id: 'user1', email: 'user1@example.com', displayName: 'User 1',
            createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
            statistics: UserStatistics(
              totalClassifications: 50, accurateClassifications: 45,
              streakDays: 5, pointsEarned: 250, badgesEarned: 2, level: 3,
            ),
          ),
          UserProfile(
            id: 'user2', email: 'user2@example.com', displayName: 'User 2',
            createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
            statistics: UserStatistics(
              totalClassifications: 100, accurateClassifications: 95,
              streakDays: 10, pointsEarned: 500, badgesEarned: 5, level: 7,
            ),
          ),
          UserProfile(
            id: 'user3', email: 'user3@example.com', displayName: 'User 3',
            createdAt: DateTime.now(), lastActiveAt: DateTime.now(),
            statistics: UserStatistics(
              totalClassifications: 25, accurateClassifications: 20,
              streakDays: 3, pointsEarned: 125, badgesEarned: 1, level: 2,
            ),
          ),
        ];

        profiles.sort((a, b) => (b.statistics?.level ?? 0).compareTo(a.statistics?.level ?? 0));

        expect(profiles[0].statistics?.level, 7);
        expect(profiles[1].statistics?.level, 3);
        expect(profiles[2].statistics?.level, 2);
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final profile = UserProfile(
          id: 'user_123',
          email: 'john.doe@example.com',
          displayName: 'John Doe',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          lastActiveAt: DateTime(2024, 1, 15, 10, 30),
          firstName: 'John',
          lastName: 'Doe',
        );

        final stringRepresentation = profile.toString();

        expect(stringRepresentation, contains('user_123'));
        expect(stringRepresentation, contains('John Doe'));
        expect(stringRepresentation, contains('john.doe@example.com'));
      });
    });
  });
}
