import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart' as wc_model;
import 'package:waste_segregation_app/screens/classification_details_screen.dart';
import 'package:waste_segregation_app/screens/family_dashboard_screen.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

import 'family_dashboard_screen_test.mocks.dart'; // Will be generated

// Mock Navigator
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Helper Functions to create mock data
UserProfile createMockUserProfile({
  String id = 'user1',
  String displayName = 'Test User',
  String? photoUrl,
  String familyId = 'fam1',
}) {
  return UserProfile(
      id: id, email: '$id@test.com', displayName: displayName, photoUrl: photoUrl, familyId: familyId);
}

Family createMockFamily({
  String id = 'fam1',
  String name = 'Test Family',
  List<FamilyMember>? members,
  FamilyStats? stats,
}) {
  return Family(
    id: id,
    name: name,
    createdBy: 'creatorUser',
    createdAt: DateTime.now(),
    lastUpdated: DateTime.now(),
    members: members ?? [FamilyMember(userId: 'user1', role: UserRole.admin, joinedAt: DateTime.now(), individualStats: UserStats.empty(), displayName: 'Test User')],
    settings: FamilySettings.defaultSettings(),
    stats: stats ?? FamilyStats(
        totalClassifications: 10,
        totalPoints: 100,
        currentStreak: 5,
        bestStreak: 10,
        categoryBreakdown: {'plastic': 5, 'organic': 5},
        environmentalImpact: EnvironmentalImpact(co2Saved: 2.5, treesEquivalent: 0.1, waterSaved: 50, lastUpdated: DateTime.now()),
        weeklyProgress: [],
        achievementCount: 2,
        lastUpdated: DateTime.now(),
      ),
  );
}

SharedWasteClassification createMockSharedClassification({
  String id = 'shared1',
  String itemName = 'Plastic Bottle',
  String category = 'Plastic',
  String sharedBy = 'user1',
  String sharedByDisplayName = 'Test User',
  List<FamilyReaction> reactions = const [],
  List<FamilyComment> comments = const [],
}) {
  return SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
    id: id,
    classification: wc_model.WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
      id: 'wc1',
      itemName: itemName,
      category: category,
      explanation: 'A plastic bottle.',
      disposalInstructions: wc_model.DisposalInstructions(primaryMethod: 'Recycle bin', steps: ['Empty', 'Rinse']),
      timestamp: DateTime.now(),
    ),
    sharedBy: sharedBy,
    sharedByDisplayName: sharedByDisplayName,
    sharedAt: DateTime.now(),
    familyId: 'fam1',
    reactions: reactions,
    comments: comments,
  );
}


@GenerateMocks([FirebaseFamilyService, StorageService])
void main() {
  late MockFirebaseFamilyService mockFamilyService;
  late MockStorageService mockStorageService;
  late MockNavigatorObserver mockNavigatorObserver;

  // Stream controllers for dashboard
  late StreamController<Family?> familyStreamController;
  late StreamController<List<SharedWasteClassification>> classificationsStreamController;

  setUp(() {
    mockFamilyService = MockFirebaseFamilyService();
    mockStorageService = MockStorageService();
    mockNavigatorObserver = MockNavigatorObserver();

    familyStreamController = StreamController<Family?>.broadcast();
    classificationsStreamController = StreamController<List<SharedWasteClassification>>.broadcast();

    // Default stubs for services
    when(mockStorageService.getCurrentUserProfile())
        .thenAnswer((_) async => createMockUserProfile());

    when(mockFamilyService.getFamilyStream(any))
        .thenAnswer((_) => familyStreamController.stream);
    when(mockFamilyService.getFamilyClassificationsStream(any, limit: anyNamed('limit')))
        .thenAnswer((_) => classificationsStreamController.stream);
    when(mockFamilyService.getFamilyMembers(any)).thenAnswer((_) async => [createMockUserProfile()]); // For initial member load
  });

  tearDown(() {
    familyStreamController.close();
    classificationsStreamController.close();
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<FirebaseFamilyService>.value(value: mockFamilyService),
        Provider<StorageService>.value(value: mockStorageService),
      ],
      child: MaterialApp(
        home: child,
        navigatorObservers: [mockNavigatorObserver],
        theme: ThemeData(
          primaryColor: AppTheme.primaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
          textTheme: AppTheme.textTheme,
          cardTheme: AppTheme.cardTheme,
          elevatedButtonTheme: AppTheme.elevatedButtonTheme,
        ),
      ),
    );
  }

  group('FamilyDashboardScreen Tests', () {
    testWidgets('Shows "No Family" state when user has no familyId', (WidgetTester tester) async {
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => createMockUserProfile(familyId: '')); // User with no family ID

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      await tester.pumpAndSettle(); // Settle for future to complete

      expect(find.text('Join or Create a Family'), findsOneWidget);
      expect(find.text('Test Family'), findsNothing); // Family name should not be there
    });

    testWidgets('Shows loading indicator initially while fetching familyId', (WidgetTester tester) async {
      // Delay the response from getCurrentUserProfile
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return createMockUserProfile(); // User with family ID
      });

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // Initial loading for familyId

      await tester.pumpAndSettle(); // Let futures complete
      // Now it might show another loader for the family stream, or content
    });

    testWidgets('Shows loading indicator while family stream is connecting', (WidgetTester tester) async {
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => createMockUserProfile()); // User with family ID
      // Don't add data to familyStreamController yet

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      await tester.pump(); // Initial pump for initState
      await tester.pump(); // Pump again for StreamBuilder to pick up initial ConnectionState.waiting

      // After initial familyId load, the StreamBuilder for family data will be in waiting state
      expect(find.byType(CircularProgressIndicator), findsWidgets); // One for family, one for classifications

      familyStreamController.add(createMockFamily()); // Add data to stream
      classificationsStreamController.add([]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Shows error message if family stream has error', (WidgetTester tester) async {
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => createMockUserProfile());

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      await tester.pumpAndSettle(); // Initial setup

      familyStreamController.addError(Exception('Family stream error'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading family details'), findsOneWidget);
    });

    testWidgets('Displays family data correctly from streams', (WidgetTester tester) async {
      final family = createMockFamily(name: 'Streamed Family', totalClassifications: 25, totalPoints: 250);
      final classifications = [
        createMockSharedClassification(itemName: 'Old Newspaper', reactions: [FamilyReaction(userId: 'u2', type: FamilyReactionType.like, timestamp: DateTime.now(), displayName: 'User2')], comments: []),
        createMockSharedClassification(itemName: 'Apple Core', comments: [FamilyComment(id: 'c1', userId: 'u3', text: 'Good job!', timestamp: DateTime.now(), displayName: 'User3')])
      ];

      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile());

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));

      familyStreamController.add(family);
      classificationsStreamController.add(classifications);
      await tester.pumpAndSettle();

      expect(find.text('Streamed Family'), findsOneWidget); // AppBar title
      expect(find.text('25'), findsOneWidget); // Total classifications
      expect(find.text('250'), findsOneWidget); // Total points

      expect(find.text('Old Newspaper'), findsOneWidget);
      expect(find.descendant(of: find.widgetWithText(Card, 'Old Newspaper'), matching: find.text('1')), findsOneWidget); // 1 reaction
      expect(find.descendant(of: find.widgetWithText(Card, 'Old Newspaper'), matching: find.text('0')), findsOneWidget); // 0 comments

      expect(find.text('Apple Core'), findsOneWidget);
      expect(find.descendant(of: find.widgetWithText(Card, 'Apple Core'), matching: find.text('0')), findsOneWidget); // 0 reactions
      expect(find.descendant(of: find.widgetWithText(Card, 'Apple Core'), matching: find.text('1')), findsOneWidget); // 1 comment
    });

    testWidgets('Environmental Impact Tooltips are present with correct messages', (WidgetTester tester) async {
      final family = createMockFamily();
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile());
      familyStreamController.add(family);
      classificationsStreamController.add([]);

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Based on number of recyclable items reported. Each recyclable item is estimated to save 0.5kg of CO₂.'), findsOneWidget);
      expect(find.byTooltip('Based on CO₂ savings. Roughly 22kg of CO₂ saved is equivalent to saving one tree.'), findsOneWidget);
      expect(find.byTooltip('Based on number of recyclable items reported. Each recyclable item is estimated to save 10 liters of water.'), findsOneWidget);
    });

    testWidgets('Navigates to ClassificationDetailsScreen on activity tap', (WidgetTester tester) async {
      final mockClassification = createMockSharedClassification(id: 'detail_test');
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => createMockUserProfile());
      familyStreamController.add(createMockFamily());
      classificationsStreamController.add([mockClassification]);

      await tester.pumpWidget(createTestableWidget(const FamilyDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text(mockClassification.classification.itemName), findsOneWidget);
      await tester.tap(find.text(mockClassification.classification.itemName));
      await tester.pumpAndSettle();

      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(ClassificationDetailsScreen), findsOneWidget);

      // Verify correct classification was passed
      final detailScreen = tester.widget<ClassificationDetailsScreen>(find.byType(ClassificationDetailsScreen));
      expect(detailScreen.classification.id, mockClassification.id);
    });
  });
}
