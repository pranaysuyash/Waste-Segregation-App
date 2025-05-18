import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../utils/animation_helpers.dart';
import '../widgets/classification_card.dart';
import '../widgets/recycling_code_info.dart';
import '../widgets/enhanced_gamification_widgets.dart';
import '../screens/waste_dashboard_screen.dart';

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
    
    // Automatically save the classification
    _autoSaveClassification();
    
    // Process the classification for gamification
    _processClassification();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Automatically save the classification when the screen loads
  Future<void> _autoSaveClassification() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Update the classification's saved state
      widget.classification.isSaved = true;
      
      await storageService.saveClassification(widget.classification);
      
      setState(() {
        _isSaved = true;
      });
      
      // No need to show a snackbar since it's automatic
    } catch (e) {
      debugPrint('Error auto-saving classification: $e');
      // If auto-save fails, we'll let the user try manual save
      setState(() {
        _isSaved = false;
      });
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
      
      // Check for new achievements
      final oldAchievementIds = oldProfile.achievements
          .where((a) => a.isEarned)
          .map((a) => a.id)
          .toSet();
          
      final newAchievements = newProfile.achievements
          .where((a) => a.isEarned && !oldAchievementIds.contains(a.id))
          .toList();
          
      // Check for completed challenges
      final oldChallengeIds = oldProfile.completedChallenges
          .map((c) => c.id)
          .toSet();
          
      final completedChallenges = newProfile.completedChallenges
          .where((c) => !oldChallengeIds.contains(c.id))
          .toList();
      
      // Update the state after classification feedback is done
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _showingClassificationFeedback = false;
            _pointsEarned = earnedPoints;
            _newlyEarnedAchievements = newAchievements;
            _completedChallenge = completedChallenges.isNotEmpty ? completedChallenges.first : null;
            
            // Show points popup
            if (earnedPoints > 0) {
              _showingPointsPopup = true;
              
              // Hide points popup after 2 seconds
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
      
    } catch (e) {
      debugPrint('Error processing gamification: $e');
      // In case of error, still show the result without gamification elements
      setState(() {
        _showingClassificationFeedback = false;
      });
    }
  }

  Future<void> _saveResult() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Update the classification's saved state
      widget.classification.isSaved = true;
      
      await storageService.saveClassification(widget.classification);

      setState(() {
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareResult() async {
    try {
      // Web sharing is more limited
      if (kIsWeb ||
          widget.classification.imageUrl == null ||
          widget.classification.imageUrl!.startsWith('web_image:')) {
        await SharePlus.instance.share(
          ShareParams(
            text: 'I identified ${widget.classification.itemName} as ${widget.classification.category} waste using the Waste Segregation app!',
          ),
        );
        return;
      }

      // Mobile sharing with image
      final imageFile = File(widget.classification.imageUrl!);

      // Create a temporary text file with the classification details
      final tempDir = await getTemporaryDirectory();
      final tempTextFile = File('${tempDir.path}/classification_details.txt');

      await tempTextFile.writeAsString(
        'Item: ${widget.classification.itemName}\n'
        'Category: ${widget.classification.category}\n\n'
        'Explanation: ${widget.classification.explanation}\n\n'
        'Identified using the Waste Segregation app',
      );

      await SharePlus.instance.share(
        ShareParams(
          text: 'Waste Classification Results',
          files: [
            XFile(imageFile.path),
            XFile(tempTextFile.path),
          ],
        ),
      );

      // Clean up
      if (await tempTextFile.exists()) {
        await tempTextFile.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successShared)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Result'),
        actions: [
          // Dashboard button
          IconButton(
            icon: const Icon(Icons.bar_chart),
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
          // Main content, only visible after feedback animation
          Visibility(
            visible: !_showingClassificationFeedback,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                children: [
                  // Classification card
                  ClassificationCard(
                    classification: widget.classification,
                    onSave: widget.showActions && !_isSaved ? _saveResult : null,
                    onShare: widget.showActions ? _shareResult : null,
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Completed challenge card if available
                  if (_completedChallenge != null) ...[
                    FadeSlideAnimation(
                      startOffset: const Offset(0, 30),
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: AppTheme.paddingSmall),
                              const Text(
                                'Challenge Completed!',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
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
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // Recycling code info section if available
                  if (widget.classification.recyclingCode != null) ...[
                    RecyclingCodeInfoCard(code: widget.classification.recyclingCode!),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // Educational section
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school, color: AppTheme.secondaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Did You Know?',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.paddingRegular),

                        // Educational fact based on waste category and subcategory
                        Text(_getEducationalFact(
                          widget.classification.category,
                          widget.classification.subcategory,
                        )),

                        const SizedBox(height: AppTheme.paddingRegular),

                        // Impact statement
                        const Text(
                          'Proper waste segregation can reduce landfill waste by up to 80% and significantly decrease greenhouse gas emissions.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Material properties section if materialType is available
                  if (widget.classification.materialType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingRegular),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusRegular),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.science, color: AppTheme.accentColor),
                              SizedBox(width: 8),
                              Text(
                                'Material Information',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppTheme.paddingRegular),

                          // Material type
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Material Type: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(widget.classification.materialType!),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Properties table
                          Table(
                            border: TableBorder.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Property',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Value',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Recyclable'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      widget.classification.isRecyclable == true
                                          ? 'Yes'
                                          : widget.classification.isRecyclable ==
                                                  false
                                              ? 'No'
                                              : 'Unknown',
                                      style: TextStyle(
                                        color: widget.classification.isRecyclable ==
                                                true
                                            ? Colors.green
                                            : widget.classification.isRecyclable ==
                                                    false
                                                ? Colors.red
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Compostable'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      widget.classification.isCompostable == true
                                          ? 'Yes'
                                          : widget.classification.isCompostable ==
                                                  false
                                              ? 'No'
                                              : 'Unknown',
                                      style: TextStyle(
                                        color: widget.classification.isCompostable ==
                                                true
                                            ? Colors.green
                                            : widget.classification.isCompostable ==
                                                    false
                                                ? Colors.red
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Special Disposal Required'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      widget.classification.requiresSpecialDisposal ==
                                              true
                                          ? 'Yes'
                                          : widget.classification
                                                      .requiresSpecialDisposal ==
                                                  false
                                              ? 'No'
                                              : 'Unknown',
                                      style: TextStyle(
                                        color: widget.classification
                                                    .requiresSpecialDisposal ==
                                                true
                                            ? Colors.orange
                                            : widget.classification
                                                        .requiresSpecialDisposal ==
                                                    false
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // View dashboard button
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
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('View Waste Analytics Dashboard'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingRegular,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.paddingRegular),

                  // Back to home button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate back to home screen
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingRegular,
                        ),
                      ),
                      icon: const Icon(Icons.home),
                      label: const Text(AppStrings.backToHome),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Initial classification success feedback overlay
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
            
          // Achievement badge notifications
          if (_newlyEarnedAchievements.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_showingPointsPopup ? 120 : 50),
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final achievement in _newlyEarnedAchievements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: FloatingAchievementBadge(
                        achievement: achievement,
                        onTap: () => _showAchievementDetails(achievement),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getEducationalFact(String category, String? subcategory) {
    // Try to get more specific educational facts based on subcategory if available
    if (subcategory != null) {
      switch (subcategory.toLowerCase()) {
        // Wet waste subcategories
        case 'food waste':
          return 'Food waste in landfills produces methane, a greenhouse gas 25 times more potent than CO2. Composting food waste reduces these emissions and creates valuable soil amendments.';
        case 'garden waste':
          return 'Composting garden waste can reduce waste volume by up to 70%. The resulting compost improves soil structure, water retention, and provides nutrients for plants.';
        case 'biodegradable packaging':
          return 'Not all biodegradable packaging decomposes in home composting systems. Industrial composting facilities maintain higher temperatures needed for some materials.';

        // Dry waste subcategories
        case 'paper':
          return 'Recycling one ton of paper saves 17 trees, 7,000 gallons of water, 380 gallons of oil, and 3.3 cubic yards of landfill space. Paper can typically be recycled 5-7 times before fibers become too short.';
        case 'plastic':
          return 'Different plastic types (indicated by recycling codes 1-7) require different recycling processes. Only about 9% of all plastic ever produced has been recycled.';
        case 'glass':
          return 'Glass can be recycled endlessly without loss in quality or purity. Recycling glass reduces energy consumption by 40% compared to making new glass from raw materials.';
        case 'metal':
          return 'Recycling aluminum saves 95% of the energy needed to make new aluminum from raw materials. A recycled aluminum can can be back on the shelf in just 60 days.';

        // Hazardous waste subcategories
        case 'electronic waste':
          return 'E-waste contains valuable materials like gold, silver, copper, and rare earth elements. One ton of circuit boards contains 40-800 times more gold than one ton of ore.';
        case 'batteries':
          return 'Batteries contain heavy metals and toxic chemicals that can leach into soil and groundwater. Recycling batteries recovers valuable metals and prevents environmental contamination.';

        // Medical waste subcategories
        case 'sharps':
          return 'Improper disposal of sharps can cause injury and potentially transmit diseases. FDA-approved sharps containers are required for safe disposal.';
        case 'pharmaceutical':
          return 'Pharmaceuticals should never be flushed down toilets as they can contaminate water sources. Many pharmacies offer drug take-back programs.';

        // Non-waste subcategories
        case 'reusable items':
          return 'Single-use items account for a significant portion of landfill waste. Switching to reusable alternatives like water bottles and shopping bags can prevent hundreds of items from entering the waste stream annually.';
        case 'edible food':
          return 'About one-third of all food produced globally is wasted. Food redistribution programs can help direct surplus food to people in need rather than landfills.';
      }
    }

    // Fall back to category-level facts if no subcategory match
    switch (category.toLowerCase()) {
      case 'wet waste':
        return 'Wet waste can be composted to create nutrient-rich soil for gardening. The composting process typically takes 2-3 months and reduces methane emissions from landfills.';
      case 'dry waste':
        return 'Recycling one ton of paper saves 17 trees, 7,000 gallons of water, 380 gallons of oil, and 3.3 cubic yards of landfill space. Plastic recycling rates are improving globally but still only about 9% of all plastic is recycled.';
      case 'hazardous waste':
        return 'Improper disposal of hazardous waste can contaminate soil and water sources for decades. Many electronic items contain valuable metals like gold, silver, and platinum that can be recovered through proper recycling.';
      case 'medical waste':
        return 'Medical waste requires special treatment to prevent the spread of infections. Autoclaving (steam sterilization) is commonly used to sterilize medical waste before disposal.';
      case 'non-waste':
        return 'Reusing items extends their lifecycle and reduces the need for new resources. Donating usable items helps support communities and reduces waste in landfills.';
      default:
        return 'Proper waste segregation is crucial for effective recycling and composting. It helps reduce landfill usage and minimizes environmental impact.';
    }
  }
}
