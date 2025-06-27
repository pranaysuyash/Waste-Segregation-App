import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/dynamic_pricing_service.dart';
import '../services/remote_config_service.dart';
import '../models/token_wallet.dart';
import '../utils/waste_app_logger.dart';

/// Service for monitoring costs and enforcing budget guardrails
///
/// Provides:
/// - Real-time cost monitoring and alerts
/// - Automatic batch mode enforcement when budgets are exceeded
/// - Cost analytics and reporting
/// - Integration with token economy and dynamic pricing
class CostGuardrailService extends ChangeNotifier {
  CostGuardrailService({
    DynamicPricingService? pricingService,
    RemoteConfigService? remoteConfigService,
  })  : _pricingService = pricingService ?? DynamicPricingService(),
        _remoteConfigService = remoteConfigService ?? RemoteConfigService();

  final DynamicPricingService _pricingService;
  final RemoteConfigService _remoteConfigService;

  // Guardrail state
  bool _batchModeEnforced = false;
  DateTime? _batchModeEnforcedAt;
  String? _lastAlertSent;
  final List<CostAlert> _recentAlerts = [];

  // Monitoring configuration
  bool _guardrailsEnabled = true;
  double _budgetThresholdPercentage = 80.0;
  bool _forceBatchModeOnThreshold = true;

  // Stream controllers for real-time updates
  final StreamController<bool> _batchModeStream = StreamController<bool>.broadcast();
  final StreamController<CostAlert> _alertStream = StreamController<CostAlert>.broadcast();
  final StreamController<Map<String, double>> _budgetUtilizationStream = 
      StreamController<Map<String, double>>.broadcast();

  /// Stream of batch mode enforcement state
  Stream<bool> get batchModeEnforced => _batchModeStream.stream;

  /// Stream of cost alerts
  Stream<CostAlert> get costAlerts => _alertStream.stream;

  /// Stream of budget utilization percentages
  Stream<Map<String, double>> get budgetUtilization => _budgetUtilizationStream.stream;

  /// Current batch mode enforcement status
  bool get isBatchModeEnforced => _batchModeEnforced;

  /// When batch mode was enforced (if currently enforced)
  DateTime? get batchModeEnforcedAt => _batchModeEnforcedAt;

  /// Initialize the cost guardrail service
  Future<void> initialize() async {
    try {
      await _pricingService.initialize();
      await _loadConfiguration();
      _startMonitoring();

      WasteAppLogger.info('CostGuardrailService initialized', null, null, {
        'service': 'cost_guardrail_service',
        'guardrails_enabled': _guardrailsEnabled,
        'threshold_percentage': _budgetThresholdPercentage,
        'force_batch_mode': _forceBatchModeOnThreshold,
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to initialize CostGuardrailService', e, null, {
        'service': 'cost_guardrail_service',
      });
      rethrow;
    }
  }

  /// Load configuration from Remote Config
  Future<void> _loadConfiguration() async {
    try {
      _guardrailsEnabled = await _remoteConfigService.getBool(
        'cost_guardrails_enabled', 
        defaultValue: true,
      );
      
      _budgetThresholdPercentage = (await _remoteConfigService.getInt(
        'budget_threshold_percentage', 
        defaultValue: 80,
      )).toDouble();
      
      _forceBatchModeOnThreshold = await _remoteConfigService.getBool(
        'force_batch_mode_on_threshold', 
        defaultValue: true,
      );

      WasteAppLogger.info('Loaded cost guardrail configuration', null, null, {
        'service': 'cost_guardrail_service',
        'guardrails_enabled': _guardrailsEnabled,
        'threshold_percentage': _budgetThresholdPercentage,
        'force_batch_mode': _forceBatchModeOnThreshold,
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to load guardrail configuration, using defaults', e, null, {
        'service': 'cost_guardrail_service',
      });
    }
  }

  /// Start continuous cost monitoring
  void _startMonitoring() {
    // Monitor cost changes every minute
    Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!_guardrailsEnabled) return;
      
      try {
        await _checkBudgetThresholds();
        await _updateBudgetUtilizationStream();
      } catch (e) {
        WasteAppLogger.warning('Error during cost monitoring', e, null, {
          'service': 'cost_guardrail_service',
          'operation': 'monitoring_cycle',
        });
      }
    });

    // Listen to pricing service changes
    _pricingService.addListener(_onPricingServiceChange);
  }

  /// Handle pricing service changes
  void _onPricingServiceChange() {
    if (!_guardrailsEnabled) return;
    
    // Check if we need to update batch mode enforcement
    final shouldEnforce = _pricingService.shouldEnforceBatchMode();
    _updateBatchModeEnforcement(shouldEnforce);
  }

  /// Check budget thresholds and trigger alerts/actions
  Future<void> _checkBudgetThresholds() async {
    final utilization = _pricingService.getBudgetUtilization();
    final budgets = _pricingService.getBudgets();

    // Check each budget period
    for (final entry in utilization.entries) {
      final period = entry.key;
      final percentage = entry.value;
      final budget = budgets['${period}_budget'] ?? 0.0;
      final spending = _getSpendingForPeriod(period);

      await _checkSingleBudgetThreshold(
        period: period,
        percentage: percentage,
        budget: budget,
        spending: spending,
      );
    }
  }

  /// Check a single budget threshold
  Future<void> _checkSingleBudgetThreshold({
    required String period,
    required double percentage,
    required double budget,
    required double spending,
  }) async {
    // Check if we've exceeded the threshold
    if (percentage >= _budgetThresholdPercentage) {
      await _handleBudgetThresholdExceeded(
        period: period,
        percentage: percentage,
        budget: budget,
        spending: spending,
      );
    }

    // Send warnings at 50%, 75%, and 90% utilization
    await _checkWarningThresholds(
      period: period,
      percentage: percentage,
      budget: budget,
      spending: spending,
    );
  }

  /// Handle when budget threshold is exceeded
  Future<void> _handleBudgetThresholdExceeded({
    required String period,
    required double percentage,
    required double budget,
    required double spending,
  }) async {
    final alert = CostAlert(
      id: 'budget_exceeded_${period}_${DateTime.now().millisecondsSinceEpoch}',
      type: CostAlertType.budgetExceeded,
      severity: CostAlertSeverity.critical,
      period: period,
      percentage: percentage,
      budget: budget,
      spending: spending,
      message: 'Budget threshold exceeded for $period period',
      timestamp: DateTime.now(),
    );

    await _sendAlert(alert);

    // Enforce batch mode if configured
    if (_forceBatchModeOnThreshold) {
      _updateBatchModeEnforcement(true);
      
      WasteAppLogger.warning('Enforcing batch mode due to budget threshold', null, null, {
        'service': 'cost_guardrail_service',
        'period': period,
        'percentage': percentage,
        'threshold': _budgetThresholdPercentage,
        'budget': budget,
        'spending': spending,
      });
    }
  }

  /// Check warning thresholds and send appropriate alerts
  Future<void> _checkWarningThresholds({
    required String period,
    required double percentage,
    required double budget,
    required double spending,
  }) async {
    final warnings = [
      (50.0, CostAlertSeverity.info, 'Budget warning: 50% utilized'),
      (75.0, CostAlertSeverity.warning, 'Budget warning: 75% utilized'),
      (90.0, CostAlertSeverity.high, 'Budget warning: 90% utilized'),
    ];

    for (final warning in warnings) {
      final threshold = warning.$1;
      final severity = warning.$2;
      final message = warning.$3;

      if (percentage >= threshold && !_wasAlertSentForThreshold(period, threshold)) {
        final alert = CostAlert(
          id: 'budget_warning_${period}_${threshold.toInt()}_${DateTime.now().millisecondsSinceEpoch}',
          type: CostAlertType.budgetWarning,
          severity: severity,
          period: period,
          percentage: percentage,
          budget: budget,
          spending: spending,
          message: '$message for $period period',
          timestamp: DateTime.now(),
        );

        await _sendAlert(alert);
      }
    }
  }

  /// Send a cost alert
  Future<void> _sendAlert(CostAlert alert) async {
    _recentAlerts.add(alert);
    
    // Keep only last 50 alerts
    if (_recentAlerts.length > 50) {
      _recentAlerts.removeAt(0);
    }

    // Add to stream
    _alertStream.add(alert);

    WasteAppLogger.warning('Cost alert sent', null, null, {
      'service': 'cost_guardrail_service',
      'alert_id': alert.id,
      'alert_type': alert.type.name,
      'severity': alert.severity.name,
      'period': alert.period,
      'percentage': alert.percentage,
      'budget': alert.budget,
      'spending': alert.spending,
      'message': alert.message,
    });

    notifyListeners();
  }

  /// Update batch mode enforcement state
  void _updateBatchModeEnforcement(bool shouldEnforce) {
    if (_batchModeEnforced != shouldEnforce) {
      _batchModeEnforced = shouldEnforce;
      _batchModeEnforcedAt = shouldEnforce ? DateTime.now() : null;
      
      _batchModeStream.add(_batchModeEnforced);
      notifyListeners();

      WasteAppLogger.info('Batch mode enforcement updated', null, null, {
        'service': 'cost_guardrail_service',
        'batch_mode_enforced': _batchModeEnforced,
        'enforced_at': _batchModeEnforcedAt?.toIso8601String(),
      });
    }
  }

  /// Update budget utilization stream
  Future<void> _updateBudgetUtilizationStream() async {
    final utilization = _pricingService.getBudgetUtilization();
    _budgetUtilizationStream.add(utilization);
  }

  /// Check if user can use instant analysis
  bool canUseInstantAnalysis({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) {
    // If batch mode is enforced, instant analysis is not allowed
    if (_batchModeEnforced) return false;

    // Check if pricing service allows it
    return _pricingService.canAffordInstantAnalysis(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    );
  }

  /// Get recommended analysis speed based on budget status
  AnalysisSpeed getRecommendedAnalysisSpeed({
    required String model,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
  }) {
    if (_batchModeEnforced) {
      return AnalysisSpeed.batch;
    }

    if (canUseInstantAnalysis(
      model: model,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    )) {
      return AnalysisSpeed.instant;
    }

    return AnalysisSpeed.batch;
  }

  /// Record API spending and check thresholds
  Future<void> recordApiSpending({
    required String model,
    required double cost,
    required int inputTokens,
    required int outputTokens,
    bool isBatchMode = false,
  }) async {
    // Record in pricing service
    await _pricingService.recordSpending(
      model: model,
      cost: cost,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      isBatchMode: isBatchMode,
    );

    // Immediately check thresholds after spending
    await _checkBudgetThresholds();
  }

  /// Get spending for a specific period
  double _getSpendingForPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return _pricingService.getDailySpending();
      case 'weekly':
        return _pricingService.getWeeklySpending();
      case 'monthly':
        return _pricingService.getMonthlySpending();
      default:
        return 0.0;
    }
  }

  /// Check if an alert was already sent for a specific threshold
  bool _wasAlertSentForThreshold(String period, double threshold) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1)); // Don't repeat alerts within 1 hour

    return _recentAlerts.any((alert) =>
        alert.period == period &&
        alert.type == CostAlertType.budgetWarning &&
        alert.percentage >= threshold &&
        alert.timestamp.isAfter(cutoff));
  }

  /// Get recent alerts
  List<CostAlert> getRecentAlerts({int limit = 20}) {
    return _recentAlerts.reversed.take(limit).toList();
  }

  /// Get cost analytics summary
  Map<String, dynamic> getCostAnalyticsSummary() {
    final utilization = _pricingService.getBudgetUtilization();
    final budgets = _pricingService.getBudgets();
    
    return {
      'batch_mode_enforced': _batchModeEnforced,
      'batch_mode_enforced_at': _batchModeEnforcedAt?.toIso8601String(),
      'guardrails_enabled': _guardrailsEnabled,
      'threshold_percentage': _budgetThresholdPercentage,
      'budget_utilization': utilization,
      'budgets': budgets,
      'daily_spending': _pricingService.getDailySpending(),
      'weekly_spending': _pricingService.getWeeklySpending(),
      'monthly_spending': _pricingService.getMonthlySpending(),
      'recent_alerts_count': _recentAlerts.length,
      'last_alert': _recentAlerts.isNotEmpty ? _recentAlerts.last.toJson() : null,
    };
  }

  /// Manually override batch mode enforcement (for testing or admin)
  void overrideBatchModeEnforcement({required bool enforce, String? reason}) {
    _updateBatchModeEnforcement(enforce);
    
    WasteAppLogger.info('Batch mode enforcement manually overridden', null, null, {
      'service': 'cost_guardrail_service',
      'enforce': enforce,
      'reason': reason,
      'overridden_at': DateTime.now().toIso8601String(),
    });
  }

  /// Temporarily disable guardrails (for emergencies)
  void temporarilyDisableGuardrails({required Duration duration, String? reason}) {
    _guardrailsEnabled = false;
    _updateBatchModeEnforcement(false);
    
    Timer(duration, () {
      _guardrailsEnabled = true;
      WasteAppLogger.info('Guardrails re-enabled after temporary disable', null, null, {
        'service': 'cost_guardrail_service',
        'disabled_duration_minutes': duration.inMinutes,
        'reason': reason,
      });
    });

    WasteAppLogger.warning('Guardrails temporarily disabled', null, null, {
      'service': 'cost_guardrail_service',
      'duration_minutes': duration.inMinutes,
      'reason': reason,
      'disabled_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _pricingService.removeListener(_onPricingServiceChange);
    _batchModeStream.close();
    _alertStream.close();
    _budgetUtilizationStream.close();
    super.dispose();
  }
}

/// Cost alert data model
class CostAlert {
  const CostAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.period,
    required this.percentage,
    required this.budget,
    required this.spending,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final CostAlertType type;
  final CostAlertSeverity severity;
  final String period;
  final double percentage;
  final double budget;
  final double spending;
  final String message;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'period': period,
      'percentage': percentage,
      'budget': budget,
      'spending': spending,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Types of cost alerts
enum CostAlertType {
  budgetWarning,
  budgetExceeded,
  anomalyDetected,
  rateLimitApproaching,
}

/// Severity levels for cost alerts
enum CostAlertSeverity {
  info,
  warning,
  high,
  critical,
}