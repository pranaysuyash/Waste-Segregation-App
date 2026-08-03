import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/local_policy_engine.dart';

/// Displays the provenance and attribution of local policy rules applied
/// to a classification result.
///
/// Shows which authority's rules were used, version info, source, helpline,
/// and whether the result was confidence-gated.
class PolicyProvenanceCard extends StatelessWidget {
  const PolicyProvenanceCard({super.key, required this.decision});

  final LocalPolicyDecision decision;

  @override
  Widget build(BuildContext context) {
    if (!decision.policyApplied && decision.pluginId == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasPolicyMetadata = decision.pluginId != null ||
        decision.rulePackId != null ||
        decision.localName != null;
    final confidenceState = decision.confidenceState ??
        (decision.policyApplied ? 'full' : 'not_applied');

    final confidenceStateLabel = {
          'not_applied': hasPolicyMetadata
              ? 'Policy checks used without local policy pack binding'
              : 'No local policy pack available',
          'warning_only': 'Confidence-gated warning checks',
          'full_softened': 'Confidence-gated full checks',
          'full': 'Full policy checks',
        }[confidenceState] ??
        confidenceState;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    confidenceStateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _provenanceRow(context, 'Authority', decision.authorityName ?? '—'),
            if (decision.authorityStatus.isNotEmpty)
              _provenanceRow(
                context,
                'Authority Status',
                _titleCaseStatus(decision.authorityStatus),
              ),
            if (decision.sourceStatus.isNotEmpty)
              _provenanceRow(
                context,
                'Source Status',
                _titleCaseStatus(decision.sourceStatus),
              ),
            if (decision.technicalStatus.isNotEmpty)
              _provenanceRow(
                context,
                'Technical Status',
                _titleCaseStatus(decision.technicalStatus),
              ),
            if (decision.localName != null)
              _provenanceRow(context, 'Source', decision.localName!),
            if (decision.guidelinesVersion != null)
              _provenanceRow(context, 'Version', decision.guidelinesVersion!),
            if (decision.helpline != null && decision.helpline!.isNotEmpty)
              _provenanceRow(context, 'Helpline', decision.helpline!),
            if (decision.complianceStatus != null)
              _provenanceRow(
                context,
                'Compliance',
                _complianceLabel(decision.complianceStatus!, cs),
              ),
            if (decision.trustTier != null)
              _provenanceRow(context, 'Trust', decision.trustTier!),
            if (decision.sourceTitle != null)
              _provenanceRow(context, 'Source', decision.sourceTitle!),
            if (decision.lastVerified != null)
              _provenanceRow(context, 'Verified', decision.lastVerified!),
            if (decision.rulePackId != null)
              _provenanceRow(context, 'Rule Pack', decision.rulePackId!),
            if (decision.nextReviewDue != null)
              _provenanceRow(context, 'Review', decision.nextReviewDue!),
            if (decision.societyName != null)
              _provenanceRow(context, 'Society', decision.societyName!),
            if (decision.societyOverrides.isNotEmpty)
              _provenanceRow(
                context,
                'Society Overrides',
                decision.societyOverrides.join(', '),
              ),
            if (decision.societyConflicts.isNotEmpty)
              _provenanceRow(
                context,
                'Conflicts',
                decision.societyConflicts.join(' | '),
              ),
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
                      'What this means',
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
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
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
                'This result combines classifier output with local policy checks. '
                'Policy checks come from versioned packs and are executed '
                'independently from the model to show what was enforced.',
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
                '• Safety-critical categories are always enforced and can never be '
                'softened away.\n'
                '• Low-confidence classification can convert non-safety checks into '
                'warnings.\n'
                '• Rule versioning and verification metadata are shown for auditability.\n'
                '• Rule-source trust fields show whether the policy data is tested, '
                'approved, or still provisional.',
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

  String _titleCaseStatus(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return normalized;

    return normalized
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
