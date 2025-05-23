# Developer Documentation: Enhanced Gamification & Waste Dashboard

> **NOTE:** The canonical, comprehensive developer guide is [`enhanced_developer_guide.md`](./enhanced_developer_guide.md). This file is focused on the gamification and waste analytics dashboard features for developers extending those systems.

This document provides technical details for developers working on or extending the Enhanced Gamification System and Waste Analytics Dashboard features.

## Code Organization

### Enhanced Gamification System

#### Key Files
- `lib/utils/animation_helpers.dart`: Reusable animation utilities
- `lib/widgets/enhanced_gamification_widgets.dart`: Enhanced UI components for gamification
- `lib/services/gamification_service.dart`: Business logic for gamification features
- `lib/screens/result_screen.dart`: Integration of immediate feedback on results screen
- `lib/screens/home_screen.dart`: Integration with home screen UI

#### Key Classes

**Animation Helpers**
```dart
// Create particle burst animation
AnimationHelpers.createParticleBurst(color: Colors.blue, size: 100, controller: animController);

// Create success checkmark animation
AnimationHelpers.createSuccessCheck(color: Colors.green, controller: animController);

// Create bounce animation
Animation<double> bounceAnim = AnimationHelpers.createBounceAnimation(controller);

// Create pulse animation
Animation<double> pulseAnim = AnimationHelpers.createPulseAnimation(controller);
```

**Enhanced Gamification Widgets**
```dart
// Show enhanced achievement notification
EnhancedAchievementNotification(
  achievement: achievement,
  onDismiss: () => Navigator.of(context).pop(),
);

// Show points earned popup
PointsEarnedPopup(
  points: 50,
  action: 'classification',
  onDismiss: () {},
);

// Create floating achievement badge
FloatingAchievementBadge(
  achievement: achievement,
  onTap: () => showAchievementDetails(achievement),
);
```

**Updated Gamification Service**
```dart
// Process a classification with enhanced feedback
final completedChallenges = await gamificationService.processClassification(classification);
```

### Automatic Classification Saving

#### Key Files
- `lib/models/waste_classification.dart`: Model with isSaved property
- `lib/screens/result_screen.dart`: Auto-save implementation
- `lib/widgets/classification_card.dart`: UI handling for saved state

#### Implementation Details

**WasteClassification Model**
```dart
// WasteClassification now includes an isSaved property
class WasteClassification {
  // Other properties...
  bool isSaved; // Track whether classification has been saved

  WasteClassification({
    // Other parameters...
    this.isSaved = false,
  });
  
  // JSON serialization includes isSaved state
  Map<String, dynamic> toJson() {
    return {
      // Other fields...
      'isSaved': isSaved,
    };
  }
  
  // JSON deserialization handles isSaved state
  factory WasteClassification.fromJson(Map<String, dynamic> json) {
    return WasteClassification(
      // Other fields...
      isSaved: json['isSaved'] ?? false,
    );
  }
}
```

**Result Screen Auto-Save**
```dart
// Auto-save implementation in ResultScreen
@override
void initState() {
  super.initState();
  // Other initialization...
  
  // Automatically save the classification
  _autoSaveClassification();
}

// Automatically save classification when screen loads
Future<void> _autoSaveClassification() async {
  try {
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // Update the classification's saved state
    widget.classification.isSaved = true;
    
    await storageService.saveClassification(widget.classification);
    
    setState(() {
      _isSaved = true;
    });
  } catch (e) {
    // Handle error...
  }
}
```

**Classification Card UI**
```dart
// Classification card handles displaying saved state
OutlinedButton.icon(
  onPressed: onSave,
  icon: Icon(
    classification.isSaved ? Icons.check : Icons.save,
    color: classification.isSaved ? Colors.green : categoryColor,
  ),
  label: Text(
    classification.isSaved ? 'Saved' : AppStrings.saveResult,
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: classification.isSaved ? Colors.green : categoryColor,
    side: BorderSide(
      color: classification.isSaved ? Colors.green : categoryColor,
    ),
  ),
),
```

### Waste Analytics Dashboard

#### Key Files
- `lib/screens/waste_dashboard_screen.dart`: Main dashboard implementation
- `lib/widgets/waste_chart_widgets.dart`: Chart components for data visualization

#### Key Classes

**Dashboard Screen**
```dart
// Access dashboard screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WasteDashboardScreen(),
  ),
);
```

**Chart Widgets**
```dart
// Create pie chart for category distribution
WasteCategoryPieChart(
  data: categoryData,
  animationController: _animationController,
);

// Create bar chart for subcategories
TopSubcategoriesBarChart(
  data: subcategoryData,
  animationController: _animationController,
);

// Create line chart for time series
WasteTimeSeriesChart(
  data: timeSeriesData,
  animationController: _animationController,
);
```

## Implementation Guidelines

### 1. Adding New Animations

To add a new animation effect to the gamification system:

1. Create a helper method in `animation_helpers.dart` if it's reusable
2. For widget-specific animations, use the Flutter animation framework in your widget
3. Keep animations short (under 2 seconds) for optimal user experience
4. Consider accessibility implications and provide options to reduce motion when appropriate

Example of adding a new animation helper:
```dart
// In animation_helpers.dart
static Animation<double> createFadeAnimation(AnimationController controller) {
  return Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    ),
  );
}
```

### 2. Adding New Chart Types

To add a new chart type to the Waste Dashboard:

1. Create a new widget class in `waste_chart_widgets.dart`
2. Implement the `build` method to render the chart using fl_chart
3. Include animation support using AnimationController
4. Add the new chart to the appropriate dashboard tab

Example skeleton for a new chart widget:
```dart
class NewChartType extends StatelessWidget {
  final List<ChartData> data;
  final AnimationController animationController;
  
  const NewChartType({
    Key? key,
    required this.data,
    required this.animationController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // Implement chart using fl_chart
        return SomeFlChartWidget(...);
      },
    );
  }
}
```

### 3. Extending Gamification Features

To add a new type of achievement or challenge:

1. Update the relevant enums in `gamification.dart`
2. Add a new processing method in `gamification_service.dart`
3. Add default achievements/challenges in the _getDefault methods
4. Update the UI components to show the new types

Example of adding a new achievement type:
```dart
// In gamification.dart
enum AchievementType {
  // Existing types...
  newAchievementType,
}

// In gamification_service.dart
Future<void> processNewAchievementEvent(SomeData data) async {
  // Process the event and update achievement progress
  await updateAchievementProgress(AchievementType.newAchievementType, 1);
}

// In _getDefaultAchievements()
Achievement(
  id: 'new_achievement',
  title: 'New Achievement',
  description: 'Description of the new achievement',
  type: AchievementType.newAchievementType,
  threshold: 5,
  iconName: 'some_icon',
  color: Colors.purple,
  tier: AchievementTier.bronze,
  pointsReward: 50,
),
```

### 4. Adding Dashboard Insights

To add new insights to the dashboard:

1. Create a new data processing method in `waste_dashboard_screen.dart`
2. Add a UI component to display the insight
3. Add logic to determine when to show the insight

Example of adding a new insight:
```dart
// In waste_dashboard_screen.dart
String? _getNewTypeOfInsight() {
  // Calculate insight based on available data
  if (someCondition) {
    return "Your insight message here based on data analysis";
  }
  return null;
}

// In _getInsight() method
final insights = [
  _getMostCommonCategoryInsight(),
  _getMostCommonSubcategoryInsight(),
  _getTrendInsight(),
  _getImprovementInsight(),
  _getNewTypeOfInsight(), // Add new insight type
];
```

### 5. Adding Time Range Filters

To add a new time range filter to the dashboard:

1. Add a new option to the _selectedTimeRange in `waste_dashboard_screen.dart`
2. Update the UI to show the new option
3. Implement the filtering logic in _filterByTimeRange

Example:
```dart
// Add a new time range option (e.g., last 3 months)
enum TimeRange {
  week,
  month,
  threeMonths, // New option
  allTime,
}

// Update the filtering method
List<WasteClassification> _filterByTimeRange(List<WasteClassification> classifications) {
  final now = DateTime.now();
  
  switch (_selectedTimeRange) {
    // Existing cases...
    
    case 2: // Three months
      final startDate = DateTime(now.year, now.month - 3, now.day);
      return classifications.where((c) => c.timestamp.isAfter(startDate)).toList();
      
    case 3: // All time (previously was case 2)
    default:
      return classifications;
  }
}
```

## Data Flow Architecture

The data flow for the enhanced gamification and dashboard features follows this pattern:

1. **User Action** (e.g., classifying waste)
2. **Service Processing** (GamificationService processes the action)
3. **State Update** (Points, achievements, and challenges are updated)
4. **Feedback Presentation** (Visual feedback is shown to the user)
5. **Data Storage** (Updated state is persisted to local storage)
6. **Dashboard Update** (Dashboard reflects the latest data)

### Flow Diagram for Classification

```
User classifies waste item
    ↓
ResultScreen shows ClassificationFeedback animation
    ↓
GamificationService.processClassification() is called
    → Updates points
    → Updates achievements
    → Updates challenges
    → Persists changes to storage
    ↓
ResultScreen shows:
    → PointsEarnedPopup
    → FloatingAchievementBadge (if earned)
    → EnhancedChallengeCard (if completed)
    ↓
Homepage reflects updated:
    → EnhancedPointsIndicator
    → EnhancedStreakIndicator
    → EnhancedChallengeCard
    ↓
WasteDashboardScreen incorporates new data point
    → Updates charts and visualizations
    → Recalculates insights
```

## Performance Considerations

### Animation Performance

1. **Reduce Overdraw**: Limit the number of transparent layers in animations
2. **Use RepaintBoundary**: Wrap complex animated widgets in RepaintBoundary
3. **Limit Particle Count**: Keep particle effects reasonable (under 50 particles)
4. **Animation Throttling**: Only show one major animation at a time
5. **Device-aware Effects**: Scale down effects on lower-end devices

Example:
```dart
// Wrap complex animations in RepaintBoundary
RepaintBoundary(
  child: AnimationHelpers.createParticleBurst(
    color: color,
    size: 200,
    controller: _animationController,
  ),
),

// Device-aware particle count
final int particleCount = isLowEndDevice ? 20 : 50;
```

### Dashboard Optimization

1. **Lazy Loading**: Only process data for the current tab
2. **Memoization**: Cache processed data to avoid recalculation
3. **Throttle Updates**: Don't update charts on every data change
4. **Limit Data Points**: For time series charts, aggregate data points for long time ranges

Example:
```dart
// Memoize processed data
Map<int, List<Map<String, dynamic>>> _memoizedTimeSeriesData = {};

List<Map<String, dynamic>> _getWasteTimeSeriesData() {
  // Check if we already processed this time range
  if (_memoizedTimeSeriesData.containsKey(_selectedTimeRange)) {
    return _memoizedTimeSeriesData[_selectedTimeRange]!;
  }
  
  // Process data...
  final result = <Map<String, dynamic>>[];
  // ...
  
  // Cache the result
  _memoizedTimeSeriesData[_selectedTimeRange] = result;
  return result;
}
```

## Testing Guidelines

### Unit Tests

Focus on testing:
1. Animation helper functions
2. Data processing methods
3. Insight generation logic
4. Time filtering functionality

Example test for a data processing method:
```dart
test('waste composition calculation should group by category', () {
  // Arrange
  final testData = [
    WasteClassification(category: 'Dry Waste', ...),
    WasteClassification(category: 'Wet Waste', ...),
    WasteClassification(category: 'Dry Waste', ...),
  ];
  
  // Act
  final result = calculateWasteComposition(testData);
  
  // Assert
  expect(result.length, 2); // Only two categories
  expect(result.firstWhere((item) => item.label == 'Dry Waste').value, 2);
  expect(result.firstWhere((item) => item.label == 'Wet Waste').value, 1);
});
```

### Widget Tests

Focus on testing:
1. Chart rendering with different datasets
2. Animation triggers and completion callbacks
3. User interaction with dashboard filters
4. Responsive layout for different screen sizes

Example test for a chart widget:
```dart
testWidgets('pie chart should render with correct segments', (WidgetTester tester) async {
  // Arrange
  final testData = [
    ChartData('Category A', 10, Colors.red),
    ChartData('Category B', 20, Colors.blue),
  ];
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WasteCategoryPieChart(
          data: testData,
          animationController: MockAnimationController(),
        ),
      ),
    ),
  );
  
  // Assert
  expect(find.byType(PieChart), findsOneWidget);
  // More specific assertions about the chart segments...
});
```

### Integration Tests

Focus on testing:
1. End-to-end flow from classification to dashboard update
2. Achievement unlocks and notification display
3. Challenge completion flow
4. Data persistence between app sessions

## Troubleshooting Common Issues

### Animation Issues

**Problem**: Animations are janky or stuttering
**Solution**: 
- Reduce complexity of animations
- Use simpler curves (linear, ease in/out instead of elastic)
- Check for CPU-intensive operations on the main thread

**Problem**: Animations not triggering
**Solution**:
- Check animation controller state (initialized, disposed, etc.)
- Verify animation is properly attached to controller
- Ensure controller.forward() is called

### Chart Issues

**Problem**: Charts not rendering or empty
**Solution**:
- Check if data is empty or null
- Verify that animation controller is properly initialized
- Check chart options for valid configuration

**Problem**: Charts showing incorrect data
**Solution**:
- Log data structure before processing
- Verify time filter logic is working correctly
- Check data aggregation for mathematical errors

### Data Processing Issues

**Problem**: Dashboard shows outdated information
**Solution**:
- Check caching and invalidation logic
- Force refresh data after classifications
- Verify listener pattern is properly implemented

**Problem**: Insights and recommendations are irrelevant
**Solution**:
- Review logic conditions for insight generation
- Ensure thresholds for showing insights are appropriate
- Add more logging to trace insight selection logic

## API Reference

### Animation Helpers

| Method | Description | Parameters |
|--------|-------------|------------|
| `createParticleBurst` | Creates a particle burst animation | `color`, `size`, `controller` |
| `createSuccessCheck` | Creates a checkmark animation | `color`, `controller`, `size` |
| `createBounceAnimation` | Creates a bounce effect | `controller` |
| `createPulseAnimation` | Creates a pulse effect | `controller` |
| `createProgressColorAnimation` | Creates a color transition for progress bars | `controller`, `startColor`, `endColor` |

### Chart Widgets

| Widget | Description | Key Parameters |
|--------|-------------|----------------|
| `WasteCategoryPieChart` | Pie chart for category distribution | `data`, `animationController` |
| `TopSubcategoriesBarChart` | Bar chart for subcategory counts | `data`, `animationController` |
| `WasteTimeSeriesChart` | Line chart for time series | `data`, `animationController` |
| `CategoryDistributionChart` | Stacked area chart for category trends | `data`, `animationController` |
| `WeeklyItemsChart` | Bar chart for weekly progress | `data`, `animationController` |

### Enhanced Gamification Widgets

| Widget | Description | Key Parameters |
|--------|-------------|----------------|
| `EnhancedAchievementNotification` | Full-screen achievement celebration | `achievement`, `onDismiss` |
| `EnhancedChallengeCard` | Animated challenge display | `challenge`, `onTap`, `showCompletionAnimation` |
| `EnhancedStreakIndicator` | Animated streak tracker | `streak`, `onTap` |
| `EnhancedPointsIndicator` | Points and level display | `points`, `previousPoints`, `onTap` |
| `ClassificationFeedback` | Success animation for classifications | `category`, `onComplete` |
| `PointsEarnedPopup` | Transient notification for points | `points`, `action`, `onDismiss` |
| `FloatingAchievementBadge` | Mini-notification for achievements | `achievement`, `onTap` |
