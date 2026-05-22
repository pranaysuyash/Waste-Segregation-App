import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';

/// Displays the provenance and attribution of local policy rules applied
/// to a classification result.
///
/// Shows which authority's rules were used, version info, source, helpline,
/// and whether the result was confidence-gated.
class PolicyProvenanceCard extends StatelessWidget {
  const PolicyProvenanceCard({
    super.key,
    required this.decision,
  });

  final LocalPolicyDecision decision;

  @override
  Widget build(BuildContext context) {
    if (!decision.policyApplied) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Policy Source',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (decision.confidenceGated)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Low confidence',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade800,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _provenanceRow(context, 'Authority', decision.authorityName ?? '—'),
            if (decision.guidelinesVersion != null)
              _provenanceRow(
                  context, 'Version', decision.guidelinesVersion!),
            if (decision.helpline != null && decision.helpline!.isNotEmpty)
              _provenanceRow(context, 'Helpline', decision.helpline!),
            if (decision.complianceStatus != null)
              _provenanceRow(
                  context, 'Compliance', _complianceLabel(decision.complianceStatus!, cs)),
            if (decision.lastVerified != null)
              _provenanceRow(context, 'Verified', decision.lastVerified!),
            if (decision.rulePackId != null)
              _provenanceRow(context, 'Rule Pack', decision.rulePackId!),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _showSourceDetail(context),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Why this matters',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _provenanceRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _complianceLabel(String status, ColorScheme cs) {
    switch (status) {
      case 'compliant':
        return '✅ Compliant';
      case 'requires_attention':
        return '⚠️ Needs attention';
      case 'violation':
        return '🚫 Violation';
      default:
        return status;
    }
  }

  void _showSourceDetail(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('About Policy Rules'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Every disposal instruction comes from a versioned policy pack '
                'maintained for your city or region. These rules are deterministic '
                '— they are checked against the official municipal guidelines, not '
                'generated by AI.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Why this matters:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Safety-critical rules (hazardous, medical) always apply\n'
                '• Low-confidence ML results show softer warnings\n'
                '• Every rule has a version ID for auditability\n'
                '• Society-specific overrides are layered on top',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
