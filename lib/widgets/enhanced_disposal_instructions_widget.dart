import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../providers/disposal_instructions_provider.dart';
import '../utils/constants.dart';
import 'disposal_instructions_widget.dart';

/// Enhanced widget that fetches LLM-generated disposal instructions
class EnhancedDisposalInstructionsWidget extends ConsumerWidget {

  const EnhancedDisposalInstructionsWidget({
    super.key,
    required this.classification,
    this.onStepCompleted,
  });
  final WasteClassification classification;
  final Function(String)? onStepCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create request for disposal instructions
    final request = DisposalInstructionsRequest(
      material: _getMaterialDescription(),
      category: classification.category,
      subcategory: classification.subcategory,
    );

    // Watch the disposal instructions provider
    final disposalInstructionsAsync = ref.watch(disposalInstructionsProvider(request));

    return disposalInstructionsAsync.when(
      data: (instructions) => DisposalInstructionsWidget(
        instructions: instructions,
        onStepCompleted: onStepCompleted,
      ),
      loading: () => _buildLoadingWidget(),
      error: (error, stackTrace) => _buildErrorWidget(error),
    );
  }

  /// Get material description for LLM generation
  String _getMaterialDescription() {
    final parts = <String>[];
    
    // Add item name if available
    if (classification.itemName.isNotEmpty) {
      parts.add(classification.itemName);
    }
    
    // Add material type if available and different from item name
    if (classification.materialType != null && 
        classification.materialType!.isNotEmpty &&
        classification.materialType != classification.itemName) {
      parts.add(classification.materialType!);
    }
    
    // Add brand if available
    if (classification.brand != null && classification.brand!.isNotEmpty) {
      parts.add('(${classification.brand})');
    }
    
    // Fallback to category if no specific material info
    if (parts.isEmpty) {
      parts.add(classification.category);
    }
    
    return parts.join(' ');
  }

  /// Build loading widget while fetching instructions
  Widget _buildLoadingWidget() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generating Disposal Instructions',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'AI is creating personalized disposal guidance...',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            const LinearProgressIndicator(
              backgroundColor: AppTheme.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            const Text(
              'This may take a few seconds...',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget with fallback to existing instructions
  Widget _buildErrorWidget(Object error) {
    return Column(
      children: [
        // Show error message
        Card(
          elevation: 2,
          margin: const EdgeInsets.all(AppTheme.paddingRegular),
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            side: BorderSide(color: Colors.orange.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Instructions Unavailable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Showing standard disposal guidance instead.',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Fallback to existing disposal instructions
        DisposalInstructionsWidget(
          instructions: classification.disposalInstructions,
          onStepCompleted: onStepCompleted,
        ),
      ],
    );
  }
}

/// Widget to show both AI and fallback instructions for comparison (debug mode)
class DebugDisposalInstructionsWidget extends ConsumerWidget {

  const DebugDisposalInstructionsWidget({
    super.key,
    required this.classification,
    this.onStepCompleted,
  });
  final WasteClassification classification;
  final Function(String)? onStepCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DisposalInstructionsRequest(
      material: _getMaterialDescription(),
      category: classification.category,
      subcategory: classification.subcategory,
    );

    final disposalInstructionsAsync = ref.watch(disposalInstructionsProvider(request));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI-generated instructions
        disposalInstructionsAsync.when(
          data: (instructions) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingRegular,
                  vertical: AppTheme.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'AI-Generated Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
              DisposalInstructionsWidget(
                instructions: instructions,
                onStepCompleted: onStepCompleted,
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        
        const SizedBox(height: AppTheme.paddingRegular),
        
        // Fallback instructions for comparison
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingRegular,
            vertical: AppTheme.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.rule, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Standard Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
            ],
          ),
        ),
        DisposalInstructionsWidget(
          instructions: classification.disposalInstructions,
          onStepCompleted: onStepCompleted,
        ),
      ],
    );
  }

  String _getMaterialDescription() {
    final parts = <String>[];
    
    if (classification.itemName.isNotEmpty) {
      parts.add(classification.itemName);
    }
    
    if (classification.materialType != null && 
        classification.materialType!.isNotEmpty &&
        classification.materialType != classification.itemName) {
      parts.add(classification.materialType!);
    }
    
    if (classification.brand != null && classification.brand!.isNotEmpty) {
      parts.add('(${classification.brand})');
    }
    
    if (parts.isEmpty) {
      parts.add(classification.category);
    }
    
    return parts.join(' ');
  }
} 