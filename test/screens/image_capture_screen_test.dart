import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/combined_result_screen.dart';
import 'package:waste_segregation_app/screens/image_capture_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class MockAiService extends Mock implements AiService {}

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
}

class MockStorageService extends Mock implements StorageService {}

class MockResultPipeline extends Mock implements ResultPipeline {}

class FakePremiumService extends PremiumService {
  FakePremiumService() : super();
  @override
  bool hasActivePremiumPlan() => false;
}

void main() {
  group('ImageCaptureScreen', () {
    testWidgets('renders waiting state when no image is provided',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      expect(find.text('Waiting for camera...'), findsOneWidget);
    });

    testWidgets(
        'tapping "Select multiple items" enters region selection mode',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
            analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
            storageServiceProvider.overrideWithValue(MockStorageService()),
            resultPipelineProvider.overrideWith((_) => MockResultPipeline()),
          ],
          child: MaterialApp(
            home: ImageCaptureScreen(
              webImage: Uint8List.fromList([0, 1, 2, 3]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select multiple items'), findsOneWidget);

      await tester.tap(find.text('Select multiple items'));
      await tester.pumpAndSettle();

      expect(find.text('Draw a rectangle around each item'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
    });

    testWidgets(
        'region selection mode disables analyze button when no regions selected',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
            analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
            storageServiceProvider.overrideWithValue(MockStorageService()),
            resultPipelineProvider.overrideWith((_) => MockResultPipeline()),
          ],
          child: MaterialApp(
            home: ImageCaptureScreen(
              webImage: Uint8List.fromList([0, 1, 2, 3]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select multiple items'));
      await tester.pumpAndSettle();

      // The analyze button text changes based on count; with 0 regions it should
      // still be present but disabled.
      final analyzeButton = find.widgetWithText(
        ElevatedButton,
        'Analyze 0 items',
      );
      expect(analyzeButton, findsOneWidget);

      final widget = tester.widget<ElevatedButton>(analyzeButton);
      expect(widget.onPressed, isNull);
    });
  });

  group('AuthException', () {
    test('stores and formats message correctly', () {
      final ex = AuthException('User not authenticated');
      expect(ex.message, 'User not authenticated');
      expect(ex.toString(), 'User not authenticated');
    });

    test('can be caught as Exception', () {
      void thrower() {
        throw AuthException('test');
      }
      expect(thrower, throwsA(isA<AuthException>()));
      expect(thrower, throwsA(isA<Exception>()));
    });
  });

  group('OfflineException', () {
    test('stores and formats message correctly', () {
      final ex = OfflineException('No network');
      expect(ex.message, 'No network');
      expect(ex.toString(), 'No network');
    });

    test('can be caught as Exception', () {
      void thrower() {
        throw OfflineException('test');
      }
      expect(thrower, throwsA(isA<OfflineException>()));
      expect(thrower, throwsA(isA<Exception>()));
    });
  });

  group('CombinedResultScreen', () {
    testWidgets('renders combined summary for multiple classifications',
        (tester) async {
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

      expect(find.text('Analysis Complete'), findsOneWidget);
      expect(find.text('2 items found in "test_image.jpg"'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Banana Peel'), findsOneWidget);
      expect(find.text('Dry Waste'), findsAtLeastNWidgets(1));
      expect(find.text('Wet Waste'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders single classification without errors',
        (tester) async {
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
