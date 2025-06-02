import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';

/// Widget for collecting user feedback on classification accuracy
class ClassificationFeedbackWidget extends StatefulWidget {
  final WasteClassification classification;
  final Function(WasteClassification updatedClassification) onFeedbackSubmitted;
  final bool showCompactVersion;

  const ClassificationFeedbackWidget({
    super.key,
    required this.classification,
    required this.onFeedbackSubmitted,
    this.showCompactVersion = false,
  });

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
    // REMOVED: Feedback submission analytics
    // final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    // analyticsService.trackUserAction('classification_feedback_submitted', ...);
    
    String? correctedCategory;
    // String? correctedSubcategory; // This was declared but never used, can be kept or removed
    
    if (_userConfirmed == false && _selectedCorrection != null) {
      if (_selectedCorrection == 'Custom correction...') {
        correctedCategory = _customCorrectionController.text.trim().isNotEmpty 
            ? _customCorrectionController.text.trim()
            : null;
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
      userNotes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      viewCount: (widget.classification.viewCount ?? 0) + 1, // This seems like existing logic
    );

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
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: const Color(0xFF0D47A1), // Dark blue for contrast
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Was this classification correct?',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0D47A1), // Dark blue text
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
                          backgroundColor: _userConfirmed == true 
                              ? Colors.green.shade600 
                              : Colors.green.shade100,
                          foregroundColor: _userConfirmed == true 
                              ? Colors.white 
                              : Colors.green.shade800,
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
                          backgroundColor: _userConfirmed == false 
                              ? Colors.orange.shade50 
                              : null,
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
                        backgroundColor: _userConfirmed == true 
                            ? Colors.green.shade600 
                            : Colors.green.shade100,
                        foregroundColor: _userConfirmed == true 
                            ? Colors.white 
                            : Colors.green.shade800,
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
                        backgroundColor: _userConfirmed == false 
                            ? Colors.orange.shade50 
                            : null,
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
            Text(
              'What should it be?',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE65100), // Dark orange for contrast
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
                        maxWidth: (constraints.maxWidth * 0.45).clamp(80.0, 200.0), // Added clamp to prevent too narrow chips
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
                  onPressed: _triggerReanalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Re-analyze with correction', style: TextStyle(fontSize: 12)),
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
            
            TextButton(
              onPressed: () => _showFullFeedbackDialog(),
              child: const Text('More options...'),
            ),
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
                  Text(
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
                          title: const Text('Yes, correct'),
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
                          title: const Text('No, incorrect'),
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
              Text(
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
            Text(
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
                  onPressed: _triggerReanalysis,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-analyze with correction'),
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
      label: isCustom 
          ? 'Custom correction option' 
          : 'Select $correction as correct classification',
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade300,
            ),
          ),
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    correction,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: isSelected 
                          ? Colors.white 
                          : Colors.grey.shade800,
                      fontWeight: isSelected 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                    topRight: Radius.circular(AppTheme.borderRadiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.feedback,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                    showCompactVersion: false,
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

    try {
      final aiService = Provider.of<AiService>(context, listen: false);
      
      // Get the final correction text
      String correctionText = _selectedCorrection!;
      if (_selectedCorrection == 'Custom correction...' && 
          _customCorrectionController.text.trim().isNotEmpty) {
        correctionText = _customCorrectionController.text.trim();
      }
      
      // Get user reason/notes
      String? userReason = _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null;
      
      // Call AI service to reanalyze with correction
      final reanalyzedClassification = await aiService.handleUserCorrection(
        widget.classification,
        correctionText,
        userReason,
        // Note: imageBytes not available in WasteClassification model
        // This will do text-only reanalysis with the user's correction
      );
      
      // Update the classification with reanalysis results and user feedback
      final updatedClassification = reanalyzedClassification.copyWith(
        userConfirmed: false, // Keep as false since user marked it incorrect
        userCorrection: correctionText,
        userNotes: userReason,
        viewCount: (widget.classification.viewCount ?? 0) + 1,
      );
      
      if (mounted) {
        // Submit the updated classification
        widget.onFeedbackSubmitted(updatedClassification);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Re-analysis complete! Updated classification with your correction.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Re-analysis failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
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
  final WasteClassification classification;
  final Function(WasteClassification) onFeedbackSubmitted;

  const FeedbackButton({
    super.key,
    required this.classification,
    required this.onFeedbackSubmitted,
  });

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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                    topRight: Radius.circular(AppTheme.borderRadiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.feedback,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                    showCompactVersion: false,
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
