import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/filter_options.dart';

void main() {
  group('FilterOptions', () {
    test('empty factory has expected defaults', () {
      final options = FilterOptions.empty();

      expect(options.isEmpty, isTrue);
      expect(options.sortNewestFirst, isTrue);
      expect(options.sortBy, SortField.date);
    });

    test('isEmpty ignores sort-only overrides', () {
      final options =
          FilterOptions(sortNewestFirst: false, sortBy: SortField.name);
      expect(options.isEmpty, isTrue);
    });

    test('isNotEmpty when a real filter is present', () {
      final options = FilterOptions(searchText: 'plastic');
      expect(options.isNotEmpty, isTrue);
    });

    test('copyWith updates only provided fields', () {
      final start = DateTime(2026, 1, 1);
      final original = FilterOptions(
        searchText: 'bottle',
        categories: const ['plastic'],
        startDate: start,
      );

      final next = original.copyWith(
        searchText: 'paper',
        sortBy: SortField.name,
        sortNewestFirst: false,
      );

      expect(next.searchText, 'paper');
      expect(next.categories, const ['plastic']);
      expect(next.startDate, start);
      expect(next.sortBy, SortField.name);
      expect(next.sortNewestFirst, isFalse);
    });

    test('toString renders useful summary', () {
      final options = FilterOptions(
        searchText: 'battery',
        categories: const ['hazardous'],
        requiresSpecialDisposal: true,
      );

      final text = options.toString();
      expect(text, contains('Search: "battery"'));
      expect(text, contains('Categories: hazardous'));
      expect(text, contains('Special Disposal: Yes'));
    });

    test('sort field display names are stable', () {
      expect(SortField.date.displayName, 'Date');
      expect(SortField.name.displayName, 'Item Name');
      expect(SortField.category.displayName, 'Category');
    });
  });
}
