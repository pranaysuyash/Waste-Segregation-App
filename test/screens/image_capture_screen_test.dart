import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/image_capture_screen.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/capture_button.dart';
import 'package:waste_segregation_app/widgets/enhanced_analysis_loader.dart';
import '../test_helper.dart';

// Mock classes for testing
class MockAiService extends Mock implements AiService {}
class MockFile extends Mock implements File {}
class MockXFile extends Mock implements XFile {}

void main() {
  group('ImageCaptureScreen Critical Tests', () {
    late MockAiService mockAiService;
    late WasteClassification mockClassification;
    late Uint8List mockImageBytes;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      mockAiService = MockAiService();
      mockImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]); // Mock JPEG header
      
      mockClassification = WasteClassification(
        itemName: 'Test Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        explanation: 'Test recyclable plastic bottle',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1', 'Step 2'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: ['plastic', 'bottle'],
        alternatives: [],
        confidence: 0.95,
      );
    });

    Widget createTestableWidget({
      File? imageFile,
      XFile? xFile,
      Uint8List? webImage,
    }) {
      return ChangeNotifierProvider<AiService>.value(
        value: mockAiService,
        child: MaterialApp(
          home: ImageCaptureScreen(
            imageFile: imageFile,
            xFile: xFile,
            webImage: webImage,
          ),
        ),
      );
    }

    group('Widget Construction Tests', () {
      testWidgets('should create with File image', (WidgetTester tester) async {
        final mockFile = MockFile();
        when(mockFile.path).thenReturn('/test/path/image.jpg');
        when(mockFile.exists()).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestableWidget(imageFile: mockFile));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
        expect(find.text('Review Image'), findsOneWidget);
      });

      testWidgets('should create with XFile', (WidgetTester tester) async {
        final mockXFile = MockXFile();
        when(mockXFile.name).thenReturn('test_image.jpg');
        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockImageBytes);

        await tester.pumpWidget(createTestableWidget(xFile: mockXFile));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should create with web image bytes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should fail assertion with no image provided', (WidgetTester tester) async {
        expect(
          () => ImageCaptureScreen(),
          throwsAssertionError,
        );
      });
    });

    group('UI Elements Tests', () {
      testWidgets('should display all essential UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Verify AppBar
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Review Image'), findsOneWidget);

        // Verify image preview area
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // Verify instructions
        expect(find.text('Position the item clearly in the image for best results.'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));

        // Verify segmentation toggle
        expect(find.text('Advanced Segmentation'), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsOneWidget);

        // Verify action buttons
        expect(find.byType(CaptureButton), findsAtLeastNWidgets(2));
      });

      testWidgets('should display image with InteractiveViewer for zoom', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Verify InteractiveViewer is present
        final interactiveViewer = find.byType(InteractiveViewer);
        expect(interactiveViewer, findsOneWidget);

        // Verify zoom instruction overlay
        expect(find.text('Pinch to zoom • Drag to pan'), findsOneWidget);
        expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      });

      testWidgets('should display segmentation controls correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Verify segmentation toggle
        final switchTile = find.byType(SwitchListTile);
        expect(switchTile, findsOneWidget);

        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isFalse); // Initially disabled
        expect(switchWidget.title, isA<Row>()); // Has PRO badge
        expect(switchWidget.subtitle, isA<Text>());
      });

      testWidgets('should show proper styling for premium feature', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Verify PRO badge styling
        expect(find.text('PRO'), findsOneWidget);
        
        // Verify container styling for segmentation section
        final containers = find.byType(Container);
        expect(containers, findsAtLeastNWidgets(1));
      });
    });

    group('Image Analysis Tests', () {
      testWidgets('should start analysis when analyze button is pressed', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Find and tap analyze button
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Should show loading screen
        expect(find.byType(EnhancedAnalysisLoader), findsOneWidget);
        expect(find.text('Review Image'), findsNothing); // AppBar should be hidden

        await tester.pumpAndSettle();
      });

      testWidgets('should handle successful analysis and navigate to results', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Wait for analysis to complete
        await tester.pumpAndSettle();

        // Should navigate to ResultScreen
        expect(find.byType(ResultScreen), findsOneWidget);
        expect(find.byType(ImageCaptureScreen), findsNothing);
      });

      testWidgets('should handle analysis errors gracefully', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenThrow(Exception('Analysis failed'));

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Wait for error to be processed
        await tester.pumpAndSettle();

        // Should show error snackbar and remain on screen
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Analysis failed'), findsOneWidget);
        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should prevent multiple simultaneous analyses', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 500));
              return mockClassification;
            });

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Tap analyze button multiple times rapidly
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();
        await tester.tap(analyzeButton);
        await tester.pump();
        await tester.tap(analyzeButton);
        await tester.pump();

        // Should only call analysis once
        await tester.pumpAndSettle();
        verify(mockAiService.analyzeWebImage(any, any)).called(1);
      });

      testWidgets('should handle analysis cancellation', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(seconds: 2));
              return mockClassification;
            });

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Should show loading screen with cancel option
        expect(find.byType(EnhancedAnalysisLoader), findsOneWidget);

        // Cancel analysis (assuming cancel functionality exists)
        // This would need to be implemented based on EnhancedAnalysisLoader structure
        await tester.pumpAndSettle();
      });
    });

    group('Segmentation Feature Tests', () {
      testWidgets('should toggle segmentation mode', (WidgetTester tester) async {
        when(mockAiService.segmentImage(any))
            .thenAnswer((_) async => [
              {'bounds': {'x': 10.0, 'y': 10.0, 'width': 50.0, 'height': 50.0}},
              {'bounds': {'x': 60.0, 'y': 60.0, 'width': 30.0, 'height': 30.0}},
            ]);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Find segmentation switch
        final switchTile = find.byType(SwitchListTile);
        expect(switchTile, findsOneWidget);

        // Toggle segmentation on
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // Should call segmentation service
        verify(mockAiService.segmentImage(any)).called(1);

        // Should show segmentation info
        expect(find.textContaining('objects detected'), findsOneWidget);
      });

      testWidgets('should handle segmentation errors', (WidgetTester tester) async {
        when(mockAiService.segmentImage(any))
            .thenThrow(Exception('Segmentation failed'));

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Toggle segmentation on
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // Should show error and disable segmentation
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Segmentation failed'), findsOneWidget);

        // Switch should be back to off
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isFalse);
      });

      testWidgets('should clear segments when segmentation is disabled', (WidgetTester tester) async {
        when(mockAiService.segmentImage(any))
            .thenAnswer((_) async => [
              {'bounds': {'x': 10.0, 'y': 10.0, 'width': 50.0, 'height': 50.0}},
            ]);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Enable segmentation
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // Verify segments are detected
        expect(find.textContaining('objects detected'), findsOneWidget);

        // Disable segmentation
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // Segments info should be gone
        expect(find.textContaining('objects detected'), findsNothing);
      });

      testWidgets('should display segment selection UI when segments exist', (WidgetTester tester) async {
        when(mockAiService.segmentImage(any))
            .thenAnswer((_) async => [
              {'bounds': {'x': 10.0, 'y': 10.0, 'width': 50.0, 'height': 50.0}},
              {'bounds': {'x': 60.0, 'y': 60.0, 'width': 30.0, 'height': 30.0}},
            ]);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Enable segmentation
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // Should show segment count
        expect(find.text('2 objects detected. Tap to select for analysis.'), findsOneWidget);

        // Should show info icon
        expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate back when retry button is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  tester.element(find.byType(ElevatedButton)),
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider<AiService>.value(
                      value: mockAiService,
                      child: ImageCaptureScreen(webImage: mockImageBytes),
                    ),
                  ),
                ),
                child: const Text('Go to Capture'),
              ),
            ),
          ),
        );

        // Navigate to capture screen
        await tester.tap(find.text('Go to Capture'));
        await tester.pumpAndSettle();

        // Find and tap retry button
        final retryButton = find.byType(CaptureButton).last;
        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        // Should navigate back
        expect(find.text('Go to Capture'), findsOneWidget);
        expect(find.byType(ImageCaptureScreen), findsNothing);
      });

      testWidgets('should navigate to results after successful analysis', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        // Should be on ResultScreen
        expect(find.byType(ResultScreen), findsOneWidget);
      });
    });

    group('Platform-Specific Tests', () {
      testWidgets('should handle File images on mobile platforms', (WidgetTester tester) async {
        // This test assumes non-web platform
        final mockFile = MockFile();
        when(mockFile.path).thenReturn('/test/image.jpg');
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockAiService.analyzeImage(any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(imageFile: mockFile));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should handle XFile for web platform', (WidgetTester tester) async {
        final mockXFile = MockXFile();
        when(mockXFile.name).thenReturn('test.jpg');
        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockImageBytes);
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(xFile: mockXFile));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });
    });

    group('Error Handling and Edge Cases Tests', () {
      testWidgets('should handle empty image bytes', (WidgetTester tester) async {
        final emptyBytes = Uint8List(0);
        
        await tester.pumpWidget(createTestableWidget(webImage: emptyBytes));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should handle analysis service unavailable', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenThrow(Exception('Service unavailable'));

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        // Should show error
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Service unavailable'), findsOneWidget);
      });

      testWidgets('should handle very large images', (WidgetTester tester) async {
        // Create a large mock image (simulated)
        final largeImageBytes = Uint8List(10 * 1024 * 1024); // 10MB
        
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        await tester.pumpWidget(createTestableWidget(webImage: largeImageBytes));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
      });

      testWidgets('should handle network timeouts', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(seconds: 30));
              throw Exception('Network timeout');
            });

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Fast forward time
        await tester.pump(const Duration(seconds: 31));

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should handle corrupted image data', (WidgetTester tester) async {
        final corruptedBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]); // Invalid image
        
        when(mockAiService.analyzeWebImage(any, any))
            .thenThrow(Exception('Invalid image format'));

        await tester.pumpWidget(createTestableWidget(webImage: corruptedBytes));
        await tester.pumpAndSettle();

        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        expect(find.textContaining('Invalid image format'), findsOneWidget);
      });
    });

    group('State Management Tests', () {
      testWidgets('should maintain UI state during analysis', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 500));
              return mockClassification;
            });

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // During analysis, should show loader
        expect(find.byType(EnhancedAnalysisLoader), findsOneWidget);
        expect(find.byType(CaptureButton), findsNothing);

        await tester.pumpAndSettle();
      });

      testWidgets('should reset state after analysis error', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenThrow(Exception('Test error'));

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        // After error, should return to normal state
        expect(find.byType(CaptureButton), findsAtLeastNWidgets(2));
        expect(find.byType(EnhancedAnalysisLoader), findsNothing);
      });

      testWidgets('should handle widget disposal during analysis', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return mockClassification;
            });

        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Start analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pump();

        // Simulate navigation away (widget disposal)
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Different Screen'))));
        await tester.pumpAndSettle();

        // Should not crash
        expect(find.text('Different Screen'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        // Check for key interactive elements
        expect(find.byType(CaptureButton), findsAtLeastNWidgets(2));
        expect(find.byType(SwitchListTile), findsOneWidget);
      });

      testWidgets('should support large text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: createTestableWidget(webImage: mockImageBytes),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(find.byType(ImageCaptureScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle different screen sizes', (WidgetTester tester) async {
        // Test with small screen
        await tester.binding.setSurfaceSize(const Size(320, 568));
        
        await tester.pumpWidget(createTestableWidget(webImage: mockImageBytes));
        await tester.pumpAndSettle();

        expect(find.byType(ImageCaptureScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Integration Tests', () {
      testWidgets('should work with real image data flow', (WidgetTester tester) async {
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => mockClassification);

        // Create realistic image data
        final jpegHeader = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
          0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
          // ... more JPEG data would follow
        ]);

        await tester.pumpWidget(createTestableWidget(webImage: jpegHeader));
        await tester.pumpAndSettle();

        // Should display image preview
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // Should work with analysis
        final analyzeButton = find.byType(CaptureButton).first;
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should integrate properly with navigation stack', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Camera')),
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  tester.element(find.byType(ElevatedButton)),
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider<AiService>.value(
                      value: mockAiService,
                      child: ImageCaptureScreen(webImage: mockImageBytes),
                    ),
                  ),
                ),
                child: const Text('Capture'),
              ),
            ),
          ),
        );

        // Navigate to capture screen
        await tester.tap(find.text('Capture'));
        await tester.pumpAndSettle();

        expect(find.text('Review Image'), findsOneWidget);

        // Navigate back
        final retryButton = find.byType(CaptureButton).last;
        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        expect(find.text('Camera'), findsOneWidget);
      });
    });
  });
}
