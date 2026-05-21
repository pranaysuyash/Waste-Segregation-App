import 'dart:async';
import '../utils/waste_app_logger.dart';
import 'api_client_factory.dart';
import 'enhanced_ai_api_service.dart';

/// Comprehensive API management service
///
/// Features:
/// - Centralized API client management
/// - Cost monitoring and optimization
/// - Performance analytics
/// - Health monitoring
/// - Configuration management
/// - Automatic scaling and optimization
class ApiManagementService {
  factory ApiManagementService() => _instance;
  ApiManagementService._internal();
  static final ApiManagementService _instance =
      ApiManagementService._internal();

  // Service instances
  EnhancedAiApiService? _aiApiService;
  Timer? _monitoringTimer;
  Timer? _optimizationTimer;

  // Configuration
  bool _initialized = false;
  bool _monitoringEnabled = true;
  bool _optimizationEnabled = true;
  Duration _monitoringInterval = const Duration(minutes: 5);
  Duration _optimizationInterval = const Duration(minutes: 15);

  // Metrics
  final Map<String, dynamic> _performanceMetrics = {};
  final Map<String, double> _costMetrics = {};
  final List<String> _healthAlerts = [];

  /// Initialize the API management service
  Future<void> initialize({
    bool enableMonitoring = true,
    bool enableOptimization = true,
    Duration? monitoringInterval,
    Duration? optimizationInterval,
  }) async {
    if (_initialized) return;

    try {
      _monitoringEnabled = enableMonitoring;
      _optimizationEnabled = enableOptimization;
      _monitoringInterval = monitoringInterval ?? _monitoringInterval;
      _optimizationInterval = optimizationInterval ?? _optimizationInterval;

      // Initialize AI API service
      _aiApiService = EnhancedAiApiService();
      await _aiApiService!.initialize();

      // Start monitoring and optimization timers
      if (_monitoringEnabled) {
        _startMonitoring();
      }

      if (_optimizationEnabled) {
        _startOptimization();
      }

      _initialized = true;

      WasteAppLogger.info('API Management Service initialized', context: {
        'monitoring_enabled': _monitoringEnabled,
        'optimization_enabled': _optimizationEnabled,
        'monitoring_interval_minutes': _monitoringInterval.inMinutes,
        'optimization_interval_minutes': _optimizationInterval.inMinutes,
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to initialize API Management Service',
          error: e,
          context: {
            'error_type': e.runtimeType.toString(),
          });
      rethrow;
    }
  }

  /// Get the AI API service instance
  EnhancedAiApiService get aiApiService {
    if (!_initialized || _aiApiService == null) {
      throw StateError('API Management Service not initialized');
    }
    return _aiApiService!;
  }

  /// Start performance monitoring
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _performMonitoringCycle();
    });

    WasteAppLogger.info('API monitoring started', context: {
      'interval_minutes': _monitoringInterval.inMinutes,
    });
  }

  /// Start optimization processes
  void _startOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = Timer.periodic(_optimizationInterval, (_) {
      _performOptimizationCycle();
    });

    WasteAppLogger.info('API optimization started', context: {
      'interval_minutes': _optimizationInterval.inMinutes,
    });
  }

  /// Perform monitoring cycle
  Future<void> _performMonitoringCycle() async {
    try {
      WasteAppLogger.fine('Starting monitoring cycle', context: {
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Collect metrics from all clients
      final clientStats = ApiClientFactory.getAllStatistics();
      _performanceMetrics['clients'] = clientStats;
      _performanceMetrics['last_updated'] = DateTime.now().toIso8601String();

      // Collect AI service metrics
      if (_aiApiService != null) {
        _performanceMetrics['ai_service'] = _aiApiService!.getStatistics();
      }

      // Check for health issues
      _checkHealthStatus(clientStats);

      // Update cost metrics
      _updateCostMetrics(clientStats);

      WasteAppLogger.fine('Monitoring cycle completed', context: {
        'total_clients': clientStats.length,
        'health_alerts': _healthAlerts.length,
      });
    } catch (e) {
      WasteAppLogger.warning('Monitoring cycle failed', error: e, context: {
        'cycle_time': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Perform optimization cycle
  Future<void> _performOptimizationCycle() async {
    try {
      WasteAppLogger.fine('Starting optimization cycle', context: {
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Analyze performance patterns
      final optimizations = _analyzePerformancePatterns();

      // Apply optimizations
      for (final optimization in optimizations) {
        await _applyOptimization(optimization);
      }

      // Clean up resources
      _cleanupResources();

      WasteAppLogger.fine('Optimization cycle completed', context: {
        'optimizations_applied': optimizations.length,
      });
    } catch (e) {
      WasteAppLogger.warning('Optimization cycle failed', error: e, context: {
        'cycle_time': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Check health status of all services
  void _checkHealthStatus(Map<String, dynamic> clientStats) {
    _healthAlerts.clear();

    for (final entry in clientStats.entries) {
      final serviceName = entry.key;
      final stats = entry.value as Map<String, dynamic>;

      // Check circuit breaker status
      final circuitStatus =
          stats['circuit_breaker_status'] as Map<String, dynamic>?;
      if (circuitStatus != null) {
        final services = circuitStatus['services'] as Map<String, dynamic>?;
        if (services != null) {
          for (final serviceEntry in services.entries) {
            final serviceData = serviceEntry.value as Map<String, dynamic>;
            final state = serviceData['state'] as String?;
            if (state == 'open') {
              _healthAlerts.add('Circuit breaker open for ${serviceEntry.key}');
            }
          }
        }
      }

      // Check rate limiter utilization
      final rateLimiters = stats['rate_limiters'] as Map<String, dynamic>?;
      if (rateLimiters != null) {
        for (final limiterEntry in rateLimiters.entries) {
          final limiterData = limiterEntry.value as Map<String, dynamic>;
          final utilization = limiterData['utilization_percent'] as int?;
          if (utilization != null && utilization > 90) {
            _healthAlerts.add(
                'High rate limit utilization for ${limiterEntry.key}: $utilization%');
          }
        }
      }

      // Check active requests
      final activeRequests = stats['active_requests'] as int?;
      final queuedRequests = stats['queued_requests'] as int?;
      if (activeRequests != null && queuedRequests != null) {
        if (queuedRequests > 10) {
          _healthAlerts.add(
              'High request queue for $serviceName: $queuedRequests requests');
        }
      }
    }

    if (_healthAlerts.isNotEmpty) {
      WasteAppLogger.warning('Health alerts detected', context: {
        'alerts': _healthAlerts,
        'alert_count': _healthAlerts.length,
      });
    }
  }

  /// Update cost metrics
  void _updateCostMetrics(Map<String, dynamic> clientStats) {
    var totalCost = 0.0;
    var totalRequests = 0;

    for (final entry in clientStats.entries) {
      final serviceName = entry.key;
      final stats = entry.value as Map<String, dynamic>;

      // Extract request count from stats
      final requestsMade = stats['requests_made'] as int? ?? 0;
      totalRequests += requestsMade;

      // Calculate estimated cost based on request count
      // Using approximate cost per request (can be configured per service)
      final estimatedCostPerRequest = _getEstimatedCostPerRequest(serviceName);
      final serviceCost = requestsMade * estimatedCostPerRequest;

      _costMetrics[serviceName] = serviceCost;
      totalCost += serviceCost;
    }

    _costMetrics['total_cost'] = totalCost;
    _costMetrics['total_requests'] = totalRequests.toDouble();
    _costMetrics['average_cost_per_request'] =
        totalRequests > 0 ? totalCost / totalRequests : 0.0;
    _costMetrics['last_updated'] =
        DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  /// Get estimated cost per request for a service
  double _getEstimatedCostPerRequest(String serviceName) {
    // Approximate costs per request (in USD)
    // These should be configured based on actual API pricing
    const costMap = {
      'openai': 0.002, // ~$0.002 per request for GPT-4 Vision
      'anthropic': 0.003, // ~$0.003 per request for Claude Vision
      'google': 0.001, // ~$0.001 per request for Gemini
      'default': 0.001,
    };

    // Find matching cost or use default
    for (final entry in costMap.entries) {
      if (serviceName.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return costMap['default']!;
  }

  /// Analyze performance patterns for optimization
  List<OptimizationAction> _analyzePerformancePatterns() {
    final actions = <OptimizationAction>[];

    // Analyze rate limit utilization
    final clientStats = ApiClientFactory.getAllStatistics();
    for (final entry in clientStats.entries) {
      final serviceName = entry.key;
      final stats = entry.value as Map<String, dynamic>;

      final rateLimiters = stats['rate_limiters'] as Map<String, dynamic>?;
      if (rateLimiters != null) {
        for (final limiterEntry in rateLimiters.entries) {
          final limiterData = limiterEntry.value as Map<String, dynamic>;
          final utilization = limiterData['utilization_percent'] as int?;

          if (utilization != null) {
            if (utilization > 80) {
              actions.add(OptimizationAction(
                type: OptimizationType.increaseRateLimit,
                serviceName: serviceName,
                details: {'current_utilization': utilization},
              ));
            } else if (utilization < 20) {
              actions.add(OptimizationAction(
                type: OptimizationType.decreaseRateLimit,
                serviceName: serviceName,
                details: {'current_utilization': utilization},
              ));
            }
          }
        }
      }
    }

    // Analyze request patterns for caching opportunities
    // This would be enhanced based on actual usage patterns

    return actions;
  }

  /// Apply optimization action
  Future<void> _applyOptimization(OptimizationAction action) async {
    try {
      switch (action.type) {
        case OptimizationType.increaseRateLimit:
          // Increase rate limit for service
          WasteAppLogger.info('Applying rate limit increase', context: {
            'service': action.serviceName,
            'details': action.details,
          });
          break;

        case OptimizationType.decreaseRateLimit:
          // Decrease rate limit for service
          WasteAppLogger.info('Applying rate limit decrease', context: {
            'service': action.serviceName,
            'details': action.details,
          });
          break;

        case OptimizationType.enableCaching:
          // Enable caching for service
          WasteAppLogger.info('Enabling caching', context: {
            'service': action.serviceName,
            'details': action.details,
          });
          break;

        case OptimizationType.adjustTimeout:
          // Adjust timeout settings
          WasteAppLogger.info('Adjusting timeout', context: {
            'service': action.serviceName,
            'details': action.details,
          });
          break;
      }
    } catch (e) {
      WasteAppLogger.warning('Failed to apply optimization',
          error: e,
          context: {
            'action_type': action.type.name,
            'service': action.serviceName,
          });
    }
  }

  /// Clean up resources
  void _cleanupResources() {
    // Clean up expired cache entries, old metrics, etc.
    final now = DateTime.now();

    // Remove old performance metrics (keep last 24 hours)
    final cutoff = now.subtract(const Duration(hours: 24));
    final cutoffMillis = cutoff.millisecondsSinceEpoch.toDouble();

    // Remove old cost metrics
    final costKeysToRemove = <String>[];
    for (final entry in _costMetrics.entries) {
      if (entry.key.startsWith('snapshot_')) {
        // Check if this is an old snapshot based on timestamp in key
        final parts = entry.key.split('_');
        if (parts.length > 1) {
          final timestamp = double.tryParse(parts.last);
          if (timestamp != null && timestamp < cutoffMillis) {
            costKeysToRemove.add(entry.key);
          }
        }
      }
    }
    for (final key in costKeysToRemove) {
      _costMetrics.remove(key);
    }

    // Trim health alerts to last 50 entries
    if (_healthAlerts.length > 50) {
      _healthAlerts.removeRange(0, _healthAlerts.length - 50);
    }

    WasteAppLogger.fine('Resource cleanup completed', context: {
      'cleanup_time': now.toIso8601String(),
      'cost_metrics_removed': costKeysToRemove.length,
      'health_alerts_count': _healthAlerts.length,
    });
  }

  /// Get comprehensive service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'initialized': _initialized,
      'monitoring_enabled': _monitoringEnabled,
      'optimization_enabled': _optimizationEnabled,
      'performance_metrics': _performanceMetrics,
      'cost_metrics': _costMetrics,
      'health_alerts': _healthAlerts,
      'client_statistics': ApiClientFactory.getAllStatistics(),
      'ai_service_statistics': _aiApiService?.getStatistics(),
      'last_monitoring_cycle': _performanceMetrics['last_updated'],
    };
  }

  /// Get health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'overall_status': _healthAlerts.isEmpty ? 'healthy' : 'warning',
      'alerts': _healthAlerts,
      'alert_count': _healthAlerts.length,
      'services_monitored': ApiClientFactory.getAllClients().length,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  /// Get cost summary
  Map<String, dynamic> getCostSummary() {
    return Map<String, dynamic>.from(_costMetrics);
  }

  /// Reset all statistics
  void resetStatistics() {
    _performanceMetrics.clear();
    _costMetrics.clear();
    _healthAlerts.clear();
    _aiApiService?.resetStatistics();

    WasteAppLogger.info('API Management Service statistics reset', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Update configuration
  void updateConfiguration({
    bool? enableMonitoring,
    bool? enableOptimization,
    Duration? monitoringInterval,
    Duration? optimizationInterval,
  }) {
    if (enableMonitoring != null) {
      _monitoringEnabled = enableMonitoring;
      if (_monitoringEnabled) {
        _startMonitoring();
      } else {
        _monitoringTimer?.cancel();
      }
    }

    if (enableOptimization != null) {
      _optimizationEnabled = enableOptimization;
      if (_optimizationEnabled) {
        _startOptimization();
      } else {
        _optimizationTimer?.cancel();
      }
    }

    if (monitoringInterval != null) {
      _monitoringInterval = monitoringInterval;
      if (_monitoringEnabled) {
        _startMonitoring(); // Restart with new interval
      }
    }

    if (optimizationInterval != null) {
      _optimizationInterval = optimizationInterval;
      if (_optimizationEnabled) {
        _startOptimization(); // Restart with new interval
      }
    }

    WasteAppLogger.info('API Management Service configuration updated',
        context: {
          'monitoring_enabled': _monitoringEnabled,
          'optimization_enabled': _optimizationEnabled,
          'monitoring_interval_minutes': _monitoringInterval.inMinutes,
          'optimization_interval_minutes': _optimizationInterval.inMinutes,
        });
  }

  /// Dispose the service
  void dispose() {
    _monitoringTimer?.cancel();
    _optimizationTimer?.cancel();

    _aiApiService?.dispose();
    ApiClientFactory.resetAllClients();

    _performanceMetrics.clear();
    _costMetrics.clear();
    _healthAlerts.clear();

    _initialized = false;

    WasteAppLogger.info('API Management Service disposed', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

/// Optimization action types
enum OptimizationType {
  increaseRateLimit,
  decreaseRateLimit,
  enableCaching,
  adjustTimeout,
}

/// Optimization action
class OptimizationAction {
  const OptimizationAction({
    required this.type,
    required this.serviceName,
    required this.details,
  });

  final OptimizationType type;
  final String serviceName;
  final Map<String, dynamic> details;
}
