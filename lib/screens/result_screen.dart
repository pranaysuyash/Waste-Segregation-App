import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/result_pipeline.dart';
import '../services/haptic_settings_service.dart';
import '../services/analytics_service.dart';
import '../providers/app_providers.dart';
import '../screens/educational_content_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/disposal_facilities_screen.dart';
import '../screens/waste_dashboard_screen.dart';
import '../widgets/result_screen/result_header.dart';
import '../widgets/result_screen/disposal_accordion.dart';
import '../widgets/result_screen/action_row.dart';
import '../widgets/result_screen/points_popup.dart';
import '../widgets/result_screen/achievement_wrapper.dart';
import '../widgets/result_screen/staggered_list.dart';
import '../widgets/interactive_tag.dart';
import '../widgets/correction_dialog.dart';
import '../utils/classification_tags.dart';
import '../utils/waste_app_logger.dart';
import '../config/debug_config.dart';

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

  // Gamification state
  bool _hasShownPointsPopup = false;
  bool _hasProcessedGamification = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> _processClassification() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.processClassification(
        widget.classification,
        autoAnalyze: widget.autoAnalyze,
      );
    } catch (error, stackTrace) {
      WasteAppLogger.severe(
        'Failed to process classification in pipeline',
        error: error,
        stackTrace: stackTrace,
        context: {
          'classificationId': widget.classification.id,
          'service': 'ResultScreen',
        },
      );
    }
  }

  void _trackScreenView() {
    // Use Legacy event name for parity
    _analyticsService.trackScreenView(
      'ResultScreen',
      parameters: {
        'classification_id': widget.classification.id,
        'category': widget.classification.category,
        'item_name': widget.classification.itemName,
        'confidence': widget.classification.confidence,
        'show_actions': widget.showActions,
        'auto_analyze': widget.autoAnalyze,
        'version': 'v2',
      },
    );

    // Also log for debugging
    WasteAppLogger.aiEvent(
      'result_screen_viewed',
      context: {
        'classificationId': widget.classification.id,
        'category': widget.classification.category,
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
    final tags = buildClassificationTags(widget.classification);
    final hasLowConfidence = (widget.classification.confidence ?? 1.0) < 0.7;

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
                        classification: widget.classification,
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
                            // Loading indicator
                            if (pipelineState.isProcessing)
                              _buildLoadingIndicator(context),

                            // Low-confidence warning banner
                            if (hasLowConfidence)
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
                              classification: widget.classification,
                            ),

                            const SizedBox(height: 16),

                            // Why This Classification Card + educational fact
                            _buildWhyCard(context),
                            if (_buildStoryCards(context) != null) ...[
                              const SizedBox(height: 16),
                              _buildStoryCards(context)!,
                            ],

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
                            if (_hasMaterialsPreview(
                              widget.classification,
                            )) ...[
                              const SizedBox(height: 16),
                              _buildMaterialsPreview(context),
                            ],

                            // Disposal Checklist
                            if (_hasDisposalChecklist(
                              widget.classification,
                            )) ...[
                              const SizedBox(height: 16),
                              _buildDisposalChecklist(context),
                            ],

                            // Local Rules (BBMP)
                            if (_hasLocalRules(widget.classification)) ...[
                              const SizedBox(height: 16),
                              _buildLocalRulesCard(context),
                            ],

                            // Safety Warnings
                            if (_hasSafetyWarnings(widget.classification)) ...[
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

  Widget _buildWhyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Why this classification?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI analyzed the visual characteristics, material properties, and recycling guidelines to determine this classification with ${((widget.classification.confidence ?? 0.0) * 100).toInt()}% confidence.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            // Educational content link
            InkWell(
              onTap: _handleEducationalContent,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.school, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Learn more about ${widget.classification.category}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Powered by AI Classification',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Low-confidence warning banner with re-analyze action.
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
                  'Low confidence (${((widget.classification.confidence ?? 0.0) * 100).toInt()}%)',
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
                  'original_confidence':
                      widget.classification.confidence.toString(),
                  'category': widget.classification.category,
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

  /// Educational "Did You Know?" story card, ported from v1.
  Widget? _buildStoryCards(BuildContext context) {
    final theme = Theme.of(context);
    final fact = educationalFact(widget.classification);
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
              child: Text(
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

  /// Find disposal facilities action.
  void _handleFindFacility() {
    _analyticsService.trackUserAction(
      'find_facility',
      parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
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
      parameters: {'category': widget.classification.category},
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

  void _handleEducationalContent() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction(
      'educational_content_viewed',
      parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      },
    );

    // Navigate to educational content
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EducationalContentScreen()),
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
      classificationId: widget.classification.id,
      pointsEarned: state.pointsEarned,
      achievementsCount: state.newAchievements.length,
      isSaved: state.isSaved,
    );
  }

  /// Show animated points popup
  void _showPointsPopup(int points) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.showPointsPopup(points);

        // Log analytics
        WasteAppLogger.aiEvent(
          'points_popup_shown',
          context: {
            'classificationId': widget.classification.id,
            'points': points,
            'version': 'v2',
          },
        );
      }
    });
  }

  /// Trigger haptic feedback
  void _triggerHapticFeedback() {
    try {
      final haptic = HapticSettingsService();
      if (haptic.enabled &&
          widget.classification.category != 'Requires Manual Review') {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Haptic feedback is non-critical
      WasteAppLogger.warning('Haptic feedback failed', error: e);
    }
  }

  void _handleDisposeCorrectly() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction(
      'dispose_correctly_tapped',
      parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      },
    );

    // Also log for debugging
    WasteAppLogger.aiEvent(
      'dispose_correctly_tapped',
      context: {
        'classificationId': widget.classification.id,
        'category': widget.classification.category,
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
                        classification: widget.classification,
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

  void _handleCorrection() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction(
      'correction_requested',
      parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      },
    );

    // Also log for debugging
    WasteAppLogger.aiEvent(
      'correction_requested',
      context: {'classificationId': widget.classification.id, 'version': 'v2'},
    );

    showDialog<bool>(
      context: context,
      builder: (context) =>
          CorrectionDialog(classification: widget.classification),
    );
  }

  Future<void> _handleSave() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.saveClassificationOnly(widget.classification);
      _triggerHapticFeedback();

      // Track user action (Legacy parity)
      await _analyticsService.trackUserAction(
        'classification_save',
        parameters: {
          'category': widget.classification.category,
          'item': widget.classification.itemName,
        },
      );

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
      await pipeline.shareClassification(widget.classification);

      // Track user action (Legacy parity)
      await _analyticsService.trackUserAction(
        'classification_share',
        parameters: {
          'category': widget.classification.category,
          'item': widget.classification.itemName,
        },
      );

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
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      },
    );

    // Navigate back to camera
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Ported features from v1
  // ---------------------------------------------------------------------------

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactReveal(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final impact = widget.classification.getEnvironmentalImpactScore().clamp(
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
              _formatCo2Impact(widget.classification),
            ),
            _buildInfoRow(
              context,
              Icons.timelapse,
              'Decomposition',
              _formatDecompositionTime(widget.classification),
            ),
            _buildInfoRow(
              context,
              Icons.recycling,
              'Recyclability',
              _formatRecyclability(widget.classification),
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
    final c = widget.classification;
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
    final c = widget.classification;
    final items = <_SnapshotItem>[
      _SnapshotItem('Recyclable', _boolLabel(c.isRecyclable), Icons.recycling),
      _SnapshotItem('Compostable', _boolLabel(c.isCompostable), Icons.compost),
      _SnapshotItem(
        'Special Disposal',
        _boolLabel(c.requiresSpecialDisposal),
        Icons.warning_amber,
      ),
      _SnapshotItem('Risk Level', c.riskLevel ?? 'Unknown', Icons.report),
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

  Widget _buildMaterialsPreview(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = widget.classification;
    final materials = c.normalizedMaterials;
    final alternatives = c.alternativeOptions ?? const <String>[];
    final relatedItems = c.relatedItems ?? const <String>[];

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
                Icon(Icons.layers_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Materials & Alternatives',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (materials.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow('Materials', materials),
            ],
            if (materials.isEmpty) ...[
              const SizedBox(height: 12),
              _buildEmptyFieldNote('Materials unavailable'),
            ],
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow('Alternatives', alternatives),
            ],
            if (relatedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildChipRow('Related', relatedItems),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipRow(String label, List<String> items) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.take(6).map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyFieldNote(String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  bool _hasMaterialsPreview(WasteClassification c) {
    final materials = c.normalizedMaterials;
    return materials.isNotEmpty ||
        (c.alternativeOptions?.isNotEmpty == true) ||
        (c.relatedItems?.isNotEmpty == true);
  }

  Widget _buildDisposalChecklist(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final steps = widget.classification.disposalInstructions.steps;
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

  Widget _buildLocalRulesCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = widget.classification;
    final regs = c.localRegulations ?? const <String, String>{};
    final bbmp = c.bbmpComplianceStatus;
    final guideline = c.localGuidelinesReference;

    if (regs.isEmpty &&
        (bbmp == null || bbmp.isEmpty) &&
        (guideline == null || guideline.isEmpty)) {
      return const SizedBox.shrink();
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
                Icon(Icons.gavel, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Local Rules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (bbmp != null && bbmp.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRuleRow('Compliance', bbmp),
            ],
            if (guideline != null && guideline.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRuleRow('Guideline', guideline),
            ],
            if (regs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...regs.entries.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildRuleRow(e.key, e.value),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
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
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasLocalRules(WasteClassification c) {
    return (c.localRegulations?.isNotEmpty == true) ||
        (c.bbmpComplianceStatus?.isNotEmpty == true) ||
        (c.localGuidelinesReference?.isNotEmpty == true);
  }

  Widget _buildSafetyWarnings(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = widget.classification;
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
        widget.classification.disposalInstructions.warnings ?? const <String>[];
    final hints =
        widget.classification.disposalInstructions.tips ?? const <String>[];
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
    final confidence = widget.classification.confidence ?? 0.0;
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
