import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/classification_state.dart';
import '../utils/constants.dart';

/// DEPRECATED: Use [ClassificationState] instead. Retained temporarily for
/// backward compatibility during migration.
@Deprecated('Use ClassificationState instead')
enum AnalysisProgressStage {
  checkingQuality,
  queuedOffline,
  uploading,
  analyzingImage,
  applyingLocalRules,
  success,
  fallback,
  failedRetryable,
}

class AnalysisProgressView extends StatefulWidget {
  const AnalysisProgressView({
    super.key,
    required this.stage,
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
    this.showRetry = false,
    this.showCancel = false,
  });

  /// Construct from canonical [ClassificationState] instead of legacy enum.
  factory AnalysisProgressView.fromState({
    Key? key,
    required ClassificationState state,
    String? imageName,
    int? offlineQueueCount,
    int? queuePosition,
    String? localRuleChipText,
    String? statusMessage,
    String? errorMessage,
    String? confidenceText,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
    Color? resultCategoryColor,
  }) {
    return AnalysisProgressView(
      key: key,
      stage: classificationStateToStage(state),
      imageName: imageName,
      offlineQueueCount: offlineQueueCount,
      queuePosition: queuePosition,
      localRuleChipText: localRuleChipText,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
      confidenceText: confidenceText,
      onRetry: onRetry,
      onCancel: onCancel,
      onContinue: onContinue,
      resultCategoryColor: resultCategoryColor,
      showRetry: state == ClassificationState.failedRetryable,
      showCancel: !_isTerminalDisplayState(state),
    );
  }

  static bool _isTerminalDisplayState(ClassificationState state) {
    return state == ClassificationState.synced ||
        state == ClassificationState.saved ||
        state == ClassificationState.cancelled ||
        state == ClassificationState.failedPermanent;
  }

  /// Map canonical state to the legacy progress stage for the existing widget.
  static AnalysisProgressStage classificationStateToStage(
    ClassificationState cs,
  ) {
    switch (cs) {
      case ClassificationState.idle:
      case ClassificationState.imageSelected:
        return AnalysisProgressStage.checkingQuality;
      case ClassificationState.qualityChecking:
      case ClassificationState.qualityRejected:
        return AnalysisProgressStage.checkingQuality;
      case ClassificationState.cacheChecking:
        return AnalysisProgressStage.checkingQuality;
      case ClassificationState.cacheHit:
        return AnalysisProgressStage.success;
      case ClassificationState.cloudClassifying:
      case ClassificationState.localClassifying:
        return AnalysisProgressStage.analyzingImage;
      case ClassificationState.queuedOffline:
        return AnalysisProgressStage.queuedOffline;
      case ClassificationState.classificationSucceeded:
        return AnalysisProgressStage.success;
      case ClassificationState.policyApplied:
        return AnalysisProgressStage.applyingLocalRules;
      case ClassificationState.awaitingUserConfirmation:
        return AnalysisProgressStage.fallback;
      case ClassificationState.saving:
      case ClassificationState.saved:
      case ClassificationState.syncing:
      case ClassificationState.synced:
        return AnalysisProgressStage.success;
      case ClassificationState.failedRetryable:
        return AnalysisProgressStage.failedRetryable;
      case ClassificationState.failedPermanent:
        return AnalysisProgressStage.failedRetryable;
      case ClassificationState.cancelled:
        return AnalysisProgressStage.checkingQuality;
    }
  }

  final AnalysisProgressStage stage;
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
  final bool showRetry;
  final bool showCancel;

  @override
  State<AnalysisProgressView> createState() => _AnalysisProgressViewState();
}

class _AnalysisProgressViewState extends State<AnalysisProgressView> {
  @override
  void didUpdateWidget(covariant AnalysisProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _triggerStageHaptic(widget.stage);
    }
  }

  void _triggerStageHaptic(AnalysisProgressStage stage) {
    if (MediaQuery.accessibleNavigationOf(context) ||
        !_shouldAnimate(context)) {
      return;
    }

    try {
      switch (stage) {
        case AnalysisProgressStage.checkingQuality:
          HapticFeedback.selectionClick();
          break;
        case AnalysisProgressStage.queuedOffline:
          HapticFeedback.lightImpact();
          break;
        case AnalysisProgressStage.uploading:
        case AnalysisProgressStage.analyzingImage:
          HapticFeedback.selectionClick();
          break;
        case AnalysisProgressStage.applyingLocalRules:
          HapticFeedback.mediumImpact();
          break;
        case AnalysisProgressStage.success:
          HapticFeedback.mediumImpact();
          break;
        case AnalysisProgressStage.fallback:
          HapticFeedback.selectionClick();
          break;
        case AnalysisProgressStage.failedRetryable:
          HapticFeedback.heavyImpact();
          break;
      }
    } catch (_) {
      // Haptic feedback is non-critical for state transitions.
    }
  }

  bool _shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  Duration get _microAnimationDuration => Duration(
        milliseconds: _shouldAnimate(context) ? 240 : 0,
      );

  Duration get _macroAnimationDuration => Duration(
        milliseconds: _shouldAnimate(context) ? 420 : 0,
      );

  double get _stageProgress {
    switch (widget.stage) {
      case AnalysisProgressStage.checkingQuality:
        return 0.12;
      case AnalysisProgressStage.queuedOffline:
        return 0.22;
      case AnalysisProgressStage.uploading:
        return 0.38;
      case AnalysisProgressStage.analyzingImage:
        return 0.62;
      case AnalysisProgressStage.applyingLocalRules:
        return 0.82;
      case AnalysisProgressStage.success:
      case AnalysisProgressStage.fallback:
      case AnalysisProgressStage.failedRetryable:
        return 1.0;
    }
  }

  String get _stageTitle {
    switch (widget.stage) {
      case AnalysisProgressStage.checkingQuality:
        return 'Checking image quality';
      case AnalysisProgressStage.queuedOffline:
        return 'Queued for offline processing';
      case AnalysisProgressStage.uploading:
        return 'Uploading image';
      case AnalysisProgressStage.analyzingImage:
        return 'Analyzing image';
      case AnalysisProgressStage.applyingLocalRules:
        return 'Applying local rules';
      case AnalysisProgressStage.success:
        return 'Result ready';
      case AnalysisProgressStage.fallback:
        return 'Result needs review';
      case AnalysisProgressStage.failedRetryable:
        return 'Analysis interrupted';
    }
  }

  String get _stageDescription {
    if (widget.statusMessage != null && widget.statusMessage!.isNotEmpty) {
      return widget.statusMessage!;
    }

    switch (widget.stage) {
      case AnalysisProgressStage.checkingQuality:
        return 'Validating sharpness, brightness, and resolution.';
      case AnalysisProgressStage.queuedOffline:
        return 'Offline network is enabled fallback queue; your item is stored and will process when online.';
      case AnalysisProgressStage.uploading:
        return 'Preparing your photo and metadata for secure processing.';
      case AnalysisProgressStage.analyzingImage:
        return 'Model inference, classification, and confidence scoring.';
      case AnalysisProgressStage.applyingLocalRules:
        return 'Checking municipal guidance and local disposal hints.';
      case AnalysisProgressStage.success:
        return 'Category and local guidance have been finalized.';
      case AnalysisProgressStage.fallback:
        return 'The result is available but needs manual verification.';
      case AnalysisProgressStage.failedRetryable:
        return 'We can retry this step with the same image.';
    }
  }

  Color _primaryColor(BuildContext context) {
    final theme = Theme.of(context);
    final base = widget.resultCategoryColor ?? AppTheme.primaryColor;
    if (widget.stage == AnalysisProgressStage.fallback) {
      return theme.colorScheme.error;
    }
    if (widget.stage == AnalysisProgressStage.failedRetryable) {
      return theme.colorScheme.error;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = !_shouldAnimate(context);
    final stageColor = _primaryColor(context);

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
                if (widget.stage == AnalysisProgressStage.queuedOffline)
                  _buildQueuedStack(reducedMotion, stageColor),
                if (widget.stage == AnalysisProgressStage.applyingLocalRules)
                  _buildRuleChip(context, reducedMotion, stageColor),
                if (widget.confidenceText != null &&
                    widget.confidenceText!.isNotEmpty &&
                    (widget.stage == AnalysisProgressStage.fallback ||
                        widget.stage == AnalysisProgressStage.success))
                  _buildConfidenceRow(theme, stageColor),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: _macroAnimationDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(widget.stage),
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
                      key: ValueKey('error-${widget.stage}'),
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
                          widget.stage == AnalysisProgressStage.fallback)
                        Expanded(
                          child: TextButton(
                            onPressed: widget.onContinue,
                            child: const Text('Continue'),
                          ),
                        ),
                      if (widget.onRetry != null &&
                          widget.showRetry &&
                          widget.stage == AnalysisProgressStage.failedRetryable)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onRetry,
                            child: const Text('Retry'),
                          ),
                        ),
                      if (widget.stage == AnalysisProgressStage.success &&
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
        (widget.stage == AnalysisProgressStage.fallback ||
            widget.stage == AnalysisProgressStage.failedRetryable);
  }

  Widget _buildLeadingIcon(ThemeData theme, Color stageColor) {
    final reducedMotion = !_shouldAnimate(context);
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

  IconData get _stageIcon {
    switch (widget.stage) {
      case AnalysisProgressStage.checkingQuality:
        return Icons.fact_check_outlined;
      case AnalysisProgressStage.queuedOffline:
        return Icons.cloud_queue;
      case AnalysisProgressStage.uploading:
        return Icons.cloud_upload_outlined;
      case AnalysisProgressStage.analyzingImage:
        return Icons.psychology_outlined;
      case AnalysisProgressStage.applyingLocalRules:
        return Icons.gavel;
      case AnalysisProgressStage.success:
        return Icons.check_circle;
      case AnalysisProgressStage.fallback:
        return Icons.help_outline;
      case AnalysisProgressStage.failedRetryable:
        return Icons.refresh;
    }
  }

  Widget _buildStagedSubtext(BuildContext context, Color stageColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPill(context, 'Quality',
            widget.stage != AnalysisProgressStage.checkingQuality),
        _buildPill(
            context, 'Upload', _stageReached(AnalysisProgressStage.uploading)),
        _buildPill(context, 'Analyze',
            _stageReached(AnalysisProgressStage.analyzingImage)),
        _buildPill(
          context,
          'Local rules',
          _stageReached(AnalysisProgressStage.applyingLocalRules),
          accent: stageColor,
        ),
      ],
    );
  }

  bool _stageReached(AnalysisProgressStage value) {
    const order = AnalysisProgressStage.values;
    return order.indexOf(widget.stage) >= order.indexOf(value);
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
          final delay = reducedMotion ? 0.0 : index * 0.12;
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
