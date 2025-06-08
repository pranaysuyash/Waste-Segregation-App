# Enhanced AI Discovery Content System v2.2.3

## Overview

The Enhanced AI Discovery Content System is a sophisticated, type-safe, and performant framework for creating dynamic "Easter eggs" and personalized discovery quests in the waste segregation app. This system enables AI-powered content generation with robust validation, flexible rule logic, and optimized performance.

## Key Improvements

### 🔧 Strongly Typed Parameters

Instead of raw `Map<String, dynamic>` parameters, the system now uses dedicated value objects:

```dart
// Before: Raw map with potential type errors
final condition = TriggerCondition(
  type: HiddenContentTriggerType.itemCountByTag,
  parameters: {'tag': 'vintage', 'count': '5'}, // String instead of int!
);

// After: Type-safe value objects
final params = ItemCountByTagParams(tag: 'vintage', count: 5);
final condition = TriggerCondition(
  type: HiddenContentTriggerType.itemCountByTag,
  parameters: params.toJson(),
);

// Or use strongly typed getters
expect(condition.tag, equals('vintage'));
expect(condition.count, equals(5));
expect(condition.asItemCountByTag.validate(), isTrue);
```

### 🗺️ Stable JSON Mapping

Enum serialization now uses stable string mappings to prevent breaking changes:

```dart
// Stable mapping prevents issues when enum names change
const _triggerTypeMap = {
  'specific_item_discovery': HiddenContentTriggerType.specificItemDiscovery,
  'item_count_by_tag': HiddenContentTriggerType.itemCountByTag,
  // ... more mappings
};

// JSON output is consistent and stable
final json = condition.toJson();
// json['type'] == 'item_count_by_tag' (stable string)
```

### 🔀 AND/OR Logic Support

Rules now support complex boolean logic:

```dart
// Simple AND logic (default)
final andRule = HiddenContentRule(
  ruleId: 'vintage_collector',
  triggerConditions: [
    // ALL conditions must be met
    vintageItemCondition,
    electronicsCountCondition,
  ],
  allMustMatch: true, // default
);

// OR logic
final orRule = HiddenContentRule(
  ruleId: 'flexible_achievement',
  triggerConditions: [
    // ANY condition can trigger
    vintageItemCondition,
    modernItemCondition,
  ],
  allMustMatch: false,
);

// Complex OR groups of AND conditions
final complexRule = HiddenContentRule(
  ruleId: 'complex_achievement',
  anyOfGroups: [
    [vintageItemCondition], // Group 1: Just vintage items
    [electronicsCondition, plasticCondition], // Group 2: Electronics AND plastic
  ],
);
```

### ⚡ Performance Optimization

The `RuleEvaluationOptimizer` provides O(1) rule lookup:

```dart
// Index all rules by trigger type
RuleEvaluationOptimizer.indexRules(allRules);

// Get only relevant rules for a specific trigger (fast!)
final relevantRules = RuleEvaluationOptimizer.getRulesForTriggerType(
  HiddenContentTriggerType.itemCountByTag,
);

// Direct rule lookup by ID
final rule = RuleEvaluationOptimizer.getRuleById('vintage_collector');

// Performance benefits:
// - Only evaluates relevant rules
// - Skips inactive rules automatically
// - O(1) lookup instead of O(n) iteration
```

### 📝 Template Interpolation

Built-in template engine for dynamic content generation:

```dart
final template = DiscoveryQuestTemplate(
  titleTemplate: 'Find the {material} {item_type} from {era}',
  descriptionTemplate: 'Search for a {rarity} item with {property}',
  // ...
);

// Instantiate with values
final values = {
  'material': 'Plastic',
  'item_type': 'bottle',
  'era': '1990s',
  'rarity': 'rare',
  'property': 'vintage label',
};

final title = template.instantiateTitle(values);
// Result: "Find the Plastic bottle from 1990s"

final description = template.instantiateDescription(values);
// Result: "Search for a rare item with vintage label"

// Validation
final placeholders = template.getRequiredPlaceholders();
final isValid = template.validateInstantiation(values);
```

### ✅ Comprehensive Validation

All models now include robust validation:

```dart
// Parameter validation
final params = ItemCountByTagParams(tag: '', count: 0);
expect(params.validate(), isFalse); // Empty tag and zero count

// Rule validation
final rule = HiddenContentRule(
  ruleId: '', // Empty ID
  contentIdToUnlock: 'content',
  triggerConditions: [invalidCondition],
  // ...
);
expect(rule.validate(), isFalse);

// Template validation
final template = DiscoveryQuestTemplate(
  templateId: 'test',
  titleTemplate: 'Find {item} in {location}',
  // ...
);
final invalidValues = {'item': 'bottle'}; // Missing 'location'
expect(template.validateInstantiation(invalidValues), isFalse);
```

## Value Objects Reference

### SpecificItemDiscoveryParams
```dart
final params = SpecificItemDiscoveryParams(itemId: 'vintage_camera_001');
expect(params.validate(), isTrue); // itemId must be non-empty
```

### ItemCountByTagParams
```dart
final params = ItemCountByTagParams(tag: 'vintage', count: 5);
expect(params.validate(), isTrue); // tag non-empty, count > 0
```

### ClassificationAccuracyStreakParams
```dart
final params = ClassificationAccuracyStreakParams(
  accuracyThreshold: 0.95, // Must be 0.0 < threshold <= 1.0
  streakLength: 10,        // Must be > 0
);
expect(params.validate(), isTrue);
```

### CombinedItemPropertiesParams
```dart
final params = CombinedItemPropertiesParams(
  material: 'Plastic',
  tag: 'single_use',
  era: '1980s',
  count: 3,
);
expect(params.validate(), isTrue); // At least one property + count > 0
```

## Usage Examples

### Creating a Complex Achievement Rule

```dart
final vintageCollectorRule = HiddenContentRule(
  ruleId: 'vintage_collector_master',
  contentIdToUnlock: 'vintage_collector_badge',
  unlockedContentType: UnlockedContentType.badge,
  description: 'Master vintage collector achievement',
  
  // Main conditions (AND logic)
  triggerConditions: [
    TriggerCondition(
      type: HiddenContentTriggerType.itemCountByTag,
      parameters: ItemCountByTagParams(tag: 'vintage', count: 10).toJson(),
    ),
  ],
  
  // Alternative paths (OR groups)
  anyOfGroups: [
    // Path 1: Electronics specialist
    [
      TriggerCondition(
        type: HiddenContentTriggerType.itemCountByCategory,
        parameters: ItemCountByCategoryParams(
          category: 'Electronics', 
          count: 20,
        ).toJson(),
      ),
    ],
    // Path 2: Material expert
    [
      TriggerCondition(
        type: HiddenContentTriggerType.itemCountByMaterial,
        parameters: ItemCountByMaterialParams(
          material: 'Bakelite', 
          count: 5,
        ).toJson(),
      ),
      TriggerCondition(
        type: HiddenContentTriggerType.classificationAccuracyStreak,
        parameters: ClassificationAccuracyStreakParams(
          accuracyThreshold: 0.95,
          streakLength: 15,
        ).toJson(),
      ),
    ],
  ],
  
  pointsBonus: 500,
  notificationMessages: [
    'Congratulations! You\'ve become a Vintage Collector Master!',
    'Your expertise in vintage items is unmatched!',
  ],
);

// Validate the rule
expect(vintageCollectorRule.validate(), isTrue);
```

### Creating a Dynamic Quest Template

```dart
final mysteryQuestTemplate = DiscoveryQuestTemplate(
  templateId: 'mystery_item_quest',
  titleTemplate: 'The Mystery of the Missing {material} {item_type}',
  descriptionTemplate: '''
Our scouts have reported sightings of a rare {rarity} {item_type} 
made from {material} somewhere in the {location} area. 
This item dates back to the {era} and has significant historical value.

Your mission: Find and classify this mysterious {item_type} to unlock 
the secrets of {era} {material} craftsmanship!
''',
  objectiveCriteria: {
    'targetMaterial': '{material}',
    'targetTag': '{rarity}',
    'minConfidence': 0.85,
    'timeLimit': 3600, // 1 hour
  },
  pointsReward: 250,
  achievementIdOnCompletion: 'mystery_solver',
  aiPersonalizationHints: [
    'good_for_intermediate_users',
    'requires_specific_knowledge',
    'location_based_potential',
  ],
  durationDays: 3,
);

// AI personalizes the quest
final personalizedValues = {
  'material': 'Bakelite',
  'item_type': 'radio',
  'rarity': 'vintage',
  'location': 'downtown',
  'era': '1940s',
};

final personalizedQuest = PersonalizedQuest(
  questId: 'mystery_quest_${userId}_${timestamp}',
  title: mysteryQuestTemplate.instantiateTitle(personalizedValues),
  description: mysteryQuestTemplate.instantiateDescription(personalizedValues),
  // ... other fields
);
```

### Performance-Optimized Rule Evaluation

```dart
class DiscoveryService {
  void initializeRules(List<HiddenContentRule> rules) {
    // Index rules for fast lookup
    RuleEvaluationOptimizer.indexRules(rules);
  }
  
  void onItemClassified(Classification classification) {
    // Only evaluate relevant rules
    final relevantRules = RuleEvaluationOptimizer.getRulesForTriggerType(
      HiddenContentTriggerType.specificItemDiscovery,
    );
    
    for (final rule in relevantRules) {
      if (evaluateRule(rule, classification)) {
        unlockContent(rule);
      }
    }
  }
  
  void onUserAchievement(String achievementType) {
    // Fast lookup for specific rules
    final rules = RuleEvaluationOptimizer.getRulesForTriggerType(
      HiddenContentTriggerType.classificationAccuracyStreak,
    );
    
    // Process only active, relevant rules
    // Performance: O(relevant_rules) instead of O(all_rules)
  }
}
```

## Migration Guide

### From v2.2.2 to v2.2.3

The new system is fully backward compatible. Existing code continues to work, but you can gradually adopt the new features:

1. **Immediate Benefits** (no code changes required):
   - Stable JSON serialization
   - Performance optimization
   - Better error handling

2. **Gradual Migration** (optional improvements):
   ```dart
   // Old way (still works)
   final count = condition.parameters['count'] as int? ?? 0;
   
   // New way (recommended)
   final count = condition.count; // Strongly typed getter
   
   // Or even better
   final params = condition.asItemCountByTag;
   if (params.validate()) {
     final count = params.count;
   }
   ```

3. **New Features** (opt-in):
   - Use `RuleEvaluationOptimizer` for performance
   - Add validation to your rule creation
   - Use template interpolation for dynamic content

## Testing

The system includes 41 comprehensive tests covering:

- All value object validation scenarios
- Template interpolation edge cases  
- Rule logic validation (AND/OR combinations)
- Performance optimizer functionality
- JSON serialization stability
- Error handling and edge cases

Run tests with:
```bash
flutter test test/models/ai_discovery_content_test.dart
```

## Performance Characteristics

- **Rule Lookup**: O(1) for relevant rules by trigger type
- **Memory Usage**: Minimal overhead with indexed storage
- **Validation**: Fast with early returns and exception safety
- **Template Processing**: Regex-based with efficient placeholder replacement

## Best Practices

1. **Always validate** rules and templates before using them
2. **Use the optimizer** for performance-critical applications
3. **Leverage strongly typed getters** for cleaner code
4. **Design templates** with clear placeholder naming
5. **Test edge cases** with malformed data
6. **Index rules** when you have many active rules

## Future Enhancements

- Rule dependency chains
- Advanced template functions
- Machine learning integration for personalization
- Real-time rule updates
- Analytics and metrics collection

---

*This enhanced system provides a robust foundation for AI-powered discovery features while maintaining excellent performance and developer experience.* 