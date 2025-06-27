import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';

void main() {
  group('Enhanced AI Analysis v2.0', () {
    late WasteClassification testClassification;

    setUp(() {
      testClassification = WasteClassification(
        itemName: 'Plastic Water Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        materialType: 'PET Plastic',
        recyclingCode: 1,
        explanation: 'Single-use plastic bottle made from PET plastic',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle in blue bin',
          steps: ['Empty contents', 'Remove cap', 'Place in blue bin'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: ['clear', 'bottle shape', 'recyclable symbol'],
        isRecyclable: true,
        isSingleUse: true,
        confidence: 0.95,
        alternatives: [],
        // Enhanced AI Analysis v2.0 fields
        recyclability: 'fully recyclable',
        hazardLevel: 1,
        co2Impact: 2.5,
        decompositionTime: '450 years',
        waterPollutionLevel: 2,
        soilContaminationRisk: 2,
        biodegradabilityDays: 164250, // 450 years
        recyclingEfficiency: 85,
        manufacturingEnergyFootprint: 3.4,
        transportationFootprint: 0.8,
        endOfLifeCost: 'Landfill space if not recycled',
        materials: ['PET plastic', 'polyethylene cap'],
        commonUses: ['Water storage', 'beverage container'],
        alternativeOptions: ['Reusable water bottle', 'Glass bottle'],
        circularEconomyPotential: ['Clothing fiber', 'Carpet material', 'New bottles'],
        generatesMicroplastics: true,
        humanToxicityLevel: 1,
        wildlifeImpactSeverity: 4,
        resourceScarcity: 'common',
        disposalCostEstimate: 2.50,
      );
    });

    test('calculatePoints should return enhanced points based on data richness', () {
      final points = testClassification.calculatePoints();
      
      // Should be higher than base 10 due to rich environmental data
      expect(points, greaterThan(10));
      expect(points, lessThanOrEqualTo(50));
      
      // High confidence should add bonus points
      expect(points, greaterThan(20)); // Should get confidence bonus
    });

    test('getEnvironmentalImpactScore should calculate impact correctly', () {
      final score = testClassification.getEnvironmentalImpactScore();
      
      // Should be in valid range - algorithm calculates more conservatively
      expect(score, greaterThanOrEqualTo(1.0));
      expect(score, lessThanOrEqualTo(10.0));
      
      // Should be impacted by wildlife severity and microplastics
      expect(score, greaterThan(2.0)); // Above neutral baseline
    });

    test('getClassificationTags should return relevant tags', () {
      final tags = testClassification.getClassificationTags();
      
      expect(tags, isNotEmpty);
      
      // Should include single-use tag
      expect(tags.any((tag) => tag.label == 'Single-Use'), isTrue);
      
      // Should include recyclability tag
      expect(tags.any((tag) => tag.label == 'Fully Recyclable'), isTrue);
      
      // Tags should be sorted by priority
      for (int i = 0; i < tags.length - 1; i++) {
        expect(tags[i].priority, lessThanOrEqualTo(tags[i + 1].priority));
      }
    });

    test('ClassificationTag should have valid color values', () {
      final tags = testClassification.getClassificationTags();
      
      for (final tag in tags) {
        expect(tag.color, startsWith('#'));
        expect(tag.color.length, equals(7)); // #RRGGBB format
        expect(tag.colorValue, isA<int>());
      }
    });

    group('BBMP Bangalore Plugin', () {
      late BBMPBangalorePlugin plugin;

      setUp(() {
        plugin = BBMPBangalorePlugin();
      });

      test('should have correct plugin metadata', () {
        expect(plugin.pluginId, equals('bbmp_bangalore'));
        expect(plugin.authorityName, equals('BBMP'));
        expect(plugin.region, equals('Bangalore, IN'));
        expect(plugin.guidelinesVersion, startsWith('BBMP-'));
      });

      test('should validate compliance correctly', () {
        final compliance = plugin.validateCompliance(testClassification);
        
        expect(compliance.status, isIn(['compliant', 'requires_attention', 'violation']));
        expect(compliance.recommendations, isNotEmpty);
      });

      test('should return color coding for all categories', () {
        final colorCoding = plugin.getColorCoding();
        
        expect(colorCoding, containsPair('wet_waste', 'Green Bin/Bag'));
        expect(colorCoding, containsPair('dry_waste', 'Blue Bin/Bag'));
        expect(colorCoding, containsPair('hazardous_waste', 'Red Bin/Bag'));
        expect(colorCoding, containsPair('medical_waste', 'Yellow Bin/Bag'));
      });

      test('should provide collection schedule information', () {
        final schedule = plugin.getCollectionSchedule();
        
        expect(schedule, contains('wet_waste'));
        expect(schedule, contains('dry_waste'));
        expect(schedule['wet_waste']['frequency'], equals('daily'));
        expect(schedule['dry_waste']['frequency'], equals('alternate_days'));
      });

      test('should apply local guidelines correctly', () async {
        final enhanced = await plugin.applyLocalGuidelines(testClassification);
        
        expect(enhanced.bbmpComplianceStatus, isNotNull);
        expect(enhanced.localGuidelinesVersion, equals(plugin.guidelinesVersion));
        expect(enhanced.localRegulations, isNotEmpty);
      });
    });

    group('Local Guidelines Manager', () {
      setUp(() {
        LocalGuidelinesManager.initializeDefaultPlugins();
      });

      test('should register BBMP plugin correctly', () {
        final plugin = LocalGuidelinesManager.getPluginForRegion('Bangalore, IN');
        expect(plugin, isNotNull);
        expect(plugin!.pluginId, equals('bbmp_bangalore'));
      });

      test('should handle unknown regions gracefully', () {
        final plugin = LocalGuidelinesManager.getPluginForRegion('Unknown City');
        expect(plugin, isNull);
      });

      test('should apply guidelines for supported regions', () async {
        final enhanced = await LocalGuidelinesManager.applyLocalGuidelines(
          testClassification,
          'Bangalore, IN',
        );
        
        // Should have BBMP enhancements
        expect(enhanced.bbmpComplianceStatus, isNotNull);
        expect(enhanced.localGuidelinesVersion, isNotNull);
      });

      test('should return unchanged classification for unsupported regions', () async {
        final enhanced = await LocalGuidelinesManager.applyLocalGuidelines(
          testClassification,
          'Unknown City',
        );
        
        // Should be the same object
        expect(enhanced, equals(testClassification));
      });
    });

    group('Points Calculation Edge Cases', () {
      test('should handle minimal data classification', () {
        final minimal = WasteClassification(
          itemName: 'Unknown Item',
          category: 'Dry Waste',
          explanation: 'Basic classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Review required',
            steps: ['Manual review needed'],
            hasUrgentTimeframe: false,
          ),
          region: 'Unknown',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.3, // Low confidence
        );

        final points = minimal.calculatePoints();
        expect(points, greaterThanOrEqualTo(5)); // Minimum points
        expect(points, lessThan(15)); // Should be low due to minimal data
      });

      test('should handle maximum data classification', () {
        final maximal = testClassification.copyWith(
          brand: 'Aquafina',
          product: 'Water Bottle 500ml',
          barcode: '1234567890',
          requiredPPE: ['gloves'],
          requiresSpecialDisposal: true,
          hasUrgentTimeframe: true,
          bbmpComplianceStatus: 'compliant',
          localGuidelinesReference: 'BBMP-2024-plastic',
          confidence: 0.98,
          // Add more environmental data
          waterPollutionLevel: 4,
          soilContaminationRisk: 4,
          humanToxicityLevel: 2,
          wildlifeImpactSeverity: 5,
        );

        final points = maximal.calculatePoints();
        expect(points, greaterThan(30)); // Should be high due to rich data
        expect(points, lessThanOrEqualTo(50)); // Capped at maximum
      });
    });

    group('Environmental Impact Scoring', () {
      test('should score low-impact items correctly', () {
        final lowImpact = testClassification.copyWith(
          co2Impact: 0.5,
          waterPollutionLevel: 1,
          soilContaminationRisk: 1,
          recyclability: 'fully recyclable',
          generatesMicroplastics: false,
          humanToxicityLevel: 1,
          wildlifeImpactSeverity: 1,
        );

        final score = lowImpact.getEnvironmentalImpactScore();
        expect(score, lessThan(4.0)); // Should be low impact
      });

      test('should score high-impact items correctly', () {
        final highImpact = testClassification.copyWith(
          co2Impact: 15.0,
          waterPollutionLevel: 5,
          soilContaminationRisk: 5,
          recyclability: 'not recyclable',
          generatesMicroplastics: true,
          humanToxicityLevel: 5,
          wildlifeImpactSeverity: 5,
        );

        final score = highImpact.getEnvironmentalImpactScore();
        expect(score, greaterThan(7.0)); // Should be high impact
      });
    });
  });
}