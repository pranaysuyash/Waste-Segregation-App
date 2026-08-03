import 'package:flutter/material.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

/// Presents the single next action a user should take after a scan.
///
/// The card deliberately distinguishes local policy-backed guidance from
/// general disposal guidance. It must not imply that a generic AI result is a
/// local rule, especially when confidence or taxonomy resolution is missing.
class DisposalDecisionCard extends StatelessWidget {
  const DisposalDecisionCard({
    super.key,
    required this.classification,
    this.onCorrect,
  });

  final WasteClassification classification;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decision = _decisionFor(classification);

    return Card(
      elevation: 0,
      color: decision.needsVerification
          ? colors.secondaryContainer.withValues(alpha: 0.5)
          : colors.primaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  decision.needsVerification
                      ? Icons.fact_check_outlined
                      : Icons.recycling_outlined,
                  color: decision.needsVerification
                      ? colors.secondary
                      : colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete this item now',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(decision: decision),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              decision.action,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              decision.context,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (decision.firstStep != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.arrow_forward_rounded,
                label: 'First step',
                value: decision.firstStep!,
              ),
            ],
            if (decision.collectionWindow != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Collection window',
                value: decision.collectionWindow!,
              ),
            ],
            if (decision.collectionNotes != null &&
                decision.collectionNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.event_note_outlined,
                label: 'Collection notes',
                value: decision.collectionNotes!,
              ),
            ],
            const SizedBox(height: 12),
            _DetailRow(
              icon: decision.hasLocalPolicy
                  ? Icons.location_on_outlined
                  : Icons.public_outlined,
              label: decision.hasLocalPolicy ? 'Local basis' : 'Guidance basis',
              value: decision.source,
            ),
            if (decision.authorityStatus != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.verified_user_outlined,
                label: 'Authority status',
                value: decision.authorityStatus!,
              ),
            ],
            if (decision.sourceStatus != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.source_outlined,
                label: 'Source status',
                value: decision.sourceStatus!,
              ),
            ],
            if (decision.governanceStage != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.track_changes_outlined,
                label: 'Policy governance',
                value: decision.governanceStage!,
              ),
            ],
            if (decision.needsVerification) ...[
              const SizedBox(height: 12),
              Text(
                decision.caution,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  height: 1.35,
                ),
              ),
            ],
            if (onCorrect != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onCorrect,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Correct this result'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _DisposalDecision _decisionFor(WasteClassification classification) {
    final regulations =
        classification.localRegulations ?? const <String, String>{};
    final confidence = classification.confidence ?? 0.0;
    final isHighRiskAction = classification.requiresSpecialDisposal == true ||
        classification.riskLevel?.toLowerCase().contains('high') == true ||
        classification.category.toLowerCase() == 'hazardous waste' ||
        classification.category.toLowerCase() == 'medical waste';
    final taxonomyUnavailable =
        classification.taxonomySource == 'taxonomy_unavailable' ||
            classification.taxonomyMethod == 'asset_missing';
    final needsVerification = classification.clarificationNeeded == true ||
        confidence < 0.7 ||
        taxonomyUnavailable;
    final hasLocalPolicy =
        regulations['policy_rule_pack_id']?.isNotEmpty == true ||
            classification.localGuidelinesVersion?.isNotEmpty == true ||
            classification.localGuidelinesReference?.isNotEmpty == true;

    final action = classification.disposalInstructions.primaryMethod.trim();
    final firstStep = classification.disposalInstructions.steps
        .map((step) => step.trim())
        .firstWhere((step) => step.isNotEmpty, orElse: () => '');
    final authority =
        regulations['policy_local_name'] ?? regulations['policy_source_title'];
    final source = hasLocalPolicy
        ? (authority?.isNotEmpty == true ? authority! : classification.region)
        : 'General disposal guidance';
    final collectionWindow = _formatCollectionWindow(regulations);
    final collectionNotes = regulations['collection_notes']?.trim();
    final authorityStatus = _titleCaseStatus(
      regulations['policy_authority_status'],
    );
    final sourceStatus = _titleCaseStatus(
      regulations['policy_source_status'],
    );
    final governanceStage = regulations['policy_governance_stage']?.trim();

    final caution = isHighRiskAction || taxonomyUnavailable || confidence < 0.6
        ? 'High-risk or uncertain item: verify with local disposal rules before handoff.'
        : confidence < 0.7 || classification.clarificationNeeded == true
            ? 'The scan is uncertain. Confirm the item or correct the result before acting.'
            : 'No local rule pack was applied. Confirm local collection rules if this item is unusual.';

    return _DisposalDecision(
      action: action.isEmpty ? 'Check local disposal guidance' : action,
      context: hasLocalPolicy
          ? 'For ${classification.region}, apply local rule-backed guidance.'
          : 'For ${classification.region}, using general guidance only.',
      firstStep: firstStep.isEmpty ? null : firstStep,
      collectionWindow: collectionWindow,
      collectionNotes: collectionNotes,
      source: source,
      authorityStatus: authorityStatus,
      sourceStatus: sourceStatus,
      governanceStage: governanceStage,
      hasLocalPolicy: hasLocalPolicy,
      needsVerification:
          needsVerification || !hasLocalPolicy || isHighRiskAction,
      caution: caution,
    );
  }

  static String? _formatCollectionWindow(Map<String, String> regulations) {
    final frequency = regulations['collection_frequency']?.trim();
    final timeWindow = regulations['collection_time_window']?.trim();
    final parts = <String>[];
    if (frequency != null && frequency.isNotEmpty) {
      parts.add('frequency: ${_humanizeFrequency(frequency)}');
    }
    if (timeWindow != null && timeWindow.isNotEmpty) {
      parts.add('time: $timeWindow');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String _humanizeFrequency(String value) {
    switch (value.toLowerCase().trim()) {
      case 'daily':
        return 'Daily';
      case 'alternate_days':
      case 'alternate':
        return 'Alternate days';
      case 'twice_weekly':
      case 'twice-a-week':
      case 'two_times_week':
        return 'Twice weekly';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return value;
    }
  }

  static String? _titleCaseStatus(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    return trimmed
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.decision});

  final _DisposalDecision decision;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = decision.needsVerification ? 'Review first' : 'Actionable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: decision.needsVerification
            ? colors.secondary.withValues(alpha: 0.15)
            : colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: decision.needsVerification
                  ? colors.onSecondaryContainer
                  : colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 4,
            children: [
              Text(
                '$label:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisposalDecision {
  const _DisposalDecision({
    required this.action,
    required this.context,
    required this.firstStep,
    required this.collectionWindow,
    required this.collectionNotes,
    required this.source,
    required this.authorityStatus,
    required this.sourceStatus,
    required this.governanceStage,
    required this.hasLocalPolicy,
    required this.needsVerification,
    required this.caution,
  });

  final String action;
  final String context;
  final String? firstStep;
  final String? collectionWindow;
  final String? collectionNotes;
  final String source;
  final String? authorityStatus;
  final String? sourceStatus;
  final String? governanceStage;
  final bool hasLocalPolicy;
  final bool needsVerification;
  final String caution;
}
