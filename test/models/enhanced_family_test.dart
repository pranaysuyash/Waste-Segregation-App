import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart';
import '../test_helper.dart';

void main() {
  group('Enhanced Family Model Tests', () {
    late DateTime testDateTime;
    late FamilyMember testMember;
    late UserStats testUserStats;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      testDateTime = DateTime.parse('2024-01-15T10:30:00Z');
      testUserStats = UserStats(
        totalPoints: 100,
        totalClassifications: 25,
        currentStreak: 5,
        bestStreak: 10,
        categoryBreakdown: {'Dry Waste': 15, 'Wet Waste': 10},
        achievements: ['first_classification', 'week_streak'],
        lastActive: testDateTime,
      );
      testMember = FamilyMember(
        userId: 'user_123',
        role: UserRole.admin,
        joinedAt: testDateTime,
        individualStats: testUserStats,
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );
    });

    group('Family Class Tests', () {
      test('should create Family with all required fields', () {
        final family = Family(
          id: 'family_123',
          name: 'Test Family',
          description: 'A test family for waste management',
          createdBy: 'user_123',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          members: [testMember],
          imageUrl: 'https://example.com/family.jpg',
          isPublic: true,
        );

        expect(family.id, equals('family_123'));
        expect(family.name, equals('Test Family'));
        expect(family.description, equals('A test family for waste management'));
        expect(family.createdBy, equals('user_123'));
        expect(family.createdAt, equals(testDateTime));
        expect(family.updatedAt, equals(testDateTime));
        expect(family.members.length, equals(1));
        expect(family.settings, isA<FamilySettings>());
        expect(family.imageUrl, equals('https://example.com/family.jpg'));
        expect(family.isPublic, isTrue);
      });

      test('should create Family with default values', () {
        final family = Family(
          id: 'family_456',
          name: 'Minimal Family',
          createdBy: 'user_456',
          createdAt: testDateTime,
        );

        expect(family.id, equals('family_456'));
        expect(family.name, equals('Minimal Family'));
        expect(family.description, isNull);
        expect(family.updatedAt, isNull);
        expect(family.members, isEmpty);
        expect(family.settings, equals(const FamilySettings()));
        expect(family.imageUrl, isNull);
        expect(family.isPublic, isFalse);
      });

      test('should create Family using factory constructor', () {
        final adminMember = FamilyMember(
          userId: 'admin_123',
          role: UserRole.admin,
          joinedAt: testDateTime,
          individualStats: testUserStats,
          displayName: 'Admin User',
        );

        final family = Family.create(
          name: 'New Family',
          createdBy: 'admin_123',
          admin: adminMember,
        );

        expect(family.id, isNotEmpty);
        expect(family.name, equals('New Family'));
        expect(family.createdBy, equals('admin_123'));
        expect(family.members.length, equals(1));
        expect(family.members.first.userId, equals('admin_123'));
        expect(family.members.first.role, equals(UserRole.admin));
        expect(family.settings, equals(FamilySettings.defaultSettings()));
      });

      test('should serialize and deserialize Family correctly', () {
        final original = Family(
          id: 'family_serialize',
          name: 'Serialization Test Family',
          description: 'Testing JSON serialization',
          createdBy: 'user_serialize',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          members: [testMember],
          settings: const FamilySettings(isPublic: true, shareClassifications: false),
          imageUrl: 'https://example.com/serialize.jpg',
          isPublic: true,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['id'], equals('family_serialize'));
        expect(json['name'], equals('Serialization Test Family'));
        expect(json['description'], equals('Testing JSON serialization'));
        expect(json['createdAt'], equals(testDateTime.toIso8601String()));
        expect(json['members'], isA<List>());
        expect(json['settings'], isA<Map<String, dynamic>>());
        expect(json['isPublic'], isTrue);

        // Test fromJson
        final recreated = Family.fromJson(json);
        expect(recreated.id, equals(original.id));
        expect(recreated.name, equals(original.name));
        expect(recreated.description, equals(original.description));
        expect(recreated.createdBy, equals(original.createdBy));
        expect(recreated.createdAt, equals(original.createdAt));
        expect(recreated.updatedAt, equals(original.updatedAt));
        expect(recreated.members.length, equals(original.members.length));
        expect(recreated.isPublic, equals(original.isPublic));
      });

      test('should handle member management methods correctly', () {
        final member1 = testMember;
        final member2 = FamilyMember(
          userId: 'user_456',
          role: UserRole.member,
          joinedAt: testDateTime,
          individualStats: testUserStats,
          displayName: 'Second User',
        );

        final family = Family(
          id: 'family_members',
          name: 'Member Test Family',
          createdBy: 'user_123',
          createdAt: testDateTime,
          members: [member1, member2],
        );

        // Test hasMember
        expect(family.hasMember('user_123'), isTrue);
        expect(family.hasMember('user_456'), isTrue);
        expect(family.hasMember('user_999'), isFalse);

        // Test getMember
        final foundMember = family.getMember('user_123');
        expect(foundMember, isNotNull);
        expect(foundMember!.userId, equals('user_123'));
        expect(foundMember.role, equals(UserRole.admin));

        final notFoundMember = family.getMember('user_999');
        expect(notFoundMember, isNull);

        // Test getAdmins
        final admins = family.getAdmins();
        expect(admins.length, equals(1));
        expect(admins.first.userId, equals('user_123'));
        expect(admins.first.role, equals(UserRole.admin));
      });

      test('should copyWith correctly', () {
        final original = Family(
          id: 'family_copy',
          name: 'Original Family',
          createdBy: 'user_123',
          createdAt: testDateTime,
          members: [testMember],
        );

        final updated = original.copyWith(
          name: 'Updated Family',
          description: 'New description',
          isPublic: true,
        );

        expect(updated.id, equals(original.id)); // Unchanged
        expect(updated.name, equals('Updated Family')); // Changed
        expect(updated.description, equals('New description')); // Changed
        expect(updated.createdBy, equals(original.createdBy)); // Unchanged
        expect(updated.members, equals(original.members)); // Unchanged
        expect(updated.isPublic, isTrue); // Changed
      });

      test('should handle missing fields in fromJson gracefully', () {
        final minimalJson = {
          'id': 'family_minimal',
          'name': 'Minimal Family',
          'createdBy': 'user_minimal',
          'createdAt': testDateTime.toIso8601String(),
        };

        final family = Family.fromJson(minimalJson);
        
        expect(family.id, equals('family_minimal'));
        expect(family.name, equals('Minimal Family'));
        expect(family.description, isNull);
        expect(family.updatedAt, isNull);
        expect(family.members, isEmpty);
        expect(family.settings, isA<FamilySettings>());
        expect(family.imageUrl, isNull);
        expect(family.isPublic, isFalse);
      });
    });

    group('FamilyMember Class Tests', () {
      test('should create FamilyMember with all fields', () {
        final member = FamilyMember(
          userId: 'member_test',
          role: UserRole.moderator,
          joinedAt: testDateTime,
          individualStats: testUserStats,
          displayName: 'Moderator User',
          photoUrl: 'https://example.com/moderator.jpg',
        );

        expect(member.userId, equals('member_test'));
        expect(member.role, equals(UserRole.moderator));
        expect(member.joinedAt, equals(testDateTime));
        expect(member.individualStats, equals(testUserStats));
        expect(member.displayName, equals('Moderator User'));
        expect(member.photoUrl, equals('https://example.com/moderator.jpg'));
      });

      test('should serialize and deserialize FamilyMember correctly', () {
        final original = FamilyMember(
          userId: 'member_serialize',
          role: UserRole.member,
          joinedAt: testDateTime,
          individualStats: testUserStats,
          displayName: 'Serialize Member',
          photoUrl: 'https://example.com/member.jpg',
        );

        // Test toJson
        final json = original.toJson();
        expect(json['userId'], equals('member_serialize'));
        expect(json['role'], equals('member'));
        expect(json['joinedAt'], equals(testDateTime.toIso8601String()));
        expect(json['individualStats'], isA<Map<String, dynamic>>());
        expect(json['displayName'], equals('Serialize Member'));
        expect(json['photoUrl'], equals('https://example.com/member.jpg'));

        // Test fromJson
        final recreated = FamilyMember.fromJson(json);
        expect(recreated.userId, equals(original.userId));
        expect(recreated.role, equals(original.role));
        expect(recreated.joinedAt, equals(original.joinedAt));
        expect(recreated.displayName, equals(original.displayName));
        expect(recreated.photoUrl, equals(original.photoUrl));
      });

      test('should handle invalid role in fromJson', () {
        final json = {
          'userId': 'member_invalid_role',
          'role': 'invalid_role',
          'joinedAt': testDateTime.toIso8601String(),
          'individualStats': testUserStats.toJson(),
        };

        final member = FamilyMember.fromJson(json);
        
        expect(member.userId, equals('member_invalid_role'));
        expect(member.role, equals(UserRole.member)); // Default fallback
      });

      test('should copyWith correctly', () {
        final original = FamilyMember(
          userId: 'member_copy',
          role: UserRole.member,
          joinedAt: testDateTime,
          individualStats: testUserStats,
          displayName: 'Original Member',
        );

        final updated = original.copyWith(
          role: UserRole.admin,
          displayName: 'Updated Member',
          photoUrl: 'https://example.com/updated.jpg',
        );

        expect(updated.userId, equals(original.userId)); // Unchanged
        expect(updated.role, equals(UserRole.admin)); // Changed
        expect(updated.joinedAt, equals(original.joinedAt)); // Unchanged
        expect(updated.displayName, equals('Updated Member')); // Changed
        expect(updated.photoUrl, equals('https://example.com/updated.jpg')); // Changed
      });
    });

    group('FamilySettings Class Tests', () {
      test('should create FamilySettings with all fields', () {
        final settings = FamilySettings(
          isPublic: true,
          allowChildInvites: true,
          shareClassifications: false,
          showMemberActivity: false,
          notifications: NotificationSettings.defaultSettings(),
          privacy: PrivacySettings.defaultSettings(),
          customSettings: {'theme': 'dark', 'language': 'en'},
          shareClassificationsPublicly: false,
          showMemberActivityInFeed: false,
          leaderboardVisibility: FamilyLeaderboardVisibility.public,
        );

        expect(settings.isPublic, isTrue);
        expect(settings.allowChildInvites, isTrue);
        expect(settings.shareClassifications, isFalse);
        expect(settings.showMemberActivity, isFalse);
        expect(settings.notifications, isNotNull);
        expect(settings.privacy, isNotNull);
        expect(settings.customSettings['theme'], equals('dark'));
        expect(settings.shareClassificationsPublicly, isFalse);
        expect(settings.showMemberActivityInFeed, isFalse);
        expect(settings.leaderboardVisibility, equals(FamilyLeaderboardVisibility.public));
      });

      test('should create default settings', () {
        final defaultSettings = FamilySettings.defaultSettings();
        
        expect(defaultSettings.isPublic, isFalse);
        expect(defaultSettings.allowChildInvites, isFalse);
        expect(defaultSettings.shareClassifications, isTrue);
        expect(defaultSettings.showMemberActivity, isTrue);
        expect(defaultSettings.customSettings, isEmpty);
      });

      test('should serialize and deserialize FamilySettings correctly', () {
        final original = FamilySettings(
          isPublic: true,
          notifications: NotificationSettings.defaultSettings(),
          privacy: PrivacySettings.defaultSettings(),
          customSettings: {'setting1': 'value1'},
        );

        // Test toJson
        final json = original.toJson();
        expect(json['isPublic'], isTrue);
        expect(json['allowChildInvites'], isFalse);
        expect(json['notifications'], isA<Map<String, dynamic>>());
        expect(json['privacy'], isA<Map<String, dynamic>>());
        expect(json['customSettings'], isA<Map<String, dynamic>>());
        expect(json['leaderboardVisibility'], contains('membersOnly'));

        // Test fromJson
        final recreated = FamilySettings.fromJson(json);
        expect(recreated.isPublic, equals(original.isPublic));
        expect(recreated.allowChildInvites, equals(original.allowChildInvites));
        expect(recreated.shareClassifications, equals(original.shareClassifications));
        expect(recreated.leaderboardVisibility, equals(original.leaderboardVisibility));
      });

      test('should copyWith correctly', () {
        const original = FamilySettings(
          allowChildInvites: false,
          customSettings: {'original': 'value'},
        );

        final updated = original.copyWith(
          isPublic: true,
          customSettings: {'updated': 'value'},
          leaderboardVisibility: FamilyLeaderboardVisibility.public,
        );

        expect(updated.isPublic, isTrue); // Changed
        expect(updated.allowChildInvites, equals(original.allowChildInvites)); // Unchanged
        expect(updated.shareClassifications, equals(original.shareClassifications)); // Unchanged
        expect(updated.customSettings['updated'], equals('value')); // Changed
        expect(updated.leaderboardVisibility, equals(FamilyLeaderboardVisibility.public)); // Changed
      });
    });

    group('NotificationSettings Class Tests', () {
      test('should create NotificationSettings with all fields', () {
        const settings = NotificationSettings(
          newMemberJoined: false,
          classificationShared: true,
          achievementUnlocked: false,
          weeklyReport: true,
          invitationReceived: false,
        );

        expect(settings.newMemberJoined, isFalse);
        expect(settings.classificationShared, isTrue);
        expect(settings.achievementUnlocked, isFalse);
        expect(settings.weeklyReport, isTrue);
        expect(settings.invitationReceived, isFalse);
      });

      test('should create default notification settings', () {
        final defaultSettings = NotificationSettings.defaultSettings();
        
        expect(defaultSettings.newMemberJoined, isTrue);
        expect(defaultSettings.classificationShared, isTrue);
        expect(defaultSettings.achievementUnlocked, isTrue);
        expect(defaultSettings.weeklyReport, isTrue);
        expect(defaultSettings.invitationReceived, isTrue);
      });

      test('should serialize and deserialize NotificationSettings correctly', () {
        const original = NotificationSettings(
          newMemberJoined: true,
          classificationShared: false,
          achievementUnlocked: true,
          weeklyReport: false,
          invitationReceived: true,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['newMemberJoined'], isTrue);
        expect(json['classificationShared'], isFalse);
        expect(json['achievementUnlocked'], isTrue);
        expect(json['weeklyReport'], isFalse);
        expect(json['invitationReceived'], isTrue);

        // Test fromJson
        final recreated = NotificationSettings.fromJson(json);
        expect(recreated.newMemberJoined, equals(original.newMemberJoined));
        expect(recreated.classificationShared, equals(original.classificationShared));
        expect(recreated.achievementUnlocked, equals(original.achievementUnlocked));
        expect(recreated.weeklyReport, equals(original.weeklyReport));
        expect(recreated.invitationReceived, equals(original.invitationReceived));
      });
    });

    group('PrivacySettings Class Tests', () {
      test('should create PrivacySettings with all fields', () {
        const settings = PrivacySettings(
          showLastSeen: false,
          showActivityStatus: true,
          allowSearchByName: false,
          blockedUsers: ['user_blocked1', 'user_blocked2'],
        );

        expect(settings.showLastSeen, isFalse);
        expect(settings.showActivityStatus, isTrue);
        expect(settings.allowSearchByName, isFalse);
        expect(settings.blockedUsers.length, equals(2));
        expect(settings.blockedUsers.contains('user_blocked1'), isTrue);
      });

      test('should create default privacy settings', () {
        final defaultSettings = PrivacySettings.defaultSettings();
        
        expect(defaultSettings.showLastSeen, isTrue);
        expect(defaultSettings.showActivityStatus, isTrue);
        expect(defaultSettings.allowSearchByName, isTrue);
        expect(defaultSettings.blockedUsers, isEmpty);
      });

      test('should serialize and deserialize PrivacySettings correctly', () {
        const original = PrivacySettings(
          showLastSeen: true,
          showActivityStatus: false,
          allowSearchByName: true,
          blockedUsers: ['blocked_user'],
        );

        // Test toJson
        final json = original.toJson();
        expect(json['showLastSeen'], isTrue);
        expect(json['showActivityStatus'], isFalse);
        expect(json['allowSearchByName'], isTrue);
        expect(json['blockedUsers'], isA<List>());

        // Test fromJson
        final recreated = PrivacySettings.fromJson(json);
        expect(recreated.showLastSeen, equals(original.showLastSeen));
        expect(recreated.showActivityStatus, equals(original.showActivityStatus));
        expect(recreated.allowSearchByName, equals(original.allowSearchByName));
        expect(recreated.blockedUsers, equals(original.blockedUsers));
      });
    });

    group('FamilyStats Class Tests', () {
      test('should create FamilyStats with all fields', () {
        final environmentalImpact = EnvironmentalImpact(
          co2Saved: 10.5,
          treesEquivalent: 2.3,
          waterSaved: 150.0,
          lastUpdated: testDateTime,
        );

        final weeklyProgress = WeeklyProgress(
          weekStart: testDateTime.subtract(const Duration(days: 7)),
          weekEnd: testDateTime,
          classificationsCount: 15,
          pointsEarned: 75,
          categoryBreakdown: {'Dry Waste': 10, 'Wet Waste': 5},
        );

        final stats = FamilyStats(
          totalClassifications: 100,
          totalPoints: 500,
          currentStreak: 7,
          bestStreak: 15,
          categoryBreakdown: {'Dry Waste': 60, 'Wet Waste': 40},
          environmentalImpact: environmentalImpact,
          weeklyProgress: [weeklyProgress],
          achievementCount: 8,
          lastUpdated: testDateTime,
        );

        expect(stats.totalClassifications, equals(100));
        expect(stats.totalPoints, equals(500));
        expect(stats.currentStreak, equals(7));
        expect(stats.bestStreak, equals(15));
        expect(stats.categoryBreakdown['Dry Waste'], equals(60));
        expect(stats.environmentalImpact.co2Saved, equals(10.5));
        expect(stats.weeklyProgress.length, equals(1));
        expect(stats.achievementCount, equals(8));
        expect(stats.lastUpdated, equals(testDateTime));
      });

      test('should create empty family stats', () {
        final emptyStats = FamilyStats.empty();
        
        expect(emptyStats.totalClassifications, equals(0));
        expect(emptyStats.totalPoints, equals(0));
        expect(emptyStats.currentStreak, equals(0));
        expect(emptyStats.bestStreak, equals(0));
        expect(emptyStats.categoryBreakdown, isEmpty);
        expect(emptyStats.weeklyProgress, isEmpty);
        expect(emptyStats.achievementCount, equals(0));
        expect(emptyStats.lastUpdated, isA<DateTime>());
      });

      test('should copyWith correctly', () {
        final original = FamilyStats.empty();
        
        final updated = original.copyWith(
          totalClassifications: 50,
          totalPoints: 250,
          currentStreak: 3,
        );

        expect(updated.totalClassifications, equals(50)); // Changed
        expect(updated.totalPoints, equals(250)); // Changed
        expect(updated.currentStreak, equals(3)); // Changed
        expect(updated.bestStreak, equals(original.bestStreak)); // Unchanged
        expect(updated.achievementCount, equals(original.achievementCount)); // Unchanged
      });
    });

    group('UserStats Class Tests', () {
      test('should create UserStats with all fields', () {
        final stats = UserStats(
          totalPoints: 150,
          totalClassifications: 30,
          currentStreak: 8,
          bestStreak: 12,
          categoryBreakdown: {'Dry Waste': 20, 'Wet Waste': 10},
          achievements: ['first_week', 'category_master'],
          lastActive: testDateTime,
        );

        expect(stats.totalPoints, equals(150));
        expect(stats.totalClassifications, equals(30));
        expect(stats.currentStreak, equals(8));
        expect(stats.bestStreak, equals(12));
        expect(stats.categoryBreakdown['Dry Waste'], equals(20));
        expect(stats.achievements.length, equals(2));
        expect(stats.achievements.contains('first_week'), isTrue);
        expect(stats.lastActive, equals(testDateTime));
      });

      test('should create empty user stats', () {
        final emptyStats = UserStats.empty();
        
        expect(emptyStats.totalPoints, equals(0));
        expect(emptyStats.totalClassifications, equals(0));
        expect(emptyStats.currentStreak, equals(0));
        expect(emptyStats.bestStreak, equals(0));
        expect(emptyStats.categoryBreakdown, isEmpty);
        expect(emptyStats.achievements, isEmpty);
        expect(emptyStats.lastActive, isA<DateTime>());
      });

      test('should serialize and deserialize UserStats correctly', () {
        final original = UserStats(
          totalPoints: 200,
          totalClassifications: 40,
          currentStreak: 6,
          bestStreak: 10,
          categoryBreakdown: {'Plastic': 25, 'Glass': 15},
          achievements: ['eco_warrior', 'plastic_expert'],
          lastActive: testDateTime,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['totalPoints'], equals(200));
        expect(json['categoryBreakdown'], isA<Map>());
        expect(json['achievements'], isA<List>());
        expect(json['lastActive'], equals(testDateTime.toIso8601String()));

        // Test fromJson
        final recreated = UserStats.fromJson(json);
        expect(recreated.totalPoints, equals(original.totalPoints));
        expect(recreated.totalClassifications, equals(original.totalClassifications));
        expect(recreated.categoryBreakdown, equals(original.categoryBreakdown));
        expect(recreated.achievements, equals(original.achievements));
        expect(recreated.lastActive, equals(original.lastActive));
      });

      test('should copyWith correctly', () {
        final original = UserStats.empty();
        
        final updated = original.copyWith(
          totalPoints: 100,
          achievements: ['new_achievement'],
          categoryBreakdown: {'New Category': 5},
        );

        expect(updated.totalPoints, equals(100)); // Changed
        expect(updated.achievements, equals(['new_achievement'])); // Changed
        expect(updated.categoryBreakdown['New Category'], equals(5)); // Changed
        expect(updated.totalClassifications, equals(original.totalClassifications)); // Unchanged
        expect(updated.currentStreak, equals(original.currentStreak)); // Unchanged
      });
    });

    group('EnvironmentalImpact Class Tests', () {
      test('should create EnvironmentalImpact with all fields', () {
        final impact = EnvironmentalImpact(
          co2Saved: 25.7,
          treesEquivalent: 5.2,
          waterSaved: 300.5,
          lastUpdated: testDateTime,
        );

        expect(impact.co2Saved, equals(25.7));
        expect(impact.treesEquivalent, equals(5.2));
        expect(impact.waterSaved, equals(300.5));
        expect(impact.lastUpdated, equals(testDateTime));
      });

      test('should create empty environmental impact', () {
        final emptyImpact = EnvironmentalImpact.empty();
        
        expect(emptyImpact.co2Saved, equals(0.0));
        expect(emptyImpact.treesEquivalent, equals(0.0));
        expect(emptyImpact.waterSaved, equals(0.0));
        expect(emptyImpact.lastUpdated, isA<DateTime>());
      });

      test('should serialize and deserialize EnvironmentalImpact correctly', () {
        final original = EnvironmentalImpact(
          co2Saved: 15.3,
          treesEquivalent: 3.7,
          waterSaved: 200.8,
          lastUpdated: testDateTime,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['co2Saved'], equals(15.3));
        expect(json['treesEquivalent'], equals(3.7));
        expect(json['waterSaved'], equals(200.8));
        expect(json['lastUpdated'], equals(testDateTime.toIso8601String()));

        // Test fromJson
        final recreated = EnvironmentalImpact.fromJson(json);
        expect(recreated.co2Saved, equals(original.co2Saved));
        expect(recreated.treesEquivalent, equals(original.treesEquivalent));
        expect(recreated.waterSaved, equals(original.waterSaved));
        expect(recreated.lastUpdated, equals(original.lastUpdated));
      });
    });

    group('WeeklyProgress Class Tests', () {
      test('should create WeeklyProgress with all fields', () {
        final weekStart = testDateTime.subtract(const Duration(days: 7));
        final weekEnd = testDateTime;
        
        final progress = WeeklyProgress(
          weekStart: weekStart,
          weekEnd: weekEnd,
          classificationsCount: 25,
          pointsEarned: 125,
          categoryBreakdown: {'Dry Waste': 15, 'Wet Waste': 10},
        );

        expect(progress.weekStart, equals(weekStart));
        expect(progress.weekEnd, equals(weekEnd));
        expect(progress.classificationsCount, equals(25));
        expect(progress.pointsEarned, equals(125));
        expect(progress.categoryBreakdown['Dry Waste'], equals(15));
        expect(progress.categoryBreakdown['Wet Waste'], equals(10));
      });

      test('should serialize and deserialize WeeklyProgress correctly', () {
        final weekStart = testDateTime.subtract(const Duration(days: 7));
        final weekEnd = testDateTime;
        
        final original = WeeklyProgress(
          weekStart: weekStart,
          weekEnd: weekEnd,
          classificationsCount: 20,
          pointsEarned: 100,
          categoryBreakdown: {'Plastic': 12, 'Glass': 8},
        );

        // Test toJson
        final json = original.toJson();
        expect(json['weekStart'], equals(weekStart.toIso8601String()));
        expect(json['weekEnd'], equals(weekEnd.toIso8601String()));
        expect(json['classificationsCount'], equals(20));
        expect(json['pointsEarned'], equals(100));
        expect(json['categoryBreakdown'], isA<Map>());

        // Test fromJson
        final recreated = WeeklyProgress.fromJson(json);
        expect(recreated.weekStart, equals(original.weekStart));
        expect(recreated.weekEnd, equals(original.weekEnd));
        expect(recreated.classificationsCount, equals(original.classificationsCount));
        expect(recreated.pointsEarned, equals(original.pointsEarned));
        expect(recreated.categoryBreakdown, equals(original.categoryBreakdown));
      });
    });

    group('Enum Tests', () {
      test('should handle UserRole enum correctly', () {
        expect(UserRole.values.length, equals(3));
        expect(UserRole.values.contains(UserRole.admin), isTrue);
        expect(UserRole.values.contains(UserRole.moderator), isTrue);
        expect(UserRole.values.contains(UserRole.member), isTrue);
      });

      test('should handle InvitationStatus enum correctly', () {
        expect(InvitationStatus.values.length, equals(4));
        expect(InvitationStatus.values.contains(InvitationStatus.pending), isTrue);
        expect(InvitationStatus.values.contains(InvitationStatus.accepted), isTrue);
        expect(InvitationStatus.values.contains(InvitationStatus.declined), isTrue);
        expect(InvitationStatus.values.contains(InvitationStatus.expired), isTrue);
      });

      test('should handle FamilyLeaderboardVisibility enum correctly', () {
        expect(FamilyLeaderboardVisibility.values.length, equals(3));
        expect(FamilyLeaderboardVisibility.values.contains(FamilyLeaderboardVisibility.public), isTrue);
        expect(FamilyLeaderboardVisibility.values.contains(FamilyLeaderboardVisibility.membersOnly), isTrue);
        expect(FamilyLeaderboardVisibility.values.contains(FamilyLeaderboardVisibility.adminsOnly), isTrue);
      });
    });

    group('Edge Cases and Integration Tests', () {
      test('should handle complex family with all features', () {
        final adminStats = UserStats(
          totalPoints: 500,
          totalClassifications: 100,
          currentStreak: 15,
          bestStreak: 20,
          categoryBreakdown: {'Dry Waste': 60, 'Wet Waste': 40},
          achievements: ['admin', 'eco_master', 'streak_king'],
          lastActive: testDateTime,
        );

        final admin = FamilyMember(
          userId: 'admin_user',
          role: UserRole.admin,
          joinedAt: testDateTime.subtract(const Duration(days: 30)),
          individualStats: adminStats,
          displayName: 'Family Admin',
          photoUrl: 'https://example.com/admin.jpg',
        );

        final memberStats = UserStats(
          totalPoints: 200,
          totalClassifications: 40,
          currentStreak: 5,
          bestStreak: 8,
          categoryBreakdown: {'Dry Waste': 25, 'Wet Waste': 15},
          achievements: ['beginner', 'first_week'],
          lastActive: testDateTime,
        );

        final member = FamilyMember(
          userId: 'regular_member',
          role: UserRole.member,
          joinedAt: testDateTime.subtract(const Duration(days: 7)),
          individualStats: memberStats,
          displayName: 'Regular Member',
        );

        final settings = FamilySettings(
          isPublic: true,
          notifications: NotificationSettings.defaultSettings(),
          privacy: PrivacySettings.defaultSettings(),
          customSettings: {'theme': 'green', 'region': 'US'},
          leaderboardVisibility: FamilyLeaderboardVisibility.public,
        );

        final family = Family(
          id: 'complex_family',
          name: 'Eco Warriors Family',
          description: 'A dedicated family working towards environmental sustainability',
          createdBy: 'admin_user',
          createdAt: testDateTime.subtract(const Duration(days: 30)),
          updatedAt: testDateTime,
          members: [admin, member],
          settings: settings,
          imageUrl: 'https://example.com/family-eco.jpg',
          isPublic: true,
        );

        // Test comprehensive family functionality
        expect(family.members.length, equals(2));
        expect(family.hasMember('admin_user'), isTrue);
        expect(family.hasMember('regular_member'), isTrue);
        expect(family.hasMember('non_member'), isFalse);
        
        final foundAdmin = family.getMember('admin_user');
        expect(foundAdmin?.role, equals(UserRole.admin));
        expect(foundAdmin?.individualStats.totalPoints, equals(500));
        
        final admins = family.getAdmins();
        expect(admins.length, equals(1));
        expect(admins.first.userId, equals('admin_user'));

        // Test serialization of complex family
        final json = family.toJson();
        final recreated = Family.fromJson(json);
        expect(recreated.members.length, equals(2));
        expect(recreated.settings.customSettings['theme'], equals('green'));
        expect(recreated.settings.leaderboardVisibility, equals(FamilyLeaderboardVisibility.public));
      });

      test('should handle empty and null values gracefully', () {
        final emptyFamily = Family(
          id: '',
          name: '',
          createdBy: '',
          createdAt: testDateTime,
          members: [],
        );

        expect(emptyFamily.id, equals(''));
        expect(emptyFamily.name, equals(''));
        expect(emptyFamily.members, isEmpty);
        expect(emptyFamily.hasMember('any_user'), isFalse);
        expect(emptyFamily.getMember('any_user'), isNull);
        expect(emptyFamily.getAdmins(), isEmpty);
      });

      test('should handle large numbers and data sets', () {
        final largeStats = UserStats(
          totalPoints: 1000000,
          totalClassifications: 50000,
          currentStreak: 365,
          bestStreak: 500,
          categoryBreakdown: Map.fromEntries(
            List.generate(20, (i) => MapEntry('Category_$i', i * 100))
          ),
          achievements: List.generate(100, (i) => 'achievement_$i'),
          lastActive: testDateTime,
        );

        expect(largeStats.totalPoints, equals(1000000));
        expect(largeStats.categoryBreakdown.length, equals(20));
        expect(largeStats.achievements.length, equals(100));

        final json = largeStats.toJson();
        final recreated = UserStats.fromJson(json);
        expect(recreated.totalPoints, equals(largeStats.totalPoints));
        expect(recreated.categoryBreakdown.length, equals(largeStats.categoryBreakdown.length));
        expect(recreated.achievements.length, equals(largeStats.achievements.length));
      });

      test('should handle special characters and unicode', () {
        final unicodeFamily = Family(
          id: 'family_unicode',
          name: '🌍 Eco Warriors 家族 🌱',
          description: 'Family with émojis and spëcial characters ñoñó',
          createdBy: 'user_unicode',
          createdAt: testDateTime,
        );

        expect(unicodeFamily.name, equals('🌍 Eco Warriors 家族 🌱'));
        expect(unicodeFamily.description, contains('émojis'));

        final json = unicodeFamily.toJson();
        final recreated = Family.fromJson(json);
        expect(recreated.name, equals(unicodeFamily.name));
        expect(recreated.description, equals(unicodeFamily.description));
      });

      test('should handle date edge cases', () {
        final futureDate = DateTime(2030, 12, 31);
        final pastDate = DateTime(1990, 1);
        
        final timeTravelFamily = Family(
          id: 'time_travel',
          name: 'Time Travel Family',
          createdBy: 'time_traveler',
          createdAt: futureDate,
          updatedAt: pastDate, // Past updated date (unusual but possible)
        );

        expect(timeTravelFamily.createdAt, equals(futureDate));
        expect(timeTravelFamily.updatedAt, equals(pastDate));

        final json = timeTravelFamily.toJson();
        final recreated = Family.fromJson(json);
        expect(recreated.createdAt, equals(timeTravelFamily.createdAt));
        expect(recreated.updatedAt, equals(timeTravelFamily.updatedAt));
      });
    });
  });
}
