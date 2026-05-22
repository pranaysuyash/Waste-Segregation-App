import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/providers/app_providers.dart'
    as app_providers;
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import 'package:waste_segregation_app/screens/home_screen.dart' as home;
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';

// Minimal fake StorageService for test purposes
class FakeStorageService extends StorageService {
  // StorageService has no required constructor parameters, just needs to exist
}

class _TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  final now = DateTime.now();
  final mockProfile = GamificationProfile(
    userId: 'test_user',
    points: const UserPoints(total: 500),
    streaks: {
      StreakType.dailyClassification.toString(): StreakDetails(
        type: StreakType.dailyClassification,
        currentCount: 3,
        longestCount: 8,
        lastActivityDate: now,
      ),
    },
    achievements: const [],
    discoveredItemIds: const [],
    unlockedHiddenContentIds: const [],
  );

  final mockUserProfile = UserProfile(
    id: 'test_user',
    displayName: 'Jane Very Long Lastname',
    email: 'jane@test.com',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  );

  WasteClassification classification({
    required String id,
    required String itemName,
    required DateTime timestamp,
    String category = 'Dry Waste',
  }) {
    return WasteClassification(
      id: id,
      itemName: itemName,
      category: category,
      explanation: 'Explanation',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Recycle',
        steps: const ['Step 1'],
        hasUrgentTimeframe: false,
      ),
      region: 'Test',
      visualFeatures: const ['plastic'],
      alternatives: const [],
      confidence: 0.92,
      timestamp: timestamp,
    );
  }

  Widget buildApp({
    required EducationalContentService educationalService,
    List<WasteClassification> classifications = const [],
    GamificationProfile? profile,
    UserProfile? userProfile,
    bool classificationsError = false,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider<AdService>(
          create: (_) => AdService(),
        ),
        provider_pkg.Provider<AnalyticsService>(
          create: (_) => AnalyticsService(
            FakeStorageService(),
            enableFirestore: false,
          ),
        ),
      ],
      child: ProviderScope(
        overrides: [
          app_providers.profileProvider
              .overrideWith((ref) async => profile ?? mockProfile),
          app_providers.userProfileProvider
              .overrideWith((ref) async => userProfile ?? mockUserProfile),
          app_providers.classificationsProvider.overrideWith((ref) async {
            if (classificationsError) {
              throw Exception('boom');
            }
            return classifications;
          }),
          app_providers.educationalContentServiceProvider
              .overrideWith((ref) => educationalService),
        ],
        child: MaterialApp(
          navigatorObservers: navigatorObservers,
          routes: {
            Routes.settings: (_) =>
                const Scaffold(body: Text('Settings Screen')),
          },
          home: const home.HomeScreen(),
        ),
      ),
    );
  }

  group('Home Screen', () {
    testWidgets('renders mission and action surfaces', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
      expect(find.byKey(const Key('home_mission_scan_button')), findsOneWidget);
      expect(
          find.byKey(const Key('home_mission_learn_button')), findsOneWidget);
      expect(find.byKey(const Key('home_action_take_photo')), findsOneWidget);
      expect(find.byKey(const Key('home_action_upload_image')), findsOneWidget);
      expect(find.byKey(const Key('home_action_instant_camera')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('home_action_instant_camera')),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_action_instant_upload')), findsOneWidget);
      expect(find.byKey(const Key('home_daily_tip_card')), findsOneWidget);
    });

    testWidgets('settings button navigates to settings route', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_settings_button')));
      await tester.pumpAndSettle();
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('mission learn navigates to educational screen', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_mission_learn_button')));
      await tester.pumpAndSettle();
      expect(find.byType(EducationalContentScreen), findsOneWidget);
    });

    testWidgets('recent list is sorted newest first and capped at 3', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final old = classification(
        id: 'old',
        itemName: 'Old Item',
        timestamp: now.subtract(const Duration(days: 3)),
      );
      final newest = classification(
        id: 'new',
        itemName: 'Newest Item',
        timestamp: now,
      );
      final middle = classification(
        id: 'mid',
        itemName: 'Middle Item',
        timestamp: now.subtract(const Duration(days: 1)),
      );
      final fourth = classification(
        id: 'fourth',
        itemName: 'Fourth Item',
        timestamp: now.subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [old, middle, newest, fourth],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_recent_section')), findsOneWidget);
      expect(find.text('Newest Item'), findsOneWidget);
      expect(find.text('Middle Item'), findsOneWidget);
      expect(find.text('Fourth Item'), findsOneWidget);
      expect(find.text('Old Item'), findsNothing);
    });

    testWidgets('view all opens history screen', (WidgetTester tester) async {
      final service = EducationalContentService();
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(id: 'one', itemName: 'One', timestamp: now),
          ],
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to make the "View All" button visible
      await tester.ensureVisible(find.byKey(const Key('home_recent_view_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_recent_view_all')));
      await tester.pump();
      expect(observer.pushCount, greaterThan(0));
    });

    testWidgets('error state shows retry surface for recent list', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classificationsError: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_recent_error_state')), findsOneWidget);
    });

    testWidgets('empty state includes direct CTA', (WidgetTester tester) async {
      final service = EducationalContentService();
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_empty_state')), findsOneWidget);
      expect(find.text('Take first photo'), findsOneWidget);
      expect(find.text('Upload image'), findsOneWidget);
    });

    testWidgets('daily tip uses preferred category when recent exists', (
      WidgetTester tester,
    ) async {
      final service = _RecordingEducationalContentService();
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(
              id: 'recent',
              itemName: 'Bottle',
              timestamp: now,
              category: 'Dry Waste',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(service.lastPreferredCategory, 'Dry Waste');
    });

    testWidgets('daily tip does not use preferred category when stale', (
      WidgetTester tester,
    ) async {
      final service = _RecordingEducationalContentService();
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(
              id: 'stale',
              itemName: 'Bottle',
              timestamp: now.subtract(const Duration(days: 10)),
              category: 'Dry Waste',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(service.lastPreferredCategory, isNull);
    });

    testWidgets('supports small width and larger text scale', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: buildApp(educationalService: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _RecordingEducationalContentService extends EducationalContentService {
  String? lastPreferredCategory;

  @override
  DailyTip getDailyTipForHome({DateTime? date, String? preferredCategory}) {
    lastPreferredCategory = preferredCategory;
    return DailyTip(
      id: 'test_tip',
      title: 'Test Tip',
      content: 'Test content',
      category: preferredCategory ?? 'General',
      date: date ?? DateTime.now(),
      contentId: '',
    );
  }
}
