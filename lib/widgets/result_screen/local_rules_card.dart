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
    final regs = _displayRegulations(
      classification.localRegulations ?? const <String, String>{},
    );

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
              ...regs.entries.take(4).map(
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

  Map<String, String> _displayRegulations(Map<String, String> raw) {
    if (raw.isEmpty) return raw;

    const labelMap = <String, String>{
      'policy_rule_pack_id': 'Policy Pack',
      'policy_plugin_id': 'Policy Plugin',
      'policy_compliance_status': 'Policy Status',
      'policy_warning_count': 'Policy Warnings',
      'policy_violation_count': 'Policy Violations',
      'policy_recommendations': 'Policy Recommendations',
      'policy_evaluated_at': 'Policy Evaluated At',
      'color_coding': 'Color Coding',
      'collection_frequency': 'Collection Frequency',
      'composting_requirement': 'Composting Requirement',
      'penalty_non_compliance': 'Penalty',
      'cleaning_requirement': 'Cleaning Requirement',
      'segregation_requirement': 'Segregation Requirement',
      'contact_required': 'Contact Requirement',
      'storage_requirement': 'Storage Requirement',
    };

    final preferredOrder = <String>[
      'policy_compliance_status',
      'policy_violation_count',
      'policy_warning_count',
      'policy_recommendations',
      'policy_rule_pack_id',
      'policy_evaluated_at',
      'color_coding',
      'collection_frequency',
      'composting_requirement',
      'segregation_requirement',
      'cleaning_requirement',
      'contact_required',
      'storage_requirement',
      'penalty_non_compliance',
    ];

    final ordered = <MapEntry<String, String>>[];
    final consumed = <String>{};

    for (final key in preferredOrder) {
      final value = raw[key];
      if (value == null || value.trim().isEmpty) continue;
      consumed.add(key);
      ordered.add(MapEntry(labelMap[key] ?? _humanizeKey(key), value));
    }

    for (final entry in raw.entries) {
      if (consumed.contains(entry.key) || entry.value.trim().isEmpty) continue;
      ordered.add(MapEntry(
          labelMap[entry.key] ?? _humanizeKey(entry.key), entry.value.trim()));
    }

    return Map<String, String>.fromEntries(ordered);
  }

  String _humanizeKey(String key) {
    final words = key
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}');
    return words.join(' ');
  }
}
