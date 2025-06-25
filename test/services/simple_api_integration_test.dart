import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/dynamic_pricing_service.dart';
import '../../lib/services/cost_guardrail_service.dart';
import '../../lib/services/remote_config_service.dart';
import '../../lib/models/token_wallet.dart';

void main() {
  group('API Integration System Tests', () {
    
    group('DynamicPricingService Basic Tests', () {
      test('should initialize with default values', () async {
        final pricingService = DynamicPricingService();
        
        // Test default pricing values
        expect(pricingService.getModelPricing('gpt_4_1_nano', isOutput: false), greaterThan(0));
        expect(pricingService.getModelPricing('gpt_4_1_nano', isOutput: true), greaterThan(0));
      });

      test('should calculate cost correctly', () async {
        final pricingService = DynamicPricingService();
        
        // Test cost calculation
        final instantCost = pricingService.calculateCost(
          model: 'gpt_4_1_nano',
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: false,
        );

        final batchCost = pricingService.calculateCost(
          model: 'gpt_4_1_nano',
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: true,
        );

        expect(instantCost, greaterThan(0));
        expect(batchCost, lessThan(instantCost));
        expect(batchCost, instantCost * 0.5); // 50% discount for batch
      });

      test('should track spending correctly', () async {
        final pricingService = DynamicPricingService();
        
        final initialSpending = pricingService.getDailySpending();
        
        await pricingService.recordSpending(
          model: 'gpt_4_1_nano',
          cost: 0.05,
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: false,
        );
        
        final finalSpending = pricingService.getDailySpending();
        expect(finalSpending, initialSpending + 0.05);
      });

      test('should enforce batch mode when budget threshold reached', () async {
        final pricingService = DynamicPricingService();
        
        // Record spending that exceeds 80% of daily budget ($5.00)
        await pricingService.recordSpending(
          model: 'gpt_4_1_nano',
          cost: 4.50, // 90% of budget
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: false,
        );

        expect(pricingService.shouldEnforceBatchMode(), true);
      });

      test('should provide budget utilization data', () async {
        final pricingService = DynamicPricingService();
        
        final utilization = pricingService.getBudgetUtilization();
        
        expect(utilization, isA<Map<String, double>>());
        expect(utilization.containsKey('daily'), true);
        expect(utilization.containsKey('weekly'), true);
        expect(utilization.containsKey('monthly'), true);
      });
    });

    group('TokenWallet Tests', () {
      test('should create new user wallet with welcome bonus', () {
        final wallet = TokenWallet.newUser();
        
        expect(wallet.balance, 10);
        expect(wallet.totalEarned, 10);
        expect(wallet.totalSpent, 0);
      });

      test('should check if user can afford operations', () {
        final wallet = TokenWallet.newUser();
        
        expect(wallet.canAfford(AnalysisSpeed.instant.cost), true); // 5 tokens
        expect(wallet.canAfford(AnalysisSpeed.batch.cost), true);   // 1 token
        expect(wallet.canAfford(15), false); // More than balance
      });

      test('should handle token transactions correctly', () {
        final transaction = TokenTransaction(
          id: 'test_txn',
          delta: -5,
          type: TokenTransactionType.spend,
          timestamp: DateTime.now(),
          description: 'Instant analysis',
          reference: 'classification_123',
        );

        expect(transaction.delta, -5);
        expect(transaction.type, TokenTransactionType.spend);
        expect(transaction.description, 'Instant analysis');
      });

      test('should convert to/from JSON correctly', () {
        final originalWallet = TokenWallet.newUser();
        final json = originalWallet.toJson();
        final reconstructedWallet = TokenWallet.fromJson(json);

        expect(reconstructedWallet.balance, originalWallet.balance);
        expect(reconstructedWallet.totalEarned, originalWallet.totalEarned);
        expect(reconstructedWallet.totalSpent, originalWallet.totalSpent);
      });
    });

    group('AnalysisSpeed Tests', () {
      test('should have correct cost values', () {
        expect(AnalysisSpeed.instant.cost, 5);
        expect(AnalysisSpeed.batch.cost, 1);
      });

      test('should have correct display names', () {
        expect(AnalysisSpeed.instant.displayName, 'Instant');
        expect(AnalysisSpeed.batch.displayName, 'Batch (2-6h)');
      });

      test('should have appropriate descriptions', () {
        expect(AnalysisSpeed.instant.description, contains('Real-time'));
        expect(AnalysisSpeed.batch.description, contains('2-6 hours'));
      });
    });

    group('Budget Management Integration', () {
      test('should provide comprehensive pricing summary', () async {
        final pricingService = DynamicPricingService();
        
        final summary = pricingService.getPricingSummary();
        
        expect(summary, isA<Map<String, dynamic>>());
        expect(summary.containsKey('pricing'), true);
        expect(summary.containsKey('budgets'), true);
        expect(summary.containsKey('daily_spending'), true);
        expect(summary.containsKey('budget_utilization'), true);
      });

      test('should calculate batch savings correctly', () async {
        final pricingService = DynamicPricingService();
        
        final savings = pricingService.getEstimatedBatchSavings(
          model: 'gpt_4_1_nano',
          estimatedInputTokens: 1500,
          estimatedOutputTokens: 800,
        );
        
        expect(savings, greaterThan(0));
      });

      test('should check affordability correctly', () async {
        final pricingService = DynamicPricingService();
        
        final canAfford = pricingService.canAffordInstantAnalysis(
          model: 'gpt_4_1_nano',
          estimatedInputTokens: 1500,
          estimatedOutputTokens: 800,
        );
        
        expect(canAfford, isA<bool>());
      });
    });

    group('Cost Optimization Features', () {
      test('should provide different model pricing', () async {
        final pricingService = DynamicPricingService();
        
        final gptPrice = pricingService.getModelPricing('gpt_4_1_nano');
        final geminiPrice = pricingService.getModelPricing('gemini_2_0_flash');
        
        expect(gptPrice, greaterThan(0));
        expect(geminiPrice, greaterThan(0));
        expect(geminiPrice, lessThan(gptPrice)); // Gemini should be cheaper
      });

      test('should support spending breakdown by model', () async {
        final pricingService = DynamicPricingService();
        
        // Record spending for different models
        await pricingService.recordSpending(
          model: 'gpt_4_1_nano',
          cost: 0.03,
          inputTokens: 1500,
          outputTokens: 800,
        );
        
        await pricingService.recordSpending(
          model: 'gemini_2_0_flash',
          cost: 0.015,
          inputTokens: 1500,
          outputTokens: 800,
        );
        
        final breakdown = pricingService.getSpendingBreakdown('daily');
        expect(breakdown, isA<Map<String, double>>());
        expect(breakdown.length, greaterThan(0));
      });
    });

    group('Error Handling and Resilience', () {
      test('should handle missing Remote Config gracefully', () async {
        // Test that service works even without Remote Config
        final pricingService = DynamicPricingService();
        
        // Should use defaults if Remote Config fails
        expect(pricingService.getModelPricing('gpt_4_1_nano'), greaterThan(0));
      });

      test('should provide fallback values for unknown models', () async {
        final pricingService = DynamicPricingService();
        
        // Should fallback to gpt_4o_mini pricing for unknown models
        final unknownPrice = pricingService.getModelPricing('unknown_model');
        expect(unknownPrice, greaterThan(0));
      });
    });
  });

  group('System Integration Scenarios', () {
    test('should handle complete budget workflow', () async {
      final pricingService = DynamicPricingService();
      
      // 1. Start with empty budget
      expect(pricingService.getDailySpending(), 0.0);
      
      // 2. Make some API calls
      await pricingService.recordSpending(
        model: 'gpt_4_1_nano',
        cost: 0.02,
        inputTokens: 1000,
        outputTokens: 500,
      );
      
      // 3. Check spending increased
      expect(pricingService.getDailySpending(), 0.02);
      
      // 4. Check utilization
      final utilization = pricingService.getBudgetUtilization();
      expect(utilization['daily'], greaterThan(0));
      
      // 5. Approach budget limit
      await pricingService.recordSpending(
        model: 'gpt_4_1_nano',
        cost: 4.0, // Total now 4.02, approaching $5 limit
        inputTokens: 1000,
        outputTokens: 500,
      );
      
      // 6. Should recommend batch mode
      expect(pricingService.shouldEnforceBatchMode(), true);
    });
  });
}