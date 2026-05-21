import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/waste_theme.dart';

/// A Material 3 warning / alert card for disposal cautions.
///
/// Used to surface disposal warnings, urgent timeframes, and required PPE
/// from a classification result.
///
/// Example:
/// ```dart
/// DisposalWarningCard(
///   title: 'Hazardous Material',
///   warnings: ['Do not mix with regular waste', 'Use gloves'],
///   severity: WarningSeverity.high,
/// )
/// ```
class DisposalWarningCard extends StatelessWidget {
  const DisposalWarningCard({
    super.key,
    this.title,
    this.warnings = const [],
    this.steps = const [],
    this.urgentMessage,
    this.severity = WarningSeverity.medium,
    this.compact = false,
    this.onTap,
  });

  final String? title;
  final List<String> warnings;
  final List<String> steps;
  final String? urgentMessage;
  final WarningSeverity severity;
  final bool compact;
  final VoidCallback? onTap;

  Color get _color => switch (severity) {
        WarningSeverity.low => AppTheme.infoColor,
        WarningSeverity.medium => AppTheme.warningColor,
        WarningSeverity.high => AppTheme.errorColor,
        WarningSeverity.critical => AppTheme.hazardousWasteColor,
      };

  IconData get _icon => switch (severity) {
        WarningSeverity.low => Icons.info_outline,
        WarningSeverity.medium => Icons.warning_amber,
        WarningSeverity.high => Icons.warning,
        WarningSeverity.critical => Icons.dangerous,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return Semantics(
      label: 'Warning: ${title ?? "disposal warning"}',
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, color),
                if (urgentMessage != null) ...[
                  const SizedBox(height: 10),
                  _buildUrgentCallout(theme, color),
                ],
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...warnings.map((w) => _buildWarningItem(theme, color, w)),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  ...steps.asMap().entries.map(
                        (e) => _buildStepItem(theme, e.key + 1, e.value),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          ),
          child: Icon(_icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title ?? 'Disposal Warning',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCallout(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              urgentMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(ThemeData theme, Color color, String warning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 6, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(ThemeData theme, int index, String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum WarningSeverity { low, medium, high, critical }
