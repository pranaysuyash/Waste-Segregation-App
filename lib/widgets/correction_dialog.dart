import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/result_pipeline.dart';
import '../utils/error_handler.dart';

/// Correction dialog for the Riverpod-based result screen.
///
/// Provides thumbs-up (confirm) / thumbs-down (correct) feedback, category
/// correction chips, custom correction input, and optional notes.
/// All business logic delegates to [ResultPipeline.submitFeedback].
class CorrectionDialog extends ConsumerStatefulWidget {
  const CorrectionDialog({
    super.key,
    required this.classification,
  });

  final WasteClassification classification;

  @override
  ConsumerState<CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<CorrectionDialog> {
  bool? _userConfirmed;
  String? _selectedCorrection;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _validationError;

  static const List<String> _commonCorrections = [
    'Wet Waste',
    'Dry Waste',
    'Hazardous Waste',
    'Medical Waste',
    'Non-Waste',
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _materialController.dispose();
    _customController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? get _resolvedCategory {
    if (_userConfirmed == true) return null;
    if (_selectedCorrection == null) return null;
    if (_selectedCorrection == 'Custom...') {
      final trimmed = _customController.text.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }
    return _selectedCorrection;
  }

  String? get _resolvedItemName {
    if (_userConfirmed == true) return null;
    final trimmed = _itemNameController.text.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  String? get _resolvedMaterial {
    if (_userConfirmed == true) return null;
    final trimmed = _materialController.text.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  bool get _hasCorrectionPayload {
    if (_userConfirmed != false) return true;
    final hasCategory = _resolvedCategory != null;
    final hasItemName = _resolvedItemName != null;
    final hasMaterial = _resolvedMaterial != null;
    final hasNotes = _notesController.text.trim().isNotEmpty;
    return hasCategory || hasItemName || hasMaterial || hasNotes;
  }

  bool get _canSubmit {
    if (_isSubmitting || _userConfirmed == null) return false;
    if (_userConfirmed == false) return _hasCorrectionPayload;
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_userConfirmed == null) return;
    if (!_hasCorrectionPayload) {
      setState(() {
        _validationError =
            'Add at least one correction detail when marking this as wrong.';
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isSubmitting = true;
    });

    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      final feedbackResult = await pipeline.submitFeedback(
        classification: widget.classification,
        userConfirmed: _userConfirmed!,
        userCorrection: _selectedCorrection,
        userNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        userSuggestedCategory: _resolvedCategory,
        userSuggestedItemName: _resolvedItemName,
        userSuggestedMaterial: _resolvedMaterial,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        final message = feedbackResult.wasDuplicate
            ? 'Already recorded!'
            : _userConfirmed!
                ? 'Thanks for confirming! +${feedbackResult.pointsAwarded} points'
                : 'Correction saved! +${feedbackResult.pointsAwarded} points';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                feedbackResult.wasDuplicate ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Is this classification correct?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.classification.displayItemLabel} → ${widget.classification.displayCategoryLabel}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Thumbs up / thumbs down
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeedbackButton(
                    icon: Icons.thumb_up,
                    label: 'Correct',
                    selected: _userConfirmed == true,
                    color: Colors.green,
                    onTap: () => setState(() {
                      _userConfirmed = true;
                      _selectedCorrection = null;
                      _validationError = null;
                    }),
                  ),
                  const SizedBox(width: 24),
                  _FeedbackButton(
                    icon: Icons.thumb_down,
                    label: 'Wrong',
                    selected: _userConfirmed == false,
                    color: Colors.red,
                    onTap: () => setState(() {
                      _userConfirmed = false;
                      _validationError = null;
                    }),
                  ),
                ],
              ),

              // Correction options (only when user says wrong)
              if (_userConfirmed == false) ...[
                const SizedBox(height: 24),
                Text(
                  'What should it be?',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonCorrections.map((correction) {
                    final isSelected = _selectedCorrection == correction;
                    return ChoiceChip(
                      label: Text(correction),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCorrection = selected ? correction : null;
                          if (_selectedCorrection == 'Custom...') {
                            _customController.clear();
                          }
                          _validationError = null;
                        });
                      },
                    );
                  }).toList()
                    ..add(
                      ChoiceChip(
                        label: const Text('Custom...'),
                        selected: _selectedCorrection == 'Custom...',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCorrection = selected ? 'Custom...' : null;
                            _validationError = null;
                          });
                        },
                      ),
                    ),
                ),
                if (_selectedCorrection == 'Custom...') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customController,
                    onChanged: (_) => setState(() => _validationError = null),
                    decoration: const InputDecoration(
                      labelText: 'Enter correct category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _itemNameController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: const InputDecoration(
                    labelText: 'Correct item name (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _materialController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: const InputDecoration(
                    labelText: 'Correct material (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],

              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _validationError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              FilledButton.icon(
                key: const Key('correction_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_userConfirmed == true ? Icons.check : Icons.send),
                label: Text(_isSubmitting
                    ? 'Submitting...'
                    : _userConfirmed == true
                        ? 'Confirm'
                        : 'Submit Correction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
