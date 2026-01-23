import 'package:dio/dio.dart';
import '../utils/waste_app_logger.dart';

/// Interceptor for tracking API costs and usage patterns
class CostTrackingInterceptor extends Interceptor {
  CostTrackingInterceptor({
    this.enableDetailedLogging = true,
  });

  final bool enableDetailedLogging;

  // Cost tracking data
  final Map<String, ServiceCostTracker> _serviceTrackers = {};
  final Map<String, double> _defaultCosts = {
    'openai': 0.002, // $0.002 per request (approximate)
    'gemini': 0.001, // $0.001 per request (approximate)
    'firebase': 0.0001, // $0.0001 per request (approximate)
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Extract service name from URL or headers
    final serviceName = _extractServiceName(options);
    
    // Record request start
    options.extra['cost_tracking'] = {
      'service_name': serviceName,
      'start_time': DateTime.now(),
      'request_size': _calculateRequestSize(options),
    };

    if (enableDetailedLogging) {
      WasteAppLogger.fine('Cost tracking started', null, null, {
        'service': serviceName,
        'method': options.method,
        'endpoint': options.path,
        'request_size_bytes': options.extra['cost_tracking']['request_size'],
      });
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final costData = response.requestOptions.extra['cost_tracking'] as Map<String, dynamic>?;
    
    if (costData != null) {
      final serviceName = costData['service_name'] as String;
      final startTime = costData['start_time'] as DateTime;
      final requestSize = costData['request_size'] as int;
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      final responseSize = _calculateResponseSize(response);
      
      // Calculate estimated cost
      final estimatedCost = _calculateCost(
        serviceName: serviceName,
        requestSize: requestSize,
        responseSize: responseSize,
        duration: duration,
        statusCode: response.statusCode ?? 0,
      );

      // Track the cost
      _trackCost(
        serviceName: serviceName,
        cost: estimatedCost,
        duration: duration,
        requestSize: requestSize,
        responseSize: responseSize,
        statusCode: response.statusCode ?? 0,
        endpoint: response.requestOptions.path,
      );

      if (enableDetailedLogging) {
        WasteAppLogger.info('Cost tracking completed', null, null, {
          'service': serviceName,
          'estimated_cost': estimatedCost,
          'duration_ms': duration.inMilliseconds,
          'request_size_bytes': requestSize,
          'response_size_bytes': responseSize,
          'status_code': response.statusCode,
        });
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final costData = err.requestOptions.extra['cost_tracking'] as Map<String, dynamic>?;
    
    if (costData != null) {
      final serviceName = costData['service_name'] as String;
      final startTime = costData['start_time'] as DateTime;
      final requestSize = costData['request_size'] as int;
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Even failed requests may incur costs
      final estimatedCost = _calculateCost(
        serviceName: serviceName,
        requestSize: requestSize,
        responseSize: 0,
        duration: duration,
        statusCode: err.response?.statusCode ?? 0,
        isError: true,
      );

      // Track the failed request cost
      _trackCost(
        serviceName: serviceName,
        cost: estimatedCost,
        duration: duration,
        requestSize: requestSize,
        responseSize: 0,
        statusCode: err.response?.statusCode ?? 0,
        endpoint: err.requestOptions.path,
        isError: true,
      );

      if (enableDetailedLogging) {
        WasteAppLogger.warning('Cost tracking for failed request', err, null, {
          'service': serviceName,
          'estimated_cost': estimatedCost,
          'duration_ms': duration.inMilliseconds,
          'request_size_bytes': requestSize,
          'error_type': err.type.name,
        });
      }
    }

    handler.next(err);
  }

  /// Extract service name from request options
  String _extractServiceName(RequestOptions options) {
    // Check for explicit service name in headers
    final serviceHeader = options.headers['X-Service-Name'] as String?;
    if (serviceHeader != null) return serviceHeader;

    // Extract from URL
    final uri = options.uri;
    if (uri.host.contains('openai.com')) return 'openai';
    if (uri.host.contains('googleapis.com')) return 'gemini';
    if (uri.host.contains('firebase')) return 'firebase';
    if (uri.host.contains('firestore')) return 'firebase';

    // Check path for service indicators
    if (options.path.contains('/openai/')) return 'openai';
    if (options.path.contains('/gemini/')) return 'gemini';
    if (options.path.contains('/firebase/')) return 'firebase';

    return 'unknown';
  }

  /// Calculate request size in bytes
  int _calculateRequestSize(RequestOptions options) {
    int size = 0;
    
    // Headers size
    options.headers.forEach((key, value) {
      size += key.length + value.toString().length + 4; // +4 for ": " and "\r\n"
    });
    
    // Query parameters size
    options.queryParameters.forEach((key, value) {
      size += key.length + value.toString().length + 2; // +2 for "=" and "&"
    });
    
    // Body size
    if (options.data != null) {
      if (options.data is String) {
        size += (options.data as String).length;
      } else if (options.data is List<int>) {
        size += (options.data as List<int>).length;
      } else {
        // Estimate JSON size
        size += options.data.toString().length;
      }
    }
    
    return size;
  }

  /// Calculate response size in bytes
  int _calculateResponseSize(Response response) {
    int size = 0;
    
    // Headers size
    response.headers.map.forEach((key, values) {
      for (final value in values) {
        size += key.length + value.length + 4; // +4 for ": " and "\r\n"
      }
    });
    
    // Body size
    if (response.data != null) {
      if (response.data is String) {
        size += (response.data as String).length;
      } else if (response.data is List<int>) {
        size += (response.data as List<int>).length;
      } else {
        // Estimate JSON size
        size += response.data.toString().length;
      }
    }
    
    return size;
  }

  /// Calculate estimated cost for the request
  double _calculateCost({
    required String serviceName,
    required int requestSize,
    required int responseSize,
    required Duration duration,
    required int statusCode,
    bool isError = false,
  }) {
    final baseCost = _defaultCosts[serviceName] ?? 0.001;
    
    // Adjust cost based on various factors
    double multiplier = 1.0;
    
    // Size-based multiplier (larger requests/responses cost more)
    final totalSize = requestSize + responseSize;
    if (totalSize > 100000) { // 100KB
      multiplier *= 1.5;
    } else if (totalSize > 10000) { // 10KB
      multiplier *= 1.2;
    }
    
    // Duration-based multiplier (longer requests might indicate more processing)
    if (duration.inSeconds > 30) {
      multiplier *= 1.3;
    } else if (duration.inSeconds > 10) {
      multiplier *= 1.1;
    }
    
    // Error-based adjustment (failed requests might still incur partial costs)
    if (isError) {
      if (statusCode >= 400 && statusCode < 500) {
        multiplier *= 0.1; // Client errors - minimal cost
      } else if (statusCode >= 500) {
        multiplier *= 0.5; // Server errors - partial cost
      }
    }
    
    return baseCost * multiplier;
  }

  /// Track cost data for a service
  void _trackCost({
    required String serviceName,
    required double cost,
    required Duration duration,
    required int requestSize,
    required int responseSize,
    required int statusCode,
    required String endpoint,
    bool isError = false,
  }) {
    final tracker = _serviceTrackers.putIfAbsent(
      serviceName,
      () => ServiceCostTracker(serviceName),
    );

    tracker.recordRequest(
      cost: cost,
      duration: duration,
      requestSize: requestSize,
      responseSize: responseSize,
      statusCode: statusCode,
      endpoint: endpoint,
      isError: isError,
    );
  }

  /// Get cost statistics for all services
  Map<String, dynamic> getCostStatistics() {
    final stats = <String, dynamic>{};
    
    double totalCost = 0.0;
    int totalRequests = 0;
    
    for (final tracker in _serviceTrackers.values) {
      final serviceStats = tracker.getStatistics();
      stats[tracker.serviceName] = serviceStats;
      totalCost += serviceStats['total_cost'] as double;
      totalRequests += serviceStats['total_requests'] as int;
    }
    
    stats['summary'] = {
      'total_cost': totalCost,
      'total_requests': totalRequests,
      'average_cost_per_request': totalRequests > 0 ? totalCost / totalRequests : 0.0,
      'tracked_services': _serviceTrackers.keys.toList(),
    };
    
    return stats;
  }

  /// Reset cost tracking data
  void resetCostTracking() {
    _serviceTrackers.clear();
    
    WasteAppLogger.info('Cost tracking data reset', null, null, {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Set custom cost for a service
  void setServiceCost(String serviceName, double costPerRequest) {
    _defaultCosts[serviceName] = costPerRequest;
    
    WasteAppLogger.info('Service cost updated', null, null, {
      'service': serviceName,
      'cost_per_request': costPerRequest,
    });
  }
}

/// Tracks cost and usage data for a specific service
class ServiceCostTracker {
  ServiceCostTracker(this.serviceName);

  final String serviceName;
  final List<RequestCostData> _requests = [];
  
  /// Record a request with cost data
  void recordRequest({
    required double cost,
    required Duration duration,
    required int requestSize,
    required int responseSize,
    required int statusCode,
    required String endpoint,
    bool isError = false,
  }) {
    _requests.add(RequestCostData(
      timestamp: DateTime.now(),
      cost: cost,
      duration: duration,
      requestSize: requestSize,
      responseSize: responseSize,
      statusCode: statusCode,
      endpoint: endpoint,
      isError: isError,
    ));
    
    // Keep only last 1000 requests to prevent memory issues
    if (_requests.length > 1000) {
      _requests.removeRange(0, _requests.length - 1000);
    }
  }

  /// Get statistics for this service
  Map<String, dynamic> getStatistics() {
    if (_requests.isEmpty) {
      return {
        'service_name': serviceName,
        'total_requests': 0,
        'total_cost': 0.0,
        'average_cost': 0.0,
        'error_rate': 0.0,
        'average_duration_ms': 0,
        'total_data_bytes': 0,
      };
    }

    final totalCost = _requests.fold<double>(0.0, (sum, req) => sum + req.cost);
    final totalRequests = _requests.length;
    final errorRequests = _requests.where((req) => req.isError).length;
    final totalDuration = _requests.fold<int>(0, (sum, req) => sum + req.duration.inMilliseconds);
    final totalDataBytes = _requests.fold<int>(0, (sum, req) => sum + req.requestSize + req.responseSize);

    // Recent statistics (last hour)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentRequests = _requests.where((req) => req.timestamp.isAfter(oneHourAgo)).toList();
    
    return {
      'service_name': serviceName,
      'total_requests': totalRequests,
      'total_cost': totalCost,
      'average_cost': totalCost / totalRequests,
      'error_rate': errorRequests / totalRequests,
      'average_duration_ms': totalDuration / totalRequests,
      'total_data_bytes': totalDataBytes,
      'recent_requests_1h': recentRequests.length,
      'recent_cost_1h': recentRequests.fold<double>(0.0, (sum, req) => sum + req.cost),
      'most_expensive_endpoint': _getMostExpensiveEndpoint(),
      'slowest_endpoint': _getSlowestEndpoint(),
      'first_request': _requests.first.timestamp.toIso8601String(),
      'last_request': _requests.last.timestamp.toIso8601String(),
    };
  }

  /// Get the most expensive endpoint
  String _getMostExpensiveEndpoint() {
    if (_requests.isEmpty) return '';
    
    final endpointCosts = <String, double>{};
    for (final request in _requests) {
      endpointCosts[request.endpoint] = (endpointCosts[request.endpoint] ?? 0.0) + request.cost;
    }
    
    return endpointCosts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the slowest endpoint
  String _getSlowestEndpoint() {
    if (_requests.isEmpty) return '';
    
    final endpointDurations = <String, List<Duration>>{};
    for (final request in _requests) {
      endpointDurations.putIfAbsent(request.endpoint, () => []).add(request.duration);
    }
    
    final endpointAvgDurations = endpointDurations.map((endpoint, durations) {
      final avgDuration = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) / durations.length;
      return MapEntry(endpoint, avgDuration);
    });
    
    return endpointAvgDurations.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Data for a single request cost tracking
class RequestCostData {
  const RequestCostData({
    required this.timestamp,
    required this.cost,
    required this.duration,
    required this.requestSize,
    required this.responseSize,
    required this.statusCode,
    required this.endpoint,
    required this.isError,
  });

  final DateTime timestamp;
  final double cost;
  final Duration duration;
  final int requestSize;
  final int responseSize;
  final int statusCode;
  final String endpoint;
  final bool isError;
}