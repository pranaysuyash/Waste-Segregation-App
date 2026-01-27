/// API version configuration for backward compatibility and versioning support
class ApiVersion {
  const ApiVersion({
    required this.version,
    required this.serviceName,
    this.pathPrefix = '',
    this.headerName = '',
    this.headers = const {},
    this.isDeprecated = false,
    this.deprecationDate,
    this.migrationGuide,
  });

  /// Create default version configuration
  factory ApiVersion.defaultVersion() {
    return const ApiVersion(
      version: 'v1',
      serviceName: 'default',
    );
  }

  /// Create OpenAI API version
  factory ApiVersion.openAI({
    String version = 'v1',
    Map<String, String>? additionalHeaders,
  }) {
    return ApiVersion(
      version: version,
      serviceName: 'openai',
      pathPrefix: '/v1',
      headers: {
        'OpenAI-Beta': 'assistants=v2',
        ...?additionalHeaders,
      },
    );
  }

  /// Create Gemini API version
  factory ApiVersion.gemini({
    String version = 'v1beta',
    Map<String, String>? additionalHeaders,
  }) {
    return ApiVersion(
      version: version,
      serviceName: 'gemini',
      pathPrefix: '/v1beta',
      headers: {
        ...?additionalHeaders,
      },
    );
  }

  /// Create Firebase API version
  factory ApiVersion.firebase({
    String version = 'v1',
    Map<String, String>? additionalHeaders,
  }) {
    return ApiVersion(
      version: version,
      serviceName: 'firebase',
      headers: {
        ...?additionalHeaders,
      },
    );
  }

  /// Create from map
  factory ApiVersion.fromMap(Map<String, dynamic> map) {
    return ApiVersion(
      version: map['version'] as String,
      serviceName: map['service_name'] as String,
      pathPrefix: map['path_prefix'] as String? ?? '',
      headerName: map['header_name'] as String? ?? '',
      headers: Map<String, String>.from(map['headers'] as Map? ?? {}),
      isDeprecated: map['is_deprecated'] as bool? ?? false,
      deprecationDate: map['deprecation_date'] != null
          ? DateTime.parse(map['deprecation_date'] as String)
          : null,
      migrationGuide: map['migration_guide'] as String?,
    );
  }

  /// Version identifier (e.g., 'v1', '2.0', '2024-01-01')
  final String version;

  /// Service name for rate limiting and circuit breaker
  final String serviceName;

  /// Path prefix to add to endpoints (e.g., '/v1', '/api/v2')
  final String pathPrefix;

  /// Header name for version specification (e.g., 'API-Version')
  final String headerName;

  /// Additional headers required for this version
  final Map<String, String> headers;

  /// Whether this version is deprecated
  final bool isDeprecated;

  /// When this version will be removed
  final DateTime? deprecationDate;

  /// URL or text with migration instructions
  final String? migrationGuide;

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'service_name': serviceName,
      'path_prefix': pathPrefix,
      'header_name': headerName,
      'headers': headers,
      'is_deprecated': isDeprecated,
      'deprecation_date': deprecationDate?.toIso8601String(),
      'migration_guide': migrationGuide,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiVersion &&
        other.version == version &&
        other.serviceName == serviceName &&
        other.pathPrefix == pathPrefix &&
        other.headerName == headerName;
  }

  @override
  int get hashCode {
    return Object.hash(version, serviceName, pathPrefix, headerName);
  }

  @override
  String toString() {
    return 'ApiVersion(version: $version, service: $serviceName, prefix: $pathPrefix)';
  }
}
