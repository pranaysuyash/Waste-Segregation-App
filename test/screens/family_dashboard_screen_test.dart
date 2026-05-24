import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart'
    as family_models;
import 'package:waste_segregation_app/models/family_invitation.dart'
    as invitation_models;
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/family_dashboard_screen.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class FakeStorageService extends StorageService {
  FakeStorageService(this.profile);

  final UserProfile? profile;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => profile;
}

class AnalyticsCall {
  AnalyticsCall({
    required this.method,
    required this.name,
    required this.parameters,
  });

  final String method;
  final String name;
  final Map<String, dynamic> parameters;
}

class FakeAnalyticsService extends AnalyticsService {
  FakeAnalyticsService() : super(FakeStorageService(null), enableFirestore: false);

  final List<AnalyticsCall> calls = [];

  void _record(String method, String name, Map<String, dynamic> parameters) {
    calls.add(
      AnalyticsCall(
        method: method,
        name: name,
        parameters: Map<String, dynamic>.from(parameters),
      ),
    );
  }

  @override
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) async {
    _record('trackEvent', eventName, {
      'event_type': eventType,
      ...parameters,
    });
  }

  @override
  Future<void> trackUserAction(
    String actionName, {
    Map<String, dynamic>? parameters,
  }) async {
    _record('trackUserAction', actionName, parameters ?? const {});
  }

  @override
  Future<void> trackClick({
    required String elementId,
    required String screenName,
    required String elementType,
    String? userIntent,
    Map<String, dynamic>? additionalData,
  }) async {
    _record('trackClick', elementId, {
      'screen_name': screenName,
      'element_type': elementType,
      if (userIntent != null) 'user_intent': userIntent,
      ...?additionalData,
    });
  }

  @override
  Future<void> trackPageView(
    String screenName, {
    String? previousScreen,
    String? navigationMethod,
    int? timeOnPreviousScreen,
  }) async {
    _record('trackPageView', screenName, {
      if (previousScreen != null) 'previous_screen': previousScreen,
      if (navigationMethod != null) 'navigation_method': navigationMethod,
      if (timeOnPreviousScreen != null)
        'time_on_previous_screen_ms': timeOnPreviousScreen,
    });
  }
}

class _ThrowingStorageService extends FakeStorageService {
  _ThrowingStorageService() : super(null);

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    throw Exception('storage lookup failed');
  }
}

class FakeFamilyService extends FirebaseFamilyService {
  FakeFamilyService({
    required this.family,
    required this.stats,
    required this.members,
    required this.invitations,
    required this.activity,
  });

  final family_models.Family? family;
  final family_models.FamilyStats? stats;
  final List<UserProfile> members;
  final List<invitation_models.FamilyInvitation> invitations;
  final List<SharedWasteClassification> activity;

  @override
  Future<family_models.Family?> getFamily(String familyId) async => family;

  @override
  Stream<family_models.Family?> getFamilyStream(String familyId) {
    return Stream<family_models.Family?>.value(family);
  }

  @override
  Future<List<UserProfile>> getFamilyMembers(String familyId) async => members;

  @override
  Future<family_models.FamilyStats> getFamilyStats(String familyId) async =>
      stats ?? family_models.FamilyStats.empty();

  @override
  Stream<List<invitation_models.FamilyInvitation>> getInvitationsStream(
    String familyId,
  ) {
    return Stream<List<invitation_models.FamilyInvitation>>.value(invitations);
  }

  @override
  Stream<List<SharedWasteClassification>> getFamilyClassificationsStream(
    String familyId, {
    int limit = 5,
  }) {
    return Stream<List<SharedWasteClassification>>.value(
      activity.take(limit).toList(),
    );
  }

  @override
  Future<void> addMember(
    String familyId,
    String userId,
    UserRole roleFromProfile,
  ) async {
    return;
  }

  @override
  Future<void> acceptInvitation(String invitationId, String userId) async {
    return;
  }
}

Widget _wrapDashboard(
  Widget child, {
  required double width,
  required double height,
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

family_models.Family _familyFixture() {
  final now = DateTime(2026, 5, 24, 12);
  return family_models.Family(
    id: 'family_1',
    name: 'Green Home',
    description: 'Shared household progress for the whole family.',
    createdBy: 'user_1',
    createdAt: now,
    updatedAt: now,
    members: [
      family_models.FamilyMember(
        userId: 'user_1',
        role: family_models.UserRole.admin,
        joinedAt: now,
        individualStats: family_models.UserStats.empty(),
        displayName: 'Alex',
      ),
      family_models.FamilyMember(
        userId: 'user_2',
        role: family_models.UserRole.member,
        joinedAt: now,
        individualStats: family_models.UserStats.empty(),
        displayName: 'Sam',
      ),
    ],
    memberUids: const ['user_1', 'user_2'],
    settings: family_models.FamilySettings.defaultSettings(),
  );
}

family_models.FamilyStats _statsFixture() {
  return const family_models.FamilyStats(
    totalClassifications: 18,
    totalPoints: 120,
    currentStreak: 6,
    memberCount: 2,
    categoryCounts: {'paper': 10, 'plastic': 8},
  );
}

List<UserProfile> _memberProfilesFixture() {
  return [
    UserProfile(
      id: 'user_1',
      email: 'alex@example.com',
      displayName: 'Alex',
      familyId: 'family_1',
      role: UserRole.admin,
    ),
    UserProfile(
      id: 'user_2',
      email: 'sam@example.com',
      displayName: 'Sam',
      familyId: 'family_1',
      role: UserRole.member,
    ),
  ];
}

List<invitation_models.FamilyInvitation> _invitationsFixture() {
  final now = DateTime(2026, 5, 24, 12);
  return [
    invitation_models.FamilyInvitation(
      familyId: 'family_1',
      familyName: 'Green Home',
      inviterUserId: 'user_1',
      inviterName: 'Alex',
      invitedEmail: 'guest@example.com',
      method: invitation_models.InvitationMethod.qr,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 3)),
    ),
    invitation_models.FamilyInvitation(
      familyId: 'family_1',
      familyName: 'Green Home',
      inviterUserId: 'user_1',
      inviterName: 'Alex',
      invitedEmail: 'friend@example.com',
      status: invitation_models.InvitationStatus.accepted,
      createdAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 6)),
      respondedAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}

List<SharedWasteClassification> _activityFixture() {
  final shared = DateTime(2026, 5, 24, 11, 30);
  final classification = WasteClassification.fallback(
    'test-image.jpg',
    userId: 'user_1',
  );
  return [
    SharedWasteClassification(
      id: 'shared_1',
      classification: classification,
      sharedBy: 'user_1',
      sharedByDisplayName: 'Alex',
      sharedAt: shared,
      familyId: 'family_1',
    ),
  ];
}

void main() {
  group('FamilyDashboardScreen', () {
    testWidgets('shows create and join actions when the user has no family', (
      tester,
    ) async {
      final storage = FakeStorageService(
        UserProfile(
          id: 'user_1',
          email: 'user@test.com',
          displayName: 'User',
          role: UserRole.member,
        ),
      );

      final familyService = FakeFamilyService(
        family: null,
        stats: null,
        members: const [],
        invitations: const [],
        activity: const [],
      );
      final analytics = FakeAnalyticsService();

      await tester.pumpWidget(
        _wrapDashboard(
          FamilyDashboardScreen(
            storageService: storage,
            familyService: familyService,
            analyticsService: analytics,
          ),
          width: 360,
          height: 900,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('family-dashboard-empty-state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-create-family')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-join-family')),
        findsOneWidget,
      );
      expect(find.text('Family Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final snapshot = analytics.calls.firstWhere(
        (call) =>
            call.method == 'trackUserAction' &&
            call.name == 'family_dashboard_snapshot',
      );
      expect(snapshot.parameters['dashboard_state'], 'no_family');
      expect(snapshot.parameters['has_family'], isFalse);
      expect(snapshot.parameters['analytics_contract_version'], 1);
      expect(snapshot.parameters['family_id'], isNull);
    });

    testWidgets('renders the household dashboard sections for a family', (
      tester,
    ) async {
      final family = _familyFixture();
      final storage = FakeStorageService(
        UserProfile(
          id: 'user_1',
          email: 'alex@example.com',
          displayName: 'Alex',
          familyId: family.id,
          role: UserRole.admin,
        ),
      );
      final familyService = FakeFamilyService(
        family: family,
        stats: _statsFixture(),
        members: _memberProfilesFixture(),
        invitations: _invitationsFixture(),
        activity: _activityFixture(),
      );
      final analytics = FakeAnalyticsService();

      await tester.pumpWidget(
        _wrapDashboard(
          FamilyDashboardScreen(
            storageService: storage,
            familyService: familyService,
            analyticsService: analytics,
          ),
          width: 800,
          height: 1200,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Green Home'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('family-dashboard-management-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-summary-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-invitations-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-impact-card')),
        findsOneWidget,
      );
      expect(find.text('Family Members (2)'), findsOneWidget);
      expect(find.text('Invitation Stats'), findsOneWidget);
      expect(find.text('Recent Family Activity'), findsOneWidget);
      expect(find.text('Family Activity'), findsOneWidget);
      expect(find.text('18'), findsWidgets);
      expect(find.text('120'), findsWidgets);
      expect(find.text('6 days'), findsWidgets);

      final snapshot = analytics.calls.firstWhere(
        (call) =>
            call.method == 'trackUserAction' &&
            call.name == 'family_dashboard_snapshot',
      );
      expect(snapshot.parameters['dashboard_state'], 'loaded');
      expect(snapshot.parameters['has_family'], isTrue);
      expect(snapshot.parameters['analytics_contract_version'], 1);
      expect(snapshot.parameters['family_id'], family.id);
      expect(snapshot.parameters['family_member_count'], 2);
      expect(snapshot.parameters['family_total_classifications'], 18);
      expect(snapshot.parameters['family_total_points'], 120);
      expect(snapshot.parameters['family_current_streak'], 6);

      await tester.tap(find.byKey(const Key('family-dashboard-invite-button')));
      await tester.pumpAndSettle();

      expect(
        analytics.calls.where(
          (call) =>
              call.method == 'trackClick' &&
              call.name == 'family_dashboard_invite_button',
        ),
        isNotEmpty,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays stable on narrow layouts with larger text scale', (
      tester,
    ) async {
      final family = _familyFixture();
      final storage = FakeStorageService(
        UserProfile(
          id: 'user_1',
          email: 'alex@example.com',
          displayName: 'Alex',
          familyId: family.id,
          role: UserRole.admin,
        ),
      );
      final familyService = FakeFamilyService(
        family: family,
        stats: _statsFixture(),
        members: _memberProfilesFixture(),
        invitations: _invitationsFixture(),
        activity: _activityFixture(),
      );
      final analytics = FakeAnalyticsService();

      await tester.pumpWidget(
        _wrapDashboard(
          FamilyDashboardScreen(
            storageService: storage,
            familyService: familyService,
            analyticsService: analytics,
          ),
          width: 320,
          height: 900,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('family-dashboard-management-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-summary-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-impact-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-invite-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('family-dashboard-manage-button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows retryable error state when loading fails', (
      tester,
    ) async {
      final storage = _ThrowingStorageService();
      final familyService = FakeFamilyService(
        family: null,
        stats: null,
        members: const [],
        invitations: const [],
        activity: const [],
      );
      final analytics = FakeAnalyticsService();

      await tester.pumpWidget(
        _wrapDashboard(
          FamilyDashboardScreen(
            storageService: storage,
            familyService: familyService,
            analyticsService: analytics,
          ),
          width: 360,
          height: 900,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('family-dashboard-error-state')),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      final snapshot = analytics.calls.firstWhere(
        (call) =>
            call.method == 'trackUserAction' &&
            call.name == 'family_dashboard_snapshot',
      );
      expect(snapshot.parameters['dashboard_state'], 'error');
      expect(snapshot.parameters['analytics_contract_version'], 1);
      expect(snapshot.parameters['family_id'], isNull);
      expect(snapshot.parameters['error_type'], contains('Exception'));
      expect(tester.takeException(), isNull);
    });
  });
}
