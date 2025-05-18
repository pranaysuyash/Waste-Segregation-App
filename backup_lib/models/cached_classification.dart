import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

/// Model for cached image classifications
/// 
/// This model stores classification results for previously analyzed images
/// and includes metadata about the cache entry like creation timestamp
/// and usage statistics.
@HiveType(typeId: 2)
class CachedClassification extends HiveObject {
  /// Unique identifier (image hash) for this cache entry
  @HiveField(0)
  final String imageHash;

  /// The actual waste classification result
  @HiveField(1)
  final WasteClassification classification;

  /// When this classification was first cached
  @HiveField(2)
  final DateTime timestamp;

  /// Last time this cache entry was accessed (for LRU eviction)
  @HiveField(3)
  DateTime lastAccessed;

  /// Number of times this cache entry was used
  @HiveField(4)
  int useCount;

  /// Size of the original image in bytes (for cache size management)
  @HiveField(5)
  final int? imageSize;

  CachedClassification({
    required this.imageHash,
    required this.classification,
    DateTime? timestamp,
    DateTime? lastAccessed,
    this.useCount = 1,
    this.imageSize,
  })  : timestamp = timestamp ?? DateTime.now(),
        lastAccessed = lastAccessed ?? DateTime.now();

  /// Increments the use count and updates last accessed timestamp
  void markUsed() {
    useCount++;
    lastAccessed = DateTime.now();
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'imageHash': imageHash,
      'classification': classification.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'useCount': useCount,
      'imageSize': imageSize,
    };
  }

  /// Constructor from JSON
  factory CachedClassification.fromJson(Map<String, dynamic> json) {
    return CachedClassification(
      imageHash: json['imageHash'],
      classification: WasteClassification.fromJson(json['classification']),
      timestamp: DateTime.parse(json['timestamp']),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      useCount: json['useCount'],
      imageSize: json['imageSize'],
    );
  }

  /// Factory constructor from classification result
  factory CachedClassification.fromClassification(
    String hash,
    WasteClassification classification, {
    int? imageSize,
  }) {
    return CachedClassification(
      imageHash: hash,
      classification: classification,
      imageSize: imageSize,
    );
  }

  /// Serialize cache entry for storage in Hive
  /// (Since we're not using TypeAdapter due to the nested WasteClassification)
  String serialize() {
    return jsonEncode(toJson());
  }

  /// Deserialize cache entry from Hive storage
  static CachedClassification deserialize(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return CachedClassification.fromJson(json);
  }
}

/// TypeAdapter generation would typically go here,
/// but we're using manual serialization/deserialization 
/// since WasteClassification doesn't have a HiveTypeAdapter.
/// 
/// If you later create a proper TypeAdapter for WasteClassification,
/// you can replace the manual serialization with:
/// 
/// @HiveType(typeId: 2)
/// class CachedClassification {
///   ...fields with @HiveField annotations
/// }
/// 
/// part 'cached_classification.g.dart';
///
/// And then run: flutter packages pub run build_runner build