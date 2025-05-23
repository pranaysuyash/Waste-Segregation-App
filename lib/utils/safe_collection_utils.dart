// Safe Collection Utilities
// Prevents "Bad state: No element" errors throughout the app

class SafeCollectionUtils {
  
  /// Safely get the first element from a list without throwing
  static T? safeFirst<T>(List<T> list) {
    if (list.isEmpty) return null;
    return list.first;
  }
  
  /// Safely get the last element from a list without throwing
  static T? safeLast<T>(List<T> list) {
    if (list.isEmpty) return null;
    return list.last;
  }
  
  /// Safely get element at index without throwing
  static T? safeElementAt<T>(List<T> list, int index) {
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }
  
  /// Safely get first element matching condition
  static T? safeFirstWhere<T>(List<T> list, bool Function(T) test) {
    try {
      return list.firstWhere(test);
    } catch (e) {
      return null;
    }
  }
  
  /// Safely get last element matching condition
  static T? safeLastWhere<T>(List<T> list, bool Function(T) test) {
    try {
      return list.lastWhere(test);
    } catch (e) {
      return null;
    }
  }
  
  /// Safely get single element matching condition
  static T? safeSingleWhere<T>(List<T> list, bool Function(T) test) {
    try {
      return list.singleWhere(test);
    } catch (e) {
      return null;
    }
  }
  
  /// Safely get elements matching condition
  static List<T> safeWhere<T>(List<T> list, bool Function(T) test) {
    try {
      return list.where(test).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Check if collection is null or empty
  static bool isNullOrEmpty<T>(List<T>? list) {
    return list == null || list.isEmpty;
  }
  
  /// Check if collection is not null and not empty
  static bool isNotNullOrEmpty<T>(List<T>? list) {
    return list != null && list.isNotEmpty;
  }
  
  /// Safe map operation
  static List<R> safeMap<T, R>(List<T> list, R Function(T) mapper) {
    try {
      return list.map(mapper).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Safe reduce operation
  static T? safeReduce<T>(List<T> list, T Function(T, T) combine) {
    if (list.isEmpty) return null;
    try {
      return list.reduce(combine);
    } catch (e) {
      return null;
    }
  }
  
  /// Safe fold operation
  static T safeFold<T, R>(List<R> list, T initialValue, T Function(T, R) combine) {
    try {
      return list.fold(initialValue, combine);
    } catch (e) {
      return initialValue;
    }
  }
}

// Extension methods for more convenient usage
extension SafeListExtension<T> on List<T> {
  T? get safeFirst => SafeCollectionUtils.safeFirst(this);
  T? get safeLast => SafeCollectionUtils.safeLast(this);
  T? safeAt(int index) => SafeCollectionUtils.safeElementAt(this, index);
  T? safeFirstWhere(bool Function(T) test) => SafeCollectionUtils.safeFirstWhere(this, test);
  T? safeLastWhere(bool Function(T) test) => SafeCollectionUtils.safeLastWhere(this, test);
  T? safeSingleWhere(bool Function(T) test) => SafeCollectionUtils.safeSingleWhere(this, test);
  List<T> safeWhere(bool Function(T) test) => SafeCollectionUtils.safeWhere(this, test);
  List<R> safeMap<R>(R Function(T) mapper) => SafeCollectionUtils.safeMap(this, mapper);
  
  /// Safe operations with default values
  T safeFirstWithDefault(T defaultValue) => safeFirst ?? defaultValue;
  T safeLastWithDefault(T defaultValue) => safeLast ?? defaultValue;
  T safeAtWithDefault(int index, T defaultValue) => safeAt(index) ?? defaultValue;
  
  /// Safe random element
  T? get safeRandom {
    if (isEmpty) return null;
    final random = DateTime.now().millisecondsSinceEpoch % length;
    return this[random];
  }
  
  /// Safe sublist
  List<T> safeSublist(int start, [int? end]) {
    if (isEmpty) return [];
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return sublist(safeStart, safeEnd);
  }
  
  /// Safe take operation
  List<T> safeTake(int count) {
    if (isEmpty || count <= 0) return [];
    return take(count.clamp(0, length)).toList();
  }
  
  /// Safe skip operation
  List<T> safeSkip(int count) {
    if (isEmpty || count <= 0) return List.from(this);
    if (count >= length) return [];
    return skip(count).toList();
  }
}

extension SafeNullableListExtension<T> on List<T>? {
  bool get isNullOrEmpty => SafeCollectionUtils.isNullOrEmpty(this);
  bool get isNotNullOrEmpty => SafeCollectionUtils.isNotNullOrEmpty(this);
  T? get safeFirst => this?.safeFirst;
  T? get safeLast => this?.safeLast;
}
