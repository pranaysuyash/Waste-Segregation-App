// lib/models/ai_discovery_content.dart

// Enum to define what kind of content is being unlocked
enum UnlockedContentType {
  badge,
  achievement, // If you distinguish from badges
  mapArea,
  loreSnippet,
  // Potentially cosmetic items, new app themes, etc.
}

// Enum to define the type of trigger for a hidden content rule
enum HiddenContentTriggerType {
  specificItemDiscovery,     // e.g., params: { "itemId": "vintage_camera_001" }
  itemCountByTag,          // e.g., params: { "tag": "vintage", "count": 5 }
  itemCountByCategory,     // e.g., params: { "category": "Electronics", "count": 10 }
  itemCountByMaterial,     // e.g., params: { "material": "Bakelite", "count": 3 }
  specificItemSequence,    // e.g., params: { "items": ["itemA_id", "itemB_id"], "ordered": true, "withinSeconds": 300 }
  classificationAccuracyStreak, // e.g., params: { "accuracyThreshold": 0.95, "streakLength": 10 }
  combinedItemProperties,  // e.g., params: { "material": "Plastic", "tag": "single_use", "era": "1980s", "count": 3 }
  // ... add more as needed
}

// Represents a single condition that needs to be met for a HiddenContentRule
class TriggerCondition { // Parameters specific to the trigger type

  const TriggerCondition({
    required this.type,
    required this.parameters,
  });

  factory TriggerCondition.fromJson(Map<String, dynamic> json) {
    return TriggerCondition(
      type: HiddenContentTriggerType.values.byName(json['type'] ?? HiddenContentTriggerType.specificItemDiscovery.name),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
  final HiddenContentTriggerType type;
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'parameters': parameters,
  };

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

// Defines a rule for unlocking hidden content (badges, map areas, lore, etc.)
// These rules would be curated (possibly AI-suggested initially) and stored.
class HiddenContentRule { // Potential messages to show user

  const HiddenContentRule({
    required this.ruleId,
    required this.contentIdToUnlock,
    required this.unlockedContentType,
    required this.triggerConditions,
    required this.description,
    this.isActive = true,
    this.pointsBonus = 0,
    this.notificationMessages = const [],
  });

  factory HiddenContentRule.fromJson(Map<String, dynamic> json) {
    return HiddenContentRule(
      ruleId: json['ruleId'] ?? '',
      contentIdToUnlock: json['contentIdToUnlock'] ?? '',
      unlockedContentType: UnlockedContentType.values.byName(json['unlockedContentType'] ?? UnlockedContentType.badge.name),
      triggerConditions: (json['triggerConditions'] as List<dynamic>? ?? [])
          .map((tc) => TriggerCondition.fromJson(tc as Map<String, dynamic>))
          .toList(),
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      pointsBonus: json['pointsBonus'] ?? 0,
      notificationMessages: List<String>.from(json['notificationMessages'] as List<dynamic>? ?? []),
    );
  }
  final String ruleId; // Unique ID for this rule
  final String contentIdToUnlock; // ID of the Badge, Achievement, MapArea, LoreSnippet etc.
  final UnlockedContentType unlockedContentType;
  final List<TriggerCondition> triggerConditions; // A list of conditions that must ALL be met
  final String description; // For admin/curation: "Unlocks 'Vintage Collector' badge"
  final bool isActive;
  final int pointsBonus; // Optional points awarded directly when this rule triggers
  final List<String> notificationMessages;

  Map<String, dynamic> toJson() => {
    'ruleId': ruleId,
    'contentIdToUnlock': contentIdToUnlock,
    'unlockedContentType': unlockedContentType.name,
    'triggerConditions': triggerConditions.map((tc) => tc.toJson()).toList(),
    'description': description,
    'isActive': isActive,
    'pointsBonus': pointsBonus,
    'notificationMessages': notificationMessages,
  };
  
  HiddenContentRule copyWith({
    String? ruleId,
    String? contentIdToUnlock,
    UnlockedContentType? unlockedContentType,
    List<TriggerCondition>? triggerConditions,
    String? description,
    bool? isActive,
    int? pointsBonus,
    List<String>? notificationMessages,
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
    );
  }
}

// Template for AI-Personalized Discovery Quests
// These would be curated templates that the AI can select and fill in.
class DiscoveryQuestTemplate { // Optional: How long the quest is available once personalized/offered

  const DiscoveryQuestTemplate({
    required this.templateId,
    required this.titleTemplate,
    required this.descriptionTemplate,
    required this.objectiveCriteria,
    required this.pointsReward,
    this.achievementIdOnCompletion,
    this.aiPersonalizationHints = const [],
    this.isActive = true,
    this.durationDays = 7, // Default duration
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
  final String titleTemplate; // e.g., "The Mystery of the Missing {material}!"
  final String descriptionTemplate; // "Our scouts report a rare {item_property} {item_category} was last seen near..."
                                  // Placeholders like {material}, {item_property}, {item_category} can be filled by AI.
  final Map<String, dynamic> objectiveCriteria; // Defines what needs to be found/done.
                                             // e.g., { "targetTag": "antique_toy", "count": 1 }
                                             // or { "targetMaterial": "Bakelite", "minRarity": 7 }
  final int pointsReward;
  final String? achievementIdOnCompletion; // Optional: ID of an Achievement to award
  final List<String> aiPersonalizationHints; // Tags for AI: "good_for_beginners", "needs_specific_item_type", "location_based_potential"
  final bool isActive;
  final int durationDays;

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