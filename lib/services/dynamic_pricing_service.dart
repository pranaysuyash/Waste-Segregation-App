import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/remote_config_service.dart';
import '../utils/waste_app_logger.dart';

/// Service for managing dynamic pricing and cost optimization
///
/// Integrates with Firebase Remote Config to provide real-time pricing updates,
/// cost monitoring, and automatic batch mode enforcement when budget limits are reached.
class DynamicPricingService extends ChangeNotifier {
  DynamicPricingService({
    RemoteConfigService? remoteConfigService,
  }) : _remoteConfigService = remoteConfigService ?? RemoteConfigService();

  final RemoteConfigService _remoteConfigService;

  // Default pricing (fallback values)
  static const Map<String, double> _defaultPricing = {
    'gpt_4_1_nano_input': 0.000150, // per 1K tokens
    'gpt_4_1_nano_output': 0.000600, // per 1K tokens
    'gpt_4o_mini_input': 0.000150, // per 1K tokens
    'gpt_4o_mini_output': 0.000600, // per 1K tokens
    'gpt_4_1_mini_input': 0.000300, // per 1K tokens
    'gpt_4_1_mini_output': 0.001200, // per 1K tokens
    'gemini_2_0_flash_input': 0.000075, // per 1K tokens
    'gemini_2_0_flash_output': 0.000300, // per 1K tokens
    'batch_discount_rate': 0.50, // 50% discount for batch processing
  };

  static const Map<String, double> _defaultBudgets = {
    'daily_budget': 5.00, // $5 per day
    'weekly_budget': 30.00, // $30 per week
    'monthly_budget': 100.00, // $100 per month
  };

  static const Map<String, int> _defaultTokenLimits = {
    'avg_input_tokens': 1500, // Average input tokens per request
    'avg_output_tokens': 800, // Average output tokens per response
    'max_tokens_per_request': 4000, // Maximum tokens per single request
  };

  // Cached pricing data
  Map<String, double>? _cachedPricing;
  Map<String, double>? _cachedBudgets;
  Map<String, int>? _cachedTokenLimits;
  DateTime? _lastUpdate;

  // Current spending tracking
  final Map<String, double> _dailySpending = {};
  final Map<String, double> _weeklySpending = {};
  final Map<String, double> _monthlySpending = {};
  DateTime? _lastSpendingReset;

  /// Initialize the pricing service
  Future<void> initialize() async {
    try {
      await _remoteConfigService.initialize();
      await _loadPricingFromRemoteConfig();
      await _loadSpendingData();
      _schedulePeriodicUpdates();

      WasteAppLogger.info('DynamicPricingService initialized successfully', null, null, {
        'service': 'dynamic_pricing_service',
        'pricing_models': _cachedPricing?.keys.toList() ?? [],
        'last_update': _lastUpdate?.toIso8601String(),
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to initialize DynamicPricingService', e, null, {
        'service': 'dynamic_pricing_service',
        'action': 'falling_back_to_defaults',
      });
      
      // Fall back to default pricing
      _cachedPricing = Map.from(_defaultPricing);
      _cachedBudgets = Map.from(_defaultBudgets);
      _cachedTokenLimits = Map.from(_defaultTokenLimits);
      _lastUpdate = DateTime.now();
    }
  }

  /// Load pricing configuration from Remote Config
  Future<void> _loadPricingFromRemoteConfig() async {
    try {
      // Load pricing data
      final pricingJson = await _remoteConfigService.getString('ai_model_pricing', 
          defaultValue: jsonEncode(_defaultPricing));
      _cachedPricing = Map<String, double>.from(jsonDecode(pricingJson));

      // Load budget limits
      final budgetJson = await _remoteConfigService.getString('spending_budgets',
          defaultValue: jsonEncode(_defaultBudgets));
      _cachedBudgets = Map<String, double>.from(jsonDecode(budgetJson));

      // Load token limits
      final tokenJson = await _remoteConfigService.getString('token_limits',
          defaultValue: jsonEncode(_defaultTokenLimits));
      _cachedTokenLimits = Map<String, int>.from(jsonDecode(tokenJson));

      _lastUpdate = DateTime.now();

      WasteAppLogger.info('Loaded pricing from Remote Config', null, null, {
        'service': 'dynamic_pricing_service',
        'pricing_count': _cachedPricing?.length ?? 0,
        'budget_count': _cachedBudgets?.length ?? 0,
        'token_limits_count': _cachedTokenLimits?.length ?? 0,
      });

      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Failed to load pricing from Remote Config', e, null, {
        'service': 'dynamic_pricing_service',
        'action': 'using_cached_or_default_pricing',
      });
      
      // Keep existing cached pricing or use defaults
      _cachedPricing ??= Map.from(_defaultPricing);
      _cachedBudgets ??= Map.from(_defaultBudgets);
      _cachedTokenLimits ??= Map.from(_defaultTokenLimits);
    }
  }

  /// Load current spending data from local storage
  Future<void> _loadSpendingData() async {
    // TODO: Implement loading spending data from local storage or Firestore
    // For now, initialize empty spending tracking
    final today = DateTime.now();
    _lastSpendingReset = DateTime(today.year, today.month, today.day);
  }

  /// Schedule periodic updates for pricing and spending resets
  void _schedulePeriodicUpdates() {
    // Update pricing from Remote Config every hour
    Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await _remoteConfigService.forceFetch();
        await _loadPricingFromRemoteConfig();
      } catch (e) {
        WasteAppLogger.warning('Failed to update pricing from Remote Config', e, null, {
          'service': 'dynamic_pricing_service',
          'operation': 'periodic_update',
        });
      }
    });

    // Reset daily spending every day at midnight
    Timer.periodic(const Duration(hours: 1), (_) {
      _resetSpendingIfNeeded();
    });
  }

  /// Reset spending counters if a new day/week/month has started
  void _resetSpendingIfNeeded() {
    final now = DateTime.now();
    final lastReset = _lastSpendingReset ?? now;

    // Reset daily spending
    if (now.day != lastReset.day || now.month != lastReset.month || now.year != lastReset.year) {
      _dailySpending.clear();
      WasteAppLogger.info('Reset daily spending counters', null, null, {
        'service': 'dynamic_pricing_service',
        'reset_type': 'daily',
        'reset_date': now.toIso8601String(),
      });
    }

    // Reset weekly spending (Monday to Sunday)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = lastReset.subtract(Duration(days: lastReset.weekday - 1));
    if (weekStart.isAfter(lastWeekStart)) {
      _weeklySpending.clear();
      WasteAppLogger.info('Reset weekly spending counters', null, null, {
        'service': 'dynamic_pricing_service',
        'reset_type': 'weekly',
        'week_start': weekStart.toIso8601String(),
      });
    }

    // Reset monthly spending
    if (now.month != lastReset.month || now.year != lastReset.year) {
      _monthlySpending.clear();
      WasteAppLogger.info('Reset monthly spending counters', null, null, {
        'service': 'dynamic_pricing_service',
        'reset_type': 'monthly',
        'reset_month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
      });
    }

    _lastSpendingReset = now;
  }

  /// Get current pricing for a specific model
  double getModelPricing(String modelKey, {bool isOutput = false}) {
    final pricing = _cachedPricing ?? _defaultPricing;
    final key = isOutput ? '${modelKey}_output' : '${modelKey}_input';
    return pricing[key] ?? pricing['gpt_4o_mini_${isOutput ? 'output' : 'input'}']!;
  }

  /// Calculate cost for a specific API call
  double calculateCost({
    required String model,
    required int inputTokens,
    required int outputTokens,
    bool isBatchMode = false,
  }) {
    // Get base pricing
    final inputCost = getModelPricing(model) * (inputTokens / 1000.0);
    final outputCost = getModelPricing(model, isOutput: true) * (outputTokens / 1000.0);
    final totalCost = inputCost + outputCost;

    // Apply batch discount if applicable
    if (isBatchMode) {
      final discountRate = _cachedPricing?['batch_discount_rate'] ?? _defaultPricing['batch_discount_rate']!;
      return totalCost * (1.0 - discountRate);
    }

    return totalCost;
  }

  /// Record spending for cost tracking
  Future<void> recordSpending({
    required String model,
    required double cost,
    required int inputTokens,
    required int outputTokens,
    bool isBatchMode = false,
  }) async {
    _resetSpendingIfNeeded();

    // Update spending counters
    _dailySpending[model] = (_dailySpending[model] ?? 0.0) + cost;
    _weeklySpending[model] = (_weeklySpending[model] ?? 0.0) + cost;
    _monthlySpending[model] = (_monthlySpending[model] ?? 0.0) + cost;

    // Log the spending
    WasteAppLogger.info('Recorded API spending', null, null, {
      'service': 'dynamic_pricing_service',
      'model': model,
      'cost': cost,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'is_batch_mode': isBatchMode,
      'daily_total': getDailySpending(),
      'weekly_total': getWeeklySpending(),
      'monthly_total': getMonthlySpending(),
    });

    // Check if we need to enforce batch mode
    await _checkBudgetLimits();

    // TODO: Persist spending data to local storage or Firestore
    notifyListeners();
  }

  /// Check budget limits and enforce batch mode if necessary
  Future<void> _checkBudgetLimits() async {
    final budgets = _cachedBudgets ?? _defaultBudgets;
    final dailyBudget = budgets['daily_budget']!;
    final weeklyBudget = budgets['weekly_budget']!;
    final monthlyBudget = budgets['monthly_budget']!;

    final dailySpend = getDailySpending();
    final weeklySpend = getWeeklySpending();
    final monthlySpend = getMonthlySpending();

    // Check if we're at 80% of any budget limit
    final dailyThreshold = dailyBudget * 0.8;
    final weeklyThreshold = weeklyBudget * 0.8;
    final monthlyThreshold = monthlyBudget * 0.8;

    if (dailySpend >= dailyThreshold || weeklySpend >= weeklyThreshold || monthlySpend >= monthlyThreshold) {
      WasteAppLogger.warning('Budget threshold reached - enforcing batch mode', null, null, {
        'service': 'dynamic_pricing_service',
        'daily_spend': dailySpend,
        'daily_threshold': dailyThreshold,
        'weekly_spend': weeklySpend,
        'weekly_threshold': weeklyThreshold,
        'monthly_spend': monthlySpend,
        'monthly_threshold': monthlyThreshold,
        'action': 'force_batch_mode',
      });

      // TODO: Send notification to force batch mode in UI
      // This could be implemented via a stream or callback mechanism
      notifyListeners();
    }
  }

  /// Check if batch mode should be enforced due to budget limits
  bool shouldEnforceBatchMode() {
    final budgets = _cachedBudgets ?? _defaultBudgets;
    final dailyBudget = budgets['daily_budget']!;
    final weeklyBudget = budgets['weekly_budget']!;
    final monthlyBudget = budgets['monthly_budget']!;

    final dailySpend = getDailySpending();
    final weeklySpend = getWeeklySpending();
    final monthlySpend = getMonthlySpending();

    // Enforce batch mode if we're at 80% of any budget
    return dailySpend >= (dailyBudget * 0.8) ||
           weeklySpend >= (weeklyBudget * 0.8) ||
           monthlySpend >= (monthlyBudget * 0.8);
  }

  /// Check if we can afford instant analysis
  bool canAffordInstantAnalysis({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) {
    final inputTokens = estimatedInputTokens ?? _cachedTokenLimits?['avg_input_tokens'] ?? _defaultTokenLimits['avg_input_tokens']!;
    final outputTokens = estimatedOutputTokens ?? _cachedTokenLimits?['avg_output_tokens'] ?? _defaultTokenLimits['avg_output_tokens']!;

    final estimatedCost = calculateCost(
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    final budgets = _cachedBudgets ?? _defaultBudgets;
    final dailyBudget = budgets['daily_budget']!;
    final remainingDailyBudget = dailyBudget - getDailySpending();

    return estimatedCost <= remainingDailyBudget;
  }

  /// Get total daily spending across all models
  double getDailySpending() {
    return _dailySpending.values.fold(0.0, (sum, cost) => sum + cost);
  }

  /// Get total weekly spending across all models
  double getWeeklySpending() {
    return _weeklySpending.values.fold(0.0, (sum, cost) => sum + cost);
  }

  /// Get total monthly spending across all models
  double getMonthlySpending() {
    return _monthlySpending.values.fold(0.0, (sum, cost) => sum + cost);
  }

  /// Get spending breakdown by model for a specific period
  Map<String, double> getSpendingBreakdown(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return Map.from(_dailySpending);
      case 'weekly':
        return Map.from(_weeklySpending);
      case 'monthly':
        return Map.from(_monthlySpending);
      default:
        return {};
    }
  }

  /// Get budget information
  Map<String, double> getBudgets() {
    return Map.from(_cachedBudgets ?? _defaultBudgets);
  }

  /// Get budget utilization percentages
  Map<String, double> getBudgetUtilization() {
    final budgets = _cachedBudgets ?? _defaultBudgets;
    return {
      'daily': (getDailySpending() / budgets['daily_budget']!) * 100,
      'weekly': (getWeeklySpending() / budgets['weekly_budget']!) * 100,
      'monthly': (getMonthlySpending() / budgets['monthly_budget']!) * 100,
    };
  }

  /// Get estimated cost savings from using batch mode
  double getEstimatedBatchSavings({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) {
    final inputTokens = estimatedInputTokens ?? _cachedTokenLimits?['avg_input_tokens'] ?? _defaultTokenLimits['avg_input_tokens']!;
    final outputTokens = estimatedOutputTokens ?? _cachedTokenLimits?['avg_output_tokens'] ?? _defaultTokenLimits['avg_output_tokens']!;

    final instantCost = calculateCost(
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    final batchCost = calculateCost(
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      isBatchMode: true,
    );

    return instantCost - batchCost;
  }

  /// Force refresh pricing from Remote Config
  Future<void> refreshPricing() async {
    try {
      await _remoteConfigService.forceFetch();
      await _loadPricingFromRemoteConfig();
      
      WasteAppLogger.info('Successfully refreshed pricing from Remote Config', null, null, {
        'service': 'dynamic_pricing_service',
        'operation': 'refresh_pricing',
        'last_update': _lastUpdate?.toIso8601String(),
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to refresh pricing', e, null, {
        'service': 'dynamic_pricing_service',
        'operation': 'refresh_pricing',
      });
      rethrow;
    }
  }

  /// Get pricing summary for debugging/admin purposes
  Map<String, dynamic> getPricingSummary() {
    return {
      'pricing': Map.from(_cachedPricing ?? {}),
      'budgets': Map.from(_cachedBudgets ?? {}),
      'token_limits': Map.from(_cachedTokenLimits ?? {}),
      'daily_spending': Map.from(_dailySpending),
      'weekly_spending': Map.from(_weeklySpending),
      'monthly_spending': Map.from(_monthlySpending),
      'last_update': _lastUpdate?.toIso8601String(),
      'batch_mode_enforced': shouldEnforceBatchMode(),
      'budget_utilization': getBudgetUtilization(),
    };
  }

  @override
  void dispose() {
    // TODO: Cancel any active timers
    super.dispose();
  }
}