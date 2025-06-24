import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart' as family_models;
import 'package:waste_segregation_app/models/family_invitation.dart' as invitation_models;
import 'package:waste_segregation_app/models/user_profile.dart' as user_profile_models;
import 'package:waste_segregation_app/screens/family_management_screen.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart'; // For AppTheme if needed in test setup

import 'family_management_screen_test.mocks.dart';

// Helper functions
user_profile_models.UserProfile createMockUserProfile({
  String id = 'user1',
  String displayName = 'Test User',
  String? photoUrl,
  String? familyId = 'fam1',
  // UserRole from user_profile_models is implicitly used by UserProfile constructor if it had a role
}) {
  return user_profile_models.UserProfile(
    id: id,
    email: '$id@test.com',
    displayName: displayName,
    photoUrl: photoUrl,
    familyId: familyId,
  );
}

family_models.FamilyMember createMockFamilyMember({
  String userId = 'user1',
  String displayName = 'Test User',
  family_models.UserRole role = family_models.UserRole.member,
}) {
  return family_models.FamilyMember(
    userId: userId,
    role: role,
    joinedAt: DateTime.now().subtract(const Duration(days: 10)),
    individualStats: family_models.UserStats.empty(),
    displayName: displayName,
  );
}

family_models.Family createMockFamily({
  String id = 'fam1',
  String name = 'Awesome Family',
  List<family_models.FamilyMember>? members,
  family_models.FamilySettings? settings,
}) {
  return family_models.Family(
    id: id,
    name: name,
    createdBy: 'creatorUser',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(), // Fixed: lastUpdated to updatedAt
    members: members ?? [createMockFamilyMember(role: family_models.UserRole.admin)],
    settings: settings ?? family_models.FamilySettings.defaultSettings(),
    // Removed: stats: family_models.FamilyStats.empty(), // Family model does not have stats directly
  );
}

invitation_models.FamilyInvitation createMockInvitation({
  String id = 'inv1',
  String familyId = 'fam1',
  String invitedEmail = 'invitee@test.com',
  user_profile_models.UserRole roleToAssign =
      user_profile_models.UserRole.member, // Role from user_profile for invitation
  invitation_models.InvitationStatus status = invitation_models.InvitationStatus.pending,
}) {
  return invitation_models.FamilyInvitation(
    id: id,
    familyId: familyId,
    familyName: 'Inviting Family',
    inviterUserId: 'user1',
    inviterName: 'Admin User',
    invitedEmail: invitedEmail,
    roleToAssign: roleToAssign, // This is user_profile_models.UserRole
    status: status,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    expiresAt: DateTime.now().add(const Duration(days: 6)),
  );
}

@GenerateMocks([FirebaseFamilyService, StorageService])
void main() {
  late MockFirebaseFamilyService mockFamilyService;
  late MockStorageService mockStorageService;

  final clipboardLog = <MethodCall>[];

  late StreamController<family_models.Family?> familyStreamController;
  late StreamController<List<user_profile_models.UserProfile>> membersStreamController;
  late StreamController<List<invitation_models.FamilyInvitation>> invitationsStreamController;

  setUp(() {
    mockFamilyService = MockFirebaseFamilyService();
    mockStorageService = MockStorageService();

    familyStreamController = StreamController<family_models.Family?>.broadcast();
    membersStreamController = StreamController<List<user_profile_models.UserProfile>>.broadcast();
    invitationsStreamController = StreamController<List<invitation_models.FamilyInvitation>>.broadcast();

    when(mockStorageService.getCurrentUserProfile()).thenAnswer(
        (_) async => createMockUserProfile(id: 'currentUserAdmin')); // Removed role from UserProfile mock creation

    when(mockFamilyService.getFamilyStream(any)).thenAnswer((_) => familyStreamController.stream);
    when(mockFamilyService.getFamilyMembersStream(any)).thenAnswer((_) => membersStreamController.stream);
    when(mockFamilyService.getInvitationsStream(any)).thenAnswer((_) => invitationsStreamController.stream);

    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardLog.add(methodCall);
          return null;
        }
        return null;
      },
    );
    clipboardLog.clear();
  });

  tearDown(() {
    familyStreamController.close();
    membersStreamController.close();
    invitationsStreamController.close();
  });

  Widget createTestableWidget(family_models.Family initialFamily, Widget child) {
    final testTheme = ThemeData.light().copyWith(
      primaryColor: AppTheme.primaryColor, // Assuming this is a static color on AppTheme
      colorScheme:
          ColorScheme.fromSeed(seedColor: AppTheme.primaryColor), // Assuming this is a static color on AppTheme
      // textTheme, cardTheme, elevatedButtonTheme will use defaults from ThemeData.light()
      // or specific overrides if AppTheme provided them as ThemeData components (e.g. AppTheme.customCardTheme)
      tabBarTheme: TabBarTheme(
        labelColor: AppTheme.primaryColor, // Assuming this is a static color on AppTheme
        unselectedLabelColor: Colors.grey.shade700,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );

    return MultiProvider(
      providers: [
        Provider<FirebaseFamilyService>.value(value: mockFamilyService),
        Provider<StorageService>.value(value: mockStorageService),
      ],
      child: MaterialApp(
        home: child,
        theme: testTheme,
      ),
    );
  }

  final mockInitialFamily = createMockFamily(id: 'manageFam1', name: 'Manageable Family');

  group('FamilyManagementScreen Tests', () {
    testWidgets('Displays loading indicators for streams initially', (WidgetTester tester) async {
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile(id: 'adminUser'));
      // Don't add data to controllers yet

      await tester
          .pumpWidget(createTestableWidget(mockInitialFamily, FamilyManagementScreen(family: mockInitialFamily)));

      // Main family stream loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // For the main family stream
      await tester.pump(); // Let one frame pass for streams to establish connection state

      familyStreamController.add(mockInitialFamily); // Resolve family stream
      await tester.pump(); // Let StreamBuilder for family rebuild

      // Now, StreamBuilders for members and invitations should show loading
      // Members tab (initial tab)
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // For members stream

      await tester.tap(find.text('Invitations'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // For invitations stream
    });

    testWidgets('Displays family name in AppBar from stream', (WidgetTester tester) async {
      final family = createMockFamily(name: 'Streamed Family Name');
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile(id: 'adminUser'));

      await tester.pumpWidget(createTestableWidget(family, FamilyManagementScreen(family: family)));
      familyStreamController.add(family); // Emit family data
      membersStreamController.add([]); // Emit empty members to resolve members stream
      invitationsStreamController.add([]); // Emit empty invitations to resolve invitations stream
      await tester.pumpAndSettle();

      expect(find.text('Manage Streamed Family Name'), findsOneWidget);
    });

    testWidgets('Displays members in Members tab from stream', (WidgetTester tester) async {
      final family = createMockFamily();
      final members = [
        createMockUserProfile(id: 'member1', displayName: 'Alice'),
        createMockUserProfile(id: 'member2', displayName: 'Bob'),
      ];
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile(id: 'adminUser'));

      await tester.pumpWidget(createTestableWidget(family, FamilyManagementScreen(family: family)));
      familyStreamController.add(family);
      membersStreamController.add(members); // Emit members
      invitationsStreamController.add([]);
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('Displays invitations in Invitations tab from stream', (WidgetTester tester) async {
      final family = createMockFamily();
      final invitations = [
        createMockInvitation(id: 'invA', invitedEmail: 'charlie@test.com'),
        createMockInvitation(id: 'invB', invitedEmail: 'diana@test.com'),
      ];
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile(id: 'adminUser'));

      await tester.pumpWidget(createTestableWidget(family, FamilyManagementScreen(family: family)));
      familyStreamController.add(family);
      membersStreamController.add([]);
      invitationsStreamController.add(invitations);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invitations'));
      await tester.pumpAndSettle();

      expect(find.text('charlie@test.com'), findsOneWidget);
      expect(find.text('diana@test.com'), findsOneWidget);
    });

    group('Settings Tab Actions', () {
      final familyForSettings = createMockFamily(id: 'settingsFam', name: 'Settings Test Fam');

      setUp(() {
        // Ensure current user is admin for settings modification
        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => createMockUserProfile(id: 'adminUser', familyId: familyForSettings.id));

        // Ensure updateFamily is stubbed
        when(mockFamilyService.updateFamily(any)).thenAnswer((_) async {});
      });

      testWidgets('Edit Family Name shows dialog and calls updateFamily', (WidgetTester tester) async {
        await tester
            .pumpWidget(createTestableWidget(familyForSettings, FamilyManagementScreen(family: familyForSettings)));
        familyStreamController.add(familyForSettings);
        membersStreamController.add([]);
        invitationsStreamController.add([]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ListTile, 'Family Name'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.widgetWithText(TextField, familyForSettings.name), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'New Family Name');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final updatedFamily = familyForSettings.copyWith(name: 'New Family Name');
        verify(mockFamilyService.updateFamily(argThat(
                predicate<family_models.Family>((f) => f.name == updatedFamily.name && f.id == updatedFamily.id))))
            .called(1);
        expect(find.text('Family name updated!'), findsOneWidget); // SnackBar
      });

      testWidgets('Copy Family ID calls Clipboard.setData and shows SnackBar', (WidgetTester tester) async {
        await tester
            .pumpWidget(createTestableWidget(familyForSettings, FamilyManagementScreen(family: familyForSettings)));
        familyStreamController.add(familyForSettings);
        membersStreamController.add([]);
        invitationsStreamController.add([]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        // Find by Icon
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle(); // For SnackBar

        expect(clipboardLog.length, 1);
        expect(clipboardLog.first.method, 'Clipboard.setData');
        expect(clipboardLog.first.arguments['text'], familyForSettings.id);
        expect(find.text('Family ID copied to clipboard!'), findsOneWidget);
      });

      testWidgets('Toggle "Public Family" calls updateFamily and shows SnackBar', (WidgetTester tester) async {
        final initialSettings = family_models.FamilySettings.defaultSettings().copyWith(isPublic: false);
        final familyWithSettings = createMockFamily(settings: initialSettings);

        await tester
            .pumpWidget(createTestableWidget(familyWithSettings, FamilyManagementScreen(family: familyWithSettings)));
        familyStreamController.add(familyWithSettings);
        membersStreamController.add([]);
        invitationsStreamController.add([]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        final publicSwitch = find.widgetWithText(SwitchListTile, 'Public Family');
        expect(publicSwitch, findsOneWidget);
        await tester.tap(publicSwitch);
        await tester.pumpAndSettle();

        final expectedSettings = initialSettings.copyWith(isPublic: true);
        verify(mockFamilyService.updateFamily(
                argThat(predicate<family_models.Family>((f) => f.settings.isPublic == expectedSettings.isPublic))))
            .called(1);
        expect(find.text('Public family setting updated to true'), findsOneWidget);
      });

      testWidgets('Toggle "Share Classifications" calls updateFamily and shows SnackBar', (WidgetTester tester) async {
        final initialSettings = family_models.FamilySettings.defaultSettings().copyWith(shareClassifications: true);
        final familyWithSettings = createMockFamily(settings: initialSettings);

        await tester
            .pumpWidget(createTestableWidget(familyWithSettings, FamilyManagementScreen(family: familyWithSettings)));
        familyStreamController.add(familyWithSettings);
        membersStreamController.add([]);
        invitationsStreamController.add([]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        final shareSwitch = find.widgetWithText(SwitchListTile, 'Share Classifications');
        await tester.tap(shareSwitch); // Toggle to false
        await tester.pumpAndSettle();

        final expectedSettings = initialSettings.copyWith(shareClassifications: false);
        verify(mockFamilyService.updateFamily(argThat(predicate<family_models.Family>(
            (f) => f.settings.shareClassifications == expectedSettings.shareClassifications)))).called(1);
        expect(find.text('Share classifications setting updated to false'), findsOneWidget);
      });

      testWidgets('Toggle "Show Member Activity" calls updateFamily and shows SnackBar', (WidgetTester tester) async {
        final initialSettings = family_models.FamilySettings.defaultSettings().copyWith(showMemberActivity: true);
        final familyWithSettings = createMockFamily(settings: initialSettings);

        await tester
            .pumpWidget(createTestableWidget(familyWithSettings, FamilyManagementScreen(family: familyWithSettings)));
        familyStreamController.add(familyWithSettings);
        membersStreamController.add([]);
        invitationsStreamController.add([]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        final activitySwitch = find.widgetWithText(SwitchListTile, 'Show Member Activity');
        await tester.tap(activitySwitch); // Toggle to false
        await tester.pumpAndSettle();

        final expectedSettings = initialSettings.copyWith(showMemberActivity: false);
        verify(mockFamilyService.updateFamily(argThat(predicate<family_models.Family>(
            (f) => f.settings.showMemberActivity == expectedSettings.showMemberActivity)))).called(1);
        expect(find.text('Show member activity setting updated to false'), findsOneWidget);
      });
    });

    // Admin actions tests (simplified, focusing on service calls)
    group('Admin Actions', () {
      final adminUser = createMockUserProfile(id: 'adminUser', familyId: 'adminFam');
      final regularMember =
          createMockUserProfile(id: 'memberUser', displayName: 'Regular Member', familyId: 'adminFam');
      final familyForAdmin = createMockFamily(id: 'adminFam', members: [
        createMockFamilyMember(userId: adminUser.id, role: family_models.UserRole.admin),
        createMockFamilyMember(userId: regularMember.id, displayName: 'Regular Member'),
      ]);
      final pendingInvite = createMockInvitation(familyId: 'adminFam', id: 'inviteToCancel');

      setUp(() {
        when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => adminUser);
        when(mockFamilyService.updateMemberRole(any, any, any)).thenAnswer((_) async {});
        when(mockFamilyService.removeMember(any, any)).thenAnswer((_) async {});
        when(mockFamilyService.cancelInvitation(any)).thenAnswer((_) async {});
      });

      testWidgets('Cancel Invitation calls service method', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(familyForAdmin, FamilyManagementScreen(family: familyForAdmin)));
        familyStreamController.add(familyForAdmin);
        membersStreamController.add([adminUser, regularMember]);
        invitationsStreamController.add([pendingInvite]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Invitations'));
        await tester.pumpAndSettle();

        expect(find.text(pendingInvite.invitedEmail), findsOneWidget);
        await tester.tap(find.byIcon(Icons.more_vert).first); // Assuming one invitation, find its menu
        await tester.pumpAndSettle(); // For menu to appear
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verify(mockFamilyService.cancelInvitation(pendingInvite.id)).called(1);
        expect(find.text('Invitation cancelled successfully'), findsOneWidget);
      });

      // Note: Testing specific role change and remove member dialogs fully can be complex.
      // These tests might focus on ensuring the options are available and lead to service calls.
      // For simplicity, we're verifying the service call directly after the menu tap,
      // assuming the dialogs correctly trigger these actions.
      // A more robust test would interact with the dialog itself.
    });
  });
}
