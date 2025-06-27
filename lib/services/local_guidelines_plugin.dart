import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';

/// Abstract base class for local guidelines plugins
/// Allows extensible support for different cities and waste management authorities
abstract class LocalGuidelinesPlugin {
  /// Get the plugin identifier (e.g., 'bbmp_bangalore', 'bmc_mumbai')
  String get pluginId;
  
  /// Get the authority name (e.g., 'BBMP', 'BMC')
  String get authorityName;
  
  /// Get the current guidelines version
  String get guidelinesVersion;
  
  /// Get the region/city this plugin covers
  String get region;
  
  /// Apply local guidelines to a classification
  Future<WasteClassification> applyLocalGuidelines(WasteClassification classification);
  
  /// Validate compliance with local regulations
  LocalComplianceResult validateCompliance(WasteClassification classification);
  
  /// Get local disposal instructions override
  Map<String, dynamic>? getLocalDisposalInstructions(String category, String? subcategory);
  
  /// Get local color coding requirements
  Map<String, String> getColorCoding();
  
  /// Get collection schedule information
  Map<String, dynamic> getCollectionSchedule();
  
  /// Get local regulations specific to this authority
  Map<String, String> getLocalRegulations(String category);
}

/// BBMP (Bruhat Bengaluru Mahanagara Palike) Guidelines Plugin for Bangalore
class BBMPBangalorePlugin extends LocalGuidelinesPlugin {
  @override
  String get pluginId => 'bbmp_bangalore';
  
  @override
  String get authorityName => 'BBMP';
  
  @override
  String get guidelinesVersion => 'BBMP-2024.1';
  
  @override
  String get region => 'Bangalore, IN';
  
  @override
  Future<WasteClassification> applyLocalGuidelines(WasteClassification classification) async {
    try {
      WasteAppLogger.info('Applying BBMP guidelines to classification', null, null, {
        'plugin': pluginId,
        'item': classification.itemName,
        'category': classification.category,
      });
      
      // Get BBMP-specific regulations
      final localRegulations = getLocalRegulations(classification.category);
      
      // Validate BBMP compliance
      final complianceResult = validateCompliance(classification);
      
      // Get local disposal instructions
      final localInstructions = getLocalDisposalInstructions(
        classification.category, 
        classification.subcategory,
      );
      
      // Apply BBMP-specific modifications
      var updatedClassification = classification.copyWith(
        localRegulations: localRegulations,
        bbmpComplianceStatus: complianceResult.status,
        localGuidelinesVersion: guidelinesVersion,
        localGuidelinesReference: _generateGuidelinesReference(classification),
      );
      
      // Apply local disposal method overrides if needed
      if (localInstructions != null) {
        updatedClassification = _applyLocalDisposalOverrides(
          updatedClassification, 
          localInstructions,
        );
      }
      
      // Apply BBMP-specific point modifiers
      final pointsModifier = _calculateBBMPPointsModifier(classification, complianceResult);
      if (pointsModifier != 0) {
        final newPoints = (classification.pointsAwarded ?? 10) + pointsModifier;
        updatedClassification = updatedClassification.copyWith(
          pointsAwarded: newPoints.clamp(5, 50),
        );
      }
      
      WasteAppLogger.info('BBMP guidelines applied successfully', null, null, {
        'compliance_status': complianceResult.status,
        'points_modifier': pointsModifier,
        'regulations_count': localRegulations.length,
      });
      
      return updatedClassification;
    } catch (e) {
      WasteAppLogger.severe('Error applying BBMP guidelines', e, null, {
        'plugin': pluginId,
        'item': classification.itemName,
      });
      return classification; // Return original on error
    }
  }
  
  @override
  LocalComplianceResult validateCompliance(WasteClassification classification) {
    final violations = <String>[];
    final warnings = <String>[];
    
    // Check category-specific BBMP compliance
    switch (classification.category.toLowerCase()) {
      case 'wet waste':
        _validateWetWasteCompliance(classification, violations, warnings);
        break;
      case 'dry waste':
        _validateDryWasteCompliance(classification, violations, warnings);
        break;
      case 'hazardous waste':
        _validateHazardousWasteCompliance(classification, violations, warnings);
        break;
      case 'medical waste':
        _validateMedicalWasteCompliance(classification, violations, warnings);
        break;
    }
    
    // Determine overall compliance status
    String status;
    if (violations.isNotEmpty) {
      status = 'violation';
    } else if (warnings.isNotEmpty) {
      status = 'requires_attention';
    } else {
      status = 'compliant';
    }
    
    return LocalComplianceResult(
      status: status,
      violations: violations,
      warnings: warnings,
      recommendations: _getComplianceRecommendations(classification),
    );
  }
  
  @override
  Map<String, dynamic>? getLocalDisposalInstructions(String category, String? subcategory) {
    final categoryKey = category.toLowerCase().replaceAll(' ', '_');
    final subcategoryKey = subcategory?.toLowerCase().replaceAll(' ', '_');
    
    final baseInstructions = _bbmpDisposalInstructions[categoryKey];
    if (baseInstructions == null) return null;
    
    // Check for subcategory-specific overrides
    if (subcategoryKey != null) {
      final subcategoryInstructions = _bbmpSubcategoryOverrides[subcategoryKey];
      if (subcategoryInstructions != null) {
        return {
          ...baseInstructions,
          ...subcategoryInstructions,
        };
      }
    }
    
    return baseInstructions;
  }
  
  @override
  Map<String, String> getColorCoding() {
    return {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag', 
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'non_waste': 'No specific bin (donate/reuse)',
    };
  }
  
  @override
  Map<String, dynamic> getCollectionSchedule() {
    return {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Collect daily to prevent pest infestation',
      },
      'dry_waste': {
        'frequency': 'alternate_days',
        'time': '6:00 AM - 9:00 AM', 
        'notes': 'Clean and dry before disposal',
      },
      'hazardous_waste': {
        'frequency': 'monthly',
        'time': 'Contact BBMP for pickup',
        'notes': 'Special collection required',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized dealer',
        'notes': 'Never mix with regular waste',
      },
    };
  }
  
  @override
  Map<String, String> getLocalRegulations(String category) {
    final categoryKey = category.toLowerCase().replaceAll(' ', '_');
    return _bbmpRegulations[categoryKey] ?? {};
  }
  
  // Private helper methods
  
  void _validateWetWasteCompliance(
    WasteClassification classification, 
    List<String> violations, 
    List<String> warnings,
  ) {
    // BBMP Wet Waste Rules
    if (classification.disposalMethod?.toLowerCase().contains('landfill') == true) {
      violations.add('Wet waste should not go to landfill - must be composted');
    }
    
    if (classification.isCompostable != true) {
      warnings.add('Item should be marked as compostable if it\'s organic');
    }
    
    if (classification.visualFeatures.any((f) => f.toLowerCase().contains('plastic'))) {
      violations.add('Remove plastic packaging before wet waste disposal');
    }
  }
  
  void _validateDryWasteCompliance(
    WasteClassification classification, 
    List<String> violations, 
    List<String> warnings,
  ) {
    // BBMP Dry Waste Rules
    if (classification.isRecyclable != true && 
        classification.subcategory?.toLowerCase().contains('plastic') == true) {
      warnings.add('Most plastics are recyclable - verify recycling code');
    }
    
    if (classification.visualFeatures.any((f) => f.toLowerCase().contains('dirty'))) {
      warnings.add('Clean items before dry waste disposal for better recycling');
    }
  }
  
  void _validateHazardousWasteCompliance(
    WasteClassification classification, 
    List<String> violations, 
    List<String> warnings,
  ) {
    // BBMP Hazardous Waste Rules
    if (classification.requiresSpecialDisposal != true) {
      violations.add('Hazardous waste must be marked as requiring special disposal');
    }
    
    if (classification.riskLevel == 'safe') {
      warnings.add('Risk level may be underestimated for hazardous category');
    }
  }
  
  void _validateMedicalWasteCompliance(
    WasteClassification classification, 
    List<String> violations, 
    List<String> warnings,
  ) {
    // BBMP Medical Waste Rules
    if (classification.hasUrgentTimeframe != true) {
      violations.add('Medical waste requires immediate disposal');
    }
    
    if (classification.requiredPPE?.isEmpty ?? true) {
      warnings.add('Medical waste handling typically requires PPE');
    }
  }
  
  List<String> _getComplianceRecommendations(WasteClassification classification) {
    final recommendations = <String>[];
    
    // General BBMP recommendations
    recommendations.add('Follow BBMP color-coding: ${getColorCoding()[classification.category.toLowerCase().replaceAll(' ', '_')]}');
    
    final schedule = getCollectionSchedule()[classification.category.toLowerCase().replaceAll(' ', '_')];
    if (schedule != null) {
      recommendations.add('Collection: ${schedule['frequency']} at ${schedule['time']}');
    }
    
    // Category-specific recommendations
    switch (classification.category.toLowerCase()) {
      case 'wet waste':
        recommendations.add('Drain excess water before disposal');
        recommendations.add('Remove non-biodegradable packaging');
        break;
      case 'dry waste':
        recommendations.add('Clean and dry items for better recycling');
        recommendations.add('Sort by material type when possible');
        break;
      case 'hazardous waste':
        recommendations.add('Contact BBMP for special collection');
        recommendations.add('Store safely until disposal');
        break;
    }
    
    return recommendations;
  }
  
  String _generateGuidelinesReference(WasteClassification classification) {
    final category = classification.category.toLowerCase().replaceAll(' ', '_');
    return 'BBMP-2024-$category-guidelines';
  }
  
  WasteClassification _applyLocalDisposalOverrides(
    WasteClassification classification,
    Map<String, dynamic> localInstructions,
  ) {
    // Apply BBMP-specific disposal method overrides
    final newMethod = localInstructions['primaryMethod'] ?? classification.disposalMethod;
    final locationOverride = localInstructions['location'];
    
    if (locationOverride != null) {
      final updatedInstructions = classification.disposalInstructions.copyWith(
        location: locationOverride,
      );
      
      return classification.copyWith(
        disposalMethod: newMethod,
        disposalInstructions: updatedInstructions,
      );
    }
    
    return classification.copyWith(disposalMethod: newMethod);
  }
  
  int _calculateBBMPPointsModifier(
    WasteClassification classification, 
    LocalComplianceResult compliance,
  ) {
    var modifier = 0;
    
    // Compliance bonus/penalty
    switch (compliance.status) {
      case 'compliant':
        modifier += 3; // Bonus for full compliance
        break;
      case 'requires_attention':
        modifier += 1; // Small bonus for mostly compliant
        break;
      case 'violation':
        modifier -= 2; // Penalty for violations
        break;
    }
    
    // Local guidelines bonus
    if (classification.localGuidelinesReference?.isNotEmpty == true) {
      modifier += 2;
    }
    
    return modifier;
  }
  
  // BBMP-specific data
  
  static final Map<String, Map<String, String>> _bbmpRegulations = {
    'wet_waste': {
      'color_coding': 'Green bin/bag only',
      'collection_frequency': 'Daily',
      'composting_requirement': 'Mandatory for apartments with 10+ units',
      'penalty_non_compliance': 'Rs. 100-500',
    },
    'dry_waste': {
      'color_coding': 'Blue bin/bag only',
      'collection_frequency': 'Alternate days',
      'cleaning_requirement': 'Must be clean and dry',
      'segregation_requirement': 'Sort by material type when possible',
    },
    'hazardous_waste': {
      'color_coding': 'Red bin/bag only',
      'collection_frequency': 'Monthly special collection',
      'contact_required': 'Contact BBMP helpline',
      'storage_requirement': 'Store in safe, dry place',
    },
    'medical_waste': {
      'color_coding': 'Yellow bin/bag only',
      'collection_frequency': 'Immediate disposal required',
      'authorized_dealer_only': 'Contact authorized medical waste dealer',
      'never_mix': 'Never mix with regular waste',
    },
  };
  
  static final Map<String, Map<String, dynamic>> _bbmpDisposalInstructions = {
    'wet_waste': {
      'primaryMethod': 'Compost or wet waste bin',
      'location': 'Green bin - daily collection',
      'timeframe': 'Daily disposal recommended',
      'bbmp_specific': 'Follow BBMP composting guidelines',
    },
    'dry_waste': {
      'primaryMethod': 'Clean and recycle',
      'location': 'Blue bin - alternate day collection',
      'timeframe': 'Clean before disposal',
      'bbmp_specific': 'BBMP recycling partner network',
    },
    'hazardous_waste': {
      'primaryMethod': 'Special BBMP collection',
      'location': 'Red bin - monthly collection',
      'timeframe': 'Contact BBMP for pickup',
      'bbmp_specific': 'Helpline: 1800-425-1442',
    },
  };
  
  static final Map<String, Map<String, dynamic>> _bbmpSubcategoryOverrides = {
    'e_waste': {
      'location': 'Authorized e-waste collection center',
      'bbmp_specific': 'BBMP e-waste exchange program',
    },
    'battery': {
      'location': 'Battery collection box at retail stores',
      'bbmp_specific': 'Return to manufacturer program',
    },
  };
}

/// Result of local compliance validation
class LocalComplianceResult {
  const LocalComplianceResult({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.recommendations,
  });
  
  final String status; // 'compliant', 'requires_attention', 'violation'
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;
}

/// Extension for DisposalInstructions to support copyWith
extension DisposalInstructionsExtension on DisposalInstructions {
  DisposalInstructions copyWith({
    String? primaryMethod,
    List<String>? steps,
    String? timeframe,
    String? location,
    List<String>? warnings,
    List<String>? tips,
    String? recyclingInfo,
    String? estimatedTime,
    bool? hasUrgentTimeframe,
  }) {
    return DisposalInstructions(
      primaryMethod: primaryMethod ?? this.primaryMethod,
      steps: steps ?? this.steps,
      timeframe: timeframe ?? this.timeframe,
      location: location ?? this.location,
      warnings: warnings ?? this.warnings,
      tips: tips ?? this.tips,
      recyclingInfo: recyclingInfo ?? this.recyclingInfo,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      hasUrgentTimeframe: hasUrgentTimeframe ?? this.hasUrgentTimeframe,
    );
  }
}

/// Local Guidelines Manager to handle multiple plugins
class LocalGuidelinesManager {
  static final Map<String, LocalGuidelinesPlugin> _plugins = {};
  
  /// Register a local guidelines plugin
  static void registerPlugin(LocalGuidelinesPlugin plugin) {
    _plugins[plugin.pluginId] = plugin;
    WasteAppLogger.info('Local guidelines plugin registered', null, null, {
      'plugin_id': plugin.pluginId,
      'authority': plugin.authorityName,
      'region': plugin.region,
    });
  }
  
  /// Get plugin for a specific region
  static LocalGuidelinesPlugin? getPluginForRegion(String region) {
    // Simple region matching - can be enhanced
    if (region.toLowerCase().contains('bangalore') || region.toLowerCase().contains('bengaluru')) {
      return _plugins['bbmp_bangalore'];
    }
    
    return null;
  }
  
  /// Apply local guidelines using appropriate plugin
  static Future<WasteClassification> applyLocalGuidelines(
    WasteClassification classification,
    String region,
  ) async {
    final plugin = getPluginForRegion(region);
    if (plugin != null) {
      return plugin.applyLocalGuidelines(classification);
    }
    
    WasteAppLogger.info('No local guidelines plugin found for region', null, null, {
      'region': region,
      'available_plugins': _plugins.keys.toList(),
    });
    
    return classification; // Return unchanged if no plugin
  }
  
  /// Initialize default plugins
  static void initializeDefaultPlugins() {
    registerPlugin(BBMPBangalorePlugin());
    // Add more plugins as needed:
    // registerPlugin(BMCMumbaiPlugin());
    // registerPlugin(MCDDelhiPlugin());
  }
}