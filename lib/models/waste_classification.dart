import 'package:flutter/foundation.dart';

/// Represents a waste classification result with comprehensive disposal information
class WasteClassification {
  final String itemName;
  final String category;
  final String? subcategory;
  final String? materialType;
  final int? recyclingCode;
  final String explanation;
  final String? disposalMethod;
  final DisposalInstructions disposalInstructions;

  // Location and guidelines
  final String region;
  final String? localGuidelinesReference;

  // Image and visual data
  final String? imageUrl;
  final String? imageHash;
  final Map<String, double>? imageMetrics;
  final List<String> visualFeatures;

  // Waste properties
  final bool? isRecyclable;
  final bool? isCompostable;
  final bool? requiresSpecialDisposal;
  final String? colorCode;
  final String? riskLevel;
  final List<String>? requiredPPE;

  // Product identification
  final String? brand;
  final String? product;
  final String? barcode;

  // User interaction data
  final bool? isSaved;
  final bool? userConfirmed;
  final String? userCorrection;
  final String? disagreementReason;
  final String? userNotes;
  final int? viewCount;
  final bool? clarificationNeeded;

  // AI model performance data
  final double? confidence;
  final String? modelVersion;
  final int? processingTimeMs;
  final String? modelSource;
  final String? analysisSessionId;

  // Alternative classifications and actions
  final List<AlternativeClassification> alternatives;
  final String? suggestedAction;
  final bool? hasUrgentTimeframe;

  // Multilingual support
  final String? instructionsLang;
  final Map<String, String>? translatedInstructions;

  // Processing context
  final String? source;
  final DateTime timestamp;

  WasteClassification({
    required this.itemName,
    required this.category,
    this.subcategory,
    this.materialType,
    this.recyclingCode,
    required this.explanation,
    this.disposalMethod,
    required this.disposalInstructions,
    required this.region,
    this.localGuidelinesReference,
    this.imageUrl,
    this.imageHash,
    this.imageMetrics,
    required this.visualFeatures,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.colorCode,
    this.riskLevel,
    this.requiredPPE,
    this.brand,
    this.product,
    this.barcode,
    this.isSaved,
    this.userConfirmed,
    this.userCorrection,
    this.disagreementReason,
    this.userNotes,
    this.viewCount,
    this.clarificationNeeded,
    this.confidence,
    this.modelVersion,
    this.processingTimeMs,
    this.modelSource,
    this.analysisSessionId,
    required this.alternatives,
    this.suggestedAction,
    this.hasUrgentTimeframe,
    this.instructionsLang,
    this.translatedInstructions,
    this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a fallback classification when AI analysis fails
  factory WasteClassification.fallback(String imagePath) {
    return WasteClassification(
      itemName: 'Unknown Item',
      category: 'Dry Waste',
      subcategory: 'Other Dry Waste',
      explanation: 'Unable to classify this item automatically. Please review and correct if needed.',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Manual review required',
        steps: ['Please review the item manually', 'Consult local waste guidelines'],
        hasUrgentTimeframe: false,
      ),
      region: 'Unknown',
      visualFeatures: [],
      alternatives: [],
      imageUrl: imagePath,
      confidence: 0.0,
      clarificationNeeded: true,
      riskLevel: 'safe',
    );
  }

  /// Creates a WasteClassification from JSON data
  factory WasteClassification.fromJson(Map<String, dynamic> json) {
    return WasteClassification(
      itemName: json['itemName'] ?? 'Unknown Item',
      category: json['category'] ?? 'Dry Waste',
      subcategory: json['subcategory'],
      materialType: json['materialType'],
      recyclingCode: json['recyclingCode'],
      explanation: json['explanation'] ?? '',
      disposalMethod: json['disposalMethod'],
      disposalInstructions: json['disposalInstructions'] != null
          ? DisposalInstructions.fromJson(json['disposalInstructions'])
          : DisposalInstructions(
              primaryMethod: 'Review required',
              steps: ['Please review manually'],
              hasUrgentTimeframe: false,
            ),
      region: json['region'] ?? 'Unknown',
      localGuidelinesReference: json['localGuidelinesReference'],
      imageUrl: json['imageUrl'],
      imageHash: json['imageHash'],
      imageMetrics: json['imageMetrics'] != null
          ? Map<String, double>.from(json['imageMetrics'])
          : null,
      visualFeatures: json['visualFeatures'] != null
          ? List<String>.from(json['visualFeatures'])
          : [],
      isRecyclable: json['isRecyclable'],
      isCompostable: json['isCompostable'],
      requiresSpecialDisposal: json['requiresSpecialDisposal'],
      colorCode: json['colorCode'],
      riskLevel: json['riskLevel'],
      requiredPPE: json['requiredPPE'] != null
          ? List<String>.from(json['requiredPPE'])
          : null,
      brand: json['brand'],
      product: json['product'],
      barcode: json['barcode'],
      isSaved: json['isSaved'],
      userConfirmed: json['userConfirmed'],
      userCorrection: json['userCorrection'],
      disagreementReason: json['disagreementReason'],
      userNotes: json['userNotes'],
      viewCount: json['viewCount'],
      clarificationNeeded: json['clarificationNeeded'],
      confidence: json['confidence']?.toDouble(),
      modelVersion: json['modelVersion'],
      processingTimeMs: json['processingTimeMs'],
      modelSource: json['modelSource'],
      analysisSessionId: json['analysisSessionId'],
      alternatives: json['alternatives'] != null
          ? (json['alternatives'] as List)
              .map((alt) => AlternativeClassification.fromJson(alt))
              .toList()
          : [],
      suggestedAction: json['suggestedAction'],
      hasUrgentTimeframe: json['hasUrgentTimeframe'],
      instructionsLang: json['instructionsLang'],
      translatedInstructions: json['translatedInstructions'] != null
          ? Map<String, String>.from(json['translatedInstructions'])
          : null,
      source: json['source'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Converts the classification to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'category': category,
      'subcategory': subcategory,
      'materialType': materialType,
      'recyclingCode': recyclingCode,
      'explanation': explanation,
      'disposalMethod': disposalMethod,
      'disposalInstructions': disposalInstructions.toJson(),
      'region': region,
      'localGuidelinesReference': localGuidelinesReference,
      'imageUrl': imageUrl,
      'imageHash': imageHash,
      'imageMetrics': imageMetrics,
      'visualFeatures': visualFeatures,
      'isRecyclable': isRecyclable,
      'isCompostable': isCompostable,
      'requiresSpecialDisposal': requiresSpecialDisposal,
      'colorCode': colorCode,
      'riskLevel': riskLevel,
      'requiredPPE': requiredPPE,
      'brand': brand,
      'product': product,
      'barcode': barcode,
      'isSaved': isSaved,
      'userConfirmed': userConfirmed,
      'userCorrection': userCorrection,
      'disagreementReason': disagreementReason,
      'userNotes': userNotes,
      'viewCount': viewCount,
      'clarificationNeeded': clarificationNeeded,
      'confidence': confidence,
      'modelVersion': modelVersion,
      'processingTimeMs': processingTimeMs,
      'modelSource': modelSource,
      'analysisSessionId': analysisSessionId,
      'alternatives': alternatives.map((alt) => alt.toJson()).toList(),
      'suggestedAction': suggestedAction,
      'hasUrgentTimeframe': hasUrgentTimeframe,
      'instructionsLang': instructionsLang,
      'translatedInstructions': translatedInstructions,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields
  WasteClassification copyWith({
    String? itemName,
    String? category,
    String? subcategory,
    String? materialType,
    int? recyclingCode,
    String? explanation,
    String? disposalMethod,
    DisposalInstructions? disposalInstructions,
    String? region,
    String? localGuidelinesReference,
    String? imageUrl,
    String? imageHash,
    Map<String, double>? imageMetrics,
    List<String>? visualFeatures,
    bool? isRecyclable,
    bool? isCompostable,
    bool? requiresSpecialDisposal,
    String? colorCode,
    String? riskLevel,
    List<String>? requiredPPE,
    String? brand,
    String? product,
    String? barcode,
    bool? isSaved,
    bool? userConfirmed,
    String? userCorrection,
    String? disagreementReason,
    String? userNotes,
    int? viewCount,
    bool? clarificationNeeded,
    double? confidence,
    String? modelVersion,
    int? processingTimeMs,
    String? modelSource,
    String? analysisSessionId,
    List<AlternativeClassification>? alternatives,
    String? suggestedAction,
    bool? hasUrgentTimeframe,
    String? instructionsLang,
    Map<String, String>? translatedInstructions,
    String? source,
    DateTime? timestamp,
  }) {
    return WasteClassification(
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      materialType: materialType ?? this.materialType,
      recyclingCode: recyclingCode ?? this.recyclingCode,
      explanation: explanation ?? this.explanation,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      disposalInstructions: disposalInstructions ?? this.disposalInstructions,
      region: region ?? this.region,
      localGuidelinesReference: localGuidelinesReference ?? this.localGuidelinesReference,
      imageUrl: imageUrl ?? this.imageUrl,
      imageHash: imageHash ?? this.imageHash,
      imageMetrics: imageMetrics ?? this.imageMetrics,
      visualFeatures: visualFeatures ?? this.visualFeatures,
      isRecyclable: isRecyclable ?? this.isRecyclable,
      isCompostable: isCompostable ?? this.isCompostable,
      requiresSpecialDisposal: requiresSpecialDisposal ?? this.requiresSpecialDisposal,
      colorCode: colorCode ?? this.colorCode,
      riskLevel: riskLevel ?? this.riskLevel,
      requiredPPE: requiredPPE ?? this.requiredPPE,
      brand: brand ?? this.brand,
      product: product ?? this.product,
      barcode: barcode ?? this.barcode,
      isSaved: isSaved ?? this.isSaved,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      userCorrection: userCorrection ?? this.userCorrection,
      disagreementReason: disagreementReason ?? this.disagreementReason,
      userNotes: userNotes ?? this.userNotes,
      viewCount: viewCount ?? this.viewCount,
      clarificationNeeded: clarificationNeeded ?? this.clarificationNeeded,
      confidence: confidence ?? this.confidence,
      modelVersion: modelVersion ?? this.modelVersion,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      modelSource: modelSource ?? this.modelSource,
      analysisSessionId: analysisSessionId ?? this.analysisSessionId,
      alternatives: alternatives ?? this.alternatives,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      hasUrgentTimeframe: hasUrgentTimeframe ?? this.hasUrgentTimeframe,
      instructionsLang: instructionsLang ?? this.instructionsLang,
      translatedInstructions: translatedInstructions ?? this.translatedInstructions,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Alternative classification suggestion
class AlternativeClassification {
  final String category;
  final String? subcategory;
  final double confidence;
  final String reason;

  AlternativeClassification({
    required this.category,
    this.subcategory,
    required this.confidence,
    required this.reason,
  });

  factory AlternativeClassification.fromJson(Map<String, dynamic> json) {
    return AlternativeClassification(
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'confidence': confidence,
      'reason': reason,
    };
  }
}

/// Detailed disposal instructions
class DisposalInstructions {
  final String primaryMethod;
  final List<String> steps;
  final String? timeframe;
  final String? location;
  final List<String>? warnings;
  final List<String>? tips;
  final String? recyclingInfo;
  final String? estimatedTime;
  final bool hasUrgentTimeframe;

  DisposalInstructions({
    required this.primaryMethod,
    required this.steps,
    this.timeframe,
    this.location,
    this.warnings,
    this.tips,
    this.recyclingInfo,
    this.estimatedTime,
    required this.hasUrgentTimeframe,
  });

  factory DisposalInstructions.fromJson(Map<String, dynamic> json) {
    return DisposalInstructions(
      primaryMethod: json['primaryMethod'] ?? 'Review required',
      steps: json['steps'] != null
          ? List<String>.from(json['steps'])
          : ['Please review manually'],
      timeframe: json['timeframe'],
      location: json['location'],
      warnings: json['warnings'] != null
          ? List<String>.from(json['warnings'])
          : null,
      tips: json['tips'] != null
          ? List<String>.from(json['tips'])
          : null,
      recyclingInfo: json['recyclingInfo'],
      estimatedTime: json['estimatedTime'],
      hasUrgentTimeframe: json['hasUrgentTimeframe'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryMethod': primaryMethod,
      'steps': steps,
      'timeframe': timeframe,
      'location': location,
      'warnings': warnings,
      'tips': tips,
      'recyclingInfo': recyclingInfo,
      'estimatedTime': estimatedTime,
      'hasUrgentTimeframe': hasUrgentTimeframe,
    };
  }
}

// Enum to define waste categories
enum WasteCategory {
  wet,
  dry,
  hazardous,
  medical,
  nonWaste,
}

// Enum to define wet waste subcategories
enum WetWasteSubcategory {
  foodWaste,
  gardenWaste,
  animalWaste,
  biodegradablePacking,
  other,
}

// Enum to define dry waste subcategories
enum DryWasteSubcategory {
  paper,
  plastic,
  glass,
  metal,
  carton,
  textile,
  rubber,
  wood,
  other,
}

// Enum to define hazardous waste subcategories
enum HazardousWasteSubcategory {
  electronic,
  battery,
  chemical,
  paint,
  lightBulb,
  aerosol,
  automotive,
  other,
}

// Enum to define medical waste subcategories
enum MedicalWasteSubcategory {
  sharps,
  pharmaceutical,
  infectious,
  nonInfectious,
  other,
}

// Enum to define non-waste subcategories
enum NonWasteSubcategory {
  reusable,
  donatable,
  edible,
  repurposable,
  other,
}

// Extension to get readable names and descriptions for categories
extension WasteCategoryExtension on WasteCategory {
  String get name {
    switch (this) {
      case WasteCategory.wet:
        return 'Wet Waste';
      case WasteCategory.dry:
        return 'Dry Waste';
      case WasteCategory.hazardous:
        return 'Hazardous Waste';
      case WasteCategory.medical:
        return 'Medical Waste';
      case WasteCategory.nonWaste:
        return 'Non-Waste';
    }
  }

  String get description {
    switch (this) {
      case WasteCategory.wet:
        return 'Biodegradable waste like food scraps and plant materials that can be composted.';
      case WasteCategory.dry:
        return 'Recyclable materials like paper, plastic, glass, and metal that can be processed and reused.';
      case WasteCategory.hazardous:
        return 'Materials that are potentially dangerous to humans or the environment and require special handling.';
      case WasteCategory.medical:
        return 'Waste generated from medical treatments, diagnoses, or immunizations that may be contaminated.';
      case WasteCategory.nonWaste:
        return 'Items that are not waste and can be reused or repurposed.';
    }
  }

  String get color {
    switch (this) {
      case WasteCategory.wet:
        return '#4CAF50'; // Green
      case WasteCategory.dry:
        return '#2196F3'; // Blue
      case WasteCategory.hazardous:
        return '#FF5722'; // Deep Orange
      case WasteCategory.medical:
        return '#F44336'; // Red
      case WasteCategory.nonWaste:
        return '#9C27B0'; // Purple
    }
  }
}

// Extension for wet waste subcategories
extension WetWasteSubcategoryExtension on WetWasteSubcategory {
  String get name {
    switch (this) {
      case WetWasteSubcategory.foodWaste:
        return 'Food Waste';
      case WetWasteSubcategory.gardenWaste:
        return 'Garden Waste';
      case WetWasteSubcategory.animalWaste:
        return 'Animal Waste';
      case WetWasteSubcategory.biodegradablePacking:
        return 'Biodegradable Packaging';
      case WetWasteSubcategory.other:
        return 'Other Wet Waste';
    }
  }

  String get color {
    return '#4CAF50'; // Green (same as parent category)
  }
}

// Extension for dry waste subcategories
extension DryWasteSubcategoryExtension on DryWasteSubcategory {
  String get name {
    switch (this) {
      case DryWasteSubcategory.paper:
        return 'Paper';
      case DryWasteSubcategory.plastic:
        return 'Plastic';
      case DryWasteSubcategory.glass:
        return 'Glass';
      case DryWasteSubcategory.metal:
        return 'Metal';
      case DryWasteSubcategory.carton:
        return 'Carton';
      case DryWasteSubcategory.textile:
        return 'Textile';
      case DryWasteSubcategory.rubber:
        return 'Rubber';
      case DryWasteSubcategory.wood:
        return 'Wood';
      case DryWasteSubcategory.other:
        return 'Other Dry Waste';
    }
  }

  String get color {
    switch (this) {
      case DryWasteSubcategory.paper:
        return '#90CAF9'; // Light Blue
      case DryWasteSubcategory.plastic:
        return '#2196F3'; // Blue
      case DryWasteSubcategory.glass:
        return '#1976D2'; // Dark Blue
      case DryWasteSubcategory.metal:
        return '#0D47A1'; // Deep Blue
      case DryWasteSubcategory.carton:
        return '#64B5F6'; // Light Blue
      case DryWasteSubcategory.textile:
        return '#42A5F5'; // Blue
      case DryWasteSubcategory.rubber:
        return '#1E88E5'; // Blue
      case DryWasteSubcategory.wood:
        return '#1565C0'; // Dark Blue
      case DryWasteSubcategory.other:
        return '#2196F3'; // Blue (same as parent category)
    }
  }
}

// Extension for hazardous waste subcategories
extension HazardousWasteSubcategoryExtension on HazardousWasteSubcategory {
  String get name {
    switch (this) {
      case HazardousWasteSubcategory.electronic:
        return 'Electronic Waste';
      case HazardousWasteSubcategory.battery:
        return 'Batteries';
      case HazardousWasteSubcategory.chemical:
        return 'Chemical Waste';
      case HazardousWasteSubcategory.paint:
        return 'Paint Waste';
      case HazardousWasteSubcategory.lightBulb:
        return 'Light Bulbs';
      case HazardousWasteSubcategory.aerosol:
        return 'Aerosol Cans';
      case HazardousWasteSubcategory.automotive:
        return 'Automotive Waste';
      case HazardousWasteSubcategory.other:
        return 'Other Hazardous Waste';
    }
  }

  String get color {
    return '#FF5722'; // Deep Orange (same as parent category)
  }
}

// Extension for medical waste subcategories
extension MedicalWasteSubcategoryExtension on MedicalWasteSubcategory {
  String get name {
    switch (this) {
      case MedicalWasteSubcategory.sharps:
        return 'Sharps';
      case MedicalWasteSubcategory.pharmaceutical:
        return 'Pharmaceutical';
      case MedicalWasteSubcategory.infectious:
        return 'Infectious';
      case MedicalWasteSubcategory.nonInfectious:
        return 'Non-Infectious';
      case MedicalWasteSubcategory.other:
        return 'Other Medical Waste';
    }
  }

  String get color {
    return '#F44336'; // Red (same as parent category)
  }
}

// Extension for non-waste subcategories
extension NonWasteSubcategoryExtension on NonWasteSubcategory {
  String get name {
    switch (this) {
      case NonWasteSubcategory.reusable:
        return 'Reusable Items';
      case NonWasteSubcategory.donatable:
        return 'Donatable Items';
      case NonWasteSubcategory.edible:
        return 'Edible Food';
      case NonWasteSubcategory.repurposable:
        return 'Repurposable Items';
      case NonWasteSubcategory.other:
        return 'Other Non-Waste';
    }
  }

  String get color {
    return '#9C27B0'; // Purple (same as parent category)
  }
}