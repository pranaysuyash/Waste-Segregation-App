import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as pkg_provider;
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/instant_analysis_screen.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

import '../mocks/mock_services.dart';
import '../mocks/mock_cloud_storage_service.dart';

class _NavObserver extends NavigatorObserver {
  int pushes = 0;
  int replaces = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaces += 1;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class _FakeStorageService extends Fake implements StorageService {
  @override
  Future<void> saveClassification(
    WasteClassification classification, {
    bool force = false,
  }) async {}

  @override
  Future<Map<String, dynamic>> getSettings() async => {};
}

class _FakeAnalyticsService extends Fake implements AnalyticsService {
  @override
  Future<void> trackScreenView(String screenName,
          {Map<String, dynamic>? parameters}) async {}

  @override
  void notifyListeners() {}
}

class _FakeCommunityService extends Fake implements CommunityService {}

class _FakeAdService extends Fake implements AdService {
  @override
  bool shouldShowInterstitial() => false;

  @override
  void notifyListeners() {}
}

void main() {
  group('Navigation - InstantAnalysisScreen', () {
    testWidgets('pushReplacement navigates to ResultScreen exactly once',
        (WidgetTester tester) async {
      final aiService = MockAiService();
      final gamificationService = MockGamificationService();
      final storageService = _FakeStorageService();
      final cloudStorageService = MockCloudStorageService(storageService);
      final communityService = _FakeCommunityService();
      final analyticsService = _FakeAnalyticsService();
      final adService = _FakeAdService();
      final observer = _NavObserver();

      final tmpDir = await Directory.systemTemp.createTemp('waste_app_test_');
      final tmpFile = File('${tmpDir.path}/image.jpg')
        ..writeAsBytesSync([0, 1, 2, 3]);
      addTearDown(() async {
        try {
          await tmpDir.delete(recursive: true);
        } catch (_) {}
      });

      final image = XFile(tmpFile.path);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            cloudStorageServiceProvider
                .overrideWithValue(cloudStorageService),
            communityServiceProvider.overrideWithValue(communityService),
            adServiceProvider.overrideWithValue(adService),
            analyticsServiceProvider.overrideWithValue(analyticsService),
            gamificationServiceProvider.overrideWithValue(gamificationService),
            aiServiceProvider.overrideWithValue(aiService),
            resultPipelineProvider.overrideWith((ref) {
              return ResultPipeline(
                storageService,
                gamificationService,
                cloudStorageService,
                communityService,
                adService,
                analyticsService,
              );
            }),
          ],
          child: pkg_provider.MultiProvider(
            providers: [
              pkg_provider.Provider<AiService>.value(value: aiService),
              pkg_provider.Provider<GamificationService>.value(
                  value: gamificationService),
            ],
            child: MaterialApp(
              home: InstantAnalysisScreen(image: image),
              navigatorObservers: [observer],
            ),
          ),
        ),
      );

      // Let analysis + navigation complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(observer.replaces, 1,
          reason:
              'InstantAnalysisScreen should replace itself once');
    });
  });
}
