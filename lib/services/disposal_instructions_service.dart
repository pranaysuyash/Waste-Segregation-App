import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

class DisposalInstructionResolution {
  const DisposalInstructionResolution({
    required this.instructions,
    required this.source,
    required this.cacheKey,
    this.confidence,
    this.explanation,
  });

  final DisposalInstructions instructions;
  final String source;
  final String cacheKey;
  final double? confidence;
  final String? explanation;
}

/// Service for fetching LLM-generated disposal instructions
class DisposalInstructionsService {
  static const String _functionUrl =
      'https://asia-south1-waste-segregation-app-df523.cloudfunctions.net/generateDisposal';

  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache for disposal instructions to avoid repeated API calls
  final Map<String, DisposalInstructions> _cache = {};

  /// Build a canonical cache/document key, including language context.
  ///
  /// This is intentionally URI-encoded to preserve uniqueness for non-ASCII
  /// values while remaining Firestore document ID safe.
  @visibleForTesting
  String buildMaterialCacheKey({
    required String material,
    String? category,
    String? subcategory,
    String lang = 'en',
  }) {
    String normalizePart(String value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return 'na';
      return Uri.encodeComponent(normalized);
    }

    final parts = [
      'lang=${normalizePart(lang)}',
      'material=${normalizePart(material)}',
    ];
    if (category != null && category.trim().isNotEmpty) {
      parts.add('category=${normalizePart(category)}');
    }
    if (subcategory != null && subcategory.trim().isNotEmpty) {
      parts.add('subcategory=${normalizePart(subcategory)}');
    }
    return parts.join('__');
  }

  /// Legacy key format retained for cache migration compatibility.
  @visibleForTesting
  String buildLegacyMaterialId(
      String material, String? category, String? subcategory) {
    final parts = [material.toLowerCase().trim()];
    if (category != null) parts.add(category.toLowerCase().trim());
    if (subcategory != null) parts.add(subcategory.toLowerCase().trim());
    return parts.join('_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Fetch disposal instructions for a material
  Future<DisposalInstructions> getDisposalInstructions({
    required String material,
    String? category,
    String? subcategory,
    String lang = 'en',
  }) async {
    final resolution = await getDisposalInstructionsWithResolution(
      material: material,
      category: category,
      subcategory: subcategory,
      lang: lang,
    );
    return resolution.instructions;
  }

  Future<DisposalInstructionResolution> getDisposalInstructionsWithResolution({
    required String material,
    String? category,
    String? subcategory,
    String lang = 'en',
  }) async {
    try {
      final materialId = buildMaterialCacheKey(
        material: material,
        category: category,
        subcategory: subcategory,
        lang: lang,
      );

      // Check local cache first
      if (_cache.containsKey(materialId)) {
        WasteAppLogger.cacheEvent('cache_hit', 'disposal_instructions',
            hit: true,
            key: materialId,
            context: {
              'material': material,
              'category': category,
              'subcategory': subcategory
            });
        return DisposalInstructionResolution(
          instructions: _cache[materialId]!,
          source: 'cache_local',
          cacheKey: materialId,
        );
      }

      // Check Firestore cache (new key, then legacy key for migration safety)
      final firestoreCached = await _loadFromFirestoreCache(
        materialId: materialId,
        material: material,
        category: category,
        subcategory: subcategory,
      );

      if (firestoreCached != null) {
        WasteAppLogger.cacheEvent(
            'cache_hit', 'disposal_instructions_firestore',
            hit: true,
            key: materialId,
            context: {
              'material': material,
              'category': category,
              'subcategory': subcategory,
              'source': 'firestore',
              'cache_key_format': 'canonical_or_legacy'
            });
        _cache[materialId] = firestoreCached.instructions;
        return firestoreCached;
      }

      // Generate new instructions via Cloud Function
      WasteAppLogger.aiEvent('disposal_instructions_generation_started',
          context: {
            'material_id': materialId,
            'material': material,
            'category': category,
            'subcategory': subcategory,
            'language': lang
          });
      final instructions = await _generateViaCloudFunction(
        materialId: materialId,
        material: material,
        category: category,
        subcategory: subcategory,
        lang: lang,
      );

      _cache[materialId] = instructions.instructions;
      return instructions;
    } catch (e) {
      WasteAppLogger.severe('Error fetching disposal instructions',
          error: e,
          context: {
            'material': material,
            'category': category,
            'subcategory': subcategory,
            'language': lang,
            'action': 'fallback_to_default_instructions'
          });
      return DisposalInstructionResolution(
        instructions: _getFallbackInstructions(material, category),
        source: 'fallback_error',
        cacheKey: buildMaterialCacheKey(
          material: material,
          category: category,
          subcategory: subcategory,
          lang: lang,
        ),
      );
    }
  }

  Future<DisposalInstructionResolution?> _loadFromFirestoreCache({
    required String materialId,
    required String material,
    String? category,
    String? subcategory,
  }) async {
    final collection =
        _firestore.collection(FirestoreCollections.disposalInstructions);

    final canonicalDoc = await collection.doc(materialId).get();
    if (canonicalDoc.exists) {
      final data = canonicalDoc.data()!;
      return DisposalInstructionResolution(
        instructions: _parseFirestoreData(data),
        source: 'cache_firestore_canonical',
        cacheKey: materialId,
        confidence: _extractConfidence(data),
        explanation: _extractExplanation(data),
      );
    }

    final legacyId = buildLegacyMaterialId(material, category, subcategory);
    if (legacyId == materialId) {
      return null;
    }

    final legacyDoc = await collection.doc(legacyId).get();
    if (!legacyDoc.exists) {
      return null;
    }

    WasteAppLogger.info('Disposal instructions loaded via legacy cache key',
        context: {'legacy_key': legacyId, 'canonical_key': materialId});
    final data = legacyDoc.data()!;
    return DisposalInstructionResolution(
      instructions: _parseFirestoreData(data),
      source: 'cache_firestore_legacy',
      cacheKey: materialId,
      confidence: _extractConfidence(data),
      explanation: _extractExplanation(data),
    );
  }

  /// Generate instructions via Cloud Function with 503 retry handling
  Future<DisposalInstructionResolution> _generateViaCloudFunction({
    required String materialId,
    required String material,
    String? category,
    String? subcategory,
    required String lang,
  }) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    final requestBody = {
      'materialId': materialId,
      'material': material,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'lang': lang,
    };

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        WasteAppLogger.info(
            'Disposal instructions API call attempt ${attempt + 1}/${maxRetries + 1}',
            context: {
              'material_id': materialId,
              'material': material,
              'attempt': attempt + 1,
              'max_retries': maxRetries + 1
            });

        final response = await http
            .post(
              Uri.parse(_functionUrl),
              headers: {
                'Content-Type': 'application/json',
              },
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          WasteAppLogger.info('Disposal instructions API call successful',
              context: {
                'material_id': materialId,
                'attempt': attempt + 1,
                'response_length': response.body.length
              });
          final data = json.decode(response.body) as Map<String, dynamic>;
          return DisposalInstructionResolution(
            instructions: _parseCloudFunctionResponse(data),
            source: 'cloud_function',
            cacheKey: materialId,
            confidence: _extractConfidence(data),
            explanation: _extractExplanation(data),
          );
        } else if (response.statusCode == 503) {
          // Server is temporarily unavailable - check for retry-after header
          final retryAfterHeader = response.headers['retry-after'];
          var retryAfterSeconds = 0;

          if (retryAfterHeader != null) {
            retryAfterSeconds = int.tryParse(retryAfterHeader) ?? 0;
          }

          if (attempt < maxRetries) {
            // Calculate delay: use retry-after header if provided, otherwise exponential backoff
            final delay = retryAfterSeconds > 0
                ? Duration(seconds: retryAfterSeconds)
                : Duration(
                    seconds: baseDelay.inSeconds *
                        (1 << attempt)); // Exponential backoff: 1s, 2s, 4s

            WasteAppLogger.warning(
                'Disposal instructions API returned 503, error: retrying');

            await Future.delayed(delay);
            continue; // Retry the request
          } else {
            // Final attempt failed with 503
            WasteAppLogger.severe(
                'Disposal instructions API exhausted retries with 503',
                context: {
                  'material_id': materialId,
                  'total_attempts': attempt + 1,
                  'final_status_code': response.statusCode,
                  'response_body': response.body,
                  'action': 'falling_back_to_default'
                });
            throw Exception(
                'Service temporarily unavailable after ${attempt + 1} attempts: ${response.body}');
          }
        } else {
          // Non-retryable error (4xx, 5xx except 503)
          WasteAppLogger.severe(
              'Disposal instructions API returned non-retryable error',
              context: {
                'material_id': materialId,
                'attempt': attempt + 1,
                'status_code': response.statusCode,
                'response_body': response.body,
                'action': 'failing_immediately'
              });
          throw Exception(
              'Cloud Function returned ${response.statusCode}: ${response.body}');
        }
      } catch (e, stackTrace) {
        if (e.toString().contains('Service temporarily unavailable')) {
          // Re-throw 503 exhaustion errors
          rethrow;
        }

        // Handle other exceptions (network errors, timeouts, etc.)
        if (attempt < maxRetries) {
          final delay = Duration(seconds: baseDelay.inSeconds * (1 << attempt));
          WasteAppLogger.warning(
              'Disposal instructions API call failed with exception, retrying',
              error: e,
              stackTrace: stackTrace);
          await Future.delayed(delay);
          continue;
        } else {
          WasteAppLogger.severe(
              'Disposal instructions API exhausted retries with exception',
              error: e,
              stackTrace: stackTrace,
              context: {
                'material_id': materialId,
                'total_attempts': attempt + 1,
                'exception_type': e.runtimeType.toString(),
                'action': 'falling_back_to_default'
              });
          rethrow;
        }
      }
    }

    // This should never be reached due to the loop structure, but added for completeness
    throw Exception('Unexpected end of retry loop');
  }

  /// Parse Cloud Function response to DisposalInstructions
  DisposalInstructions _parseCloudFunctionResponse(Map<String, dynamic> data) {
    return DisposalInstructions(
      primaryMethod: data['primaryMethod'] ?? 'Review required',
      steps: _parseSteps(data['steps']),
      timeframe: data['timeframe'],
      location: data['location'],
      warnings: _parseStringList(data['warnings']),
      tips: _parseStringList(data['tips']),
      recyclingInfo: data['recyclingInfo'],
      estimatedTime: data['estimatedTime'],
      hasUrgentTimeframe: data['hasUrgentTimeframe'] ?? false,
    );
  }

  double? _extractConfidence(Map<String, dynamic> data) {
    final value = data['confidence'] ?? data['confidenceScore'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _extractExplanation(Map<String, dynamic> data) {
    final value = data['explanation'] ?? data['reasoning'] ?? data['rationale'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  /// Parse Firestore data to DisposalInstructions
  DisposalInstructions _parseFirestoreData(Map<String, dynamic> data) {
    return DisposalInstructions(
      primaryMethod: data['primaryMethod'] ?? 'Review required',
      steps: _parseSteps(data['steps']),
      timeframe: data['timeframe'],
      location: data['location'],
      warnings: _parseStringList(data['warnings']),
      tips: _parseStringList(data['tips']),
      recyclingInfo: data['recyclingInfo'],
      estimatedTime: data['estimatedTime'],
      hasUrgentTimeframe: data['hasUrgentTimeframe'] ?? false,
    );
  }

  /// Parse steps from various formats
  List<String> _parseSteps(dynamic stepsData) {
    if (stepsData == null) return ['Please review manually'];

    if (stepsData is List) {
      return List<String>.from(stepsData);
    }

    if (stepsData is String) {
      // Handle various string formats
      if (stepsData.contains('\n')) {
        return stepsData
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (stepsData.contains(',')) {
        return stepsData
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        return [stepsData];
      }
    }

    return ['Please review manually'];
  }

  /// Parse string list from various formats
  List<String>? _parseStringList(dynamic listData) {
    if (listData == null) return null;

    if (listData is List) {
      return List<String>.from(listData);
    }

    if (listData is String) {
      if (listData.trim().isEmpty) return null;
      return _parseSteps(listData);
    }

    return null;
  }

  /// Get fallback instructions when AI generation fails
  DisposalInstructions _getFallbackInstructions(
      String material, String? category) {
    // Use existing category-based fallbacks
    switch (category?.toLowerCase()) {
      case 'wet waste':
        return DisposalInstructions(
          primaryMethod: 'Compost or wet waste bin',
          steps: [
            'Remove any non-biodegradable packaging',
            'Place in designated wet waste bin',
            'Ensure proper drainage to avoid odors',
            'Collect daily for municipal pickup'
          ],
          timeframe: 'Daily collection',
          location: 'Wet waste bin',
          tips: ['Keep bin covered', 'Drain excess liquids'],
          hasUrgentTimeframe: false,
        );
      case 'dry waste':
        return DisposalInstructions(
          primaryMethod: 'Recycle or dry waste bin',
          steps: [
            'Clean and dry the item',
            'Remove any labels if possible',
            'Sort by material type if required',
            'Place in dry waste bin'
          ],
          timeframe: 'Weekly collection',
          location: 'Dry waste bin or recycling center',
          tips: [
            'Clean items recycle better',
            'Sort by material when possible'
          ],
          hasUrgentTimeframe: false,
        );
      case 'hazardous waste':
        return DisposalInstructions(
          primaryMethod: 'Special disposal facility',
          steps: [
            'Do not mix with regular waste',
            'Store safely until disposal',
            'Take to designated hazardous waste facility',
            'Follow facility-specific guidelines'
          ],
          timeframe: 'As soon as possible',
          location: 'Hazardous waste collection center',
          warnings: [
            'Never dispose in regular bins',
            'Can contaminate other waste'
          ],
          hasUrgentTimeframe: true,
        );
      default:
        return DisposalInstructions(
          primaryMethod: 'Review disposal method',
          steps: [
            'Identify the correct waste category for this item',
            'Clean the item if required',
            'Place in appropriate disposal bin',
            'Follow local waste management guidelines'
          ],
          timeframe: 'When convenient',
          location: 'Appropriate waste bin',
          hasUrgentTimeframe: false,
        );
    }
  }

  /// Clear the local cache
  void clearCache() {
    _cache.clear();
  }

  /// Preload instructions for common materials
  Future<void> preloadCommonMaterials() async {
    final commonMaterials = [
      {'material': 'plastic bottle', 'category': 'dry waste'},
      {'material': 'food scraps', 'category': 'wet waste'},
      {'material': 'battery', 'category': 'hazardous waste'},
      {'material': 'paper', 'category': 'dry waste'},
      {'material': 'glass jar', 'category': 'dry waste'},
    ];

    for (final item in commonMaterials) {
      try {
        await getDisposalInstructions(
          material: item['material']!,
          category: item['category'],
        );
      } catch (e) {
        WasteAppLogger.warning('Failed to preload disposal instructions',
            error: e,
            context: {
              'material': item['material'],
              'action': 'continue_preloading'
            });
      }
    }
  }
}
