import 'package:dio/dio.dart';

/// Unified API response wrapper with enhanced metadata
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.statusMessage,
    this.headers,
    this.operationId,
    this.requestOptions,
    this.timing,
    this.cacheInfo,
  });

  /// Response data
  final T data;
  
  /// HTTP status code
  final int statusCode;
  
  /// HTTP status message
  final String? statusMessage;
  
  /// Response headers
  final Map<String, List<String>>? headers;
  
  /// Operation identifier for tracking
  final String? operationId;
  
  /// Original request options
  final RequestOptions? requestOptions;
  
  /// Request timing information
  final ApiTiming? timing;
  
  /// Cache information if applicable
  final CacheInfo? cacheInfo;

  /// Whether the request was successful
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Whether the response came from cache
  bool get isFromCache => cacheInfo?.isFromCache ?? false;

  /// Get header value by name
  String? getHeader(String name) {
    final headerList = headers?[name.toLowerCase()];
    return headerList?.isNotEmpty == true ? headerList!.first : null;
  }

  /// Get all header values by name
  List<String>? getHeaders(String name) {
    return headers?[name.toLowerCase()];
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'status_code': statusCode,
      'status_message': statusMessage,
      'headers': headers,
      'operation_id': operationId,
      'is_successful': isSuccessful,
      'is_from_cache': isFromCache,
      'timing': timing?.toMap(),
      'cache_info': cacheInfo?.toMap(),
    };
  }

  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, operationId: $operationId, isSuccessful: $isSuccessful)';
  }
}

/// Request timing information
class ApiTiming {
  const ApiTiming({
    required this.startTime,
    required this.endTime,
    this.dnsLookupTime,
    this.connectionTime,
    this.tlsHandshakeTime,
    this.requestSentTime,
    this.responseReceivedTime,
  });

  final DateTime startTime;
  final DateTime endTime;
  final Duration? dnsLookupTime;
  final Duration? connectionTime;
  final Duration? tlsHandshakeTime;
  final DateTime? requestSentTime;
  final DateTime? responseReceivedTime;

  /// Total request duration
  Duration get totalDuration => endTime.difference(startTime);

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_duration_ms': totalDuration.inMilliseconds,
      'dns_lookup_ms': dnsLookupTime?.inMilliseconds,
      'connection_ms': connectionTime?.inMilliseconds,
      'tls_handshake_ms': tlsHandshakeTime?.inMilliseconds,
      'request_sent': requestSentTime?.toIso8601String(),
      'response_received': responseReceivedTime?.toIso8601String(),
    };
  }
}

/// Cache information for responses
class CacheInfo {
  const CacheInfo({
    required this.isFromCache,
    this.cacheKey,
    this.cachedAt,
    this.expiresAt,
    this.maxAge,
    this.etag,
    this.lastModified,
  });

  final bool isFromCache;
  final String? cacheKey;
  final DateTime? cachedAt;
  final DateTime? expiresAt;
  final Duration? maxAge;
  final String? etag;
  final DateTime? lastModified;

  /// Whether the cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Time until expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    return expiresAt!.isAfter(now) ? expiresAt!.difference(now) : Duration.zero;
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'is_from_cache': isFromCache,
      'cache_key': cacheKey,
      'cached_at': cachedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'max_age_seconds': maxAge?.inSeconds,
      'etag': etag,
      'last_modified': lastModified?.toIso8601String(),
      'is_expired': isExpired,
      'time_until_expiration_ms': timeUntilExpiration?.inMilliseconds,
    };
  }
}