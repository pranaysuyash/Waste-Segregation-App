import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/waste_app_logger.dart';
import '../utils/error_handler.dart';

/// Service that provides resilient network operations with retry logic and fallback mechanisms
class ResilientNetworkService {
  factory ResilientNetworkService() => _instance;
  ResilientNetworkService._internal();
  static final ResilientNetworkService _instance =
      ResilientNetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  final List<Function()> _pendingOperations = [];
  final Map<String, dynamic> _cache = {};

  /// Initialize the service
  Future<void> initialize() async {
    // Check initial connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    _isOnline = !connectivityResults.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);

        if (!wasOnline && _isOnline) {
          _processPendingOperations();
        }

        WasteAppLogger.info(
            'Connectivity changed: ${results.map((r) => r.name).join(', ')}, error: online: $_isOnline');
      },
    );
  }

  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Check if device is currently online
  bool get isOnline => _isOnline;

  /// Execute a network operation with retry logic and fallback
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    String? operationName,
    T? fallbackValue,
    bool useCache = false,
    String? cacheKey,
  }) async {
    if (!_isOnline) {
      if (useCache && cacheKey != null && _cache.containsKey(cacheKey)) {
        WasteAppLogger.info('Using cached value for $operationName (offline)');
        return _cache[cacheKey] as T?;
      }

      if (fallbackValue != null) {
        WasteAppLogger.info(
            'Using fallback value for $operationName (offline)');
        return fallbackValue;
      }

      throw NetworkException('Device is offline and no fallback available');
    }

    return ErrorHandler.retryOperation<T>(
      operation,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: backoffMultiplier,
      context: operationName ?? 'network operation',
    ).catchError((error) {
      // If operation fails, try fallback options
      if (useCache && cacheKey != null && _cache.containsKey(cacheKey)) {
        WasteAppLogger.info(
            'Using cached value for $operationName (after failure)');
        return _cache[cacheKey] as T?;
      }

      if (fallbackValue != null) {
        WasteAppLogger.info(
            'Using fallback value for $operationName (after failure)');
        return fallbackValue;
      }

      throw error;
    });
  }

  /// Cache a value for offline use
  void cacheValue(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Get cached value
  T? getCachedValue<T>(String key) {
    return _cache[key] as T?;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Queue an operation to be executed when online
  void queueOperation(Function() operation) {
    if (_isOnline) {
      operation();
    } else {
      _pendingOperations.add(operation);
      WasteAppLogger.info('Queued operation for when online');
    }
  }

  /// Process all pending operations
  void _processPendingOperations() {
    if (_pendingOperations.isEmpty) return;

    WasteAppLogger.info(
        'Processing ${_pendingOperations.length} pending operations');

    final operations = List.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        operation();
      } catch (e) {
        WasteAppLogger.severe('Error processing pending operation', error: e);
      }
    }
  }

  /// Execute operation with circuit breaker pattern
  Future<T?> executeWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    String? operationName,
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 30),
    Duration resetTimeout = const Duration(minutes: 1),
  }) async {
    final circuitBreaker = _getCircuitBreaker(operationName ?? 'default');

    if (circuitBreaker.state == CircuitBreakerState.open) {
      if (DateTime.now().difference(circuitBreaker.lastFailureTime!) >
          resetTimeout) {
        circuitBreaker.state = CircuitBreakerState.halfOpen;
        WasteAppLogger.info(
            'Circuit breaker for $operationName moved to half-open');
      } else {
        throw CircuitBreakerOpenException(
            'Circuit breaker is open for $operationName');
      }
    }

    try {
      final result = await operation().timeout(timeout);

      if (circuitBreaker.state == CircuitBreakerState.halfOpen) {
        circuitBreaker.state = CircuitBreakerState.closed;
        circuitBreaker.failureCount = 0;
        WasteAppLogger.info('Circuit breaker for $operationName closed');
      }

      return result;
    } catch (e) {
      circuitBreaker.failureCount++;
      circuitBreaker.lastFailureTime = DateTime.now();

      if (circuitBreaker.failureCount >= failureThreshold) {
        circuitBreaker.state = CircuitBreakerState.open;
        WasteAppLogger.warning(
            'Circuit breaker for $operationName opened after $failureThreshold failures');
      }

      rethrow;
    }
  }

  final Map<String, CircuitBreaker> _circuitBreakers = {};

  CircuitBreaker _getCircuitBreaker(String name) {
    return _circuitBreakers.putIfAbsent(name, () => CircuitBreaker());
  }

  /// Execute operation with timeout and fallback
  Future<T?> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    T? fallbackValue,
    String? operationName,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      WasteAppLogger.warning(
          'Operation $operationName timed out after ${timeout.inSeconds}s');
      if (fallbackValue != null) {
        return fallbackValue;
      }
      throw NetworkTimeoutException('Operation timed out');
    }
  }

  /// Check if a specific host is reachable
  Future<bool> isHostReachable(String host,
      {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get network quality indicator
  Future<NetworkQuality> getNetworkQuality() async {
    if (!_isOnline) return NetworkQuality.offline;

    try {
      final stopwatch = Stopwatch()..start();
      final isReachable = await isHostReachable('google.com',
          timeout: const Duration(seconds: 3));
      stopwatch.stop();

      if (!isReachable) return NetworkQuality.poor;

      final latency = stopwatch.elapsedMilliseconds;
      if (latency < 100) return NetworkQuality.excellent;
      if (latency < 300) return NetworkQuality.good;
      if (latency < 1000) return NetworkQuality.fair;
      return NetworkQuality.poor;
    } catch (e) {
      return NetworkQuality.poor;
    }
  }
}

/// Circuit breaker for network operations
class CircuitBreaker {
  CircuitBreakerState state = CircuitBreakerState.closed;
  int failureCount = 0;
  DateTime? lastFailureTime;
}

enum CircuitBreakerState { closed, open, halfOpen }

enum NetworkQuality { offline, poor, fair, good, excellent }

/// Custom exceptions for network operations
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CircuitBreakerOpenException implements Exception {
  CircuitBreakerOpenException(this.message);
  final String message;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

class NetworkTimeoutException implements Exception {
  NetworkTimeoutException(this.message);
  final String message;

  @override
  String toString() => 'NetworkTimeoutException: $message';
}
