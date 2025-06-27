import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../test_config/test_app_wrapper.dart';
import '../mocks/mock_services.dart';
import '../../lib/screens/new_modern_home_screen.dart';
import '../../lib/screens/instant_analysis_screen.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import '../../lib/screens/result_screen.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../../lib/models/recycling_code.dart';

void main() {
  group('Navigation Tests - Double Navigation Prevention', () {
    late MockAiService mockAiService;
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late WasteClassification mockClassification;

    setUp(() {
      mockAiService = MockAiService();
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();

      mockClassification = WasteClassification(
        id: 'test-id',
        itemName: 'Test Item',
        category: 'plastic',
        explanation: 'Test explanation',
        region: 'Test Region',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: const ['Test step'],
          hasUrgentTimeframe: false,
        ),
        confidence: 0.95,
        timestamp: DateTime.now(),
        imageRelativePath: 'images/test_image.jpg',
        userId: 'test-user',
      );

      // Setup default mocks
      when(mockAiService.analyzeImage(
        File('test.jpg'),
        retryCount: 0,
        maxRetries: 3,
        region: 'US',
        instructionsLang: 'en',
        classificationId: null,
      )).thenAnswer((_) async => mockClassification);

      when(mockStorageService.saveClassification(mockClassification, force: false)).thenAnswer((_) async {});

      when(mockGamificationService.getProfile(forceRefresh: false)).thenAnswer((_) async => GamificationProfile(
            userId: 'test-user',
            points: const UserPoints(total: 100),
            streaks: const {},
            achievements: const [],
            activeChallenges: const [],
          ));

      when(mockGamificationService.processClassification(mockClassification)).thenAnswer((_) async => []);
    });

    testWidgets('Analysis button should push only one route to Navigator stack', (WidgetTester tester) async {
      // Build the app with mocked services
      await tester.pumpWidget(
        TestAppWrapper(
          mockAiService: mockAiService,
          mockStorageService: mockStorageService,
          mockGamificationService: mockGamificationService,
          child: const NewModernHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial Navigator state
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      final initialRouteCount = navigator.widget.pages?.length ?? 1;

      // Find and tap the instant analysis button
      final instantAnalysisButton = find.byKey(const Key('instant_analysis_button'));
      if (instantAnalysisButton.evaluate().isNotEmpty) {
        await tester.tap(instantAnalysisButton);
        await tester.pump(); // Trigger the navigation

        // Verify only one additional route was pushed
        final newRouteCount = navigator.widget.pages?.length ?? 1;
        expect(newRouteCount, equals(initialRouteCount + 1), reason: 'Should push exactly one route, not multiple');
      }
    });

    testWidgets('InstantAnalysisScreen should not cause double navigation', (WidgetTester tester) async {
      // Create a mock XFile for testing
      final mockXFile = XFile('/test/image.jpg');

      // Build InstantAnalysisScreen directly
      await tester.pumpWidget(
        TestAppWrapper(
          mockAiService: mockAiService,
          mockStorageService: mockStorageService,
          mockGamificationService: mockGamificationService,
          child: InstantAnalysisScreen(image: mockXFile),
        ),
      );

      // Let the analysis complete
      await tester.pumpAndSettle();

      // Verify we're on ResultScreen (not multiple instances)
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(InstantAnalysisScreen), findsNothing);

      // Verify Navigator stack depth
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      final routeCount = navigator.widget.pages?.length ?? 1;
      expect(routeCount, equals(1), reason: 'Should have exactly one route after navigation completes');
    });

    testWidgets('Multiple rapid taps should not cause multiple navigations', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          mockAiService: mockAiService,
          mockStorageService: mockStorageService,
          mockGamificationService: mockGamificationService,
          child: const NewModernHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the instant analysis button
      final instantAnalysisButton = find.byKey(const Key('instant_analysis_button'));
      if (instantAnalysisButton.evaluate().isNotEmpty) {
        // Tap multiple times rapidly
        await tester.tap(instantAnalysisButton);
        await tester.tap(instantAnalysisButton);
        await tester.tap(instantAnalysisButton);
        await tester.pump();

        // Verify only one navigation occurred
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        final routeCount = navigator.widget.pages?.length ?? 1;
        expect(routeCount, lessThanOrEqualTo(2), reason: 'Multiple rapid taps should not create multiple routes');
      }
    });

    testWidgets('Navigation guard should prevent concurrent navigation calls', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          mockAiService: mockAiService,
          mockStorageService: mockStorageService,
          mockGamificationService: mockGamificationService,
          child: const NewModernHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate concurrent navigation attempts
      final takePhotoButton = find.byKey(const Key('take_photo_button'));
      final pickImageButton = find.byKey(const Key('pick_image_button'));

      if (takePhotoButton.evaluate().isNotEmpty && pickImageButton.evaluate().isNotEmpty) {
        // Try to trigger both navigation paths simultaneously
        await tester.tap(takePhotoButton);
        await tester.tap(pickImageButton);
        await tester.pump();

        // Verify navigation guard prevented double navigation
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        final routeCount = navigator.widget.pages?.length ?? 1;
        expect(routeCount, lessThanOrEqualTo(2), reason: 'Navigation guard should prevent concurrent navigation');
      }
    });
  });

  group('Navigation Observer Tests', () {
    testWidgets('DebugNavigatorObserver should log navigation events', (WidgetTester tester) async {
      final logs = <String>[];

      // Override debugPrint to capture logs
      void Function(String?, {int? wrapWidth}) originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && message.contains('🧭 NAVIGATION')) {
          logs.add(message);
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };

      try {
        await tester.pumpWidget(
          TestAppWrapper(
            child: const NewModernHomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger navigation
        final button = find.byType(ElevatedButton).first;
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pump();
        }

        // Verify navigation events were logged
        expect(logs.any((log) => log.contains('NAVIGATION PUSH')), isTrue, reason: 'Should log navigation push events');
      } finally {
        // Restore original debugPrint
        debugPrint = originalDebugPrint;
      }
    });
  });
}
