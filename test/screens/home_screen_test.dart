import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/providers/app_providers.dart'
    as app_providers;
import 'package:waste_segregation_app/screens/content_detail_screen.dart';
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import 'package:waste_segregation_app/screens/disposal_completion_history_screen.dart';
import 'package:waste_segregation_app/screens/home_screen.dart' as home;
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
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
  })  : _profile = profile,
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

    return ProviderScope(
      overrides: [
        app_providers.adServiceProvider.overrideWithValue(AdService()),
        app_providers.educationalContentServiceProvider
            .overrideWithValue(educationalService),
        app_providers.analyticsServiceProvider.overrideWithValue(
          AnalyticsService(
            FakeStorageService(),
            enableFirestore: false,
          ),
        ),
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
          Routes.settings: (_) => const Scaffold(body: Text('Settings Screen')),
        },
        home: const home.HomeScreen(),
      ),
    );
  }

  group('Home Screen', () {
    Future<void> ensureActionVisible(
      WidgetTester tester,
      Key key,
    ) async {
      final target = find.byKey(key);
      if (target.evaluate().isEmpty) {
        fail('Action tile not found: $key');
      }

      await tester.ensureVisible(target);
      await tester.pump();
    }

    testWidgets('renders PMF-focused home surfaces', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
      expect(find.byKey(const Key('home_area_schedule_card')), findsOneWidget);
      expect(find.text('Area updates and pickup events'), findsOneWidget);
      await ensureActionVisible(tester, const Key('home_action_scan'));
      expect(find.byKey(const Key('home_action_scan')), findsOneWidget);
      await ensureActionVisible(tester, const Key('home_action_upload'));
      expect(find.byKey(const Key('home_action_upload')), findsOneWidget);
      await ensureActionVisible(tester, const Key('home_action_guidance'));
      expect(find.byKey(const Key('home_action_guidance')), findsOneWidget);
      await ensureActionVisible(tester, const Key('home_action_history'));
      expect(find.byKey(const Key('home_action_history')), findsOneWidget);
      await ensureActionVisible(tester, const Key('home_action_completion'));
      expect(find.byKey(const Key('home_action_completion')), findsOneWidget);
      expect(find.byKey(const Key('home_daily_tip_card')), findsOneWidget);
    });

    testWidgets(
        'shows area schedule coverage, pickup zones, and notice details', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      final scheduleCard = find.byKey(const Key('home_area_schedule_card'));
      expect(scheduleCard, findsOneWidget);
      expect(
          find.descendant(
              of: scheduleCard, matching: find.text('Zone coverage')),
          findsOneWidget);
      expect(
        find.descendant(
          of: scheduleCard,
          matching:
              find.textContaining('Bengaluru South + central pilot wards'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scheduleCard, matching: find.text('Today')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scheduleCard, matching: find.text('Tomorrow')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.text('Upcoming windows'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.textContaining('Pickup confidence: high'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.textContaining('Last verified: 2026-07-30'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching:
              find.textContaining('BBMP Bengaluru South + central pilot wards'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.text('Community notices'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.text('E-waste Collection Drive'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.textContaining('Schedule exceptions'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.text('Dry waste delayed'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.text('When: Saturday'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scheduleCard, matching: find.text('Next step')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.textContaining(
              'Prepare the item and take it to the listed location'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduleCard,
          matching: find.textContaining(
              'Keep this stream separate and use the updated pickup window'),
        ),
        findsOneWidget,
      );
    });

    test('delegates source-qualified pickup metadata and exact weekdays', () {
      final plugin = BBMPBangalorePlugin();
      final pickupZones = plugin.getPickupZones();
      final dryWasteSchedule = plugin.getCollectionSchedule()['dry_waste'];

      expect(pickupZones['zone_confidence'], 'high');
      expect(pickupZones['last_verified'], '2026-07-30');
      expect(pickupZones['source'], 'BBMP SWM Operations Dashboard');
      expect(dryWasteSchedule, isA<Map<String, dynamic>>());
      expect(
        (dryWasteSchedule! as Map<String, dynamic>)['days'],
        containsAll(<String>['Monday', 'Wednesday', 'Friday']),
      );
    });

    testWidgets('shows pickup reminders card for next area collection windows',
        (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      final reminderCard = find.byKey(const Key('home_pickup_reminder_card'));
      expect(reminderCard, findsOneWidget);
      expect(
        find.descendant(
          of: reminderCard,
          matching: find.text('Collection reminders'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: reminderCard,
          matching: find.textContaining('Window: 6:00 AM - 9:00 AM'),
        ),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.descendant(
          of: reminderCard,
          matching: find.textContaining('Wet Waste'),
        ),
        findsOneWidget,
      );
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

    testWidgets('guidance action navigates to educational screen', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(buildApp(educationalService: service));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('home_action_guidance')));
      await ensureActionVisible(tester, const Key('home_action_guidance'));
      await tester.tap(find.byKey(const Key('home_action_guidance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(EducationalContentScreen), findsOneWidget);
    });

    testWidgets('history action opens recent decisions screen', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final observer = _TestNavigatorObserver();
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      await ensureActionVisible(tester, const Key('home_action_history'));
      await tester.tap(find.byKey(const Key('home_action_history')));
      await tester.pump();

      expect(observer.pushCount, greaterThan(0));
    });

    testWidgets('completion history action opens completion tracking screen', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final observer = _TestNavigatorObserver();
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      await ensureActionVisible(tester, const Key('home_action_completion'));
      await tester.tap(find.byKey(const Key('home_action_completion')));
      await tester.pumpAndSettle();

      expect(observer.pushCount, greaterThan(0));
      expect(find.byType(DisposalCompletionHistoryScreen), findsOneWidget);
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

    testWidgets('shows pending special item highlights', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final urgentClassification = classification(
        id: 'urgent-1',
        itemName: 'Expired Batteries',
        timestamp: now,
        category: 'Hazardous Waste',
      ).copyWith(requiresSpecialDisposal: true);

      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [urgentClassification],
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('home_pending_special_card')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home_pending_special_card')),
          matching: find.textContaining('Expired Batteries'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows recent disposal completion summary when available', (
      WidgetTester tester,
    ) async {
      final observer = _TestNavigatorObserver();
      final service = EducationalContentService();
      final userProfileWithCompletion = UserProfile(
        id: 'test_user',
        preferences: {
          UserPreferenceKeys.disposalCompletionLast: {
            'classificationId': 'abc-123',
            'status': 'pickup_booked',
            'recordedAt': '2026-08-03T10:00:00.000Z',
            'notes': 'Picked up today at 6 PM',
          },
        },
      );

      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          userProfile: userProfileWithCompletion,
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('home_completion_summary_card'));
      expect(card, findsOneWidget);
      expect(
          find.descendant(
              of: card, matching: find.text('Last disposal completion')),
          findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('Status: Pickup booked'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('Recorded: 2026-08-03T10:00:00.000Z'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining('Picked up today at 6 PM'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home_completion_summary_card_open_history')),
        findsOneWidget,
      );

      await ensureActionVisible(
        tester,
        const Key('home_completion_summary_card_update'),
      );
      await tester.tap(
        find.byKey(const Key('home_completion_summary_card_update')),
      );
      await tester.pumpAndSettle();
      expect(observer.pushCount, greaterThan(1));
      expect(find.byType(DisposalCompletionHistoryScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await ensureActionVisible(
        tester,
        const Key('home_completion_summary_card_open_history'),
      );
      await tester.tap(
        find.byKey(const Key('home_completion_summary_card_open_history')),
      );
      await tester.pumpAndSettle();
      expect(observer.pushCount, greaterThan(2));
      expect(find.byType(DisposalCompletionHistoryScreen), findsOneWidget);
    });

    testWidgets('shows pending completion follow-up card and opens history', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      final observer = _TestNavigatorObserver();
      final userProfileWithPendingFollowUp = UserProfile(
        id: 'test_user',
        preferences: {
          UserPreferenceKeys.disposalCompletionHistory: {
            'abc-123': {
              'classificationId': 'abc-123',
              'itemName': 'Old batteries',
              'status': 'blocked',
              'recordedAt': '2026-08-03T09:00:00.000Z',
              'followUp': {
                'required': true,
                'action': 'Take batteries to hazardous facility',
              },
            },
            'xyz-456': {
              'classificationId': 'xyz-456',
              'itemName': 'Disposable cup',
              'status': 'prepared',
              'recordedAt': '2026-08-03T10:00:00.000Z',
              'followUp': {'required': false},
            },
          },
        },
      );

      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          userProfile: userProfileWithPendingFollowUp,
          navigatorObservers: [observer],
        ),
      );
      await tester.pumpAndSettle();

      final followUpCard =
          find.byKey(const Key('home_completion_followup_card'));
      expect(followUpCard, findsOneWidget);
      expect(
        find.descendant(
          of: followUpCard,
          matching: find.textContaining('Pending disposal follow-ups'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: followUpCard,
          matching: find.textContaining('Old batteries'),
        ),
        findsOneWidget,
      );

      await ensureActionVisible(
        tester,
        const Key('home_completion_followup_card_open_all'),
      );
      await tester
          .tap(find.byKey(const Key('home_completion_followup_card_open_all')));
      await tester.pumpAndSettle();
      expect(observer.pushCount, 2);
      expect(find.byType(DisposalCompletionHistoryScreen), findsOneWidget);
    });

    testWidgets('daily tip contentId opens the detail screen', (
      WidgetTester tester,
    ) async {
      final content = EducationalContent.article(
        id: 'detail-tip-1',
        title: 'Reusable Lunch Boxes',
        description: 'A practical guide to reducing disposable packaging.',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        contentText:
            'Choose reusable containers to cut down on single-use waste.',
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
      await tester.scrollUntilVisible(
        find.byKey(const Key('home_daily_tip_card')),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
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
