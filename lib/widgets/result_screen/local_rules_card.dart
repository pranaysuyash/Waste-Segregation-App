import 'package:flutter/material.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../responsive_text.dart';

/// A modular component displaying local regulations and compliance guidelines (e.g. BBMP Bangalore rules).
class LocalRulesCard extends StatelessWidget {
  const LocalRulesCard({
    super.key,
    required this.classification,
  });

  final WasteClassification classification;

  static bool hasLocalRules(WasteClassification c) {
    return (c.localRegulations?.isNotEmpty == true) ||
        (c.bbmpComplianceStatus?.isNotEmpty == true) ||
        (c.localGuidelinesReference?.isNotEmpty == true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bbmp = classification.bbmpComplianceStatus;
    final guideline = classification.localGuidelinesReference;
    final regs = classification.localRegulations ?? const <String, String>{};

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Local Rules & Compliance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (bbmp != null && bbmp.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRuleRow(context, 'Compliance', bbmp),
            ],
            if (guideline != null && guideline.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRuleRow(context, 'Guideline', guideline),
            ],
            if (regs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...regs.entries.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRuleRow(context, e.key, e.value),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              ReadMoreText(
                value,
                trimLines: 3,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
