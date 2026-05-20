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

import 'history_screen_test.mocks.dart';

/// Disposes animated widgets by replacing the tree with an empty box.
/// Call this in tests that render [EmptyStateWidget] or any widget with
/// repeating [AnimationController]s to avoid pending-timer failures.
Future<void> _disposeAnimatedWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> trackScreenView(String screenName,
          {Map<String, dynamic>? parameters}) =>
      super.noSuchMethod(
        Invocation.method(#trackScreenView, [screenName], {#parameters: parameters}),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> trackUserAction(String actionName,
          {Map<String, dynamic>? parameters}) =>
      super.noSuchMethod(
        Invocation.method(#trackUserAction, [actionName], {#parameters: parameters}),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;
}

WasteClassification _classification({
  required String id,
  required String itemName,
  required String category,
  String? subcategory,
  String? materialType,
  double? confidence,
  bool? clarificationNeeded,
  bool? isSaved,
  bool? userConfirmed,
  String? userCorrection,
  DateTime? timestamp,
}) {
  return WasteClassification(
    id: id,
    itemName: itemName,
    category: category,
    subcategory: subcategory,
    materialType: materialType,
    explanation: 'Test explanation',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test method',
      steps: const ['Test step'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['test feature'],
    alternatives: const [],
    confidence: confidence,
    clarificationNeeded: clarificationNeeded,
    isSaved: isSaved,
    userConfirmed: userConfirmed,
    userCorrection: userCorrection,
    timestamp: timestamp ?? DateTime.now(),
    userId: 'test-user',
    imageRelativePath: 'images/test.jpg',
  );
}

@GenerateMocks([StorageService, CloudStorageService])
void main() {
  late MockStorageService mockStorageService;
  late MockCloudStorageService mockCloudStorageService;
  late MockAnalyticsService mockAnalyticsService;

  Widget buildApp({Widget? child}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<StorageService>.value(value: mockStorageService),
          Provider<CloudStorageService>.value(value: mockCloudStorageService),
          ChangeNotifierProvider<AnalyticsService>.value(
              value: mockAnalyticsService),
        ],
        child: child ?? const HistoryScreen(),
      ),
    );
  }

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
        .thenAnswer((invocation) =>
            invocation.positionalArguments.first as List<WasteClassification>);

    when(mockStorageService.getClassificationsWithPagination(
      filterOptions: anyNamed('filterOptions'),
      pageSize: anyNamed('pageSize'),
      page: anyNamed('page'),
    )).thenAnswer((_) async => <WasteClassification>[]);

    when(mockCloudStorageService.getAllClassificationsWithCloudSync(any))
        .thenAnswer((_) async => <WasteClassification>[]);
  });

  group('HistoryScreen - Empty State', () {
    testWidgets('shows empty state with scan CTA when no classifications',
        (WidgetTester tester) async {
      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => <WasteClassification>[]);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No classifications yet'), findsOneWidget);
      expect(find.text('Scan your first item'), findsOneWidget);

      await _disposeAnimatedWidget(tester);
    });

    testWidgets('empty state scan CTA is tappable', (
      WidgetTester tester,
    ) async {
      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => <WasteClassification>[]);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Scan your first item'));
      await tester.pump();

      expect(find.text('No classifications yet'), findsOneWidget);

      await _disposeAnimatedWidget(tester);
    });
  });

  group('HistoryScreen - Filter and Search', () {
    setUp(() {
      final now = DateTime.now();
      final classifications = [
        _classification(
          id: 'c1',
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          materialType: 'Plastic',
          confidence: 0.95,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        _classification(
          id: 'c2',
          itemName: 'Banana Peel',
          category: 'Wet Waste',
          subcategory: 'Food Waste',
          materialType: 'Organic',
          confidence: 0.88,
          timestamp: now.subtract(const Duration(days: 2)),
        ),
        _classification(
          id: 'c3',
          itemName: 'Battery',
          category: 'Hazardous Waste',
          subcategory: 'Batteries',
          materialType: 'Metal',
          confidence: 0.72,
          timestamp: now.subtract(const Duration(days: 3)),
        ),
        _classification(
          id: 'c4',
          itemName: 'Unknown Item',
          category: 'Requires Manual Review',
          clarificationNeeded: true,
          confidence: 0.0,
          timestamp: now.subtract(const Duration(days: 4)),
        ),
      ];

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((invocation) async {
        final filterOptions =
            invocation.namedArguments[#filterOptions] as FilterOptions?;
        var result = List<WasteClassification>.from(classifications);

        if (filterOptions?.categories != null &&
            filterOptions!.categories!.isNotEmpty) {
          result = result
              .where((c) => filterOptions.categories!
                  .any((cat) => c.category.toLowerCase() == cat.toLowerCase()))
              .toList();
        }

        if (filterOptions?.searchText != null &&
            filterOptions!.searchText!.isNotEmpty) {
          final query = filterOptions.searchText!.toLowerCase();
          result = result
              .where((c) =>
                  c.itemName.toLowerCase().contains(query) ||
                  (c.subcategory?.toLowerCase().contains(query) ?? false) ||
                  (c.materialType?.toLowerCase().contains(query) ?? false) ||
                  c.category.toLowerCase().contains(query))
              .toList();
        }

        return result;
      });
    });

    testWidgets('shows filter chips row', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Wet Waste'), findsWidgets);
      expect(find.text('Dry Waste'), findsWidgets);
      expect(find.text('Hazardous'), findsOneWidget);
      expect(find.text('Manual Review'), findsOneWidget);
    });

    testWidgets('filter chips narrow list by category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wet Waste').first);
      await tester.pumpAndSettle();

      expect(find.text('Banana Peel'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsNothing);
    });

    testWidgets('search filters by item name', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bottle');
      await tester.pumpAndSettle();

      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Banana Peel'), findsNothing);
    });

    testWidgets('search filters by category name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Wet');
      await tester.pumpAndSettle();

      expect(find.text('Banana Peel'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsNothing);
    });

    testWidgets('no-results state when filters produce no matches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hazardous').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      await _disposeAnimatedWidget(tester);
    });

    testWidgets('clear filters button restores full list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wet Waste').first);
      await tester.pumpAndSettle();
      expect(find.text('Banana Peel'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Banana Peel'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsOneWidget);
    });
  });

  group('HistoryScreen - Card Tapping', () {
    testWidgets('tapping a classification card navigates to details', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final classifications = [
        _classification(
          id: 'c1',
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          confidence: 0.95,
          timestamp: now,
        ),
      ];

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => classifications);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Dry Waste'), findsWidgets);
    });
  });

  group('HistoryScreen - Fallback Classification Display', () {
    testWidgets('fallback classifications show Needs review indicator', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final classifications = [
        _classification(
          id: 'c4',
          itemName: 'Unknown Item',
          category: 'Requires Manual Review',
          clarificationNeeded: true,
          confidence: 0.0,
          timestamp: now.subtract(const Duration(days: 4)),
        ),
      ];

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => classifications);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Needs review'), findsOneWidget);
      expect(find.text('Unknown Item'), findsOneWidget);
    });

    testWidgets('corrected classifications show Corrected badge', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final classifications = [
        _classification(
          id: 'c5',
          itemName: 'Glass Bottle',
          category: 'Dry Waste',
          confidence: 0.65,
          userCorrection: 'user corrected this',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => classifications);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Corrected'), findsOneWidget);
      expect(find.text('Glass Bottle'), findsOneWidget);
    });

    testWidgets('confirmed classifications show Confirmed badge', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final classifications = [
        _classification(
          id: 'c6',
          itemName: 'Paper Bag',
          category: 'Dry Waste',
          confidence: 0.98,
          userConfirmed: true,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      when(mockStorageService.getAllClassifications(
        filterOptions: anyNamed('filterOptions'),
      )).thenAnswer((_) async => classifications);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Paper Bag'), findsOneWidget);
    });
  });
}
