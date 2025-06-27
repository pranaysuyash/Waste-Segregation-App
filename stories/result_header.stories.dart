import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:waste_segregation_app/widgets/result_screen/result_header.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: ResultHeader,
)
Widget resultHeaderUseCase(BuildContext context) {
  return const _ResultHeaderDemo();
}

@widgetbook.UseCase(
  name: 'High Confidence',
  type: ResultHeader,
)
Widget resultHeaderHighConfidenceUseCase(BuildContext context) {
  return const _ResultHeaderDemo(
    confidence: 0.95,
    pointsEarned: 25,
  );
}

@widgetbook.UseCase(
  name: 'Low Confidence',
  type: ResultHeader,
)
Widget resultHeaderLowConfidenceUseCase(BuildContext context) {
  return const _ResultHeaderDemo(
    category: 'Hazardous',
    confidence: 0.65,
    pointsEarned: 5,
  );
}

class _ResultHeaderDemo extends StatelessWidget {
  const _ResultHeaderDemo({
    this.category = 'Recyclable',
    this.confidence = 0.92,
    this.pointsEarned = 15,
  });

  final String category;
  final String itemName;
  final double confidence;
  final int pointsEarned;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    // Create mock classification
    final classification = WasteClassification(
      id: 'story-classification',
      itemName: itemName,
      category: category,
      confidence: confidence,
      timestamp: DateTime.now(),
      imageUrl: hasImage 
          ? 'https://images.unsplash.com/photo-1572297662242-0e4b9f3e0b4a?w=400&h=300&fit=crop'
          : null,
      // Required parameters
      explanation: 'This item appears to be a $itemName based on visual analysis.',
      region: 'Demo Region',
      visualFeatures: ['metallic surface', 'cylindrical shape', 'recyclable material'],
      alternatives: [],
      // Mock disposal instructions
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Recycle in designated bin',
        steps: [
          'Clean the item thoroughly',
          'Remove any labels or stickers',
          'Place in the appropriate recycling bin',
        ],
        hasUrgentTimeframe: false,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Story title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Result Header Component',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // The actual component
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(51),
                  ),
                ),
                child: ResultHeader(
                  classification: classification,
                  pointsEarned: pointsEarned,
                  onDisposeCorrectly: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispose correctly button pressed!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  heroTag: 'story-hero',
                ),
              ),
              
              // Component info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Component Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Above-the-fold content (≈60% viewport)'),
                        const Text('• Hero image with visual continuity'),
                        const Text('• Category chip with semantic colors'),
                        const Text('• Animated confidence bar'),
                        const Text('• Prominent item name'),
                        const Text('• KPI chips (points & environmental impact)'),
                        const Text('• Primary CTA with haptic feedback'),
                        const SizedBox(height: 8),
                        Text(
                          'Current Values:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('Category: $category'),
                        Text('Confidence: ${(confidence * 100).round()}%'),
                        Text('Points: $pointsEarned XP'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 