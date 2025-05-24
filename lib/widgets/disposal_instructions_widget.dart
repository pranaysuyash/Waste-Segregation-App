import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/disposal_instructions.dart';
import '../utils/constants.dart';

/// Widget to display complete disposal instructions
class DisposalInstructionsWidget extends StatefulWidget {
  final DisposalInstructions instructions;
  final Function(DisposalStep)? onStepCompleted;
  final bool showLocations;

  const DisposalInstructionsWidget({
    super.key,
    required this.instructions,
    this.onStepCompleted,
    this.showLocations = true,
  });

  @override
  State<DisposalInstructionsWidget> createState() => _DisposalInstructionsWidgetState();
}

class _DisposalInstructionsWidgetState extends State<DisposalInstructionsWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _completedPreparationSteps = {};
  final Set<int> _completedDisposalSteps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showLocations ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          // Header with disposal urgency indicator
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
                  widget.instructions.requiresSpecialHandling 
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
                      Text(
                        'How to Dispose This Item',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.instructions.timeframe.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              widget.instructions.hasUrgentTimeframe 
                                  ? Icons.schedule 
                                  : Icons.info_outline,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.instructions.timeframe,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.instructions.estimatedTotalTime.inMinutes > 0)
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
                      '~${widget.instructions.estimatedTotalTime.inMinutes}min',
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
          if (widget.instructions.safetyWarnings.isNotEmpty)
            _buildSafetyWarnings(),

          // Tab bar for different sections
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.format_list_numbered),
                text: 'Steps (${widget.instructions.totalSteps})',
              ),
              const Tab(
                icon: Icon(Icons.lightbulb_outline),
                text: 'Tips',
              ),
              if (widget.showLocations)
                Tab(
                  icon: const Icon(Icons.location_on),
                  text: 'Locations (${widget.instructions.recommendedLocations.length})',
                ),
            ],
          ),

          // Tab content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStepsTab(),
                _buildTipsTab(),
                if (widget.showLocations)
                  _buildLocationsTab(),
              ],
            ),
          ),
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
          ...widget.instructions.safetyWarnings.map((warning) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Icon(
                      warning.icon,
                      color: warning.level.color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning.message,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildStepsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preparation steps
          if (widget.instructions.preparationSteps.isNotEmpty) ...[
            _buildSectionHeader('Preparation Steps', Icons.cleaning_services),
            const SizedBox(height: AppTheme.paddingSmall),
            ...widget.instructions.preparationSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return DisposalStepWidget(
                step: step,
                stepNumber: index + 1,
                isCompleted: _completedPreparationSteps.contains(index),
                onToggleCompleted: () {
                  setState(() {
                    if (_completedPreparationSteps.contains(index)) {
                      _completedPreparationSteps.remove(index);
                    } else {
                      _completedPreparationSteps.add(index);
                    }
                  });
                  widget.onStepCompleted?.call(step);
                },
              );
            }).toList(),
            const SizedBox(height: AppTheme.paddingLarge),
          ],

          // Disposal steps
          if (widget.instructions.disposalSteps.isNotEmpty) ...[
            _buildSectionHeader('Disposal Steps', Icons.delete),
            const SizedBox(height: AppTheme.paddingSmall),
            ...widget.instructions.disposalSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return DisposalStepWidget(
                step: step,
                stepNumber: widget.instructions.preparationSteps.length + index + 1,
                isCompleted: _completedDisposalSteps.contains(index),
                onToggleCompleted: () {
                  setState(() {
                    if (_completedDisposalSteps.contains(index)) {
                      _completedDisposalSteps.remove(index);
                    } else {
                      _completedDisposalSteps.add(index);
                    }
                  });
                  widget.onStepCompleted?.call(step);
                },
              );
            }).toList(),
          ],

          // Collection schedule if available
          if (widget.instructions.collectionSchedule != null) ...[
            const SizedBox(height: AppTheme.paddingLarge),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.instructions.collectionSchedule!,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Common mistakes
          if (widget.instructions.commonMistakes.isNotEmpty) ...[
            _buildSectionHeader('Common Mistakes to Avoid', Icons.error_outline),
            const SizedBox(height: AppTheme.paddingSmall),
            ...widget.instructions.commonMistakes.map((mistake) =>
              _buildTipItem(mistake, Icons.close, Colors.red.shade600),
            ).toList(),
            const SizedBox(height: AppTheme.paddingLarge),
          ],

          // Environmental benefits
          if (widget.instructions.environmentalBenefits.isNotEmpty) ...[
            _buildSectionHeader('Environmental Benefits', Icons.eco),
            const SizedBox(height: AppTheme.paddingSmall),
            ...widget.instructions.environmentalBenefits.map((benefit) =>
              _buildTipItem(benefit, Icons.check_circle, Colors.green.shade600),
            ).toList(),
            const SizedBox(height: AppTheme.paddingLarge),
          ],

          // Alternative disposal method
          if (widget.instructions.alternativeDisposalMethod != null) ...[
            _buildSectionHeader('Alternative Method', Icons.alt_route),
            const SizedBox(height: AppTheme.paddingSmall),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                widget.instructions.alternativeDisposalMethod!,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeRegular,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      itemCount: widget.instructions.recommendedLocations.length,
      itemBuilder: (context, index) {
        final location = widget.instructions.recommendedLocations[index];
        return DisposalLocationCard(
          location: location,
          onCallPressed: () => _callLocation(location),
          onDirectionsPressed: () => _getDirections(location),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callLocation(DisposalLocation location) async {
    if (location.phoneNumber != null) {
      final uri = Uri.parse('tel:${location.phoneNumber}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _getDirections(DisposalLocation location) async {
    String query = Uri.encodeComponent(location.address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Widget for individual disposal steps with checkbox
class DisposalStepWidget extends StatelessWidget {
  final DisposalStep step;
  final int stepNumber;
  final bool isCompleted;
  final VoidCallback? onToggleCompleted;

  const DisposalStepWidget({
    super.key,
    required this.step,
    required this.stepNumber,
    this.isCompleted = false,
    this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      child: InkWell(
        onTap: onToggleCompleted,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.green.shade50 
                : (step.isOptional ? Colors.grey.shade50 : Colors.white),
            border: Border.all(
              color: isCompleted 
                  ? Colors.green.shade300 
                  : (step.isOptional ? Colors.grey.shade300 : Colors.grey.shade200),
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number or checkbox
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.shade600 
                      : (step.isOptional ? Colors.grey.shade400 : AppTheme.primaryColor),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          stepNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Step icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  step.icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Step content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.instruction,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              fontWeight: FontWeight.w500,
                              color: isCompleted 
                                  ? Colors.green.shade800 
                                  : AppTheme.textPrimaryColor,
                              decoration: isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                        ),
                        if (step.isOptional)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (step.estimatedTime != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${step.estimatedTime!.inMinutes}min',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    if (step.additionalInfo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.additionalInfo!,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    
                    if (step.warningMessage != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade600,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              step.warningMessage!,
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying disposal location information
class DisposalLocationCard extends StatelessWidget {
  final DisposalLocation location;
  final VoidCallback? onCallPressed;
  final VoidCallback? onDirectionsPressed;

  const DisposalLocationCard({
    super.key,
    required this.location,
    this.onCallPressed,
    this.onDirectionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    location.type.icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        location.type.displayName,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (location.isOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            // Address and distance
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.address,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (location.distanceKm != null)
                  Text(
                    '${location.distanceKm!.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            
            // Accepted waste types
            if (location.acceptedWasteTypes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: location.acceptedWasteTypes.take(3).map((type) => 
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
            
            // Special instructions
            if (location.specialInstructions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade800,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location.specialInstructions.first,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                if (location.phoneNumber != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCallPressed,
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                if (location.phoneNumber != null)
                  const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDirectionsPressed,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact disposal summary widget for use in lists
class DisposalSummaryWidget extends StatelessWidget {
  final DisposalInstructions instructions;
  final VoidCallback? onViewDetails;

  const DisposalSummaryWidget({
    super.key,
    required this.instructions,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: instructions.hasUrgentTimeframe 
            ? Colors.red.shade50 
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        border: Border.all(
          color: instructions.hasUrgentTimeframe 
              ? Colors.red.shade200 
              : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                instructions.requiresSpecialHandling 
                    ? Icons.warning 
                    : Icons.delete_outline,
                color: instructions.hasUrgentTimeframe 
                    ? Colors.red.shade700 
                    : Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Disposal Instructions',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: instructions.hasUrgentTimeframe 
                        ? Colors.red.shade800 
                        : Colors.blue.shade800,
                  ),
                ),
              ),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View All'),
                ),
            ],
          ),
          
          if (instructions.timeframe.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              instructions.timeframe,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: instructions.hasUrgentTimeframe 
                    ? Colors.red.shade700 
                    : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          Row(
            children: [
              _buildQuickStat(
                '${instructions.totalSteps} steps',
                Icons.format_list_numbered,
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              if (instructions.estimatedTotalTime.inMinutes > 0)
                _buildQuickStat(
                  '~${instructions.estimatedTotalTime.inMinutes}min',
                  Icons.schedule,
                ),
              const SizedBox(width: AppTheme.paddingRegular),
              if (instructions.recommendedLocations.isNotEmpty)
                _buildQuickStat(
                  '${instructions.recommendedLocations.length} locations',
                  Icons.location_on,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
