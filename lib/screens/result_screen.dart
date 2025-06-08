import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/share_service.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../models/classification_feedback.dart';
import '../services/cloud_storage_service.dart';
import '../utils/app_version.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/animation_helpers.dart';
import '../utils/safe_collection_utils.dart';
import '../widgets/enhanced_gamification_widgets.dart' as widgets;
import '../widgets/interactive_tag.dart';
import '../widgets/disposal_instructions_widget.dart';
import '../widgets/classification_feedback_widget.dart';
// import '../models/disposal_instructions.dart'; // Now included in waste_classification.dart
import '../screens/waste_dashboard_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/history_screen.dart';
import '../screens/modern_home_screen.dart';
import '../widgets/modern_ui/modern_info_tile.dart';

class ResultScreen extends StatefulWidget {

  const ResultScreen({
    super.key,
    required this.classification,
    this.showActions = true,
  });
  final WasteClassification classification;
  final bool showActions;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isAutoSaving = false;
  bool _showingClassificationFeedback = false;
  bool _showingPointsPopup = false;
  bool _isExplanationExpanded = false; // Added for expandable explanation
  bool _isEducationalFactExpanded = false; // Added for expandable educational fact
  
  List<Achievement> _newlyEarnedAchievements = [];
  int _pointsEarned = 0;
  Challenge? _completedChallenge;
  
  // Static set to track classifications being saved to prevent duplicates
  static final Set<String> _savingClassifications = <String>{};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Process the classification for gamification only if it's a new classification
    if (widget.showActions) {
      _autoSaveAndProcess();
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
      debugPrint('🚫 Already processing ${classificationId}, skipping.');
      return;
    }

    _savingClassifications.add(classificationId);
    if(mounted) setState(() => _isAutoSaving = true);

    try {
      // Step 1: Get services
      final storageService = Provider.of<StorageService>(context, listen: false);
      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      
      // Step 2: Save classification locally
      debugPrint('➡️ STEP 1: Saving classification locally...');
      final savedClassification = widget.classification.copyWith(isSaved: true);
      await storageService.saveClassification(savedClassification);
      debugPrint('✅ STEP 1: Local save complete.');

      // Step 3: Process for gamification (points, achievements)
      debugPrint('➡️ STEP 2: Processing for gamification...');
      final oldProfile = await gamificationService.getProfile();
      await gamificationService.processClassification(savedClassification);
      final newProfile = await gamificationService.getProfile(forceRefresh: true);
      debugPrint('✅ STEP 2: Gamification processing complete.');

      // Step 4: Sync to cloud
      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      if (isGoogleSyncEnabled) {
        debugPrint('➡️ STEP 3: Syncing classification and profile to cloud...');
        await cloudStorageService.saveClassificationWithSync(
          savedClassification,
          isGoogleSyncEnabled,
          processGamification: false, // Already processed
        );
         await gamificationService.saveProfile(newProfile); // Explicitly save updated profile
        debugPrint('✅ STEP 3: Cloud sync complete.');
      } else {
        debugPrint('Skipped cloud sync (disabled).');
      }

      // Step 5: Update UI
      final earnedPoints = newProfile.points.total - oldProfile.points.total;
      
      // Correctly and efficiently calculate newly earned achievements
      final oldAchievementIds = oldProfile.achievements.map((a) => a.id).toSet();
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
              .where((c) => !oldProfile.completedChallenges.map((oc) => oc.id).contains(c.id))
              .firstOrNull;
          
          // Show points popup
          if (earnedPoints > 0) {
            debugPrint('🎮 RESULT_SCREEN: Showing points popup for $earnedPoints points');
            _showingPointsPopup = true;
            
            Future.delayed(const Duration(milliseconds: 3000), () {
              if (mounted) {
                setState(() {
                  _showingPointsPopup = false;
                });
              }
            });
          } else {
            debugPrint('🎮 RESULT_SCREEN: No points to show popup for');
          }
        });

        // Show feedback
        final syncMessage = isGoogleSyncEnabled ? 'Saved and synced!' : 'Saved locally!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(syncMessage),
          backgroundColor: Colors.green,
        ));
      }

    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${ErrorHandler.getUserFriendlyMessage(e)}'),
        ));
      }
    } finally {
      _savingClassifications.remove(classificationId);
      if(mounted) setState(() => _isAutoSaving = false);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Check if this existing classification needs retroactive gamification processing
  /// This fixes the issue where users have classifications but 0 points
  Future<void> _checkRetroactiveGamificationProcessing() async {
    try {
      debugPrint('🎮 RETROACTIVE: Checking if ${widget.classification.itemName} needs gamification processing');
      
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      
      // Get current profile
      final profile = await gamificationService.getProfile();
      final currentPoints = profile.points.total;
      
      // Check if this classification is from today and might be missing points
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final classificationDate = DateTime(
        widget.classification.timestamp.year,
        widget.classification.timestamp.month,
        widget.classification.timestamp.day,
      );
      
      // Only process classifications from today to avoid retroactively awarding too many points
      if (classificationDate == today) {
        debugPrint('🎮 RETROACTIVE: Classification from today, checking if points were already awarded');
        
        // For existing classifications, we can try processing gamification
        // The gamification service should handle duplicate detection
        await gamificationService.processClassification(widget.classification);
        
        // Check if points were actually awarded
        final newProfile = await gamificationService.getProfile();
        final pointsAwarded = newProfile.points.total - currentPoints;
        
        if (pointsAwarded > 0) {
          debugPrint('🎮 RETROACTIVE: ✅ Awarded $pointsAwarded points for existing classification');
          
          // Trigger refresh of home screen to update the points display
          ModernHomeScreen.triggerRefresh();
        } else {
          debugPrint('🎮 RETROACTIVE: ⏭️ No points awarded (likely already processed)');
        }
      } else {
        debugPrint('🎮 RETROACTIVE: ⏭️ Classification not from today, skipping retroactive processing');
      }
    } catch (e, stackTrace) {
      debugPrint('🎮 RETROACTIVE: ❌ Error in retroactive processing: $e');
      ErrorHandler.handleError(e, stackTrace);
      // Don't rethrow - this is a background operation
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
        child: widgets.EnhancedAchievementNotification(
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
    
    // Usage type tag if available
    if (widget.classification.isSingleUse != null) {
      tags.add(TagFactory.property(
        widget.classification.isSingleUse! ? 'Single-Use' : 'Multi-Use',
        widget.classification.isSingleUse! ? false : true, // Multi-use is better
      ));
    }
    
    // Environmental impact tag if available
    if (widget.classification.environmentalImpact != null) {
      tags.add(TagFactory.didYouKnow(
        widget.classification.environmentalImpact!,
        Colors.green,
      ));
    }
    
    // Points awarded tag if available
    if (widget.classification.pointsAwarded != null) {
      tags.add(TagData(
        text: '+${widget.classification.pointsAwarded} Points',
        color: Colors.amber,
        action: TagAction.info,
        icon: Icons.star,
      ));
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
      tags.add(const TagData(
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

  Widget _buildDetailsSection(BuildContext context, WasteClassification classification) {
    return ExpansionTile(
      title: const Text(
        'Detailed Analysis',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      initiallyExpanded: true,
      children: [
        ModernInfoTile(
          icon: Icons.eco,
          label: 'Environmental Impact',
          value: classification.environmentalImpact ?? 'Not available',
        ),
        ModernInfoTile(
          icon: Icons.recycling,
          label: 'Recyclable',
          value: classification.isRecyclable == null ? 'Unknown' : (classification.isRecyclable! ? 'Yes' : 'No'),
          valueColor: classification.isRecyclable == null ? null : (classification.isRecyclable! ? Colors.green : Colors.red),
        ),
        ModernInfoTile(
          icon: Icons.compost,
          label: 'Compostable',
          value: classification.isCompostable == null ? 'Unknown' : (classification.isCompostable! ? 'Yes' : 'No'),
           valueColor: classification.isCompostable == null ? null : (classification.isCompostable! ? Colors.green : Colors.red),
        ),
        ModernInfoTile(
          icon: Icons.warning_amber,
          label: 'Risk Level',
          value: classification.riskLevel ?? 'Not assessed',
        ),
        if (classification.requiredPPE != null && classification.requiredPPE!.isNotEmpty)
          ModernInfoTile(
            icon: Icons.health_and_safety,
            label: 'Required PPE',
            value: classification.requiredPPE!.join(', '),
          ),
      ],
    );
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
                color: Colors.black.withValues(alpha:0.3),
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
                                      color: _getCategoryColor(widget.classification.category).withValues(alpha:0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: _buildThumbnail(32),
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
                                      maxLines: 2, // Added maxLines
                                      overflow: TextOverflow.ellipsis, // Added ellipsis
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
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF0D47A1), // Dark blue for contrast
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D47A1), // Dark blue text
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                Text(
                                  widget.classification.explanation,
                                  maxLines: _isExplanationExpanded ? null : 3,
                                  overflow: _isExplanationExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeRegular,
                                    color: Color(0xFF212121), // Almost black for readability
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExplanationExpanded = !_isExplanationExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isExplanationExpanded ? 'Show Less' : 'Read More',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.paddingLarge),
                          
                          // Display detailed analysis
                          _buildDetailsSection(context, widget.classification),
                          
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
                                      side: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
                              widgets.EnhancedChallengeCard(
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
                  // Allow feedback on new classifications OR recent ones based on user settings
                  FutureBuilder<bool>(
                    future: widget.showActions ? Future.value(true) : _isRecentClassification(),
                    builder: (context, snapshot) {
                      final shouldShowFeedback = snapshot.data ?? false;
                      
                      if (!shouldShowFeedback) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(top: AppTheme.paddingRegular),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add context header for history items
                            if (!widget.showActions) ...[
                              Container(
                                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You can still provide feedback on recent classifications to help improve our AI',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeSmall,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.paddingSmall),
                            ],
                            ClassificationFeedbackWidget(
                              classification: widget.classification,
                              onFeedbackSubmitted: _handleFeedbackSubmission,
                              showCompactVersion: !widget.showActions, // Use compact version for history items
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.paddingLarge),

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
                          const Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: AppTheme.secondaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 8),
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
                            maxLines: _isEducationalFactExpanded ? null : 3, // Added maxLines
                            overflow: _isEducationalFactExpanded ? TextOverflow.visible : TextOverflow.ellipsis, // Added ellipsis
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              height: 1.6,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingSmall), // Adjusted padding
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEducationalFactExpanded = !_isEducationalFactExpanded;
                              });
                            },
                            child: Text(
                              _isEducationalFactExpanded ? 'Show Less' : 'Read More',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
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

                  // Points awarded card (always visible)
                  if (widget.showActions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.paddingLarge),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                        ),
                        color: _pointsEarned > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingLarge),
                          child: Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: _pointsEarned > 0 ? Colors.green : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pointsEarned > 0
                                      ? '+$_pointsEarned Points awarded for this classification'
                                      : 'No points awarded (duplicate or already processed)',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: _pointsEarned > 0 ? Colors.green.shade900 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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
                                side: const BorderSide(color: AppTheme.secondaryColor),
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
            
          // Points earned popup
          if (_showingPointsPopup)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 0,
              right: 0,
              child: Center(
                child: widgets.PointsEarnedPopup(
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
                    child: widgets.FloatingAchievementBadge(
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

    final file = File(url);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder();
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            file,
            height: size,
            width: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
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
      },
    );
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
      'requires manual review': 'AI classification can be challenging for unusual items, poor lighting, or complex materials. Your feedback helps improve recognition accuracy.',
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
  Future<void> _handleFeedbackSubmission(
      WasteClassification updatedClassification) async {
    if (!mounted) return;

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      // Save updated classification first
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

      // Persist locally first
      await storageService.saveClassificationFeedback(feedback);

      // Cloud sync handled separately
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
      // Log but do not block user experience
      ErrorHandler.handleError(e, stackTrace);
      debugPrint('Cloud sync failed for feedback, but local save succeeded');
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
            Expanded(
              child: Text('Thank you for your feedback!'),
            ),
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
        content: Text('Failed to save feedback: ${ErrorHandler.getUserFriendlyMessage(error)}'),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<bool> _isRecentClassification() async {
    try {
      // Get user settings
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      
      // Check if history feedback is enabled
      final allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
      if (!allowHistoryFeedback) {
        return false;
      }
      
      // Check timeframe
      final feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;
      final now = DateTime.now();
      final classificationDate = widget.classification.timestamp;
      final daysDifference = now.difference(classificationDate).inDays;
      
      // Allow feedback on classifications within the specified timeframe
      return daysDifference <= feedbackTimeframeDays;
    } catch (e) {
      debugPrint('Error checking recent classification: $e');
      return false; // Default to not showing feedback on error
    }
  }
}
