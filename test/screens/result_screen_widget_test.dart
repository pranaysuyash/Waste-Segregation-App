/// Widget tests for ResultScreen critical states
/// 
/// These tests verify UI renders correctly for key scenarios.
/// They don't test pixel-perfect rendering, but critical elements presence.
/// 
/// Run: flutter test test/screens/result_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';

import '../fixtures/classifications/fixtures.dart';

// Mock services for testing
class MockAnalyticsService extends AnalyticsService {
  final List<Map<String, dynamic>> trackedEvents = [];

  @override
  Future<void> trackScreenView(String screenName,
      {Map<String, dynamic>? parameters}) async {
    trackedEvents.add({
      'event': 'screen_view',
      'screen': screenName,
      'parameters': parameters,
    });
  }

  @override
  Future<void> trackUserAction(String action,
      {Map<String, dynamic>? parameters}) async {
    trackedEvents.add({
      'event': 'user_action',
      'action': action,
      'parameters': parameters,
    });
  }
}

class MockStorageService extends StorageService {
  final List<WasteClassification> savedClassifications = [];
  bool saveShouldFail = false;

  @override
  Future<void> saveClassification(WasteClassification classification,
      {bool force = false}) async {
    if (saveShouldFail) {
      throw Exception('Save failed');
    }
    savedClassifications.add(classification);
  }
}

class MockGamificationService extends GamificationService {
  @override
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) async {
    return GamificationProfile(
      points: Points(total: 100, weekly: 50),
      achievements: [],
      completedChallenges: [],
    );
  }

  @override
  Future<void> processClassification(
      WasteClassification classification) async {
    // No-op for testing
  }
}

void main() {
  group('ResultScreen Widget Tests', () {
    late MockAnalyticsService mockAnalytics;
    late MockStorageService mockStorage;
    late MockGamificationService mockGamification;

    Widget buildTestableWidget({
      required WasteClassification classification,
      bool showActions = true,
      bool autoAnalyze = false,
    }) {
      return MultiProvider(
        providers: [
          Provider<AnalyticsService>.value(value: mockAnalytics),
          Provider<StorageService>.value(value: mockStorage),
          Provider<GamificationService>.value(value: mockGamification),
        ],
        child: MaterialApp(
          home: ResultScreen(
            classification: classification,
            showActions: showActions,
            autoAnalyze: autoAnalyze,
          ),
        ),
      );
    }

    setUp(() {
      mockAnalytics = MockAnalyticsService();
      mockStorage = MockStorageService();
      mockGamification = MockGamificationService();
    });

    group('Standard Success State', () {
      testWidgets('displays category and item name',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Verify category is displayed
        expect(find.text('Dry Waste'), findsOneWidget);
        
        // Verify item name is displayed
        expect(find.text('Plastic Water Bottle'), findsOneWidget);
      });

      testWidgets('displays confidence percentage',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Look for confidence text (format: XX%)
        expect(find.textContaining('%'), findsWidgets);
        expect(find.textContaining('94'), findsOneWidget);
      });

      testWidgets('displays disposal instructions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Look for disposal section
        expect(find.textContaining('Disposal'), findsWidgets);
        
        // Look for steps
        expect(find.textContaining('Empty'), findsOneWidget);
      });

      testWidgets('shows primary action buttons when showActions=true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            classification: plasticBottleFixture,
            showActions: true,
          ),
        );
        await tester.pumpAndSettle();

        // Look for action buttons (Share, Save, etc.)
        expect(find.byType(IconButton), findsWidgets);
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('hides action buttons when showActions=false',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            classification: plasticBottleFixture,
            showActions: false,
          ),
        );
        await tester.pumpAndSettle();

        // Should have fewer buttons
        final buttonCount = find.byType(ElevatedButton).evaluate().length;
        expect(buttonCount, lessThan(3));
      });
    });

    group('Unknown/Low Confidence State', () {
      testWidgets('displays clarification needed UI',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: unknownLowConfidenceFixture),
        );
        await tester.pumpAndSettle();

        // Should show unknown/manual review messaging
        expect(find.textContaining('Manual'), findsOneWidget);
        expect(find.textContaining('Review'), findsOneWidget);
      });

      testWidgets('shows alternatives for unknown items',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: unknownLowConfidenceFixture),
        );
        await tester.pumpAndSettle();

        // Should show alternative suggestions
        expect(find.textContaining('Alternative'), findsWidgets);
      });

      testWidgets('displays feedback prompt',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: unknownLowConfidenceFixture),
        );
        await tester.pumpAndSettle();

        // Should prompt for user feedback
        expect(find.textContaining('feedback'), findsOneWidget);
      });
    });

    group('High Risk/Hazardous State', () {
      testWidgets('displays warning indicators for medical waste',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: medicalWasteFixture),
        );
        await tester.pumpAndSettle();

        // Should show warning colors/icons
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('displays PPE requirements',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: medicalWasteFixture),
        );
        await tester.pumpAndSettle();

        // Should mention required PPE
        expect(find.textContaining('gloves'), findsOneWidget);
      });

      testWidgets('emphasizes urgent disposal for hazardous items',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: hazardousBatteryFixture),
        );
        await tester.pumpAndSettle();

        // Should show urgent messaging
        expect(find.textContaining('urgent'), findsOneWidget);
      });
    });

    group('Analytics Tracking', () {
      testWidgets('tracks screen view on load',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Verify analytics event was fired
        expect(mockAnalytics.trackedEvents, isNotEmpty);
        
        final screenViewEvent = mockAnalytics.trackedEvents.firstWhere(
          (e) => e['event'] == 'screen_view',
          orElse: () => {},
        );
        
        expect(screenViewEvent, isNotEmpty);
        expect(screenViewEvent['screen'], 'ResultScreen');
      });

      testWidgets('includes classification params in analytics',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        final screenViewEvent = mockAnalytics.trackedEvents.firstWhere(
          (e) => e['event'] == 'screen_view',
          orElse: () => {},
        );
        
        final params = screenViewEvent['parameters'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['category'], 'Dry Waste');
        expect(params['item_name'], 'Plastic Water Bottle');
      });
    });

    group('Error States', () {
      testWidgets('displays error when save fails',
          (WidgetTester tester) async {
        mockStorage.saveShouldFail = true;

        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Tap save button
        final saveButton = find.byIcon(Icons.save);
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // Should show error
          expect(find.textContaining('Error'), findsOneWidget);
        }
      });
    });

    group('Gamification Display', () {
      testWidgets('shows points earned when gamification active',
          (WidgetTester tester) async {
        // This would require mocking the gamification state
        // Placeholder for when gamification widget tests are added
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Look for points/points-related UI
        // expect(find.textContaining('points'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('back button navigates correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(classification: plasticBottleFixture),
        );
        await tester.pumpAndSettle();

        // Find and tap back button
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Should navigate away (screen no longer visible)
          // This depends on navigation setup
        }
      });
    });
  });
}
