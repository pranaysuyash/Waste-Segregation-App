import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart' show AlternativeClassification;
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
  Future<NearMilestoneNudge?> getNearMilestoneNudge() =>
      super.noSuchMethod(
        Invocation.method(#getNearMilestoneNudge, const []),
        returnValue: Future<NearMilestoneNudge?>.value(null),
        returnValueForMissingStub: Future<NearMilestoneNudge?>.value(null),
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
  Future<UserProfile?> getCurrentUserProfile() =>
      super.noSuchMethod(
        Invocation.method(#getCurrentUserProfile, const []),
        returnValue: Future.value(null),
      ) as Future<UserProfile?>;
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
    subcategory: 'Plastic',
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

      // Allow staggered list timers/animations to complete so the test binding
      // doesn't report pending timers.
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

        final nudge = NearMilestoneNudge(
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
          subcategory: 'Chemicals',
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

        expect(find.text('Learn more'), findsOneWidget);
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
          subcategory: 'Diapers',
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
