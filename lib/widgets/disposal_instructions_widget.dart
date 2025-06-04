import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';

/// Widget to display disposal instructions
class DisposalInstructionsWidget extends StatefulWidget {

  const DisposalInstructionsWidget({
    super.key,
    required this.instructions,
    this.onStepCompleted,
  });
  final DisposalInstructions instructions;
  final Function(String)? onStepCompleted;

  @override
  State<DisposalInstructionsWidget> createState() => _DisposalInstructionsWidgetState();
}

class _DisposalInstructionsWidgetState extends State<DisposalInstructionsWidget> {
  final Set<int> _completedSteps = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                topRight: Radius.circular(AppTheme.borderRadiusLarge),
              ),
              gradient: LinearGradient(
                colors: widget.instructions.hasUrgentTimeframe
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.instructions.hasUrgentTimeframe 
                      ? Icons.warning 
                      : Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Disposal Instructions',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.instructions.primaryMethod,
                        maxLines: 2, // Added maxLines
                        overflow: TextOverflow.ellipsis, // Added ellipsis
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeRegular,
                          color: Colors.white70,
                        ),
                      ),
                      if (widget.instructions.timeframe != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.instructions.timeframe!,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.instructions.estimatedTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.instructions.estimatedTime!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Safety warnings if present
          if (widget.instructions.warnings != null && widget.instructions.warnings!.isNotEmpty)
            _buildSafetyWarnings(),

          // Steps
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Steps to Follow',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                ...widget.instructions.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCompleted = _completedSteps.contains(index);
                  
                  return _buildStepItem(index, step, isCompleted);
                }),
              ],
            ),
          ),

          // Tips if present
          if (widget.instructions.tips != null && widget.instructions.tips!.isNotEmpty)
            _buildTipsSection(),

          // Recycling info if present
          if (widget.instructions.recyclingInfo != null)
            _buildRecyclingInfo(),

          // Location if present
          if (widget.instructions.location != null)
            _buildLocationInfo(),
        ],
      ),
    );
  }

  Widget _buildSafetyWarnings() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Safety Warnings',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          ...widget.instructions.warnings!.map((warning) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      maxLines: 3, // Added maxLines
                      overflow: TextOverflow.ellipsis, // Added ellipsis
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int index, String step, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isCompleted) {
                  _completedSteps.remove(index);
                } else {
                  _completedSteps.add(index);
                  widget.onStepCompleted?.call(step);
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Expanded(
            child: Text(
              step,
              maxLines: 3, // Added maxLines
              overflow: TextOverflow.ellipsis, // Added ellipsis
              style: TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: isCompleted ? Colors.grey.shade600 : AppTheme.textPrimaryColor,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Helpful Tips',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          ...widget.instructions.tips!.map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      maxLines: 3, // Added maxLines
                      overflow: TextOverflow.ellipsis, // Added ellipsis
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclingInfo() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recycling,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recycling Information',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            widget.instructions.recyclingInfo!,
            maxLines: 3, // Added maxLines
            overflow: TextOverflow.ellipsis, // Added ellipsis
            style: TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Where to Dispose',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            widget.instructions.location!,
            maxLines: 3, // Added maxLines
            overflow: TextOverflow.ellipsis, // Added ellipsis
            style: TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
