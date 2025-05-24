// Integration example for adding ImpactVisualizationRing to your existing home screen
// Add this code to your existing home_screen.dart file

// 1. Import the new widget at the top of your file:
import '../widgets/advanced_ui/impact_visualization_ring.dart';

// 2. Add these variables to your _HomeScreenState class:
class _HomeScreenState extends State<HomeScreen> {
  // ... your existing variables ...
  
  // Add these new variables for impact tracking
  int _dailyClassificationGoal = 10;
  int _weeklyClassificationGoal = 50;
  double _estimatedCO2Saved = 0.0;
  double _monthlyCO2Target = 25.0;
  
  // ... rest of your existing code ...
  
  // 3. Add this method to calculate environmental impact:
  void _calculateEnvironmentalImpact() {
    // Simple calculation: each classification saves ~0.5kg CO2 equivalent
    _estimatedCO2Saved = _recentClassifications.length * 0.5;
  }
  
  // 4. Add this method to build the impact section:
  Widget _buildImpactSection() {
    final today = DateTime.now();
    final todayClassifications = _recentClassifications.where((c) {
      final classificationDate = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      return classificationDate == todayDate;
    }).length.toDouble();
    
    final thisWeekClassifications = _recentClassifications.where((c) {
      final daysDifference = today.difference(c.timestamp).inDays;
      return daysDifference <= 7;
    }).length.toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Impact Today',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        
        // Daily classification ring
        ImpactVisualizationRing(
          progress: todayClassifications / _dailyClassificationGoal,
          currentValue: todayClassifications,
          targetValue: _dailyClassificationGoal.toDouble(),
          unit: 'items',
          primaryColor: WasteAppDesignSystem.primaryGreen,
          secondaryColor: WasteAppDesignSystem.secondaryGreen,
          title: 'Daily Classification Goal',
          subtitle: 'Items classified today',
          centerText: todayClassifications >= _dailyClassificationGoal ? 'Goal achieved!' : 'Keep going!',
          milestones: [
            ImpactMilestone(
              threshold: 0.3,
              title: 'Great Start',
              description: 'You\'re building momentum!',
              icon: Icons.trending_up,
              color: WasteAppDesignSystem.primaryGreen,
            ),
            ImpactMilestone(
              threshold: 0.7,
              title: 'Almost There',
              description: 'You\'re so close to your goal!',
              icon: Icons.near_me,
              color: WasteAppDesignSystem.secondaryGreen,
            ),
            ImpactMilestone(
              threshold: 1.0,
              title: 'Daily Champion',
              description: 'Daily goal completed!',
              icon: Icons.emoji_events,
              color: WasteAppDesignSystem.warningOrange,
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.paddingLarge),
        
        // Secondary impact rings
        Row(
          children: [
            // CO2 Impact
            Expanded(
              child: WasteImpactConfigurations.compactImpactRing(
                title: 'CO₂ Saved',
                currentValue: _estimatedCO2Saved,
                targetValue: _monthlyCO2Target,
                unit: 'kg',
                color: WasteAppDesignSystem.wetWasteColor,
                icon: Icons.eco,
                size: 80,
              ),
            ),
            
            const SizedBox(width: AppTheme.paddingRegular),
            
            // Weekly Progress
            Expanded(
              child: WasteImpactConfigurations.compactImpactRing(
                title: 'Weekly Goal',
                currentValue: thisWeekClassifications,
                targetValue: _weeklyClassificationGoal.toDouble(),
                unit: 'items',
                color: WasteAppDesignSystem.dryWasteColor,
                icon: Icons.calendar_today,
                size: 80,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 5. Update your _loadRecentClassifications method to calculate impact:
  Future<void> _loadRecentClassifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final classifications = await storageService.getAllClassifications();

      setState(() {
        _recentClassifications = classifications.safeTake(5);
        // Calculate environmental impact after loading classifications
        _calculateEnvironmentalImpact();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 6. In your build method, add the impact section after the capture buttons:
  @override
  Widget build(BuildContext context) {
    // ... existing code until after capture buttons ...
    
    return Scaffold(
      // ... existing scaffold code ...
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... existing welcome message and capture buttons ...
                
                // Add the impact section here
                const SizedBox(height: AppTheme.paddingLarge),
                _buildImpactSection(),
                
                // ... rest of your existing sections ...
              ],
            ),
          ),
          // ... existing positioned widgets ...
        ],
      ),
    );
  }
}

// 7. Alternative: Quick Integration in Existing Gamification Section
// If you prefer to add it to your existing gamification section, replace your
// _buildGamificationSection method with this enhanced version:

Widget _buildEnhancedGamificationSection() {
  if (_isLoadingGamification) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingRegular),
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (_gamificationProfile == null) {
    return const SizedBox.shrink();
  }

  // Calculate today's classifications for the ring
  final today = DateTime.now();
  final todayClassifications = _recentClassifications.where((c) {
    final classificationDate = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return classificationDate == todayDate;
  }).length.toDouble();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Your Progress',
        style: TextStyle(
          fontSize: AppTheme.fontSizeLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: AppTheme.paddingRegular),

      // Add Impact Ring alongside existing gamification
      if (todayClassifications > 0 || _dailyClassificationGoal > 0)
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          decoration: BoxDecoration(
            color: WasteAppDesignSystem.lightGray,
            borderRadius: BorderRadius.circular(WasteAppDesignSystem.radiusL),
            border: Border.all(
              color: WasteAppDesignSystem.primaryGreen.withOpacity(0.2),
            ),
          ),
          child: ImpactVisualizationRing(
            progress: todayClassifications / _dailyClassificationGoal,
            currentValue: todayClassifications,
            targetValue: _dailyClassificationGoal.toDouble(),
            unit: 'items today',
            primaryColor: WasteAppDesignSystem.primaryGreen,
            secondaryColor: WasteAppDesignSystem.secondaryGreen,
            title: 'Daily Impact',
            subtitle: 'Classifications completed',
            centerText: todayClassifications >= _dailyClassificationGoal ? 'Goal achieved! 🎉' : 'Keep going! 💪',
            milestones: [
              ImpactMilestone(
                threshold: 0.5,
                title: 'Halfway There',
                description: 'Great progress today!',
                icon: Icons.trending_up,
                color: WasteAppDesignSystem.primaryGreen,
              ),
              ImpactMilestone(
                threshold: 1.0,
                title: 'Daily Champion',
                description: 'Goal completed for today!',
                icon: Icons.emoji_events,
                color: WasteAppDesignSystem.warningOrange,
              ),
            ],
          ),
        ),

      const SizedBox(height: AppTheme.paddingRegular),

      // Existing streak indicator
      StreakIndicator(
        streak: _gamificationProfile!.streak,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AchievementsScreen(initialTabIndex: 2),
            ),
          );
        },
      ),

      // ... rest of your existing gamification widgets remain the same ...
    ],
  );
}

/*
IMPORTANT INTEGRATION NOTES:

1. Make sure to import the WasteAppDesignSystem:
   import '../utils/design_system.dart';

2. The impact ring will automatically animate when values change.

3. You can customize the colors, milestones, and text to match your app's tone.

4. The calculations are simple examples - you may want to use more sophisticated 
   environmental impact calculations based on waste types.

5. Consider storing user goals (daily/weekly targets) in SharedPreferences or your 
   existing storage service.

6. The compact rings work great in grids or alongside other widgets.

7. You can trigger celebrations when milestones are reached by listening to the 
   milestone animations in the widget.

8. For better user experience, consider showing the ring only when users have 
   made at least one classification.

QUICK START STEPS:

1. Copy the import statement to your home_screen.dart
2. Add the new variables to your _HomeScreenState class
3. Copy the _buildImpactSection method
4. Update your _loadRecentClassifications method
5. Add the impact section to your build method where you want it to appear
6. Test the integration and customize colors/text as needed

The impact rings will help motivate users by visualizing their progress and 
environmental contribution in an engaging, animated way!
*/
