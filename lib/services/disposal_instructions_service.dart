import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';

/// Service for fetching LLM-generated disposal instructions
class DisposalInstructionsService {
  static const String _functionUrl = 'https://asia-south1-waste-segregation-app-df523.cloudfunctions.net/generateDisposal';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Cache for disposal instructions to avoid repeated API calls
  final Map<String, DisposalInstructions> _cache = {};
  
  /// Generate a unique material ID for caching
  String _generateMaterialId(String material, String? category, String? subcategory) {
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
    try {
      final materialId = _generateMaterialId(material, category, subcategory);
      
      // Check local cache first
      if (_cache.containsKey(materialId)) {
        WasteAppLogger.cacheEvent('cache_hit', 'disposal_instructions', 
          hit: true, 
          key: materialId,
          context: {
            'material': material,
            'category': category,
            'subcategory': subcategory
          }
        );
        return _cache[materialId]!;
      }
      
      // Check Firestore cache
      final cachedDoc = await _firestore
          .collection('disposal_instructions')
          .doc(materialId)
          .get();
      
      if (cachedDoc.exists) {
        WasteAppLogger.cacheEvent('cache_hit', 'disposal_instructions_firestore', 
          hit: true, 
          key: materialId,
          context: {
            'material': material,
            'category': category,
            'subcategory': subcategory,
            'source': 'firestore'
          }
        );
        final instructions = _parseFirestoreData(cachedDoc.data()!);
        _cache[materialId] = instructions;
        return instructions;
      }
      
      // Generate new instructions via Cloud Function
      WasteAppLogger.aiEvent('disposal_instructions_generation_started', 
        context: {
          'material_id': materialId,
          'material': material,
          'category': category,
          'subcategory': subcategory,
          'language': lang
        }
      );
      final instructions = await _generateViaCloudFunction(
        materialId: materialId,
        material: material,
        category: category,
        subcategory: subcategory,
        lang: lang,
      );
      
      _cache[materialId] = instructions;
      return instructions;
      
    } catch (e) {
      WasteAppLogger.severe('Error fetching disposal instructions', e, null, {
        'material': material,
        'category': category,
        'subcategory': subcategory,
        'language': lang,
        'action': 'fallback_to_default_instructions'
      });
      return _getFallbackInstructions(material, category);
    }
  }
  
  /// Generate instructions via Cloud Function
  Future<DisposalInstructions> _generateViaCloudFunction({
    required String materialId,
    required String material,
    String? category,
    String? subcategory,
    required String lang,
  }) async {
    final requestBody = {
      'materialId': materialId,
      'material': material,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'lang': lang,
    };
    
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parseCloudFunctionResponse(data);
    } else {
      throw Exception('Cloud Function returned ${response.statusCode}: ${response.body}');
    }
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
        return stepsData.split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (stepsData.contains(',')) {
        return stepsData.split(',')
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
  DisposalInstructions _getFallbackInstructions(String material, String? category) {
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
          tips: ['Clean items recycle better', 'Sort by material when possible'],
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
          warnings: ['Never dispose in regular bins', 'Can contaminate other waste'],
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
        WasteAppLogger.warning('Failed to preload disposal instructions', e, null, {
          'material': item['material'],
          'action': 'continue_preloading'
        });
      }
    }
  }
} 