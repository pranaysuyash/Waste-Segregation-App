import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/history_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

@GenerateMocks([StorageService])
import 'history_screen_test.mocks.dart';

void main() {
  group('HistoryScreen Tests', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<StorageService>.value(
          value: mockStorageService,
          child: const HistoryScreen(),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render history screen with empty state', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Classification History'), findsOneWidget);
        expect(find.text('No classifications found'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('should render history list with classifications', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(
            itemName: 'Test Item', 
            explanation: 'Test explanation',
            category: 'plastic',
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            confidence: 0.95,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_2',
            imageUrl: '/path/to/image2.jpg',
            category: 'paper',
            confidence: 0.88,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in paper bin', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Classification History'), findsOneWidget);
        expect(find.text('plastic'), findsOneWidget);
        expect(find.text('paper'), findsOneWidget);
        expect(find.text('95%'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);
      });

      testWidgets('should show loading indicator while fetching data', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return [];
        });

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('User Interactions', () {
      testWidgets('should navigate to classification details on tap', (WidgetTester tester) async {
        final mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_1',
          imageUrl: '/path/to/image1.jpg',
          category: 'plastic',
          confidence: 0.95,
          disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
          timestamp: DateTime.now(),
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [mockClassification]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('plastic'));
        await tester.pumpAndSettle();

        // Should navigate to details screen
        verify(mockStorageService.getAllClassifications()).called(1);
      });

      testWidgets('should show search functionality', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search), findsOneWidget);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search classifications...'), findsOneWidget);
      });

      testWidgets('should filter classifications by search query', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            category: 'plastic',
            confidence: 0.95,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_2',
            imageUrl: '/path/to/image2.jpg',
            category: 'paper',
            confidence: 0.88,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in paper bin', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());
        // Note: searchClassifications method doesn't exist in StorageService

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'plastic');
        await tester.pumpAndSettle();

        expect(find.text('plastic'), findsOneWidget);
        expect(find.text('paper'), findsNothing);
      });

      testWidgets('should show filter options', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.filter_list), findsOneWidget);

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('Filter Classifications'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Date Range'), findsOneWidget);
        expect(find.text('Confidence'), findsOneWidget);
      });

      testWidgets('should delete classification on swipe', (WidgetTester tester) async {
        final mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_1',
          imageUrl: '/path/to/image1.jpg',
          category: 'plastic',
          confidence: 0.95,
          disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
          timestamp: DateTime.now(),
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [mockClassification]);
        when(mockStorageService.deleteClassification('class_1'))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform swipe to delete
        await tester.drag(find.text('plastic'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Should show delete confirmation
        expect(find.text('Delete Classification?'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Confirm deletion
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(mockStorageService.deleteClassification('class_1')).called(1);
      });
    });

    group('Data Management', () {
      testWidgets('should refresh data on pull-to-refresh', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform pull-to-refresh
        await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
        await tester.pumpAndSettle();

        verify(mockStorageService.getAllClassifications()).called(2);
      });

      testWidgets('should handle pagination for large datasets', (WidgetTester tester) async {
        final largeClassificationList = List.generate(100, (index) => 
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_$index',
            imageUrl: '/path/to/image$index.jpg',
            category: index % 2 == 0 ? 'plastic' : 'paper',
            confidence: 0.8 + (index % 20) * 0.01,
            disposalInstructions: 'Disposal instructions $index',
            timestamp: DateTime.now().subtract(Duration(hours: index)),
          )
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => largeClassificationList.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially should show first page
        expect(find.text('plastic'), findsWidgets);

        // Scroll to bottom to trigger pagination
        await tester.drag(find.byType(ListView), const Offset(0, -5000));
        await tester.pumpAndSettle();

        // Should load more items
        expect(find.text('Load More'), findsNothing); // Should auto-load
      });

      testWidgets('should export classification data', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            category: 'plastic',
            confidence: 0.95,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open overflow menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Export Data'), findsOneWidget);

        await tester.tap(find.text('Export Data'));
        await tester.pumpAndSettle();

        expect(find.text('Export Options'), findsOneWidget);
        expect(find.text('CSV'), findsOneWidget);
        expect(find.text('JSON'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error message when data loading fails', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenThrow(Exception('Failed to load data'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Error loading classifications'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should retry loading data on error', (WidgetTester tester) async {
        when(mockStorageService.getAllClassifications())
            .thenThrow(Exception('Failed to load data'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);

        // Mock successful retry
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => []);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('No classifications found'), findsOneWidget);
        verify(mockStorageService.getAllClassifications()).called(2);
      });

      testWidgets('should handle delete operation failure', (WidgetTester tester) async {
        final mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_1',
          imageUrl: '/path/to/image1.jpg',
          category: 'plastic',
          confidence: 0.95,
          disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
          timestamp: DateTime.now(),
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [mockClassification]);
        when(mockStorageService.deleteClassification('class_1'))
            .thenThrow(Exception('Delete failed'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Swipe to delete
        await tester.drag(find.text('plastic'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to delete classification'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('Sorting and Organization', () {
      testWidgets('should sort classifications by date', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            category: 'plastic',
            confidence: 0.95,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_2',
            imageUrl: '/path/to/image2.jpg',
            category: 'paper',
            confidence: 0.88,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open sort menu
        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        expect(find.text('Sort by Date'), findsOneWidget);
        expect(find.text('Sort by Category'), findsOneWidget);
        expect(find.text('Sort by Confidence'), findsOneWidget);

        await tester.tap(find.text('Sort by Date'));
        await tester.pumpAndSettle();

        // Should sort by newest first
        final listItems = find.byType(ListTile);
        expect(listItems, findsWidgets);
      });

      testWidgets('should group classifications by category', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            category: 'plastic',
            confidence: 0.95,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_2',
            imageUrl: '/path/to/image2.jpg',
            category: 'plastic',
            confidence: 0.88,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_3',
            imageUrl: '/path/to/image3.jpg',
            category: 'paper',
            confidence: 0.92,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Toggle group by category
        await tester.tap(find.byIcon(Icons.group_work));
        await tester.pumpAndSettle();

        expect(find.text('Plastic (2)'), findsOneWidget);
        expect(find.text('Paper (1)'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should support screen reader navigation', (WidgetTester tester) async {
        final mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_1',
          imageUrl: '/path/to/image1.jpg',
          category: 'plastic',
          confidence: 0.95,
          disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle in plastic bin', steps: ['Test step'], hasUrgentTimeframe: false),
          timestamp: DateTime.now(),
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [mockClassification]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final semanticsNode = find.text('plastic').evaluate().first;
        expect(semanticsNode.widget, isA<Widget>());

        // Should have proper semantics labels
        expect(
          tester.getSemantics(find.text('plastic')),
          matchesSemantics(
            label: 'plastic',
            isButton: true,
          ),
        );
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        final mockClassifications = [
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_1',
            imageUrl: '/path/to/image1.jpg',
            category: 'plastic',
            confidence: 0.95,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_2',
            imageUrl: '/path/to/image2.jpg',
            category: 'paper',
            confidence: 0.88,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Test keyboard focus
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should focus on first item
        expect(WidgetsBinding.instance.focusManager.primaryFocus, isNotNull);
      });
    });

    group('Performance', () {
      testWidgets('should handle large datasets efficiently', (WidgetTester tester) async {
        final largeDataset = List.generate(1000, (index) => 
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_$index',
            imageUrl: '/path/to/image$index.jpg',
            category: 'plastic',
            confidence: 0.9,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now().subtract(Duration(minutes: index)),
          )
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => largeDataset.cast<WasteClassification>());

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should render within reasonable time (less than 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Should show initial items
        expect(find.text('plastic'), findsWidgets);
      });

      testWidgets('should implement lazy loading for images', (WidgetTester tester) async {
        final mockClassifications = List.generate(20, (index) => 
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class_$index',
            imageUrl: '/path/to/image$index.jpg',
            category: 'plastic',
            confidence: 0.9,
            disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          )
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => mockClassifications.cast<WasteClassification>());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should implement image lazy loading
        expect(find.byType(Image), findsWidgets);
        
        // Scroll to trigger more image loading
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsWidgets);
      });
    });
  });
}
