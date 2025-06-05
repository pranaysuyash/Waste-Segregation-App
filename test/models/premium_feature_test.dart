import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

void main() {
  group('PremiumFeature Model Tests', () {
    group('PremiumFeature Model', () {
      test('should create PremiumFeature with all required properties', () {
        final feature = PremiumFeature(
          id: 'feature_001',
          name: 'Advanced Analytics',
          description: 'Detailed analytics and insights about your waste patterns',
          icon: 'analytics_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.pro,
          isEnabled: true,
          sortOrder: 1,
        );

        expect(feature.id, 'feature_001');
        expect(feature.name, 'Advanced Analytics');
        expect(feature.description, 'Detailed analytics and insights about your waste patterns');
        expect(feature.icon, 'analytics_icon');
        expect(feature.category, FeatureCategory.analytics);
        expect(feature.tier, PremiumTier.pro);
        expect(feature.isEnabled, true);
        expect(feature.sortOrder, 1);
      });

      test('should create PremiumFeature with optional properties', () {
        final feature = PremiumFeature(
          id: 'feature_002',
          name: 'Cloud Backup',
          description: 'Backup your data to the cloud',
          icon: 'cloud_icon',
          category: FeatureCategory.storage,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 2,
          maxUsage: 1000,
          currentUsage: 250,
          resetPeriod: UsageResetPeriod.monthly,
          dependencies: ['feature_001'],
          comingSoon: false,
          betaFeature: true,
        );

        expect(feature.maxUsage, 1000);
        expect(feature.currentUsage, 250);
        expect(feature.resetPeriod, UsageResetPeriod.monthly);
        expect(feature.dependencies, ['feature_001']);
        expect(feature.comingSoon, false);
        expect(feature.betaFeature, true);
      });

      test('should serialize PremiumFeature to JSON correctly', () {
        final feature = PremiumFeature(
          id: 'feature_003',
          name: 'AI Insights',
          description: 'AI-powered waste reduction recommendations',
          icon: 'ai_icon',
          category: FeatureCategory.ai,
          tier: PremiumTier.enterprise,
          isEnabled: true,
          sortOrder: 3,
          maxUsage: 500,
          currentUsage: 100,
        );

        final json = feature.toJson();

        expect(json['id'], 'feature_003');
        expect(json['name'], 'AI Insights');
        expect(json['description'], 'AI-powered waste reduction recommendations');
        expect(json['icon'], 'ai_icon');
        expect(json['category'], 'ai');
        expect(json['tier'], 'enterprise');
        expect(json['isEnabled'], true);
        expect(json['sortOrder'], 3);
        expect(json['maxUsage'], 500);
        expect(json['currentUsage'], 100);
      });

      test('should deserialize PremiumFeature from JSON correctly', () {
        final json = {
          'id': 'feature_004',
          'name': 'Export Data',
          'description': 'Export your data in various formats',
          'icon': 'export_icon',
          'category': 'export',
          'tier': 'pro',
          'isEnabled': false,
          'sortOrder': 4,
          'maxUsage': 10,
          'currentUsage': 3,
          'resetPeriod': 'weekly',
          'dependencies': ['feature_001', 'feature_002'],
          'comingSoon': true,
          'betaFeature': false,
        };

        final feature = PremiumFeature.fromJson(json);

        expect(feature.id, 'feature_004');
        expect(feature.name, 'Export Data');
        expect(feature.description, 'Export your data in various formats');
        expect(feature.icon, 'export_icon');
        expect(feature.category, FeatureCategory.export);
        expect(feature.tier, PremiumTier.pro);
        expect(feature.isEnabled, false);
        expect(feature.sortOrder, 4);
        expect(feature.maxUsage, 10);
        expect(feature.currentUsage, 3);
        expect(feature.resetPeriod, UsageResetPeriod.weekly);
        expect(feature.dependencies, ['feature_001', 'feature_002']);
        expect(feature.comingSoon, true);
        expect(feature.betaFeature, false);
      });

      test('should calculate usage percentage correctly', () {
        final feature = PremiumFeature(
          id: 'feature_005',
          name: 'Usage Test',
          description: 'Test usage calculation',
          icon: 'test_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
          maxUsage: 100,
          currentUsage: 75,
        );

        expect(feature.usagePercentage, 0.75);
        expect(feature.usagePercentageInt, 75);
        expect(feature.remainingUsage, 25);
      });

      test('should handle unlimited usage correctly', () {
        final unlimitedFeature = PremiumFeature(
          id: 'feature_006',
          name: 'Unlimited Feature',
          description: 'Feature with unlimited usage',
          icon: 'unlimited_icon',
          category: FeatureCategory.storage,
          tier: PremiumTier.enterprise,
          isEnabled: true,
          sortOrder: 1,
          currentUsage: 1000,
        );

        expect(unlimitedFeature.isUnlimited, true);
        expect(unlimitedFeature.usagePercentage, 0.0);
        expect(unlimitedFeature.remainingUsage, null);
      });

      test('should check if feature is exhausted', () {
        final exhaustedFeature = PremiumFeature(
          id: 'feature_007',
          name: 'Exhausted Feature',
          description: 'Feature that is exhausted',
          icon: 'exhausted_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
          maxUsage: 50,
          currentUsage: 50,
        );

        final availableFeature = PremiumFeature(
          id: 'feature_008',
          name: 'Available Feature',
          description: 'Feature with available usage',
          icon: 'available_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
          maxUsage: 50,
          currentUsage: 25,
        );

        expect(exhaustedFeature.isExhausted, true);
        expect(exhaustedFeature.canUse, false);
        expect(availableFeature.isExhausted, false);
        expect(availableFeature.canUse, true);
      });

      test('should check if feature is available', () {
        final enabledFeature = PremiumFeature(
          id: 'feature_009',
          name: 'Enabled Feature',
          description: 'An enabled feature',
          icon: 'enabled_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
        );

        final disabledFeature = PremiumFeature(
          id: 'feature_010',
          name: 'Disabled Feature',
          description: 'A disabled feature',
          icon: 'disabled_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          sortOrder: 1,
        );

        final comingSoonFeature = PremiumFeature(
          id: 'feature_011',
          name: 'Coming Soon Feature',
          description: 'A feature coming soon',
          icon: 'soon_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
          comingSoon: true,
        );

        expect(enabledFeature.isAvailable, true);
        expect(disabledFeature.isAvailable, false);
        expect(comingSoonFeature.isAvailable, false);
      });
    });

    group('PremiumSubscription Model', () {
      test('should create PremiumSubscription with all properties', () {
        final subscription = PremiumSubscription(
          id: 'sub_001',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.active,
          startDate: DateTime(2024, 1),
          endDate: DateTime(2024, 12, 31),
          autoRenew: true,
          paymentMethod: 'credit_card',
        );

        expect(subscription.id, 'sub_001');
        expect(subscription.userId, 'user_123');
        expect(subscription.tier, PremiumTier.pro);
        expect(subscription.status, SubscriptionStatus.active);
        expect(subscription.startDate, DateTime(2024, 1));
        expect(subscription.endDate, DateTime(2024, 12, 31));
        expect(subscription.autoRenew, true);
        expect(subscription.paymentMethod, 'credit_card');
      });

      test('should check if subscription is active', () {
        final activeSubscription = PremiumSubscription(
          id: 'sub_002',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 30)),
          autoRenew: true,
        );

        final expiredSubscription = PremiumSubscription(
          id: 'sub_003',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
          autoRenew: false,
        );

        expect(activeSubscription.isActive, true);
        expect(activeSubscription.isExpired, false);
        expect(expiredSubscription.isActive, false);
        expect(expiredSubscription.isExpired, true);
      });

      test('should calculate days until expiry', () {
        final subscription = PremiumSubscription(
          id: 'sub_004',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 20)),
          autoRenew: true,
        );

        expect(subscription.daysUntilExpiry, 20);
        expect(subscription.expiresWithinDays(30), true);
        expect(subscription.expiresWithinDays(10), false);
      });

      test('should handle trial period correctly', () {
        final trialSubscription = PremiumSubscription(
          id: 'sub_005',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.trial,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          endDate: DateTime.now().add(const Duration(days: 9)),
          autoRenew: true,
          trialEndDate: DateTime.now().add(const Duration(days: 9)),
        );

        expect(trialSubscription.isTrial, true);
        expect(trialSubscription.trialDaysRemaining, 9);
      });

      test('should check if subscription can be renewed', () {
        final renewableSubscription = PremiumSubscription(
          id: 'sub_006',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 300)),
          endDate: DateTime.now().add(const Duration(days: 30)),
          autoRenew: false,
        );

        final cancelledSubscription = PremiumSubscription(
          id: 'sub_007',
          userId: 'user_123',
          tier: PremiumTier.pro,
          status: SubscriptionStatus.cancelled,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
          autoRenew: false,
        );

        expect(renewableSubscription.canRenew, true);
        expect(cancelledSubscription.canRenew, false);
      });
    });

    group('Premium Tier Management', () {
      test('should handle tier hierarchy correctly', () {
        expect(PremiumTier.basic.index < PremiumTier.pro.index, true);
        expect(PremiumTier.pro.index < PremiumTier.enterprise.index, true);
      });

      test('should provide tier display names', () {
        expect(PremiumTier.basic.displayName, 'Basic');
        expect(PremiumTier.pro.displayName, 'Pro');
        expect(PremiumTier.enterprise.displayName, 'Enterprise');
      });

      test('should calculate tier upgrade paths', () {
        expect(PremiumTier.basic.canUpgradeTo(PremiumTier.pro), true);
        expect(PremiumTier.basic.canUpgradeTo(PremiumTier.enterprise), true);
        expect(PremiumTier.pro.canUpgradeTo(PremiumTier.basic), false);
        expect(PremiumTier.enterprise.canUpgradeTo(PremiumTier.pro), false);
      });

      test('should get tier pricing information', () {
        expect(PremiumTier.basic.monthlyPrice, 4.99);
        expect(PremiumTier.pro.monthlyPrice, 9.99);
        expect(PremiumTier.enterprise.monthlyPrice, 19.99);

        expect(PremiumTier.basic.yearlyPrice, 49.99);
        expect(PremiumTier.pro.yearlyPrice, 99.99);
        expect(PremiumTier.enterprise.yearlyPrice, 199.99);
      });
    });

    group('Feature Categories', () {
      test('should handle all feature categories', () {
        final categories = [
          FeatureCategory.analytics,
          FeatureCategory.storage,
          FeatureCategory.ai,
          FeatureCategory.export,
          FeatureCategory.customization,
          FeatureCategory.collaboration,
        ];

        for (final category in categories) {
          expect(category.displayName, isNotEmpty);
          expect(category.description, isNotEmpty);
        }
      });

      test('should provide category descriptions', () {
        expect(FeatureCategory.analytics.description, contains('analytics'));
        expect(FeatureCategory.storage.description, contains('storage'));
        expect(FeatureCategory.ai.description, contains('AI'));
        expect(FeatureCategory.export.description, contains('export'));
        expect(FeatureCategory.customization.description, contains('customization'));
        expect(FeatureCategory.collaboration.description, contains('collaboration'));
      });
    });

    group('Usage Reset Periods', () {
      test('should handle all reset periods', () {
        expect(UsageResetPeriod.daily.days, 1);
        expect(UsageResetPeriod.weekly.days, 7);
        expect(UsageResetPeriod.monthly.days, 30);
        expect(UsageResetPeriod.yearly.days, 365);
      });

      test('should calculate next reset date', () {
        final now = DateTime.now();
        
        final dailyReset = UsageResetPeriod.daily.nextResetDate(now);
        expect(dailyReset.day, now.add(const Duration(days: 1)).day);

        final weeklyReset = UsageResetPeriod.weekly.nextResetDate(now);
        expect(weeklyReset.isAfter(now.add(const Duration(days: 6))), true);

        final monthlyReset = UsageResetPeriod.monthly.nextResetDate(now);
        expect(monthlyReset.month, now.add(const Duration(days: 30)).month);
      });
    });

    group('Feature Dependencies', () {
      test('should check feature dependencies', () {
        final baseFeature = PremiumFeature(
          id: 'base',
          name: 'Base Feature',
          description: 'Base feature',
          icon: 'base',
          category: FeatureCategory.analytics,
          tier: PremiumTier.basic,
          isEnabled: true,
          sortOrder: 1,
        );

        final dependentFeature = PremiumFeature(
          id: 'dependent',
          name: 'Dependent Feature',
          description: 'Feature with dependencies',
          icon: 'dependent',
          category: FeatureCategory.analytics,
          tier: PremiumTier.pro,
          isEnabled: true,
          sortOrder: 2,
          dependencies: ['base'],
        );

        expect(dependentFeature.hasDependencies, true);
        expect(dependentFeature.dependencies, contains('base'));
        expect(baseFeature.hasDependencies, false);
      });

      test('should validate dependency chain', () {
        final features = [
          PremiumFeature(
            id: 'feature_a',
            name: 'Feature A',
            description: 'First feature',
            icon: 'a',
            category: FeatureCategory.analytics,
            tier: PremiumTier.basic,
            isEnabled: true,
            sortOrder: 1,
          ),
          PremiumFeature(
            id: 'feature_b',
            name: 'Feature B',
            description: 'Second feature',
            icon: 'b',
            category: FeatureCategory.analytics,
            tier: PremiumTier.pro,
            isEnabled: true,
            sortOrder: 2,
            dependencies: ['feature_a'],
          ),
          PremiumFeature(
            id: 'feature_c',
            name: 'Feature C',
            description: 'Third feature',
            icon: 'c',
            category: FeatureCategory.analytics,
            tier: PremiumTier.enterprise,
            isEnabled: true,
            sortOrder: 3,
            dependencies: ['feature_a', 'feature_b'],
          ),
        ];

        final featureC = features.last;
        expect(featureC.dependencies, containsAll(['feature_a', 'feature_b']));
      });
    });

    group('Equality and Comparison', () {
      test('should compare PremiumFeature for equality', () {
        final feature1 = PremiumFeature(
          id: 'feature_001',
          name: 'Test Feature',
          description: 'A test feature',
          icon: 'test_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.pro,
          isEnabled: true,
          sortOrder: 1,
        );

        final feature2 = PremiumFeature(
          id: 'feature_001',
          name: 'Test Feature',
          description: 'A test feature',
          icon: 'test_icon',
          category: FeatureCategory.analytics,
          tier: PremiumTier.pro,
          isEnabled: true,
          sortOrder: 1,
        );

        final feature3 = PremiumFeature(
          id: 'feature_002',
          name: 'Different Feature',
          description: 'A different feature',
          icon: 'different_icon',
          category: FeatureCategory.storage,
          tier: PremiumTier.basic,
          sortOrder: 2,
        );

        expect(feature1 == feature2, true);
        expect(feature1 == feature3, false);
        expect(feature1.hashCode == feature2.hashCode, true);
      });

      test('should sort features by sort order', () {
        final features = [
          PremiumFeature(
            id: 'feature_c', name: 'Feature C', description: 'Third',
            icon: 'c', category: FeatureCategory.analytics, tier: PremiumTier.basic,
            isEnabled: true, sortOrder: 3,
          ),
          PremiumFeature(
            id: 'feature_a', name: 'Feature A', description: 'First',
            icon: 'a', category: FeatureCategory.analytics, tier: PremiumTier.basic,
            isEnabled: true, sortOrder: 1,
          ),
          PremiumFeature(
            id: 'feature_b', name: 'Feature B', description: 'Second',
            icon: 'b', category: FeatureCategory.analytics, tier: PremiumTier.basic,
            isEnabled: true, sortOrder: 2,
          ),
        ];

        features.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        expect(features[0].name, 'Feature A');
        expect(features[1].name, 'Feature B');
        expect(features[2].name, 'Feature C');
      });
    });

    group('Edge Cases and Validation', () {
      test('should handle invalid usage values', () {
        expect(() => PremiumFeature(
          id: 'feature_001', name: 'Test', description: 'Test',
          icon: 'test', category: FeatureCategory.analytics, tier: PremiumTier.basic,
          isEnabled: true, sortOrder: 1,
          maxUsage: 100, currentUsage: 150, // Current > max
        ), throwsArgumentError);

        expect(() => PremiumFeature(
          id: 'feature_002', name: 'Test', description: 'Test',
          icon: 'test', category: FeatureCategory.analytics, tier: PremiumTier.basic,
          isEnabled: true, sortOrder: 1,
          currentUsage: -10, // Negative usage
        ), throwsArgumentError);
      });

      test('should handle empty or null dependencies', () {
        final feature = PremiumFeature(
          id: 'feature_001', name: 'Test', description: 'Test',
          icon: 'test', category: FeatureCategory.analytics, tier: PremiumTier.basic,
          isEnabled: true, sortOrder: 1,
          dependencies: [],
        );

        expect(feature.hasDependencies, false);
        expect(feature.dependencies, isEmpty);
      });

      test('should validate subscription date ranges', () {
        expect(() => PremiumSubscription(
          id: 'sub_001', userId: 'user_123', tier: PremiumTier.pro,
          status: SubscriptionStatus.active,
          startDate: DateTime(2024, 6),
          endDate: DateTime(2024, 1), // End before start
          autoRenew: true,
        ), throwsArgumentError);
      });
    });
  });
}
