import '../models/gamification.dart';
import '../utils/waste_app_logger.dart';

/// Validates analytics events against predefined schemas to ensure data quality
class AnalyticsSchemaValidator {
  // Required fields for all events
  static const List<String> _requiredGlobalFields = [
    'id',
    'userId',
    'eventType',
    'eventName',
    'timestamp',
    'sessionId',
  ];

  // Event-specific required fields
  static const Map<String, List<String>> _eventSpecificRequiredFields = {
    // Session events
    AnalyticsEventNames.sessionStart: ['device_type', 'app_version', 'platform'],
    AnalyticsEventNames.sessionEnd: ['session_duration_ms', 'events_in_session'],
    AnalyticsEventNames.pageView: ['screen_name', 'previous_screen'],

    // Classification events
    AnalyticsEventNames.fileClassified: ['model_version', 'processing_duration_ms', 'confidence_score', 'category'],
    AnalyticsEventNames.classificationStarted: ['input_method', 'source'],
    AnalyticsEventNames.classificationRetried: ['original_confidence', 'retry_reason', 'attempt_number'],

    // Interaction events
    AnalyticsEventNames.click: ['element_id', 'screen_name', 'element_type'],
    AnalyticsEventNames.rageClick: ['element_id', 'tap_count', 'screen_name'],
    AnalyticsEventNames.scrollDepth: ['depth_percent', 'screen_name'],

    // Performance events
    AnalyticsEventNames.clientError: ['error_message', 'screen_name'],
    AnalyticsEventNames.apiError: ['endpoint', 'status_code', 'latency_ms'],
    AnalyticsEventNames.slowResource: ['operation_name', 'duration_ms', 'resource_type'],

    // Gamification events
    AnalyticsEventNames.pointsEarned: ['points_amount', 'source_action', 'total_points'],
    AnalyticsEventNames.achievementUnlocked: ['achievement_id', 'achievement_type', 'points_awarded'],
    AnalyticsEventNames.levelUp: ['new_level', 'previous_level', 'points_required'],
  };

  // Field type validation rules
  static const Map<String, String> _fieldTypes = {
    'id': 'string',
    'userId': 'string',
    'sessionId': 'string',
    'eventType': 'string',
    'eventName': 'string',
    'timestamp': 'string',
    'screen_name': 'string',
    'previous_screen': 'string',
    'element_id': 'string',
    'element_type': 'string',
    'device_type': 'string',
    'app_version': 'string',
    'platform': 'string',
    'model_version': 'string',
    'category': 'string',
    'input_method': 'string',
    'source': 'string',
    'retry_reason': 'string',
    'error_message': 'string',
    'endpoint': 'string',
    'operation_name': 'string',
    'resource_type': 'string',
    'achievement_id': 'string',
    'achievement_type': 'string',
    'source_action': 'string',
    'session_duration_ms': 'int',
    'events_in_session': 'int',
    'processing_duration_ms': 'int',
    'confidence_score': 'double',
    'tap_count': 'int',
    'depth_percent': 'int',
    'status_code': 'int',
    'latency_ms': 'int',
    'duration_ms': 'int',
    'attempt_number': 'int',
    'points_amount': 'int',
    'points_awarded': 'int',
    'total_points': 'int',
    'new_level': 'int',
    'previous_level': 'int',
    'points_required': 'int',
    'original_confidence': 'double',
  };

  // Valid values for specific fields
  static const Map<String, List<String>> _validValues = {
    'platform': ['iOS', 'Android', 'Web'],
    'input_method': ['camera', 'gallery', 'file_upload'],
    'source': ['manual', 'instant', 'batch'],
    'element_type': ['button', 'link', 'icon', 'card', 'tab'],
    'retry_reason': ['low_confidence', 'user_disagreement', 'technical_error'],
    'resource_type': ['api_call', 'image_processing', 'database_query', 'file_operation'],
    'achievement_type': ['milestone', 'streak', 'special', 'daily', 'weekly'],
  };

  // Numeric field ranges
  static const Map<String, Map<String, num>> _numericRanges = {
    'confidence_score': {'min': 0.0, 'max': 1.0},
    'depth_percent': {'min': 0, 'max': 100},
    'tap_count': {'min': 3, 'max': 20}, // rage click definition
    'status_code': {'min': 100, 'max': 599},
    'session_duration_ms': {'min': 0, 'max': 86400000}, // max 24 hours
    'processing_duration_ms': {'min': 0, 'max': 60000}, // max 60 seconds
    'latency_ms': {'min': 0, 'max': 30000}, // max 30 seconds
    'duration_ms': {'min': 0, 'max': 300000}, // max 5 minutes
    'attempt_number': {'min': 1, 'max': 10},
    'points_amount': {'min': 0, 'max': 1000},
    'points_awarded': {'min': 0, 'max': 1000},
    'total_points': {'min': 0, 'max': 1000000},
    'new_level': {'min': 1, 'max': 100},
    'previous_level': {'min': 0, 'max': 99},
    'points_required': {'min': 0, 'max': 10000},
  };

  /// Validates an analytics event against the schema
  Future<ValidationResult> validateEvent(AnalyticsEvent event) async {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // Convert event to map for validation
      final eventData = event.toJson();

      // Validate required global fields
      for (final field in _requiredGlobalFields) {
        if (!eventData.containsKey(field) || eventData[field] == null) {
          errors.add('Missing required field: $field');
        }
      }

      // Validate event-specific required fields
      final eventName = event.eventName;
      final requiredFields = _eventSpecificRequiredFields[eventName];
      if (requiredFields != null) {
        for (final field in requiredFields) {
          if (!event.parameters.containsKey(field) || event.parameters[field] == null) {
            errors.add('Missing required parameter for $eventName: $field');
          }
        }
      }

      // Validate field types
      _validateFieldTypes(eventData, event.parameters, errors);

      // Validate field values
      _validateFieldValues(event.parameters, errors, warnings);

      // Validate numeric ranges
      _validateNumericRanges(event.parameters, errors, warnings);

      // Validate event name format
      if (!_isValidEventName(eventName)) {
        errors.add('Invalid event name format: $eventName (should be snake_case)');
      }

      // Validate timestamp format
      _validateTimestamp(event.timestamp, errors);

      // Check for potential PII in parameters
      _checkForPII(event.parameters, warnings);

      final isValid = errors.isEmpty;

      if (!isValid) {
        WasteAppLogger.warning('Event validation failed', null, null,
            {'event_name': eventName, 'errors': errors, 'warnings': warnings, 'service': 'AnalyticsSchemaValidator'});
      } else if (warnings.isNotEmpty) {
        WasteAppLogger.info('Event validation passed with warnings', null, null,
            {'event_name': eventName, 'warnings': warnings, 'service': 'AnalyticsSchemaValidator'});
      }

      return ValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      WasteAppLogger.severe('Error during event validation', e, stackTrace,
          {'event_name': event.eventName, 'service': 'AnalyticsSchemaValidator'});

      return ValidationResult(
        isValid: false,
        errors: ['Validation error: ${e.toString()}'],
        warnings: [],
      );
    }
  }

  /// Validates field types
  void _validateFieldTypes(Map<String, dynamic> eventData, Map<String, dynamic> parameters, List<String> errors) {
    // Validate event data types
    for (final entry in eventData.entries) {
      final expectedType = _fieldTypes[entry.key];
      if (expectedType != null && !_isCorrectType(entry.value, expectedType)) {
        errors.add('Field ${entry.key} should be $expectedType but got ${entry.value.runtimeType}');
      }
    }

    // Validate parameter types
    for (final entry in parameters.entries) {
      final expectedType = _fieldTypes[entry.key];
      if (expectedType != null && !_isCorrectType(entry.value, expectedType)) {
        errors.add('Parameter ${entry.key} should be $expectedType but got ${entry.value.runtimeType}');
      }
    }
  }

  /// Validates field values against allowed values
  void _validateFieldValues(Map<String, dynamic> parameters, List<String> errors, List<String> warnings) {
    for (final entry in parameters.entries) {
      final validValues = _validValues[entry.key];
      if (validValues != null && !validValues.contains(entry.value)) {
        errors.add('Invalid value for ${entry.key}: ${entry.value}. Valid values: ${validValues.join(', ')}');
      }
    }
  }

  /// Validates numeric ranges
  void _validateNumericRanges(Map<String, dynamic> parameters, List<String> errors, List<String> warnings) {
    for (final entry in parameters.entries) {
      final range = _numericRanges[entry.key];
      if (range != null && entry.value is num) {
        final value = entry.value as num;
        final min = range['min']!;
        final max = range['max']!;

        if (value < min || value > max) {
          errors.add('Value for ${entry.key} ($value) is outside valid range [$min, $max]');
        }

        // Add warnings for suspicious values
        if (entry.key == 'confidence_score' && value < 0.5) {
          warnings.add('Low confidence score detected: $value');
        }
        if (entry.key == 'processing_duration_ms' && value > 10000) {
          warnings.add('High processing duration detected: ${value}ms');
        }
      }
    }
  }

  /// Checks if a value matches the expected type
  bool _isCorrectType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'string':
        return value is String;
      case 'int':
        return value is int;
      case 'double':
        return value is double || value is int; // Allow int for double fields
      case 'bool':
        return value is bool;
      case 'list':
        return value is List;
      case 'map':
        return value is Map;
      default:
        return true; // Unknown type, allow it
    }
  }

  /// Validates event name format (snake_case)
  bool _isValidEventName(String eventName) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(eventName);
  }

  /// Validates timestamp format
  void _validateTimestamp(DateTime timestamp, List<String> errors) {
    final now = DateTime.now();
    final diff = now.difference(timestamp).abs();

    // Timestamp shouldn't be more than 1 hour in the future or past
    if (diff.inHours > 1) {
      errors.add('Timestamp is too far from current time: ${timestamp.toIso8601String()}');
    }
  }

  /// Checks for potential PII in parameters
  void _checkForPII(Map<String, dynamic> parameters, List<String> warnings) {
    final piiPatterns = {
      'email': RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      'phone': RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      'ip': RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
    };

    for (final entry in parameters.entries) {
      if (entry.value is String) {
        final value = entry.value as String;
        for (final piiEntry in piiPatterns.entries) {
          if (piiEntry.value.hasMatch(value)) {
            warnings.add('Potential ${piiEntry.key} detected in parameter ${entry.key}');
          }
        }
      }
    }
  }

  /// Validates multiple events in batch
  Future<BatchValidationResult> validateEvents(List<AnalyticsEvent> events) async {
    final results = <ValidationResult>[];
    var validCount = 0;
    var errorCount = 0;
    var warningCount = 0;

    for (final event in events) {
      final result = await validateEvent(event);
      results.add(result);

      if (result.isValid) {
        validCount++;
      } else {
        errorCount++;
      }

      if (result.warnings.isNotEmpty) {
        warningCount++;
      }
    }

    return BatchValidationResult(
      results: results,
      totalEvents: events.length,
      validEvents: validCount,
      invalidEvents: errorCount,
      eventsWithWarnings: warningCount,
    );
  }
}

/// Result of event validation
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
      };
}

/// Result of batch validation
class BatchValidationResult {
  const BatchValidationResult({
    required this.results,
    required this.totalEvents,
    required this.validEvents,
    required this.invalidEvents,
    required this.eventsWithWarnings,
  });

  final List<ValidationResult> results;
  final int totalEvents;
  final int validEvents;
  final int invalidEvents;
  final int eventsWithWarnings;

  double get validationRate => totalEvents > 0 ? validEvents / totalEvents : 0.0;

  Map<String, dynamic> toJson() => {
        'totalEvents': totalEvents,
        'validEvents': validEvents,
        'invalidEvents': invalidEvents,
        'eventsWithWarnings': eventsWithWarnings,
        'validationRate': validationRate,
      };
}
