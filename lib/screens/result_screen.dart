import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/share_service.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/animation_helpers.dart';
import '../utils/safe_collection_utils.dart';
import '../widgets/enhanced_gamification_widgets.dart';
import '../widgets/interactive_tag.dart';
import '../widgets/disposal_instructions_widget.dart';
import '../widgets/classification_feedback_widget.dart';
// import '../models/disposal_instructions.dart'; // Now included in waste_classification.dart
import '../screens/waste_dashboard_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/history_screen.dart';
import '../screens/modern_home_screen.dart';

class ResultScreen extends StatefulWidget {
  final WasteClassification classification;
  final bool showActions;

  const ResultScreen({
    super.key,
    required this.classification,
    this.showActions = true,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isAutoSaving = false;
  bool _showingClassificationFeedback = true;
  bool _showingPointsPopup = false;
  
  List<Achievement> _newlyEarnedAchievements = [];
  int _pointsEarned = 0;
  Challenge? _completedChallenge;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Process the classification for gamification only if it's a new classification
    if (widget.showActions) {
      _autoSaveClassification();
      _processClassification();
    } else {
      _showingClassificationFeedback = false;
    }
  }
  
  // Enhance classification with disposal instructions if not already present
  Future<WasteClassification> _enhanceClassificationWithDisposalInstructions() async {
    // This method is now called from within _autoSaveClassification to prevent duplicate saves
    if (widget.classification.disposalInstructions == null) {
      // Generate disposal instructions for this classification
      final enhancedClassification = widget.classification; // Already has disposal instructions
      return enhancedClassification;
    }
    return widget.classification;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Automatically save the classification when the screen loads
  Future<void> _autoSaveClassification() async {
    if (!widget.showActions || _isSaved) return;

    setState(() {
      _isAutoSaving = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Enhance classification with disposal instructions if needed
      final enhancedClassification = await _enhanceClassificationWithDisposalInstructions();
      
      // Save the enhanced classification with isSaved flag
      final savedClassification = enhancedClassification.copyWith(isSaved: true);
      await storageService.saveClassification(savedClassification);

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isAutoSaving = false;
        });
        
        // Trigger refresh of home screen data
        ModernHomeScreen.triggerRefresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successSaved)),
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-save failed: ${ErrorHandler.getUserFriendlyMessage(e)}')), 
        );
      }
    }
  }
  
  Future<void> _processClassification() async {
    try {
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      
      // Record the old profile to compare for new achievements
      final oldProfile = await gamificationService.getProfile();
      
      // Process the classification
      await gamificationService.processClassification(widget.classification);
      
      // Get updated profile
      final newProfile = await gamificationService.getProfile();
      
      // Calculate points earned
      final earnedPoints = newProfile.points.total - oldProfile.points.total;
      
      // Check for new achievements using safe collection access
      final oldAchievementIds = oldProfile.achievements
          .safeWhere((a) => a.isEarned)
          .map((a) => a.id)
          .toSet();
          
      final newAchievements = newProfile.achievements
          .safeWhere((a) => a.isEarned && !oldAchievementIds.contains(a.id));
          
      // Check for completed challenges using safe access
      final oldChallengeIds = oldProfile.completedChallenges
          .map((c) => c.id)
          .toSet();
          
      final completedChallenges = newProfile.completedChallenges
          .safeWhere((c) => !oldChallengeIds.contains(c.id));
      
      // Update the state after classification feedback is done
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _showingClassificationFeedback = false;
            _pointsEarned = earnedPoints;
            _newlyEarnedAchievements = newAchievements;
            _completedChallenge = completedChallenges.safeFirst;
            
            // Show points popup
            if (earnedPoints > 0) {
              _showingPointsPopup = true;
              
              Future.delayed(const Duration(milliseconds: 3000), () {
                if (mounted) {
                  setState(() {
                    _showingPointsPopup = false;
                  });
                }
              });
            }
          });
        }
      });
      
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        setState(() {
          _showingClassificationFeedback = false;
        });
      }
    }
  }

  Future<void> _saveResult() async {
    if (_isSaved) return;

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final savedClassification = widget.classification.copyWith(isSaved: true);
      await storageService.saveClassification(savedClassification);

      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        
        // Trigger refresh of home screen data
        ModernHomeScreen.triggerRefresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successSaved)),
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${ErrorHandler.getUserFriendlyMessage(e)}')), 
        );
      }
    }
  }

  Future<void> _shareResult() async {
    try {
      await ShareService.share(
        text: 'I identified ${widget.classification.itemName} as ${widget.classification.category} waste using the Waste Segregation app!',
        context: context,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${ErrorHandler.getUserFriendlyMessage(e)}')),
        );
      }
    }
  }
  
  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: EnhancedAchievementNotification(
          achievement: achievement,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Build enhanced interactive tags for the classification
  List<TagData> _buildInteractiveTags() {
    final tags = <TagData>[];
    
    // Category tag
    tags.add(TagFactory.category(widget.classification.category));
    
    // Subcategory tag if available
    if (widget.classification.subcategory != null) {
      tags.add(TagFactory.subcategory(
        widget.classification.subcategory!,
        widget.classification.category,
      ));
    }
    
    // Material type tag if available
    if (widget.classification.materialType != null) {
      tags.add(TagFactory.material(widget.classification.materialType!));
    }
    
    // Property tags
    if (widget.classification.isRecyclable == true) {
      tags.add(TagFactory.property('Recyclable', true));
      
      // Add recycling difficulty based on category/material
      final difficulty = _getRecyclingDifficulty();
      tags.add(TagFactory.recyclingDifficulty('to recycle', difficulty));
    }
    
    if (widget.classification.isCompostable == true) {
      tags.add(TagFactory.property('Compostable', true));
      tags.add(TagFactory.didYouKnow('Composting reduces methane emissions by 70%', Colors.green));
    }
    
    if (widget.classification.requiresSpecialDisposal == true) {
      tags.add(TagData(
        text: 'Special Disposal',
        color: Colors.orange,
        action: TagAction.warning,
        icon: Icons.warning,
      ));
      tags.add(TagFactory.actionRequired('Find specialized facility', Colors.red));
    }
    
    // Environmental impact tags
    final co2Savings = _calculateCO2Savings();
    if (co2Savings > 0) {
      tags.add(TagFactory.co2Savings(co2Savings));
    }
    
    // Resource conservation tags
    final waterSaved = _calculateWaterSavings();
    if (waterSaved > 0) {
      tags.add(TagFactory.resourceSaved('water', waterSaved, 'L'));
    }
    
    // Local information tags (Bangalore-specific)
    _addLocalInformationTags(tags);
    
    // Urgency tags
    _addUrgencyTags(tags);
    
    // Educational tips
    _addEducationalTips(tags);
    
    // Add filter tags for finding similar items
    tags.add(TagFactory.filter(
      'Similar Items',
      widget.classification.category,
      subcategory: widget.classification.subcategory,
    ));
    
    return tags;
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
        tags.add(TagFactory.localInfo('BBMP collects daily 6-10 AM', Icons.schedule));
        break;
      case 'dry waste':
        tags.add(TagFactory.localInfo('BBMP dry waste: Mon, Wed, Fri', Icons.schedule));
        tags.add(TagFactory.nearbyFacility('Kabadiwala available', Icons.store));
        break;
      case 'hazardous waste':
        tags.add(TagFactory.nearbyFacility('KSPCB facility - Bidadi', Icons.location_on));
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
      tags.add(TagFactory.didYouKnow('Remove caps before recycling', Colors.blue));
      tags.add(TagFactory.commonMistake('Leaving food residue on containers', Colors.amber));
    } else if (subcategory == 'paper') {
      tags.add(TagFactory.didYouKnow('Paper can be recycled 5-7 times', Colors.blue));
      tags.add(TagFactory.commonMistake('Mixing wet and dry paper', Colors.amber));
    } else if (category == 'wet waste') {
      tags.add(TagFactory.didYouKnow('Composting creates nutrient-rich soil', Colors.green));
      tags.add(TagFactory.commonMistake('Adding meat or oil to compost', Colors.amber));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Better background contrast
      appBar: AppBar(
        title: Text(
          'Classification Result',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
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
          // Main content
          Visibility(
            visible: !_showingClassificationFeedback,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Classification Card with better contrast
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.paddingLarge),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Classification result header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(widget.classification.category),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getCategoryColor(widget.classification.category).withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getCategoryIcon(widget.classification.category),
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingRegular),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Identified As',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeSmall,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.classification.itemName,
                                      style: const TextStyle(
                                        fontSize: AppTheme.fontSizeExtraLarge,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppTheme.paddingLarge),
                          
                          // Interactive Tags Section
                          Text(
                            'Tags & Actions',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingSmall),
                          InteractiveTagCollection(
                            tags: _buildInteractiveTags(),
                            maxTags: 6,
                          ),
                          
                          const SizedBox(height: AppTheme.paddingLarge),
                          
                          // Explanation section with WCAG AA compliant contrast
                          Container(
                            padding: const EdgeInsets.all(AppTheme.paddingRegular),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD), // Very light blue
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                              border: Border.all(color: const Color(0xFF1976D2)), // Dark blue border
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: const Color(0xFF0D47A1), // Dark blue for contrast
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D47A1), // Dark blue text
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                Text(
                                  widget.classification.explanation,
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeRegular,
                                    color: const Color(0xFF212121), // Almost black for readability
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.paddingLarge),
                          
                          // Action buttons with better contrast
                          if (widget.showActions) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isAutoSaving 
                                        ? null // Disabled while auto-saving
                                        : (_isSaved ? _shareResult : _saveResult),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAutoSaving 
                                          ? Colors.grey // Neutral color when saving
                                          : (_isSaved ? AppTheme.primaryColor : Colors.green), // Green for Save, Primary for Share
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                                      ),
                                    ),
                                    icon: Icon(
                                      _isAutoSaving 
                                          ? Icons.hourglass_empty // Saving icon
                                          : (_isSaved ? Icons.share : Icons.save)
                                    ),
                                    label: Text(
                                      _isAutoSaving 
                                          ? 'Saving...' 
                                          : (_isSaved ? 'Share' : 'Save')
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.paddingRegular),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _shareResult, // Share is always possible if item is shareable
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      side: BorderSide(color: AppTheme.primaryColor, width: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                                      ),
                                    ),
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Completed challenge card if available
                  if (_completedChallenge != null) ...[
                    FadeSlideAnimation(
                      startOffset: const Offset(0, 30),
                      duration: const Duration(milliseconds: 600),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.paddingLarge),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade50, Colors.orange.shade50],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber.shade700,
                                    size: 28,
                                  ),
                                  const SizedBox(width: AppTheme.paddingSmall),
                                  Text(
                                    'Challenge Completed!',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingSmall),
                              EnhancedChallengeCard(
                                challenge: _completedChallenge!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // User Feedback Section (for training AI model)
                  if (widget.showActions) ...[
                    ClassificationFeedbackWidget(
                      classification: widget.classification,
                      onFeedbackSubmitted: _handleFeedbackSubmission,
                      showCompactVersion: true,
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // Disposal Instructions Section
                  if (widget.classification.disposalInstructions != null ||
                      widget.classification.hasUrgentTimeframe == true) ...[
                    DisposalInstructionsWidget(
                      instructions: widget.classification.disposalInstructions,
                      onStepCompleted: (step) {
                        // Award points for completing disposal steps
                        _awardPointsForDisposalStep();
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // Enhanced Educational Section
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: AppTheme.secondaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Did You Know?',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          Text(
                            _getEducationalFact(
                              widget.classification.category,
                              widget.classification.subcategory,
                            ),
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              height: 1.6,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EducationalContentScreen(
                                          initialCategory: widget.classification.category,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.menu_book),
                                  label: const Text('Learn More'),
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingSmall),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HistoryScreen(
                                          filterCategory: widget.classification.category,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.history),
                                  label: const Text('Similar Items'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Navigation buttons
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingRegular),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WasteDashboardScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text('View Analytics Dashboard'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppTheme.secondaryColor),
                                foregroundColor: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingRegular),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.popUntil(context, (route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.home),
                              label: const Text(AppStrings.backToHome),
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
          
          // Classification feedback overlay
          if (_showingClassificationFeedback)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: ClassificationFeedback(
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
            
          // Points earned popup
          if (_showingPointsPopup)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 0,
              right: 0,
              child: Center(
                child: PointsEarnedPopup(
                  points: _pointsEarned,
                  action: 'classification',
                  onDismiss: () {
                    setState(() {
                      _showingPointsPopup = false;
                    });
                  },
                ),
              ),
            ),
            
          // Achievement notifications
          if (_newlyEarnedAchievements.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_showingPointsPopup ? 120 : 50),
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _newlyEarnedAchievements.map((achievement) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FloatingAchievementBadge(
                      achievement: achievement,
                      onTap: () => _showAchievementDetails(achievement),
                    ),
                  ),
                ).toList(),
              ),
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
      default:
        return Icons.category;
    }
  }

  String _getEducationalFact(String category, String? subcategory) {
    // Enhanced educational facts with more detailed information
    if (subcategory != null) {
      final subcategoryFacts = {
        'food waste': 'Food waste generates methane in landfills - a greenhouse gas 25x more potent than CO2. Home composting can reduce this by 70% while creating nutrient-rich soil.',
        'garden waste': 'Garden waste composting reduces volume by 70% and creates valuable soil conditioner. Browns (carbon) and greens (nitrogen) should be balanced 3:1.',
        'paper': 'Each ton of recycled paper saves 17 trees, 7,000 gallons of water, and 380 gallons of oil. Paper fibers can be recycled 5-7 times before becoming too short.',
        'plastic': 'Only 9% of all plastic ever made has been recycled. Different plastic types (codes 1-7) require separate processing - check your local guidelines.',
        'electronic waste': 'E-waste contains precious metals worth billions annually. One ton of circuit boards has 40-800x more gold than ore. Proper recycling recovers these materials.',
        'batteries': 'Battery recycling prevents toxic heavy metals from contaminating groundwater for decades. Many auto parts stores accept used batteries for free.',
      };
      
      final fact = subcategoryFacts[subcategory.toLowerCase()];
      if (fact != null) return fact;
    }

    // Category-level facts
    final categoryFacts = {
      'wet waste': 'Composting wet waste creates nutrient-rich soil amendment while reducing methane emissions from landfills by up to 80%.',
      'dry waste': 'Proper recycling of dry waste saves energy, reduces raw material extraction, and creates jobs in the recycling industry.',
      'hazardous waste': 'Hazardous waste can contaminate soil and water for decades. Proper disposal protects both human health and the environment.',
      'medical waste': 'Medical waste requires specialized treatment to prevent disease transmission. Autoclaving sterilizes waste before safe disposal.',
      'non-waste': 'Reusing and repurposing items reduces manufacturing demand and keeps valuable materials in circulation longer.',
    };
    
    return categoryFacts[category.toLowerCase()] ?? 'Proper waste management is essential for environmental protection and resource conservation.';
  }
  
  // Generate fallback disposal instructions if none are available
  // DisposalInstructions _generateFallbackDisposalInstructions() {
  //   return DisposalInstructionsGenerator.generateForItem(
  //     category: widget.classification.category,
  //     subcategory: widget.classification.subcategory,
  //     materialType: widget.classification.materialType,
  //     isRecyclable: widget.classification.isRecyclable,
  //     isCompostable: widget.classification.isCompostable,
  //     requiresSpecialDisposal: widget.classification.requiresSpecialDisposal,
  //   );
  // }
  
  // Award points for completing disposal steps
  Future<void> _awardPointsForDisposalStep() async {
    try {
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      // Award small points for following proper disposal procedures
      await gamificationService.addPoints('disposal_step_completed', customPoints: 2);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
    }
  }
  
  // Handle user feedback submission
  Future<void> _handleFeedbackSubmission(WasteClassification updatedClassification) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveClassification(updatedClassification);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Thank you for your feedback!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Award points for providing feedback
        final gamificationService = Provider.of<GamificationService>(context, listen: false);
        await gamificationService.addPoints('feedback_provided', customPoints: 5);
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}
