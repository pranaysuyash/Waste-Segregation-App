import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result from a barcode product lookup.
class BarcodeLookupResult {
  BarcodeLookupResult({
    this.category,
    this.subcategory,
    this.confidence = 0.0,
    this.productName,
    this.brand,
    this.packagingTags = const [],
    this.categoryTags = const [],
    required this.found,
    this.failureReason,
    this.processingTimeMs = 0,
    this.source = 'network',
  });

  final String? category;
  final String? subcategory;
  final double confidence;
  final String? productName;
  final String? brand;
  final List<String> packagingTags;
  final List<String> categoryTags;
  final bool found;
  final String? failureReason;
  final int processingTimeMs;
  final String source;
}

/// LRU cache entry for barcode lookups.
class _CacheEntry {
  _CacheEntry(this.result, this.cachedAt);
  final BarcodeLookupResult result;
  final DateTime cachedAt;
}

/// Packaging tags mapped to waste categories.
const Map<String, ({String category, String subcategory})> _packagingToWaste = {
  'en:plastic-bottle': (category: 'Dry Waste', subcategory: 'Plastic Bottle'),
  'en:pet': (category: 'Dry Waste', subcategory: 'PET Plastic'),
  'en:hdpe': (category: 'Dry Waste', subcategory: 'HDPE Plastic'),
  'en:plastic': (category: 'Dry Waste', subcategory: 'Plastic'),
  'en:aluminium-can': (category: 'Dry Waste', subcategory: 'Aluminium Can'),
  'en:glass-bottle': (category: 'Dry Waste', subcategory: 'Glass Bottle'),
  'en:glass': (category: 'Dry Waste', subcategory: 'Glass'),
  'en:cardboard': (category: 'Dry Waste', subcategory: 'Cardboard'),
  'en:paper': (category: 'Dry Waste', subcategory: 'Paper'),
  'en:tetra-pak': (category: 'Dry Waste', subcategory: 'Tetra Pak'),
  'en:metal': (category: 'Dry Waste', subcategory: 'Metal'),
  'en:steel': (category: 'Dry Waste', subcategory: 'Steel/Tin Can'),
  'en:can': (category: 'Dry Waste', subcategory: 'Metal Can'),
};

/// Product category tags mapped to waste categories (food content → wet waste).
const Map<String, ({String category, String subcategory})> _foodCategoryToWaste = {
  'en:beverages': (category: 'Wet Waste', subcategory: 'Liquid / Beverage'),
  'en:dairies': (category: 'Wet Waste', subcategory: 'Dairy'),
  'en:meats': (category: 'Wet Waste', subcategory: 'Meat / Fish'),
  'en:fruits': (category: 'Wet Waste', subcategory: 'Fruit'),
  'en:vegetables': (category: 'Wet Waste', subcategory: 'Vegetable'),
  'en:baked-goods': (category: 'Wet Waste', subcategory: 'Baked Goods'),
  'en:snacks': (category: 'Wet Waste', subcategory: 'Food Scraps'),
  'en:condiments': (category: 'Wet Waste', subcategory: 'Food Scraps'),
  'en:chocolates': (category: 'Wet Waste', subcategory: 'Food Scraps'),
  'en:soups': (category: 'Wet Waste', subcategory: 'Food Scraps'),
};

/// Standalone service that looks up a barcode via the Open Food Facts API
/// and maps the product's packaging/category to a waste classification.
///
/// This is NOT a [LocalClassifier] — it takes a barcode string, not image bytes.
/// The [Layer0Router] unifies this with the color histogram classifier.
class BarcodeLookupService {
  BarcodeLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _maxCacheSize = 500;
  static const _cacheTtl = Duration(days: 7);
  final Map<String, _CacheEntry> _cache = {};

  /// Look up a barcode and return a waste classification.
  ///
  /// Returns [BarcodeLookupResult.found] = false on network failure or
  /// unknown barcode — the caller should fall through to AI classification.
  Future<BarcodeLookupResult> lookup(
    String barcode, {
    String region = 'IN',
  }) async {
    final sw = Stopwatch()..start();
    final normalised = barcode.trim();

    if (normalised.isEmpty || normalised.length < 4) {
      return BarcodeLookupResult(
        found: false,
        failureReason: 'Invalid barcode: too short',
        processingTimeMs: sw.elapsedMilliseconds,
      );
    }

    // Check cache first.
    final cached = _cache[normalised];
    if (cached != null) {
      if (DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
        sw.stop();
        return BarcodeLookupResult(
          category: cached.result.category,
          subcategory: cached.result.subcategory,
          confidence: cached.result.confidence,
          productName: cached.result.productName,
          brand: cached.result.brand,
          packagingTags: cached.result.packagingTags,
          categoryTags: cached.result.categoryTags,
          found: cached.result.found,
          processingTimeMs: sw.elapsedMilliseconds,
          source: 'cache',
        );
      }
      _cache.remove(normalised);
    }

    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$normalised.json',
      );
      final response = await _client
          .get(uri, headers: {'User-Agent': 'WasteSegregationApp/1.0'})
          .timeout(const Duration(seconds: 3));

      sw.stop();

      if (response.statusCode != 200) {
        return BarcodeLookupResult(
          found: false,
          failureReason: 'HTTP ${response.statusCode}',
          processingTimeMs: sw.elapsedMilliseconds,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as int?;

      if (status != 1) {
        // Product not found in Open Food Facts.
        return BarcodeLookupResult(
          found: false,
          failureReason: 'Product not found',
          processingTimeMs: sw.elapsedMilliseconds,
        );
      }

      final product = json['product'] as Map<String, dynamic>? ?? {};
      final packagingTags = _parseStringList(product['packaging_tags']);
      final categoryTags = _parseStringList(product['categories_tags']);
      final productName = product['product_name'] as String?;
      final brand = product['brands'] as String?;

      // Map to waste category.
      final result = _mapToWasteCategory(
        packagingTags: packagingTags,
        categoryTags: categoryTags,
        productName: productName,
      );

      final lookupResult = BarcodeLookupResult(
        category: result.category,
        subcategory: result.subcategory,
        confidence: result.confidence,
        productName: productName,
        brand: brand,
        packagingTags: packagingTags,
        categoryTags: categoryTags,
        found: true,
        processingTimeMs: sw.elapsedMilliseconds,
        source: 'network',
      );

      // Store in cache.
      _cache[normalised] = _CacheEntry(lookupResult, DateTime.now());
      _evictIfNeeded();

      return lookupResult;
    } catch (e) {
      sw.stop();
      return BarcodeLookupResult(
        found: false,
        failureReason: 'Lookup error: $e',
        processingTimeMs: sw.elapsedMilliseconds,
      );
    }
  }

  /// Map packaging and category tags to a waste classification.
  _WasteMapping _mapToWasteCategory({
    required List<String> packagingTags,
    required List<String> categoryTags,
    String? productName,
  }) {
    // Priority 1: Packaging tags — the container/ wrapping determines disposal.
    for (final tag in packagingTags) {
      final match = _packagingToWaste[tag];
      if (match != null) {
        return _WasteMapping(
          category: match.category,
          subcategory: match.subcategory,
          confidence: 0.90,
        );
      }
    }

    // Priority 2: Food category tags — food content is wet waste.
    for (final tag in categoryTags) {
      final match = _foodCategoryToWaste[tag];
      if (match != null) {
        return _WasteMapping(
          category: match.category,
          subcategory: match.subcategory,
          confidence: 0.80,
        );
      }
    }

    // Default: we found the product but can't classify specifically.
    // Assign Dry Waste with medium confidence (most packaged items are dry waste).
    return _WasteMapping(
      category: 'Dry Waste',
      subcategory: 'Packaged Item',
      confidence: 0.60,
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  void _evictIfNeeded() {
    if (_cache.length <= _maxCacheSize) return;
    // Remove oldest entries.
    final sorted = _cache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final toRemove = sorted.take(_cache.length - _maxCacheSize);
    for (final entry in toRemove) {
      _cache.remove(entry.key);
    }
  }
}

class _WasteMapping {
  _WasteMapping({
    required this.category,
    this.subcategory,
    required this.confidence,
  });

  final String category;
  final String? subcategory;
  final double confidence;
}
