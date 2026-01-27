import 'dart:async';
import 'dart:collection';
import '../utils/waste_app_logger.dart';

/// Rate limiter with sliding window and burst support
class RateLimiter {
  RateLimiter({
    required this.maxRequests,
    required this.windowDuration,
    this.burstLimit,
    this.enableLogging = true,
  }) : _requestTimes = Queue<DateTime>();

  /// Maximum requests allowed in the time window
  final int maxRequests;

  /// Time window duration
  final Duration windowDuration;

  /// Maximum burst requests (optional)
  final int? burstLimit;

  /// Whether to enable logging
  final bool enableLogging;

  /// Queue of request timestamps
  final Queue<DateTime> _requestTimes;

  /// Pending requests waiting for rate limit
  final Queue<Completer<void>> _pendingRequests = Queue<Completer<void>>();

  /// Timer for processing pending requests
  Timer? _processingTimer;

  /// Acquire permission to make a request
  Future<void> acquire() async {
    final now = DateTime.now();

    // Clean up old requests outside the window
    _cleanupOldRequests(now);

    // Check if we can make the request immediately
    if (_canMakeRequest(now)) {
      _recordRequest(now);
      return;
    }

    // Need to wait - add to queue
    final completer = Completer<void>();
    _pendingRequests.add(completer);

    if (enableLogging) {
      WasteAppLogger.info('Rate limit reached, error: queuing request');
    }

    // Start processing timer if not already running
    _startProcessingTimer();

    return completer.future;
  }

  /// Check if a request can be made immediately
  bool _canMakeRequest(DateTime now) {
    // Check sliding window limit
    if (_requestTimes.length >= maxRequests) {
      return false;
    }

    // Check burst limit if specified
    if (burstLimit != null) {
      final recentRequests =
          _countRecentRequests(now, const Duration(seconds: 1));
      if (recentRequests >= burstLimit!) {
        return false;
      }
    }

    return true;
  }

  /// Record a request timestamp
  void _recordRequest(DateTime timestamp) {
    _requestTimes.add(timestamp);

    if (enableLogging) {
      WasteAppLogger.fine('Request recorded', context: {
        'timestamp': timestamp.toIso8601String(),
        'current_requests': _requestTimes.length,
        'max_requests': maxRequests,
      });
    }
  }

  /// Clean up request timestamps outside the window
  void _cleanupOldRequests(DateTime now) {
    final cutoff = now.subtract(windowDuration);

    while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(cutoff)) {
      _requestTimes.removeFirst();
    }
  }

  /// Count recent requests within a specific duration
  int _countRecentRequests(DateTime now, Duration duration) {
    final cutoff = now.subtract(duration);
    return _requestTimes.where((time) => time.isAfter(cutoff)).length;
  }

  /// Start the timer to process pending requests
  void _startProcessingTimer() {
    if (_processingTimer?.isActive == true) return;

    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processPendingRequests();
    });
  }

  /// Process pending requests in the queue
  void _processPendingRequests() {
    if (_pendingRequests.isEmpty) {
      _processingTimer?.cancel();
      return;
    }

    final now = DateTime.now();
    _cleanupOldRequests(now);

    while (_pendingRequests.isNotEmpty && _canMakeRequest(now)) {
      final completer = _pendingRequests.removeFirst();
      _recordRequest(now);
      completer.complete();

      if (enableLogging) {
        WasteAppLogger.fine('Processed queued request', context: {
          'remaining_queue': _pendingRequests.length,
          'current_requests': _requestTimes.length,
        });
      }
    }

    // Stop timer if queue is empty
    if (_pendingRequests.isEmpty) {
      _processingTimer?.cancel();
    }
  }

  /// Get current rate limiter statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    _cleanupOldRequests(now);

    return {
      'max_requests': maxRequests,
      'window_duration_ms': windowDuration.inMilliseconds,
      'burst_limit': burstLimit,
      'current_requests': _requestTimes.length,
      'available_requests': maxRequests - _requestTimes.length,
      'pending_requests': _pendingRequests.length,
      'utilization_percent': (_requestTimes.length / maxRequests * 100).round(),
      'recent_requests_1s':
          _countRecentRequests(now, const Duration(seconds: 1)),
      'recent_requests_10s':
          _countRecentRequests(now, const Duration(seconds: 10)),
      'oldest_request': _requestTimes.isNotEmpty
          ? _requestTimes.first.toIso8601String()
          : null,
      'newest_request': _requestTimes.isNotEmpty
          ? _requestTimes.last.toIso8601String()
          : null,
    };
  }

  /// Get time until next request can be made
  Duration? getTimeUntilNextRequest() {
    if (_canMakeRequest(DateTime.now())) {
      return Duration.zero;
    }

    if (_requestTimes.isEmpty) {
      return Duration.zero;
    }

    final oldestRequest = _requestTimes.first;
    final nextAvailableTime = oldestRequest.add(windowDuration);
    final now = DateTime.now();

    return nextAvailableTime.isAfter(now)
        ? nextAvailableTime.difference(now)
        : Duration.zero;
  }

  /// Reset the rate limiter
  void reset() {
    _requestTimes.clear();

    // Complete all pending requests
    while (_pendingRequests.isNotEmpty) {
      final completer = _pendingRequests.removeFirst();
      completer.complete();
    }

    _processingTimer?.cancel();

    if (enableLogging) {
      WasteAppLogger.info('Rate limiter reset', context: {
        'max_requests': maxRequests,
        'window_duration_ms': windowDuration.inMilliseconds,
      });
    }
  }

  /// Dispose the rate limiter
  void dispose() {
    _processingTimer?.cancel();

    // Complete all pending requests with error
    while (_pendingRequests.isNotEmpty) {
      final completer = _pendingRequests.removeFirst();
      completer.completeError(StateError('Rate limiter disposed'));
    }

    _requestTimes.clear();
  }
}

/// Cost-aware rate limiter that adjusts limits based on usage costs
class CostAwareRateLimiter extends RateLimiter {
  CostAwareRateLimiter({
    required super.maxRequests,
    required super.windowDuration,
    super.burstLimit,
    super.enableLogging,
    required this.costPerRequest,
    required this.maxCostPerWindow,
    this.costMultiplier = 1.0,
  });

  /// Cost per request (e.g., in dollars)
  final double costPerRequest;

  /// Maximum cost allowed per window
  final double maxCostPerWindow;

  /// Cost multiplier for dynamic pricing
  double costMultiplier;

  /// Current cost in the window
  double get currentCost =>
      _requestTimes.length * costPerRequest * costMultiplier;

  /// Available cost remaining
  double get availableCost => maxCostPerWindow - currentCost;

  /// Check if request can be made considering cost
  @override
  bool _canMakeRequest(DateTime now) {
    // Check parent rate limits first
    if (!super._canMakeRequest(now)) {
      return false;
    }

    // Check cost limit
    final requestCost = costPerRequest * costMultiplier;
    if (currentCost + requestCost > maxCostPerWindow) {
      if (enableLogging) {
        WasteAppLogger.warning('Cost limit reached', context: {
          'current_cost': currentCost,
          'request_cost': requestCost,
          'max_cost': maxCostPerWindow,
          'cost_multiplier': costMultiplier,
        });
      }
      return false;
    }

    return true;
  }

  /// Update cost multiplier for dynamic pricing
  void updateCostMultiplier(double newMultiplier) {
    costMultiplier = newMultiplier;

    if (enableLogging) {
      WasteAppLogger.info('Cost multiplier updated', context: {
        'old_multiplier': costMultiplier,
        'new_multiplier': newMultiplier,
        'current_cost': currentCost,
        'max_cost': maxCostPerWindow,
      });
    }
  }

  /// Get cost-aware statistics
  @override
  Map<String, dynamic> getStatistics() {
    final baseStats = super.getStatistics();

    return {
      ...baseStats,
      'cost_per_request': costPerRequest,
      'cost_multiplier': costMultiplier,
      'current_cost': currentCost,
      'max_cost_per_window': maxCostPerWindow,
      'available_cost': availableCost,
      'cost_utilization_percent':
          (currentCost / maxCostPerWindow * 100).round(),
    };
  }
}
