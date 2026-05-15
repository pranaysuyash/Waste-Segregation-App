import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/share_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../models/classification_feedback.dart';
import '../services/cloud_storage_service.dart';
import '../utils/app_version.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../widgets/enhanced_gamification_widgets.dart' as widgets;
import '../widgets/advanced_ui/achievement_celebration.dart';
import '../widgets/interactive_tag.dart';
import '../widgets/enhanced_disposal_instructions_widget.dart';
import '../widgets/classification_feedback_widget.dart';
import '../widgets/expandable_section.dart';
import '../widgets/result_screen/action_buttons.dart';
import '../widgets/result_screen/classification_card.dart';
import '../widgets/result_screen/staggered_list.dart';
import '../widgets/result_screen/enhanced_reanalysis_widget.dart';
import '../widgets/modern_ui/modern_cards.dart'
    show StatsCard, Trend, ModernCard;
import '../widgets/modern_ui/modern_buttons.dart';
import '../widgets/enhanced_analysis_loader.dart';
import '../screens/waste_dashboard_screen.dart';
import '../widgets/modern_ui/modern_info_tile.dart';
import '../widgets/advanced_ui/impact_visualization_ring.dart';
import '../services/analytics_service.dart';
import '../services/dynamic_link_service.dart';
import '../screens/image_capture_screen.dart';
import '../screens/disposal_facilities_screen.dart';
import '../screens/educational_content_screen.dart';
import '../services/haptic_settings_service.dart';
import '../utils/waste_app_logger.dart';
import '../models/gamification_result.dart';
import '../providers/points_engine_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.classification,
    this.showActions = true,
    this.autoAnalyze = false,
  });
  final WasteClassification classification;
  final bool showActions;
  final bool autoAnalyze;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isAutoSaving = false;
  bool _showingClassificationFeedback = false;

  List<Achievement> _newlyEarnedAchievements = [];
  int _pointsEarned = 0;
  Challenge? _completedChallenge;

  // Achievement celebration state
  bool _showCelebration = false;
  Achievement? _celebrationAchievement;

  // Static set to track classifications being saved to prevent duplicates
  static final Set<String> _savingClassifications = <String>{};

  late AnimationController _animationController;
  late AnalyticsService _analyticsService;
  late final PageController _insightsController;
  int _insightsPage = 0;

  @override
  void initState() {
    super.initState();
    _analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    // Track screen view with classification details
    _analyticsService.trackScreenView('ResultScreen', parameters: {
      'classification_id': widget.classification.id,
      'category': widget.classification.category,
      'item_name': widget.classification.itemName,
      'show_actions': widget.showActions,
      'confidence': widget.classification.confidence,
      'auto_analyze': widget.autoAnalyze,
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _insightsController = PageController();

    // Process the classification for gamification only if it's a new classification
    // Skip auto-save processing for autoAnalyze mode since it's already saved in InstantAnalysisScreen
    if (widget.showActions && !widget.autoAnalyze) {
      _autoSaveAndProcess();
    } else if (widget.autoAnalyze) {
      // For autoAnalyze mode, the classification is already saved and processed
      // But we need to show the points popup, so calculate the points earned
      _showPointsForAutoAnalyze();
    } else {
      // 🎮 GAMIFICATION FIX: For existing classifications, check if they need
      // retroactive gamification processing (fixes the 2/10 classifications but 0 points issue)
      _checkRetroactiveGamificationProcessing();
    }
  }

  // Automatically save the classification and process gamification sequentially
  Future<void> _autoSaveAndProcess() async {
    if (!widget.showActions || _isSaved) return;

    final classificationId = widget.classification.id;
    if (_savingClassifications.contains(classificationId)) {
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});
      return;
    }

    _savingClassifications.add(classificationId);
    if (mounted) setState(() => _isAutoSaving = true);

    try {
      // Step 1: Get services
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      // Step 2: Save classification locally
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});
      final savedClassification = widget.classification.copyWith(isSaved: true);
      await storageService.saveClassification(savedClassification,
          force: widget.autoAnalyze);
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});

      // Step 3: Process for gamification (points, achievements)
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});
      final oldProfile = await gamificationService.getProfile();
      await gamificationService.processClassification(savedClassification);
      final newProfile =
          await gamificationService.getProfile(forceRefresh: true);
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});

      // Step 4: Sync to cloud
      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      if (isGoogleSyncEnabled) {
        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});
        await cloudStorageService.saveClassificationWithSync(
          savedClassification,
          isGoogleSyncEnabled,
          processGamification: false, // Already processed
        );
        await gamificationService
            .saveProfile(newProfile); // Explicitly save updated profile
        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});
      } else {
        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});
      }

      // Step 5: Update UI
      final earnedPoints = newProfile.points.total - oldProfile.points.total;

      // Correctly and efficiently calculate newly earned achievements
      final oldAchievementIds =
          oldProfile.achievements.map((a) => a.id).toSet();
      final newlyEarnedAchievements = newProfile.achievements
          .where((a) => a.isEarned && !oldAchievementIds.contains(a.id))
          .toList();

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isAutoSaving = false;
          _pointsEarned = earnedPoints;
          _newlyEarnedAchievements = newlyEarnedAchievements;
          _completedChallenge = newProfile.completedChallenges
              .where((c) => !oldProfile.completedChallenges
                  .map((oc) => oc.id)
                  .contains(c.id))
              .firstOrNull;

          // Show achievement celebration for major achievements
          if (newlyEarnedAchievements.isNotEmpty) {
            final majorAchievement = newlyEarnedAchievements.firstWhere(
              (a) => a.tier != AchievementTier.bronze || a.pointsReward >= 25,
              orElse: () => newlyEarnedAchievements.first,
            );
            _showAchievementCelebration(majorAchievement);
          }

          // ROADMAP FIX: Show points popup with proper timing to avoid race condition
          if (earnedPoints > 0) {
            _showPointsEarnedPopup(earnedPoints);
          }

          WasteAppLogger.info(
              'Points earned: $earnedPoints, error: Achievements: ${newlyEarnedAchievements.length}');
        });

        // Show feedback
        final syncMessage =
            isGoogleSyncEnabled ? 'Saved and synced!' : 'Saved locally!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(syncMessage),
          backgroundColor: _getCategoryColor(widget.classification.category),
        ));

        final haptic = context.read<HapticSettingsService>();
        if (haptic.enabled &&
            widget.classification.category != 'Requires Manual Review') {
          HapticFeedback.lightImpact();
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${ErrorHandler.getUserFriendlyMessage(e)}'),
        ));
      }
    } finally {
      _savingClassifications.remove(classificationId);
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }

  @override
  void dispose() {
    _insightsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showAchievementCelebration(Achievement achievement) {
    setState(() {
      _celebrationAchievement = achievement;
      _showCelebration = true;
    });
  }

  void _onCelebrationDismissed() {
    setState(() {
      _showCelebration = false;
      _celebrationAchievement = null;
    });
  }

  /// Return gamification results when navigating back to home screen
  void _navigateBackWithResults() {
    final result = GamificationResult(
      pointsEarned: _pointsEarned,
      newlyEarnedAchievements: _newlyEarnedAchievements,
      completedChallenge: _completedChallenge,
    );

    Navigator.of(context).pop(result);
  }

  /// Show points popup for autoAnalyze mode
  /// The classification is already saved and processed, we just need to trigger the popup
  Future<void> _showPointsForAutoAnalyze() async {
    try {
      WasteAppLogger.info(
          '🎯 POPUP FIX: Triggering points popup for autoAnalyze mode');

      // Get the PointsEngine to trigger the global popup system
      final pointsEngineProvider =
          Provider.of<PointsEngineProvider>(context, listen: false);
      final pointsEngine = pointsEngineProvider.pointsEngine;

      // Trigger the points earned event which will show the popup via navigation wrapper
      // Use standard classification points (consistent with GamificationService._pointValues)
      const pointsPerClassification = 10;
      await pointsEngine.addPoints('classification', metadata: {
        'source': 'instant_analysis',
        'classification_id': widget.classification.id,
        'category': widget.classification.category,
      });

      setState(() {
        _isSaved = true;
        _pointsEarned = pointsPerClassification;
      });

      WasteAppLogger.info(
          '🎯 POPUP FIX: Points popup triggered via PointsEngine - $pointsPerClassification points');
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      WasteAppLogger.severe('🎯 POPUP FIX: Error triggering points popup: $e');

      // Fallback to standard points if PointsEngine fails
      setState(() {
        _isSaved = true;
        _pointsEarned = 10; // Standard classification points
      });
    }
  }

  /// ROADMAP FIX: Show points earned popup with proper timing to avoid race condition
  Future<void> _showPointsEarnedPopup(int points) async {
    // Wait for navigation and UI to complete to avoid race condition
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && Navigator.of(context).canPop()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Points Earned!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+$points points',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Great job classifying waste!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  /// Check if this existing classification needs retroactive gamification processing
  /// This fixes the issue where users have classifications but 0 points
  Future<void> _checkRetroactiveGamificationProcessing() async {
    try {
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});

      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      // Get current profile
      final profile = await gamificationService.getProfile();
      final currentPoints = profile.points.total;

      // Get all classifications
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final allClassifications = await storageService.getAllClassifications();

      // If user has classifications but 0 points, they need retroactive processing
      if (allClassifications.isNotEmpty && currentPoints == 0) {
        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});

        // Process all classifications for gamification
        for (final classification in allClassifications) {
          await gamificationService.processClassification(classification);
        }

        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});
      } else {
        WasteAppLogger.info('Operation completed',
            context: {'service': 'screen', 'file': 'result_screen'});
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      WasteAppLogger.severe('Error occurred',
          context: {'service': 'screen', 'file': 'result_screen'});
    }
  }

  Future<void> _saveResult() async {
    _analyticsService.trackUserAction('classification_save', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    if (_isSaved || _isAutoSaving) return;

    setState(() => _isAutoSaving = true);

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final savedClassification = widget.classification.copyWith(isSaved: true);
      await storageService.saveClassification(savedClassification,
          force: widget.autoAnalyze);

      setState(() {
        _isSaved = true;
        _isAutoSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        final haptic = context.read<HapticSettingsService>();
        if (haptic.enabled &&
            widget.classification.category != 'Requires Manual Review') {
          HapticFeedback.lightImpact();
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      setState(() => _isAutoSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error saving: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareResult() async {
    if (_isAutoSaving) return;

    _analyticsService.trackUserAction('classification_share', parameters: {
      'category': widget.classification.category,
      'item': widget.classification.itemName,
    });
    try {
      final link = DynamicLinkService.createResultLink(widget.classification);
      await ShareService.share(
        text:
            'I identified ${widget.classification.itemName} as ${widget.classification.category} waste using the Waste Segregation app!\n$link',
        subject: 'Waste Classification Result',
        context: context,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error sharing: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAchievementDetails(dynamic achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.name),
        content: Text(achievement.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<TagData> _buildInteractiveTags() {
    final tags = <TagData>[];
    tags.add(TagFactory.category(widget.classification.category));
    if (widget.classification.materialType != null) {
      tags.add(TagFactory.material(widget.classification.materialType!));
    }

    _addEnvironmentalImpactTags(tags);
    _addLocalInformationTags(tags);
    _addUrgencyTags(tags);
    _addEducationalTips(tags);

    return tags;
  }

  void _addEnvironmentalImpactTags(List<TagData> tags) {
    final co2Savings = _calculateCO2Savings();
    final waterSavings = _calculateWaterSavings();
    final difficulty = _getRecyclingDifficulty();

    if (co2Savings > 0) {
      tags.add(TagFactory.environmentalImpact(
          '${co2Savings}kg CO₂ saved', Colors.green));
    }

    if (waterSavings > 0) {
      tags.add(TagFactory.environmentalImpact(
          '${waterSavings}L water saved', Colors.blue));
    }

    tags.add(TagFactory.recyclingDifficulty(difficulty.label, difficulty));
  }

  DifficultyLevel _getRecyclingDifficulty() {
    final category = widget.classification.category.toLowerCase();
    final material = widget.classification.materialType?.toLowerCase();

    if (category == 'hazardous waste' || category == 'medical waste') {
      return DifficultyLevel.expert;
    }

    if (material == 'plastic') {
      // Check recycling code for difficulty
      final code = widget.classification.recyclingCode;
      if (code == '1' || code == '2') return DifficultyLevel.easy;
      if (code == '5') return DifficultyLevel.medium;
      return DifficultyLevel.hard;
    }

    if (material == 'paper') return DifficultyLevel.easy;
    if (material == 'glass') return DifficultyLevel.medium;
    if (material == 'metal') return DifficultyLevel.easy;

    return DifficultyLevel.medium;
  }

  double _calculateCO2Savings() {
    final category = widget.classification.category.toLowerCase();
    switch (category) {
      case 'paper':
      case 'dry waste':
        return 2.3; // Average CO2 savings for recycling paper
      case 'plastic':
        return 1.8; // Average CO2 savings for recycling plastic
      case 'wet waste':
        return 0.5; // CO2 savings from composting vs landfill
      default:
        return 0.0;
    }
  }

  double _calculateWaterSavings() {
    final category = widget.classification.category.toLowerCase();
    switch (category) {
      case 'paper':
      case 'dry waste':
        return 45.0; // Liters saved by recycling paper
      case 'plastic':
        return 12.0; // Liters saved by recycling plastic
      default:
        return 0.0;
    }
  }

  void _addLocalInformationTags(List<TagData> tags) {
    final category = widget.classification.category.toLowerCase();

    switch (category) {
      case 'wet waste':
        tags.add(TagFactory.localInfo(
            'BBMP collects daily 6-10 AM', Icons.schedule));
        break;
      case 'dry waste':
        tags.add(TagFactory.localInfo(
            'BBMP dry waste: Mon, Wed, Fri', Icons.schedule));
        tags.add(
            TagFactory.nearbyFacility('Kabadiwala available', Icons.store));
        break;
      case 'hazardous waste':
        tags.add(TagFactory.nearbyFacility(
            'KSPCB facility - Bidadi', Icons.location_on));
        break;
    }
  }

  void _addUrgencyTags(List<TagData> tags) {
    final category = widget.classification.category.toLowerCase();

    if (category == 'medical waste') {
      tags.add(TagFactory.timeUrgent('Medical waste', UrgencyLevel.critical));
    } else if (category == 'hazardous waste') {
      tags.add(TagFactory.timeUrgent('Hazardous materials', UrgencyLevel.high));
    } else if (category == 'wet waste') {
      tags.add(TagFactory.timeUrgent('Prevent odors', UrgencyLevel.medium));
    }
  }

  void _addEducationalTips(List<TagData> tags) {
    final category = widget.classification.category.toLowerCase();
    final subcategory = widget.classification.subcategory?.toLowerCase();

    if (subcategory == 'plastic') {
      tags.add(
          TagFactory.didYouKnow('Remove caps before recycling', Colors.blue));
      tags.add(TagFactory.commonMistake(
          'Leaving food residue on containers', Colors.amber));
    } else if (subcategory == 'paper') {
      tags.add(TagFactory.didYouKnow(
          'Paper can be recycled 5-7 times', Colors.blue));
      tags.add(
          TagFactory.commonMistake('Mixing wet and dry paper', Colors.amber));
    } else if (category == 'wet waste') {
      tags.add(TagFactory.didYouKnow(
          'Composting creates nutrient-rich soil', Colors.green));
      tags.add(TagFactory.commonMistake(
          'Adding meat or oil to compost', Colors.amber));
    }
  }

  /// Get educational fact based on classification category
  String _getEducationalFact() {
    final category = widget.classification.category.toLowerCase();
    final subcategory = widget.classification.subcategory?.toLowerCase();

    if (subcategory == 'plastic') {
      return 'Plastic bottles can be recycled into new bottles, clothing, carpets, and even park benches! However, removing caps and labels before recycling helps ensure better quality recycled materials. Did you know that recycling one plastic bottle saves enough energy to power a 60-watt light bulb for 3 hours?';
    } else if (subcategory == 'paper') {
      return 'Paper can be recycled 5-7 times before the fibers become too short to make new paper. Recycling one ton of paper saves 17 trees, 7,000 gallons of water, and enough energy to power an average home for 6 months. However, wet or food-contaminated paper cannot be recycled and should go to compost instead.';
    } else if (category == 'wet waste') {
      return 'Composting organic waste reduces methane emissions from landfills by up to 50%! Home composting can divert 30% of household waste from landfills while creating nutrient-rich soil for plants. Avoid adding meat, dairy, or oily foods to compost as they can attract pests and slow decomposition.';
    } else if (category == 'hazardous waste') {
      return 'Hazardous waste like batteries, electronics, and chemicals require special handling to prevent soil and water contamination. One improperly disposed battery can contaminate 20 square meters of soil for decades. Always use designated collection centers for safe disposal.';
    } else if (category == 'e-waste') {
      return 'Electronic waste contains valuable materials like gold, silver, and rare earth elements. Recycling 1 million cell phones recovers 35,000 pounds of copper, 772 pounds of silver, 75 pounds of gold, and 33 pounds of palladium! Proper e-waste recycling also prevents toxic materials from entering landfills.';
    } else {
      return 'Proper waste segregation is the first step toward a circular economy. When we sort waste correctly, we enable better recycling, reduce landfill burden, and conserve natural resources. Every small action contributes to a more sustainable future for our planet.';
    }
  }

  Widget _buildDetailsSection(
      BuildContext context, WasteClassification classification) {
    final confidence = classification.confidence;
    return ModernCard(
      child: ExpansionTile(
        title: const Text(
          'Detailed Analysis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        initiallyExpanded: true,
        children: [
          if (confidence != null && confidence < 0.6)
            ModernCard(
              backgroundColor: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.orange.shade800),
                title: Text('Low confidence (${(confidence * 100).round()}%)'),
                subtitle: const Text('You may want to re-analyze this item.'),
              ),
            ),
          ModernInfoTile(
              icon: Icons.loop,
              label: 'Use Type',
              value: classification.isSingleUse == true
                  ? 'Single-Use'
                  : 'Reusable / Multi-Use'),
          ModernInfoTile(
            icon: Icons.eco,
            label: 'Environmental Impact',
            value: classification.environmentalImpact ?? 'Not available',
          ),
          ModernInfoTile(
            icon: Icons.recycling,
            label: 'Recyclable',
            value: classification.isRecyclable == null
                ? 'Unknown'
                : (classification.isRecyclable! ? 'Yes' : 'No'),
            valueColor: classification.isRecyclable == null
                ? null
                : (classification.isRecyclable! ? Colors.green : Colors.red),
          ),
          ModernInfoTile(
            icon: Icons.compost,
            label: 'Compostable',
            value: classification.isCompostable == null
                ? 'Unknown'
                : (classification.isCompostable! ? 'Yes' : 'No'),
            valueColor: classification.isCompostable == null
                ? null
                : (classification.isCompostable! ? Colors.green : Colors.red),
          ),
          ModernInfoTile(
            icon: Icons.warning_amber,
            label: 'Risk Level',
            value: classification.riskLevel ?? 'Not assessed',
          ),
          if (classification.requiredPPE != null &&
              classification.requiredPPE!.isNotEmpty)
            ModernInfoTile(
              icon: Icons.health_and_safety,
              label: 'Required PPE',
              value: classification.requiredPPE!.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildImpactRevealSection(WasteClassification classification) {
    final theme = Theme.of(context);
    final impactScore = classification
        .getEnvironmentalImpactScore()
        .clamp(1.0, 10.0)
        .toDouble();
    final ecoScore = (10.0 - impactScore).clamp(0.0, 10.0).toDouble();
    final ecoProgress = ecoScore / 10.0;

    return ModernCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.08),
          AppTheme.secondaryColor.withValues(alpha: 0.12),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.rewardGold),
              const SizedBox(width: 8),
              Text(
                'Impact Reveal',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ImpactVisualizationRing(
            progress: ecoProgress,
            targetValue: 10.0,
            currentValue: ecoScore,
            unit: 'eco score',
            centerText: ecoScore.toStringAsFixed(1),
            title: 'Eco Score',
            subtitle: 'Lower impact is better',
          ),
          const SizedBox(height: 16),
          ModernInfoTile(
            icon: Icons.cloud_outlined,
            label: 'CO2 impact',
            value: _formatCo2Impact(classification),
          ),
          ModernInfoTile(
            icon: Icons.timelapse,
            label: 'Decomposition',
            value: _formatDecompositionTime(classification),
          ),
          ModernInfoTile(
            icon: Icons.recycling,
            label: 'Recyclability',
            value: _formatRecyclability(classification),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactJourneySection(WasteClassification classification) {
    final theme = Theme.of(context);
    final steps = [
      _JourneyStep(
        icon: Icons.label_outline,
        title: 'Sorted as',
        detail: classification.category,
      ),
      _JourneyStep(
        icon: Icons.build_circle_outlined,
        title: 'Processing',
        detail: classification.disposalInstructions.primaryMethod,
      ),
      _JourneyStep(
        icon: Icons.auto_awesome,
        title: 'Next life',
        detail: _nextLifeText(classification),
      ),
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Impact Journey',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSm),
                    ),
                    child: Icon(step.icon,
                        color: AppTheme.secondaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.detail,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _nextLifeText(WasteClassification classification) {
    final category = classification.category.toLowerCase();
    if (category.contains('wet')) {
      return 'Compost or biogas feedstock';
    }
    if (category.contains('dry')) {
      return 'Recycled into new materials';
    }
    if (category.contains('hazard')) {
      return 'Safely treated at hazardous facility';
    }
    if (category.contains('medical')) {
      return 'Special medical waste treatment';
    }
    if (category.contains('non-waste')) {
      return 'Reuse or donation pathway';
    }
    return 'Proper disposal route';
  }

  Widget _buildCategorySnapshot(WasteClassification classification) {
    final theme = Theme.of(context);
    final items = <_SnapshotItem>[
      _SnapshotItem(
        label: 'Recyclable',
        value: _boolLabel(classification.isRecyclable),
        icon: Icons.recycling,
      ),
      _SnapshotItem(
        label: 'Compostable',
        value: _boolLabel(classification.isCompostable),
        icon: Icons.compost,
      ),
      _SnapshotItem(
        label: 'Special Disposal',
        value: _boolLabel(classification.requiresSpecialDisposal),
        icon: Icons.warning_amber,
      ),
      _SnapshotItem(
        label: 'Risk Level',
        value: classification.riskLevel ?? 'Unknown',
        icon: Icons.report,
      ),
      if (classification.recyclingCode != null)
        _SnapshotItem(
          label: 'Recycling Code',
          value: classification.recyclingCode.toString(),
          icon: Icons.qr_code_2,
        ),
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Category Snapshot',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
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
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _boolLabel(bool? value) {
    if (value == null) {
      return 'Unknown';
    }
    return value ? 'Yes' : 'No';
  }

  Color _snapshotColor(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'yes') {
      return AppTheme.wetWasteColor;
    }
    if (normalized == 'no') {
      return AppTheme.hazardousWasteColor;
    }
    if (normalized.contains('unknown')) {
      return AppTheme.secondaryColor;
    }
    return AppTheme.rewardGold;
  }

  Widget _buildImpactActions(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Next Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Find Facility',
                  icon: Icons.location_on_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DisposalFacilitiesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: ModernButton(
                  text: 'Learn More',
                  icon: Icons.school_outlined,
                  style: ModernButtonStyle.outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EducationalContentScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionStrip(BuildContext context) {
    return ModernCard(
      child: Row(
        children: [
          Expanded(
            child: ModernButton(
              text: 'Scan Another',
              icon: Icons.camera_alt_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageCaptureScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: ModernButton(
              text: 'Share Result',
              icon: Icons.share_outlined,
              style: ModernButtonStyle.outlined,
              onPressed: _shareResult,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableInsights(WasteClassification classification) {
    final items = <_InsightItem>[
      _InsightItem(
          height: 300, child: _buildImpactJourneySection(classification)),
      _InsightItem(height: 280, child: _buildCategorySnapshot(classification)),
      if (_hasMaterialsPreview(classification))
        _InsightItem(
            height: 280, child: _buildMaterialsPreview(classification)),
      if (_hasDisposalChecklist(classification))
        _InsightItem(
            height: 320,
            child: _buildDisposalChecklist(classification, maxSteps: 3)),
      if (_hasLocalRules(classification))
        _InsightItem(height: 300, child: _buildLocalRulesCard(classification)),
      if (_hasSafetyWarnings(classification))
        _InsightItem(height: 280, child: _buildSafetyWarnings(classification)),
      _InsightItem(height: 240, child: _buildImpactBadges(classification)),
      _InsightItem(height: 280, child: _buildContaminationTips(classification)),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: items[_insightsPage.clamp(0, items.length - 1)].height,
          child: PageView.builder(
            controller: _insightsController,
            itemCount: items.length,
            onPageChanged: (index) {
              if (mounted) {
                HapticFeedback.selectionClick();
                setState(() {
                  _insightsPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: items[index].child,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final isActive = index == _insightsPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.secondaryColor
                    : AppTheme.secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }

  bool _hasMaterialsPreview(WasteClassification classification) {
    final materials = classification.materials ??
        (classification.materialType != null
            ? [classification.materialType!]
            : []);
    final alternatives = classification.alternativeOptions ?? const <String>[];
    final relatedItems = classification.relatedItems ?? const <String>[];
    return materials.isNotEmpty ||
        alternatives.isNotEmpty ||
        relatedItems.isNotEmpty;
  }

  bool _hasDisposalChecklist(WasteClassification classification) {
    return classification.disposalInstructions.steps.isNotEmpty;
  }

  bool _hasLocalRules(WasteClassification classification) {
    final regulations =
        classification.localRegulations ?? const <String, String>{};
    final bbmpStatus = classification.bbmpComplianceStatus;
    final guidelineRef = classification.localGuidelinesReference;
    return regulations.isNotEmpty ||
        (bbmpStatus != null && bbmpStatus.isNotEmpty) ||
        (guidelineRef != null && guidelineRef.isNotEmpty);
  }

  bool _hasSafetyWarnings(WasteClassification classification) {
    return classification.requiresSpecialDisposal == true ||
        (classification.requiredPPE != null &&
            classification.requiredPPE!.isNotEmpty) ||
        classification.hasUrgentTimeframe == true ||
        (classification.hazardLevel != null);
  }

  Widget _buildStoryCards(WasteClassification classification) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Story Highlights',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpandableSection(
            title: 'Explanation',
            content: classification.explanation,
            titleIcon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          ExpandableSection(
            title: 'Did You Know?',
            content: _getEducationalFact(),
            titleIcon: Icons.lightbulb_outline,
            trimLines: 2,
            titleColor: Colors.amber.shade700,
            backgroundColor: Colors.amber.shade50,
            borderColor: Colors.amber.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRibbon(WasteClassification classification) {
    final confidence = classification.confidence;
    final confidenceText = confidence == null
        ? 'Confidence: —'
        : 'Confidence: ${(confidence * 100).round()}%';
    final savedText =
        _isSaved ? 'Saved' : (_isAutoSaving ? 'Saving...' : 'Not saved');
    final pointsText =
        _pointsEarned > 0 ? '+$_pointsEarned points' : 'Points pending';

    return ModernCard(
      child: Row(
        children: [
          _buildRibbonChip(Icons.check_circle, savedText,
              _isSaved ? AppTheme.wetWasteColor : AppTheme.secondaryColor),
          const SizedBox(width: AppTheme.spacingSm),
          _buildRibbonChip(Icons.stars, pointsText, AppTheme.rewardGold),
          const SizedBox(width: AppTheme.spacingSm),
          _buildRibbonChip(
              Icons.psychology, confidenceText, AppTheme.secondaryColor),
        ],
      ),
    );
  }

  Widget _buildRibbonChip(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCo2Impact(WasteClassification classification) {
    final impact = classification.co2Impact;
    if (impact == null) {
      return 'Unknown';
    }
    if (impact <= 0) {
      return 'Low';
    }
    return '${impact.toStringAsFixed(1)} kg';
  }

  String _formatDecompositionTime(WasteClassification classification) {
    final value = classification.decompositionTime;
    if (value == null || value.trim().isEmpty) {
      return 'Unknown';
    }
    return value;
  }

  String _formatRecyclability(WasteClassification classification) {
    final explicit = classification.recyclability;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit;
    }
    if (classification.isRecyclable == true) {
      return 'Recyclable';
    }
    if (classification.isRecyclable == false) {
      return 'Not recyclable';
    }
    return 'Unknown';
  }

  Widget _buildImpactProgressCard(WasteClassification classification) {
    final theme = Theme.of(context);
    final impactScore = classification
        .getEnvironmentalImpactScore()
        .clamp(1.0, 10.0)
        .toDouble();
    final ecoScore = (10.0 - impactScore).clamp(0.0, 10.0).toDouble();
    final progress = ecoScore / 10.0;
    final color = _impactProgressColor(ecoScore);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: color),
              const SizedBox(width: 8),
              Text(
                'Eco Progress',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Score ${ecoScore.toStringAsFixed(1)} / 10',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _impactProgressColor(double ecoScore) {
    if (ecoScore >= 7.0) {
      return AppTheme.wetWasteColor;
    }
    if (ecoScore >= 4.0) {
      return AppTheme.rewardGold;
    }
    return AppTheme.hazardousWasteColor;
  }

  Widget _buildMaterialsPreview(WasteClassification classification) {
    final theme = Theme.of(context);
    final materials = classification.materials ??
        (classification.materialType != null
            ? [classification.materialType!]
            : []);
    final alternatives = classification.alternativeOptions ?? const <String>[];
    final relatedItems = classification.relatedItems ?? const <String>[];

    if (materials.isEmpty && alternatives.isEmpty && relatedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Materials & Alternatives',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (materials.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildChipRow('Materials', materials),
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
    );
  }

  Widget _buildChipRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.take(6).map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDisposalChecklist(WasteClassification classification,
      {int maxSteps = 5}) {
    final instructions = classification.disposalInstructions.steps;
    if (instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final steps = instructions.take(maxSteps).toList();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Disposal Checklist',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
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
                      color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppTheme.secondaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$index',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocalRulesCard(WasteClassification classification) {
    final regulations =
        classification.localRegulations ?? const <String, String>{};
    final bbmpStatus = classification.bbmpComplianceStatus;
    final guidelineRef = classification.localGuidelinesReference;

    if (regulations.isEmpty &&
        (bbmpStatus == null || bbmpStatus.isEmpty) &&
        (guidelineRef == null || guidelineRef.isEmpty)) {
      return const SizedBox.shrink();
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Local Rules',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (bbmpStatus != null && bbmpStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRuleRow('Compliance', bbmpStatus),
          ],
          if (guidelineRef != null && guidelineRef.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRuleRow('Guideline', guidelineRef),
          ],
          if (regulations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...regulations.entries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildRuleRow(entry.key, entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppTheme.secondaryColor,
            shape: BoxShape.circle,
          ),
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

  Widget _buildSafetyWarnings(WasteClassification classification) {
    final warnings = <String>[];
    if (classification.requiresSpecialDisposal == true) {
      warnings.add('Requires special disposal handling.');
    }
    if (classification.requiredPPE != null &&
        classification.requiredPPE!.isNotEmpty) {
      warnings.add('Use PPE: ${classification.requiredPPE!.join(', ')}.');
    }
    if (classification.hasUrgentTimeframe == true) {
      warnings.add('Time-sensitive disposal required.');
    }
    if (classification.hazardLevel != null && classification.hazardLevel! > 0) {
      warnings.add('Hazard level: ${classification.hazardLevel}.');
    }

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return ModernCard(
      backgroundColor: AppTheme.hazardousWasteColor.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppTheme.hazardousWasteColor),
              const SizedBox(width: 8),
              Text(
                'Safety Warnings',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map((warning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppTheme.hazardousWasteColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImpactBadges(WasteClassification classification) {
    final ecoScore = (10.0 - classification.getEnvironmentalImpactScore())
        .clamp(0.0, 10.0)
        .toDouble();
    final ecoLabel = 'Eco ${ecoScore.toStringAsFixed(1)}';
    final pointsLabel =
        _pointsEarned > 0 ? '+$_pointsEarned pts' : 'Points pending';
    final categoryLabel = classification.category;

    return ModernCard(
      child: Row(
        children: [
          _buildBadgeChip(Icons.park, ecoLabel, _impactProgressColor(ecoScore)),
          const SizedBox(width: AppTheme.spacingSm),
          _buildBadgeChip(Icons.stars, pointsLabel, AppTheme.rewardGold),
          const SizedBox(width: AppTheme.spacingSm),
          _buildBadgeChip(
              Icons.category, categoryLabel, AppTheme.secondaryColor),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContaminationTips(WasteClassification classification) {
    final tips = <String>[];
    final warnings =
        classification.disposalInstructions.warnings ?? const <String>[];
    final hints = classification.disposalInstructions.tips ?? const <String>[];

    tips.addAll(warnings.take(2));
    tips.addAll(hints.take(3));

    if (tips.isEmpty) {
      tips.addAll([
        'Keep recyclables clean and dry.',
        'Remove food residue before sorting.',
        'Avoid mixing different material types.',
      ]);
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cleaning_services,
                  color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Contamination Tips',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check,
                      size: 16, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Classification Result',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBackWithResults,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'View Waste Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WasteDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Visibility(
            visible: !_showingClassificationFeedback,
            child: _isAutoSaving
                ? const Center(child: EnhancedAnalysisLoader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Low confidence warning banner
                        if (widget.classification.confidence != null &&
                            widget.classification.confidence! < 0.7)
                          _buildLowConfidenceWarningBanner(),

                        ClassificationCard(
                          classification: widget.classification,
                          thumbnailBuilder: (size) => _buildThumbnail(size),
                          tags: _buildInteractiveTags(),
                        ),
                        const SizedBox(height: 16),
                        _buildImpactRevealSection(widget.classification),
                        const SizedBox(height: 16),
                        StaggeredList<TagData>(
                          items: _buildInteractiveTags(),
                          itemBuilder: (_, tag) => InteractiveTag(
                            text: tag.text,
                            color: tag.color,
                            icon: tag.icon,
                            textColor: tag.textColor,
                            action: tag.action,
                            category: tag.category,
                            subcategory: tag.subcategory,
                            isOutlined: tag.isOutlined,
                            onTap: tag.onTap,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ModernButton(
                          text: 'Re-analyze',
                          icon: Icons.refresh,
                          style: ModernButtonStyle.outlined,
                          onPressed: _isAutoSaving ? null : _reAnalyze,
                        ),
                        const SizedBox(height: 24),
                        _buildStoryCards(widget.classification),
                        const SizedBox(height: 24),
                        _buildImpactActions(context),
                        const SizedBox(height: 24),
                        _buildQuickActionStrip(context),
                        const SizedBox(height: 24),
                        _buildStatusRibbon(widget.classification),
                        const SizedBox(height: 24),
                        _buildImpactProgressCard(widget.classification),
                        const SizedBox(height: 24),
                        _buildSwipeableInsights(widget.classification),
                        const SizedBox(height: 24),
                        _buildDetailsSection(context, widget.classification),
                        const SizedBox(height: 24),
                        if (widget.showActions)
                          ActionButtons(
                            isSaved: _isSaved,
                            isAutoSaving: _isAutoSaving,
                            onSave: _saveResult,
                            onShare: _shareResult,
                          ),
                        const SizedBox(height: 24),
                        if (_pointsEarned > 0)
                          StatsCard(
                            title: 'Points Earned',
                            value: '$_pointsEarned',
                            icon: Icons.stars,
                            trend: Trend.up,
                          ),
                        if (_completedChallenge != null) ...[
                          const SizedBox(height: 16),
                          ModernCard(
                            child: ListTile(
                              leading: const Icon(Icons.emoji_events,
                                  color: Colors.amber, size: 32),
                              title: Text(_completedChallenge!.title),
                              subtitle: Text(_completedChallenge!.description),
                              onTap: () =>
                                  _showAchievementDetails(_completedChallenge!),
                            ),
                          )
                        ],
                        const SizedBox(height: 16),
                        ModernButton(
                          text: 'Back to Home',
                          icon: Icons.home,
                          style: ModernButtonStyle.outlined,
                          onPressed: _navigateBackWithResults,
                        ),
                        const SizedBox(height: 24),
                        ModernButton(
                          text: 'View Analytics',
                          icon: Icons.bar_chart,
                          style: ModernButtonStyle.outlined,
                          onPressed: () {
                            _analyticsService
                                .trackUserAction('view_analytics_dashboard');
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const WasteDashboardScreen()));
                          },
                        ),
                        const SizedBox(height: 24),
                        FutureBuilder<bool>(
                          future: widget.showActions
                              ? Future.value(true)
                              : _isRecentClassification(),
                          builder: (context, snapshot) {
                            if (!(snapshot.data ?? false)) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(top: 24),
                              child: ClassificationFeedbackWidget(
                                classification: widget.classification,
                                onFeedbackSubmitted: _handleFeedbackSubmission,
                                showCompactVersion: !widget.showActions,
                              ),
                            );
                          },
                        ),
                        // Enhanced re-analysis widget
                        const SizedBox(height: 16),
                        EnhancedReanalysisWidget(
                          classification: widget.classification,
                          onReanalysisStarted: () {
                            _analyticsService
                                .trackUserAction('enhanced_reanalysis_started');
                          },
                          onReanalysisCompleted: (newClassification) {
                            _analyticsService.trackUserAction(
                                'enhanced_reanalysis_completed',
                                parameters: {
                                  'original_category':
                                      widget.classification.category,
                                  'new_category': newClassification.category,
                                });
                          },
                        ),
                        ...[
                          const SizedBox(height: 24),
                          EnhancedDisposalInstructionsWidget(
                            classification: widget.classification,
                            onStepCompleted: (step) {
                              _awardPointsForDisposalStep();
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
          if (_showingClassificationFeedback)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: widgets.ClassificationFeedback(
                    category: widget.classification.category,
                    onComplete: () {
                      setState(() {
                        _showingClassificationFeedback = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          if (_newlyEarnedAchievements.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _newlyEarnedAchievements
                    .map((achievement) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: widgets.FloatingAchievementBadge(
                            achievement: achievement,
                            onTap: () => _showAchievementDetails(achievement),
                          ),
                        ))
                    .toList(),
              ),
            ),
          // Achievement celebration overlay
          if (_showCelebration && _celebrationAchievement != null)
            AchievementCelebration(
              achievement: _celebrationAchievement!,
              onDismiss: _onCelebrationDismissed,
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return AppTheme.wetWasteColor;
      case 'dry waste':
        return AppTheme.dryWasteColor;
      case 'hazardous waste':
        return AppTheme.hazardousWasteColor;
      case 'medical waste':
        return AppTheme.medicalWasteColor;
      case 'non-waste':
        return AppTheme.nonWasteColor;
      case 'requires manual review':
        return AppTheme.manualReviewColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return Icons.eco;
      case 'dry waste':
        return Icons.recycling;
      case 'hazardous waste':
        return Icons.warning;
      case 'medical waste':
        return Icons.medical_services;
      case 'non-waste':
        return Icons.refresh;
      case 'requires manual review':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  /// Builds a thumbnail image for the classification if available
  Widget _buildThumbnail(double size) {
    final url = widget.classification.imageUrl;
    Widget placeholder() => Icon(
          _getCategoryIcon(widget.classification.category),
          color: Colors.white,
          size: size,
        );

    if (url == null || url.isEmpty) {
      return placeholder();
    }

    if (kIsWeb) {
      if (url.startsWith('web_image:')) {
        try {
          final dataUrl = url.substring('web_image:'.length);
          if (dataUrl.startsWith('data:image')) {
            return Image.network(
              dataUrl,
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder(),
            );
          }
        } catch (_) {
          return placeholder();
        }
        return placeholder();
      }

      if (url.startsWith('http')) {
        return Image.network(
          url,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        );
      }

      return placeholder();
    }

    // On non-web platforms, just return the placeholder; ClassificationCard handles file logic.
    return placeholder();
  }

  // Award points for completing disposal steps
  Future<void> _awardPointsForDisposalStep() async {
    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);
      await gamificationService.addPoints('disposal_step_completed',
          customPoints: 2);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
    }
  }

  // Handle user feedback submission
  Future<void> _handleFeedbackSubmission(
      WasteClassification updatedClassification) async {
    if (!mounted) return;

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      await storageService.saveClassification(updatedClassification);

      final feedback = ClassificationFeedback(
        userId: updatedClassification.userId ?? 'guest_user',
        originalClassificationId: widget.classification.id,
        originalAIItemName: widget.classification.itemName,
        originalAICategory: widget.classification.category,
        originalAIMaterial: widget.classification.materialType,
        originalAIConfidence: widget.classification.confidence,
        userSuggestedItemName: updatedClassification.itemName,
        userSuggestedCategory: updatedClassification.category,
        userSuggestedMaterial: updatedClassification.materialType,
        userNotes: updatedClassification.userNotes,
        appVersion: AppVersion.fullVersion,
      );

      await storageService.saveClassificationFeedback(feedback);
      await _syncFeedbackToCloud(feedback);
      await _handleFeedbackSuccess();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      await _handleFeedbackError(e);
    }
  }

  Future<void> _syncFeedbackToCloud(ClassificationFeedback feedback) async {
    try {
      final cloudStorageService =
          Provider.of<CloudStorageService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      if (isGoogleSyncEnabled) {
        await cloudStorageService.saveClassificationFeedbackToCloud(feedback);
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      WasteAppLogger.info('Operation completed',
          context: {'service': 'screen', 'file': 'result_screen'});
    }
  }

  Future<void> _handleFeedbackSuccess() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Thank you for your feedback!')),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);
      await gamificationService.addPoints('feedback_provided', customPoints: 5);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
    }
  }

  Future<void> _handleFeedbackError(dynamic error) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Failed to save feedback: ${ErrorHandler.getUserFriendlyMessage(error)}'),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<bool> _isRecentClassification() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();

      final allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
      if (!allowHistoryFeedback) {
        return false;
      }

      final feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;
      final now = DateTime.now();
      final classificationDate = widget.classification.timestamp;
      final daysDifference = now.difference(classificationDate).inDays;

      return daysDifference <= feedbackTimeframeDays;
    } catch (e) {
      WasteAppLogger.severe('Error occurred',
          context: {'service': 'screen', 'file': 'result_screen'});
      return false;
    }
  }

  void _reAnalyze() {
    _analyticsService.trackUserAction('classification_reanalyze');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ImageCaptureScreen()),
    );
  }

  /// Build low confidence warning banner
  Widget _buildLowConfidenceWarningBanner() {
    final confidence = widget.classification.confidence!;
    final confidencePercent = (confidence * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        border: Border.all(
          color: Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Confidence Classification',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              // Confidence percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Text(
                  '$confidencePercent%',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This classification has lower confidence than usual. Consider re-analyzing with a clearer image or different angle for better accuracy.',
            style: TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: Colors.orange.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Re-analyze button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Track low confidence re-analyze
                _analyticsService
                    .trackUserAction('low_confidence_reanalyze', parameters: {
                  'original_confidence': confidence,
                  'category': widget.classification.category,
                });
                _reAnalyze();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Re-analyze with Better Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusRegular),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep {
  const _JourneyStep({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;
}

class _SnapshotItem {
  const _SnapshotItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _InsightItem {
  const _InsightItem({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;
}
