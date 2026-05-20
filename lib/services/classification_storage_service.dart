import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/filter_options.dart';
import '../models/classification_feedback.dart';
import '../utils/constants.dart';
import '../utils/waste_app_logger.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// ⚠️ CONTAINED EXTRACTION — see StorageService for primary write path.
///
/// This service was extracted from StorageService during Phase 4 architecture
/// work. It is NOT wired into the app's core classification write path.
///
/// Format mismatch:
///   - StorageService writes via Hive TypeAdapter (binary WasteClassification)
///   - This service writes via jsonEncode(classification.toJson())
///   - Both write to the same Hive box (StorageKeys.classificationsBox)
///   - Naive delegation would create dual-format writes in the same box —
///     a bad steady state because every future reader must parse both formats.
///
/// Key mismatch (profile service):
///   - StorageService stores current profile under StorageKeys.userProfileKey
///   - UserProfileStorageService stores under userProfile.id (UUID)
///   - These are NOT equivalent: StorageService.getCurrentUserProfile()
///     would not find a record written by UserProfileStorageService.
///
/// Safe usage:
///   - Read/helper methods (getClassificationById, getSetting<T>, CSV export)
///     are format-safe because both services handle multi-format reads.
///   - Do NOT call saveClassification / saveUserProfile from app code —
///     use StorageService which is the canonical write path.
///
/// Roadmap:
///   A true fix requires unifying all storage on one serialization format
///   (TypeAdapter) and resolving the profile keying difference. That is a
///   migration, not a refactor, and should not be attempted as a quick fix.
///
/// See also: StorageService.classificationStorage, StorageService.profileStorage
class ClassificationStorageService {
  static const String _classificationsBoxName = StorageKeys.classificationsBox;
  static const String _feedbackBoxName = StorageKeys.classificationFeedbackBox;

  /// Save or update a classification
  @Deprecated(
    'Do not use for primary app persistence. StorageService.saveClassification '
    'is the source of truth because it writes TypeAdapter objects and maintains '
    'dedup/hash index compatibility. This method writes JSON strings to the '
    'same Hive box, creating an unsafe dual-format condition.',
  )
  Future<void> saveClassification(WasteClassification classification,
      {String? userId}) async {
    try {
      final box = await Hive.openBox(_classificationsBoxName);

      // Ensure classification has an ID
      if (classification.id.isEmpty) {
        classification = classification.copyWith(id: const Uuid().v4());
      }

      // Set userId if provided
      if (userId != null) {
        classification = classification.copyWith(userId: userId);
      }

      // Save as JSON string for consistency
      await box.put(classification.id, jsonEncode(classification.toJson()));

      WasteAppLogger.info(
        'Classification saved',
        context: {
          'id': classification.id,
          'category': classification.category,
          'item': classification.itemName,
        },
      );
    } catch (e, s) {
      WasteAppLogger.severe('Error saving classification',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get all classifications with optional filtering
  Future<List<WasteClassification>> getAllClassifications({
    FilterOptions? filterOptions,
    String? userId,
  }) async {
    try {
      final box = await Hive.openBox(_classificationsBoxName);
      final classifications = <WasteClassification>[];

      for (final key in box.keys) {
        try {
          final data = box.get(key);
          if (data == null) continue;

          WasteClassification classification;

          if (data is WasteClassification) {
            classification = data;
          } else if (data is String) {
            if (data.isEmpty) continue;
            final json = jsonDecode(data);
            classification = WasteClassification.fromJson(json);
          } else if (data is Map) {
            classification = WasteClassification.fromJson(
                data is Map<String, dynamic>
                    ? data
                    : Map<String, dynamic>.from(data));
          } else {
            WasteAppLogger.warning('Invalid classification data type',
                context: {
                  'key': key.toString(),
                  'type': data.runtimeType.toString(),
                });
            continue;
          }

          // Filter by userId if provided
          if (userId != null) {
            final matchesUser = classification.userId == userId ||
                (userId == 'guest_user' &&
                    (classification.userId == null ||
                        classification.userId == 'guest_user'));
            if (!matchesUser) continue;
          }

          classifications.add(classification);
        } catch (e) {
          WasteAppLogger.warning('Error parsing classification',
              error: e, context: {'key': key.toString()});
          continue;
        }
      }

      // Apply filters if provided
      if (filterOptions != null && filterOptions.isNotEmpty) {
        return _applyFilters(classifications, filterOptions);
      }

      // Default sorting by timestamp (newest first)
      classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return classifications;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting classifications',
          error: e, stackTrace: s);
      return [];
    }
  }

  /// Get classifications with pagination
  Future<List<WasteClassification>> getClassificationsWithPagination({
    FilterOptions? filterOptions,
    String? userId,
    int pageSize = 20,
    int page = 0,
  }) async {
    final allClassifications = await getAllClassifications(
      filterOptions: filterOptions,
      userId: userId,
    );

    final startIndex = page * pageSize;
    final endIndex = (page + 1) * pageSize;

    if (startIndex >= allClassifications.length) {
      return [];
    }

    return allClassifications.sublist(
      startIndex,
      endIndex > allClassifications.length
          ? allClassifications.length
          : endIndex,
    );
  }

  /// Get count of classifications
  Future<int> getClassificationsCount({
    FilterOptions? filterOptions,
    String? userId,
  }) async {
    final classifications = await getAllClassifications(
      filterOptions: filterOptions,
      userId: userId,
    );
    return classifications.length;
  }

  /// Get a single classification by ID
  Future<WasteClassification?> getClassificationById(String id) async {
    try {
      final box = await Hive.openBox(_classificationsBoxName);
      final data = box.get(id);

      if (data == null) return null;

      if (data is WasteClassification) {
        return data;
      } else if (data is String) {
        final json = jsonDecode(data);
        return WasteClassification.fromJson(json);
      } else if (data is Map) {
        return WasteClassification.fromJson(data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data));
      }

      return null;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting classification by ID',
          error: e, stackTrace: s, context: {'id': id});
      return null;
    }
  }

  /// Delete a classification
  Future<void> deleteClassification(String id) async {
    try {
      final box = await Hive.openBox(_classificationsBoxName);
      await box.delete(id);

      WasteAppLogger.info('Classification deleted', context: {'id': id});
    } catch (e, s) {
      WasteAppLogger.severe('Error deleting classification',
          error: e, stackTrace: s, context: {'id': id});
      rethrow;
    }
  }

  /// Clear all classifications
  Future<void> clearAllClassifications() async {
    try {
      final box = await Hive.openBox(_classificationsBoxName);
      await box.clear();

      WasteAppLogger.info('All classifications cleared');
    } catch (e, s) {
      WasteAppLogger.severe('Error clearing classifications',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Export classifications to CSV
  Future<String> exportToCSV({
    FilterOptions? filterOptions,
    String? userId,
  }) async {
    final classifications = await getAllClassifications(
      filterOptions: filterOptions,
      userId: userId,
    );

    final rows = <List<dynamic>>[
      [
        'ID',
        'Item Name',
        'Category',
        'Subcategory',
        'Material Type',
        'Confidence',
        'Timestamp',
        'Is Recyclable',
        'Is Compostable',
        'Disposal Method',
      ],
    ];

    for (final classification in classifications) {
      rows.add([
        classification.id,
        classification.itemName,
        classification.category,
        classification.subcategory ?? '',
        classification.materialType ?? '',
        classification.confidence,
        classification.timestamp.toIso8601String(),
        classification.isRecyclable,
        classification.isCompostable,
        classification.disposalMethod ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Save classification feedback
  Future<void> saveClassificationFeedback(
      ClassificationFeedback feedback) async {
    try {
      final box = await Hive.openBox(_feedbackBoxName);
      await box.put(feedback.id, jsonEncode(feedback.toJson()));

      WasteAppLogger.info('Classification feedback saved',
          context: {'id': feedback.id});
    } catch (e, s) {
      WasteAppLogger.severe('Error saving feedback', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get all classification feedback
  Future<List<ClassificationFeedback>> getAllClassificationFeedback() async {
    try {
      final box = await Hive.openBox(_feedbackBoxName);
      final feedbackList = <ClassificationFeedback>[];

      for (final key in box.keys) {
        try {
          final data = box.get(key);
          if (data is String) {
            final json = jsonDecode(data);
            feedbackList.add(ClassificationFeedback.fromJson(json));
          }
        } catch (e) {
          WasteAppLogger.warning('Error parsing feedback',
              error: e, context: {'key': key.toString()});
        }
      }

      return feedbackList;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting feedback', error: e, stackTrace: s);
      return [];
    }
  }

  /// OPTIMIZATION: Apply filters in a single pass (already optimized in original)
  List<WasteClassification> _applyFilters(
    List<WasteClassification> classifications,
    FilterOptions filterOptions,
  ) {
    return classifications.where((classification) {
      // Search text filter
      if (filterOptions.searchText != null &&
          filterOptions.searchText!.isNotEmpty) {
        final searchText = filterOptions.searchText!.toLowerCase();
        final matchesSearch =
            classification.itemName.toLowerCase().contains(searchText) ||
                (classification.subcategory != null &&
                    classification.subcategory!
                        .toLowerCase()
                        .contains(searchText)) ||
                (classification.materialType != null &&
                    classification.materialType!
                        .toLowerCase()
                        .contains(searchText)) ||
                classification.category.toLowerCase().contains(searchText);
        if (!matchesSearch) return false;
      }

      // Category filter
      if (filterOptions.categories != null &&
          filterOptions.categories!.isNotEmpty) {
        final matchesCategory = filterOptions.categories!.any((category) =>
            classification.category.toLowerCase() == category.toLowerCase());
        if (!matchesCategory) return false;
      }

      // Subcategory filter
      if (filterOptions.subcategories != null &&
          filterOptions.subcategories!.isNotEmpty) {
        if (classification.subcategory == null) return false;
        final matchesSubcategory = filterOptions.subcategories!.any(
            (subcategory) =>
                classification.subcategory!.toLowerCase() ==
                subcategory.toLowerCase());
        if (!matchesSubcategory) return false;
      }

      // Material type filter
      if (filterOptions.materialTypes != null &&
          filterOptions.materialTypes!.isNotEmpty) {
        if (classification.materialType == null) return false;
        final matchesMaterial = filterOptions.materialTypes!.any(
            (materialType) =>
                classification.materialType!.toLowerCase() ==
                materialType.toLowerCase());
        if (!matchesMaterial) return false;
      }

      // Recyclable filter
      if (filterOptions.isRecyclable != null) {
        if (classification.isRecyclable != filterOptions.isRecyclable) {
          return false;
        }
      }

      // Compostable filter
      if (filterOptions.isCompostable != null) {
        if (classification.isCompostable != filterOptions.isCompostable) {
          return false;
        }
      }

      // Special disposal filter
      if (filterOptions.requiresSpecialDisposal != null) {
        if (classification.requiresSpecialDisposal !=
            filterOptions.requiresSpecialDisposal) {
          return false;
        }
      }

      // Date range filters
      if (filterOptions.startDate != null) {
        final startDate = DateTime(
          filterOptions.startDate!.year,
          filterOptions.startDate!.month,
          filterOptions.startDate!.day,
        );
        final classificationDate = DateTime(
          classification.timestamp.year,
          classification.timestamp.month,
          classification.timestamp.day,
        );
        if (!(classificationDate.isAtSameMomentAs(startDate) ||
            classificationDate.isAfter(startDate))) {
          return false;
        }
      }

      if (filterOptions.endDate != null) {
        final endDate = DateTime(
          filterOptions.endDate!.year,
          filterOptions.endDate!.month,
          filterOptions.endDate!.day,
          23,
          59,
          59,
          999,
        );
        if (!(classification.timestamp.isBefore(endDate) ||
            classification.timestamp.isAtSameMomentAs(endDate))) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Apply sorting based on filterOptions
        switch (filterOptions.sortBy) {
          case SortField.date:
            return filterOptions.sortNewestFirst
                ? b.timestamp.compareTo(a.timestamp)
                : a.timestamp.compareTo(b.timestamp);
          case SortField.name:
            return filterOptions.sortNewestFirst
                ? a.itemName.compareTo(b.itemName)
                : b.itemName.compareTo(a.itemName);
          case SortField.category:
            return filterOptions.sortNewestFirst
                ? a.category.compareTo(b.category)
                : b.category.compareTo(a.category);
        }
      });
  }

  /// Clean up duplicate classifications
  Future<int> cleanupDuplicateClassifications() async {
    try {
      final allClassifications = await getAllClassifications();
      final box = await Hive.openBox(_classificationsBoxName);

      // Track seen classifications by content hash
      final seen = <String, WasteClassification>{};
      final duplicates = <String>[];

      for (final classification in allClassifications) {
        final key = '${classification.itemName}_${classification.category}_'
            '${classification.timestamp.millisecondsSinceEpoch ~/ 60000}'; // Group by minute

        if (seen.containsKey(key)) {
          // This is a duplicate
          duplicates.add(classification.id);
        } else {
          seen[key] = classification;
        }
      }

      // Delete duplicates
      for (final id in duplicates) {
        await box.delete(id);
      }

      WasteAppLogger.info(
        'Cleaned up duplicate classifications',
        context: {'duplicates_removed': duplicates.length},
      );

      return duplicates.length;
    } catch (e, s) {
      WasteAppLogger.severe('Error cleaning up duplicates',
          error: e, stackTrace: s);
      return 0;
    }
  }
}
