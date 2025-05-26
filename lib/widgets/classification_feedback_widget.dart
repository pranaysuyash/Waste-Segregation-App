import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
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
    final updatedClassification = widget.classification.copyWith(
      // Updated user feedback data
      userConfirmed: _userConfirmed,
      userCorrection: _selectedCorrection == 'Custom correction...' 
          ? _customCorrectionController.text.trim().isNotEmpty 
              ? _customCorrectionController.text.trim()
              : null
          : _selectedCorrection,
      userNotes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      viewCount: (widget.classification.viewCount ?? 0) + 1,
    );

    widget.onFeedbackSubmitted(updatedClassification);
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
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: Colors.blue.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Was this classification correct?',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeRegular,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
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
                  ),
                  icon: Icon(_userConfirmed == true ? Icons.check_circle : Icons.thumb_up),
                  label: const Text('Correct'),
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
                  ),
                  icon: Icon(_userConfirmed == false ? Icons.error : Icons.thumb_down),
                  label: const Text('Incorrect'),
                ),
              ),
            ],
          ),
          if (_showCorrectionOptions) ...[
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              'What should it be?',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _commonCorrections.take(4).map((correction) =>
                _buildCorrectionChip(correction),
              ).toList(),
            ),
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Help us improve classification',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonCorrections.map((correction) =>
                  _buildCorrectionChip(correction),
                ).toList(),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Submit Feedback'),
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            // Privacy note
            Text(
              'Your feedback is anonymous and helps improve the app for everyone.',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionChip(String correction) {
    final isSelected = _selectedCorrection == correction;
    final isCustom = correction == 'Custom correction...';
    
    return GestureDetector(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.white,
              ),
            if (isSelected) const SizedBox(width: 4),
            Text(
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
            ),
          ],
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
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height to 80% of screen
          ),
          child: SingleChildScrollView(
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
      ),
    );
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
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height to 80% of screen
          ),
          child: SingleChildScrollView(
            child: ClassificationFeedbackWidget(
              classification: classification,
              onFeedbackSubmitted: onFeedbackSubmitted,
              showCompactVersion: false,
            ),
          ),
        ),
      ),
    );
  }
}
