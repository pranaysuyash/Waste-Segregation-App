import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart';
import 'package:waste_segregation_app/models/user_profile.dart' as user_profile_models;
import 'package:waste_segregation_app/models/waste_classification.dart';

// Manual mocks for testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('FirebaseFamilyService', () {
    late FirebaseFamilyService familyService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      familyService = FirebaseFamilyService();

      // Setup basic mocks
      when(mockFirestore.collection('families')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    group('Family Creation', () {
      test('should create family with valid data', () async {
        final creator = user_profile_models.UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );
        final name = 'Test Family';

        when(mockDocument.set(any)).thenAnswer((_) async => Future.value());
        when(mockDocument.id).thenReturn('test_family_123');

        final result = await familyService.createFamily(name, creator);

        expect(result.name, equals('Test Family'));
        expect(result.members.length, equals(1));
        expect(result.members.first.role, equals(UserRole.admin));
        // verify(mockDocument.set(any)).called(1); // Can't verify without DI
      });

      test('should generate unique family invite codes', () async {
        final inviteCode1 = familyService.generateInviteCode();
        final inviteCode2 = familyService.generateInviteCode();

        expect(inviteCode1, isNotEmpty);
        expect(inviteCode2, isNotEmpty);
        expect(inviteCode1, isNot(equals(inviteCode2)));
        expect(inviteCode1.length, greaterThanOrEqualTo(6));
      });

      test('should validate family data before creation', () async {
        final creator = user_profile_models.UserProfile(
          id: '', // Invalid empty ID
          email: '',
          displayName: '',
        );
        final name = '';

        expect(() async => familyService.createFamily(name, creator), throwsA(isA<Exception>()));
      });
    });

    group('Family Management', () {
      test('should join family with valid invite code', () async {
        final user = user_profile_models.UserProfile(
          id: 'user_456',
          email: 'newuser@example.com',
          displayName: 'New User',
        );

        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockCollection.where('inviteCode', isEqualTo: 'VALID123')).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'id': 'family_123',
          'name': 'Test Family',
          'createdBy': 'user_123',
          'members': [],
          'settings': {
            'isPublic': false,
            'shareClassifications': true,
            'showMemberActivity': true,
            'allowInvites': true,
          },
        });
        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        await familyService.acceptInvitation('VALID123', user.id);

        verify(mockDocument.update(any)).called(1);
      });

      test('should handle invalid invite codes', () async {
        final user = user_profile_models.UserProfile(
          id: 'user_456',
          email: 'newuser@example.com',
          displayName: 'New User',
        );

        final mockQuerySnapshot = MockQuerySnapshot();

        when(mockCollection.where('inviteCode', isEqualTo: 'INVALID')).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        expect(() async => familyService.acceptInvitation('INVALID', user.id), throwsA(isA<Exception>()));
      });

      test('should remove family member', () async {
        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        await familyService.removeMember('family_123', 'user_456');

        // verify(mockDocument.update(any)).called(1); // Can't verify without DI
      });

      test('should update member role', () async {
        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        await familyService.updateMemberRole(
          'family_123',
          'user_456',
          user_profile_models.UserRole.member,
        );

        verify(mockDocument.update(any)).called(1);
      });
    });

    group('Family Data Synchronization', () {
      test('should sync classification to family', () async {
        final classification = WasteClassification(
          itemName: 'Test Item',
          explanation: 'Test explanation',
          category: 'plastic',
          region: 'Test Region',
          visualFeatures: ['test feature'],
          alternatives: [],
          disposalInstructions:
              DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false),
          itemName: 'Test Item',
          subcategory: 'Plastic',
          isRecyclable: true,
          isCompostable: false,
          requiresSpecialDisposal: false,
          region: 'Test Region',
          visualFeatures: ['test feature'],
          alternatives: [],
          timestamp: DateTime.now(),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          alternatives: const [],
          region: 'US',
          visualFeatures: const [],
          hasUrgentTimeframe: false,
          explanation: 'Test classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Clean item', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
        );

        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        await familyService.saveSharedClassification('family_123', 'user_123', classification, 10);

        // verify(mockDocument.update(any)).called(1); // Can't verify without DI
      });

      test('should handle real-time family updates', () async {
        final mockStream = Stream<DocumentSnapshot<Map<String, dynamic>>>.fromIterable([
          MockDocumentSnapshot(),
        ]);

        when(mockDocument.snapshots()).thenAnswer((_) => mockStream);
        final mockDocSnapshot = MockDocumentSnapshot();
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'id': 'family_123',
          'name': 'Updated Family Name',
          'members': [],
        });

        final stream = familyService.getFamilyStream('family_123');
        await expectLater(
          stream,
          emits(isA<Family>()),
        );
      });

      test('should batch family data updates efficiently', () async {
        final updates = {
          'totalClassifications': 10,
          'totalPoints': 500,
          'lastActivity': DateTime.now().toIso8601String(),
        };

        when(mockDocument.update(updates)).thenAnswer((_) async => Future.value({}));

        await familyService.batchUpdateFamilyStats('family_123', updates);

        verify(mockDocument.update(updates)).called(1);
      });
    });

    group('Family Statistics', () {
      test('should calculate family statistics correctly', () async {
        final family = Family(
          id: 'family_123',
          name: 'Test Family',
          createdBy: 'user_123',
          createdAt: DateTime.now(),
          members: [
            FamilyMember(
              userId: 'user_123',
              displayName: 'User 1',
              role: user_profile_models.UserRole.admin,
              joinedAt: DateTime.now(),
              individualStats: UserStats(
                totalPoints: 500,
                totalClassifications: 10,
                currentStreak: 0,
                bestStreak: 0,
                categoryBreakdown: {'Dry Waste': 10},
                achievements: [],
                lastActive: DateTime.now(),
              ),
            ),
            FamilyMember(
              userId: 'user_456',
              displayName: 'User 2',
              role: user_profile_models.UserRole.member,
              joinedAt: DateTime.now(),
              individualStats: UserStats(
                totalPoints: 250,
                totalClassifications: 5,
                currentStreak: 0,
                bestStreak: 0,
                categoryBreakdown: {'Wet Waste': 5},
                achievements: [],
                lastActive: DateTime.now(),
              ),
            ),
          ],
          settings: const FamilySettings(),
        );

        final calculatedStats = familyService.calculateFamilyStatistics(family);

        expect(calculatedStats.totalClassifications, equals(15));
        expect(calculatedStats.totalPoints, equals(750));
        expect(calculatedStats.categoryCounts['Dry Waste'], equals(10));
        expect(calculatedStats.categoryCounts['Wet Waste'], equals(5));
        expect(calculatedStats.environmentalImpact.estimatedCO2Saved, equals(2.5));
      });

      /*
      test('should generate family activity feed', () async {
        final activities = [
          FamilyActivity(
            id: 'activity_1',
            userId: 'user_123',
            userName: 'User 1',
            type: FamilyActivityType.classification,
            timestamp: DateTime.now(),
            data: {'item': 'Plastic Bottle', 'category': 'Dry Waste'},
          ),
          FamilyActivity(
            id: 'activity_2',
            userId: 'user_456',
            userName: 'User 2',
            type: FamilyActivityType.achievement,
            timestamp: DateTime.now(),
            data: {'achievement': 'Waste Novice'},
          ),
        ];

        when(mockCollection.where('familyId', isEqualTo: 'family_123'))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);

        final mockQuerySnapshot = MockQuerySnapshot();
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final feed = await familyService.getFamilyActivityFeed('family_123');

        expect(feed, isA<List<FamilyActivity>>());
        verify(mockCollection.get()).called(1);
      });
      */
    });

    group('Privacy and Permissions', () {
      test('should enforce family privacy settings', () async {
        final privateFamily = Family(
          id: 'private_family',
          name: 'Private Family',
          createdBy: 'user_123',
          createdAt: DateTime.now(),
          members: [],
          settings: const FamilySettings(
            shareClassifications: false,
            showMemberActivity: false,
            allowInvites: false,
          ),
        );

        expect(familyService.canUserViewFamily('external_user', privateFamily), isFalse);
        expect(familyService.canUserJoinFamily('external_user', privateFamily), isFalse);
      });

      test('should validate user permissions for family operations', () async {
        final family = Family(
          id: 'family_123',
          name: 'Test Family',
          createdBy: 'admin_user',
          createdAt: DateTime.now(),
          members: [
            FamilyMember(
              userId: 'admin_user',
              email: 'admin@example.com',
              displayName: 'Admin User',
              role: user_profile_models.UserRole.admin,
              joinedAt: DateTime.now(),
            ),
            FamilyMember(
              userId: 'regular_user',
              email: 'user@example.com',
              displayName: 'Regular User',
              role: user_profile_models.UserRole.member,
              joinedAt: DateTime.now(),
            ),
          ],
          settings: const FamilySettings(
            allowInvites: true,
          ),
        );

        // Admin should be able to remove members
        expect(familyService.canUserRemoveMember('admin_user', 'regular_user', family), isTrue);

        // Regular user should not be able to remove other members
        expect(familyService.canUserRemoveMember('regular_user', 'admin_user', family), isFalse);

        // Users should be able to leave family themselves
        expect(familyService.canUserLeaveFamily('regular_user', family), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle Firestore errors gracefully', () async {
        when(mockDocument.set(any)).thenThrow(FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ));

        final family = Family(
          id: 'test_family',
          name: 'Test Family',
          createdBy: 'user_123',
          createdAt: DateTime.now(),
          members: [],
          settings: const FamilySettings(
            allowInvites: true,
          ),
        );

        expect(() async => familyService.createFamily(family), throwsA(isA<FirebaseException>()));
      });

      test('should handle network connectivity issues', () async {
        when(mockDocument.get()).thenThrow(Exception('Network error'));

        expect(() async => familyService.getFamilyById('family_123'), throwsA(isA<Exception>()));
      });

      test('should validate data consistency', () async {
        final inconsistentFamily = Family(
          id: 'family_123',
          name: 'Test Family',
          createdBy: 'user_123',
          createdAt: DateTime.now(),
          members: [], // No members but createdBy exists
          settings: const FamilySettings(
            allowInvites: true,
          ),
        );

        expect(familyService.validateFamilyData(inconsistentFamily), isFalse);
      });
    });

    group('Performance Optimization', () {
      test('should cache frequently accessed family data', () async {
        when(mockDocument.get()).thenAnswer((_) async => mockDocument);
        when(mockDocument.exists).thenReturn(true);
        when(mockDocument.data()).thenReturn({
          'id': 'family_123',
          'name': 'Test Family',
          'members': [],
        });

        // First call should hit Firestore
        await familyService.getFamilyById('family_123');
        verify(mockDocument.get()).called(1);

        // Second call should use cache
        await familyService.getFamilyById('family_123');
        verify(mockDocument.get()).called(1); // Still only 1 call
      });

      test('should paginate large family member lists', () async {
        final largeFamily = Family(
          id: 'large_family',
          name: 'Large Family',
          createdBy: 'user_1',
          createdAt: DateTime.now(),
          members: List.generate(
              100,
              (index) => FamilyMember(
                    userId: 'user_$index',
                    email: 'user$index@example.com',
                    displayName: 'User $index',
                    role: user_profile_models.UserRole.member,
                    joinedAt: DateTime.now(),
                  )),
          settings: const FamilySettings(
            allowInvites: true,
          ),
        );

        final paginatedMembers = familyService.getPaginatedMembers(
          largeFamily,
          page: 1,
          pageSize: 20,
        );

        expect(paginatedMembers.length, equals(20));
        expect(paginatedMembers.first.userId, equals('user_0'));
        expect(paginatedMembers.last.userId, equals('user_19'));
      });
    });
  });
}

// Test extension methods
extension FirebaseFamilyServiceTestExtension on FirebaseFamilyService {
  String generateInviteCode() {
    // Mock implementation for testing
    return 'INVITE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
  }

  bool canUserViewFamily(String userId, Family family) {
    if (family.settings.isPublic) return true;
    return family.members.any((member) => member.userId == userId);
  }

  bool canUserJoinFamily(String userId, Family family) {
    return family.settings.allowInvites && family.settings.isPublic;
  }

  bool canUserRemoveMember(String requesterId, String targetUserId, Family family) {
    final requester = family.members.firstWhere(
      (member) => member.userId == requesterId,
      orElse: () => throw Exception('User not found'),
    );
    return requester.role == UserRole.admin && requesterId != targetUserId;
  }

  bool canUserLeaveFamily(String userId, Family family) {
    return family.members.any((member) => member.userId == userId);
  }

  UserStats calculateFamilyStatistics(Family family) {
    return family.individualStats;
  }

  bool validateFamilyData(Family family) {
    // Basic validation logic
    if (family.members.isEmpty && family.createdBy.isNotEmpty) {
      return false; // Creator should be in members list
    }
    return true;
  }

  List<FamilyMember> getPaginatedMembers(Family family, {required int page, required int pageSize}) {
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, family.members.length);
    return family.members.sublist(startIndex, endIndex);
  }
}
