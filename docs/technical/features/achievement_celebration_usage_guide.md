# Achievement Celebration Usage Guide

## Quick Start

To add achievement celebrations to any screen in the WasteWise app, follow these simple steps:

### 1. Import the Widget

```dart
import '../widgets/advanced_ui/achievement_celebration.dart';
```

### 2. Add State Variables

```dart
class _YourScreenState extends State<YourScreen> {
  // Achievement celebration state
  bool _showCelebration = false;
  Achievement? _celebrationAchievement;
  
  // ... other state variables
}
```

### 3. Add Helper Methods

```dart
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
```

### 4. Wrap Your UI in a Stack

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Your existing UI content
        YourExistingContent(),
        
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
```

### 5. Trigger Celebrations

Call `_showAchievementCelebration(achievement)` whenever you want to show a celebration:

```dart
// Example: When user completes an action
void _onUserAction() async {
  // ... perform action
  
  // Check for achievements
  final newAchievement = await checkForNewAchievements();
  if (newAchievement != null) {
    _showAchievementCelebration(newAchievement);
  }
}
```

## Common Use Cases

### Daily Goal Achievement

```dart
Future<void> _checkDailyGoal() async {
  const dailyGoal = 50;
  final profile = await gamificationService.getProfile();
  
  if (profile.points.total >= dailyGoal) {
    final goalAchievement = Achievement(
      id: 'daily_goal_${DateTime.now().day}',
      title: "Daily Goal Reached!",
      description: "You've hit your $dailyGoal-point goal!",
      type: AchievementType.userGoal,
      threshold: dailyGoal,
      pointsReward: 25,
      color: Colors.green,
      iconName: "local_fire_department",
    );
    
    _showAchievementCelebration(goalAchievement);
  }
}
```

### Newly Earned Achievements

```dart
Future<void> _checkNewAchievements(GamificationProfile oldProfile, GamificationProfile newProfile) async {
  final oldEarnedIds = oldProfile.achievements
      .where((a) => a.isEarned)
      .map((a) => a.id)
      .toSet();
  
  final newlyEarned = newProfile.achievements
      .where((a) => a.isEarned && !oldEarnedIds.contains(a.id))
      .toList();
  
  if (newlyEarned.isNotEmpty) {
    // Show celebration for the first newly earned achievement
    _showAchievementCelebration(newlyEarned.first);
  }
}
```

### Custom Achievement

```dart
void _celebrateCustomAchievement() {
  final customAchievement = Achievement(
    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
    title: "Amazing Work!",
    description: "You've done something incredible!",
    type: AchievementType.specialEvent,
    threshold: 1,
    pointsReward: 100,
    color: Colors.purple,
    iconName: "emoji_events",
  );
  
  _showAchievementCelebration(customAchievement);
}
```

## Best Practices

### 1. Filter for Major Achievements

Don't show celebrations for every small achievement:

```dart
bool shouldCelebrate(Achievement achievement) {
  return achievement.tier != AchievementTier.bronze || 
         achievement.pointsReward >= 25;
}

if (shouldCelebrate(newAchievement)) {
  _showAchievementCelebration(newAchievement);
}
```

### 2. Avoid Overlapping Celebrations

```dart
void _showAchievementCelebration(Achievement achievement) {
  // Don't show if already showing
  if (_showCelebration) return;
  
  setState(() {
    _celebrationAchievement = achievement;
    _showCelebration = true;
  });
}
```

### 3. Handle Screen Navigation

```dart
@override
void dispose() {
  // Clean up if needed
  super.dispose();
}
```

## Customization Options

### Custom Duration

```dart
AchievementCelebration(
  achievement: achievement,
  onDismiss: _onCelebrationDismissed,
  duration: const Duration(seconds: 6), // Custom duration
)
```

### Achievement Properties

```dart
Achievement(
  id: 'unique_id',
  title: "Your Title",
  description: "Your description",
  type: AchievementType.yourType,
  threshold: 10,
  pointsReward: 50,
  color: Colors.blue,           // Badge color
  iconName: "star",            // Icon name
  tier: AchievementTier.gold,  // Badge tier
)
```

## Available Icons

Common icon names you can use:
- `"emoji_events"` - Trophy
- `"local_fire_department"` - Fire
- `"star"` - Star
- `"eco"` - Eco leaf
- `"recycling"` - Recycling symbol
- `"lightbulb"` - Light bulb
- `"workspace_premium"` - Premium badge

## Troubleshooting

### Celebration Not Showing

1. Check if `_showCelebration` is true
2. Verify `_celebrationAchievement` is not null
3. Ensure Stack is properly structured
4. Check for console errors

### Multiple Celebrations

1. Add celebration queue system
2. Use `_showCelebration` flag to prevent overlaps
3. Consider delaying subsequent celebrations

### Performance Issues

1. Limit particle count in confetti
2. Dispose animation controllers properly
3. Use `mounted` checks in async operations

## Example Implementation

See the complete implementation in:
- `lib/screens/new_modern_home_screen.dart`
- `lib/screens/result_screen.dart`
- `lib/screens/achievements_screen.dart`

These files demonstrate the full integration pattern and best practices. 