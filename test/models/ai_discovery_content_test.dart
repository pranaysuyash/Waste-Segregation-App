import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/ai_discovery_content.dart';

void main() {
  group('UnlockedContentType', () {
    test('should have all expected enum values', () {
      expect(UnlockedContentType.values, hasLength(4));
      expect(UnlockedContentType.values, contains(UnlockedContentType.badge));
      expect(UnlockedContentType.values, contains(UnlockedContentType.achievement));
      expect(UnlockedContentType.values, contains(UnlockedContentType.mapArea));
      expect(UnlockedContentType.values, contains(UnlockedContentType.loreSnippet));
    });
  });

  group('HiddenContentTriggerType', () {
    test('should have all expected enum values', () {
      expect(HiddenContentTriggerType.values, hasLength(7));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.specificItemDiscovery));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.itemCountByTag));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.itemCountByCategory));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.itemCountByMaterial));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.specificItemSequence));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.classificationAccuracyStreak));
      expect(HiddenContentTriggerType.values, contains(HiddenContentTriggerType.combinedItemProperties));
    });
  });

  group('TriggerCondition', () {
    test('should create with required parameters', () {
      final condition = TriggerCondition(
        type: HiddenContentTriggerType.specificItemDiscovery,
        parameters: {'itemId': 'vintage_camera_001'},
      );

      expect(condition.type, equals(HiddenContentTriggerType.specificItemDiscovery));
      expect(condition.parameters, equals({'itemId': 'vintage_camera_001'}));
    });

    test('should serialize to and from JSON correctly', () {
      final condition = TriggerCondition(
        type: HiddenContentTriggerType.itemCountByTag,
        parameters: {'tag': 'vintage', 'count': 5},
      );

      final json = condition.toJson();
      final fromJson = TriggerCondition.fromJson(json);

      expect(fromJson.type, equals(condition.type));
      expect(fromJson.parameters, equals(condition.parameters));
    });

    test('should handle fromJson with null values', () {
      final condition = TriggerCondition.fromJson({});

      expect(condition.type, equals(HiddenContentTriggerType.specificItemDiscovery));
      expect(condition.parameters, equals({}));
    });

    test('should handle fromJson with partial data', () {
      final condition = TriggerCondition.fromJson({
        'type': 'itemCountByCategory',
      });

      expect(condition.type, equals(HiddenContentTriggerType.itemCountByCategory));
      expect(condition.parameters, equals({}));
    });

    test('should copyWith correctly', () {
      final original = TriggerCondition(
        type: HiddenContentTriggerType.specificItemDiscovery,
        parameters: {'itemId': 'original'},
      );

      final updated = original.copyWith(
        type: HiddenContentTriggerType.itemCountByTag,
        parameters: {'tag': 'updated', 'count': 10},
      );

      expect(updated.type, equals(HiddenContentTriggerType.itemCountByTag));
      expect(updated.parameters, equals({'tag': 'updated', 'count': 10}));
      expect(original.type, equals(HiddenContentTriggerType.specificItemDiscovery));
    });

    test('should handle complex parameters', () {
      final condition = TriggerCondition(
        type: HiddenContentTriggerType.specificItemSequence,
        parameters: {
          'items': ['itemA_id', 'itemB_id'],
          'ordered': true,
          'withinSeconds': 300,
          'nestedData': {'level': 2, 'bonus': true}
        },
      );

      final json = condition.toJson();
      final fromJson = TriggerCondition.fromJson(json);

      expect(fromJson.parameters['items'], equals(['itemA_id', 'itemB_id']));
      expect(fromJson.parameters['ordered'], isTrue);
      expect(fromJson.parameters['withinSeconds'], equals(300));
      expect(fromJson.parameters['nestedData'], isMap);
    });
  });

  group('HiddenContentRule', () {
    test('should create with required parameters', () {
      final rule = HiddenContentRule(
        ruleId: 'rule_001',
        contentIdToUnlock: 'vintage_collector_badge',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByTag,
            parameters: {'tag': 'vintage', 'count': 5},
          ),
        ],
        description: 'Unlocks Vintage Collector badge',
      );

      expect(rule.ruleId, equals('rule_001'));
      expect(rule.contentIdToUnlock, equals('vintage_collector_badge'));
      expect(rule.unlockedContentType, equals(UnlockedContentType.badge));
      expect(rule.triggerConditions, hasLength(1));
      expect(rule.description, equals('Unlocks Vintage Collector badge'));
      expect(rule.isActive, isTrue);
      expect(rule.pointsBonus, equals(0));
      expect(rule.notificationMessages, isEmpty);
    });

    test('should create with optional parameters', () {
      final rule = HiddenContentRule(
        ruleId: 'rule_002',
        contentIdToUnlock: 'map_area_secret',
        unlockedContentType: UnlockedContentType.mapArea,
        triggerConditions: [],
        description: 'Unlocks secret map area',
        isActive: false,
        pointsBonus: 100,
        notificationMessages: ['Congratulations!', 'You found a secret!'],
      );

      expect(rule.isActive, isFalse);
      expect(rule.pointsBonus, equals(100));
      expect(rule.notificationMessages, hasLength(2));
    });

    test('should serialize to and from JSON correctly', () {
      final rule = HiddenContentRule(
        ruleId: 'rule_003',
        contentIdToUnlock: 'achievement_001',
        unlockedContentType: UnlockedContentType.achievement,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.classificationAccuracyStreak,
            parameters: {'accuracyThreshold': 0.95, 'streakLength': 10},
          ),
        ],
        description: 'Perfect accuracy achievement',
        pointsBonus: 250,
        notificationMessages: ['Perfect streak!'],
      );

      final json = rule.toJson();
      final fromJson = HiddenContentRule.fromJson(json);

      expect(fromJson.ruleId, equals(rule.ruleId));
      expect(fromJson.contentIdToUnlock, equals(rule.contentIdToUnlock));
      expect(fromJson.unlockedContentType, equals(rule.unlockedContentType));
      expect(fromJson.triggerConditions, hasLength(1));
      expect(fromJson.description, equals(rule.description));
      expect(fromJson.pointsBonus, equals(rule.pointsBonus));
      expect(fromJson.notificationMessages, equals(rule.notificationMessages));
    });

    test('should handle fromJson with null values', () {
      final rule = HiddenContentRule.fromJson({});

      expect(rule.ruleId, equals(''));
      expect(rule.contentIdToUnlock, equals(''));
      expect(rule.unlockedContentType, equals(UnlockedContentType.badge));
      expect(rule.triggerConditions, isEmpty);
      expect(rule.description, equals(''));
      expect(rule.isActive, isTrue);
      expect(rule.pointsBonus, equals(0));
      expect(rule.notificationMessages, isEmpty);
    });

    test('should copyWith correctly', () {
      final original = HiddenContentRule(
        ruleId: 'rule_original',
        contentIdToUnlock: 'original_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [],
        description: 'Original description',
      );

      final updated = original.copyWith(
        ruleId: 'rule_updated',
        pointsBonus: 500,
        isActive: false,
      );

      expect(updated.ruleId, equals('rule_updated'));
      expect(updated.contentIdToUnlock, equals('original_content'));
      expect(updated.pointsBonus, equals(500));
      expect(updated.isActive, isFalse);
      expect(original.ruleId, equals('rule_original'));
      expect(original.pointsBonus, equals(0));
    });

    test('should handle multiple trigger conditions', () {
      final rule = HiddenContentRule(
        ruleId: 'rule_multi',
        contentIdToUnlock: 'complex_achievement',
        unlockedContentType: UnlockedContentType.achievement,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByCategory,
            parameters: {'category': 'Electronics', 'count': 10},
          ),
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByMaterial,
            parameters: {'material': 'Bakelite', 'count': 3},
          ),
        ],
        description: 'Complex multi-condition achievement',
      );

      expect(rule.triggerConditions, hasLength(2));
      expect(rule.triggerConditions[0].type, equals(HiddenContentTriggerType.itemCountByCategory));
      expect(rule.triggerConditions[1].type, equals(HiddenContentTriggerType.itemCountByMaterial));

      final json = rule.toJson();
      final fromJson = HiddenContentRule.fromJson(json);
      expect(fromJson.triggerConditions, hasLength(2));
    });
  });

  group('DiscoveryQuestTemplate', () {
    test('should create with required parameters', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'quest_001',
        titleTemplate: 'The Mystery of the Missing {material}!',
        descriptionTemplate: 'Our scouts report a rare {item_property} {item_category} was last seen near...',
        objectiveCriteria: {'targetTag': 'antique_toy', 'count': 1},
        pointsReward: 100,
      );

      expect(template.templateId, equals('quest_001'));
      expect(template.titleTemplate, contains('{material}'));
      expect(template.descriptionTemplate, contains('{item_property}'));
      expect(template.objectiveCriteria, equals({'targetTag': 'antique_toy', 'count': 1}));
      expect(template.pointsReward, equals(100));
      expect(template.achievementIdOnCompletion, isNull);
      expect(template.aiPersonalizationHints, isEmpty);
      expect(template.isActive, isTrue);
      expect(template.durationDays, equals(7));
    });

    test('should create with optional parameters', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'quest_002',
        titleTemplate: 'Advanced Quest',
        descriptionTemplate: 'A complex quest description',
        objectiveCriteria: {'targetMaterial': 'Bakelite', 'minRarity': 7},
        pointsReward: 500,
        achievementIdOnCompletion: 'master_discoverer',
        aiPersonalizationHints: ['good_for_beginners', 'location_based_potential'],
        isActive: false,
        durationDays: 14,
      );

      expect(template.achievementIdOnCompletion, equals('master_discoverer'));
      expect(template.aiPersonalizationHints, hasLength(2));
      expect(template.isActive, isFalse);
      expect(template.durationDays, equals(14));
    });

    test('should serialize to and from JSON correctly', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'quest_json',
        titleTemplate: 'JSON Quest {type}',
        descriptionTemplate: 'Test description for {type}',
        objectiveCriteria: {
          'targetTag': 'vintage',
          'count': 5,
          'difficulty': 'medium'
        },
        pointsReward: 200,
        achievementIdOnCompletion: 'json_master',
        aiPersonalizationHints: ['test_hint', 'json_compatible'],
        durationDays: 10,
      );

      final json = template.toJson();
      final fromJson = DiscoveryQuestTemplate.fromJson(json);

      expect(fromJson.templateId, equals(template.templateId));
      expect(fromJson.titleTemplate, equals(template.titleTemplate));
      expect(fromJson.descriptionTemplate, equals(template.descriptionTemplate));
      expect(fromJson.objectiveCriteria, equals(template.objectiveCriteria));
      expect(fromJson.pointsReward, equals(template.pointsReward));
      expect(fromJson.achievementIdOnCompletion, equals(template.achievementIdOnCompletion));
      expect(fromJson.aiPersonalizationHints, equals(template.aiPersonalizationHints));
      expect(fromJson.durationDays, equals(template.durationDays));
    });

    test('should handle fromJson with null values', () {
      final template = DiscoveryQuestTemplate.fromJson({});

      expect(template.templateId, equals(''));
      expect(template.titleTemplate, equals(''));
      expect(template.descriptionTemplate, equals(''));
      expect(template.objectiveCriteria, equals({}));
      expect(template.pointsReward, equals(0));
      expect(template.achievementIdOnCompletion, isNull);
      expect(template.aiPersonalizationHints, isEmpty);
      expect(template.isActive, isTrue);
      expect(template.durationDays, equals(7));
    });

    test('should copyWith correctly', () {
      final original = DiscoveryQuestTemplate(
        templateId: 'original_quest',
        titleTemplate: 'Original Title',
        descriptionTemplate: 'Original Description',
        objectiveCriteria: {'original': true},
        pointsReward: 100,
      );

      final updated = original.copyWith(
        templateId: 'updated_quest',
        pointsReward: 300,
        durationDays: 21,
        aiPersonalizationHints: ['updated_hint'],
      );

      expect(updated.templateId, equals('updated_quest'));
      expect(updated.titleTemplate, equals('Original Title'));
      expect(updated.pointsReward, equals(300));
      expect(updated.durationDays, equals(21));
      expect(updated.aiPersonalizationHints, equals(['updated_hint']));
      expect(original.templateId, equals('original_quest'));
      expect(original.pointsReward, equals(100));
    });

    test('should handle complex objective criteria', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'complex_quest',
        titleTemplate: 'Complex Discovery',
        descriptionTemplate: 'A quest with complex criteria',
        objectiveCriteria: {
          'primary': {
            'targetMaterial': 'Plastic',
            'itemCount': 5,
            'timeLimit': 3600
          },
          'secondary': {
            'accuracyRequired': 0.9,
            'streakLength': 3
          },
          'bonus': ['location_diversity', 'speed_completion']
        },
        pointsReward: 1000,
      );

      expect(template.objectiveCriteria['primary'], isMap);
      expect(template.objectiveCriteria['secondary'], isMap);
      expect(template.objectiveCriteria['bonus'], isList);

      final json = template.toJson();
      final fromJson = DiscoveryQuestTemplate.fromJson(json);
      expect(fromJson.objectiveCriteria, equals(template.objectiveCriteria));
    });

    test('should validate template placeholders', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'placeholder_test',
        titleTemplate: 'Find the {material} {item_type} from {era}',
        descriptionTemplate: 'Search for a {rarity} {item_category} with {property}',
        objectiveCriteria: {},
        pointsReward: 50,
      );

      expect(template.titleTemplate, contains('{material}'));
      expect(template.titleTemplate, contains('{item_type}'));
      expect(template.titleTemplate, contains('{era}'));
      expect(template.descriptionTemplate, contains('{rarity}'));
      expect(template.descriptionTemplate, contains('{item_category}'));
      expect(template.descriptionTemplate, contains('{property}'));
    });
  });

  group('Edge Cases and Integration', () {
    test('should handle empty trigger conditions list', () {
      final rule = HiddenContentRule(
        ruleId: 'empty_triggers',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.loreSnippet,
        triggerConditions: [],
        description: 'Rule with no triggers',
      );

      expect(rule.triggerConditions, isEmpty);

      final json = rule.toJson();
      final fromJson = HiddenContentRule.fromJson(json);
      expect(fromJson.triggerConditions, isEmpty);
    });

    test('should handle very large parameter maps', () {
      final largeParameters = <String, dynamic>{};
      for (int i = 0; i < 100; i++) {
        largeParameters['param_$i'] = 'value_$i';
      }

      final condition = TriggerCondition(
        type: HiddenContentTriggerType.combinedItemProperties,
        parameters: largeParameters,
      );

      expect(condition.parameters, hasLength(100));

      final json = condition.toJson();
      final fromJson = TriggerCondition.fromJson(json);
      expect(fromJson.parameters, hasLength(100));
      expect(fromJson.parameters['param_50'], equals('value_50'));
    });

    test('should handle special characters in strings', () {
      final template = DiscoveryQuestTemplate(
        templateId: 'special_chars_123',
        titleTemplate: 'Quest with émojis 🎯 and spëcial chars!',
        descriptionTemplate: 'Description with "quotes" and \'apostrophes\' & symbols',
        objectiveCriteria: {'unicode': '🔍', 'special': 'test@#\$%'},
        pointsReward: 42,
      );

      final json = template.toJson();
      final fromJson = DiscoveryQuestTemplate.fromJson(json);

      expect(fromJson.titleTemplate, equals(template.titleTemplate));
      expect(fromJson.descriptionTemplate, equals(template.descriptionTemplate));
      expect(fromJson.objectiveCriteria['unicode'], equals('🔍'));
    });

    test('should handle boundary values', () {
      final template = DiscoveryQuestTemplate(
        templateId: '',
        titleTemplate: '',
        descriptionTemplate: '',
        objectiveCriteria: {},
        pointsReward: 0,
        durationDays: 0,
      );

      expect(template.templateId, isEmpty);
      expect(template.pointsReward, equals(0));
      expect(template.durationDays, equals(0));

      final json = template.toJson();
      final fromJson = DiscoveryQuestTemplate.fromJson(json);
      expect(fromJson.templateId, isEmpty);
      expect(fromJson.pointsReward, equals(0));
    });
  });
}
