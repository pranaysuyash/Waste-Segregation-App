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
import 'package:waste_segregation_app/providers/points_engine_provider.dart';
import 'package:waste_segregation_app/screens/achievements_screen.dart';
import 'package:waste_segregation_app/screens/content_detail_screen.dart';
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import 'package:waste_segregation_app/screens/home_screen.dart' as home;
import 'package:waste_segregation_app/screens/waste_dashboard_screen.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/routes.dart';

// Minimal fake StorageService for test purposes
class FakeStorageService extends StorageService {
  // StorageService has no required constructor parameters, just needs to exist
}

class _StubGamificationService extends GamificationService {
  _StubGamificationService({
    required GamificationProfile profile,
    this.nearMilestoneNudge,
  }) : _profile = profile,
       super(
         FakeStorageService(),
         CloudStorageService(FakeStorageService()),
       );

  final GamificationProfile _profile;
  final NearMilestoneNudge? nearMilestoneNudge;

  @override
  GamificationProfile? get currentProfile => _profile;

  @override
  Future<NearMilestoneNudge?> getNearMilestoneNudge() async {
    if (nearMilestoneNudge != null) {
      return nearMilestoneNudge;
    }
    return super.getNearMilestoneNudge();
  }
}

class _StaticTipEducationalContentService extends EducationalContentService {
  _StaticTipEducationalContentService({
    required this.tip,
    required this.content,
  });

  final DailyTip tip;
  final EducationalContent content;

  @override
  DailyTip getDailyTipForHome({DateTime? date, String? preferredCategory}) {
    return tip.copyWith(date: date ?? DateTime.now());
  }

  @override
  EducationalContent? getContentById(String id) {
    if (id == content.id) return content;
    return super.getContentById(id);
  }
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
    NearMilestoneNudge? nearMilestoneNudge,
    UserProfile? userProfile,
    bool classificationsError = false,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    final gamificationService = _StubGamificationService(
      profile: profile ?? mockProfile,
      nearMilestoneNudge: nearMilestoneNudge,
    );

    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider<AdService>(
          create: (_) => AdService(),
        ),
        provider_pkg.Provider<EducationalContentService>(
          create: (_) => educationalService,
        ),
        provider_pkg.ChangeNotifierProvider<PointsEngineProvider>(
          create: (_) => PointsEngineProvider(
            FakeStorageService(),
            CloudStorageService(FakeStorageService()),
          ),
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
          app_providers.gamificationServiceProvider
              .overrideWithValue(gamificationService),
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
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(service.lastPreferredCategory, isNull);
    });

    testWidgets('daily progress and near milestone cards reflect the shared goal', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final goalProfile = mockProfile.copyWith(
        weeklyStats: [
          WeeklyStats(
            weekStartDate: now.subtract(const Duration(days: 1)),
            itemsIdentified: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(
              id: 'today-1',
              itemName: 'Bottle',
              timestamp: now,
            ),
            classification(
              id: 'today-2',
              itemName: 'Can',
              timestamp: now.subtract(const Duration(minutes: 1)),
            ),
            classification(
              id: 'yesterday',
              itemName: 'Paper',
              timestamp: now.subtract(const Duration(days: 1)),
            ),
          ],
          profile: goalProfile,
          nearMilestoneNudge: const NearMilestoneNudge(
            type: NudgeType.dailyGoal,
            title: 'Almost there!',
            message: '1 more scan today to reach your daily goal of 3 scans',
            progress: 2,
            target: 3,
            priority: NudgePriority.high,
            iconName: 'flag',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_daily_progress_card')), findsOneWidget);
      expect(find.text('2/3 scans today'), findsOneWidget);
      expect(find.byKey(const Key('home_near_milestone_card')), findsOneWidget);
      expect(
        find.text('1 more scan today to reach your daily goal of 3 scans'),
        findsOneWidget,
      );
    });

    testWidgets('community impact card opens the dashboard', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final observer = _TestNavigatorObserver();
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(
              id: 'community-1',
              itemName: 'Jar',
              timestamp: now,
            ),
          ],
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_community_impact_card')), findsOneWidget);
      expect(find.text('Your Impact'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('home_community_impact_card')));
      await tester.tap(find.byKey(const Key('home_community_impact_card')));
      await tester.pumpAndSettle();
      expect(find.byType(WasteDashboardScreen), findsOneWidget);
    });

    testWidgets('active challenge card opens achievements and shows progress', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final challenge = Challenge(
        id: 'challenge-1',
        title: 'Recycle 5 items',
        description: 'Classify five recyclable items this week.',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 7)),
        pointsReward: 50,
        iconName: 'recycling',
        color: Colors.green,
        requirements: const {'count': 5},
        progress: 0.6,
      );
      final challengeProfile = mockProfile.copyWith(
        activeChallenges: [challenge],
      );

      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          profile: challengeProfile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_active_challenge_card')), findsOneWidget);
      expect(find.text('Recycle 5 items'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('home_active_challenge_card')));
      await tester.tap(find.byKey(const Key('home_active_challenge_card')));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('daily tip contentId opens the detail screen', (
      WidgetTester tester,
    ) async {
      final content = EducationalContent.article(
        id: 'detail-tip-1',
        title: 'Reusable Lunch Boxes',
        description: 'A practical guide to reducing disposable packaging.',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        contentText: 'Choose reusable containers to cut down on single-use waste.',
        categories: const ['Dry Waste'],
        level: ContentLevel.beginner,
        durationMinutes: 3,
      );
      final service = _StaticTipEducationalContentService(
        tip: DailyTip(
          id: 'tip-1',
          title: 'Reduce single-use packaging',
          content: 'Choose reusable containers to cut down on waste.',
          category: 'Dry Waste',
          date: now,
          actionText: 'Read more',
          contentId: content.id,
        ),
        content: content,
      );

      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [
            classification(
              id: 'tip-recent',
              itemName: 'Bottle',
              timestamp: now,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_daily_tip_card')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('home_daily_tip_card')));
      await tester.tap(find.byKey(const Key('home_daily_tip_card')));
      await tester.pumpAndSettle();
      expect(find.byType(ContentDetailScreen), findsOneWidget);
      expect(find.textContaining('single-use waste'), findsOneWidget);
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

      expect(find.byKey(const Key('home_daily_tip_card')), findsOneWidget);
      expect(find.byKey(const Key('home_empty_state')), findsOneWidget);
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
