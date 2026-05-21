import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
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

import '../fixtures/classifications/fixtures.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> trackScreenView(String screenName,
          {Map<String, dynamic>? parameters}) =>
      Future<void>.value();

  @override
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) =>
      Future<void>.value();
}

class MockGamificationService extends Mock implements GamificationService {
  @override
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) =>
      Future<GamificationProfile>.value(const GamificationProfile(
        userId: 'u1',
        streaks: {},
        points: UserPoints(total: 10),
      ));

  @override
  Future<NearMilestoneNudge?> getNearMilestoneNudge() =>
      Future<NearMilestoneNudge?>.value(null);
}

class MockStorageService extends Mock implements StorageService {
  @override
  Future<List<WasteClassification>> getAllClassifications(
          {dynamic filterOptions}) =>
      Future<List<WasteClassification>>.value(const []);

  @override
  Future<UserProfile?> getCurrentUserProfile() => Future.value(null);
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

void main() {
  group('ResultScreen V2 Golden Tests', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    Widget buildTestWrapper(WasteClassification classification,
        {bool darkTheme = false}) {
      final baseTheme = darkTheme ? ThemeData.dark() : ThemeData.light();
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(MockStorageService()),
          gamificationServiceProvider
              .overrideWithValue(MockGamificationService()),
          cloudStorageServiceProvider
              .overrideWithValue(MockCloudStorageService()),
          communityServiceProvider.overrideWithValue(MockCommunityService()),
          adServiceProvider.overrideWithValue(MockAdService()),
          analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
          resultPipelineProvider.overrideWith(
            (ref) => ResultPipeline(
              MockStorageService(),
              MockGamificationService(),
              MockCloudStorageService(),
              MockCommunityService(),
              MockAdService(),
              MockAnalyticsService(),
            ),
          ),
          disposalInstructionsServiceProvider
              .overrideWithValue(FakeDisposalInstructionsService()),
        ],
        child: MaterialApp(
          theme: baseTheme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: darkTheme ? Brightness.dark : Brightness.light,
            ),
          ),
          home: Scaffold(
            body: ResultScreen(
              classification: classification,
              showActions: false,
            ),
          ),
        ),
      );
    }

    testGoldens('High Confidence Classification State', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      builder.addScenario(
        widget: buildTestWrapper(plasticBottleFixture),
        name: 'high_confidence_light',
      );

      builder.addScenario(
        widget: buildTestWrapper(plasticBottleFixture, darkTheme: true),
        name: 'high_confidence_dark',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'result_screen_v2_high_confidence');
    });

    testGoldens('Low Confidence Classification State', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      builder.addScenario(
        widget: buildTestWrapper(unknownLowConfidenceFixture),
        name: 'low_confidence_light',
      );

      builder.addScenario(
        widget: buildTestWrapper(unknownLowConfidenceFixture, darkTheme: true),
        name: 'low_confidence_dark',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'result_screen_v2_low_confidence');
    });

    testGoldens('Hazardous Classification State', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ]);

      builder.addScenario(
        widget: buildTestWrapper(requiresPPEFixture),
        name: 'hazardous_light',
      );

      builder.addScenario(
        widget: buildTestWrapper(requiresPPEFixture, darkTheme: true),
        name: 'hazardous_dark',
      );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'result_screen_v2_hazardous');
    });
  });
}
