import 'disposal_instructions.dart';

class WasteClassification {
  // Core classification data
  final String itemName;
  final String category;
  final String? subcategory;
  final String explanation;
  final String? imageUrl;
  final String? disposalMethod;
  final String? recyclingCode;
  final DateTime timestamp;
  final bool? isRecyclable;
  final bool? isCompostable;
  final bool? requiresSpecialDisposal;
  final String? colorCode;
  final String? materialType;
  bool isSaved;

  // Disposal instructions
  final DisposalInstructions? disposalInstructions;

  // AI Model Performance Data
  final double? confidence; // 0.0 to 1.0 - AI classification confidence
  final String? modelVersion; // Which AI model version was used
  final int? processingTimeMs; // Processing time in milliseconds
  final List<AlternativeClassification>? alternatives; // Alternative classifications

  // User Interaction Data
  final bool? userConfirmed; // Did user confirm this classification?
  final String? userCorrection; // What did user change it to?
  final String? userNotes; // User's personal notes
  final int? viewCount; // How many times viewed

  // Processing Context
  final String? source; // 'camera', 'gallery', 'web_upload'
  final Map<String, double>? imageMetrics; // blur, brightness, contrast scores
  final String? imageHash; // For deduplication and caching

  WasteClassification({
    required this.itemName,
    required this.category,
    this.subcategory,
    required this.explanation,
    this.imageUrl,
    this.disposalMethod,
    this.recyclingCode,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.colorCode,
    this.materialType,
    this.isSaved = false,
    DateTime? timestamp,
    // Disposal instructions
    this.disposalInstructions,
    // AI Model Performance Data
    this.confidence,
    this.modelVersion,
    this.processingTimeMs,
    this.alternatives,
    // User Interaction Data
    this.userConfirmed,
    this.userCorrection,
    this.userNotes,
    this.viewCount,
    // Processing Context
    this.source,
    this.imageMetrics,
    this.imageHash,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Generate disposal instructions for this classification
  WasteClassification withDisposalInstructions() {
    final instructions = DisposalInstructionsGenerator.generateForItem(
      category: category,
      subcategory: subcategory,
      materialType: materialType,
      isRecyclable: isRecyclable,
      isCompostable: isCompostable,
      requiresSpecialDisposal: requiresSpecialDisposal,
    );
    
    return WasteClassification(
      itemName: itemName,
      category: category,
      subcategory: subcategory,
      explanation: explanation,
      imageUrl: imageUrl,
      disposalMethod: disposalMethod,
      recyclingCode: recyclingCode,
      isRecyclable: isRecyclable,
      isCompostable: isCompostable,
      requiresSpecialDisposal: requiresSpecialDisposal,
      colorCode: colorCode,
      materialType: materialType,
      isSaved: isSaved,
      timestamp: timestamp,
      confidence: confidence,
      modelVersion: modelVersion,
      processingTimeMs: processingTimeMs,
      alternatives: alternatives,
      userConfirmed: userConfirmed,
      userCorrection: userCorrection,
      userNotes: userNotes,
      viewCount: viewCount,
      source: source,
      imageMetrics: imageMetrics,
      imageHash: imageHash,
      disposalInstructions: instructions,
    );
  }

  /// Check if this item has urgent disposal requirements
  bool get hasUrgentDisposal {
    return disposalInstructions?.hasUrgentTimeframe ?? false ||
           requiresSpecialDisposal == true ||
           category.toLowerCase() == 'medical waste' ||
           category.toLowerCase() == 'hazardous waste';
  }

  /// Get the estimated time needed for proper disposal
  Duration get estimatedDisposalTime {
    return disposalInstructions?.estimatedTotalTime ?? Duration(minutes: 5);
  }

  // Method to convert model to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'category': category,
      'subcategory': subcategory,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'disposalMethod': disposalMethod,
      'recyclingCode': recyclingCode,
      'isRecyclable': isRecyclable,
      'isCompostable': isCompostable,
      'requiresSpecialDisposal': requiresSpecialDisposal,
      'colorCode': colorCode,
      'materialType': materialType,
      'isSaved': isSaved,
      'timestamp': timestamp.toIso8601String(),
      // AI Model Performance Data
      'confidence': confidence,
      'modelVersion': modelVersion,
      'processingTimeMs': processingTimeMs,
      'alternatives': alternatives?.map((alt) => alt.toJson()).toList(),
      // User Interaction Data
      'userConfirmed': userConfirmed,
      'userCorrection': userCorrection,
      'userNotes': userNotes,
      'viewCount': viewCount,
      // Processing Context
      'source': source,
      'imageMetrics': imageMetrics,
      'imageHash': imageHash,
      // Disposal instructions
      'disposalInstructions': disposalInstructions?.toJson(),
    };
  }

  // Factory constructor to create a model from JSON
  factory WasteClassification.fromJson(Map<String, dynamic> json) {
    // Handle different data types for recyclingCode
    String? recyclingCode;
    if (json['recyclingCode'] != null) {
      recyclingCode = json['recyclingCode'].toString();
    }
    
    // Parse alternatives if present
    List<AlternativeClassification>? alternatives;
    if (json['alternatives'] != null) {
      alternatives = (json['alternatives'] as List)
          .map((alt) => AlternativeClassification.fromJson(alt))
          .toList();
    }
    
    // Parse imageMetrics if present
    Map<String, double>? imageMetrics;
    if (json['imageMetrics'] != null) {
      imageMetrics = Map<String, double>.from(json['imageMetrics']);
    }
    
    // Parse disposal instructions if present
    DisposalInstructions? disposalInstructions;
    if (json['disposalInstructions'] != null) {
      disposalInstructions = DisposalInstructions.fromJson(json['disposalInstructions']);
    }
    
    return WasteClassification(
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      explanation: json['explanation'] ?? '',
      imageUrl: json['imageUrl'],
      disposalMethod: json['disposalMethod'],
      recyclingCode: recyclingCode,
      isRecyclable: json['isRecyclable'],
      isCompostable: json['isCompostable'],
      requiresSpecialDisposal: json['requiresSpecialDisposal'],
      colorCode: json['colorCode'],
      materialType: json['materialType'],
      isSaved: json['isSaved'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      // AI Model Performance Data
      confidence: json['confidence']?.toDouble(),
      modelVersion: json['modelVersion'],
      processingTimeMs: json['processingTimeMs'],
      alternatives: alternatives,
      // User Interaction Data
      userConfirmed: json['userConfirmed'],
      userCorrection: json['userCorrection'],
      userNotes: json['userNotes'],
      viewCount: json['viewCount'],
      // Processing Context
      source: json['source'],
      imageMetrics: imageMetrics,
      imageHash: json['imageHash'],
      // Disposal instructions
      disposalInstructions: disposalInstructions,
    );
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

/// Alternative classification suggestion from AI model
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

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'confidence': confidence,
      'reason': reason,
    };
  }

  factory AlternativeClassification.fromJson(Map<String, dynamic> json) {
    return AlternativeClassification(
      category: json['category'],
      subcategory: json['subcategory'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
    );
  }
}