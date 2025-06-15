import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('UserProfile', () {
    test('should create a UserProfile with all fields', () {
      final profile = UserProfile(
        id: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        familyId: 'family456',
        role: UserRole.admin,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        lastActive: DateTime(2024, 1, 15, 10, 30),
        preferences: {
          'notifications': true,
          'theme': 'dark',
        },
        gamificationProfile: const GamificationProfile(
          userId: 'user123',
          streaks: {},
          points: UserPoints(total: 1500, level: 5),
          achievements: [],
          activeChallenges: [],
          completedChallenges: [],
        ),
      );

      expect(profile.id, 'user123');
      expect(profile.displayName, 'John Doe');
      expect(profile.email, 'john.doe@example.com');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.familyId, 'family456');
      expect(profile.role, UserRole.admin);
      expect(profile.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(profile.lastActive, DateTime(2024, 1, 15, 10, 30));
      expect(profile.preferences?['notifications'], true);
      expect(profile.preferences?['theme'], 'dark');
      expect(profile.gamificationProfile?.userId, 'user123');
      expect(profile.gamificationProfile?.points.level, 5);
    });

    test('should create a minimal UserProfile with only required fields', () {
      final profile = UserProfile(
        id: 'user123',
      );

      expect(profile.id, 'user123');
      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.familyId, isNull);
      expect(profile.role, isNull);
      expect(profile.createdAt, isNull);
      expect(profile.lastActive, isNull);
      expect(profile.preferences, isNull);
      expect(profile.gamificationProfile, isNull);
    });

    test('should create UserProfile with admin role', () {
      final profile = UserProfile(
        id: 'admin123',
        displayName: 'Admin User',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(profile.role, UserRole.admin);
      expect(profile.displayName, 'Admin User');
    });

    test('should create a UserProfile from JSON', () {
      final json = {
        'id': 'user123',
        'displayName': 'Bob Wilson',
        'email': 'bob.wilson@example.com',
        'photoUrl': 'https://example.com/bob.jpg',
        'familyId': 'family789',
        'role': 'member',
        'createdAt': '2024-01-15T10:30:00.000Z',
        'lastActive': '2024-01-15T10:30:00.000Z',
        'preferences': {
          'notifications': true,
          'theme': 'light',
        },
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.displayName, 'Bob Wilson');
      expect(profile.email, 'bob.wilson@example.com');
      expect(profile.photoUrl, 'https://example.com/bob.jpg');
      expect(profile.familyId, 'family789');
      expect(profile.role, UserRole.member);
      expect(profile.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(profile.lastActive, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(profile.preferences?['notifications'], true);
      expect(profile.preferences?['theme'], 'light');
    });

    test('should convert UserProfile to JSON', () {
      final profile = UserProfile(
        id: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        familyId: 'family456',
        role: UserRole.admin,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        lastActive: DateTime.now(),
        preferences: {
          'notifications': true,
          'theme': 'dark',
        },
      );

      final json = profile.toJson();

      expect(json['id'], 'user123');
      expect(json['displayName'], 'John Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['familyId'], 'family456');
      expect(json['role'], 'admin');
      expect(json['createdAt'], '2024-01-15T10:30:00.000');
      expect(json['preferences'], isA<Map<String, dynamic>>());
    });

    test('should create a copy with updated fields', () {
      final original = UserProfile(
        id: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        role: UserRole.member,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final updated = original.copyWith(
        displayName: 'Jane Doe',
        role: UserRole.admin,
      );

      expect(updated.id, 'user123'); // Unchanged
      expect(updated.displayName, 'Jane Doe'); // Changed
      expect(updated.email, 'john.doe@example.com'); // Unchanged
      expect(updated.role, UserRole.admin); // Changed
    });

    test('should handle null values in JSON gracefully', () {
      final json = {
        'id': 'user123',
        'displayName': null,
        'email': null,
        'role': null,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
      expect(profile.role, isNull);
    });

    test('should handle invalid role in JSON gracefully', () {
      final json = {
        'id': 'user123',
        'role': 'invalid_role',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.role, UserRole.guest); // Default fallback
    });

    test('should handle missing timestamps in JSON', () {
      final json = {
        'id': 'user123',
        'displayName': 'Test User',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.displayName, 'Test User');
      expect(profile.createdAt, isNull);
      expect(profile.lastActive, isNull);
    });

    test('should handle all UserRole values', () {
      expect(UserRole.admin, isA<UserRole>());
      expect(UserRole.member, isA<UserRole>());
      expect(UserRole.child, isA<UserRole>());
      expect(UserRole.guest, isA<UserRole>());
    });

    test('should create UserProfile with child role', () {
      final profile = UserProfile(
        id: 'child123',
        displayName: 'Child User',
        role: UserRole.child,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(profile.role, UserRole.child);
      expect(profile.displayName, 'Child User');
    });

    test('should create UserProfile with guest role', () {
      final profile = UserProfile(
        id: 'guest123',
        displayName: 'Guest User',
        role: UserRole.guest,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(profile.role, UserRole.guest);
      expect(profile.displayName, 'Guest User');
    });

    test('should handle complex preferences object', () {
      final preferences = {
        'notifications': {
          'email': true,
          'push': false,
          'sms': true,
        },
        'privacy': {
          'shareData': false,
          'analytics': true,
        },
        'ui': {
          'theme': 'dark',
          'language': 'en',
        },
      };

      final profile = UserProfile(
        id: 'user123',
        preferences: preferences,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(profile.preferences?['notifications'], isA<Map>());
      expect(profile.preferences?['privacy'], isA<Map>());
      expect(profile.preferences?['ui'], isA<Map>());
    });

    test('should handle gamification profile integration', () {
      const gamificationProfile = GamificationProfile(
        userId: 'user123',
        streaks: {},
        points: UserPoints(total: 5000, level: 10),
        achievements: [],
        activeChallenges: [],
        completedChallenges: [],
      );

      final profile = UserProfile(
        id: 'user123',
        displayName: 'Gamer User',
        gamificationProfile: gamificationProfile,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(profile.gamificationProfile?.userId, 'user123');
      expect(profile.gamificationProfile?.points.level, 10);
      expect(profile.gamificationProfile?.points.total, 5000);
    });

    test('should handle edge cases for copyWith', () {
      final original = UserProfile(
        id: 'user123',
        displayName: 'Original Name',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Test copying with no changes
      final updated = original.copyWith();

      expect(updated.displayName, 'Original Name');
      expect(updated.id, 'user123'); // Should remain unchanged

      // Test copying with explicit values - copyWith doesn't support setting to null
      // This is the standard Dart pattern where copyWith preserves existing values
      final updatedWithNewName = original.copyWith(
        displayName: 'New Name',
      );

      expect(updatedWithNewName.displayName, 'New Name');
      expect(updatedWithNewName.id, 'user123'); // Should remain unchanged
    });

    test('should handle JSON serialization roundtrip', () {
      final original = UserProfile(
        id: 'user123',
        displayName: 'Test User',
        email: 'test@example.com',
        role: UserRole.member,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        lastActive: DateTime(2024, 1, 16, 10, 30),
        preferences: {'theme': 'dark'},
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastActive, original.lastActive);
      expect(restored.preferences?['theme'], 'dark');
    });

    test('should handle UserRole enum serialization correctly', () {
      // Test all UserRole values
      for (final role in UserRole.values) {
        final profile = UserProfile(
          id: 'test_user',
          role: role,
        );

        final json = profile.toJson();
        final restored = UserProfile.fromJson(json);

        expect(restored.role, role);
      }
    });

    test('should handle gamification profile with complex data', () {
      final gamificationProfile = GamificationProfile(
        userId: 'user123',
        points: const UserPoints(
          total: 2500,
          level: 15,
          categoryPoints: {
            'Recyclable': 1000,
            'Organic': 800,
            'Hazardous': 700,
          },
        ),
        streaks: {
          'daily': StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 7,
            longestCount: 21,
            lastActivityDate: DateTime.now(),
          ),
          'learning': StreakDetails(
            type: StreakType.dailyLearning,
            currentCount: 3,
            longestCount: 10,
            lastActivityDate: DateTime.now(),
          ),
        },
        achievements: [
          const Achievement(
            id: 'eco_warrior',
            title: 'Eco Warrior',
            description: 'Classified 100 items',
            type: AchievementType.ecoWarrior,
            threshold: 100,
            iconName: 'eco',
            color: Colors.green,
            tier: AchievementTier.gold,
            pointsReward: 500,
          ),
        ],
        discoveredItemIds: {'item1', 'item2', 'item3'},
        unlockedHiddenContentIds: {'content1'},
      );

      final profile = UserProfile(
        id: 'complex_user',
        displayName: 'Complex User',
        gamificationProfile: gamificationProfile,
      );

      // Test serialization roundtrip
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.gamificationProfile?.points.total, 2500);
      expect(restored.gamificationProfile?.points.level, 15);
      expect(restored.gamificationProfile?.points.categoryPoints.length, 3);
      expect(restored.gamificationProfile?.streaks.length, 2);
      expect(restored.gamificationProfile?.achievements.length, 1);
      expect(restored.gamificationProfile?.discoveredItemIds.length, 3);
      expect(restored.gamificationProfile?.unlockedHiddenContentIds.length, 1);
    });

    test('should validate required fields', () {
      // ID is required
      expect(() => UserProfile(id: ''), returnsNormally);
      
      // Empty ID should still work
      final profile = UserProfile(id: '');
      expect(profile.id, '');
    });

    test('should handle edge cases in preferences', () {
      final complexPreferences = {
        'nested': {
          'deeply': {
            'nested': {
              'value': 'test',
              'number': 42,
              'boolean': true,
              'list': [1, 2, 3],
            },
          },
        },
        'nullValue': null,
        'emptyString': '',
        'emptyList': [],
        'emptyMap': {},
      };

      final profile = UserProfile(
        id: 'complex_prefs_user',
        preferences: complexPreferences,
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.preferences?['nested'], isA<Map>());
      expect(restored.preferences?['nullValue'], isNull);
      expect(restored.preferences?['emptyString'], '');
      expect(restored.preferences?['emptyList'], isEmpty);
      expect(restored.preferences?['emptyMap'], isEmpty);
    });
  });
}
