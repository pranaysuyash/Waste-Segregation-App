import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/result_pipeline.dart';
import '../services/haptic_settings_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../screens/educational_content_screen.dart';
import '../widgets/result_screen/result_header.dart';
import '../widgets/result_screen/disposal_accordion.dart';
import '../widgets/result_screen/action_row.dart';
import '../widgets/result_screen/points_popup.dart';
import '../widgets/result_screen/achievement_wrapper.dart';
import '../utils/waste_app_logger.dart';
import '../config/debug_config.dart';

/// ResultScreenV2 - New composable result screen implementation
///
/// Features:
/// - Composable widget architecture with separation of concerns
/// - Material 3 design principles with proper theming
/// - Progressive disclosure with collapsible sections
/// - Clean integration with ResultPipeline for business logic
class ResultScreenV2 extends ConsumerStatefulWidget {
  const ResultScreenV2({
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
  ConsumerState<ResultScreenV2> createState() => _ResultScreenV2State();
}

class _ResultScreenV2State extends ConsumerState<ResultScreenV2>
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

    // Initialize analytics (will be properly initialized with context)
    _analyticsService = AnalyticsService(StorageService());

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

    // Process classification through pipeline
    _processClassification();

    // Track screen view
    _trackScreenView();
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
      WasteAppLogger.severe('Failed to process classification in pipeline',
          error: error,
          stackTrace: stackTrace,
          context: {
            'classificationId': widget.classification.id,
            'service': 'ResultScreenV2',
          });
    }
  }

  void _trackScreenView() {
    // Use Legacy event name for parity
    _analyticsService.trackScreenView('ResultScreen', parameters: {
      'classification_id': widget.classification.id,
      'category': widget.classification.category,
      'item_name': widget.classification.itemName,
      'confidence': widget.classification.confidence,
      'show_actions': widget.showActions,
      'auto_analyze': widget.autoAnalyze,
      'version': 'v2',
    });
    
    // Also log for debugging
    WasteAppLogger.aiEvent('result_screen_viewed', context: {
      'classificationId': widget.classification.id,
      'category': widget.classification.category,
      'version': 'v2',
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pipelineState = ref.watch(resultPipelineProvider);
    
    // Process gamification when pipeline completes
    _processGamificationState(pipelineState);

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
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: _handleReanalyze,
                ),
                actions: widget.showActions
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: colorScheme.onSurface,
                          ),
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
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: Curves.easeOutCubic,
                  )),
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
                            // Disposal Instructions Accordion
                            DisposalAccordion(
                              classification: widget.classification,
                            ),

                            const SizedBox(height: 16),

                            // Why This Classification Card
                            _buildWhyCard(context),

                            const SizedBox(height: 24),

                            // Secondary Actions
                            if (widget.showActions) ...[
                              ActionRow(
                                onShare: _handleShare,
                                onCorrect: _handleCorrection,
                                onSave: _handleSave,
                              ),
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
    return Stack(
      children: [
        scaffold,
        buildAchievementCelebration(),
      ],
    );
  }

  Widget _buildWhyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: colorScheme.primary,
                  size: 20,
                ),
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
                    Icon(
                      Icons.school,
                      size: 16,
                      color: colorScheme.primary,
                    ),
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
  
  void _handleEducationalContent() {
    // Track user action (Legacy parity)
    _analyticsService.trackUserAction('educational_content_viewed', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    
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
      showAchievementCelebration(state.newAchievements);
    }
    
    // Trigger haptic feedback on successful save
    if (state.isSaved) {
      _triggerHapticFeedback();
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
        WasteAppLogger.aiEvent('points_popup_shown', context: {
          'classificationId': widget.classification.id,
          'points': points,
          'version': 'v2',
        });
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
    _analyticsService.trackUserAction('dispose_correctly_tapped', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    
    // Also log for debugging
    WasteAppLogger.aiEvent('dispose_correctly_tapped', context: {
      'classificationId': widget.classification.id,
      'category': widget.classification.category,
      'version': 'v2',
    });

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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
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
    _analyticsService.trackUserAction('correction_requested', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    
    // Also log for debugging
    WasteAppLogger.aiEvent('correction_requested', context: {
      'classificationId': widget.classification.id,
      'version': 'v2',
    });

    // TODO: Implement correction dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Correction feature coming soon!'),
      ),
    );
  }

  void _handleSave() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.saveClassificationOnly(widget.classification);

      // Track user action (Legacy parity)
      _analyticsService.trackUserAction('classification_save', parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      });

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

  void _handleShare() async {
    try {
      final pipeline = ref.read(resultPipelineProvider.notifier);
      await pipeline.shareClassification(widget.classification);

      // Track user action (Legacy parity)
      _analyticsService.trackUserAction('classification_share', parameters: {
        'category': widget.classification.category,
        'item': widget.classification.itemName,
      });

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
    _analyticsService.trackUserAction('classification_reanalyze', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    
    // Navigate back to camera
    Navigator.of(context).pop();
  }
}
