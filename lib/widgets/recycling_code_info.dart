import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recycling_code.dart';
import '../utils/constants.dart';

// 1. Data Model & Structure
const unknownCode = RecyclingCode(
  id: '?',
  name: 'Unknown Code',
  examples: 'Could not find information for this code.',
  recyclable: 'Unknown',
);

final Map<String, RecyclingCode> recyclingCodes = {
  '1': const RecyclingCode(
    id: '1',
    name: 'PET (Polyethylene Terephthalate)',
    examples: 'Water bottles, soft drink bottles, food containers',
    recyclable: 'Yes - widely recyclable',
  ),
  '2': const RecyclingCode(
    id: '2',
    name: 'HDPE (High-Density Polyethylene)',
    examples: 'Milk jugs, detergent bottles, yogurt containers',
    recyclable: 'Yes - widely recyclable',
  ),
  '3': const RecyclingCode(
    id: '3',
    name: 'PVC (Polyvinyl Chloride)',
    examples: 'Food wrap, bottles for toiletries, medical equipment',
    recyclable: 'Limited - check local facilities',
  ),
  '4': const RecyclingCode(
    id: '4',
    name: 'LDPE (Low-Density Polyethylene)',
    examples: 'Shopping bags, food wraps, squeeze bottles',
    recyclable: 'Limited - some stores accept bags',
  ),
  '5': const RecyclingCode(
    id: '5',
    name: 'PP (Polypropylene)',
    examples: 'Yogurt containers, bottle caps, straws',
    recyclable: 'Growing acceptance - check locally',
  ),
  '6': const RecyclingCode(
    id: '6',
    name: 'PS (Polystyrene)',
    examples: 'Disposable cups, takeout containers, packing peanuts',
    recyclable: 'Rarely accepted - avoid if possible',
  ),
  '7': const RecyclingCode(
    id: '7',
    name: 'Other (Mixed plastics)',
    examples: 'Water cooler bottles, some food containers',
    recyclable: 'Varies - check with manufacturer',
  ),
};

/// Displays information about a recycling code (1-7) with description.
class RecyclingCodeInfoCard extends StatefulWidget {
  const RecyclingCodeInfoCard({super.key, required this.code});
  final String code;

  @override
  State<RecyclingCodeInfoCard> createState() => _RecyclingCodeInfoCardState();
}

class _RecyclingCodeInfoCardState extends State<RecyclingCodeInfoCard> {
  bool _isExpanded = false;

  Color _getRecyclabilityColor(String recyclableText, BuildContext context) {
    final text = recyclableText.toLowerCase();
    if (text.contains('yes') || text.contains('widely')) {
      return Colors.green;
    } else if (text.contains('limited') || text.contains('growing')) {
      return Colors.orange;
    } else if (text.contains('rarely') || text.contains('avoid')) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final codeInfo = recyclingCodes[widget.code] ?? unknownCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getRecyclabilityColor(codeInfo.recyclable, context);

    if (codeInfo == unknownCode) {
      return Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          child: Row(
            children: [
              Icon(Icons.warning, color: colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unknown recycling code: ${widget.code}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      color: statusColor.withAlphaFraction(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CodeCircle(code: codeInfo.id, borderColor: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TODO(i18n): Localize plastic name
                      Text(
                        codeInfo.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_isExpanded) ...[
                        const SizedBox(height: 4),
                        // TODO(i18n): Localize examples text
                        Text(
                          codeInfo.examples,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
                Semantics(
                  // TODO(i18n): Localize semantics label
                  label: 'Show more details for code ${widget.code}',
                  button: true,
                  child: IconButton(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.expand_more),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints:
                    _isExpanded ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.paddingRegular),
                  child: Column(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: codeInfo.examples));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              // TODO(i18n): Localize SnackBar content
                              content: Text('Examples copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child:
                            InfoRow(label: 'Examples', text: codeInfo.examples),
                      ),
                      const SizedBox(height: 8),
                      InfoRow(
                        label: 'Recycling',
                        text: codeInfo.recyclable,
                        highlightColor: statusColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Extracted Sub-widgets
class CodeCircle extends StatelessWidget {
  const CodeCircle(
      {super.key, required this.code, required this.borderColor});
  final String code;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.text,
    this.highlightColor,
  });
  final String label;
  final String text;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            // TODO(i18n): Localize label
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: highlightColor,
              fontWeight: highlightColor != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}