import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart' as family_models;
import 'package:waste_segregation_app/models/family_invitation.dart' as invitation_models;
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/screens/family_management_screen.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class MockFirebaseFamilyService extends Mock implements FirebaseFamilyService {
  @override
  Stream<family_models.Family?> getFamilyStream(String familyId) =>
      super.noSuchMethod(
        Invocation.method(#getFamilyStream, [familyId]),
        returnValue: const Stream<family_models.Family?>.empty(),
        returnValueForMissingStub: const Stream<family_models.Family?>.empty(),
      ) as Stream<family_models.Family?>;

  @override
  Stream<List<UserProfile>> getFamilyMembersStream(String familyId) =>
      super.noSuchMethod(
        Invocation.method(#getFamilyMembersStream, [familyId]),
        returnValue: const Stream<List<UserProfile>>.empty(),
        returnValueForMissingStub: const Stream<List<UserProfile>>.empty(),
      ) as Stream<List<UserProfile>>;

  @override
  Stream<List<invitation_models.FamilyInvitation>> getInvitationsStream(
          String familyId) =>
      super.noSuchMethod(
        Invocation.method(#getInvitationsStream, [familyId]),
        returnValue:
            const Stream<List<invitation_models.FamilyInvitation>>.empty(),
        returnValueForMissingStub:
            const Stream<List<invitation_models.FamilyInvitation>>.empty(),
      ) as Stream<List<invitation_models.FamilyInvitation>>;
}

class MockStorageService extends Mock implements StorageService {
  @override
  Future<UserProfile?> getCurrentUserProfile() => super.noSuchMethod(
        Invocation.method(#getCurrentUserProfile, const []),
        returnValue: Future<UserProfile?>.value(null),
        returnValueForMissingStub: Future<UserProfile?>.value(null),
      ) as Future<UserProfile?>;
}

family_models.Family _family() {
  return family_models.Family(
    id: 'fam1',
    name: 'Test Family',
    createdBy: 'user1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    members: [
      family_models.FamilyMember(
        userId: 'user1',
        role: family_models.UserRole.admin,
        joinedAt: DateTime.now(),
        individualStats: family_models.UserStats.empty(),
        displayName: 'Admin',
      ),
    ],
    settings: family_models.FamilySettings.defaultSettings(),
  );
}

void main() {
  group('FamilyManagementScreen', () {
    testWidgets('renders with stream-backed family', (tester) async {
      final familyService = MockFirebaseFamilyService();
      final storageService = MockStorageService();

      when(storageService.getCurrentUserProfile()).thenAnswer(
        (_) async => UserProfile(
          id: 'user1',
          email: 'user1@test.com',
          displayName: 'Admin',
          familyId: 'fam1',
        ),
      );

      final family = _family();
      when(familyService.getFamilyStream('fam1'))
          .thenAnswer((_) => Stream<family_models.Family?>.value(family));
      when(familyService.getFamilyMembersStream('fam1'))
          .thenAnswer((_) => Stream<List<UserProfile>>.value(const []));
      when(familyService.getInvitationsStream('fam1'))
          .thenAnswer((_) => Stream.value(const []));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseFamilyService>.value(value: familyService),
            Provider<StorageService>.value(value: storageService),
          ],
          child: MaterialApp(home: FamilyManagementScreen(family: family)),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Manage Test Family'), findsOneWidget);
    });
  });
}
