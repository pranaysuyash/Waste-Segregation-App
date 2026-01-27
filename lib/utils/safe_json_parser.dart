/// Utility class for safe JSON parsing with proper null safety and type validation
class SafeJsonParser {
  /// Safely extracts a String from JSON with validation
  static String getString(Map<String, dynamic> json, String key,
      {String? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required string field "$key" is null');
    }
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    throw ArgumentError(
        'Field "$key" is not a valid string type, got ${value.runtimeType}');
  }

  /// Safely extracts an optional String from JSON
  static String? getOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts an int from JSON with validation
  static int getInt(Map<String, dynamic> json, String key,
      {int? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required int field "$key" is null');
    }
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError(
        'Field "$key" is not a valid int type, got ${value.runtimeType}');
  }

  /// Safely extracts an optional int from JSON
  static int? getOptionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts a double from JSON with validation
  static double getDouble(Map<String, dynamic> json, String key,
      {double? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required double field "$key" is null');
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError(
        'Field "$key" is not a valid double type, got ${value.runtimeType}');
  }

  /// Safely extracts an optional double from JSON
  static double? getOptionalDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts a bool from JSON with validation
  static bool getBool(Map<String, dynamic> json, String key,
      {bool? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required bool field "$key" is null');
    }
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) return value != 0;
    throw ArgumentError(
        'Field "$key" is not a valid bool type, got ${value.runtimeType}');
  }

  /// Safely extracts an optional bool from JSON
  static bool? getOptionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) return value != 0;
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts a DateTime from JSON with validation
  static DateTime getDateTime(Map<String, dynamic> json, String key,
      {DateTime? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required DateTime field "$key" is null');
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError(
        'Field "$key" is not a valid DateTime string, got ${value.runtimeType}');
  }

  /// Safely extracts an optional DateTime from JSON
  static DateTime? getOptionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts a List from JSON with validation
  static List<T> getList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(dynamic) converter, {
    List<T>? defaultValue,
  }) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required List field "$key" is null');
    }
    if (value is! List) {
      throw ArgumentError(
          'Field "$key" is not a List, got ${value.runtimeType}');
    }

    try {
      return value.map(converter).toList();
    } catch (e) {
      throw ArgumentError('Failed to convert List items in field "$key": $e');
    }
  }

  /// Safely extracts an optional List from JSON
  static List<T>? getOptionalList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(dynamic) converter,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! List) return null;

    try {
      return value.map(converter).toList();
    } catch (e) {
      return null; // Failed conversion, return null instead of throwing
    }
  }

  /// Safely extracts a Map from JSON with validation
  static Map<String, dynamic> getMap(Map<String, dynamic> json, String key,
      {Map<String, dynamic>? defaultValue}) {
    final value = json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required Map field "$key" is null');
    }
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw ArgumentError(
        'Field "$key" is not a valid Map, got ${value.runtimeType}');
  }

  /// Safely extracts an optional Map from JSON
  static Map<String, dynamic>? getOptionalMap(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return value.map((k, v) => MapEntry(k.toString(), v));
      } catch (e) {
        return null; // Failed conversion, return null instead of throwing
      }
    }
    return null; // Invalid type, return null instead of throwing
  }

  /// Safely extracts an enum value from JSON
  static T getEnum<T extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
    T defaultValue,
  ) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is String) {
      try {
        return values.firstWhere(
          (e) => e.toString().split('.').last == value,
          orElse: () => defaultValue,
        );
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Safely extracts an optional enum value from JSON
  static T? getOptionalEnum<T extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
  ) {
    final value = json[key];
    if (value == null) return null;

    if (value is String) {
      try {
        return values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Validates that a JSON object contains all required fields
  static void validateRequiredFields(
      Map<String, dynamic> json, List<String> requiredFields) {
    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        missingFields.add(field);
      }
    }
    if (missingFields.isNotEmpty) {
      throw ArgumentError(
          'Missing required fields: ${missingFields.join(', ')}');
    }
  }

  /// Safely converts a value to a specific type with fallback
  static T safeCast<T>(dynamic value, T fallback) {
    try {
      if (value is T) return value;
      return fallback;
    } catch (e) {
      return fallback;
    }
  }
}
