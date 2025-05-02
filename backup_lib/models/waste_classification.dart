class WasteClassification {
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
  final String? colorCode; // Added for color-coding representation
  final String? materialType; // Added for material type identification

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
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

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
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Factory constructor to create a model from JSON
  factory WasteClassification.fromJson(Map<String, dynamic> json) {
    return WasteClassification(
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      explanation: json['explanation'] ?? '',
      imageUrl: json['imageUrl'],
      disposalMethod: json['disposalMethod'],
      recyclingCode: json['recyclingCode'],
      isRecyclable: json['isRecyclable'],
      isCompostable: json['isCompostable'],
      requiresSpecialDisposal: json['requiresSpecialDisposal'],
      colorCode: json['colorCode'],
      materialType: json['materialType'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
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