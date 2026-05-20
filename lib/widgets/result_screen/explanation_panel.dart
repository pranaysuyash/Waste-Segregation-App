import 'package:flutter/material.dart';
import '../../models/waste_classification.dart';
import '../responsive_text.dart';

/// An expandable “Why this classification?” panel for the result screen.
///
/// Shows:
/// 1. Visual clues used by the AI (`visualFeatures`).
/// 2. Material / category reasoning (`explanation`, `subCategory`, `materials`).
/// 3. Alternative classifications (`alternatives`) — “Could also be…”.
/// 4. Confidence / uncertainty copy.
/// 5. Local disposal reason (`localGuidelinesReference`) if available.
///
/// Behaviour:
/// * Normal confident result → collapsed by default, compact styling.
/// * Low confidence (`< 0.7`) or `clarificationNeeded` → expanded by default,
///   tinted header to draw attention.
/// * Missing fields are omitted gracefully — no placeholders or crashes.
class ExplanationPanel extends StatefulWidget {
  const ExplanationPanel({
    super.key,
    required this.classification,
  });

  final WasteClassification classification;

  @override
  State<ExplanationPanel> createState() => _ExplanationPanelState();
}

class _ExplanationPanelState extends State<ExplanationPanel>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  static const double _lowConfidenceThreshold = 0.7;

  @override
  void initState() {
    super.initState();
    _expanded = _shouldExpandByDefault;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldExpandByDefault {
    final c = widget.classification;
    final confidence = c.confidence ?? 1.0;
    return confidence < _lowConfidenceThreshold || (c.clarificationNeeded == true);
  }

  bool get _isLowConfidence {
    final confidence = widget.classification.confidence ?? 1.0;
    return confidence < _lowConfidenceThreshold;
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = widget.classification;

    final hasContent = _hasAnyContent(c);
    if (!hasContent) return const SizedBox.shrink();

    final headerColor = _isLowConfidence
        ? cs.secondaryContainer.withValues(alpha: 0.45)
        : cs.surfaceContainerHighest;

    return Card(
      elevation: 0,
      color: headerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: _isLowConfidence ? cs.secondary : cs.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why this classification?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (!_expanded) ...[
                          const SizedBox(height: 4),
                          _buildCompactSubtitle(theme, cs),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded body
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _controller.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // 1. Visual clues
                  if (c.visualFeatures.isNotEmpty)
                    _buildVisualClues(context, c.visualFeatures),

                  // 2. Material / category reasoning
                  _buildReasoning(context, c),

                  // 3. Alternative classifications
                  if (c.alternatives.isNotEmpty)
                    _buildAlternatives(context, c.alternatives),

                  // 4. Confidence / uncertainty
                  _buildConfidenceBlock(context, c),

                  // 5. Local disposal reason
                  if (c.localGuidelinesReference != null &&
                      c.localGuidelinesReference!.isNotEmpty)
                    _buildLocalGuideline(context, c.localGuidelinesReference!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnyContent(WasteClassification c) {
    return c.visualFeatures.isNotEmpty ||
        c.explanation.isNotEmpty ||
        c.alternatives.isNotEmpty ||
        c.localGuidelinesReference != null && c.localGuidelinesReference!.isNotEmpty;
  }

  Widget _buildCompactSubtitle(ThemeData theme, ColorScheme cs) {
    final c = widget.classification;
    final confidence = c.confidence ?? 0.0;
    final pct = (confidence * 100).toInt();

    String text;
    if (_isLowConfidence) {
      text = 'Low confidence ($pct%) — tap to see why';
    } else if (c.alternatives.isNotEmpty) {
      text = '${c.alternatives.length} alternative suggestion${c.alternatives.length == 1 ? '' : 's'} · $pct% confident';
    } else {
      text = '$pct% confident · tap for details';
    }

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildVisualClues(BuildContext context, List<String> features) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, Icons.visibility, 'Visual clues'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                feature,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReasoning(BuildContext context, WasteClassification c) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final materials = c.normalizedMaterials;
    final subcategory = c.normalizedSubcategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, Icons.category, 'Reasoning'),
        const SizedBox(height: 8),
        if (subcategory != null && subcategory.isNotEmpty)
          _buildBulletRow(
            context,
            'Identified as $subcategory',
            Icons.label_outline,
          ),
        if (materials.isNotEmpty)
          _buildBulletRow(
            context,
            'Made of ${materials.take(3).join(', ')}',
            Icons.layers_outlined,
          ),
        if (c.explanation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ReadMoreText(
              c.explanation,
              trimLines: 3,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlternatives(
    BuildContext context,
    List<AlternativeClassification> alternatives,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, Icons.compare_arrows, 'Could also be…'),
        const SizedBox(height: 8),
        ...alternatives.take(3).map((alt) {
          final pct = (alt.confidence * 100).toInt();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alt.category +
                              (alt.subcategory != null && alt.subcategory!.isNotEmpty
                                  ? ' — ${alt.subcategory}'
                                  : ''),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (pct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pct%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ReadMoreText(
                    alt.reason,
                    trimLines: 2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfidenceBlock(BuildContext context, WasteClassification c) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confidence = c.confidence ?? 0.0;
    final pct = (confidence * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, Icons.speed, 'Confidence'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
                backgroundColor: cs.surfaceContainerHighest,
                color: _confidenceColor(confidence, cs),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLowConfidence)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: cs.secondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The AI is uncertain about this classification. '
                    'Consider reviewing the alternatives or providing a clearer image.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (confidence >= 0.9)
          Text(
            'High confidence — the AI is very sure about this classification.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        else
          Text(
            'Moderate confidence — review the details if unsure.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocalGuideline(BuildContext context, String guideline) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, Icons.location_on, 'Local guideline'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.gavel,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReadMoreText(
                guideline,
                trimLines: 3,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletRow(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: cs.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double confidence, ColorScheme cs) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.amber;
    return cs.secondary;
  }
}
