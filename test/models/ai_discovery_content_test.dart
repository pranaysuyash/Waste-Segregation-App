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

  group('Value Objects for Strongly Typed Parameters', () {
    group('SpecificItemDiscoveryParams', () {
      test('should create and validate correctly', () {
        const params = SpecificItemDiscoveryParams(itemId: 'vintage_camera_001');
        expect(params.itemId, equals('vintage_camera_001'));
        expect(params.validate(), isTrue);
      });

      test('should fail validation with empty itemId', () {
        const params = SpecificItemDiscoveryParams(itemId: '');
        expect(params.validate(), isFalse);
      });

      test('should serialize to/from JSON', () {
        const params = SpecificItemDiscoveryParams(itemId: 'test_item');
        final json = params.toJson();
        final fromJson = SpecificItemDiscoveryParams.from(json);
        expect(fromJson.itemId, equals(params.itemId));
      });
    });

    group('ItemCountByTagParams', () {
      test('should create and validate correctly', () {
        const params = ItemCountByTagParams(tag: 'vintage', count: 5);
        expect(params.tag, equals('vintage'));
        expect(params.count, equals(5));
        expect(params.validate(), isTrue);
      });

      test('should fail validation with invalid values', () {
        const params1 = ItemCountByTagParams(tag: '', count: 5);
        const params2 = ItemCountByTagParams(tag: 'vintage', count: 0);
        expect(params1.validate(), isFalse);
        expect(params2.validate(), isFalse);
      });
    });

    group('ClassificationAccuracyStreakParams', () {
      test('should create and validate correctly', () {
        const params = ClassificationAccuracyStreakParams(
          accuracyThreshold: 0.95,
          streakLength: 10,
        );
        expect(params.accuracyThreshold, equals(0.95));
        expect(params.streakLength, equals(10));
        expect(params.validate(), isTrue);
      });

      test('should fail validation with invalid threshold', () {
        const params1 = ClassificationAccuracyStreakParams(
          accuracyThreshold: 1.5, // > 1.0
          streakLength: 10,
        );
        const params2 = ClassificationAccuracyStreakParams(
          accuracyThreshold: 0.0, // = 0.0
          streakLength: 10,
        );
        expect(params1.validate(), isFalse);
        expect(params2.validate(), isFalse);
      });
    });

    group('CombinedItemPropertiesParams', () {
      test('should create and validate correctly', () {
        const params = CombinedItemPropertiesParams(
          material: 'Plastic',
          tag: 'single_use',
          era: '1980s',
          count: 3,
        );
        expect(params.material, equals('Plastic'));
        expect(params.tag, equals('single_use'));
        expect(params.era, equals('1980s'));
        expect(params.count, equals(3));
        expect(params.validate(), isTrue);
      });

      test('should fail validation with no properties', () {
        const params = CombinedItemPropertiesParams(count: 3);
        expect(params.validate(), isFalse);
      });

      test('should validate with at least one property', () {
        const params = CombinedItemPropertiesParams(
          material: 'Plastic',
          count: 1,
        );
        expect(params.validate(), isTrue);
      });
    });
  });

  group('TemplateInterpolator', () {
    test('should instantiate templates correctly', () {
      const template = 'Find the {material} {item_type} from {era}';
      final values = {
        'material': 'Plastic',
        'item_type': 'bottle',
        'era': '1990s',
      };
      
      final result = TemplateInterpolator.instantiate(template, values);
      expect(result, equals('Find the Plastic bottle from 1990s'));
    });

    test('should keep placeholders when values missing', () {
      const template = 'Find the {material} {item_type}';
      final values = {'material': 'Plastic'};
      
      final result = TemplateInterpolator.instantiate(template, values);
      expect(result, equals('Find the Plastic {item_type}'));
    });

    test('should extract placeholders correctly', () {
      const template = 'Quest for {material} and {category} items from {era}';
      final placeholders = TemplateInterpolator.extractPlaceholders(template);
      
      expect(placeholders, hasLength(3));
      expect(placeholders, contains('material'));
      expect(placeholders, contains('category'));
      expect(placeholders, contains('era'));
    });

    test('should validate templates correctly', () {
      const template = 'Find {item} in {location}';
      final validValues = {'item': 'bottle', 'location': 'park'};
      final invalidValues = {'item': 'bottle'}; // missing location
      
      expect(TemplateInterpolator.validateTemplate(template, validValues), isTrue);
      expect(TemplateInterpolator.validateTemplate(template, invalidValues), isFalse);
    });
  });

  group('TriggerCondition with Strongly Typed Getters', () {
    test('should provide strongly typed getters', () {
      const condition = TriggerCondition(
        type: HiddenContentTriggerType.itemCountByTag,
        parameters: {'tag': 'vintage', 'count': 5},
      );

      expect(condition.tag, equals('vintage'));
      expect(condition.count, equals(5));
    });

    test('should provide strongly typed parameter objects', () {
      const condition = TriggerCondition(
        type: HiddenContentTriggerType.itemCountByTag,
        parameters: {'tag': 'vintage', 'count': 5},
      );

      final params = condition.asItemCountByTag;
      expect(params.tag, equals('vintage'));
      expect(params.count, equals(5));
      expect(params.validate(), isTrue);
    });

    test('should validate parameters correctly', () {
      const validCondition = TriggerCondition(
        type: HiddenContentTriggerType.specificItemDiscovery,
        parameters: {'itemId': 'valid_item'},
      );
      
      const invalidCondition = TriggerCondition(
        type: HiddenContentTriggerType.specificItemDiscovery,
        parameters: {'itemId': ''}, // empty itemId
      );

      expect(validCondition.validate(), isTrue);
      expect(invalidCondition.validate(), isFalse);
    });

    test('should use stable JSON mapping for serialization', () {
      const condition = TriggerCondition(
        type: HiddenContentTriggerType.itemCountByTag,
        parameters: {'tag': 'vintage', 'count': 5},
      );

      final json = condition.toJson();
      expect(json['type'], equals('item_count_by_tag')); // stable string format

      final fromJson = TriggerCondition.fromJson(json);
      expect(fromJson.type, equals(HiddenContentTriggerType.itemCountByTag));
    });
  });

  group('HiddenContentRule with AND/OR Logic', () {
    test('should support AND logic (default)', () {
      const rule = HiddenContentRule(
        ruleId: 'and_rule',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByTag,
            parameters: {'tag': 'vintage', 'count': 5},
          ),
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByCategory,
            parameters: {'category': 'Electronics', 'count': 3},
          ),
        ],
        description: 'AND rule test',
        allMustMatch: true,
      );

      expect(rule.allMustMatch, isTrue);
      expect(rule.triggerConditions, hasLength(2));
    });

    test('should support OR logic', () {
      const rule = HiddenContentRule(
        ruleId: 'or_rule',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByTag,
            parameters: {'tag': 'vintage', 'count': 5},
          ),
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByCategory,
            parameters: {'category': 'Electronics', 'count': 3},
          ),
        ],
        description: 'OR rule test',
        allMustMatch: false,
      );

      expect(rule.allMustMatch, isFalse);
    });

    test('should support anyOfGroups for complex OR logic', () {
      const rule = HiddenContentRule(
        ruleId: 'complex_rule',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [],
        description: 'Complex OR rule test',
        anyOfGroups: [
          [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByTag,
              parameters: {'tag': 'vintage', 'count': 5},
            ),
          ],
          [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByCategory,
              parameters: {'category': 'Electronics', 'count': 10},
            ),
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByMaterial,
              parameters: {'material': 'Plastic', 'count': 3},
            ),
          ],
        ],
      );

      expect(rule.anyOfGroups, hasLength(2));
      expect(rule.anyOfGroups[0], hasLength(1));
      expect(rule.anyOfGroups[1], hasLength(2));
    });

    test('should validate rules correctly', () {
      const validRule = HiddenContentRule(
        ruleId: 'valid_rule',
        contentIdToUnlock: 'valid_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.specificItemDiscovery,
            parameters: {'itemId': 'valid_item'},
          ),
        ],
        description: 'Valid rule',
        pointsBonus: 100,
      );

      const invalidRule = HiddenContentRule(
        ruleId: '', // empty ruleId
        contentIdToUnlock: 'content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [],
        description: 'Invalid rule',
      );

      expect(validRule.validate(), isTrue);
      expect(invalidRule.validate(), isFalse);
    });

    test('should get trigger types for indexing', () {
      const rule = HiddenContentRule(
        ruleId: 'multi_trigger_rule',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByTag,
            parameters: {'tag': 'vintage', 'count': 5},
          ),
        ],
        description: 'Multi trigger rule',
        anyOfGroups: [
          [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByCategory,
              parameters: {'category': 'Electronics', 'count': 3},
            ),
          ],
        ],
      );

      final triggerTypes = rule.getTriggerTypes();
      expect(triggerTypes, hasLength(2));
      expect(triggerTypes, contains(HiddenContentTriggerType.itemCountByTag));
      expect(triggerTypes, contains(HiddenContentTriggerType.itemCountByCategory));
    });

    test('should check relevance for trigger types', () {
      const rule = HiddenContentRule(
        ruleId: 'relevance_test',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.badge,
        triggerConditions: [
          TriggerCondition(
            type: HiddenContentTriggerType.itemCountByTag,
            parameters: {'tag': 'vintage', 'count': 5},
          ),
        ],
        description: 'Relevance test rule',
      );

      expect(rule.isRelevantForTriggerType(HiddenContentTriggerType.itemCountByTag), isTrue);
      expect(rule.isRelevantForTriggerType(HiddenContentTriggerType.itemCountByCategory), isFalse);
    });

    test('should use stable JSON mapping for UnlockedContentType', () {
      const rule = HiddenContentRule(
        ruleId: 'json_test',
        contentIdToUnlock: 'test_content',
        unlockedContentType: UnlockedContentType.mapArea,
        triggerConditions: [],
        description: 'JSON test rule',
      );

      final json = rule.toJson();
      expect(json['unlockedContentType'], equals('map_area')); // stable string format

      final fromJson = HiddenContentRule.fromJson(json);
      expect(fromJson.unlockedContentType, equals(UnlockedContentType.mapArea));
    });
  });

  group('DiscoveryQuestTemplate with Enhanced Features', () {
    test('should instantiate title and description templates', () {
      const template = DiscoveryQuestTemplate(
        templateId: 'instantiation_test',
        titleTemplate: 'Find the {material} {item_type}',
        descriptionTemplate: 'Search for a {rarity} item from {era}',
        objectiveCriteria: {},
        pointsReward: 100,
      );

      final values = {
        'material': 'Plastic',
        'item_type': 'bottle',
        'rarity': 'rare',
        'era': '1990s',
      };

      final title = template.instantiateTitle(values);
      final description = template.instantiateDescription(values);

      expect(title, equals('Find the Plastic bottle'));
      expect(description, equals('Search for a rare item from 1990s'));
    });

    test('should get required placeholders', () {
      const template = DiscoveryQuestTemplate(
        templateId: 'placeholder_test',
        titleTemplate: 'Quest for {material} and {category}',
        descriptionTemplate: 'Find items from {era} with {property}',
        objectiveCriteria: {},
        pointsReward: 100,
      );

      final placeholders = template.getRequiredPlaceholders();
      expect(placeholders, hasLength(4));
      expect(placeholders, contains('material'));
      expect(placeholders, contains('category'));
      expect(placeholders, contains('era'));
      expect(placeholders, contains('property'));
    });

    test('should validate template structure', () {
      const validTemplate = DiscoveryQuestTemplate(
        templateId: 'valid_template',
        titleTemplate: 'Valid Title',
        descriptionTemplate: 'Valid Description',
        objectiveCriteria: {'target': 'something'},
        pointsReward: 100,
        durationDays: 7,
      );

      const invalidTemplate = DiscoveryQuestTemplate(
        templateId: '', // empty templateId
        titleTemplate: 'Title',
        descriptionTemplate: 'Description',
        objectiveCriteria: {},
        pointsReward: -10, // negative points
        durationDays: 0, // zero duration
      );

      expect(validTemplate.validate(), isTrue);
      expect(invalidTemplate.validate(), isFalse);
    });

    test('should validate instantiation with values', () {
      const template = DiscoveryQuestTemplate(
        templateId: 'validation_test',
        titleTemplate: 'Find {item} in {location}',
        descriptionTemplate: 'Search for {item}',
        objectiveCriteria: {},
        pointsReward: 100,
      );

      final validValues = {'item': 'bottle', 'location': 'park'};
      final invalidValues = {'item': 'bottle'}; // missing location

      expect(template.validateInstantiation(validValues), isTrue);
      expect(template.validateInstantiation(invalidValues), isFalse);
    });
  });

  group('RuleEvaluationOptimizer', () {
    setUp(() {
      RuleEvaluationOptimizer.clearIndex();
    });

    test('should index rules by trigger type', () {
      final rules = [
        const HiddenContentRule(
          ruleId: 'rule1',
          contentIdToUnlock: 'content1',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByTag,
              parameters: {'tag': 'vintage', 'count': 5},
            ),
          ],
          description: 'Rule 1',
          isActive: true,
        ),
        const HiddenContentRule(
          ruleId: 'rule2',
          contentIdToUnlock: 'content2',
          unlockedContentType: UnlockedContentType.achievement,
          triggerConditions: [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByCategory,
              parameters: {'category': 'Electronics', 'count': 3},
            ),
          ],
          description: 'Rule 2',
          isActive: true,
        ),
        const HiddenContentRule(
          ruleId: 'rule3',
          contentIdToUnlock: 'content3',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByTag,
              parameters: {'tag': 'modern', 'count': 10},
            ),
          ],
          description: 'Rule 3',
          isActive: false, // inactive rule should be excluded
        ),
      ];

      RuleEvaluationOptimizer.indexRules(rules);

      final tagRules = RuleEvaluationOptimizer.getRulesForTriggerType(
        HiddenContentTriggerType.itemCountByTag,
      );
      final categoryRules = RuleEvaluationOptimizer.getRulesForTriggerType(
        HiddenContentTriggerType.itemCountByCategory,
      );

      expect(tagRules, hasLength(1)); // only active rule1
      expect(tagRules.first.ruleId, equals('rule1'));
      expect(categoryRules, hasLength(1));
      expect(categoryRules.first.ruleId, equals('rule2'));
    });

    test('should get rule by ID', () {
      final rules = [
        const HiddenContentRule(
          ruleId: 'test_rule',
          contentIdToUnlock: 'test_content',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [],
          description: 'Test rule',
          isActive: true,
        ),
      ];

      RuleEvaluationOptimizer.indexRules(rules);

      final rule = RuleEvaluationOptimizer.getRuleById('test_rule');
      expect(rule, isNotNull);
      expect(rule!.ruleId, equals('test_rule'));

      final nonExistentRule = RuleEvaluationOptimizer.getRuleById('non_existent');
      expect(nonExistentRule, isNull);
    });

    test('should get all active rules', () {
      final rules = [
        const HiddenContentRule(
          ruleId: 'active_rule',
          contentIdToUnlock: 'content',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [],
          description: 'Active rule',
          isActive: true,
        ),
        const HiddenContentRule(
          ruleId: 'inactive_rule',
          contentIdToUnlock: 'content',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [],
          description: 'Inactive rule',
          isActive: false,
        ),
      ];

      RuleEvaluationOptimizer.indexRules(rules);

      final activeRules = RuleEvaluationOptimizer.getAllActiveRules();
      expect(activeRules, hasLength(1));
      expect(activeRules.first.ruleId, equals('active_rule'));
    });

    test('should clear index correctly', () {
      final rules = [
        const HiddenContentRule(
          ruleId: 'test_rule',
          contentIdToUnlock: 'test_content',
          unlockedContentType: UnlockedContentType.badge,
          triggerConditions: [
            TriggerCondition(
              type: HiddenContentTriggerType.itemCountByTag,
              parameters: {'tag': 'test', 'count': 1},
            ),
          ],
          description: 'Test rule',
          isActive: true,
        ),
      ];

      RuleEvaluationOptimizer.indexRules(rules);
      expect(RuleEvaluationOptimizer.getAllActiveRules(), hasLength(1));

      RuleEvaluationOptimizer.clearIndex();
      expect(RuleEvaluationOptimizer.getAllActiveRules(), isEmpty);
    });
  });

  group('Edge Cases and Integration', () {
    test('should handle empty trigger conditions list', () {
      const rule = HiddenContentRule(
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
      for (var i = 0; i < 100; i++) {
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
      const template = DiscoveryQuestTemplate(
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
      const template = DiscoveryQuestTemplate(
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

    test('should handle malformed JSON gracefully', () {
      // Test with unknown enum values
      final malformedJson = {
        'type': 'unknown_trigger_type',
        'parameters': {'test': 'value'},
      };

      final condition = TriggerCondition.fromJson(malformedJson);
      expect(condition.type, equals(HiddenContentTriggerType.specificItemDiscovery)); // fallback

      final ruleJson = {
        'ruleId': 'test',
        'contentIdToUnlock': 'content',
        'unlockedContentType': 'unknown_content_type',
        'triggerConditions': [],
        'description': 'test',
      };

      final rule = HiddenContentRule.fromJson(ruleJson);
      expect(rule.unlockedContentType, equals(UnlockedContentType.badge)); // fallback
    });

    test('should handle validation edge cases', () {
      // Test validation with exception-throwing parameters
      final condition = TriggerCondition(
        type: HiddenContentTriggerType.specificItemDiscovery,
        parameters: {'itemId': null}, // null value that might cause exception
      );

      expect(() => condition.validate(), returnsNormally);
      expect(condition.validate(), isFalse);
    });
  });
}
