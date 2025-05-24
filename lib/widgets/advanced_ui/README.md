# Impact Visualization Ring - Advanced UI Component

This component provides an advanced, animated impact visualization ring specifically designed for waste segregation applications. It features smooth animations, milestone tracking, and environmental storytelling.

## Features

- **Animated Progress Ring**: Smooth animated progress with gradient colors and glow effects
- **Milestone System**: Visual markers and descriptions for achievement tracking
- **Customizable Styling**: Integrates with your existing design system
- **Environmental Focus**: Built specifically for waste management and environmental impact tracking
- **Pulse Animation**: Engaging visual feedback with subtle pulse effects
- **Flexible Configuration**: Multiple predefined configurations for different use cases

## Usage

### Basic Implementation

```dart
import 'package:your_app/widgets/advanced_ui/impact_visualization_ring.dart';

ImpactVisualizationRing(
  progress: 0.47, // 47% progress
  currentValue: 47.0,
  targetValue: 100.0,
  unit: 'items classified',
  primaryColor: WasteAppDesignSystem.primaryGreen,
  secondaryColor: WasteAppDesignSystem.secondaryGreen,
  title: 'Monthly Progress',
  subtitle: 'Items classified this month',
  centerText: 'Keep going!',
  milestones: [
    ImpactMilestone(
      threshold: 0.5,
      title: 'Halfway Hero',
      description: 'You're making a real difference!',
      icon: Icons.trending_up,
      color: WasteAppDesignSystem.secondaryGreen,
    ),
  ],
)
```

### Predefined Configurations

Use the `WasteImpactConfigurations` class for common scenarios:

```dart
// Daily waste classification goal
WasteImpactConfigurations.dailyWasteGoal(
  itemsClassified: 15.0,
  dailyTarget: 20.0,
)

// Weekly environmental impact
WasteImpactConfigurations.weeklyEnvironmentalImpact(
  co2Saved: 23.5,
  weeklyTarget: 50.0,
)

// Monthly streak tracking
WasteImpactConfigurations.monthlyStreak(
  currentStreak: 12,
  targetStreak: 30,
)

// Compact ring for dashboard widgets
WasteImpactConfigurations.compactImpactRing(
  title: 'CO₂ Saved',
  currentValue: 23.5,
  targetValue: 50.0,
  unit: 'kg',
  color: WasteAppDesignSystem.wetWasteColor,
  icon: Icons.eco,
)
```

### Complete Dashboard Example

See `impact_dashboard_example.dart` for a complete implementation showing:
- Main impact ring with milestones
- Secondary impact rings in a grid layout
- Impact summary card with statistics
- Integration with your waste segregation app's data

## Parameters

### ImpactVisualizationRing

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `progress` | `double` | ✅ | Progress value (0.0 to 1.0) |
| `currentValue` | `double` | ✅ | Current progress value |
| `targetValue` | `double` | ✅ | Target/goal value |
| `unit` | `String` | ❌ | Unit of measurement (default: 'items') |
| `primaryColor` | `Color` | ❌ | Main ring color (default: Color(0xFF06FFA5)) |
| `secondaryColor` | `Color` | ❌ | Secondary gradient color (default: Color(0xFF00B4D8)) |
| `centerText` | `String` | ❌ | Additional text in center |
| `milestones` | `List<ImpactMilestone>` | ❌ | Milestone markers on the ring |
| `title` | `String` | ❌ | Main title above the ring |
| `subtitle` | `String` | ❌ | Subtitle below the title |

### ImpactMilestone

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `threshold` | `double` | ✅ | Progress threshold (0.0 to 1.0) |
| `title` | `String` | ✅ | Milestone title |
| `description` | `String` | ✅ | Milestone description |
| `icon` | `IconData` | ✅ | Milestone icon |
| `color` | `Color` | ✅ | Milestone color |
| `isReached` | `bool` | ❌ | Whether milestone is reached (default: false) |

## Integration with Existing App

### 1. Add to Home Screen

```dart
// In your home_screen.dart
import '../widgets/advanced_ui/impact_visualization_ring.dart';

// Add to your build method
ImpactVisualizationRing(
  progress: userStats.dailyProgress,
  currentValue: userStats.itemsClassifiedToday.toDouble(),
  targetValue: userStats.dailyTarget.toDouble(),
  unit: 'items',
  primaryColor: WasteAppDesignSystem.primaryGreen,
  title: 'Today\'s Progress',
  milestones: _buildDailyMilestones(),
)
```

### 2. Add to Dashboard Screen

```dart
// In your waste_dashboard_screen.dart
// Create a grid of compact impact rings
GridView.count(
  crossAxisCount: 2,
  children: [
    WasteImpactConfigurations.compactImpactRing(
      title: 'CO₂ Saved',
      currentValue: environmentalStats.co2Saved,
      targetValue: environmentalStats.co2Target,
      unit: 'kg',
      color: WasteAppDesignSystem.wetWasteColor,
      icon: Icons.eco,
    ),
    WasteImpactConfigurations.compactImpactRing(
      title: 'Items Today',
      currentValue: userStats.itemsToday.toDouble(),
      targetValue: userStats.dailyTarget.toDouble(),
      unit: 'items',
      color: WasteAppDesignSystem.primaryGreen,
      icon: Icons.recycling,
    ),
    // Add more rings as needed
  ],
)
```

### 3. Connect to Gamification Service

```dart
// In your gamification_service.dart
import '../widgets/advanced_ui/impact_visualization_ring.dart';

class GamificationService {
  List<ImpactMilestone> getDailyMilestones(UserStats stats) {
    return [
      ImpactMilestone(
        threshold: 0.25,
        title: 'Getting Started',
        description: 'First items of the day classified',
        icon: Icons.flag,
        color: WasteAppDesignSystem.primaryGreen,
        isReached: stats.dailyProgress >= 0.25,
      ),
      ImpactMilestone(
        threshold: 0.5,
        title: 'Halfway Hero',
        description: 'Halfway to your daily goal!',
        icon: Icons.trending_up,
        color: WasteAppDesignSystem.secondaryGreen,
        isReached: stats.dailyProgress >= 0.5,
      ),
      ImpactMilestone(
        threshold: 1.0,
        title: 'Daily Champion',
        description: 'Daily goal completed!',
        icon: Icons.emoji_events,
        color: WasteAppDesignSystem.warningOrange,
        isReached: stats.dailyProgress >= 1.0,
      ),
    ];
  }

  List<ImpactMilestone> getEnvironmentalMilestones(EnvironmentalStats stats) {
    final progress = stats.co2Saved / stats.monthlyTarget;
    
    return [
      ImpactMilestone(
        threshold: 0.1,
        title: 'Eco Starter',
        description: 'First environmental contribution',
        icon: Icons.eco,
        color: WasteAppDesignSystem.wetWasteColor,
        isReached: progress >= 0.1,
      ),
      ImpactMilestone(
        threshold: 0.5,
        title: 'Green Guardian',
        description: 'Significant environmental impact',
        icon: Icons.park,
        color: WasteAppDesignSystem.primaryGreen,
        isReached: progress >= 0.5,
      ),
      ImpactMilestone(
        threshold: 0.9,
        title: 'Planet Protector',
        description: 'Outstanding environmental commitment',
        icon: Icons.public,
        color: WasteAppDesignSystem.secondaryGreen,
        isReached: progress >= 0.9,
      ),
    ];
  }
}
```

### 4. Real-time Updates

```dart
// Update the ring when new classifications are made
void onWasteClassified() {
  setState(() {
    // Update your stats
    userStats.incrementDailyCount();
    environmentalStats.updateCO2Savings();
    
    // The ring will automatically animate to new values
  });
}
```

## Customization

### Colors

The component uses your existing `WasteAppDesignSystem` colors by default:
- Primary Green: For main progress ring
- Secondary Green: For gradient effect
- Waste Category Colors: For different impact types
- Warning Orange: For achievements and milestones

### Animations

- **Progress Animation**: 2 seconds with easeOutCubic curve
- **Pulse Animation**: 1.5 seconds continuous cycle
- **Milestone Animation**: 800ms celebration when reached

### Sizing

- **Default Ring**: 220x220 pixels
- **Compact Ring**: 100x100 pixels (configurable)
- **Stroke Width**: 12 pixels
- **Milestone Markers**: 6-8 pixel radius

## Performance Considerations

- Uses efficient `CustomPainter` for ring rendering
- Animations are optimized with proper dispose methods
- Milestone checks only trigger when progress changes
- Glow effects use `MaskFilter` for hardware acceleration

## Accessibility

- Supports screen readers with semantic labels
- High contrast mode compatible
- Touch targets meet minimum size requirements
- Color-blind friendly with multiple visual cues

## Examples in Your App Context

### Waste Classification Progress
```dart
ImpactVisualizationRing(
  progress: classificationService.todayProgress,
  currentValue: classificationService.itemsClassifiedToday.toDouble(),
  targetValue: settingsService.dailyGoal.toDouble(),
  unit: 'items classified',
  title: 'Daily Classification Goal',
  subtitle: 'Items classified today',
  centerText: 'Keep it up!',
)
```

### Environmental Impact Tracking
```dart
ImpactVisualizationRing(
  progress: environmentalService.co2SavedProgress,
  currentValue: environmentalService.co2SavedThisMonth,
  targetValue: environmentalService.monthlyCO2Target,
  unit: 'kg CO₂ prevented',
  primaryColor: WasteAppDesignSystem.wetWasteColor,
  title: 'Environmental Impact',
  subtitle: 'CO₂ emissions prevented',
  centerText: 'Saving the planet! 🌍',
)
```

### User Engagement Metrics
```dart
ImpactVisualizationRing(
  progress: gamificationService.streakProgress,
  currentValue: gamificationService.currentStreak.toDouble(),
  targetValue: 30.0, // Monthly streak goal
  unit: 'day streak',
  primaryColor: const Color(0xFFFF6B35),
  title: 'Consistency Streak',
  subtitle: 'Days of continuous use',
  centerText: 'On fire! 🔥',
)
```

## Troubleshooting

### Common Issues

1. **Ring not animating**: Ensure the widget is properly disposed and recreated when progress changes
2. **Milestones not showing**: Check that threshold values are between 0.0 and 1.0
3. **Colors not matching**: Verify `WasteAppDesignSystem` import and color definitions
4. **Performance issues**: Limit the number of impact rings on a single screen

### Debug Tips

```dart
// Add debug prints to track progress updates
ImpactVisualizationRing(
  progress: progress,
  // ... other parameters
  // Add a key to force rebuild when needed
  key: ValueKey('impact_ring_$progress'),
)
```

## Future Enhancements

- [ ] Sound effects for milestone achievements
- [ ] Haptic feedback on progress updates
- [ ] Social sharing of achievements
- [ ] Custom milestone celebration animations
- [ ] Integration with device widgets/complications
- [ ] Offline progress synchronization

---

*This component is part of the Waste Segregation App's advanced UI system. For more information about the design system, see `utils/design_system.dart`.*
