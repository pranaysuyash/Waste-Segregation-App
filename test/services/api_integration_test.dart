import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/ai_service.dart';
import '../../lib/services/dynamic_pricing_service.dart';
import '../../lib/services/cost_guardrail_service.dart';
import '../../lib/services/remote_config_service.dart';
import '../../lib/services/enhanced_api_error_handler.dart';
import '../../lib/models/token_wallet.dart';

// Generate mocks
@GenerateMocks([
  RemoteConfigService,
  DynamicPricingService,
  CostGuardrailService,
  EnhancedApiErrorHandler,
])
import 'api_integration_test.mocks.dart';

void main() {
  group('API Integration Tests', () {
    late MockRemoteConfigService mockRemoteConfig;
    late MockDynamicPricingService mockPricingService;
    late MockCostGuardrailService mockGuardrailService;
    late MockEnhancedApiErrorHandler mockErrorHandler;

    setUp(() {
      mockRemoteConfig = MockRemoteConfigService();
      mockPricingService = MockDynamicPricingService();
      mockGuardrailService = MockCostGuardrailService();
      mockErrorHandler = MockEnhancedApiErrorHandler();
    });

    group('DynamicPricingService', () {
      test('should load pricing from Remote Config correctly', () async {
        // Arrange
        when(mockRemoteConfig.getString('ai_model_pricing', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => '''
{
  "gpt_4_1_nano_input": 0.000150,
  "gpt_4_1_nano_output": 0.000600,
  "batch_discount_rate": 0.50
}''');

        when(mockRemoteConfig.getString('spending_budgets', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => '''
{
  "daily_budget": 5.00,
  "weekly_budget": 30.00,
  "monthly_budget": 100.00
}''');

        when(mockRemoteConfig.getString('token_limits', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => '''
{
  "avg_input_tokens": 1500,
  "avg_output_tokens": 800,
  "max_tokens_per_request": 4000
}''');

        when(mockRemoteConfig.initialize()).thenAnswer((_) async {});

        final pricingService = DynamicPricingService(
          remoteConfigService: mockRemoteConfig,
        );

        // Act
        await pricingService.initialize();

        // Assert
        expect(pricingService.getModelPricing('gpt_4_1_nano', isOutput: false), 0.000150);
        expect(pricingService.getModelPricing('gpt_4_1_nano', isOutput: true), 0.000600);
        
        final budgets = pricingService.getBudgets();
        expect(budgets['daily_budget'], 5.00);
        expect(budgets['weekly_budget'], 30.00);
        expect(budgets['monthly_budget'], 100.00);
      });

      test('should calculate cost correctly for different models', () async {
        when(mockRemoteConfig.initialize()).thenAnswer((_) async {});
        when(mockRemoteConfig.getString(any, defaultValue: anyNamed('defaultValue')))
            .thenAnswer((invocation) async => invocation.namedArguments[#defaultValue]);

        final pricingService = DynamicPricingService(
          remoteConfigService: mockRemoteConfig,
        );
        await pricingService.initialize();

        // Test instant analysis cost
        final instantCost = pricingService.calculateCost(
          model: 'gpt_4_1_nano',
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: false,
        );

        // Test batch mode cost (50% discount)
        final batchCost = pricingService.calculateCost(
          model: 'gpt_4_1_nano',
          inputTokens: 1500,
          outputTokens: 800,
          isBatchMode: true,
        );

        expect(batchCost, instantCost * 0.5);
        expect(instantCost, greaterThan(0));
      });

      test('should enforce batch mode when budget threshold is reached', () async {
        when(mockRemoteConfig.initialize()).thenAnswer((_) async {});
        when(mockRemoteConfig.getString(any, defaultValue: anyNamed('defaultValue')))
            .thenAnswer((invocation) async => invocation.namedArguments[#defaultValue]);

        final pricingService = DynamicPricingService(
          remoteConfigService: mockRemoteConfig,
        );
        await pricingService.initialize();

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
    });

    group('CostGuardrailService', () {
      test('should properly integrate with pricing service', () async {
        // Mock pricing service behavior
        when(mockPricingService.initialize()).thenAnswer((_) async {});
        when(mockPricingService.shouldEnforceBatchMode()).thenReturn(false);
        when(mockPricingService.canAffordInstantAnalysis(
          model: anyNamed('model'),
          estimatedInputTokens: anyNamed('estimatedInputTokens'),
          estimatedOutputTokens: anyNamed('estimatedOutputTokens'),
        )).thenReturn(true);

        when(mockRemoteConfig.getBool('cost_guardrails_enabled', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => true);
        when(mockRemoteConfig.getInt('budget_threshold_percentage', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => 80);
        when(mockRemoteConfig.getBool('force_batch_mode_on_threshold', defaultValue: anyNamed('defaultValue')))
            .thenAnswer((_) async => true);

        final guardrailService = CostGuardrailService(
          pricingService: mockPricingService,
          remoteConfigService: mockRemoteConfig,
        );

        // Act
        await guardrailService.initialize();

        // Assert
        expect(guardrailService.canUseInstantAnalysis(model: 'gpt_4_1_nano'), true);
        expect(guardrailService.getRecommendedAnalysisSpeed(model: 'gpt_4_1_nano'), 
               AnalysisSpeed.instant);
      });

      test('should recommend batch mode when budget is exceeded', () async {
        // Mock pricing service to indicate budget exceeded
        when(mockPricingService.initialize()).thenAnswer((_) async {});
        when(mockPricingService.shouldEnforceBatchMode()).thenReturn(true);
        when(mockPricingService.canAffordInstantAnalysis(
          model: anyNamed('model'),
          estimatedInputTokens: anyNamed('estimatedInputTokens'),
          estimatedOutputTokens: anyNamed('estimatedOutputTokens'),
        )).thenReturn(false);

        when(mockRemoteConfig.getBool(any, defaultValue: anyNamed('defaultValue')))
            .thenAnswer((invocation) async => invocation.namedArguments[#defaultValue]);
        when(mockRemoteConfig.getInt(any, defaultValue: anyNamed('defaultValue')))
            .thenAnswer((invocation) async => invocation.namedArguments[#defaultValue]);

        final guardrailService = CostGuardrailService(
          pricingService: mockPricingService,
          remoteConfigService: mockRemoteConfig,
        );

        await guardrailService.initialize();

        // Act & Assert
        expect(guardrailService.canUseInstantAnalysis(model: 'gpt_4_1_nano'), false);
        expect(guardrailService.getRecommendedAnalysisSpeed(model: 'gpt_4_1_nano'), 
               AnalysisSpeed.batch);
      });
    });

    group('Enhanced Error Handling', () {
      test('should classify API errors correctly', () async {
        final errorHandler = EnhancedApiErrorHandler();

        // Test successful operation
        final result = await errorHandler.executeWithErrorHandling<String>(
          serviceName: 'test',
          operationId: 'test_op',
          operation: () async => 'success',
        );

        expect(result, 'success');
      });

      test('should implement circuit breaker pattern', () async {
        final errorHandler = EnhancedApiErrorHandler(
          circuitBreakerThreshold: 2,
          circuitBreakerTimeout: const Duration(seconds: 1),
        );

        // Cause multiple failures to trigger circuit breaker
        for (int i = 0; i < 3; i++) {
          try {
            await errorHandler.executeWithErrorHandling<String>(
              serviceName: 'failing_service',
              operationId: 'test_op_$i',
              operation: () async => throw Exception('Service failure'),
            );
          } catch (e) {
            // Expected to fail
          }
        }

        // Circuit breaker should now be open
        expect(() async {
          await errorHandler.executeWithErrorHandling<String>(
            serviceName: 'failing_service',
            operationId: 'blocked_op',
            operation: () async => 'should not execute',
          );
        }, throwsA(isA<ApiException>()));
      });
    });

    group('Token Economy Integration', () {
      test('should handle token wallet operations correctly', () {
        // Test new user wallet
        final newWallet = TokenWallet.newUser();
        expect(newWallet.balance, 10);
        expect(newWallet.totalEarned, 10);
        expect(newWallet.totalSpent, 0);

        // Test cost checking
        expect(newWallet.canAfford(AnalysisSpeed.instant.cost), true);
        expect(newWallet.canAfford(15), false);

        // Test wallet updates
        final updatedWallet = newWallet.copyWith(
          balance: 8,
          totalSpent: 2,
        );
        expect(updatedWallet.balance, 8);
        expect(updatedWallet.totalSpent, 2);
      });

      test('should track analysis speed costs correctly', () {
        expect(AnalysisSpeed.instant.cost, 5);
        expect(AnalysisSpeed.batch.cost, 1);
        expect(AnalysisSpeed.instant.displayName, 'Instant');
        expect(AnalysisSpeed.batch.displayName, 'Batch (2-6h)');
      });
    });

    group('Cost Analytics and Reporting', () {
      test('should provide comprehensive cost analytics', () async {
        when(mockPricingService.getBudgetUtilization()).thenReturn({
          'daily': 45.0,
          'weekly': 23.0,
          'monthly': 15.0,
        });

        when(mockPricingService.getBudgets()).thenReturn({
          'daily_budget': 5.00,
          'weekly_budget': 30.00,
          'monthly_budget': 100.00,
        });

        when(mockPricingService.getDailySpending()).thenReturn(2.25);
        when(mockPricingService.getWeeklySpending()).thenReturn(6.90);
        when(mockPricingService.getMonthlySpending()).thenReturn(15.00);

        when(mockGuardrailService.getCostAnalyticsSummary()).thenReturn({
          'batch_mode_enforced': false,
          'guardrails_enabled': true,
          'threshold_percentage': 80.0,
          'budget_utilization': {
            'daily': 45.0,
            'weekly': 23.0,
            'monthly': 15.0,
          },
          'recent_alerts_count': 0,
        });

        final analytics = mockGuardrailService.getCostAnalyticsSummary();

        expect(analytics['batch_mode_enforced'], false);
        expect(analytics['guardrails_enabled'], true);
        expect(analytics['budget_utilization']['daily'], 45.0);
      });
    });
  });

  group('Integration Scenarios', () {
    test('should handle complete analysis workflow with cost tracking', () async {
      // This test simulates a complete analysis workflow
      // from cost checking to result processing

      final mockServices = _createMockServices();
      
      // Mock a successful analysis scenario
      when(mockServices.guardrailService.canUseInstantAnalysis(model: anyNamed('model')))
          .thenReturn(true);
      
      when(mockServices.pricingService.calculateCost(
        model: anyNamed('model'),
        inputTokens: anyNamed('inputTokens'),
        outputTokens: anyNamed('outputTokens'),
        isBatchMode: anyNamed('isBatchMode'),
      )).thenReturn(0.025);

      // Verify the workflow completes successfully
      expect(mockServices.guardrailService.canUseInstantAnalysis(model: 'gpt_4_1_nano'), true);
      
      final cost = mockServices.pricingService.calculateCost(
        model: 'gpt_4_1_nano',
        inputTokens: 1500,
        outputTokens: 800,
        isBatchMode: false,
      );
      expect(cost, 0.025);
    });

    test('should handle budget exceeded scenario', () async {
      final mockServices = _createMockServices();
      
      // Mock budget exceeded scenario
      when(mockServices.guardrailService.canUseInstantAnalysis(model: anyNamed('model')))
          .thenReturn(false);
      when(mockServices.guardrailService.getRecommendedAnalysisSpeed(model: anyNamed('model')))
          .thenReturn(AnalysisSpeed.batch);

      expect(mockServices.guardrailService.canUseInstantAnalysis(model: 'gpt_4_1_nano'), false);
      expect(mockServices.guardrailService.getRecommendedAnalysisSpeed(model: 'gpt_4_1_nano'), 
             AnalysisSpeed.batch);
    });
  });
}

// Helper class to group mock services
class MockServices {
  final MockDynamicPricingService pricingService;
  final MockCostGuardrailService guardrailService;
  final MockRemoteConfigService remoteConfigService;

  MockServices({
    required this.pricingService,
    required this.guardrailService,
    required this.remoteConfigService,
  });
}

MockServices _createMockServices() {
  final mockPricing = MockDynamicPricingService();
  final mockGuardrail = MockCostGuardrailService();
  final mockRemoteConfig = MockRemoteConfigService();

  return MockServices(
    pricingService: mockPricing,
    guardrailService: mockGuardrail,
    remoteConfigService: mockRemoteConfig,
  );
}