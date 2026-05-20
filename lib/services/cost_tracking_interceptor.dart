import 'package:dio/dio.dart';
import '../utils/waste_app_logger.dart';

/// Interceptor for tracking API costs and usage patterns
///
/// IMPORTANT: This interceptor provides rough telemetry estimates for usage
/// analysis. It is not a billing-grade source of truth.
class CostTrackingInterceptor extends Interceptor {
  CostTrackingInterceptor({
    this.enableDetailedLogging = true,
  });

  final bool enableDetailedLogging;
  static const int _maxServiceTrackers = 32;
  static const String _unknownService = 'unknown';
  static const String _customService = 'custom';
  static const Set<String> _sensitiveHeaders = {
    'authorization',
    'x-goog-api-key',
    'api-key',
    'x-api-key',
    'cookie',
    'set-cookie',
  };

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
      WasteAppLogger.fine('Cost tracking started', context: {
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
    final costData =
        response.requestOptions.extra['cost_tracking'] as Map<String, dynamic>?;

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
        endpoint: _sanitizeEndpoint(response.requestOptions),
      );

      if (enableDetailedLogging) {
        WasteAppLogger.info('Cost tracking completed', context: {
          'service': serviceName,
          'rough_telemetry_cost_estimate': estimatedCost,
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
    final costData =
        err.requestOptions.extra['cost_tracking'] as Map<String, dynamic>?;

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
        endpoint: _sanitizeEndpoint(err.requestOptions),
        isError: true,
      );

      if (enableDetailedLogging) {
        WasteAppLogger.warning('Cost tracking for failed request',
            error: err,
            context: {
              'service': serviceName,
              'rough_telemetry_cost_estimate': estimatedCost,
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
    if (serviceHeader != null) {
      return _normalizeServiceName(serviceHeader, source: 'header');
    }

    // Extract from URL
    // NOTE: firebase/firestore must be checked before googleapis.com
    // because firestore.googleapis.com also contains 'googleapis.com'
    final uri = options.uri;
    final host = uri.host.toLowerCase();
    if (host.contains('openai.com')) return 'openai';
    if (host.contains('firestore.googleapis.com') ||
        host.contains('firebase')) {
      return 'firebase';
    }
    if (host.contains('generativelanguage.googleapis.com')) return 'gemini';
    if (host.contains('storage.googleapis.com')) return 'google_storage';
    if (host.contains('googleapis.com')) return 'google';

    // Check path for service indicators
    if (options.path.contains('/openai/')) return 'openai';
    if (options.path.contains('/gemini/')) return 'gemini';
    if (options.path.contains('/firebase/')) return 'firebase';

    return _unknownService;
  }

  /// Calculate request size in bytes
  int _calculateRequestSize(RequestOptions options) {
    var size = 0;

    // Headers size
    options.headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      final valueLength =
          _sensitiveHeaders.contains(lowerKey) ? 8 : value.toString().length;
      size += key.length + valueLength + 4; // +4 for ": " and "\r\n"
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
    var size = 0;

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
    var multiplier = 1.0;

    // Size-based multiplier (larger requests/responses cost more)
    final totalSize = requestSize + responseSize;
    if (totalSize > 100000) {
      // 100KB
      multiplier *= 1.5;
    } else if (totalSize > 10000) {
      // 10KB
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

  String _sanitizeEndpoint(RequestOptions options) {
    var path = options.path;
    if (path.isEmpty) path = options.uri.path;
    path = path.split('?').first;
    final segments = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
      final isNumeric = RegExp(r'^\d+$').hasMatch(segment);
      final isUuid = RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$')
          .hasMatch(segment);
      final isLongOpaque = segment.length > 20 &&
          RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(segment);
      if (isNumeric || isUuid || isLongOpaque) return ':id';
      return segment;
    }).toList();
    return '/${segments.join('/')}';
  }

  String _normalizeServiceName(String raw, {required String source}) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return _unknownService;
    if (value == 'openai' ||
        value == 'gemini' ||
        value == 'firebase' ||
        value == 'google' ||
        value == 'google_storage' ||
        value == _customService) {
      return value;
    }
    if (source == 'header') {
      return _customService;
    }
    return _unknownService;
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
    final normalizedServiceName = _normalizeServiceName(
      serviceName,
      source: 'runtime',
    );
    if (!_serviceTrackers.containsKey(normalizedServiceName) &&
        _serviceTrackers.length >= _maxServiceTrackers) {
      final oldestKey = _serviceTrackers.entries
          .reduce((a, b) =>
              a.value.lastRequestAt.isBefore(b.value.lastRequestAt) ? a : b)
          .key;
      _serviceTrackers.remove(oldestKey);
    }
    final tracker = _serviceTrackers.putIfAbsent(
      normalizedServiceName,
      () => ServiceCostTracker(normalizedServiceName),
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

    var totalCost = 0.0;
    var totalRequests = 0;

    for (final tracker in _serviceTrackers.values) {
      final serviceStats = tracker.getStatistics();
      stats[tracker.serviceName] = serviceStats;
      totalCost += serviceStats['total_cost'] as double;
      totalRequests += serviceStats['total_requests'] as int;
    }

    stats['summary'] = {
      'total_cost': totalCost,
      'total_requests': totalRequests,
      'average_cost_per_request':
          totalRequests > 0 ? totalCost / totalRequests : 0.0,
      'tracked_services': _serviceTrackers.keys.toList(),
    };

    return stats;
  }

  /// Reset cost tracking data
  void resetCostTracking() {
    _serviceTrackers.clear();

    WasteAppLogger.info('Cost tracking data reset', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Set custom cost for a service
  void setServiceCost(String serviceName, double costPerRequest) {
    if (!costPerRequest.isFinite || costPerRequest < 0) {
      throw ArgumentError(
          'costPerRequest must be finite and non-negative.');
    }
    final normalizedServiceName =
        _normalizeServiceName(serviceName, source: 'runtime');
    _defaultCosts[normalizedServiceName] = costPerRequest;

    WasteAppLogger.info('Service cost updated', context: {
      'service': normalizedServiceName,
      'cost_per_request': costPerRequest,
    });
  }
}

/// Tracks cost and usage data for a specific service
class ServiceCostTracker {
  ServiceCostTracker(this.serviceName);

  final String serviceName;
  final List<RequestCostData> _requests = [];
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime get lastRequestAt => _lastRequestAt;

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
    _lastRequestAt = DateTime.now();
    _requests.add(RequestCostData(
      timestamp: _lastRequestAt,
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
        'average_duration_ms': 0.0,
        'total_data_bytes': 0,
      };
    }

    final totalCost = _requests.fold<double>(0.0, (sum, req) => sum + req.cost);
    final totalRequests = _requests.length;
    final errorRequests = _requests.where((req) => req.isError).length;
    final totalDuration =
        _requests.fold<int>(0, (sum, req) => sum + req.duration.inMilliseconds);
    final totalDataBytes = _requests.fold<int>(
        0, (sum, req) => sum + req.requestSize + req.responseSize);

    // Recent statistics (last hour)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentRequests =
        _requests.where((req) => req.timestamp.isAfter(oneHourAgo)).toList();

    return {
      'service_name': serviceName,
      'total_requests': totalRequests,
      'total_cost': totalCost,
      'average_cost': totalCost / totalRequests,
      'error_rate': errorRequests / totalRequests,
      'average_duration_ms': totalDuration / totalRequests,
      'total_data_bytes': totalDataBytes,
      'recent_requests_1h': recentRequests.length,
      'recent_cost_1h':
          recentRequests.fold<double>(0.0, (sum, req) => sum + req.cost),
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
      endpointCosts[request.endpoint] =
          (endpointCosts[request.endpoint] ?? 0.0) + request.cost;
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
      endpointDurations
          .putIfAbsent(request.endpoint, () => [])
          .add(request.duration);
    }

    final endpointAvgDurations = endpointDurations.map((endpoint, durations) {
      final avgDuration =
          durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) /
              durations.length;
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
