import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/filter_options.dart';

void main() {
  group('FilterOptions Model Tests', () {
    group('Constructor and Default Values', () {
      test('should create FilterOptions with default values', () {
        final filterOptions = FilterOptions();

        expect(filterOptions.searchText, null);
        expect(filterOptions.categories, null);
        expect(filterOptions.subcategories, null);
        expect(filterOptions.materialTypes, null);
        expect(filterOptions.isRecyclable, null);
        expect(filterOptions.isCompostable, null);
        expect(filterOptions.requiresSpecialDisposal, null);
        expect(filterOptions.startDate, null);
        expect(filterOptions.endDate, null);
        expect(filterOptions.sortNewestFirst, true);
        expect(filterOptions.sortBy, SortField.date);
      });

      test('should create FilterOptions with custom values', () {
        final startDate = DateTime(2024, 1);
        final endDate = DateTime(2024, 1, 31);
        final categories = ['plastic', 'paper'];
        final subcategories = ['bottle', 'newspaper'];
        final materialTypes = ['PET', 'cardboard'];

        final filterOptions = FilterOptions(
          searchText: 'test query',
          categories: categories,
          subcategories: subcategories,
          materialTypes: materialTypes,
          isRecyclable: true,
          isCompostable: false,
          requiresSpecialDisposal: true,
          startDate: startDate,
          endDate: endDate,
          sortNewestFirst: false,
          sortBy: SortField.category,
        );

        expect(filterOptions.searchText, 'test query');
        expect(filterOptions.categories, categories);
        expect(filterOptions.subcategories, subcategories);
        expect(filterOptions.materialTypes, materialTypes);
        expect(filterOptions.isRecyclable, true);
        expect(filterOptions.isCompostable, false);
        expect(filterOptions.requiresSpecialDisposal, true);
        expect(filterOptions.startDate, startDate);
        expect(filterOptions.endDate, endDate);
        expect(filterOptions.sortNewestFirst, false);
        expect(filterOptions.sortBy, SortField.category);
      });

      test('FilterOptions.empty() factory constructor', () {
        final filterOptions = FilterOptions.empty();

        expect(filterOptions.searchText, null);
        expect(filterOptions.categories, null);
        expect(filterOptions.subcategories, null);
        expect(filterOptions.materialTypes, null);
        expect(filterOptions.isRecyclable, null);
        expect(filterOptions.isCompostable, null);
        expect(filterOptions.requiresSpecialDisposal, null);
        expect(filterOptions.startDate, null);
        expect(filterOptions.endDate, null);
        expect(filterOptions.sortNewestFirst, true); // Default from constructor
        expect(filterOptions.sortBy, SortField.date); // Default from constructor
        expect(filterOptions.isEmpty, true);
      });
    });

    group('isEmpty and isNotEmpty Getters', () {
      test('isEmpty should be true for default FilterOptions', () {
        final filterOptions = FilterOptions();
        // Note: Default sort options don't make it "non-empty" by its definition
        expect(filterOptions.isEmpty, true);
        expect(filterOptions.isNotEmpty, false);
      });

      test('isEmpty should be false if searchText is set', () {
        final filterOptions = FilterOptions(searchText: 'test');
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });

      test('isEmpty should be false if categories are set', () {
        final filterOptions = FilterOptions(categories: ['plastic']);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if subcategories are set', () {
        final filterOptions = FilterOptions(subcategories: ['bottle']);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if materialTypes are set', () {
        final filterOptions = FilterOptions(materialTypes: ['PET']);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if isRecyclable is set', () {
        final filterOptions = FilterOptions(isRecyclable: true);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if isCompostable is set', () {
        final filterOptions = FilterOptions(isCompostable: true);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if requiresSpecialDisposal is set', () {
        final filterOptions = FilterOptions(requiresSpecialDisposal: true);
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if startDate is set', () {
        final filterOptions = FilterOptions(startDate: DateTime.now());
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });
      test('isEmpty should be false if endDate is set', () {
        final filterOptions = FilterOptions(endDate: DateTime.now());
        expect(filterOptions.isEmpty, false);
        expect(filterOptions.isNotEmpty, true);
      });

      test('isEmpty should be true if only sort options are non-default', () {
        final filterOptions = FilterOptions(sortBy: SortField.name, sortNewestFirst: false);
        expect(filterOptions.isEmpty, true); // Sorting options don't count as filters for isEmpty
        expect(filterOptions.isNotEmpty, false);
      });
    });

    group('copyWith Method', () {
      test('copyWith should create a copy with updated values', () {
        final original = FilterOptions(
          searchText: 'original',
          categories: ['glass'],
          sortBy: SortField.name,
        );

        final copied = original.copyWith(
          searchText: 'updated',
          categories: ['paper', 'plastic'],
          isRecyclable: true,
          sortBy: SortField.category,
          sortNewestFirst: false,
        );

        expect(copied.searchText, 'updated');
        expect(copied.categories, ['paper', 'plastic']);
        expect(copied.isRecyclable, true);
        expect(copied.sortBy, SortField.category);
        expect(copied.sortNewestFirst, false);

        // Ensure original is unchanged
        expect(original.searchText, 'original');
        expect(original.categories, ['glass']);
        expect(original.isRecyclable, null);
        expect(original.sortBy, SortField.name);
        expect(original.sortNewestFirst, true);
      });

      test('copyWith should use original values if new values are null', () {
        final original = FilterOptions(
          searchText: 'original',
          categories: ['glass'],
          startDate: DateTime(2023),
        );

        final copied = original.copyWith(); // No changes

        expect(copied.searchText, 'original');
        expect(copied.categories, ['glass']);
        expect(copied.startDate, DateTime(2023));
        expect(copied.sortBy, SortField.date); // Default
        expect(copied.sortNewestFirst, true); // Default
      });

      test('copyWith can clear a value by passing null', () {
        final original = FilterOptions(searchText: 'original');
        final copied = original.copyWith();
        expect(copied.searchText, null);
      });
    });

    group('SortFieldExtension Tests', () {
      test('displayName should return correct strings', () {
        expect(SortField.date.displayName, 'Date');
        expect(SortField.name.displayName, 'Item Name');
        expect(SortField.category.displayName, 'Category');
      });
    });

    group('toString Method', () {
      test('toString with no filters', () {
        final options = FilterOptions();
        expect(options.toString(), 'No filters applied');
      });

      test('toString with multiple filters', () {
        final options = FilterOptions(
            searchText: 'bottle',
            categories: ['plastic', 'glass'],
            isRecyclable: true,
            startDate: DateTime(2024, 1),
            endDate: DateTime(2024, 1, 31));
        // Basic check, exact format might vary slightly based on implementation details not shown
        // For example, date formatting.
        // The model's _formatDate is 'day/month/year'
        expect(options.toString(), contains('Search: "bottle"'));
        expect(options.toString(), contains('Categories: plastic, glass'));
        expect(options.toString(), contains('Recyclable: Yes'));
        expect(options.toString(), contains('Date Range: 1/1/2024 to 31/1/2024'));
      });

      test('toString with only searchText', () {
        final options = FilterOptions(searchText: 'keyword');
        expect(options.toString(), 'Search: "keyword"');
      });

      test('toString with only categories', () {
        final options = FilterOptions(categories: ['food', 'organic']);
        expect(options.toString(), 'Categories: food, organic');
      });

      test('toString with only subcategories', () {
        final options = FilterOptions(subcategories: ['peels', 'cores']);
        expect(options.toString(), 'Subcategories: peels, cores');
      });

      test('toString with only materialTypes', () {
        final options = FilterOptions(materialTypes: ['HDPE', 'LDPE']);
        expect(options.toString(), 'Materials: HDPE, LDPE');
      });

      test('toString with only isCompostable false', () {
        final options = FilterOptions(isCompostable: false);
        expect(options.toString(), 'Compostable: No');
      });
      test('toString with only requiresSpecialDisposal true', () {
        final options = FilterOptions(requiresSpecialDisposal: true);
        expect(options.toString(), 'Special Disposal: Yes');
      });

      test('toString with only startDate', () {
        final options = FilterOptions(startDate: DateTime(2024, 3, 15));
        expect(options.toString(), 'From: 15/3/2024');
      });

      test('toString with only endDate', () {
        final options = FilterOptions(endDate: DateTime(2024, 4, 20));
        expect(options.toString(), 'Until: 20/4/2024');
      });
    });
  });
}
