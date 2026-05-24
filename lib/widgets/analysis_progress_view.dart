import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/classification_state.dart';
import '../services/visual_feedback_service.dart';
import '../utils/constants.dart';
import '../utils/animation_system.dart';

/// Progress/status view rendered during image analysis.
///
/// Driven entirely by [ClassificationState] — the canonical lifecycle enum.
/// Every title, icon, color, and action button is derived from a single
/// state value, replacing the old boolean/flag approach.
class AnalysisProgressView extends StatefulWidget {
  const AnalysisProgressView({
    super.key,
    required this.state,
    this.imageName,
    this.offlineQueueCount,
    this.queuePosition,
    this.localRuleChipText,
    this.statusMessage,
    this.errorMessage,
    this.confidenceText,
    this.onRetry,
    this.onCancel,
    this.onContinue,
    this.resultCategoryColor,
  });

  final ClassificationState state;
  final String? imageName;
  final int? offlineQueueCount;
  final int? queuePosition;
  final String? localRuleChipText;
  final String? statusMessage;
  final String? errorMessage;
  final String? confidenceText;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onContinue;
  final Color? resultCategoryColor;

  bool get showRetry => state == ClassificationState.failedRetryable;

  bool get showCancel {
    switch (state) {
      case ClassificationState.synced:
      case ClassificationState.saved:
      case ClassificationState.cancelled:
      case ClassificationState.failedPermanent:
        return false;
      default:
        return true;
    }
  }

  bool get showContinue =>
      state == ClassificationState.awaitingUserConfirmation ||
      state == ClassificationState.classificationSucceeded;

  @override
  State<AnalysisProgressView> createState() => _AnalysisProgressViewState();
}

class _AnalysisProgressViewState extends State<AnalysisProgressView> {
  @override
  void didUpdateWidget(covariant AnalysisProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _triggerStateHaptic(widget.state);
    }
  }

  void _triggerStateHaptic(ClassificationState state) {
    if (!AnimationSystem.shouldAnimate(context)) {
      return;
    }
    try {
      switch (state) {
        case ClassificationState.qualityChecking:
        case ClassificationState.qualityRejected:
        case ClassificationState.cacheChecking:
        case ClassificationState.cloudClassifying:
        case ClassificationState.localClassifying:
          VisualFeedbackService.instance.selectionClick();
          break;
        case ClassificationState.queuedOffline:
          VisualFeedbackService.instance.lightImpact();
          break;
        case ClassificationState.policyApplied:
        case ClassificationState.classificationSucceeded:
        case ClassificationState.saved:
        case ClassificationState.synced:
          VisualFeedbackService.instance.mediumImpact();
          break;
        case ClassificationState.awaitingUserConfirmation:
          VisualFeedbackService.instance.selectionClick();
          break;
        case ClassificationState.failedRetryable:
          VisualFeedbackService.instance.heavyImpact();
          break;
        case ClassificationState.failedPermanent:
          VisualFeedbackService.instance.heavyImpact();
          break;
        case ClassificationState.idle:
        case ClassificationState.imageSelected:
        case ClassificationState.cacheHit:
        case ClassificationState.saving:
        case ClassificationState.syncing:
        case ClassificationState.cancelled:
          break;
      }
    } catch (_) {}
  }

  Duration get _microAnimationDuration => AnimationSystem.accessibleDuration(
      context, const Duration(milliseconds: 240));

  Duration get _macroAnimationDuration => AnimationSystem.accessibleDuration(
      context, const Duration(milliseconds: 420));

  double get _stageProgress {
    switch (widget.state) {
      case ClassificationState.idle:
      case ClassificationState.imageSelected:
        return 0.0;
      case ClassificationState.qualityChecking:
      case ClassificationState.qualityRejected:
      case ClassificationState.cacheChecking:
        return 0.12;
      case ClassificationState.cacheHit:
        return 0.50;
      case ClassificationState.cloudClassifying:
      case ClassificationState.localClassifying:
        return 0.62;
      case ClassificationState.queuedOffline:
        return 0.22;
      case ClassificationState.classificationSucceeded:
        return 0.82;
      case ClassificationState.policyApplied:
        return 0.90;
      case ClassificationState.awaitingUserConfirmation:
        return 0.95;
      case ClassificationState.saving:
      case ClassificationState.syncing:
        return 0.96;
      case ClassificationState.saved:
      case ClassificationState.synced:
      case ClassificationState.failedRetryable:
      case ClassificationState.failedPermanent:
      case ClassificationState.cancelled:
        return 1.0;
    }
  }

  String get _stageTitle {
    switch (widget.state) {
      case ClassificationState.idle:
      case ClassificationState.imageSelected:
        return 'Ready to analyze';
      case ClassificationState.qualityChecking:
      case ClassificationState.qualityRejected:
      case ClassificationState.cacheChecking:
        return 'Checking image quality';
      case ClassificationState.cacheHit:
        return 'Found cached result';
      case ClassificationState.cloudClassifying:
      case ClassificationState.localClassifying:
        return 'Analyzing image';
      case ClassificationState.queuedOffline:
        return 'Queued for offline processing';
      case ClassificationState.classificationSucceeded:
        return 'Classification complete';
      case ClassificationState.policyApplied:
        return 'Applying local rules';
      case ClassificationState.awaitingUserConfirmation:
        return 'Result needs review';
      case ClassificationState.saving:
        return 'Saving result';
      case ClassificationState.saved:
        return 'Saved';
      case ClassificationState.syncing:
        return 'Syncing to cloud';
      case ClassificationState.synced:
        return 'Synced';
      case ClassificationState.failedRetryable:
        return 'Analysis interrupted';
      case ClassificationState.failedPermanent:
        return 'Analysis failed';
      case ClassificationState.cancelled:
        return 'Cancelled';
    }
  }

  String get _stageDescription {
    if (widget.statusMessage != null && widget.statusMessage!.isNotEmpty) {
      return widget.statusMessage!;
    }
    switch (widget.state) {
      case ClassificationState.idle:
      case ClassificationState.imageSelected:
        return 'Tap analyze to start.';
      case ClassificationState.qualityChecking:
      case ClassificationState.qualityRejected:
      case ClassificationState.cacheChecking:
        return 'Validating sharpness, brightness, and resolution.';
      case ClassificationState.cacheHit:
        return 'Using a previous result for this image.';
      case ClassificationState.cloudClassifying:
      case ClassificationState.localClassifying:
        return 'Model inference, classification, and confidence scoring.';
      case ClassificationState.queuedOffline:
        return 'Offline queue: your item is stored and will process when online.';
      case ClassificationState.classificationSucceeded:
        return 'Category and local guidance are being finalized.';
      case ClassificationState.policyApplied:
        return 'Checking municipal guidance and local disposal hints.';
      case ClassificationState.awaitingUserConfirmation:
        return 'The result is available but needs manual verification.';
      case ClassificationState.saving:
        return 'Writing classification to local storage.';
      case ClassificationState.saved:
        return 'Classification saved successfully.';
      case ClassificationState.syncing:
        return 'Uploading to cloud storage.';
      case ClassificationState.synced:
        return 'Fully synced.';
      case ClassificationState.failedRetryable:
        return 'We can retry this step with the same image.';
      case ClassificationState.failedPermanent:
        return 'This cannot be retried. Please start again.';
      case ClassificationState.cancelled:
        return 'Analysis was cancelled.';
    }
  }

  Color _primaryColor(BuildContext context) {
    final theme = Theme.of(context);
    final base = widget.resultCategoryColor ?? AppTheme.primaryColor;
    switch (widget.state) {
      case ClassificationState.awaitingUserConfirmation:
      case ClassificationState.failedRetryable:
      case ClassificationState.failedPermanent:
        return theme.colorScheme.error;
      default:
        return base;
    }
  }

  IconData get _stageIcon {
    switch (widget.state) {
      case ClassificationState.idle:
      case ClassificationState.imageSelected:
        return Icons.image_outlined;
      case ClassificationState.qualityChecking:
      case ClassificationState.qualityRejected:
      case ClassificationState.cacheChecking:
        return Icons.fact_check_outlined;
      case ClassificationState.cacheHit:
        return Icons.memory;
      case ClassificationState.cloudClassifying:
      case ClassificationState.localClassifying:
        return Icons.psychology_outlined;
      case ClassificationState.queuedOffline:
        return Icons.cloud_queue;
      case ClassificationState.classificationSucceeded:
        return Icons.check_circle_outline;
      case ClassificationState.policyApplied:
        return Icons.gavel;
      case ClassificationState.awaitingUserConfirmation:
        return Icons.help_outline;
      case ClassificationState.saving:
        return Icons.save_outlined;
      case ClassificationState.saved:
        return Icons.save;
      case ClassificationState.syncing:
        return Icons.cloud_upload_outlined;
      case ClassificationState.synced:
        return Icons.cloud_done;
      case ClassificationState.failedRetryable:
        return Icons.refresh;
      case ClassificationState.failedPermanent:
        return Icons.error_outline;
      case ClassificationState.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = !AnimationSystem.shouldAnimate(context);
    final stageColor = _primaryColor(context);
    final cs = widget.state;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Card(
          elevation: reducedMotion ? 0 : 2,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildLeadingIcon(theme, stageColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stageTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (widget.imageName != null &&
                              widget.imageName!.isNotEmpty) ...[
                            Text(
                              widget.imageName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            _stageDescription,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cs == ClassificationState.queuedOffline)
                  _buildQueuedStack(reducedMotion, stageColor),
                if (cs == ClassificationState.policyApplied)
                  _buildRuleChip(context, reducedMotion, stageColor),
                if (widget.confidenceText != null &&
                    widget.confidenceText!.isNotEmpty &&
                    (cs == ClassificationState.awaitingUserConfirmation ||
                        cs == ClassificationState.classificationSucceeded))
                  _buildConfidenceRow(theme, stageColor),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: _macroAnimationDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(cs),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: _stageProgress,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            stageColor.withValues(alpha: 0.95)),
                      ),
                      const SizedBox(height: 10),
                      _buildStagedSubtext(context, stageColor),
                    ],
                  ),
                ),
                if (_shouldRenderError(context)) ...[
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: _microAnimationDuration,
                    child: Container(
                      key: ValueKey('error-${cs.name}'),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.errorMessage ?? 'Something needs review.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: _microAnimationDuration,
                  child: Row(
                    key: ValueKey('${widget.showRetry}-${widget.showCancel}'),
                    children: [
                      if (widget.onCancel != null && widget.showCancel)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                        ),
                      if (widget.onCancel != null &&
                          widget.onRetry != null &&
                          widget.showCancel)
                        const SizedBox(width: 8),
                      if (widget.onContinue != null &&
                          cs == ClassificationState.awaitingUserConfirmation)
                        Expanded(
                          child: TextButton(
                            onPressed: widget.onContinue,
                            child: const Text('Continue'),
                          ),
                        ),
                      if (widget.onRetry != null &&
                          widget.showRetry &&
                          cs == ClassificationState.failedRetryable)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onRetry,
                            child: const Text('Retry'),
                          ),
                        ),
                      if (cs == ClassificationState.classificationSucceeded &&
                          widget.onContinue != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            child: const Text('View result'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldRenderError(BuildContext context) {
    return widget.errorMessage != null &&
        (widget.state == ClassificationState.awaitingUserConfirmation ||
            widget.state == ClassificationState.failedRetryable ||
            widget.state == ClassificationState.failedPermanent);
  }

  Widget _buildLeadingIcon(ThemeData theme, Color stageColor) {
    final reducedMotion = !AnimationSystem.shouldAnimate(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: reducedMotion ? 1.0 : 1.08),
      duration: _macroAnimationDuration,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: _microAnimationDuration,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  stageColor.withValues(alpha: 0.2),
                  stageColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              _stageIcon,
              color: stageColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStagedSubtext(BuildContext context, Color stageColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPill(
          context,
          'Quality',
          _stateReached(ClassificationState.cacheChecking),
        ),
        _buildPill(
          context,
          'Analyze',
          _stateReached(ClassificationState.cloudClassifying),
        ),
        _buildPill(
          context,
          'Local rules',
          _stateReached(ClassificationState.policyApplied),
          accent: stageColor,
        ),
        _buildPill(
          context,
          'Save',
          _stateReached(ClassificationState.saving),
        ),
      ],
    );
  }

  bool _stateReached(ClassificationState threshold) {
    const order = ClassificationState.values;
    return order.indexOf(widget.state) >= order.indexOf(threshold);
  }

  Widget _buildPill(BuildContext context, String label, bool active,
      {Color? accent}) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: _microAnimationDuration,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? (accent ?? AppTheme.primaryColor).withValues(alpha: 0.16)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? (accent ?? AppTheme.primaryColor).withValues(alpha: 0.55)
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: active
                ? (accent ?? AppTheme.primaryColor)
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? (accent ?? AppTheme.primaryColor)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedStack(bool reducedMotion, Color stageColor) {
    final count = math.min(widget.offlineQueueCount ?? 1, 3);
    final stackDepth = math.max(1, count);
    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(stackDepth, (index) {
          return AnimatedSlide(
            duration: _macroAnimationDuration,
            curve: Curves.easeOutCubic,
            offset: Offset(0, reducedMotion ? 0 : -0.12 * (stackDepth - index)),
            child: AnimatedOpacity(
              duration: _macroAnimationDuration,
              opacity: 1 - (index * 0.18),
              curve: Curves.easeInOut,
              child: Transform.rotate(
                angle: reducedMotion ? 0 : (index * 0.04),
                child: Container(
                  width: 230,
                  margin: EdgeInsets.only(top: index * 8.0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: stageColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, color: stageColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline queue position #${widget.offlineQueueCount ?? 1}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: stageColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRuleChip(
      BuildContext context, bool reducedMotion, Color stageColor) {
    return AnimatedContainer(
      duration: _macroAnimationDuration,
      margin: const EdgeInsets.only(bottom: 10),
      transform: reducedMotion
          ? Matrix4.identity()
          : Matrix4.translationValues(0, 12, 0),
      child: AnimatedSlide(
        duration: _macroAnimationDuration,
        offset: reducedMotion ? Offset.zero : const Offset(0.03, 0),
        child: Wrap(
          spacing: 8,
          children: [
            Chip(
              backgroundColor: stageColor.withValues(alpha: 0.12),
              side: BorderSide(color: stageColor.withValues(alpha: 0.6)),
              label: Text(
                widget.localRuleChipText ??
                    'Local rules checked for your region.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: stageColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              avatar: CircleAvatar(
                backgroundColor: stageColor.withValues(alpha: 0.22),
                child: Icon(Icons.rule, color: stageColor, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceRow(ThemeData theme, Color stageColor) {
    return AnimatedSwitcher(
      duration: _microAnimationDuration,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        key: ValueKey('confidence-${widget.confidenceText}'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: stageColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stageColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          widget.confidenceText!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: stageColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
