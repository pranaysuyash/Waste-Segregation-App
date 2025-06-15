import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/enhanced_disposal_instructions_widget.dart';
import 'package:waste_segregation_app/providers/disposal_instructions_provider.dart';

void main() {
  group('EnhancedDisposalInstructionsWidget', () {
    late WasteClassification mockClassification;

    setUp(() {
      mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test-id',
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        materialType: 'PET Plastic',
        explanation: 'This is a plastic bottle made of PET plastic',
        region: 'Test Region',
        visualFeatures: ['transparent', 'bottle-shaped'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle in blue bin',
          steps: ['Clean the bottle', 'Remove cap', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
      );
    });

    testWidgets('should show loading widget initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedDisposalInstructionsWidget(
                classification: mockClassification,
              ),
            ),
          ),
        ),
      );

      // Should show loading widget initially
      expect(find.text('Generating Disposal Instructions'), findsOneWidget);
      expect(find.text('AI is creating personalized disposal guidance...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error widget when provider fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disposalInstructionsProvider.overrideWith((ref, request) async {
              throw Exception('Network error');
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedDisposalInstructionsWidget(
                classification: mockClassification,
              ),
            ),
          ),
        ),
      );

      // Wait for the provider to complete
      await tester.pumpAndSettle();

      // Should show error message and fallback instructions
      expect(find.text('AI Instructions Unavailable'), findsOneWidget);
      expect(find.text('Showing standard disposal guidance instead.'), findsOneWidget);
      
      // Should still show disposal instructions (fallback)
      expect(find.text('Disposal Instructions'), findsOneWidget);
    });

    testWidgets('should show disposal instructions when provider succeeds', (WidgetTester tester) async {
      final mockInstructions = DisposalInstructions(
        primaryMethod: 'AI-generated disposal method',
        steps: [
          'AI Step 1: Clean thoroughly',
          'AI Step 2: Remove all labels',
          'AI Step 3: Place in appropriate bin',
          'AI Step 4: Ensure proper sorting'
        ],
        hasUrgentTimeframe: false,
        timeframe: 'Weekly collection',
        location: 'Blue recycling bin',
        tips: ['Rinse with cold water', 'Check local guidelines'],
        warnings: ['Ensure no food residue remains'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disposalInstructionsProvider.overrideWith((ref, request) async {
              return mockInstructions;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedDisposalInstructionsWidget(
                classification: mockClassification,
              ),
            ),
          ),
        ),
      );

      // Wait for the provider to complete
      await tester.pumpAndSettle();

      // Should show the disposal instructions widget with AI-generated content
      expect(find.text('Disposal Instructions'), findsOneWidget);
      expect(find.text('AI-generated disposal method'), findsOneWidget);
      expect(find.text('Steps to Follow'), findsOneWidget);
      
      // Should show AI-generated steps
      expect(find.text('AI Step 1: Clean thoroughly'), findsOneWidget);
      expect(find.text('AI Step 2: Remove all labels'), findsOneWidget);
    });

    testWidgets('should handle step completion callback', (WidgetTester tester) async {
      String? completedStep;
      
      final mockInstructions = DisposalInstructions(
        primaryMethod: 'Test method',
        steps: ['Step 1', 'Step 2'],
        hasUrgentTimeframe: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disposalInstructionsProvider.overrideWith((ref, request) async {
              return mockInstructions;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedDisposalInstructionsWidget(
                classification: mockClassification,
                onStepCompleted: (step) {
                  completedStep = step;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a step checkbox
      final stepCheckbox = find.byType(Checkbox).first;
      expect(stepCheckbox, findsOneWidget);
      
      await tester.tap(stepCheckbox);
      await tester.pumpAndSettle();

      // Callback should have been called
      expect(completedStep, isNotNull);
    });

    testWidgets('should generate correct material description', (WidgetTester tester) async {
      final classificationWithBrand = mockClassification.copyWith(
        brand: 'Coca-Cola',
        itemName: 'Soda Bottle',
        materialType: 'PET Plastic',
      );

      String? capturedMaterial;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disposalInstructionsProvider.overrideWith((ref, request) async {
              capturedMaterial = request.material;
              return DisposalInstructions(
                primaryMethod: 'Test',
                steps: ['Test step'],
                hasUrgentTimeframe: false,
              );
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedDisposalInstructionsWidget(
                classification: classificationWithBrand,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should include item name, material type, and brand
      expect(capturedMaterial, contains('Soda Bottle'));
      expect(capturedMaterial, contains('PET Plastic'));
      expect(capturedMaterial, contains('Coca-Cola'));
    });
  });
} 