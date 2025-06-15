import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/history_screen.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import '../mocks/mock_services.dart';

void main() {
  group('HistoryScreen Memory Leak Tests', () {
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();
    });

    testWidgets('should not call setState after dispose during async operations', (WidgetTester tester) async {
      // Create a test classification
      final testClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test-1',
        itemName: 'Test Item',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        confidence: 0.95,
        explanation: 'Test explanation',
        disposalInstructions: 'Test disposal',
        imageUrl: 'test/path',
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
        timestamp: DateTime.now(),
        userId: 'test-user',
      );

      // Setup mock to return classifications with delay
      mockStorageService.setupGetAllClassifications([testClassification]);
      mockStorageService.setupGetSettings({'isGoogleSyncEnabled': false});
      mockCloudStorageService.setupGetAllClassificationsWithCloudSync([testClassification]);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<StorageService>.value(value: mockStorageService),
              ChangeNotifierProvider<CloudStorageService>.value(value: mockCloudStorageService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate away immediately to dispose the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Other Screen')),
            body: const Center(child: Text('Different screen')),
          ),
        ),
      );

      // Wait for any pending async operations to complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // If we get here without errors, the mounted checks are working
      expect(find.text('Other Screen'), findsOneWidget);
    });

    testWidgets('should handle rapid navigation without memory leaks', (WidgetTester tester) async {
      final testClassifications = List.generate(50, (index) => 
        WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test-$index',
          itemName: 'Test Item $index',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          confidence: 0.95,
          explanation: 'Test explanation $index',
          disposalInstructions: 'Test disposal $index',
          imageUrl: 'test/path$index',
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now().subtract(Duration(days: index)),
          userId: 'test-user',
        ),
      );

      mockStorageService.setupGetAllClassifications(testClassifications);
      mockStorageService.setupGetSettings({'isGoogleSyncEnabled': false});
      mockStorageService.setupGetClassificationsWithPagination(testClassifications.take(20).toList());

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<StorageService>.value(value: mockStorageService),
              ChangeNotifierProvider<CloudStorageService>.value(value: mockCloudStorageService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Rapidly navigate back and forth
      for (int i = 0; i < 5; i++) {
        // Navigate away
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: Text('Screen $i')),
              body: Center(child: Text('Screen $i')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Navigate back to history
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<StorageService>.value(value: mockStorageService),
                ChangeNotifierProvider<CloudStorageService>.value(value: mockCloudStorageService),
              ],
              child: const HistoryScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Final navigation away
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Final Screen')),
            body: const Center(child: Text('Final screen')),
          ),
        ),
      );

      // Wait for all async operations to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Final Screen'), findsOneWidget);
    });

    testWidgets('should handle export operation cancellation gracefully', (WidgetTester tester) async {
      final testClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test-1',
        itemName: 'Test Item',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        confidence: 0.95,
        explanation: 'Test explanation',
        disposalInstructions: 'Test disposal',
        imageUrl: 'test/path',
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
        timestamp: DateTime.now(),
        userId: 'test-user',
      );

      mockStorageService.setupGetAllClassifications([testClassification]);
      mockStorageService.setupGetSettings({'isGoogleSyncEnabled': false});
      mockStorageService.setupExportClassificationsToCSV('test,csv,content');

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<StorageService>.value(value: mockStorageService),
              ChangeNotifierProvider<CloudStorageService>.value(value: mockCloudStorageService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the export button
      final exportButton = find.byIcon(Icons.share);
      expect(exportButton, findsOneWidget);
      
      await tester.tap(exportButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Immediately navigate away while export is in progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Export Test Screen')),
            body: const Center(child: Text('Export test screen')),
          ),
        ),
      );

      // Wait for export operation to complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Export Test Screen'), findsOneWidget);
    });

    testWidgets('should handle filter operations during disposal', (WidgetTester tester) async {
      final testClassifications = List.generate(10, (index) => 
        WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test-$index',
          itemName: 'Test Item $index',
          category: index % 2 == 0 ? 'Dry Waste' : 'Wet Waste',
          subcategory: 'Test Subcategory',
          confidence: 0.95,
          explanation: 'Test explanation $index',
          disposalInstructions: 'Test disposal $index',
          imageUrl: 'test/path$index',
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now().subtract(Duration(days: index)),
          userId: 'test-user',
        ),
      );

      mockStorageService.setupGetAllClassifications(testClassifications);
      mockStorageService.setupGetSettings({'isGoogleSyncEnabled': false});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<StorageService>.value(value: mockStorageService),
              ChangeNotifierProvider<CloudStorageService>.value(value: mockCloudStorageService),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open filter dialog
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pump();

      // Immediately navigate away while dialog is open
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Filter Test Screen')),
            body: const Center(child: Text('Filter test screen')),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Filter Test Screen'), findsOneWidget);
    });
  });
} 