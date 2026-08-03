import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart'
    show DisposalInstructions, WasteClassification;
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/providers/disposal_instructions_provider.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/disposal_instructions_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> trackScreenView(String screenName,
          {Map<String, dynamic>? parameters}) =>
      super.noSuchMethod(
        Invocation.method(
            #trackScreenView, [screenName], {#parameters: parameters}),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) =>
      super.noSuchMethod(
        Invocation.method(#trackEvent, const [], {
          #eventType: eventType,
          #eventName: eventName,
          #parameters: parameters,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;
}

class MockGamificationService extends Mock implements GamificationService {
  @override
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) =>
      super.noSuchMethod(
        Invocation.method(
          #getProfile,
          const [],
          {#forceRefresh: forceRefresh},
        ),
        returnValue:
            Future<GamificationProfile>.value(const GamificationProfile(
          userId: 'u1',
          streaks: {},
          points: UserPoints(),
        )),
        returnValueForMissingStub:
            Future<GamificationProfile>.value(const GamificationProfile(
          userId: 'u1',
          streaks: {},
          points: UserPoints(),
        )),
      ) as Future<GamificationProfile>;

  @override
  Future<NearMilestoneNudge?> getNearMilestoneNudge() => super.noSuchMethod(
        Invocation.method(#getNearMilestoneNudge, const []),
        returnValue: Future<NearMilestoneNudge?>.value(),
        returnValueForMissingStub: Future<NearMilestoneNudge?>.value(),
      ) as Future<NearMilestoneNudge?>;
}

class MockStorageService extends Mock implements StorageService {
  @override
  Future<List<WasteClassification>> getAllClassifications(
          {FilterOptions? filterOptions}) =>
      super.noSuchMethod(
        Invocation.method(
          #getAllClassifications,
          const [],
          {#filterOptions: filterOptions},
        ),
        returnValue: Future<List<WasteClassification>>.value(const []),
        returnValueForMissingStub:
            Future<List<WasteClassification>>.value(const []),
      ) as Future<List<WasteClassification>>;

  @override
  Future<UserProfile?> getCurrentUserProfile() => super.noSuchMethod(
        Invocation.method(#getCurrentUserProfile, const []),
        returnValue: Future<UserProfile?>.value(),
        returnValueForMissingStub: Future<UserProfile?>.value(),
      ) as Future<UserProfile?>;

  @override
  Future<void> saveUserProfile(UserProfile userProfile) => super.noSuchMethod(
        Invocation.method(#saveUserProfile, [userProfile]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;
}

class MockStorageServiceForCompletion extends MockStorageService {
  UserProfile? lastSavedProfile;

  @override
  Future<void> saveUserProfile(UserProfile userProfile) async {
    lastSavedProfile = userProfile;
  }
}

class MockCloudStorageService extends Mock implements CloudStorageService {}

class MockCommunityService extends Mock implements CommunityService {}

class MockAdService extends Mock implements AdService {}

class FakeDisposalInstructionsService extends DisposalInstructionsService {
  @override
  Future<DisposalInstructions> getDisposalInstructions({
    required String material,
    String? category,
    String? subcategory,
    String lang = 'en',
  }) async {
    return DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Recycle'],
      hasUrgentTimeframe: false,
    );
  }

  @override
  Future<void> preloadCommonMaterials() async {}

  @override
  void clearCache() {}
}

WasteClassification _classification() {
  return WasteClassification(
    id: 'c1',
    itemName: 'Plastic Bottle',
    category: 'Dry Waste',
    subCategory: 'Plastic',
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Recycle'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['bottle'],
    alternatives: const [],
    confidence: 0.9,
    timestamp: DateTime.now(),
    userId: 'u1',
    imageRelativePath: 'images/test.jpg',
  );
}

void main() {
  group('ResultScreen', () {
    testWidgets(
      'loads and renders completion handover state when actions are enabled',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        final profile = UserProfile(
          id: 'u1',
          preferences: {
            UserPreferenceKeys.disposalCompletionHistory: {
              'c1': {
                'status': 'blocked',
                'notes': 'Bucket kept outside',
                'recordedAt': '2026-08-03T09:00:00Z',
                'policySnapshot': {
                  'policy_pickup_collector': 'BBMP zonal collection teams',
                  'policy_pickup_zone': 'South pilot wards',
                },
                'pickupOptions': [
                  {
                    'policyKey': 'policy_pickup_collector',
                    'title': 'Contact the collector',
                    'detail': 'BBMP zonal collection teams',
                  },
                ],
                'followUp': {
                  'required': true,
                  'policyKey': 'policy_pickup_collector',
                  'action': 'Contact the collector',
                },
              },
            },
          },
        );

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);
        when(storageService.getCurrentUserProfile()).thenAnswer(
          (_) async => profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: _classification(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Completion handover'), findsOneWidget);
        expect(
          find.text('Last recorded: 2026-08-03T09:00:00Z'),
          findsOneWidget,
        );
        expect(find.text('Blocked / requires follow-up'), findsOneWidget);
        expect(find.text('Alternative pickup options'), findsOneWidget);
        expect(find.text('Follow-up required'), findsOneWidget);
        expect(find.text('Contact the collector'), findsOneWidget);
        expect(find.byKey(const Key('completion_follow_up_open_facilities')),
            findsOneWidget);
      },
    );

    testWidgets(
      'saves completion handover status to user profile preferences',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageServiceForCompletion();

        final profile = UserProfile(
          id: 'u1',
          preferences: {},
        );

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);
        when(storageService.getCurrentUserProfile()).thenAnswer(
          (_) async => profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: _classification(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        final saveButton = find.text('Save completion status');
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(storageService.lastSavedProfile, isNotNull);
        final history = storageService.lastSavedProfile!
                .preferences?[UserPreferenceKeys.disposalCompletionHistory]
            as Map<String, dynamic>?;
        expect(history, isNotNull);
        final savedOutcome =
            (history!['c1'] as Map<String, dynamic>?)?['status'];
        expect(savedOutcome, 'not_recorded');
        final savedItemName =
            (history['c1'] as Map<String, dynamic>?)?['itemName'];
        expect(savedItemName, 'Plastic Bottle');
      },
    );

    testWidgets(
      'persists policy-backed pickup choice and follow-up workflow',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageServiceForCompletion();

        final profile = UserProfile(id: 'u1', preferences: {});
        final classification = _classification().copyWith(
          localRegulations: const {
            'collection_frequency': 'alternate_days',
            'collection_time_window': '6:00 AM - 9:00 AM',
            'policy_pickup_area': 'Bengaluru Municipal Boundaries',
            'policy_pickup_zone': 'South pilot wards',
            'policy_pickup_collector': 'BBMP zonal collection teams',
            'policy_helpline': '1800-425-1442',
          },
        );

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);
        when(storageService.getCurrentUserProfile()).thenAnswer(
          (_) async => profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: classification,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Alternative pickup options'), findsOneWidget);
        expect(find.text('Scheduled collection'), findsOneWidget);
        expect(find.text('Pickup area'), findsOneWidget);

        final collectorOption = find.byKey(
          const Key('completion_pickup_option_policy_pickup_collector'),
        );
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1600),
        );
        await tester.pumpAndSettle();
        await tester.tap(collectorOption);
        await tester.pumpAndSettle();

        final saveButton = find.text('Save completion status');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        final saved = storageService.lastSavedProfile!;
        final history =
            saved.preferences?[UserPreferenceKeys.disposalCompletionHistory]
                as Map<String, dynamic>;
        final record = history['c1'] as Map<String, dynamic>;
        expect(
            record['policySnapshot'],
            containsPair(
              'policy_pickup_collector',
              'BBMP zonal collection teams',
            ));
        expect(record['pickupOptions'], isA<List<dynamic>>());
        expect(record['followUp'], containsPair('required', true));
        expect(
            record['followUp'],
            containsPair(
              'policyKey',
              'policy_pickup_collector',
            ));
        expect(
            record['followUp'],
            containsPair(
              'action',
              'Contact the collector',
            ));

        final last =
            saved.preferences?[UserPreferenceKeys.disposalCompletionLast]
                as Map<String, dynamic>;
        expect(last['followUpRequired'], true);
        expect(last['followUpPolicyKey'], 'policy_pickup_collector');
      },
    );

    testWidgets('renders for an existing classification', (tester) async {
      final analyticsService = MockAnalyticsService();
      final gamificationService = MockGamificationService();
      final storageService = MockStorageService();

      when(gamificationService.getProfile()).thenAnswer(
        (_) async => const GamificationProfile(
          userId: 'u1',
          streaks: {},
          points: UserPoints(total: 10),
        ),
      );
      when(storageService.getAllClassifications())
          .thenAnswer((_) async => const []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            gamificationServiceProvider.overrideWithValue(gamificationService),
            cloudStorageServiceProvider.overrideWithValue(
              MockCloudStorageService(),
            ),
            communityServiceProvider.overrideWithValue(
              MockCommunityService(),
            ),
            adServiceProvider.overrideWithValue(MockAdService()),
            analyticsServiceProvider.overrideWithValue(analyticsService),
            resultPipelineProvider.overrideWith(
              (ref) => ResultPipeline(
                storageService,
                gamificationService,
                MockCloudStorageService(),
                MockCommunityService(),
                MockAdService(),
                analyticsService,
              ),
            ),
            disposalInstructionsServiceProvider
                .overrideWithValue(FakeDisposalInstructionsService()),
          ],
          child: MaterialApp(
            home: ResultScreen(
              classification: _classification(),
              showActions: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Complete this item now'), findsOneWidget);

      // Allow staggered list timers/animations to complete so the test binding
      // doesn't report pending timers.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('shows analysis source in the snapshot card', (tester) async {
      final analyticsService = MockAnalyticsService();
      final gamificationService = MockGamificationService();
      final storageService = MockStorageService();

      when(gamificationService.getProfile()).thenAnswer(
        (_) async => const GamificationProfile(
          userId: 'u1',
          streaks: {},
          points: UserPoints(total: 10),
        ),
      );
      when(storageService.getAllClassifications())
          .thenAnswer((_) async => const []);

      final classification = _classification().copyWith(
        analysisSource: WasteClassification.analysisSourceLocalExperimental,
        analysisFallbackReason: 'placeholder_local_model',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            gamificationServiceProvider.overrideWithValue(gamificationService),
            cloudStorageServiceProvider.overrideWithValue(
              MockCloudStorageService(),
            ),
            communityServiceProvider.overrideWithValue(
              MockCommunityService(),
            ),
            adServiceProvider.overrideWithValue(MockAdService()),
            analyticsServiceProvider.overrideWithValue(analyticsService),
            resultPipelineProvider.overrideWith(
              (ref) => ResultPipeline(
                storageService,
                gamificationService,
                MockCloudStorageService(),
                MockCommunityService(),
                MockAdService(),
                analyticsService,
              ),
            ),
            disposalInstructionsServiceProvider
                .overrideWithValue(FakeDisposalInstructionsService()),
          ],
          child: MaterialApp(
            home: ResultScreen(
              classification: classification,
              showActions: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Analysis Source: Local experimental'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
      'shows correction panel when actions are enabled',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: _classification(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Was this correct?'), findsOneWidget);
        expect(find.text('Correct it'), findsOneWidget);
        expect(find.text('Correct it'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'does not show nudge card when no near milestone exists',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 200),
          ),
        );
        when(gamificationService.getNearMilestoneNudge()).thenAnswer(
          (_) async => null,
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: _classification(),
                showActions: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Almost there!'), findsNothing);
      },
    );

    testWidgets(
      'shows nudge card when near milestone exists',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        const nudge = NearMilestoneNudge(
          type: NudgeType.dailyGoal,
          title: 'Almost there!',
          message: '1 more scan today to reach your daily goal of 5 scans',
          progress: 4,
          target: 5,
          priority: NudgePriority.high,
          iconName: 'flag',
        );

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 50),
          ),
        );
        when(gamificationService.getNearMilestoneNudge()).thenAnswer(
          (_) async => nudge,
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(
                classification: _classification(),
                showActions: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Almost there!'), findsOneWidget);
        expect(
          find.text('1 more scan today to reach your daily goal of 5 scans'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows learn more card for hazardous waste classification',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);

        final classification = _classification().copyWith(
          category: 'Hazardous Waste',
          subCategory: 'Chemicals',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(classification: classification),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Learn more'), findsAtLeastNWidgets(1));
        expect(
          find.text('How to safely dispose hazardous household items'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'hides learn more card for non-matching category',
      (tester) async {
        final analyticsService = MockAnalyticsService();
        final gamificationService = MockGamificationService();
        final storageService = MockStorageService();

        when(gamificationService.getProfile()).thenAnswer(
          (_) async => const GamificationProfile(
            userId: 'u1',
            streaks: {},
            points: UserPoints(total: 10),
          ),
        );
        when(storageService.getAllClassifications())
            .thenAnswer((_) async => const []);

        final classification = _classification().copyWith(
          category: 'Sanitary Waste',
          subCategory: 'Diapers',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              gamificationServiceProvider
                  .overrideWithValue(gamificationService),
              cloudStorageServiceProvider.overrideWithValue(
                MockCloudStorageService(),
              ),
              communityServiceProvider.overrideWithValue(
                MockCommunityService(),
              ),
              adServiceProvider.overrideWithValue(MockAdService()),
              analyticsServiceProvider.overrideWithValue(analyticsService),
              resultPipelineProvider.overrideWith(
                (ref) => ResultPipeline(
                  storageService,
                  gamificationService,
                  MockCloudStorageService(),
                  MockCommunityService(),
                  MockAdService(),
                  analyticsService,
                ),
              ),
              disposalInstructionsServiceProvider
                  .overrideWithValue(FakeDisposalInstructionsService()),
            ],
            child: MaterialApp(
              home: ResultScreen(classification: classification),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Learn more'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
