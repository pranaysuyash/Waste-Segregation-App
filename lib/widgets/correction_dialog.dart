import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/result_pipeline.dart';
import '../utils/error_handler.dart';

/// Result returned by [CorrectionDialog] when it closes.
///
/// Carries the user's confirmation or correction details so the caller
/// can trigger optional re-analysis via AiService.handleUserCorrection().
class CorrectionResult {
  const CorrectionResult({
    required this.userConfirmed,
    this.userSuggestedCategory,
    this.userSuggestedItemName,
    this.userSuggestedMaterial,
    this.userNotes,
    this.barcode,
  });

  /// True = user confirmed the classification; False = user said it was wrong.
  final bool userConfirmed;

  final String? userSuggestedCategory;
  final String? userSuggestedItemName;
  final String? userSuggestedMaterial;
  final String? userNotes;
  final String? barcode;

  /// Whether the user provided actual correction data (as opposed to just
  /// confirming). Only meaningful when [userConfirmed] is false.
  bool get hasCorrectionData =>
      userSuggestedCategory != null ||
      userSuggestedItemName != null ||
      userSuggestedMaterial != null ||
      (userNotes?.trim().isNotEmpty == true) ||
      (barcode?.trim().isNotEmpty == true);
}

/// Correction dialog for the Riverpod-based result screen.
///
/// Provides thumbs-up (confirm) / thumbs-down (correct) feedback, category
/// correction chips, custom correction input, and optional notes.
/// All business logic delegates to [ResultPipeline.submitFeedback].
///
/// Returns a [CorrectionResult] when popped, or null if dismissed.
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
  final TextEditingController _barcodeController = TextEditingController();
  bool _isSubmitting = false;
  String? _validationError;
  bool _hasTriedSubmit = false;

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
    _barcodeController.dispose();
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

  /// Whether the user has provided enough input to submit.
  ///
  /// - When confirmed correct (true): always has a payload (the confirmation).
  /// - When not yet selected (null): no payload.
  /// - When marked wrong (false): must provide at least one correction detail.
  String? get _resolvedBarcode {
    final trimmed = _barcodeController.text.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  bool get _hasCorrectionPayload {
    if (_userConfirmed == true) return true;
    if (_userConfirmed == null) return false;
    // _userConfirmed == false — check for at least one correction detail
    return _resolvedCategory != null ||
        _resolvedItemName != null ||
        _resolvedMaterial != null ||
        _notesController.text.trim().isNotEmpty ||
        _resolvedBarcode != null;
  }

  bool get _canSubmit {
    if (_isSubmitting || _userConfirmed == null) return false;
    if (_userConfirmed == false) {
      if (!_hasCorrectionPayload) return false;
      // Require at least one meaningful field beyond notes (barcode counts)
      final hasMeaningfulCorrection =
          _resolvedCategory != null ||
          _resolvedItemName != null ||
          _resolvedMaterial != null ||
          _resolvedBarcode != null;
      return hasMeaningfulCorrection;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_userConfirmed == null) return;

    _hasTriedSubmit = true;

    if (!_hasCorrectionPayload) {
      setState(() {
        _validationError =
            'Add at least one correction detail when marking this as wrong.';
      });
      return;
    }

    if (!_canSubmit) {
      setState(() {
        _validationError =
            'Provide a category, item name, or material.';
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
        barcode: _resolvedBarcode,
      );

      if (mounted) {
        Navigator.of(context).pop(CorrectionResult(
          userConfirmed: _userConfirmed!,
          userSuggestedCategory: _resolvedCategory,
          userSuggestedItemName: _resolvedItemName,
          userSuggestedMaterial: _resolvedMaterial,
          userNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          barcode: _resolvedBarcode,
        ));
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
                const SizedBox(height: 4),
                Text(
                  'Select a category or provide details below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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

                // Inline hint when no correction data is entered
                if (_userConfirmed == false &&
                    !_hasCorrectionPayload &&
                    _hasTriedSubmit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Provide at least a category, item name, or material.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                TextField(
                  controller: _itemNameController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: InputDecoration(
                    labelText: 'Correct item name',
                    hintText: 'e.g. Plastic Bottle',
                    border: const OutlineInputBorder(),
                    helperText: 'Required if no category is selected',
                    helperStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _materialController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: InputDecoration(
                    labelText: 'Correct material',
                    hintText: 'e.g. PET, Glass, Cardboard',
                    border: const OutlineInputBorder(),
                    helperText: 'Optional if category is set',
                    helperStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Why was this wrong?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _barcodeController,
                  onChanged: (_) => setState(() => _validationError = null),
                  decoration: InputDecoration(
                    labelText: 'Barcode / Product code',
                    hintText: 'e.g. 8901234567890',
                    border: const OutlineInputBorder(),
                    helperText: 'Product lookup coming later',
                    helperStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    prefixIcon: const Icon(Icons.qr_code),
                  ),
                  keyboardType: TextInputType.number,
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
