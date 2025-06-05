import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/filter_options.dart';

void main() {
  group('FilterOptions Model Tests', () {
    group('Constructor and Default Values', () {
      test('should create FilterOptions with default values', () {
        final filterOptions = FilterOptions();

        expect(filterOptions.categories, isEmpty);
        expect(filterOptions.dateRange, null);
        expect(filterOptions.locationRadius, null);
        expect(filterOptions.sortBy, SortBy.dateDesc);
        expect(filterOptions.showOnlyMistakes, false);
        expect(filterOptions.showOnlyShared, false);
        expect(filterOptions.minConfidence, null);
        expect(filterOptions.maxConfidence, null);
      });

      test('should create FilterOptions with custom values', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );

        final filterOptions = FilterOptions(
          categories: ['plastic', 'paper', 'glass'],
          dateRange: dateRange,
          locationRadius: 5.0,
          sortBy: SortBy.categoryAsc,
          showOnlyMistakes: true,
          showOnlyShared: true,
          minConfidence: 0.7,
          maxConfidence: 0.95,
          searchText: 'bottle',
        );

        expect(filterOptions.categories, ['plastic', 'paper', 'glass']);
        expect(filterOptions.dateRange, dateRange);
        expect(filterOptions.locationRadius, 5.0);
        expect(filterOptions.sortBy, SortBy.categoryAsc);
        expect(filterOptions.showOnlyMistakes, true);
        expect(filterOptions.showOnlyShared, true);
        expect(filterOptions.minConfidence, 0.7);
        expect(filterOptions.maxConfidence, 0.95);
        expect(filterOptions.searchText, 'bottle');
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );

        final filterOptions = FilterOptions(
          categories: ['plastic', 'paper'],
          dateRange: dateRange,
          locationRadius: 10.0,
          sortBy: SortBy.confidenceDesc,
          showOnlyMistakes: true,
          showOnlyShared: false,
          minConfidence: 0.8,
          maxConfidence: 1.0,
          searchText: 'recycling',
        );

        final json = filterOptions.toJson();

        expect(json['categories'], ['plastic', 'paper']);
        expect(json['dateRange'], isA<Map<String, dynamic>>());
        expect(json['locationRadius'], 10.0);
        expect(json['sortBy'], 'confidenceDesc');
        expect(json['showOnlyMistakes'], true);
        expect(json['showOnlyShared'], false);
        expect(json['minConfidence'], 0.8);
        expect(json['maxConfidence'], 1.0);
        expect(json['searchText'], 'recycling');
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'categories': ['metal', 'organic'],
          'dateRange': {
            'start': '2024-01-01T00:00:00.000',
            'end': '2024-01-31T23:59:59.999',
          },
          'locationRadius': 15.0,
          'sortBy': 'categoryDesc',
          'showOnlyMistakes': false,
          'showOnlyShared': true,
          'minConfidence': 0.6,
          'maxConfidence': 0.9,
          'searchText': 'compost',
        };

        final filterOptions = FilterOptions.fromJson(json);

        expect(filterOptions.categories, ['metal', 'organic']);
        expect(filterOptions.dateRange?.start, DateTime(2024, 1, 1));
        expect(filterOptions.dateRange?.end, DateTime(2024, 1, 31, 23, 59, 59, 999));
        expect(filterOptions.locationRadius, 15.0);
        expect(filterOptions.sortBy, SortBy.categoryDesc);
        expect(filterOptions.showOnlyMistakes, false);
        expect(filterOptions.showOnlyShared, true);
        expect(filterOptions.minConfidence, 0.6);
        expect(filterOptions.maxConfidence, 0.9);
        expect(filterOptions.searchText, 'compost');
      });

      test('should handle null values in JSON', () {
        final json = {
          'categories': <String>[],
          'dateRange': null,
          'locationRadius': null,
          'sortBy': 'dateDesc',
          'showOnlyMistakes': false,
          'showOnlyShared': false,
          'minConfidence': null,
          'maxConfidence': null,
          'searchText': null,
        };

        final filterOptions = FilterOptions.fromJson(json);

        expect(filterOptions.categories, isEmpty);
        expect(filterOptions.dateRange, null);
        expect(filterOptions.locationRadius, null);
        expect(filterOptions.sortBy, SortBy.dateDesc);
        expect(filterOptions.showOnlyMistakes, false);
        expect(filterOptions.showOnlyShared, false);
        expect(filterOptions.minConfidence, null);
        expect(filterOptions.maxConfidence, null);
        expect(filterOptions.searchText, null);
      });
    });

    group('Filter State Management', () {
      test('should check if any filters are active', () {
        final emptyFilter = FilterOptions();
        expect(emptyFilter.hasActiveFilters, false);

        final filterWithCategories = FilterOptions(
          categories: ['plastic'],
        );
        expect(filterWithCategories.hasActiveFilters, true);

        final filterWithDateRange = FilterOptions(
          dateRange: DateRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
        );
        expect(filterWithDateRange.hasActiveFilters, true);

        final filterWithSearchText = FilterOptions(
          searchText: 'bottle',
        );
        expect(filterWithSearchText.hasActiveFilters, true);
      });

      test('should count active filters', () {
        final multipleFilters = FilterOptions(
          categories: ['plastic', 'paper'],
          showOnlyMistakes: true,
          minConfidence: 0.8,
          searchText: 'bottle',
        );

        expect(multipleFilters.activeFilterCount, 4);

        final singleFilter = FilterOptions(
          locationRadius: 10.0,
        );

        expect(singleFilter.activeFilterCount, 1);
      });

      test('should clear all filters', () {
        final filterOptions = FilterOptions(
          categories: ['plastic', 'paper'],
          dateRange: DateRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
          locationRadius: 10.0,
          sortBy: SortBy.confidenceDesc,
          showOnlyMistakes: true,
          showOnlyShared: true,
          minConfidence: 0.8,
          maxConfidence: 0.95,
          searchText: 'bottle',
        );

        final clearedFilters = filterOptions.clearAll();

        expect(clearedFilters.categories, isEmpty);
        expect(clearedFilters.dateRange, null);
        expect(clearedFilters.locationRadius, null);
        expect(clearedFilters.sortBy, SortBy.dateDesc);
        expect(clearedFilters.showOnlyMistakes, false);
        expect(clearedFilters.showOnlyShared, false);
        expect(clearedFilters.minConfidence, null);
        expect(clearedFilters.maxConfidence, null);
        expect(clearedFilters.searchText, null);
        expect(clearedFilters.hasActiveFilters, false);
      });
    });

    group('Category Management', () {
      test('should add category', () {
        final filterOptions = FilterOptions();
        final updated = filterOptions.addCategory('plastic');

        expect(updated.categories, contains('plastic'));
        expect(updated.categories.length, 1);
      });

      test('should not add duplicate category', () {
        final filterOptions = FilterOptions(categories: ['plastic']);
        final updated = filterOptions.addCategory('plastic');

        expect(updated.categories, ['plastic']);
        expect(updated.categories.length, 1);
      });

      test('should remove category', () {
        final filterOptions = FilterOptions(categories: ['plastic', 'paper']);
        final updated = filterOptions.removeCategory('plastic');

        expect(updated.categories, ['paper']);
        expect(updated.categories.length, 1);
      });

      test('should toggle category', () {
        final filterOptions = FilterOptions(categories: ['plastic']);
        
        // Remove existing category
        final removed = filterOptions.toggleCategory('plastic');
        expect(removed.categories, isEmpty);

        // Add new category
        final added = removed.toggleCategory('paper');
        expect(added.categories, ['paper']);
      });

      test('should check if category is selected', () {
        final filterOptions = FilterOptions(categories: ['plastic', 'paper']);

        expect(filterOptions.isCategorySelected('plastic'), true);
        expect(filterOptions.isCategorySelected('glass'), false);
      });
    });

    group('Date Range Management', () {
      test('should set date range', () {
        final filterOptions = FilterOptions();
        final dateRange = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );

        final updated = filterOptions.setDateRange(dateRange);

        expect(updated.dateRange, dateRange);
      });

      test('should clear date range', () {
        final filterOptions = FilterOptions(
          dateRange: DateRange(
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 31),
          ),
        );

        final updated = filterOptions.clearDateRange();

        expect(updated.dateRange, null);
      });

      test('should set preset date ranges', () {
        final filterOptions = FilterOptions();

        // Today
        final today = filterOptions.setTodayFilter();
        expect(today.dateRange?.start.day, DateTime.now().day);

        // This week
        final thisWeek = filterOptions.setThisWeekFilter();
        expect(thisWeek.dateRange?.start.weekday, 1); // Monday

        // This month
        final thisMonth = filterOptions.setThisMonthFilter();
        expect(thisMonth.dateRange?.start.day, 1);
      });
    });

    group('Confidence Range Management', () {
      test('should set confidence range', () {
        final filterOptions = FilterOptions();
        final updated = filterOptions.setConfidenceRange(0.7, 0.9);

        expect(updated.minConfidence, 0.7);
        expect(updated.maxConfidence, 0.9);
      });

      test('should validate confidence range', () {
        final filterOptions = FilterOptions();

        // Invalid range (min > max)
        expect(() => filterOptions.setConfidenceRange(0.9, 0.7),
               throwsArgumentError);

        // Invalid values (out of range)
        expect(() => filterOptions.setConfidenceRange(-0.1, 0.9),
               throwsArgumentError);
        expect(() => filterOptions.setConfidenceRange(0.1, 1.1),
               throwsArgumentError);
      });

      test('should clear confidence range', () {
        final filterOptions = FilterOptions(
          minConfidence: 0.7,
          maxConfidence: 0.9,
        );

        final updated = filterOptions.clearConfidenceRange();

        expect(updated.minConfidence, null);
        expect(updated.maxConfidence, null);
      });
    });

    group('Copy and Update', () {
      test('should create copy with updated properties', () {
        final original = FilterOptions(
          categories: ['plastic'],
          sortBy: SortBy.dateDesc,
          showOnlyMistakes: false,
        );

        final updated = original.copyWith(
          categories: ['plastic', 'paper'],
          sortBy: SortBy.categoryAsc,
          showOnlyShared: true,
        );

        expect(updated.categories, ['plastic', 'paper']);
        expect(updated.sortBy, SortBy.categoryAsc);
        expect(updated.showOnlyMistakes, false); // Unchanged
        expect(updated.showOnlyShared, true); // Changed
        expect(original.categories, ['plastic']); // Original unchanged
      });
    });

    group('Validation', () {
      test('should validate location radius', () {
        expect(() => FilterOptions(locationRadius: -5.0),
               throwsArgumentError);

        expect(() => FilterOptions(locationRadius: 0.0),
               returnsNormally);

        expect(() => FilterOptions(locationRadius: 100.0),
               returnsNormally);
      });

      test('should validate search text length', () {
        expect(() => FilterOptions(searchText: ''),
               returnsNormally);

        expect(() => FilterOptions(searchText: 'a' * 1000),
               throwsArgumentError);
      });

      test('should validate date range consistency', () {
        final invalidDateRange = DateRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 1, 1), // End before start
        );

        expect(() => FilterOptions(dateRange: invalidDateRange),
               throwsArgumentError);
      });
    });

    group('Sort Options', () {
      test('should handle all sort options', () {
        final sortOptions = [
          SortBy.dateDesc,
          SortBy.dateAsc,
          SortBy.categoryAsc,
          SortBy.categoryDesc,
          SortBy.confidenceDesc,
          SortBy.confidenceAsc,
        ];

        for (final sortBy in sortOptions) {
          final filterOptions = FilterOptions(sortBy: sortBy);
          expect(filterOptions.sortBy, sortBy);
        }
      });

      test('should provide sort display names', () {
        expect(SortBy.dateDesc.displayName, 'Newest First');
        expect(SortBy.dateAsc.displayName, 'Oldest First');
        expect(SortBy.categoryAsc.displayName, 'Category A-Z');
        expect(SortBy.categoryDesc.displayName, 'Category Z-A');
        expect(SortBy.confidenceDesc.displayName, 'Highest Confidence');
        expect(SortBy.confidenceAsc.displayName, 'Lowest Confidence');
      });
    });

    group('Equality and Comparison', () {
      test('should compare FilterOptions for equality', () {
        final filter1 = FilterOptions(
          categories: ['plastic', 'paper'],
          sortBy: SortBy.categoryAsc,
          showOnlyMistakes: true,
        );

        final filter2 = FilterOptions(
          categories: ['plastic', 'paper'],
          sortBy: SortBy.categoryAsc,
          showOnlyMistakes: true,
        );

        final filter3 = FilterOptions(
          categories: ['plastic'],
          sortBy: SortBy.categoryAsc,
          showOnlyMistakes: true,
        );

        expect(filter1 == filter2, true);
        expect(filter1 == filter3, false);
        expect(filter1.hashCode == filter2.hashCode, true);
      });
    });

    group('Preset Filters', () {
      test('should create preset filter for mistakes only', () {
        final mistakesFilter = FilterOptions.mistakesOnly();

        expect(mistakesFilter.showOnlyMistakes, true);
        expect(mistakesFilter.showOnlyShared, false);
      });

      test('should create preset filter for shared items only', () {
        final sharedFilter = FilterOptions.sharedOnly();

        expect(sharedFilter.showOnlyShared, true);
        expect(mistakesFilter.showOnlyMistakes, false);
      });

      test('should create preset filter for high confidence items', () {
        final highConfidenceFilter = FilterOptions.highConfidenceOnly();

        expect(highConfidenceFilter.minConfidence, greaterThan(0.8));
        expect(highConfidenceFilter.maxConfidence, 1.0);
      });

      test('should create preset filter for recent items', () {
        final recentFilter = FilterOptions.recentOnly();

        expect(recentFilter.dateRange, isNotNull);
        expect(recentFilter.dateRange!.start.isAfter(
          DateTime.now().subtract(const Duration(days: 8))
        ), true);
      });
    });
  });
}
