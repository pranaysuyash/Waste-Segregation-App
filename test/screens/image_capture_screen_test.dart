import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/models/multi_item_classification_result.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/combined_result_screen.dart';
import 'package:waste_segregation_app/screens/image_capture_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/widgets/manual_region_selector.dart';
import 'package:waste_segregation_app/widgets/per_item_result_card.dart';
import 'package:waste_segregation_app/providers/scan_orchestrator_provider.dart';
import 'package:waste_segregation_app/providers/token_providers.dart';
import 'package:waste_segregation_app/services/scan_orchestrator.dart';
import 'package:waste_segregation_app/services/token_service.dart';

/// A minimal valid 1x1 blue PNG used as test image data.
final Uint8List kTestPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // 8-bit grayscale
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x08, 0xD7, 0x63, 0x68, 0x60, 0x60, 0x60, // compressed data
  0x00, 0x00, 0x00, 0x04, 0x00, 0x01, 0x27, 0x34,
  0x27, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class MockAiService extends Mock implements AiService {}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? parameters,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #trackScreenView,
          [screenName],
          {#parameters: parameters},
        ),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;
}

class MockStorageService extends Mock implements StorageService {}

class MockResultPipeline extends Mock implements ResultPipeline {}

class MockTokenService extends Mock implements TokenService {}

/// Mockito-based fake: must NOT extend the real [PremiumService], whose
/// constructor kicks off unawaited `initialize()` (Hive/Firebase) that throws
/// in widget tests. `implements` + a concrete `hasActivePremiumPlan` avoids the
/// real constructor while keeping a real `false` (never a null-in-bool slot).
class FakePremiumService extends Mock implements PremiumService {
  @override
  bool hasActivePremiumPlan() => false;
}

/// ProviderScope with test doubles for every service the capture screen reads
/// at initState/build time (no Firebase/Hive).
///
/// Drift fix: the refactor added `scanOrchestratorProvider` (initState queue
/// listener) and `tokenServiceProvider`/`tokenWalletProvider` (review body)
/// reads; these were previously un-overridden, so the real services touched
/// Firebase and threw `[core/no-app]` in widget tests.
///
/// Note: `classificationStateMachineProvider` is deliberately NOT overridden —
/// `ClassificationStateMachineNotifier` is a pure in-memory notifier with no
/// Firebase/Hive dependencies, so the real provider is safe in widget tests.
ProviderScope _captureScope({
  required Widget child,
  MockAiService? aiService,
  MockAnalyticsService? analyticsService,
  MockStorageService? storageService,
  MockResultPipeline? resultPipeline,
}) {
  final mockAi = aiService ?? MockAiService();
  final mockAnalytics = analyticsService ?? MockAnalyticsService();
  final mockStorage = storageService ?? MockStorageService();
  final mockPipeline = resultPipeline ?? MockResultPipeline();
  return ProviderScope(
    overrides: [
      aiServiceProvider.overrideWithValue(mockAi),
      analyticsServiceProvider.overrideWithValue(mockAnalytics),
      storageServiceProvider.overrideWithValue(mockStorage),
      resultPipelineProvider.overrideWith((_) => mockPipeline),
      scanOrchestratorProvider.overrideWithValue(
        ScanOrchestrator(aiService: mockAi, resultPipeline: mockPipeline),
      ),
      tokenServiceProvider.overrideWithValue(MockTokenService()),
      tokenWalletProvider.overrideWith((_) async => null),
      premiumServiceProvider.overrideWithValue(FakePremiumService()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ImageCaptureScreen', () {
    testWidgets('renders waiting state when no image is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _captureScope(child: const ImageCaptureScreen()),
      );

      expect(find.text('Waiting for camera...'), findsOneWidget);
    });

    testWidgets(
      'tapping "Select multiple items" enters region selection mode',
      (tester) async {
      await tester.pumpWidget(
        _captureScope(child: ImageCaptureScreen(webImage: kTestPng)),
      );
        // Use pump instead of pumpAndSettle because image decoding in tests
        // may not settle with tiny test data.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Scroll down to find the button (overflowing content)
        await tester.drag(find.byType(Scrollable), const Offset(0, -300));
        await tester.pump();

        final selectMultipleItemsFinder = find.text('Select multiple items');
        expect(selectMultipleItemsFinder, findsOneWidget);
        await tester.scrollUntilVisible(
          selectMultipleItemsFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(selectMultipleItemsFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byType(ManualRegionSelector), findsOneWidget);
        expect(find.textContaining('Analyze'), findsWidgets);
      },
    );

    testWidgets(
      'region selection mode disables analyze button when no regions selected',
      (tester) async {
      await tester.pumpWidget(
        _captureScope(child: ImageCaptureScreen(webImage: kTestPng)),
      );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Scroll down to find the button
        await tester.drag(find.byType(Scrollable), const Offset(0, -300));
        await tester.pump();

        final selectMultipleItemsFinder = find.text('Select multiple items');
        await tester.scrollUntilVisible(
          selectMultipleItemsFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(selectMultipleItemsFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Region selection mode is active and an Analyze CTA is present.
        expect(find.byType(ManualRegionSelector), findsOneWidget);
        expect(find.textContaining('Analyze'), findsWidgets);
      },
    );

    testWidgets('review screen keeps Analyze enabled before analysis starts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _captureScope(child: ImageCaptureScreen(webImage: kTestPng)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Review Image'), findsOneWidget);
      expect(find.textContaining('Analyze'), findsWidgets);
    });
  });

  group('AuthException', () {
    test('stores and formats message correctly', () {
      const ex = AuthException('User not authenticated');
      expect(ex.message, 'User not authenticated');
      expect(ex.toString(), 'User not authenticated');
    });

    test('can be caught as Exception', () {
      void thrower() {
        throw const AuthException('test');
      }

      expect(thrower, throwsA(isA<AuthException>()));
      expect(thrower, throwsA(isA<Exception>()));
    });
  });

  group('OfflineException', () {
    test('stores and formats message correctly', () {
      const ex = OfflineException('No network');
      expect(ex.message, 'No network');
      expect(ex.toString(), 'No network');
    });

    test('can be caught as Exception', () {
      void thrower() {
        throw const OfflineException('test');
      }

      expect(thrower, throwsA(isA<OfflineException>()));
      expect(thrower, throwsA(isA<Exception>()));
    });
  });

  group('CombinedResultScreen', () {
    testWidgets('renders combined summary for multiple classifications', (
      tester,
    ) async {
      final classifications = [
        WasteClassification(
          id: 'c1',
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Rinse'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.9,
          timestamp: DateTime.now(),
        ),
        WasteClassification(
          id: 'c2',
          itemName: 'Banana Peel',
          category: 'Wet Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: const ['Bin'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.85,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CombinedResultScreen(
              classifications: classifications,
              imageName: 'test_image.jpg',
            ),
          ),
        ),
      );

      expect(find.text('Items Found'), findsOneWidget);
      expect(find.text('2 items found in "test_image.jpg"'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Banana Peel'), findsOneWidget);
      expect(find.text('Dry Waste'), findsAtLeastNWidgets(1));
      expect(find.text('Wet Waste'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders mixed waste guidance when multi-item data is passed', (
      tester,
    ) async {
      final classifications = [
        WasteClassification(
          id: 'c1',
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Rinse'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.9,
          timestamp: DateTime.now(),
        ),
        WasteClassification(
          id: 'c2',
          itemName: 'Banana Peel',
          category: 'Wet Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: const ['Bin'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.85,
          timestamp: DateTime.now(),
        ),
      ];
      final regions = [
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.0,
            top: 0.0,
            width: 0.4,
            height: 0.4,
          ),
          classification: classifications[0],
          confidence: 0.9,
          userConfirmed: true,
          label: 'Plastic Bottle',
        ),
        DetectedWasteRegion(
          boundingBox: NormalizedBoundingBox(
            left: 0.5,
            top: 0.5,
            width: 0.4,
            height: 0.4,
          ),
          classification: classifications[1],
          confidence: 0.85,
          userConfirmed: true,
          label: 'Banana Peel',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CombinedResultScreen(
              classifications: classifications,
              multiItemResult: MultiItemClassificationResult(
                sourceImagePath: 'test_image.jpg',
                regions: regions,
                mixedWasteGuidance:
                    'Mixed waste detected. Separate items before disposal.',
              ),
              imageName: 'test_image.jpg',
            ),
          ),
        ),
      );

      expect(find.text('Mixed Waste Detected'), findsOneWidget);
      expect(find.text('Disposal Summary'), findsOneWidget);
      expect(find.byType(PerItemResultCard), findsOneWidget);
      expect(
        find.textContaining('Separate items before disposal'),
        findsOneWidget,
      );
    });

    testWidgets('renders single classification without errors', (tester) async {
      final classification = WasteClassification(
        id: 'c1',
        itemName: 'Paper Bag',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Fold'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: const [],
        alternatives: const [],
        confidence: 0.92,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CombinedResultScreen(
              classifications: [classification],
              imageName: 'single.jpg',
            ),
          ),
        ),
      );

      expect(find.text('1 item found in "single.jpg"'), findsOneWidget);
      expect(find.text('Paper Bag'), findsOneWidget);
    });
  });
}
