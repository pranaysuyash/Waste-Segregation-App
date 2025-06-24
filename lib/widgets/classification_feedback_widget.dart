import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../models/gamification.dart';
import '../utils/constants.dart';
import '../screens/result_screen.dart';

/// Widget for collecting user feedback on classification accuracy
class ClassificationFeedbackWidget extends StatefulWidget {
  const ClassificationFeedbackWidget({
    super.key,
    required this.classification,
    required this.onFeedbackSubmitted,
    this.showCompactVersion = false,
  });
  final WasteClassification classification;
  final Function(WasteClassification updatedClassification) onFeedbackSubmitted;
  final bool showCompactVersion;

  @override
  State<ClassificationFeedbackWidget> createState() => _ClassificationFeedbackWidgetState();
}

class _ClassificationFeedbackWidgetState extends State<ClassificationFeedbackWidget> {
  bool? _userConfirmed;
  String? _selectedCorrection;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customCorrectionController = TextEditingController();
  bool _showCorrectionOptions = false;
  bool _showCustomCorrection = false;
  bool _isReanalyzing = false; // Track reanalysis state
  int feedbackTimeframeDays = 7; // Default feedback timeframe
  bool _showExpandedFeedback = false; // Track inline expansion instead of modal

  // Common correction options based on analysis of frequent mistakes
  final List<String> _commonCorrections = [
    'Wet Waste',
    'Dry Waste',
    'Hazardous Waste',
    'Medical Waste',
    'Non-Waste',
    'Different subcategory',
    'Wrong material type',
    'Custom correction...'
  ];

  // List of all models to try, in order
  static const List<String> _modelSequence = [
    ApiConfig.primaryModel,
    ApiConfig.secondaryModel1,
    ApiConfig.secondaryModel2,
    ApiConfig.tertiaryModel,
  ];

  List<String> get _modelsTried => widget.classification.reanalysisModelsTried ?? [];
  String? get _nextModelToTry {
    for (final model in _modelSequence) {
      if (!_modelsTried.contains(model)) return model;
    }
    return null;
  }

  bool get _allModelsExhausted => _nextModelToTry == null;

  @override
  void initState() {
    super.initState();
    _userConfirmed = widget.classification.userConfirmed;
    _selectedCorrection = widget.classification.userCorrection;
    _notesController.text = widget.classification.userNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customCorrectionController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    String? correctedCategory;
    // String? correctedSubcategory; // This was declared but never used, can be kept or removed

    if (_userConfirmed == false && _selectedCorrection != null) {
      if (_selectedCorrection == 'Custom correction...') {
        correctedCategory =
            _customCorrectionController.text.trim().isNotEmpty ? _customCorrectionController.text.trim() : null;
      } else {
        correctedCategory = _selectedCorrection;
      }

      // REMOVED: Correction analytics
      // if (correctedCategory != null) {
      //   analyticsService.trackUserAction('classification_corrected', ...);
      // }
    }

    DisposalInstructions? updatedDisposalInstructions;
    if (correctedCategory != null) {
      updatedDisposalInstructions = _generateDisposalInstructionsForCategory(correctedCategory);
    }

    final updatedClassification = widget.classification.copyWith(
      category: correctedCategory ?? widget.classification.category,
      disposalInstructions: updatedDisposalInstructions ?? widget.classification.disposalInstructions,
      userConfirmed: _userConfirmed,
      userCorrection: _selectedCorrection == 'Custom correction...'
          ? _customCorrectionController.text.trim().isNotEmpty
              ? _customCorrectionController.text.trim()
              : null
          : _selectedCorrection,
      userNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      viewCount: (widget.classification.viewCount ?? 0) + 1, // This seems like existing logic
      confirmedByModel: _nextModelToTry, // Track which model was confirmed correct
    );

    analyticsService.trackEvent(
      eventType: AnalyticsEventTypes.userAction,
      eventName: 'classification_feedback_submitted',
      parameters: {
        'is_correct': _userConfirmed,
        'has_correction': correctedCategory != null,
        'original_category': widget.classification.category,
        if (correctedCategory != null) 'corrected_category': correctedCategory,
      },
    );

    if (correctedCategory != null) {
      analyticsService.trackEvent(
        eventType: AnalyticsEventTypes.userAction,
        eventName: 'classification_corrected',
        parameters: {
          'original_category': widget.classification.category,
          'corrected_category': correctedCategory,
        },
      );
    }

    widget.onFeedbackSubmitted(updatedClassification);
  }

  /// Generate appropriate disposal instructions for a given category
  DisposalInstructions _generateDisposalInstructionsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return DisposalInstructions(
          primaryMethod: 'Compost or wet waste bin',
          steps: [
            'Remove any non-biodegradable packaging',
            'Place in designated wet waste bin',
            'Ensure proper drainage to avoid odors',
            'Collect daily for municipal pickup'
          ],
          timeframe: 'Daily collection',
          location: 'Wet waste bin',
          tips: ['Keep bin covered', 'Drain excess liquids'],
          hasUrgentTimeframe: false,
        );
      case 'dry waste':
        return DisposalInstructions(
          primaryMethod: 'Recycle or dry waste bin',
          steps: [
            'Clean and dry the item',
            'Remove any labels if possible',
            'Sort by material type if required',
            'Place in dry waste bin'
          ],
          timeframe: 'Weekly collection',
          location: 'Dry waste bin or recycling center',
          tips: ['Clean items recycle better', 'Sort by material when possible'],
          hasUrgentTimeframe: false,
        );
      case 'hazardous waste':
        return DisposalInstructions(
          primaryMethod: 'Special disposal facility',
          steps: [
            'Do not mix with regular waste',
            'Store safely until disposal',
            'Take to designated hazardous waste facility',
            'Follow facility-specific guidelines'
          ],
          timeframe: 'As soon as possible',
          location: 'Hazardous waste collection center',
          warnings: ['Never dispose in regular bins', 'Can contaminate other waste'],
          hasUrgentTimeframe: true,
        );
      case 'medical waste':
        return DisposalInstructions(
          primaryMethod: 'Medical waste disposal',
          steps: [
            'Place in puncture-proof container',
            'Seal container properly',
            'Take to pharmacy or medical facility',
            'Never dispose in regular waste'
          ],
          timeframe: 'Immediately',
          location: 'Pharmacy or medical facility',
          warnings: ['Risk of infection', 'Environmental contamination'],
          hasUrgentTimeframe: true,
        );
      case 'non-waste':
        return DisposalInstructions(
          primaryMethod: 'Reuse, donate, or repurpose',
          steps: [
            'Clean the item if needed',
            'Consider donating if in good condition',
            'Repurpose for other uses',
            'Only discard if truly unusable'
          ],
          timeframe: 'No urgency',
          location: 'Donation centers, reuse',
          tips: ['Extend item lifespan', 'Consider creative reuses'],
          hasUrgentTimeframe: false,
        );
      default:
        return DisposalInstructions(
          primaryMethod: 'Review disposal method',
          steps: [
            'Identify the correct waste category',
            'Consult local waste guidelines',
            'Use appropriate disposal method'
          ],
          timeframe: 'When convenient',
          location: 'Appropriate waste bin',
          hasUrgentTimeframe: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showCompactVersion) {
      return _buildCompactFeedback();
    }

    return _buildFullFeedback();
  }

  Widget _buildCompactFeedback() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Very light blue for accessibility
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        border: Border.all(color: const Color(0xFF1976D2)), // Dark blue border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: Color(0xFF0D47A1), // Dark blue for contrast
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Was this classification correct?',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D47A1), // Dark blue text
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, // Allow wrapping to 2 lines
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          LayoutBuilder(
            builder: (context, constraints) {
              // If screen is very narrow, use column layout
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _userConfirmed = true;
                            _showCorrectionOptions = false;
                          });
                          _submitFeedback();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _userConfirmed == true ? Colors.green.shade600 : Colors.green.shade100,
                          foregroundColor: _userConfirmed == true ? Colors.white : Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        icon: Icon(_userConfirmed == true ? Icons.check_circle : Icons.thumb_up, size: 18),
                        label: const Text('Correct', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _userConfirmed = false;
                            _showCorrectionOptions = true;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _userConfirmed == false ? Colors.orange.shade50 : null,
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        icon: Icon(_userConfirmed == false ? Icons.error : Icons.thumb_down, size: 18),
                        label: const Text('Incorrect', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              }

              // For wider screens, use row layout
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userConfirmed = true;
                          _showCorrectionOptions = false;
                        });
                        _submitFeedback();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userConfirmed == true ? Colors.green.shade600 : Colors.green.shade100,
                        foregroundColor: _userConfirmed == true ? Colors.white : Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      icon: Icon(_userConfirmed == true ? Icons.check_circle : Icons.thumb_up, size: 18),
                      label: const Text('Correct', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userConfirmed = false;
                          _showCorrectionOptions = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _userConfirmed == false ? Colors.orange.shade50 : null,
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      icon: Icon(_userConfirmed == false ? Icons.error : Icons.thumb_down, size: 18),
                      label: const Text('Incorrect', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_showCorrectionOptions) ...[
            const SizedBox(height: AppTheme.paddingRegular),
            const Text(
              'What should it be?',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE65100), // Dark orange for contrast
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonCorrections.take(4).map((correction) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            (constraints.maxWidth * 0.45).clamp(80.0, 200.0), // Added clamp to prevent too narrow chips
                        minWidth: 80.0, // Minimum width to prevent overflow
                      ),
                      child: _buildCorrectionChip(correction),
                    );
                  }).toList(),
                );
              },
            ),

            // Add Re-analyze button when correction is selected
            if (_userConfirmed == false && _selectedCorrection != null && !_isReanalyzing) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _allModelsExhausted ? null : _triggerReanalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allModelsExhausted ? Colors.grey.shade300 : Colors.orange,
                    foregroundColor: _allModelsExhausted ? Colors.grey.shade600 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _allModelsExhausted ? 'No more reanalysis possible' : 'Re-analyze with correction',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_allModelsExhausted)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'All available AI models have been tried. Your feedback will help us improve future results.',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Show reanalyzing indicator
            if (_isReanalyzing) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Re-analyzing with your correction...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Inline expansion instead of modal
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showExpandedFeedback = !_showExpandedFeedback;
                });
              },
              icon: Icon(
                _showExpandedFeedback ? Icons.expand_less : Icons.expand_more,
                size: 16,
              ),
              label: Text(
                _showExpandedFeedback ? 'Less options' : 'More options',
                style: const TextStyle(fontSize: 12),
              ),
            ),

            // Expanded feedback options (inline, not modal)
            if (_showExpandedFeedback) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: AppTheme.paddingSmall),

              // Custom correction field if custom option selected
              if (_showCustomCorrection) ...[
                TextField(
                  controller: _customCorrectionController,
                  decoration: InputDecoration(
                    labelText: 'Custom correction',
                    hintText: 'Enter correct classification...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.edit, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.paddingSmall),
              ],

              // Notes field
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional notes (optional)',
                  hintText: 'Any context or details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note_add, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
              ),

              const SizedBox(height: AppTheme.paddingSmall),

              // Submit feedback button for expanded view
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _submitFeedback,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Submit Feedback', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFullFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          'Your feedback helps train our AI model to be more accurate.',
          style: TextStyle(
            fontSize: AppTheme.fontSizeRegular,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: AppTheme.paddingLarge),

        // Confirmation question
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Is this classification correct?',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Classification: ${widget.classification.itemName} → ${widget.classification.category}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeRegular,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _userConfirmed,
                      onChanged: (value) {
                        setState(() {
                          _userConfirmed = value;
                          _showCorrectionOptions = false;
                        });
                      },
                      dense: true,
                      activeColor: Colors.green.shade600,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _userConfirmed,
                      onChanged: (value) {
                        setState(() {
                          _userConfirmed = value;
                          _showCorrectionOptions = true;
                        });
                      },
                      dense: true,
                      activeColor: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Correction options
        if (_showCorrectionOptions) ...[
          const SizedBox(height: AppTheme.paddingLarge),
          const Text(
            'What should the correct classification be?',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonCorrections.map((correction) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.48,
                    ),
                    child: _buildCorrectionChip(correction),
                  );
                }).toList(),
              );
            },
          ),
          if (_showCustomCorrection) ...[
            const SizedBox(height: AppTheme.paddingRegular),
            TextField(
              controller: _customCorrectionController,
              decoration: InputDecoration(
                labelText: 'Custom correction',
                hintText: 'Enter the correct classification...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
              maxLines: 2,
            ),
          ],
        ],

        // Notes section
        const SizedBox(height: AppTheme.paddingLarge),
        const Text(
          'Additional notes (optional)',
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Any additional context or details...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            prefixIcon: const Icon(Icons.note_add),
          ),
          maxLines: 3,
        ),

        const SizedBox(height: AppTheme.paddingLarge),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.send),
            label: const Text('Submit Feedback'),
          ),
        ),

        // Add Re-analyze button for full feedback version too
        if (_userConfirmed == false && _selectedCorrection != null && !_isReanalyzing) ...[
          const SizedBox(height: AppTheme.paddingSmall),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _allModelsExhausted ? null : _triggerReanalysis,
              style: OutlinedButton.styleFrom(
                foregroundColor: _allModelsExhausted ? Colors.grey.shade600 : Colors.orange,
                side: BorderSide(color: _allModelsExhausted ? Colors.grey.shade400 : Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(_allModelsExhausted ? 'No more reanalysis possible' : 'Re-analyze with correction'),
            ),
          ),
          if (_allModelsExhausted)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'All available AI models have been tried. Your feedback will help us improve future results.',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],

        // Show reanalyzing indicator for full version
        if (_isReanalyzing) ...[
          const SizedBox(height: AppTheme.paddingSmall),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Re-analyzing with your correction...',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCorrectionChip(String correction) {
    final isSelected = _selectedCorrection == correction;
    final isCustom = correction == 'Custom correction...';

    return Semantics(
      button: true,
      selected: isSelected,
      label: isCustom ? 'Custom correction option' : 'Select $correction as correct classification',
      hint: isSelected ? 'Currently selected' : 'Tap to select',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCorrection = correction;
            if (isCustom) {
              _showCustomCorrection = true;
            } else {
              _showCustomCorrection = false;
              _customCorrectionController.clear();
            }
          });
        },
        child: Container(
          width: double.infinity, // Take full available width
          padding: const EdgeInsets.symmetric(
            horizontal: 8, // Reduced padding for tight spaces
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8), // Slightly less rounded for compactness
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle,
                  size: 14, // Smaller icon
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                // Allow text to take remaining space
                child: Text(
                  correction,
                  style: TextStyle(
                    fontSize: 11, // Smaller font for tight spaces
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85, // Increased to 85%
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                    topRight: Radius.circular(AppTheme.borderRadiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.feedback,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Help us improve classification',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      tooltip: 'Close feedback dialog',
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  child: ClassificationFeedbackWidget(
                    classification: widget.classification,
                    onFeedbackSubmitted: (updatedClassification) {
                      Navigator.of(context).pop();
                      widget.onFeedbackSubmitted(updatedClassification);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateFeedbackTimeframe(int newTimeframe) async {
    // This would normally update user settings, but since this widget
    // is focused on feedback, we'll just update the local state
    setState(() {
      feedbackTimeframeDays = newTimeframe;
    });
  }

  Future<void> _triggerReanalysis() async {
    if (_selectedCorrection == null) return;

    setState(() {
      _isReanalyzing = true;
    });

    // Get the final correction text and user reason outside try block
    var correctionText = _selectedCorrection!;
    if (_selectedCorrection == 'Custom correction...' && _customCorrectionController.text.trim().isNotEmpty) {
      correctionText = _customCorrectionController.text.trim();
    }

    final userReason = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    try {
      final aiService = Provider.of<AiService>(context, listen: false);

      // If all models are exhausted, just save feedback and show message
      if (_allModelsExhausted) {
        if (mounted) {
          final originalWithFeedback = widget.classification.copyWith(
            userConfirmed: false,
            userCorrection: correctionText,
            userNotes: userReason,
            disagreementReason: 'All models exhausted. Feedback will be used for future improvements.',
            reanalysisModelsTried: _modelsTried,
          );
          widget.onFeedbackSubmitted(originalWithFeedback);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'All available AI models have been tried. Your feedback will help us improve future results.'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Call AI service to reanalyze with the next unused model
      final reanalyzedClassification = await aiService.handleUserCorrection(
        widget.classification,
        correctionText,
        userReason,
        model: _nextModelToTry,
      );

      // Update the list of tried models
      final updatedModelsTried = List<String>.from(_modelsTried)..add(_nextModelToTry!);

      // Create NEW classification entry (don't update existing)
      final newClassification = reanalyzedClassification.copyWith(
        userNotes:
            'Reanalyzed from: ${widget.classification.itemName} (${widget.classification.category})\n${userReason ?? ''}',
        userCorrection: correctionText,
        source: 'reanalysis', // Mark as reanalyzed
        viewCount: 1, // New classification starts at 1
        reanalysisModelsTried: updatedModelsTried,
      );

      // Also update original classification with user feedback (preserve for history)
      final originalWithFeedback = widget.classification.copyWith(
        userConfirmed: false,
        userCorrection: correctionText,
        userNotes: userReason,
        disagreementReason: 'User requested reanalysis - see newer entry',
        reanalysisModelsTried: updatedModelsTried,
      );

      if (mounted) {
        // Save the original with user feedback first
        widget.onFeedbackSubmitted(originalWithFeedback);

        // Brief delay then navigate to new classification
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Show navigation snackbar with action to view new results
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reanalysis complete!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.classification.category} → ${newClassification.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View Results',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to new classification result
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        classification: newClassification,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Even if reanalysis fails, save user's feedback on original classification
        final originalWithFeedback = widget.classification.copyWith(
          userConfirmed: false,
          userCorrection: correctionText,
          userNotes: userReason,
          disagreementReason: 'Reanalysis failed, but user feedback preserved: ${e.toString()}',
          reanalysisModelsTried: _modelsTried,
        );

        // Save the user feedback regardless of reanalysis failure
        widget.onFeedbackSubmitted(originalWithFeedback);

        // Show error message with explanation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reanalysis failed',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your corrections have been saved for future improvement',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReanalyzing = false;
        });
      }
    }
  }
}

/// Compact feedback button for quick access
class FeedbackButton extends StatelessWidget {
  const FeedbackButton({
    super.key,
    required this.classification,
    required this.onFeedbackSubmitted,
  });
  final WasteClassification classification;
  final Function(WasteClassification) onFeedbackSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasExistingFeedback = classification.userConfirmed != null;

    return TextButton.icon(
      onPressed: () => _showFeedbackDialog(context),
      icon: Icon(
        hasExistingFeedback ? Icons.feedback : Icons.feedback_outlined,
        size: 18,
        color: hasExistingFeedback ? Colors.green.shade600 : AppTheme.primaryColor,
      ),
      label: Text(
        hasExistingFeedback ? 'Feedback given' : 'Give feedback',
        style: TextStyle(
          color: hasExistingFeedback ? Colors.green.shade600 : AppTheme.primaryColor,
          fontSize: AppTheme.fontSizeSmall,
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85, // Increased to 85%
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                    topRight: Radius.circular(AppTheme.borderRadiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.feedback,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Help us improve classification',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      tooltip: 'Close feedback dialog',
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  child: ClassificationFeedbackWidget(
                    classification: classification,
                    onFeedbackSubmitted: onFeedbackSubmitted,
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
