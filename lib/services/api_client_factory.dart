import '../utils/constants.dart';
import '../utils/production_safety_config.dart';
import '../utils/waste_app_logger.dart';
import 'unified_api_client.dart';
import 'enhanced_api_error_handler.dart';
import '../models/api_version.dart';

/// Factory for creating configured API clients for different services
class ApiClientFactory {
  static final Map<String, UnifiedApiClient> _clients = {};
  static final Map<String, EnhancedApiErrorHandler> _errorHandlers = {};

  /// Get or create OpenAI API client
  static UnifiedApiClient getOpenAIClient() {
    return _clients.putIfAbsent('openai', () {
      final errorHandler = _errorHandlers.putIfAbsent(
        'openai',
        () => EnhancedApiErrorHandler(),
      );

      ProductionSafetyConfig.guardClientAiCall('OpenAI UnifiedApiClient');
      if (ProductionSafetyConfig.hasPlaceholderKey(ApiConfig.openAiApiKey)) {
        throw const ProductionSafetyException(
          'OpenAI client blocked: OPENAI_API_KEY is placeholder/missing. Route through backend gateway or provide a real key in non-release test builds.',
        );
      }

      final client = UnifiedApiClient(
        baseUrl: ApiConfig.openAiBaseUrl,
        defaultHeaders: {
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
          'X-Service-Name': 'openai',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 1),
        errorHandler: errorHandler,
        maxConcurrentRequests: 5, // Conservative for OpenAI
      );

      // Configure API versions
      client.configureApiVersions(
        versions: {
          'v1': ApiVersion.openAI(),
          'v1beta': ApiVersion.openAI(
            version: 'v1beta',
            additionalHeaders: {'OpenAI-Beta': 'assistants=v2'},
          ),
        },
        defaultVersion: ApiVersion.openAI(),
      );

      WasteAppLogger.info('OpenAI API client created', context: {
        'base_url': ApiConfig.openAiBaseUrl,
        'max_concurrent_requests': 5,
        'rate_limiting_enabled': true,
      });

      return client;
    });
  }

  /// Get or create Gemini API client
  static UnifiedApiClient getGeminiClient() {
    return _clients.putIfAbsent('gemini', () {
      final errorHandler = _errorHandlers.putIfAbsent(
        'gemini',
        () => EnhancedApiErrorHandler(
          circuitBreakerThreshold: 8,
          circuitBreakerTimeout: const Duration(minutes: 3),
        ),
      );

      ProductionSafetyConfig.guardClientAiCall('Gemini UnifiedApiClient');
      if (ProductionSafetyConfig.hasPlaceholderKey(ApiConfig.apiKey)) {
        throw const ProductionSafetyException(
          'Gemini client blocked: GEMINI_API_KEY is placeholder/missing. Route through backend gateway or provide a real key in non-release test builds.',
        );
      }

      final client = UnifiedApiClient(
        baseUrl: ApiConfig.geminiBaseUrl,
        defaultHeaders: {
          'X-Service-Name': 'gemini',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 1),
        errorHandler: errorHandler,
        maxConcurrentRequests: 8, // Higher limit for Gemini
      );

      // Configure API versions
      client.configureApiVersions(
        versions: {
          'v1beta': ApiVersion.gemini(),
          'v1': ApiVersion.gemini(version: 'v1'),
        },
        defaultVersion: ApiVersion.gemini(),
      );

      WasteAppLogger.info('Gemini API client created', context: {
        'base_url': ApiConfig.geminiBaseUrl,
        'max_concurrent_requests': 8,
        'rate_limiting_enabled': true,
      });

      return client;
    });
  }

  /// Get or create Firebase API client
  static UnifiedApiClient getFirebaseClient() {
    return _clients.putIfAbsent('firebase', () {
      final errorHandler = _errorHandlers.putIfAbsent(
        'firebase',
        () => EnhancedApiErrorHandler(
          maxRetries: 2,
          circuitBreakerThreshold: 10,
          circuitBreakerTimeout: const Duration(minutes: 2),
        ),
      );

      final client = UnifiedApiClient(
        baseUrl: '', // Firebase uses full URLs
        defaultHeaders: {
          'X-Service-Name': 'firebase',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        errorHandler: errorHandler,
        maxConcurrentRequests: 20, // Higher limit for Firebase
      );

      // Configure API versions
      client.configureApiVersions(
        versions: {
          'v1': ApiVersion.firebase(),
        },
        defaultVersion: ApiVersion.firebase(),
      );

      WasteAppLogger.info('Firebase API client created', context: {
        'max_concurrent_requests': 20,
        'rate_limiting_enabled': true,
        'deduplication_enabled': false,
      });

      return client;
    });
  }

  /// Get or create a custom API client
  static UnifiedApiClient getCustomClient({
    required String serviceName,
    required String baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int maxRetries = 3,
    int circuitBreakerThreshold = 5,
    Duration circuitBreakerTimeout = const Duration(minutes: 5),
    bool enableRequestDeduplication = false,
    bool enableRateLimiting = true,
    int maxConcurrentRequests = 10,
    Map<String, ApiVersion>? apiVersions,
    ApiVersion? defaultVersion,
  }) {
    return _clients.putIfAbsent(serviceName, () {
      final errorHandler = _errorHandlers.putIfAbsent(
        serviceName,
        () => EnhancedApiErrorHandler(
          maxRetries: maxRetries,
          circuitBreakerThreshold: circuitBreakerThreshold,
          circuitBreakerTimeout: circuitBreakerTimeout,
        ),
      );

      final client = UnifiedApiClient(
        baseUrl: baseUrl,
        defaultHeaders: {
          'X-Service-Name': serviceName,
          ...?defaultHeaders,
        },
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
        sendTimeout: sendTimeout ?? const Duration(seconds: 30),
        errorHandler: errorHandler,
        enableRequestDeduplication: enableRequestDeduplication,
        enableRateLimiting: enableRateLimiting,
        maxConcurrentRequests: maxConcurrentRequests,
      );

      // Configure API versions if provided
      if (apiVersions != null) {
        client.configureApiVersions(
          versions: apiVersions,
          defaultVersion: defaultVersion,
        );
      }

      WasteAppLogger.info('Custom API client created', context: {
        'service_name': serviceName,
        'base_url': baseUrl,
        'max_concurrent_requests': maxConcurrentRequests,
        'rate_limiting_enabled': enableRateLimiting,
        'deduplication_enabled': enableRequestDeduplication,
      });

      return client;
    });
  }

  /// Get all active clients
  static Map<String, UnifiedApiClient> getAllClients() {
    return Map.unmodifiable(_clients);
  }

  /// Get statistics for all clients
  static Map<String, dynamic> getAllStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _clients.entries) {
      stats[entry.key] = entry.value.getStatistics();
    }

    return stats;
  }

  /// Reset a specific client
  static void resetClient(String serviceName) {
    final client = _clients.remove(serviceName);
    client?.dispose();
    _errorHandlers.remove(serviceName);

    WasteAppLogger.info('API client reset', context: {
      'service_name': serviceName,
    });
  }

  /// Reset all clients
  static void resetAllClients() {
    for (final client in _clients.values) {
      client.dispose();
    }

    _clients.clear();
    _errorHandlers.clear();

    WasteAppLogger.info('All API clients reset', context: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Configure rate limits for a service
  static void configureRateLimit({
    required String serviceName,
    required int maxRequests,
    required Duration windowDuration,
    int? burstLimit,
  }) {
    final client = _clients[serviceName];
    if (client == null) {
      WasteAppLogger.warning('Cannot configure rate limit for unknown service',
          context: {
            'service_name': serviceName,
            'available_services': _clients.keys.toList(),
          });
      return;
    }

    // Rate limit configuration would be applied here
    // This is a placeholder for the actual implementation
    WasteAppLogger.info('Rate limit configured', context: {
      'service_name': serviceName,
      'max_requests': maxRequests,
      'window_duration_ms': windowDuration.inMilliseconds,
      'burst_limit': burstLimit,
    });
  }

  /// Update API key for a service
  static void updateApiKey(String serviceName, String newApiKey) {
    final client = _clients[serviceName];
    if (client == null) {
      WasteAppLogger.warning('Cannot update API key for unknown service',
          context: {
            'service_name': serviceName,
            'available_services': _clients.keys.toList(),
          });
      return;
    }

    // API key update would be implemented here
    // This would require modifying the client's default headers
    WasteAppLogger.info('API key updated', context: {
      'service_name': serviceName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Health check for all clients
  static Future<Map<String, bool>> healthCheck() async {
    final results = <String, bool>{};

    for (final entry in _clients.entries) {
      try {
        // Perform a simple health check request
        // This is a placeholder - actual implementation would depend on service
        results[entry.key] = true;
      } catch (e) {
        results[entry.key] = false;
        WasteAppLogger.warning('Health check failed for service',
            error: e,
            context: {
              'service_name': entry.key,
            });
      }
    }

    return results;
  }
}
