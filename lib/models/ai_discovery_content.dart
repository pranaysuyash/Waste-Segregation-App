// lib/models/ai_discovery_content.dart

// Enum to define what kind of content is being unlocked
enum UnlockedContentType {
  badge,
  achievement,
  mapArea,
  loreSnippet,
}

// Stable JSON mapping for UnlockedContentType to avoid enum rename brittleness
const _unlockedContentTypeMap = {
  'badge': UnlockedContentType.badge,
  'achievement': UnlockedContentType.achievement,
  'map_area': UnlockedContentType.mapArea,
  'lore_snippet': UnlockedContentType.loreSnippet,
};

const _unlockedContentTypeReverseMap = {
  UnlockedContentType.badge: 'badge',
  UnlockedContentType.achievement: 'achievement',
  UnlockedContentType.mapArea: 'map_area',
  UnlockedContentType.loreSnippet: 'lore_snippet',
};

// Enum to define the type of trigger for a hidden content rule
enum HiddenContentTriggerType {
  specificItemDiscovery,
  itemCountByTag,
  itemCountByCategory,
  itemCountByMaterial,
  specificItemSequence,
  classificationAccuracyStreak,
  combinedItemProperties,
}

// Stable JSON mapping for HiddenContentTriggerType
const _triggerTypeMap = {
  'specific_item_discovery': HiddenContentTriggerType.specificItemDiscovery,
  'item_count_by_tag': HiddenContentTriggerType.itemCountByTag,
  'item_count_by_category': HiddenContentTriggerType.itemCountByCategory,
  'item_count_by_material': HiddenContentTriggerType.itemCountByMaterial,
  'specific_item_sequence': HiddenContentTriggerType.specificItemSequence,
  'classification_accuracy_streak': HiddenContentTriggerType.classificationAccuracyStreak,
  'combined_item_properties': HiddenContentTriggerType.combinedItemProperties,
};

const _triggerTypeReverseMap = {
  HiddenContentTriggerType.specificItemDiscovery: 'specific_item_discovery',
  HiddenContentTriggerType.itemCountByTag: 'item_count_by_tag',
  HiddenContentTriggerType.itemCountByCategory: 'item_count_by_category',
  HiddenContentTriggerType.itemCountByMaterial: 'item_count_by_material',
  HiddenContentTriggerType.specificItemSequence: 'specific_item_sequence',
  HiddenContentTriggerType.classificationAccuracyStreak: 'classification_accuracy_streak',
  HiddenContentTriggerType.combinedItemProperties: 'combined_item_properties',
};

// Value objects for strongly typed parameters
class SpecificItemDiscoveryParams {
  final String itemId;
  
  const SpecificItemDiscoveryParams({required this.itemId});
  
  factory SpecificItemDiscoveryParams.from(Map<String, dynamic> params) {
    return SpecificItemDiscoveryParams(
      itemId: params['itemId'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {'itemId': itemId};
  
  bool validate() => itemId.isNotEmpty;
}

class ItemCountByTagParams {
  final String tag;
  final int count;
  
  const ItemCountByTagParams({required this.tag, required this.count});
  
  factory ItemCountByTagParams.from(Map<String, dynamic> params) {
    return ItemCountByTagParams(
      tag: params['tag'] as String? ?? '',
      count: (params['count'] as num?)?.toInt() ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {'tag': tag, 'count': count};
  
  bool validate() => tag.isNotEmpty && count > 0;
}

class ItemCountByCategoryParams {
  final String category;
  final int count;
  
  const ItemCountByCategoryParams({required this.category, required this.count});
  
  factory ItemCountByCategoryParams.from(Map<String, dynamic> params) {
    return ItemCountByCategoryParams(
      category: params['category'] as String? ?? '',
      count: (params['count'] as num?)?.toInt() ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {'category': category, 'count': count};
  
  bool validate() => category.isNotEmpty && count > 0;
}

class ItemCountByMaterialParams {
  final String material;
  final int count;
  
  const ItemCountByMaterialParams({required this.material, required this.count});
  
  factory ItemCountByMaterialParams.from(Map<String, dynamic> params) {
    return ItemCountByMaterialParams(
      material: params['material'] as String? ?? '',
      count: (params['count'] as num?)?.toInt() ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {'material': material, 'count': count};
  
  bool validate() => material.isNotEmpty && count > 0;
}

class SpecificItemSequenceParams {
  final List<String> items;
  final bool ordered;
  final int withinSeconds;
  
  const SpecificItemSequenceParams({
    required this.items,
    required this.ordered,
    required this.withinSeconds,
  });
  
  factory SpecificItemSequenceParams.from(Map<String, dynamic> params) {
    return SpecificItemSequenceParams(
      items: List<String>.from(params['items'] as List<dynamic>? ?? []),
      ordered: params['ordered'] as bool? ?? true,
      withinSeconds: (params['withinSeconds'] as num?)?.toInt() ?? 300,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'items': items,
    'ordered': ordered,
    'withinSeconds': withinSeconds,
  };
  
  bool validate() => items.isNotEmpty && withinSeconds > 0;
}

class ClassificationAccuracyStreakParams {
  final double accuracyThreshold;
  final int streakLength;
  
  const ClassificationAccuracyStreakParams({
    required this.accuracyThreshold,
    required this.streakLength,
  });
  
  factory ClassificationAccuracyStreakParams.from(Map<String, dynamic> params) {
    return ClassificationAccuracyStreakParams(
      accuracyThreshold: (params['accuracyThreshold'] as num?)?.toDouble() ?? 0.95,
      streakLength: (params['streakLength'] as num?)?.toInt() ?? 10,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'accuracyThreshold': accuracyThreshold,
    'streakLength': streakLength,
  };
  
  bool validate() => accuracyThreshold > 0 && accuracyThreshold <= 1.0 && streakLength > 0;
}

class CombinedItemPropertiesParams {
  final String? material;
  final String? tag;
  final String? era;
  final String? category;
  final int count;
  
  const CombinedItemPropertiesParams({
    this.material,
    this.tag,
    this.era,
    this.category,
    required this.count,
  });
  
  factory CombinedItemPropertiesParams.from(Map<String, dynamic> params) {
    return CombinedItemPropertiesParams(
      material: params['material'] as String?,
      tag: params['tag'] as String?,
      era: params['era'] as String?,
      category: params['category'] as String?,
      count: (params['count'] as num?)?.toInt() ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() => {
    if (material != null) 'material': material!,
    if (tag != null) 'tag': tag!,
    if (era != null) 'era': era!,
    if (category != null) 'category': category!,
    'count': count,
  };
  
  bool validate() {
    final hasAtLeastOneProperty = material != null || tag != null || era != null || category != null;
    return hasAtLeastOneProperty && count > 0;
  }
}

// Template interpolation helper
class TemplateInterpolator {
  static final RegExp _placeholderRegex = RegExp(r'\{([^}]+)\}');
  
  /// Instantiate a template string with the provided values
  /// 
  /// Replaces all placeholders in the format {key} with corresponding values.
  /// If a placeholder has no corresponding value, it remains unchanged.
  static String instantiate(String template, Map<String, String> values) {
    return template.replaceAllMapped(_placeholderRegex, (match) {
      final key = match.group(1);
      return values[key] ?? '{$key}'; // Keep placeholder if no value provided
    });
  }
  
  /// Extract all placeholder keys from a template
  /// 
  /// Returns a Set of all unique placeholder keys found in the template.
  static Set<String> extractPlaceholders(String template) {
    return _placeholderRegex.allMatches(template)
        .map((match) => match.group(1)!)
        .toSet();
  }
  
  /// Validate that all placeholders in template have corresponding values
  /// 
  /// Returns true if all placeholders can be filled with the provided values.
  static bool validateTemplate(String template, Map<String, String> values) {
    final placeholders = extractPlaceholders(template);
    return placeholders.every((placeholder) => values.containsKey(placeholder));
  }
}

// Represents a single condition that needs to be met for a HiddenContentRule
class TriggerCondition {
  const TriggerCondition({
    required this.type,
    required this.parameters,
  });

  factory TriggerCondition.fromJson(Map<String, dynamic> json) {
    // Improved null-safety: check type before casting
    final typeValue = json['type'];
    final typeString = typeValue is String ? typeValue : 'specific_item_discovery';
    final type = _triggerTypeMap[typeString] ?? HiddenContentTriggerType.specificItemDiscovery;
    
    return TriggerCondition(
      type: type,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
  
  final HiddenContentTriggerType type;
  final Map<String, dynamic> parameters;

  // Strongly typed parameter getters
  int get count => (parameters['count'] as num?)?.toInt() ?? 0;
  String get tag => parameters['tag'] as String? ?? '';
  String get category => parameters['category'] as String? ?? '';
  String get material => parameters['material'] as String? ?? '';
  String get itemId => parameters['itemId'] as String? ?? '';
  double get accuracyThreshold => (parameters['accuracyThreshold'] as num?)?.toDouble() ?? 0.95;
  int get streakLength => (parameters['streakLength'] as num?)?.toInt() ?? 10;
  List<String> get items => List<String>.from(parameters['items'] as List<dynamic>? ?? []);
  bool get ordered => parameters['ordered'] as bool? ?? true;
  int get withinSeconds => (parameters['withinSeconds'] as num?)?.toInt() ?? 300;
  
  // Strongly typed parameter objects
  SpecificItemDiscoveryParams get asSpecificItemDiscovery => 
      SpecificItemDiscoveryParams.from(parameters);
  
  ItemCountByTagParams get asItemCountByTag => 
      ItemCountByTagParams.from(parameters);
  
  ItemCountByCategoryParams get asItemCountByCategory => 
      ItemCountByCategoryParams.from(parameters);
  
  ItemCountByMaterialParams get asItemCountByMaterial => 
      ItemCountByMaterialParams.from(parameters);
  
  SpecificItemSequenceParams get asSpecificItemSequence => 
      SpecificItemSequenceParams.from(parameters);
  
  ClassificationAccuracyStreakParams get asClassificationAccuracyStreak => 
      ClassificationAccuracyStreakParams.from(parameters);
  
  CombinedItemPropertiesParams get asCombinedItemProperties => 
      CombinedItemPropertiesParams.from(parameters);

  Map<String, dynamic> toJson() => {
    'type': _triggerTypeReverseMap[type] ?? 'specific_item_discovery',
    'parameters': parameters,
  };

  /// Validate that the parameters are valid for this trigger type
  /// 
  /// Returns true if all parameters are valid according to the trigger type's requirements.
  /// Uses exception-safe validation to handle malformed data gracefully.
  bool validate() {
    try {
      switch (type) {
        case HiddenContentTriggerType.specificItemDiscovery:
          return asSpecificItemDiscovery.validate();
        case HiddenContentTriggerType.itemCountByTag:
          return asItemCountByTag.validate();
        case HiddenContentTriggerType.itemCountByCategory:
          return asItemCountByCategory.validate();
        case HiddenContentTriggerType.itemCountByMaterial:
          return asItemCountByMaterial.validate();
        case HiddenContentTriggerType.specificItemSequence:
          return asSpecificItemSequence.validate();
        case HiddenContentTriggerType.classificationAccuracyStreak:
          return asClassificationAccuracyStreak.validate();
        case HiddenContentTriggerType.combinedItemProperties:
          return asCombinedItemProperties.validate();
      }
    } catch (e) {
      return false;
    }
  }

  TriggerCondition copyWith({
    HiddenContentTriggerType? type,
    Map<String, dynamic>? parameters,
  }) {
    return TriggerCondition(
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
    );
  }
}

// Defines a rule for unlocking hidden content with AND/OR logic support
class HiddenContentRule {
  const HiddenContentRule({
    required this.ruleId,
    required this.contentIdToUnlock,
    required this.unlockedContentType,
    required this.triggerConditions,
    required this.description,
    this.isActive = true,
    this.pointsBonus = 0,
    this.notificationMessages = const [],
    this.allMustMatch = true,
    this.anyOfGroups = const [],
  });

  factory HiddenContentRule.fromJson(Map<String, dynamic> json) {
    // Improved null-safety: check type before casting
    final typeValue = json['unlockedContentType'];
    final typeString = typeValue is String ? typeValue : 'badge';
    final unlockedContentType = _unlockedContentTypeMap[typeString] ?? UnlockedContentType.badge;
    
    return HiddenContentRule(
      ruleId: json['ruleId'] ?? '',
      contentIdToUnlock: json['contentIdToUnlock'] ?? '',
      unlockedContentType: unlockedContentType,
      triggerConditions: (json['triggerConditions'] as List<dynamic>? ?? [])
          .map((tc) => TriggerCondition.fromJson(tc as Map<String, dynamic>))
          .toList(),
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      pointsBonus: json['pointsBonus'] ?? 0,
      notificationMessages: List<String>.from(json['notificationMessages'] as List<dynamic>? ?? []),
      allMustMatch: json['allMustMatch'] ?? true,
      anyOfGroups: (json['anyOfGroups'] as List<dynamic>? ?? [])
          .map((group) => (group as List<dynamic>)
              .map((tc) => TriggerCondition.fromJson(tc as Map<String, dynamic>))
              .toList())
          .toList(),
    );
  }
  
  final String ruleId;
  final String contentIdToUnlock;
  final UnlockedContentType unlockedContentType;
  final List<TriggerCondition> triggerConditions; // Main conditions (AND logic if allMustMatch=true)
  final String description;
  final bool isActive;
  final int pointsBonus;
  final List<String> notificationMessages;
  final bool allMustMatch; // If false, any condition can trigger (OR logic)
  final List<List<TriggerCondition>> anyOfGroups; // OR groups of AND conditions

  Map<String, dynamic> toJson() => {
    'ruleId': ruleId,
    'contentIdToUnlock': contentIdToUnlock,
    'unlockedContentType': _unlockedContentTypeReverseMap[unlockedContentType] ?? 'badge',
    'triggerConditions': triggerConditions.map((tc) => tc.toJson()).toList(),
    'description': description,
    'isActive': isActive,
    'pointsBonus': pointsBonus,
    'notificationMessages': notificationMessages,
    'allMustMatch': allMustMatch,
    'anyOfGroups': anyOfGroups.map((group) => 
        group.map((tc) => tc.toJson()).toList()).toList(),
  };
  
  /// Validate the entire rule and all its conditions
  /// 
  /// Performs comprehensive validation including basic rule structure,
  /// all trigger conditions, and anyOfGroups conditions.
  /// Returns false if any validation fails or if an exception occurs.
  bool validate() {
    try {
      // Basic validation
      if (ruleId.isEmpty || contentIdToUnlock.isEmpty) return false;
      if (pointsBonus < 0) return false;
      
      // Validate all trigger conditions
      if (!triggerConditions.every((condition) => condition.validate())) {
        return false;
      }
      
      // Validate anyOfGroups conditions
      for (final group in anyOfGroups) {
        if (!group.every((condition) => condition.validate())) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get all trigger types used in this rule for indexing
  /// 
  /// Returns a Set of all HiddenContentTriggerType values used in both
  /// the main triggerConditions and all anyOfGroups. This is used by
  /// the RuleEvaluationOptimizer for efficient rule indexing.
  Set<HiddenContentTriggerType> getTriggerTypes() {
    final types = <HiddenContentTriggerType>{};
    types.addAll(triggerConditions.map((c) => c.type));
    for (final group in anyOfGroups) {
      types.addAll(group.map((c) => c.type));
    }
    return types;
  }
  
  /// Check if this rule should be evaluated for a given trigger type
  /// 
  /// Returns true if this rule contains any conditions that match the
  /// specified trigger type. Used for performance optimization to avoid
  /// evaluating irrelevant rules.
  bool isRelevantForTriggerType(HiddenContentTriggerType triggerType) {
    return getTriggerTypes().contains(triggerType);
  }
  
  HiddenContentRule copyWith({
    String? ruleId,
    String? contentIdToUnlock,
    UnlockedContentType? unlockedContentType,
    List<TriggerCondition>? triggerConditions,
    String? description,
    bool? isActive,
    int? pointsBonus,
    List<String>? notificationMessages,
    bool? allMustMatch,
    List<List<TriggerCondition>>? anyOfGroups,
  }) {
    return HiddenContentRule(
      ruleId: ruleId ?? this.ruleId,
      contentIdToUnlock: contentIdToUnlock ?? this.contentIdToUnlock,
      unlockedContentType: unlockedContentType ?? this.unlockedContentType,
      triggerConditions: triggerConditions ?? this.triggerConditions,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      pointsBonus: pointsBonus ?? this.pointsBonus,
      notificationMessages: notificationMessages ?? this.notificationMessages,
      allMustMatch: allMustMatch ?? this.allMustMatch,
      anyOfGroups: anyOfGroups ?? this.anyOfGroups,
    );
  }
}

// Template for AI-Personalized Discovery Quests with enhanced validation
class DiscoveryQuestTemplate {
  const DiscoveryQuestTemplate({
    required this.templateId,
    required this.titleTemplate,
    required this.descriptionTemplate,
    required this.objectiveCriteria,
    required this.pointsReward,
    this.achievementIdOnCompletion,
    this.aiPersonalizationHints = const [],
    this.isActive = true,
    this.durationDays = 7,
  });

  factory DiscoveryQuestTemplate.fromJson(Map<String, dynamic> json) {
    return DiscoveryQuestTemplate(
      templateId: json['templateId'] ?? '',
      titleTemplate: json['titleTemplate'] ?? '',
      descriptionTemplate: json['descriptionTemplate'] ?? '',
      objectiveCriteria: Map<String, dynamic>.from(json['objectiveCriteria'] ?? {}),
      pointsReward: json['pointsReward'] ?? 0,
      achievementIdOnCompletion: json['achievementIdOnCompletion'],
      aiPersonalizationHints: List<String>.from(json['aiPersonalizationHints'] as List<dynamic>? ?? []),
      isActive: json['isActive'] ?? true,
      durationDays: json['durationDays'] ?? 7,
    );
  }
  
  final String templateId;
  final String titleTemplate;
  final String descriptionTemplate;
  final Map<String, dynamic> objectiveCriteria;
  final int pointsReward;
  final String? achievementIdOnCompletion;
  final List<String> aiPersonalizationHints;
  final bool isActive;
  final int durationDays;

  /// Instantiate the title template with provided values
  /// 
  /// Uses the TemplateInterpolator to replace placeholders in the title template.
  String instantiateTitle(Map<String, String> values) {
    return TemplateInterpolator.instantiate(titleTemplate, values);
  }
  
  /// Instantiate the description template with provided values
  /// 
  /// Uses the TemplateInterpolator to replace placeholders in the description template.
  String instantiateDescription(Map<String, String> values) {
    return TemplateInterpolator.instantiate(descriptionTemplate, values);
  }
  
  /// Get all placeholders used in title and description templates
  /// 
  /// Returns a Set of all unique placeholder keys required to fully
  /// instantiate both the title and description templates.
  Set<String> getRequiredPlaceholders() {
    final titlePlaceholders = TemplateInterpolator.extractPlaceholders(titleTemplate);
    final descriptionPlaceholders = TemplateInterpolator.extractPlaceholders(descriptionTemplate);
    return {...titlePlaceholders, ...descriptionPlaceholders};
  }
  
  /// Validate the template and objective criteria
  /// 
  /// Checks that all required fields are present and valid.
  /// Returns false if any validation fails or if an exception occurs.
  bool validate() {
    try {
      if (templateId.isEmpty || titleTemplate.isEmpty || descriptionTemplate.isEmpty) {
        return false;
      }
      if (pointsReward < 0 || durationDays <= 0) return false;
      if (objectiveCriteria.isEmpty) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Validate that the provided values can fill all template placeholders
  /// 
  /// Returns true if all placeholders in both title and description templates
  /// have corresponding values in the provided map.
  bool validateInstantiation(Map<String, String> values) {
    return TemplateInterpolator.validateTemplate(titleTemplate, values) &&
           TemplateInterpolator.validateTemplate(descriptionTemplate, values);
  }

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'titleTemplate': titleTemplate,
    'descriptionTemplate': descriptionTemplate,
    'objectiveCriteria': objectiveCriteria,
    'pointsReward': pointsReward,
    'achievementIdOnCompletion': achievementIdOnCompletion,
    'aiPersonalizationHints': aiPersonalizationHints,
    'isActive': isActive,
    'durationDays': durationDays,
  };

  DiscoveryQuestTemplate copyWith({
    String? templateId,
    String? titleTemplate,
    String? descriptionTemplate,
    Map<String, dynamic>? objectiveCriteria,
    int? pointsReward,
    String? achievementIdOnCompletion,
    List<String>? aiPersonalizationHints,
    bool? isActive,
    int? durationDays,
  }) {
    return DiscoveryQuestTemplate(
      templateId: templateId ?? this.templateId,
      titleTemplate: titleTemplate ?? this.titleTemplate,
      descriptionTemplate: descriptionTemplate ?? this.descriptionTemplate,
      objectiveCriteria: objectiveCriteria ?? this.objectiveCriteria,
      pointsReward: pointsReward ?? this.pointsReward,
      achievementIdOnCompletion: achievementIdOnCompletion ?? this.achievementIdOnCompletion,
      aiPersonalizationHints: aiPersonalizationHints ?? this.aiPersonalizationHints,
      isActive: isActive ?? this.isActive,
      durationDays: durationDays ?? this.durationDays,
    );
  }
}

// Performance optimization helper for rule evaluation
class RuleEvaluationOptimizer {
  static final Map<HiddenContentTriggerType, List<HiddenContentRule>> _rulesByTriggerType = {};
  static final Map<String, HiddenContentRule> _rulesById = {};
  
  /// Index rules by trigger type for fast lookup
  /// 
  /// Creates optimized indexes for rule evaluation. Only active rules are indexed.
  /// Rules are organized by trigger type for O(1) lookup during evaluation.
  /// Call this method whenever rules are updated to refresh the indexes.
  static void indexRules(List<HiddenContentRule> rules) {
    _rulesByTriggerType.clear();
    _rulesById.clear();
    
    for (final rule in rules.where((r) => r.isActive)) {
      _rulesById[rule.ruleId] = rule;
      
      for (final triggerType in rule.getTriggerTypes()) {
        _rulesByTriggerType.putIfAbsent(triggerType, () => []).add(rule);
      }
    }
  }
  
  /// Get only rules relevant to a specific trigger type
  /// 
  /// Returns a list of rules that contain conditions matching the specified
  /// trigger type. This enables efficient rule evaluation by only processing
  /// relevant rules instead of all rules.
  static List<HiddenContentRule> getRulesForTriggerType(HiddenContentTriggerType triggerType) {
    return _rulesByTriggerType[triggerType] ?? [];
  }
  
  /// Get rule by ID for fast lookup
  /// 
  /// Provides O(1) access to rules by their unique ID.
  /// Returns null if the rule is not found or is inactive.
  static HiddenContentRule? getRuleById(String ruleId) {
    return _rulesById[ruleId];
  }
  
  /// Get all active rules
  /// 
  /// Returns a list of all currently active and indexed rules.
  /// Useful for administrative operations and bulk processing.
  static List<HiddenContentRule> getAllActiveRules() {
    return _rulesById.values.toList();
  }
  
  /// Clear the index (call when rules are updated)
  /// 
  /// Clears all internal indexes. Call this before re-indexing with
  /// updated rules to ensure clean state.
  static void clearIndex() {
    _rulesByTriggerType.clear();
    _rulesById.clear();
  }
} 