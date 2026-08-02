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
                    'Recommended next step',
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
            const SizedBox(height: 12),
            _DetailRow(
              icon: decision.hasLocalPolicy
                  ? Icons.location_on_outlined
                  : Icons.public_outlined,
              label: decision.hasLocalPolicy ? 'Local basis' : 'Guidance basis',
              value: decision.source,
            ),
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

    final caution = taxonomyUnavailable
        ? 'The material taxonomy could not be resolved. Confirm this action with your local waste authority before disposal.'
        : confidence < 0.7 || classification.clarificationNeeded == true
            ? 'The scan is uncertain. Confirm the item or correct the result before acting on this recommendation.'
            : 'No local rule pack was applied. Confirm local collection rules if this item is unusual or hazardous.';

    return _DisposalDecision(
      action: action.isEmpty ? 'Check local disposal guidance' : action,
      context: hasLocalPolicy
          ? 'For ${classification.region}, using the available local rule context.'
          : 'For ${classification.region}, using general guidance only.',
      firstStep: firstStep.isEmpty ? null : firstStep,
      source: source,
      hasLocalPolicy: hasLocalPolicy,
      needsVerification: needsVerification || !hasLocalPolicy,
      caution: caution,
    );
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
    required this.source,
    required this.hasLocalPolicy,
    required this.needsVerification,
    required this.caution,
  });

  final String action;
  final String context;
  final String? firstStep;
  final String source;
  final bool hasLocalPolicy;
  final bool needsVerification;
  final String caution;
}
