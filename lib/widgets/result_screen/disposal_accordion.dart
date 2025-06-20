import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/waste_classification.dart';

/// DisposalAccordion provides progressive disclosure for disposal instructions
/// Implements the below-the-fold accordion design from the plan
class DisposalAccordion extends ConsumerStatefulWidget {
  const DisposalAccordion({
    super.key,
    required this.classification,
    this.initiallyExpanded = false,
  });

  final WasteClassification classification;
  final bool initiallyExpanded;

  @override
  ConsumerState<DisposalAccordion> createState() => _DisposalAccordionState();
}

class _DisposalAccordionState extends ConsumerState<DisposalAccordion>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _expansionController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, colorScheme),
          _buildExpandableContent(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final disposalSteps = widget.classification.disposalInstructions.steps ?? [];
    final stepCount = disposalSteps.length;
    
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.recycling_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Title and preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                     Text(
                     'Disposal Steps',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.w600,
                       color: colorScheme.onSurface,
                     ),
                   ),
                   const SizedBox(height: 2),
                   Text(
                     _isExpanded 
                         ? '$stepCount steps to dispose correctly'
                         : _getPreviewText(),
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: colorScheme.onSurfaceVariant,
                     ),
                     maxLines: _isExpanded ? null : 1,
                     overflow: _isExpanded ? null : TextOverflow.ellipsis,
                   ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Expansion indicator
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(BuildContext context, ColorScheme colorScheme) {
    return SizeTransition(
      sizeFactor: _expansionAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStaggeredSteps(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildStaggeredSteps(BuildContext context, ColorScheme colorScheme) {
    final disposalSteps = widget.classification.disposalInstructions.steps ?? [];
    
    if (disposalSteps.isEmpty) {
      return _buildNoStepsMessage(context, colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Steps list with staggered animation
        ...disposalSteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          
          return AnimatedBuilder(
            animation: _expansionAnimation,
            builder: (context, child) {
              // Staggered delay for each step
              final delay = index * 0.1;
              final progress = (_expansionAnimation.value - delay).clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(0, (1 - progress) * 20),
                child: Opacity(
                  opacity: progress,
                  child: _buildStep(
                    context,
                    colorScheme,
                    index + 1,
                    step,
                  ),
                ),
              );
            },
          );
        }),
        
                 // Additional info if available
         if (widget.classification.disposalInstructions.tips != null && 
             widget.classification.disposalInstructions.tips!.isNotEmpty) ...[
           const SizedBox(height: 16),
           _buildAdditionalInfo(context, colorScheme),
         ],
      ],
    );
  }

  Widget _buildStep(BuildContext context, ColorScheme colorScheme, int stepNumber, String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Step content
          Expanded(
            child: Text(
              step,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, ColorScheme colorScheme) {
    final tips = widget.classification.disposalInstructions.tips;
    if (tips == null || tips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $tip',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNoStepsMessage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.help_outline_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No specific disposal instructions available for this item.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPreviewText() {
    final disposalSteps = widget.classification.disposalInstructions.steps ?? [];
    if (disposalSteps.isEmpty) {
      return 'Tap to view disposal guidelines';
    }
    
    // Show first step as preview
    final firstStep = disposalSteps.first;
    const maxLength = 60;
    
    if (firstStep.length <= maxLength) {
      return firstStep;
    }
    
    return '${firstStep.substring(0, maxLength)}...';
  }
} 