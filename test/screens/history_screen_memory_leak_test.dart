import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/history_screen.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

import 'history_screen_memory_leak_test.mocks.dart';

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

WasteClassification _classification({
  required String id,
  required DateTime timestamp,
}) {
  return WasteClassification(
    id: id,
    itemName: 'Test Item',
    category: 'Dry Waste',
    subcategory: 'Plastic',
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test method',
      steps: const ['Test step'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['test feature'],
    alternatives: const [],
    confidence: 0.95,
    timestamp: timestamp,
    userId: 'test-user',
    imageRelativePath: 'images/test.jpg',
  );
}

@GenerateMocks([StorageService, CloudStorageService])
void main() {
  group('HistoryScreen Memory Leak Tests', () {
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();
      mockAnalyticsService = MockAnalyticsService();

      when(mockAnalyticsService.trackScreenView('HistoryScreen',
              parameters: anyNamed('parameters')))
          .thenAnswer((_) async {});

      when(mockStorageService.getSettings()).thenAnswer((_) async => {
            'isGoogleSyncEnabled': false,
            'allowHistoryFeedback': true,
            'feedbackTimeframeDays': 7,
          });

      when(mockStorageService.applyFiltersToClassifications(any, any))
          .thenAnswer((invocation) => invocation.positionalArguments.first
              as List<WasteClassification>);

      when(mockStorageService.getClassificationsWithPagination(
        filterOptions: anyNamed('filterOptions'),
        pageSize: anyNamed('pageSize'),
        page: anyNamed('page'),
      )).thenAnswer((_) async => <WasteClassification>[]);

      when(mockCloudStorageService.getAllClassificationsWithCloudSync(any))
          .thenAnswer((_) async => <WasteClassification>[]);
    });

    testWidgets('does not call setState after dispose',
        (WidgetTester tester) async {
      final testClassification = _classification(
        id: 'test-1',
        timestamp: DateTime.now(),
      );

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => [testClassification]);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<StorageService>.value(value: mockStorageService),
              Provider<CloudStorageService>.value(
                  value: mockCloudStorageService),
              ChangeNotifierProvider<AnalyticsService>.value(
                  value: mockAnalyticsService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      await tester.pump(); // initial frame
      await tester.pump(const Duration(milliseconds: 200)); // allow async load

      // Navigate away immediately to dispose HistoryScreen.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Other Screen')),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Other Screen'), findsOneWidget);
    });

    testWidgets('handles rapid navigation without throwing',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final testClassifications = List.generate(
        50,
        (index) => _classification(
          id: 'test-$index',
          timestamp: now.subtract(Duration(days: index)),
        ),
      );

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => testClassifications);

      when(mockStorageService.getClassificationsWithPagination(
        filterOptions: anyNamed('filterOptions'),
        pageSize: anyNamed('pageSize'),
        page: anyNamed('page'),
      )).thenAnswer((invocation) async {
        final pageSize = invocation.namedArguments[#pageSize] as int;
        final page = invocation.namedArguments[#page] as int;
        final start = page * pageSize;
        if (start >= testClassifications.length) return <WasteClassification>[];
        final end = (start + pageSize).clamp(0, testClassifications.length);
        return testClassifications.sublist(start, end);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<StorageService>.value(value: mockStorageService),
              Provider<CloudStorageService>.value(
                  value: mockCloudStorageService),
              ChangeNotifierProvider<AnalyticsService>.value(
                  value: mockAnalyticsService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Rapidly replace the widget tree a few times.
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: Text('Other $i'))),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      expect(find.text('Other 2'), findsOneWidget);
    });
  });
}
