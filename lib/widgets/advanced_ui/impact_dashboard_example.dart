import 'package:flutter/material.dart';
import 'impact_visualization_ring.dart';
import '../../utils/design_system.dart';

/// Example widget showing how to use ImpactVisualizationRing for waste segregation
class WasteImpactDashboard extends StatefulWidget {
  const WasteImpactDashboard({super.key});

  @override
  State<WasteImpactDashboard> createState() => _WasteImpactDashboardState();
}

class _WasteImpactDashboardState extends State<WasteImpactDashboard> {
  // Sample data - in a real app, this would come from your data services
  double wasteItemsClassified = 47.0;
  double monthlyTarget = 100.0;
  
  @override
  Widget build(BuildContext context) {
    final progress = wasteItemsClassified / monthlyTarget;
    
    return Scaffold(
      backgroundColor: WasteAppDesignSystem.lightGray,
      appBar: AppBar(
        title: const Text('Environmental Impact'),
        backgroundColor: WasteAppDesignSystem.primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WasteAppDesignSystem.spacingL),
        child: Column(
          children: [
            // Main Impact Ring
            Container(
              padding: const EdgeInsets.all(WasteAppDesignSystem.spacingL),
              decoration: WasteAppDesignSystem.getCardDecoration(
                elevation: WasteAppDesignSystem.elevationM,
                borderRadius: WasteAppDesignSystem.radiusL,
              ),
              child: ImpactVisualizationRing(
                progress: progress,
                currentValue: wasteItemsClassified,
                targetValue: monthlyTarget,
                unit: 'items classified',
                primaryColor: WasteAppDesignSystem.primaryGreen,
                secondaryColor: WasteAppDesignSystem.secondaryGreen,
                title: 'Monthly Progress',
                subtitle: 'Items classified this month',
                centerText: 'Keep going!',
                milestones: _buildWasteMilestones(),
              ),
            ),
            
            const SizedBox(height: WasteAppDesignSystem.spacingXL),
            
            // Secondary Impact Rings Grid
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryImpactCard(
                    'CO₂ Saved',
                    23.5,
                    50.0,
                    'kg',
                    WasteAppDesignSystem.wetWasteColor,
                    Icons.eco,
                  ),
                ),
                const SizedBox(width: WasteAppDesignSystem.spacingM),
                Expanded(
                  child: _buildSecondaryImpactCard(
                    'Water Saved',
                    156.0,
                    300.0,
                    'liters',
                    WasteAppDesignSystem.dryWasteColor,
                    Icons.water_drop,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: WasteAppDesignSystem.spacingL),
            
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryImpactCard(
                    'Energy Saved',
                    12.8,
                    25.0,
                    'kWh',
                    WasteAppDesignSystem.warningOrange,
                    Icons.flash_on,
                  ),
                ),
                const SizedBox(width: WasteAppDesignSystem.spacingM),
                Expanded(
                  child: _buildSecondaryImpactCard(
                    'Waste Diverted',
                    8.2,
                    15.0,
                    'kg',
                    WasteAppDesignSystem.hazardousWasteColor,
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: WasteAppDesignSystem.spacingXL),
            
            // Impact Summary Card
            _buildImpactSummaryCard(),
          ],
        ),
      ),
    );
  }
  
  List<ImpactMilestone> _buildWasteMilestones() {
    return [
      ImpactMilestone(
        threshold: 0.25,
        title: 'Getting Started',
        description: '25% of monthly goal reached',
        icon: Icons.flag,
        color: WasteAppDesignSystem.primaryGreen,
        isReached: wasteItemsClassified >= monthlyTarget * 0.25,
      ),
      ImpactMilestone(
        threshold: 0.5,
        title: 'Halfway Hero',
        description: 'You\'re making a real difference!',
        icon: Icons.trending_up,
        color: WasteAppDesignSystem.secondaryGreen,
        isReached: wasteItemsClassified >= monthlyTarget * 0.5,
      ),
      ImpactMilestone(
        threshold: 0.75,
        title: 'Eco Champion',
        description: 'Outstanding environmental commitment',
        icon: Icons.eco,
        color: WasteAppDesignSystem.wetWasteColor,
        isReached: wasteItemsClassified >= monthlyTarget * 0.75,
      ),
      ImpactMilestone(
        threshold: 1.0,
        title: 'Goal Achieved',
        description: 'Monthly target completed!',
        icon: Icons.emoji_events,
        color: WasteAppDesignSystem.warningOrange,
        isReached: wasteItemsClassified >= monthlyTarget,
      ),
    ];
  }
  
  Widget _buildSecondaryImpactCard(
    String title,
    double currentValue,
    double targetValue,
    String unit,
    Color color,
    IconData icon,
  ) {
    final progress = currentValue / targetValue;
    
    return Container(
      padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
      decoration: WasteAppDesignSystem.getCardDecoration(
        
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: WasteAppDesignSystem.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingM),
          
          // Mini impact ring
          SizedBox(
            width: 80,
            height: 80,
            child: ImpactVisualizationRing(
              progress: progress,
              currentValue: currentValue,
              targetValue: targetValue,
              unit: unit,
              primaryColor: color,
              secondaryColor: color.withValues(alpha: 0.7),
              title: '',
              subtitle: '',
            ),
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingS),
          
          Text(
            '${currentValue.toStringAsFixed(1)} $unit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WasteAppDesignSystem.darkGray,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WasteAppDesignSystem.spacingL),
      decoration: WasteAppDesignSystem.getCardDecoration(
        elevation: WasteAppDesignSystem.elevationM,
        borderRadius: WasteAppDesignSystem.radiusL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights,
                color: WasteAppDesignSystem.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: WasteAppDesignSystem.spacingS),
              Text(
                'Your Environmental Impact',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingM),
          
          _buildImpactStat(
            'Total Items Classified',
            '${wasteItemsClassified.toInt()}',
            'this month',
            Icons.recycling,
            WasteAppDesignSystem.primaryGreen,
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingM),
          
          _buildImpactStat(
            'Environmental Savings',
            '23.5 kg CO₂',
            'equivalent saved',
            Icons.eco,
            WasteAppDesignSystem.wetWasteColor,
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingM),
          
          _buildImpactStat(
            'Community Contribution',
            'Top 15%',
            'of active users',
            Icons.group,
            WasteAppDesignSystem.secondaryGreen,
          ),
          
          const SizedBox(height: WasteAppDesignSystem.spacingL),
          
          // Call to action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
            decoration: BoxDecoration(
              color: WasteAppDesignSystem.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(WasteAppDesignSystem.radiusM),
              border: Border.all(
                color: WasteAppDesignSystem.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: WasteAppDesignSystem.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: WasteAppDesignSystem.spacingS),
                Expanded(
                  child: Text(
                    'Classify ${(monthlyTarget - wasteItemsClassified).toInt()} more items to reach your monthly goal!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WasteAppDesignSystem.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactStat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(WasteAppDesignSystem.spacingS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(WasteAppDesignSystem.radiusS),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        
        const SizedBox(width: WasteAppDesignSystem.spacingM),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: WasteAppDesignSystem.spacingXS),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WasteAppDesignSystem.darkGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Utility class for creating predefined impact ring configurations
class WasteImpactConfigurations {
  /// Creates an impact ring for daily waste classification goals
  static ImpactVisualizationRing dailyWasteGoal({
    required double itemsClassified,
    required double dailyTarget,
    VoidCallback? onTap,
  }) {
    return ImpactVisualizationRing(
      progress: itemsClassified / dailyTarget,
      currentValue: itemsClassified,
      targetValue: dailyTarget,
      primaryColor: WasteAppDesignSystem.primaryGreen,
      secondaryColor: WasteAppDesignSystem.secondaryGreen,
      title: 'Daily Goal',
      subtitle: 'Items classified today',
      centerText: itemsClassified >= dailyTarget 
          ? 'Goal achieved!' 
          : 'Keep going!',
      milestones: const [
        ImpactMilestone(
          threshold: 0.5,
          title: 'Halfway There',
          description: 'You\'re making great progress!',
          icon: Icons.trending_up,
          color: WasteAppDesignSystem.primaryGreen,
        ),
        ImpactMilestone(
          threshold: 0.8,
          title: 'Almost Done',
          description: 'Just a few more items to go!',
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
    );
  }

  /// Creates an impact ring for weekly environmental impact
  static ImpactVisualizationRing weeklyEnvironmentalImpact({
    required double co2Saved,
    required double weeklyTarget,
  }) {
    return ImpactVisualizationRing(
      progress: co2Saved / weeklyTarget,
      currentValue: co2Saved,
      targetValue: weeklyTarget,
      unit: 'kg CO₂ saved',
      primaryColor: WasteAppDesignSystem.wetWasteColor,
      secondaryColor: const Color(0xFF2E7D32),
      subtitle: 'CO₂ emissions prevented this week',
      centerText: 'Saving the planet!',
      milestones: const [
        ImpactMilestone(
          threshold: 0.25,
          title: 'Eco Beginner',
          description: 'First steps toward sustainability',
          icon: Icons.eco,
          color: WasteAppDesignSystem.wetWasteColor,
        ),
        ImpactMilestone(
          threshold: 0.75,
          title: 'Green Hero',
          description: 'Significant environmental contribution',
          icon: Icons.park,
          color: WasteAppDesignSystem.primaryGreen,
        ),
      ],
    );
  }

  /// Creates an impact ring for monthly streak tracking
  static ImpactVisualizationRing monthlyStreak({
    required int currentStreak,
    required int targetStreak,
  }) {
    return ImpactVisualizationRing(
      progress: currentStreak / targetStreak,
      currentValue: currentStreak.toDouble(),
      targetValue: targetStreak.toDouble(),
      unit: 'day streak',
      primaryColor: const Color(0xFFFF6B35),
      secondaryColor: const Color(0xFFFF8E53),
      title: 'Consistency Streak',
      subtitle: 'Days of continuous classification',
      centerText: currentStreak > 0 ? 'On fire! 🔥' : 'Start your streak!',
      milestones: const [
        ImpactMilestone(
          threshold: 0.2,
          title: 'Getting Started',
          description: 'Building the habit',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        ImpactMilestone(
          threshold: 0.5,
          title: 'Streak Master',
          description: 'Consistency is key!',
          icon: Icons.whatshot,
          color: Colors.deepOrange,
        ),
        ImpactMilestone(
          threshold: 1.0,
          title: 'Unstoppable',
          description: 'Perfect monthly streak!',
          icon: Icons.local_fire_department,
          color: Colors.red,
        ),
      ],
    );
  }

  /// Creates a compact impact ring for dashboard widgets
  static Widget compactImpactRing({
    required String title,
    required double currentValue,
    required double targetValue,
    required String unit,
    required Color color,
    required IconData icon,
    double size = 100,
  }) {
    return Container(
      width: size + 40,
      padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
      decoration: WasteAppDesignSystem.getCardDecoration(
        
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: WasteAppDesignSystem.spacingXS),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WasteAppDesignSystem.textBlack,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: WasteAppDesignSystem.spacingS),
          SizedBox(
            width: size,
            height: size,
            child: ImpactVisualizationRing(
              progress: currentValue / targetValue,
              currentValue: currentValue,
              targetValue: targetValue,
              unit: unit,
              primaryColor: color,
              secondaryColor: color.withValues(alpha: 0.7),
              title: '',
              subtitle: '',
            ),
          ),
        ],
      ),
    );
  }
}
