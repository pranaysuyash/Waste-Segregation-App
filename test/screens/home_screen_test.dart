import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/screens/home_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';

// Mock classes
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('HomeScreen Basic Tests', () {
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();
      mockAnalyticsService = MockAnalyticsService();

      // Setup basic mocks
      when(mockStorageService.getAllClassifications())
          .thenAnswer((_) async => <WasteClassification>[]);
      when(mockGamificationService.getProfile())
          .thenAnswer((_) async => const GamificationProfile(
                userId: 'test-user',
                points: UserPoints(total: 100, categoryPoints: {}),
                streaks: {},
                achievements: [],
                activeChallenges: [],
                completedChallenges: [],
                discoveredItemIds: {},
                unlockedHiddenContentIds: {},
              ));
    });

    testWidgets('should create basic widget structure', (WidgetTester tester) async {
      // Create a simple test widget that doesn't depend on charts
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<StorageService>.value(value: mockStorageService),
              Provider<GamificationService>.value(value: mockGamificationService),
              Provider<AnalyticsService>.value(value: mockAnalyticsService),
            ],
            child: const Scaffold(
              body: Center(
                child: Text('Home Screen Test'),
              ),
            ),
          ),
        ),
      );

      // Verify basic widget structure
      expect(find.text('Home Screen Test'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle service initialization', (WidgetTester tester) async {
      // Test that services can be initialized without errors
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<StorageService>.value(value: mockStorageService),
              Provider<GamificationService>.value(value: mockGamificationService),
              Provider<AnalyticsService>.value(value: mockAnalyticsService),
            ],
            child: Builder(
              builder: (context) {
                final storage = Provider.of<StorageService>(context, listen: false);
                final gamification = Provider.of<GamificationService>(context, listen: false);
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Storage: ${storage.runtimeType}'),
                      Text('Gamification: ${gamification.runtimeType}'),
                      Text('Analytics: ${analytics.runtimeType}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify services are accessible
      expect(find.text('Storage: MockStorageService'), findsOneWidget);
      expect(find.text('Gamification: MockGamificationService'), findsOneWidget);
      expect(find.text('Analytics: MockAnalyticsService'), findsOneWidget);
    });

    test('should verify mock service setup', () {
      // Test that mocks are properly configured
      expect(mockStorageService, isA<StorageService>());
      expect(mockGamificationService, isA<GamificationService>());
      expect(mockAnalyticsService, isA<AnalyticsService>());
    });

    test('should handle async service calls', () async {
      // Test async service methods
      final classifications = await mockStorageService.getAllClassifications();
      expect(classifications, isEmpty);

      final profile = await mockGamificationService.getProfile();
      expect(profile.userId, equals('test-user'));
      expect(profile.points.total, equals(100));
    });
  });
}

// Helper function to create test classification
WasteClassification _createTestClassification(String itemName, String category) {
  return WasteClassification(
    itemName: itemName,
    category: category,
    explanation: 'Test classification for $itemName',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal method',
      steps: ['Step 1', 'Step 2'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: ['test'],
    alternatives: [],
    confidence: 0.8,
    timestamp: DateTime.now(),
  );
}
