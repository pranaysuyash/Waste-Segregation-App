import 'package:flutter/material.dart';

/// Represents a single step in the disposal process
class DisposalStep {
  final String instruction;
  final IconData icon;
  final bool isOptional;
  final String? additionalInfo;
  final String? warningMessage;
  final Duration? estimatedTime;

  const DisposalStep({
    required this.instruction,
    required this.icon,
    this.isOptional = false,
    this.additionalInfo,
    this.warningMessage,
    this.estimatedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'icon': icon.codePoint,
      'isOptional': isOptional,
      'additionalInfo': additionalInfo,
      'warningMessage': warningMessage,
      'estimatedTimeMinutes': estimatedTime?.inMinutes,
    };
  }

  factory DisposalStep.fromJson(Map<String, dynamic> json) {
    return DisposalStep(
      instruction: json['instruction'] ?? '',
      icon: IconData(json['icon'] ?? Icons.check_circle.codePoint, fontFamily: 'MaterialIcons'),
      isOptional: json['isOptional'] ?? false,
      additionalInfo: json['additionalInfo'],
      warningMessage: json['warningMessage'],
      estimatedTime: json['estimatedTimeMinutes'] != null 
          ? Duration(minutes: json['estimatedTimeMinutes']) 
          : null,
    );
  }
}

/// Represents a safety warning for disposal
class SafetyWarning {
  final String message;
  final IconData icon;
  final SafetyLevel level;

  const SafetyWarning({
    required this.message,
    required this.icon,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'icon': icon.codePoint,
      'level': level.toString(),
    };
  }

  factory SafetyWarning.fromJson(Map<String, dynamic> json) {
    return SafetyWarning(
      message: json['message'] ?? '',
      icon: IconData(json['icon'] ?? Icons.warning.codePoint, fontFamily: 'MaterialIcons'),
      level: SafetyLevel.values.firstWhere(
        (level) => level.toString() == json['level'],
        orElse: () => SafetyLevel.low,
      ),
    );
  }
}

/// Safety levels for warnings
enum SafetyLevel {
  low,
  medium,
  high,
  critical;

  Color get color {
    switch (this) {
      case SafetyLevel.low:
        return Colors.blue;
      case SafetyLevel.medium:
        return Colors.orange;
      case SafetyLevel.high:
        return Colors.red;
      case SafetyLevel.critical:
        return Colors.red.shade900;
    }
  }

  String get label {
    switch (this) {
      case SafetyLevel.low:
        return 'Info';
      case SafetyLevel.medium:
        return 'Caution';
      case SafetyLevel.high:
        return 'Warning';
      case SafetyLevel.critical:
        return 'Danger';
    }
  }
}

/// Represents a location where items can be disposed
class DisposalLocation {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final List<String> acceptedWasteTypes;
  final Map<String, String> operatingHours; // day -> hours
  final String? phoneNumber;
  final String? website;
  final List<String> specialInstructions;
  final bool requiresAppointment;
  final bool isGovernmentFacility;
  final DisposalLocationType type;

  const DisposalLocation({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.acceptedWasteTypes,
    required this.operatingHours,
    this.phoneNumber,
    this.website,
    this.specialInstructions = const [],
    this.requiresAppointment = false,
    this.isGovernmentFacility = false,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'acceptedWasteTypes': acceptedWasteTypes,
      'operatingHours': operatingHours,
      'phoneNumber': phoneNumber,
      'website': website,
      'specialInstructions': specialInstructions,
      'requiresAppointment': requiresAppointment,
      'isGovernmentFacility': isGovernmentFacility,
      'type': type.toString(),
    };
  }

  factory DisposalLocation.fromJson(Map<String, dynamic> json) {
    return DisposalLocation(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distanceKm: json['distanceKm']?.toDouble(),
      acceptedWasteTypes: List<String>.from(json['acceptedWasteTypes'] ?? []),
      operatingHours: Map<String, String>.from(json['operatingHours'] ?? {}),
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      specialInstructions: List<String>.from(json['specialInstructions'] ?? []),
      requiresAppointment: json['requiresAppointment'] ?? false,
      isGovernmentFacility: json['isGovernmentFacility'] ?? false,
      type: DisposalLocationType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => DisposalLocationType.recyclingCenter,
      ),
    );
  }

  bool get isOpen {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final hours = operatingHours[dayName];
    
    if (hours == null || hours.toLowerCase().contains('closed')) {
      return false;
    }
    
    // Simple hour parsing - could be enhanced
    return true; // Simplified for now
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}

/// Types of disposal locations
enum DisposalLocationType {
  recyclingCenter,
  hazardousWasteFacility,
  compostingCenter,
  retailerDropOff,
  curbsideCollection,
  specialtyProcessor,
  repairShop,
  donationCenter;

  String get displayName {
    switch (this) {
      case DisposalLocationType.recyclingCenter:
        return 'Recycling Center';
      case DisposalLocationType.hazardousWasteFacility:
        return 'Hazardous Waste Facility';
      case DisposalLocationType.compostingCenter:
        return 'Composting Center';
      case DisposalLocationType.retailerDropOff:
        return 'Retailer Drop-off';
      case DisposalLocationType.curbsideCollection:
        return 'Curbside Collection';
      case DisposalLocationType.specialtyProcessor:
        return 'Specialty Processor';
      case DisposalLocationType.repairShop:
        return 'Repair Shop';
      case DisposalLocationType.donationCenter:
        return 'Donation Center';
    }
  }

  IconData get icon {
    switch (this) {
      case DisposalLocationType.recyclingCenter:
        return Icons.recycling;
      case DisposalLocationType.hazardousWasteFacility:
        return Icons.warning;
      case DisposalLocationType.compostingCenter:
        return Icons.eco;
      case DisposalLocationType.retailerDropOff:
        return Icons.store;
      case DisposalLocationType.curbsideCollection:
        return Icons.home;
      case DisposalLocationType.specialtyProcessor:
        return Icons.factory;
      case DisposalLocationType.repairShop:
        return Icons.build;
      case DisposalLocationType.donationCenter:
        return Icons.volunteer_activism;
    }
  }
}

/// Complete disposal instructions for a waste item
class DisposalInstructions {
  final List<DisposalStep> preparationSteps;
  final List<DisposalStep> disposalSteps;
  final List<SafetyWarning> safetyWarnings;
  final List<DisposalLocation> recommendedLocations;
  final String timeframe; // e.g., "Dispose within 24 hours"
  final List<String> commonMistakes;
  final List<String> environmentalBenefits;
  final String? collectionSchedule; // e.g., "Next pickup: Tuesday, 8 AM"
  final bool requiresSpecialHandling;
  final String? alternativeDisposalMethod;

  const DisposalInstructions({
    this.preparationSteps = const [],
    this.disposalSteps = const [],
    this.safetyWarnings = const [],
    this.recommendedLocations = const [],
    this.timeframe = '',
    this.commonMistakes = const [],
    this.environmentalBenefits = const [],
    this.collectionSchedule,
    this.requiresSpecialHandling = false,
    this.alternativeDisposalMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'preparationSteps': preparationSteps.map((step) => step.toJson()).toList(),
      'disposalSteps': disposalSteps.map((step) => step.toJson()).toList(),
      'safetyWarnings': safetyWarnings.map((warning) => warning.toJson()).toList(),
      'recommendedLocations': recommendedLocations.map((location) => location.toJson()).toList(),
      'timeframe': timeframe,
      'commonMistakes': commonMistakes,
      'environmentalBenefits': environmentalBenefits,
      'collectionSchedule': collectionSchedule,
      'requiresSpecialHandling': requiresSpecialHandling,
      'alternativeDisposalMethod': alternativeDisposalMethod,
    };
  }

  factory DisposalInstructions.fromJson(Map<String, dynamic> json) {
    return DisposalInstructions(
      preparationSteps: (json['preparationSteps'] as List?)
          ?.map((step) => DisposalStep.fromJson(step))
          .toList() ?? [],
      disposalSteps: (json['disposalSteps'] as List?)
          ?.map((step) => DisposalStep.fromJson(step))
          .toList() ?? [],
      safetyWarnings: (json['safetyWarnings'] as List?)
          ?.map((warning) => SafetyWarning.fromJson(warning))
          .toList() ?? [],
      recommendedLocations: (json['recommendedLocations'] as List?)
          ?.map((location) => DisposalLocation.fromJson(location))
          .toList() ?? [],
      timeframe: json['timeframe'] ?? '',
      commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
      environmentalBenefits: List<String>.from(json['environmentalBenefits'] ?? []),
      collectionSchedule: json['collectionSchedule'],
      requiresSpecialHandling: json['requiresSpecialHandling'] ?? false,
      alternativeDisposalMethod: json['alternativeDisposalMethod'],
    );
  }

  bool get hasUrgentTimeframe {
    final urgentKeywords = ['immediately', 'within hours', '24 hours', 'asap'];
    return urgentKeywords.any((keyword) => timeframe.toLowerCase().contains(keyword));
  }

  int get totalSteps => preparationSteps.length + disposalSteps.length;

  Duration get estimatedTotalTime {
    final prepTime = preparationSteps
        .where((step) => step.estimatedTime != null)
        .fold(Duration.zero, (total, step) => total + step.estimatedTime!);
    
    final disposalTime = disposalSteps
        .where((step) => step.estimatedTime != null)
        .fold(Duration.zero, (total, step) => total + step.estimatedTime!);
    
    return prepTime + disposalTime;
  }
}

/// Helper class to generate disposal instructions based on waste classification
class DisposalInstructionsGenerator {
  /// Generate disposal instructions based on category and subcategory
  static DisposalInstructions generateForItem({
    required String category,
    String? subcategory,
    String? materialType,
    bool? isRecyclable,
    bool? isCompostable,
    bool? requiresSpecialDisposal,
  }) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return _generateWetWasteInstructions(subcategory, materialType);
      case 'dry waste':
        return _generateDryWasteInstructions(subcategory, materialType, isRecyclable);
      case 'hazardous waste':
        return _generateHazardousWasteInstructions(subcategory, materialType);
      case 'medical waste':
        return _generateMedicalWasteInstructions(subcategory, materialType);
      case 'non-waste':
        return _generateNonWasteInstructions(subcategory, materialType);
      default:
        return _generateGenericInstructions();
    }
  }

  static DisposalInstructions _generateWetWasteInstructions(String? subcategory, String? materialType) {
    final basePreparation = [
      DisposalStep(
        instruction: 'Remove any non-organic materials (stickers, rubber bands, packaging)',
        icon: Icons.cleaning_services,
        estimatedTime: Duration(minutes: 2),
      ),
      DisposalStep(
        instruction: 'Drain excess liquids to prevent odors',
        icon: Icons.water_drop,
        estimatedTime: Duration(minutes: 1),
      ),
    ];

    final baseDisposal = [
      DisposalStep(
        instruction: 'Place in green/brown composting bin',
        icon: Icons.delete,
        estimatedTime: Duration(seconds: 30),
      ),
    ];

    List<DisposalStep> specificPreparation = [];
    
    if (subcategory?.toLowerCase() == 'food waste') {
      specificPreparation.addAll([
        DisposalStep(
          instruction: 'Break down large pieces for faster decomposition',
          icon: Icons.content_cut,
          isOptional: true,
          estimatedTime: Duration(minutes: 3),
        ),
        DisposalStep(
          instruction: 'Remove bones if setting up home composting',
          icon: Icons.remove_circle,
          isOptional: true,
          additionalInfo: 'Bones decompose slowly in home compost',
        ),
      ]);
    }

    return DisposalInstructions(
      preparationSteps: [...basePreparation, ...specificPreparation],
      disposalSteps: baseDisposal,
      timeframe: 'Dispose within 24-48 hours to prevent odors',
      commonMistakes: [
        'Mixing with plastic packaging',
        'Adding oil or grease in large quantities',
        'Including meat bones in home composting',
      ],
      environmentalBenefits: [
        'Reduces methane emissions from landfills',
        'Creates nutrient-rich soil amendment',
        'Diverts organic waste from overburdened landfills',
      ],
      collectionSchedule: 'Check with BBMP for wet waste collection days',
      recommendedLocations: _getBangaloreWetWasteLocations(),
    );
  }

  static DisposalInstructions _generateDryWasteInstructions(String? subcategory, String? materialType, bool? isRecyclable) {
    List<DisposalStep> preparation = [
      DisposalStep(
        instruction: 'Clean the item thoroughly - remove all food residue',
        icon: Icons.clean_hands,
        estimatedTime: Duration(minutes: 2),
        warningMessage: 'Contaminated items cannot be recycled',
      ),
    ];

    List<DisposalStep> disposal = [];
    List<String> mistakes = ['Not cleaning items before disposal'];

    if (subcategory?.toLowerCase() == 'plastic') {
      preparation.addAll([
        DisposalStep(
          instruction: 'Remove caps and lids (dispose separately if different plastic type)',
          icon: Icons.remove_circle_outline,
          estimatedTime: Duration(seconds: 30),
        ),
        DisposalStep(
          instruction: 'Check recycling code - #1, #2, #5 commonly accepted',
          icon: Icons.numbers,
          additionalInfo: 'Look for triangle symbol on bottom',
        ),
      ]);
      
      mistakes.addAll([
        'Leaving caps on bottles',
        'Not checking recycling codes',
        'Including black plastic (often not recyclable)',
      ]);
    }

    disposal.add(
      DisposalStep(
        instruction: isRecyclable == true 
            ? 'Place in blue recycling bin'
            : 'Place in general dry waste collection',
        icon: isRecyclable == true ? Icons.recycling : Icons.delete,
        estimatedTime: Duration(seconds: 30),
      ),
    );

    return DisposalInstructions(
      preparationSteps: preparation,
      disposalSteps: disposal,
      timeframe: 'Can store clean dry waste for weekly collection',
      commonMistakes: mistakes,
      environmentalBenefits: [
        'Conserves raw materials and energy',
        'Reduces landfill burden',
        'Creates jobs in recycling industry',
      ],
      collectionSchedule: 'Dry waste collection: Check BBMP schedule for your area',
      recommendedLocations: _getBangaloreDryWasteLocations(),
    );
  }

  static DisposalInstructions _generateHazardousWasteInstructions(String? subcategory, String? materialType) {
    return DisposalInstructions(
      preparationSteps: [
        DisposalStep(
          instruction: 'Wear protective gloves when handling',
          icon: Icons.medical_services,
          warningMessage: 'Protect yourself from harmful substances',
        ),
        DisposalStep(
          instruction: 'Keep item in original container if possible',
          icon: Icons.inventory,
          additionalInfo: 'Original labels help with proper processing',
        ),
        DisposalStep(
          instruction: 'Do not mix different hazardous materials',
          icon: Icons.dangerous,
          warningMessage: 'Mixing can create dangerous reactions',
        ),
      ],
      disposalSteps: [
        DisposalStep(
          instruction: 'Transport to designated hazardous waste facility',
          icon: Icons.local_shipping,
          estimatedTime: Duration(minutes: 30),
        ),
      ],
      safetyWarnings: [
        SafetyWarning(
          message: 'NEVER dispose in regular trash - can harm sanitation workers',
          icon: Icons.warning,
          level: SafetyLevel.critical,
        ),
        SafetyWarning(
          message: 'Keep away from children and pets',
          icon: Icons.child_care,
          level: SafetyLevel.high,
        ),
      ],
      timeframe: 'Dispose as soon as possible - do not store long-term',
      requiresSpecialHandling: true,
      commonMistakes: [
        'Putting in regular garbage',
        'Pouring chemicals down drains',
        'Mixing different hazardous materials',
      ],
      environmentalBenefits: [
        'Prevents soil and water contamination',
        'Protects wildlife and ecosystems',
        'Enables safe material recovery where possible',
      ],
      recommendedLocations: _getBangaloreHazardousWasteLocations(),
    );
  }

  static DisposalInstructions _generateMedicalWasteInstructions(String? subcategory, String? materialType) {
    return DisposalInstructions(
      preparationSteps: [
        DisposalStep(
          instruction: 'Use puncture-proof sharps container if available',
          icon: Icons.medical_services,
          warningMessage: 'Never use regular containers for sharps',
        ),
        DisposalStep(
          instruction: 'Seal items in leak-proof bag',
          icon: Icons.shopping_bag,
        ),
      ],
      disposalSteps: [
        DisposalStep(
          instruction: 'Take to hospital or medical facility for proper disposal',
          icon: Icons.local_hospital,
          estimatedTime: Duration(minutes: 20),
        ),
      ],
      safetyWarnings: [
        SafetyWarning(
          message: 'Risk of infection - handle with extreme care',
          icon: Icons.coronavirus,
          level: SafetyLevel.critical,
        ),
      ],
      timeframe: 'Dispose immediately - do not store',
      requiresSpecialHandling: true,
      commonMistakes: [
        'Putting in household trash',
        'Not using proper containers for sharps',
        'Storing medical waste at home',
      ],
      environmentalBenefits: [
        'Prevents disease transmission',
        'Protects sanitation workers',
        'Ensures proper sterilization',
      ],
      recommendedLocations: _getBangaloreMedicalWasteLocations(),
    );
  }

  static DisposalInstructions _generateNonWasteInstructions(String? subcategory, String? materialType) {
    return DisposalInstructions(
      preparationSteps: [
        DisposalStep(
          instruction: 'Clean and inspect item for damage',
          icon: Icons.cleaning_services,
          estimatedTime: Duration(minutes: 5),
        ),
      ],
      disposalSteps: [
        DisposalStep(
          instruction: 'Consider donating to local charity or NGO',
          icon: Icons.volunteer_activism,
          estimatedTime: Duration(minutes: 15),
        ),
        DisposalStep(
          instruction: 'List on online platforms for reuse',
          icon: Icons.smartphone,
          isOptional: true,
        ),
      ],
      timeframe: 'No urgency - store safely until donation/reuse',
      commonMistakes: [
        'Throwing away items that could be donated',
        'Not checking if items work before donating',
      ],
      environmentalBenefits: [
        'Extends product lifecycle',
        'Reduces demand for new products',
        'Helps community members in need',
      ],
      recommendedLocations: _getBangaloreDonationCenters(),
    );
  }

  static DisposalInstructions _generateGenericInstructions() {
    return DisposalInstructions(
      disposalSteps: [
        DisposalStep(
          instruction: 'Check with local waste management authorities',
          icon: Icons.help,
        ),
      ],
      timeframe: 'Follow local guidelines',
      commonMistakes: ['Not researching proper disposal methods'],
    );
  }

  // Bangalore-specific disposal locations
  static List<DisposalLocation> _getBangaloreWetWasteLocations() {
    return [
      DisposalLocation(
        name: 'BBMP Wet Waste Collection',
        address: 'Door-to-door collection service',
        type: DisposalLocationType.curbsideCollection,
        acceptedWasteTypes: ['Food waste', 'Garden waste', 'Organic matter'],
        operatingHours: {
          'monday': '6:00 AM - 10:00 AM',
          'tuesday': '6:00 AM - 10:00 AM',
          'wednesday': '6:00 AM - 10:00 AM',
          'thursday': '6:00 AM - 10:00 AM',
          'friday': '6:00 AM - 10:00 AM',
          'saturday': '6:00 AM - 10:00 AM',
          'sunday': 'Closed',
        },
        isGovernmentFacility: true,
        specialInstructions: ['Use green bags', 'No plastic packaging'],
      ),
      DisposalLocation(
        name: 'Daily Dump - HSR Layout',
        address: 'HSR Layout, Bengaluru',
        type: DisposalLocationType.compostingCenter,
        acceptedWasteTypes: ['Organic waste', 'Garden waste'],
        operatingHours: {
          'monday': '9:00 AM - 6:00 PM',
          'tuesday': '9:00 AM - 6:00 PM',
          'wednesday': '9:00 AM - 6:00 PM',
          'thursday': '9:00 AM - 6:00 PM',
          'friday': '9:00 AM - 6:00 PM',
          'saturday': '9:00 AM - 4:00 PM',
          'sunday': 'Closed',
        },
        phoneNumber: '+91-80-1234-5678',
        specialInstructions: ['Home composting solutions available'],
      ),
    ];
  }

  static List<DisposalLocation> _getBangaloreDryWasteLocations() {
    return [
      DisposalLocation(
        name: 'BBMP Dry Waste Collection Center',
        address: 'Various locations across Bengaluru',
        type: DisposalLocationType.recyclingCenter,
        acceptedWasteTypes: ['Paper', 'Plastic', 'Glass', 'Metal'],
        operatingHours: {
          'monday': '8:00 AM - 5:00 PM',
          'tuesday': '8:00 AM - 5:00 PM',
          'wednesday': '8:00 AM - 5:00 PM',
          'thursday': '8:00 AM - 5:00 PM',
          'friday': '8:00 AM - 5:00 PM',
          'saturday': '8:00 AM - 2:00 PM',
          'sunday': 'Closed',
        },
        isGovernmentFacility: true,
      ),
      DisposalLocation(
        name: 'Kabadiwala Network',
        address: 'Local scrap dealers',
        type: DisposalLocationType.retailerDropOff,
        acceptedWasteTypes: ['Paper', 'Plastic', 'Metal', 'Glass'],
        operatingHours: {
          'monday': '8:00 AM - 8:00 PM',
          'tuesday': '8:00 AM - 8:00 PM',
          'wednesday': '8:00 AM - 8:00 PM',
          'thursday': '8:00 AM - 8:00 PM',
          'friday': '8:00 AM - 8:00 PM',
          'saturday': '8:00 AM - 8:00 PM',
          'sunday': '8:00 AM - 6:00 PM',
        },
        specialInstructions: ['May offer payment for valuable materials'],
      ),
    ];
  }

  static List<DisposalLocation> _getBangaloreHazardousWasteLocations() {
    return [
      DisposalLocation(
        name: 'KSPCB Hazardous Waste Treatment Facility',
        address: 'Bidadi Industrial Area, Bengaluru',
        type: DisposalLocationType.hazardousWasteFacility,
        acceptedWasteTypes: ['Electronic waste', 'Batteries', 'Chemicals', 'Paint'],
        operatingHours: {
          'monday': '9:00 AM - 5:00 PM',
          'tuesday': '9:00 AM - 5:00 PM',
          'wednesday': '9:00 AM - 5:00 PM',
          'thursday': '9:00 AM - 5:00 PM',
          'friday': '9:00 AM - 5:00 PM',
          'saturday': '9:00 AM - 1:00 PM',
          'sunday': 'Closed',
        },
        isGovernmentFacility: true,
        requiresAppointment: true,
        specialInstructions: ['Bring ID proof', 'Call ahead for appointment'],
      ),
    ];
  }

  static List<DisposalLocation> _getBangaloreMedicalWasteLocations() {
    return [
      DisposalLocation(
        name: 'Manipal Hospital',
        address: 'HAL Airport Road, Bengaluru',
        type: DisposalLocationType.specialtyProcessor,
        acceptedWasteTypes: ['Sharps', 'Medical equipment', 'Pharmaceutical waste'],
        operatingHours: {
          'monday': '24 hours',
          'tuesday': '24 hours',
          'wednesday': '24 hours',
          'thursday': '24 hours',
          'friday': '24 hours',
          'saturday': '24 hours',
          'sunday': '24 hours',
        },
        phoneNumber: '+91-80-2502-4444',
        specialInstructions: ['Medical waste acceptance program'],
      ),
    ];
  }

  static List<DisposalLocation> _getBangaloreDonationCenters() {
    return [
      DisposalLocation(
        name: 'Goodwill Store',
        address: 'Multiple locations, Bengaluru',
        type: DisposalLocationType.donationCenter,
        acceptedWasteTypes: ['Clothing', 'Furniture', 'Electronics', 'Books'],
        operatingHours: {
          'monday': '10:00 AM - 7:00 PM',
          'tuesday': '10:00 AM - 7:00 PM',
          'wednesday': '10:00 AM - 7:00 PM',
          'thursday': '10:00 AM - 7:00 PM',
          'friday': '10:00 AM - 7:00 PM',
          'saturday': '10:00 AM - 6:00 PM',
          'sunday': '12:00 PM - 5:00 PM',
        },
        specialInstructions: ['Items should be in good condition'],
      ),
    ];
  }
}
