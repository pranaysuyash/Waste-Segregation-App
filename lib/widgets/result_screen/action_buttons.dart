import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Action buttons for the result screen with proper state management
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.isSaved,
    required this.isAutoSaving,
    required this.onSave,
    required this.onShare,
  });
  final bool isSaved;
  final bool isAutoSaving;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isAutoSaving ? null : (isSaved ? onShare : onSave),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAutoSaving
                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                  : (isSaved ? AppTheme.primaryColor : Colors.green),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              elevation: isAutoSaving ? 0 : 2,
            ),
            icon: Icon(
              isAutoSaving ? Icons.hourglass_empty : (isSaved ? Icons.share : Icons.save),
            ),
            label: Text(
              isAutoSaving ? 'Saving...' : (isSaved ? 'Share' : 'Save'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.paddingRegular),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
            ),
            icon: const Icon(Icons.share),
            label: const Text(
              'Share',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
