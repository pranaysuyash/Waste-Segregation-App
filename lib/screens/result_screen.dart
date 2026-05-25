import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/visual_feedback_service.dart';
import '../models/classification_state.dart';
import '../models/gamification.dart';
import '../services/result_pipeline.dart';
import '../services/haptic_settings_service.dart';
import '../services/analytics_service.dart';
import '../services/ai_service.dart';
import '../providers/app_providers.dart';
import '../screens/educational_content_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/disposal_facilities_screen.dart';
import '../screens/waste_dashboard_screen.dart';
import '../widgets/result_screen/result_header.dart';
import '../utils/ai_error_messages.dart';
import '../widgets/result_screen/disposal_accordion.dart';
import '../widgets/result_screen/action_row.dart';
import '../widgets/result_screen/points_popup.dart';
import '../widgets/result_screen/achievement_wrapper.dart';
import '../widgets/result_screen/explanation_panel.dart';
import '../widgets/result_screen/staggered_list.dart';
import '../widgets/result_screen/materials_preview.dart';
import '../widgets/result_screen/local_rules_card.dart';
import '../widgets/offline_result_banner.dart';
import '../widgets/interactive_tag.dart';
import '../widgets/correction_dialog.dart';
import '../widgets/responsive_text.dart';
import '../utils/classification_tags.dart';
import '../utils/waste_app_logger.dart';
import '../utils/education_card_engine.dart';
import '../models/education_card.dart';
import '../widgets/education_card_widget.dart';
import '../screens/mini_lesson_screen.dart';
import '../config/debug_config.dart';
import '../utils/design_system.dart';
import '../widgets/analysis_progress_view.dart';

/// ResultScreen — Canonical result screen implementation.
///
/// Features:
/// - Composable widget architecture with separation of concerns
/// - Material 3 design principles with proper theming
/// - Progressive disclosure with collapsible sections
/// - Clean integration with ResultPipeline for business logic
/// - Full feedback/correction pipeline
/// - Environmental impact scores, tags, disposal instructions
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.classification,
    this.showActions = true,
    this.autoAnalyze = false,
    this.heroTag,
  });

  final WasteClassification classification;
  final bool showActions;
  final bool autoAnalyze;
  final String? heroTag;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin, AchievementCelebrationMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnalyticsService _analyticsService;

  // Mutable classification — updated after re-analysis
  late WasteClassification _classification;
  bool _isReanalyzing = false;

  // Audit trail: set to true when the classification has been re-analyzed
  bool _wasCorrected = false;
  bool get hasLowConfidence => (_classification.confidence ?? 1.0) < 0.7;

  // Gamification state
  bool _hasShownPointsPopup = false;
  bool _hasProcessedGamification = false;
  bool _isRetryingPipeline = false;

  // Education card state
  WasteEducationCard? _educationCard;
  final EducationCardEngine _educationEngine = EducationCardEngine();

  @override
  void initState() {
    super.initState();

    _classification = widget.classification;

    // Use the canonical analytics provider so tests can override it and the
    // result screen does not construct a Firebase-backed service directly.
    _analyticsService = ref.read(analyticsServiceProvider);

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Defer provider mutations until after the first frame so Riverpod does
    // not reject state changes during widget construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processClassification();
      _trackScreenView();
      _selectEducationCard();

      // Check retroactive gamification for existing classifications
      if (!widget.showActions && !widget.autoAnalyze) {
        _checkRetroactiveGamification();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _processClassification({bool force = false}) async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.processClassification(
        _classification,
        autoAnalyze: widget.autoAnalyze,
        force: force,
      );
    } catch (error, stackTrace) {
      WasteAppLogger.severe(
        'Failed to process classification in pipeline',
        error: error,
        stackTrace: stackTrace,
        context: {
          'classificationId': _classification.id,
          'service': 'ResultScreen',
        },
      );
    }
  }

  Future<void> _retryClassificationProcessing() async {
    if (_isRetryingPipeline) return;
    _isRetryingPipeline = true;

    setState(() {
      _hasProcessedGamification = false;
      _hasShownPointsPopup = false;
    });

    try {
      await _processClassification(force: true);
    } finally {
      if (mounted) {
        _isRetryingPipeline = false;
      }
    }
  }

  ClassificationState _pipelineProgressState(
      ResultPipelineState pipelineState) {
    if (pipelineState.error != null) {
      return ClassificationState.failedRetryable;
    }
    if (pipelineState.isProcessing) {
      return ClassificationState.policyApplied;
    }
    final shouldShowFallback = _classification.clarificationNeeded == true ||
        _classification.category.toLowerCase() == 'requires manual review';
    return shouldShowFallback
        ? ClassificationState.awaitingUserConfirmation
        : ClassificationState.classificationSucceeded;
  }

  String _pipelineStatusMessage(ResultPipelineState pipelineState) {
    if (pipelineState.error != null) {
      return AiErrorMessages.toUserMessage(pipelineState.error!);
    }
    if (pipelineState.isProcessing) {
      return 'Applying local rules, saving, and preparing rewards.';
    }
    return '';
  }

  void _selectEducationCard() {
    final cooldownIds = _educationEngine.currentCooldownIds();

    final card = _educationEngine.bestCardFor(
      _classification,
      _classification.region,
      excludeIds: cooldownIds,
    );
    if (card != null && mounted) {
      setState(() => _educationCard = card);
    }
  }

  void _dismissEducationCard() {
    if (_educationCard == null) return;
    final cardId = _educationCard!.id;
    EducationCardEngine.dismissCard(cardId);
    setState(() => _educationCard = null);
  }

  void _openMiniLesson() {
    if (_educationCard == null) return;
    final relatedIds = _educationCard!.relatedCardIds ?? [];
    final relatedCards = relatedIds
        .map((id) => _educationEngine.cardById(id))
        .whereType<WasteEducationCard>()
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MiniLessonScreen(
          card: _educationCard!,
          relatedCards: relatedCards,
          onDismissParent: _dismissEducationCard,
        ),
      ),
    );
  }

  void _trackScreenView() {
    // Use Legacy event name for parity
    _analyticsService.trackScreenView(
      'ResultScreen',
      parameters: {
        'classification_id': _classification.id,
        'category': _classification.category,
        'item_name': _classification.itemName,
        'confidence': _classification.confidence,
        'show_actions': widget.showActions,
        'auto_analyze': widget.autoAnalyze,
        'version': 'v2',
        if (_classification.analysisSource != null)
          'analysis_source': _classification.analysisSource,
        if (_classification.modelVersion != null)
          'model_version': _classification.modelVersion,
        if (_classification.analysisFallbackReason != null)
          'fallback_reason': _classification.analysisFallbackReason,
      },
    );

    // Also log for debugging
    WasteAppLogger.aiEvent(
      'result_screen_viewed',
      context: {
        'classificationId': _classification.id,
        'category': _classification.category,
        'analysisSource': _classification.analysisSource,
        'version': 'v2',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pipelineState = ref.watch(resultPipelineProvider);

    // Process gamification when pipeline completes
    _processGamificationState(pipelineState);

    // Build tags once
    final tags = buildClassificationTags(_classification);
    final hasLowConfidence = (_classification.confidence ?? 1.0) < 0.7;
    final isFallback = _classification.category.toLowerCase() == 'general';
    final needsReview = _classification.clarificationNeeded == true;

    final scaffold = Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: widget.showActions
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: _handleReanalyze,
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: colorScheme.onSurface),
                          onPressed: _handleShare,
                        ),
                      ]
                    : null,
              ),

              // Content
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Hero Header with KPIs
                      ResultHeader(
                        classification: _classification,
                        pointsEarned: pipelineState.pointsEarned,
                        onDisposeCorrectly: _handleDisposeCorrectly,
                        heroTag: widget.heroTag,
                      ),

                      const SizedBox(height: 32),

                      // Progressive Disclosure Sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Processing state
                            if (pipelineState.isProcessing ||
                                pipelineState.error != null)
                              _buildPipelineProgress(context, pipelineState),

                            // Re-analysis audit trail badge
                            if (_wasCorrected) _buildCorrectedBadge(context),

                            // Re-analysis in-progress banner
                            if (_isReanalyzing) _buildReanalysisBanner(context),

                            // Offline result banner (Layer 0 hint while offline)
                            if (_classification.isOfflineHint)
                              OfflineResultBanner(
                                isAccepted: _classification.classificationLayer ==
                                    'layer0_deterministic',
                              ),

                            // Needs-review banner (clarificationNeeded or fallback)
                            if (needsReview || isFallback)
                              _buildNeedsReviewBanner(context),

                            // Low-confidence warning banner
                            if (hasLowConfidence && !needsReview && !isFallback)
                              _buildLowConfidenceBanner(context),

                            // Interactive Tags
                            if (tags.isNotEmpty) ...[
                              StaggeredTagList(
                                tags: tags
                                    .map(
                                      (t) => InteractiveTag(
                                        text: t.text,
                                        color: t.color,
                                        icon: t.icon,
                                        textColor: t.textColor,
                                        action: t.action,
                                        category: t.category,
                                        subcategory: t.subcategory,
                                        isOutlined: t.isOutlined,
                                        onTap: t.onTap,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Disposal Instructions Accordion
                            DisposalAccordion(
                              classification: _classification,
                            ),

                            const SizedBox(height: 16),

                            // Why This Classification Card + educational fact
                            ExplanationPanel(classification: _classification),
                            if (_buildStoryCards(context) != null) ...[
                              const SizedBox(height: 16),
                              _buildStoryCards(context)!,
                            ],

                            // Education card (one relevant card picked by engine)
                            if (_educationCard != null) ...[
                              const SizedBox(height: 16),
                              EducationCardWidget(
                                card: _educationCard!,
                                onDismiss: _dismissEducationCard,
                                onLearnMore: _educationCard!.extendedBody != null
                                    ? _openMiniLesson
                                    : null,
                              ),
                            ],

                            // Learn More recommendation card
                            _buildLearnMoreCard(context),

                            const SizedBox(height: 24),

                            // Impact Reveal / Eco Score
                            _buildImpactReveal(context),

                            const SizedBox(height: 16),

                            // Impact Journey
                            _buildImpactJourney(context),

                            const SizedBox(height: 16),

                            // Category Snapshot
                            _buildCategorySnapshot(context),

                            // Materials & Alternatives
                            // Materials & Alternatives
                            if (MaterialsPreview.hasMaterialsPreview(
                              _classification,
                            )) ...[
                              const SizedBox(height: 16),
                              MaterialsPreview(classification: _classification),
                            ],

                            // Disposal Checklist
                            if (_hasDisposalChecklist(
                              _classification,
                            )) ...[
                              const SizedBox(height: 16),
                              _buildDisposalChecklist(context),
                            ],

                            // Local Rules (BBMP)
                            if (LocalRulesCard.hasLocalRules(
                                _classification)) ...[
                              const SizedBox(height: 16),
                              LocalRulesCard(classification: _classification),
                            ],

                            // Safety Warnings
                            if (_hasSafetyWarnings(_classification)) ...[
                              const SizedBox(height: 16),
                              _buildSafetyWarnings(context),
                            ],

                            // Contamination Tips
                            const SizedBox(height: 16),
                            _buildContaminationTips(context),

                            // Challenge Completed
                            if (pipelineState.completedChallenge != null) ...[
                              const SizedBox(height: 16),
                              _buildCompletedChallengeCard(
                                context,
                                pipelineState,
                              ),
                            ],

                            // Points earned card
                            if (pipelineState.pointsEarned > 0) ...[
                              const SizedBox(height: 16),
                              _buildPointsCard(context, pipelineState),
                            ],

                            // Near-milestone nudge (post-scan progress encouragement)
                            _buildNearMilestoneNudge(context),

                            const SizedBox(height: 24),

                            // Secondary Actions
                            if (widget.showActions) ...[
                              _buildFeedbackPrompt(context),
                              const SizedBox(height: 12),
                              ActionRow(
                                onShare: _handleShare,
                                onCorrect: _handleCorrection,
                                onSave: _handleSave,
                              ),
                              const SizedBox(height: 16),
                              // Quick action strip: scan another, view analytics
                              _buildQuickActionStrip(context),
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Add achievement celebration overlay
    return Stack(children: [scaffold, buildAchievementCelebration()]);
  }

  /// Audit trail badge shown after successful re-analysis.
  Widget _buildCorrectedBadge(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Corrected based on your feedback',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Low-confidence warning banner with re-analyze action.
  /// Re-analysis in-progress banner.
  Widget _buildReanalysisBanner(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Re-analyzing with your correction…',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowConfidenceBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low confidence (${((_classification.confidence ?? 0.0) * 100).toInt()}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try re-analyzing with a clearer image for better accuracy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              _analyticsService.trackUserAction(
                'low_confidence_reanalyze',
                parameters: {
                  'original_confidence': _classification.confidence.toString(),
                  'category': _classification.category,
                },
              );
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.refresh, size: 18, color: Colors.orange.shade800),
            label: Text(
              'Re-analyze',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsReviewBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This result needs review. Please verify before disposal.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Educational "Did You Know?" story card, ported from v1.
  Widget? _buildStoryCards(BuildContext context) {
    final theme = Theme.of(context);
    final fact = educationalFact(_classification);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReadMoreText(
                fact,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact "Learn more about this item" recommendation card.
  Widget _buildLearnMoreCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final educationalService = ref.read(educationalContentServiceProvider);
    final recommendation =
        educationalService.getRecommendationForClassification(
      category: _classification.category,
      subcategory: _classification.normalizedSubcategory,
      riskLevel: _classification.riskLevel,
      requiresSpecialDisposal: _classification.requiresSpecialDisposal,
      clarificationNeeded: _classification.clarificationNeeded,
      confidence: _classification.confidence,
    );

    if (recommendation == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _analyticsService.trackUserAction(
            'learn_more_tapped',
            parameters: {
              'content_id': recommendation.id,
              'content_title': recommendation.title,
              'category': _classification.category,
              'item': _classification.itemName,
            },
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationalContentScreen(
                initialCategory: recommendation.categories.isNotEmpty
                    ? recommendation.categories.first
                    : _classification.category,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendation.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Find disposal facilities action.
  void _handleFindFacility() {
    _analyticsService.trackUserAction(
      'find_facility',
      parameters: {
        'category': _classification.category,
        'item': _classification.itemName,
      },
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DisposalFacilitiesScreen()),
    );
  }

  /// Scan another item action.
  void _handleScanAnother() {
    _analyticsService.trackUserAction(
      'scan_another',
      parameters: {'category': _classification.category},
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ImageCaptureScreen()),
    );
  }

  /// View analytics dashboard.
  void _handleViewAnalytics() {
    _analyticsService.trackUserAction('view_analytics_dashboard');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WasteDashboardScreen()),
    );
  }

  /// Process gamification state changes
  void _processGamificationState(ResultPipelineState state) {
    if (_hasProcessedGamification || state.isProcessing) {
      return;
    }

    // Mark as processed to prevent duplicate handling
    _hasProcessedGamification = true;

    // Show points popup
    if (state.pointsEarned > 0 && !_hasShownPointsPopup) {
      _hasShownPointsPopup = true;
      _showPointsPopup(state.pointsEarned);
    }

    // Show achievement celebration
    if (state.newAchievements.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAchievementCelebration(state.newAchievements);
      });
    }

    // Debug logging
    ResultScreenDebugConfig.logPipelineOutput(
      classificationId: _classification.id,
      pointsEarned: state.pointsEarned,
      achievementsCount: state.newAchievements.length,
      isSaved: state.isSaved,
      analysisSource: _classification.analysisSource,
      modelVersion: _classification.modelVersion,
      fallbackReason: _classification.analysisFallbackReason,
    );
  }

  /// Show animated points popup
  void _showPointsPopup(int points) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.showPointsPopup(
          points,
          actionLabel: _buildRewardActionLabel(),
          impactLabel: _buildRewardImpactLabel(),
        );

        // Log analytics
        WasteAppLogger.aiEvent(
          'points_popup_shown',
          context: {
            'classificationId': _classification.id,
            'points': points,
            'version': 'v2',
          },
        );
      }
    });
  }

  String _buildRewardActionLabel() {
    final category = _classification.category.trim();
    if (category.isEmpty) return 'Waste sorted correctly';
    return '$category disposed right';
  }

  String? _buildRewardImpactLabel() {
    final co2 = _classification.co2Impact;
    if (co2 == null || co2 <= 0) return null;
    return '${co2.toStringAsFixed(1)}kg CO2 impact handled';
  }

  /// Trigger haptic feedback
  void _triggerHapticFeedback() {
    if (_classification.category == 'Requires Manual Review') return;
    VisualFeedbackService.instance.lightImpact();
  }

  void _handleDisposeCorrectly() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction(
      'dispose_correctly_tapped',
      parameters: {
        'category': _classification.category,
        'item': _classification.itemName,
      },
    );

    // Also log for debugging
    WasteAppLogger.aiEvent(
      'dispose_correctly_tapped',
      context: {
        'classificationId': _classification.id,
        'category': _classification.category,
        'version': 'v2',
      },
    );

    // Show disposal instructions in bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'How to Dispose',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: DisposalAccordion(
                        classification: _classification,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCorrection() async {
    // Prevent showing the dialog while a re-analysis is already in progress
    if (_isReanalyzing) return;

    // Track user action (fire-and-forget — analytics + logging are non-critical)
    unawaited(_analyticsService.trackUserAction(
      'correction_requested',
      parameters: {
        'category': _classification.category,
        'item': _classification.itemName,
      },
    ));
    WasteAppLogger.aiEvent(
      'correction_requested',
      context: {'classificationId': _classification.id, 'version': 'v2'},
    );

    final result = await showDialog<CorrectionResult>(
      context: context,
      builder: (context) => CorrectionDialog(classification: _classification),
    );

    // Guard: widget may have been disposed while dialog was open
    if (!mounted) return;

    // No action if dialog was dismissed or user confirmed
    if (result == null || result.userConfirmed) return;

    // User provided correction data — trigger re-analysis
    if (!result.hasCorrectionData) return;

    setState(() => _isReanalyzing = true);

    try {
      final aiService = _readAiService();

      // Build a correction string from the available fields
      final parts = <String>[
        if (result.userSuggestedCategory != null)
          'Category: ${result.userSuggestedCategory}',
        if (result.userSuggestedItemName != null)
          'Item: ${result.userSuggestedItemName}',
        if (result.userSuggestedMaterial != null)
          'Material: ${result.userSuggestedMaterial}',
        if (result.userNotes != null && result.userNotes!.isNotEmpty)
          'Notes: ${result.userNotes}',
      ];
      final correctionText = parts.join('; ');

      final reanalyzed = await aiService.handleUserCorrection(
        _classification,
        correctionText,
        result.userNotes,
      );

      if (!mounted) return;

      final oldCategory = _classification.category;
      final oldItemName = _classification.itemName;

      setState(() {
        _classification = reanalyzed;
        _isReanalyzing = false;
        _wasCorrected = true;
      });

      // Auto-save the corrected classification
      unawaited(_handleSave());

      // Track analytics for correction → reanalysis conversion
      unawaited(_analyticsService.trackUserAction(
        'correction_reanalyzed',
        parameters: {
          'classificationId': reanalyzed.id,
          'originalCategory': oldCategory,
          'newCategory': reanalyzed.category,
          'originalItem': oldItemName,
          'newItem': reanalyzed.itemName,
          'confidence': '${reanalyzed.confidence}',
          'source': 'correction_loop',
        },
      ));

      WasteAppLogger.aiEvent(
        'correction_reanalyzed',
        context: {
          'originalId': reanalyzed.id,
          'oldCategory': oldCategory,
          'newCategory': reanalyzed.category,
          'oldItem': oldItemName,
          'newItem': reanalyzed.itemName,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Re-analyzed: ${reanalyzed.displayItemLabel} → ${reanalyzed.displayCategoryLabel}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isReanalyzing = false);

      WasteAppLogger.severe('Re-analysis failed after correction', error: e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AiErrorMessages.toUserMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reads the AiService from the provider.
  /// This is a separate method so it can be overridden in tests.
  AiService _readAiService() => ref.read(aiServiceProvider);

  Future<void> _handleSave() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.saveClassificationOnly(_classification);
      _triggerHapticFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.shareClassification(_classification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReanalyze() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction(
      'classification_reanalyze',
      parameters: {
        'category': _classification.category,
        'item': _classification.itemName,
      },
    );

    // Navigate back to camera
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Ported features from v1
  // ---------------------------------------------------------------------------

  Widget _buildPipelineProgress(
      BuildContext context, ResultPipelineState pipelineState) {
    final state = _pipelineProgressState(pipelineState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnalysisProgressView(
        state: state,
        statusMessage: _pipelineStatusMessage(pipelineState),
        localRuleChipText: pipelineState.isProcessing
            ? 'Applying local rules and saving your scan result.'
            : null,
        confidenceText: _classification.confidence != null
            ? 'Confidence: ${(_classification.confidence! * 100).round()}%'
            : null,
        resultCategoryColor:
            WasteAppDesignSystem.getCategoryColor(_classification.category),
        onRetry: state == ClassificationState.failedRetryable
            ? _retryClassificationProcessing
            : null,
      ),
    );
  }

  Widget _buildImpactReveal(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final impact = _classification.getEnvironmentalImpactScore().clamp(
          1.0,
          10.0,
        );
    final eco = (10.0 - impact).clamp(0.0, 10.0);
    final progress = eco / 10.0;
    final color = _impactProgressColor(eco);

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Impact Reveal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: color,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eco.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('eco score', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.cloud_outlined,
              'CO2 impact',
              _formatCo2Impact(_classification),
            ),
            _buildInfoRow(
              context,
              Icons.timelapse,
              'Decomposition',
              _formatDecompositionTime(_classification),
            ),
            _buildInfoRow(
              context,
              Icons.recycling,
              'Recyclability',
              _formatRecyclability(_classification),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildImpactJourney(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = _classification;
    final accentColor = cs.primary;

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
                Icon(Icons.route, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Impact Journey',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _journeyStep(Icons.label_outline, 'Sorted as', c.category),
            _journeyStep(
              Icons.build_circle_outlined,
              'Processing',
              c.disposalInstructions.primaryMethod,
            ),
            _journeyStep(Icons.auto_awesome, 'Next life', _nextLifeText(c)),
          ],
        ),
      ),
    );
  }

  Widget _journeyStep(IconData icon, String title, String detail) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nextLifeText(WasteClassification c) {
    if (c.isCompostable == true) return 'Compost / Fertilizer';
    if (c.isRecyclable == true) {
      final mat = c.normalizedMaterials.isNotEmpty
          ? c.normalizedMaterials.first.toLowerCase()
          : null;
      if (mat == 'paper') return 'Recycled paper products';
      if (mat == 'plastic') return 'Recycled plastic products';
      if (mat == 'glass') return 'Recycled glass products';
      if (mat == 'metal') return 'Recycled metal products';
      return 'Recycling facility';
    }
    if (c.category.toLowerCase() == 'hazardous waste') {
      return 'Safe disposal facility';
    }
    if (c.category.toLowerCase() == 'medical waste') {
      return 'Incineration / Treatment';
    }
    return 'Proper disposal route';
  }

  Widget _buildCategorySnapshot(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = _classification;
    final items = <_SnapshotItem>[
      _SnapshotItem('Recyclable', _boolLabel(c.isRecyclable), Icons.recycling),
      _SnapshotItem('Compostable', _boolLabel(c.isCompostable), Icons.compost),
      _SnapshotItem(
        'Special Disposal',
        _boolLabel(c.requiresSpecialDisposal),
        Icons.warning_amber,
      ),
      _SnapshotItem('Risk Level', c.riskLevel ?? 'Unknown', Icons.report),
      _SnapshotItem(
        'Analysis Source',
        c.analysisSourceLabel,
        c.isExperimentalAnalysisSource
            ? Icons.science_outlined
            : Icons.cloud_outlined,
      ),
    ];
    if (c.recyclingCode != null) {
      items.add(
        _SnapshotItem(
          'Recycling Code',
          c.displayRecyclingCodeLabel,
          Icons.qr_code_2,
        ),
      );
    }
    if ((c.modelVersion ?? '').trim().isNotEmpty) {
      items.add(
        _SnapshotItem(
          'Model Version',
          c.modelVersion!,
          Icons.sell_outlined,
        ),
      );
    }
    if ((c.analysisFallbackReason ?? '').trim().isNotEmpty) {
      items.add(
        _SnapshotItem(
          'Fallback Reason',
          c.analysisFallbackReason!,
          Icons.subdirectory_arrow_right,
        ),
      );
    }

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
                Icon(Icons.dashboard, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Category Snapshot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final color = _snapshotColor(item.value);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${item.label}: ${item.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _boolLabel(bool? value) {
    if (value == null) return 'Unknown';
    return value ? 'Yes' : 'No';
  }

  Color _snapshotColor(String value) {
    switch (value.toLowerCase()) {
      case 'yes':
        return Colors.green;
      case 'no':
        return Colors.red;
      case 'unknown':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildDisposalChecklist(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final steps = _classification.disposalInstructions.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

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
                Icon(Icons.checklist, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Disposal Checklist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$i',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _hasDisposalChecklist(WasteClassification c) {
    return c.disposalInstructions.steps.isNotEmpty;
  }

  Widget _buildSafetyWarnings(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = _classification;
    final warnings = <String>[];
    if (c.requiresSpecialDisposal == true) {
      warnings.add('Requires special disposal handling.');
    }
    if (c.requiredPPE != null && c.requiredPPE!.isNotEmpty) {
      warnings.add('Use PPE: ${c.requiredPPE!.join(', ')}.');
    }
    if (c.hasUrgentTimeframe == true) {
      warnings.add('Time-sensitive disposal required.');
    }
    if (c.hazardLevel != null && c.hazardLevel! > 0) {
      warnings.add('Hazard level: ${c.hazardLevel}.');
    }
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: cs.errorContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: cs.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Safety Warnings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSafetyWarnings(WasteClassification c) {
    return c.requiresSpecialDisposal == true ||
        (c.requiredPPE?.isNotEmpty == true) ||
        c.hasUrgentTimeframe == true ||
        c.hazardLevel != null;
  }

  Widget _buildContaminationTips(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final warnings =
        _classification.disposalInstructions.warnings ?? const <String>[];
    final hints = _classification.disposalInstructions.tips ?? const <String>[];
    final tips = <String>[...warnings.take(2), ...hints.take(3)];

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
                Icon(Icons.cleaning_services, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contamination Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tips.isEmpty)
              Text(
                'Keep recyclables clean and dry.',
                style: theme.textTheme.bodySmall,
              )
            else
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip, style: theme.textTheme.bodySmall),
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

  Widget _buildCompletedChallengeCard(
    BuildContext context,
    ResultPipelineState state,
  ) {
    final theme = Theme.of(context);
    final challenge = state.completedChallenge!;
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
        title: Text(
          challenge.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(challenge.description, style: theme.textTheme.bodySmall),
        onTap: () => _showAchievementDetails(challenge),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, ResultPipelineState state) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.stars, color: Colors.amber.shade700, size: 24),
            const SizedBox(width: 12),
            Text(
              '+${state.pointsEarned} points earned',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionStrip(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _handleScanAnother,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Scan Another'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: _handleFindFacility,
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('Find Facility'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: _handleViewAnalytics,
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text('Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Almost there" nudge card shown after a scan when near a milestone.
  Widget _buildNearMilestoneNudge(BuildContext context) {
    final gamificationService = ref.watch(gamificationServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<NearMilestoneNudge?>(
      future: gamificationService.getNearMilestoneNudge(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final nudge = snapshot.data!;
        final nudgeColor = _resultNudgeColor(nudge.type);

        return Card(
          elevation: 0,
          color: nudgeColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: nudgeColor.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nudgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _resultNudgeIcon(nudge.iconName),
                    color: nudgeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nudge.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nudge.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: nudge.target > 0
                            ? nudge.progress / nudge.target
                            : 0,
                        backgroundColor: nudgeColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(nudgeColor),
                        minHeight: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _resultNudgeIcon(String? iconName) {
    switch (iconName) {
      case 'flag':
        return Icons.flag;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'stars':
        return Icons.stars;
      case 'category':
        return Icons.category;
      default:
        return Icons.near_me;
    }
  }

  Color _resultNudgeColor(NudgeType type) {
    switch (type) {
      case NudgeType.dailyGoal:
        return const Color(0xFF2196F3);
      case NudgeType.challengeNearComplete:
        return const Color(0xFFFF9800);
      case NudgeType.categoryAchievement:
        return const Color(0xFF4CAF50);
      case NudgeType.streakMilestone:
        return const Color(0xFFFF5722);
      case NudgeType.pointsMilestone:
        return const Color(0xFF9C27B0);
    }
  }

  void _showAchievementDetails(dynamic achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title ?? achievement.name ?? ''),
        content: Text(achievement.description ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _impactProgressColor(double ecoScore) {
    if (ecoScore >= 7.0) return Colors.green;
    if (ecoScore >= 4.0) return Colors.amber;
    return Colors.red;
  }

  String _formatCo2Impact(WasteClassification c) {
    final impact = c.co2Impact;
    if (impact == null) return 'Unknown';
    if (impact <= 0) return 'Low';
    return '${impact.toStringAsFixed(1)} kg';
  }

  String _formatDecompositionTime(WasteClassification c) {
    final value = c.decompositionTime;
    if (value == null || value.trim().isEmpty) return 'Unknown';
    return value;
  }

  String _formatRecyclability(WasteClassification c) {
    final explicit = c.recyclability;
    if (explicit != null && explicit.trim().isNotEmpty) return explicit;
    if (c.isRecyclable == true) return 'Recyclable';
    if (c.isRecyclable == false) return 'Not recyclable';
    return 'Unknown';
  }

  Widget _buildFeedbackPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confidence = _classification.confidence ?? 0.0;
    final lowConfidence = confidence < 0.7;

    return Card(
      elevation: 0,
      color: lowConfidence
          ? cs.secondaryContainer.withValues(alpha: 0.45)
          : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              lowConfidence ? Icons.help_outline : Icons.fact_check_outlined,
              color: lowConfidence ? cs.secondary : cs.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Was this correct?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lowConfidence
                        ? 'Help us improve uncertain results with a quick correction.'
                        : 'You can confirm it or tell us what should change.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _handleCorrection,
              child: const Text('Correct it'),
            ),
          ],
        ),
      ),
    );
  }

  // Retroactive gamification check — called from initState
  Future<void> _checkRetroactiveGamification() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.processRetroactiveGamification();
    } catch (e) {
      WasteAppLogger.warning('Retroactive gamification check failed', error: e);
    }
  }
}

/// Lightweight data classes for card sections.
class _SnapshotItem {
  const _SnapshotItem(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}
