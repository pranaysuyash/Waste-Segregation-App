import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'waste_classification.g.dart';

/// Represents a waste classification result with comprehensive disposal information
@HiveType(typeId: 0)
class WasteClassification extends HiveObject {
  WasteClassification({
    String? id,
    required this.itemName,
    required this.category,
    this.subcategory,
    this.materialType,
    this.recyclingCode,
    required this.explanation,
    this.disposalMethod,
    required this.disposalInstructions,
    this.userId,
    required this.region,
    this.localGuidelinesReference,
    this.imageUrl,
    this.imageHash,
    this.imageMetrics,
    required this.visualFeatures,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.isSingleUse,
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
    this.reanalysisModelsTried,
    this.confirmedByModel,
    this.pointsAwarded,
    this.environmentalImpact,
    this.relatedItems,
    this.imageRelativePath,
    this.thumbnailRelativePath,
    // Enhanced AI Analysis v2.0 fields
    this.recyclability,
    this.hazardLevel,
    this.co2Impact,
    this.decompositionTime,
    this.properEquipment,
    this.materials,
    this.subCategory,
    this.commonUses,
    this.alternativeOptions,
    this.localRegulations,
    // Enhanced AI Analysis v2.0 additional fields
    this.waterPollutionLevel,
    this.soilContaminationRisk,
    this.biodegradabilityDays,
    this.recyclingEfficiency,
    this.manufacturingEnergyFootprint,
    this.transportationFootprint,
    this.endOfLifeCost,
    this.circularEconomyPotential,
    this.generatesMicroplastics,
    this.humanToxicityLevel,
    this.wildlifeImpactSeverity,
    this.resourceScarcity,
    this.disposalCostEstimate,
    this.bbmpComplianceStatus,
    this.localGuidelinesVersion,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a fallback classification when AI analysis fails
  factory WasteClassification.fallback(String imagePath, {String? userId, String? id}) {
    return WasteClassification(
      id: id ?? const Uuid().v4(),
      itemName: 'Unidentified Item - Fallback',
      category: 'Requires Manual Review',
      subcategory: 'Classification Needed',
      explanation:
          'Our AI was unable to automatically identify this item. This could be due to unclear image quality, unusual lighting, or an uncommon item type. Please help us improve by providing feedback on what this item actually is.',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Manual identification required',
        steps: [
          'Look at the item carefully and identify its material type',
          'Check if it\'s primarily made of paper, plastic, glass, metal, or organic matter',
          'Refer to local waste sorting guidelines for your area',
          'Use the feedback button to help improve our AI recognition',
          'When in doubt, contact your local waste management authority'
        ],
        hasUrgentTimeframe: false,
        warnings: ['Do not dispose until properly identified', 'Some items may require special handling'],
        tips: [
          'Take a clearer photo with better lighting if possible',
          'Ensure the item fills most of the image frame',
          'Remove any packaging or labels that might confuse the AI'
        ],
      ),
      userId: userId,
      region: 'Unknown',
      visualFeatures: [],
      alternatives: [
        AlternativeClassification(
          category: 'Wet Waste',
          subcategory: 'Food Waste',
          confidence: 0.0,
          reason: 'If this is food scraps or organic matter, it belongs in wet waste',
        ),
        AlternativeClassification(
          category: 'Dry Waste',
          subcategory: 'Recyclable Material',
          confidence: 0.0,
          reason: 'If this is paper, plastic, glass, or metal, it likely belongs in dry waste',
        ),
        AlternativeClassification(
          category: 'Hazardous Waste',
          subcategory: 'Special Disposal',
          confidence: 0.0,
          reason: 'If this contains batteries, electronics, or chemicals, it needs special handling',
        ),
      ],
      imageUrl: imagePath,
      confidence: 0.0,
      clarificationNeeded: true,
      riskLevel: 'unknown',
      suggestedAction: 'Please identify the item manually and provide feedback to help improve our AI',
    );
  }

  /// Creates a WasteClassification from JSON data
  factory WasteClassification.fromJson(Map<String, dynamic> json) {
    return WasteClassification(
      id: json['id'],
      itemName: json['itemName'] ?? 'Unknown Item',
      category: json['category'] ?? 'Dry Waste',
      subcategory: json['subcategory'],
      materialType: json['materialType'],
      recyclingCode: json['recyclingCode'],
      explanation: json['explanation'] ?? '',
      disposalMethod: json['disposalMethod'],
      disposalInstructions: json['disposalInstructions'] != null
          ? _parseDisposalInstructions(json['disposalInstructions'])
          : DisposalInstructions(
              primaryMethod: 'Review required',
              steps: ['Please review manually'],
              hasUrgentTimeframe: false,
            ),
      userId: json['userId'],
      region: json['region'] ?? 'Unknown',
      localGuidelinesReference: json['localGuidelinesReference'],
      imageUrl: json['imageUrl'],
      imageHash: json['imageHash'],
      imageMetrics: json['imageMetrics'] != null ? Map<String, double>.from(json['imageMetrics']) : null,
      visualFeatures: json['visualFeatures'] != null ? List<String>.from(json['visualFeatures']) : [],
      isRecyclable: json['isRecyclable'],
      isCompostable: json['isCompostable'],
      requiresSpecialDisposal: json['requiresSpecialDisposal'],
      isSingleUse: json['isSingleUse'],
      colorCode: json['colorCode'],
      riskLevel: json['riskLevel'],
      requiredPPE: json['requiredPPE'] != null ? List<String>.from(json['requiredPPE']) : null,
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
          ? (json['alternatives'] as List).map((alt) => AlternativeClassification.fromJson(alt)).toList()
          : [],
      suggestedAction: json['suggestedAction'],
      hasUrgentTimeframe: json['hasUrgentTimeframe'],
      instructionsLang: json['instructionsLang'],
      translatedInstructions:
          json['translatedInstructions'] != null ? Map<String, String>.from(json['translatedInstructions']) : null,
      source: json['source'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      reanalysisModelsTried:
          json['reanalysisModelsTried'] != null ? List<String>.from(json['reanalysisModelsTried']) : null,
      confirmedByModel: json['confirmedByModel'],
      pointsAwarded: json['pointsAwarded'],
      environmentalImpact: json['environmentalImpact'],
      relatedItems: json['relatedItems'] != null ? List<String>.from(json['relatedItems']) : null,
      imageRelativePath: json['imageRelativePath'],
      thumbnailRelativePath: json['thumbnailRelativePath'],
      // Enhanced AI Analysis v2.0 additional fields
      recyclability: json['recyclability'],
      hazardLevel: json['hazardLevel'],
      co2Impact: json['co2Impact']?.toDouble(),
      decompositionTime: json['decompositionTime'],
      properEquipment: json['properEquipment'] != null ? List<String>.from(json['properEquipment']) : null,
      materials: json['materials'] != null ? List<String>.from(json['materials']) : null,
      subCategory: json['subCategory'],
      commonUses: json['commonUses'] != null ? List<String>.from(json['commonUses']) : null,
      alternativeOptions: json['alternativeOptions'] != null ? List<String>.from(json['alternativeOptions']) : null,
      localRegulations: json['localRegulations'] != null ? Map<String, String>.from(json['localRegulations']) : null,
      waterPollutionLevel: json['waterPollutionLevel'],
      soilContaminationRisk: json['soilContaminationRisk'],
      biodegradabilityDays: json['biodegradabilityDays'],
      recyclingEfficiency: json['recyclingEfficiency'],
      manufacturingEnergyFootprint: json['manufacturingEnergyFootprint']?.toDouble(),
      transportationFootprint: json['transportationFootprint']?.toDouble(),
      endOfLifeCost: json['endOfLifeCost'],
      circularEconomyPotential: json['circularEconomyPotential'] != null ? List<String>.from(json['circularEconomyPotential']) : null,
      generatesMicroplastics: json['generatesMicroplastics'],
      humanToxicityLevel: json['humanToxicityLevel'],
      wildlifeImpactSeverity: json['wildlifeImpactSeverity'],
      resourceScarcity: json['resourceScarcity'],
      disposalCostEstimate: json['disposalCostEstimate']?.toDouble(),
      bbmpComplianceStatus: json['bbmpComplianceStatus'],
      localGuidelinesVersion: json['localGuidelinesVersion'],
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String itemName;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final String? subcategory;
  @HiveField(4)
  final String? materialType;
  @HiveField(5)
  final int? recyclingCode;
  @HiveField(6)
  final String explanation;
  @HiveField(7)
  final String? disposalMethod;
  @HiveField(8)
  final DisposalInstructions disposalInstructions;

  // User identification
  @HiveField(9)
  final String? userId;

  // Location and guidelines
  @HiveField(10)
  final String region;
  @HiveField(11)
  final String? localGuidelinesReference;

  // Image and visual data
  @HiveField(12)
  final String? imageUrl;

  /// Relative path to the image (for better cross-platform compatibility)
  @HiveField(60)
  final String? imageRelativePath;

  /// Relative path to the thumbnail image
  @HiveField(61)
  final String? thumbnailRelativePath;
  @HiveField(13)
  final String? imageHash;
  @HiveField(14)
  final Map<String, double>? imageMetrics;
  @HiveField(15)
  final List<String> visualFeatures;

  // Waste properties
  @HiveField(16)
  final bool? isRecyclable;
  @HiveField(17)
  final bool? isCompostable;
  @HiveField(18)
  final bool? requiresSpecialDisposal;
  @HiveField(19)
  final bool? isSingleUse;
  @HiveField(20)
  final String? colorCode;
  @HiveField(21)
  final String? riskLevel;
  @HiveField(22)
  final List<String>? requiredPPE;

  // Product identification
  @HiveField(23)
  final String? brand;
  @HiveField(24)
  final String? product;
  @HiveField(25)
  final String? barcode;

  // User interaction data
  @HiveField(26)
  final bool? isSaved;
  @HiveField(27)
  final bool? userConfirmed;
  @HiveField(28)
  final String? userCorrection;
  @HiveField(29)
  final String? disagreementReason;
  @HiveField(30)
  final String? userNotes;
  @HiveField(31)
  final int? viewCount;
  @HiveField(32)
  final bool? clarificationNeeded;

  // AI model performance data
  @HiveField(33)
  final double? confidence;
  @HiveField(34)
  final String? modelVersion;
  @HiveField(35)
  final int? processingTimeMs;
  @HiveField(36)
  final String? modelSource;
  @HiveField(37)
  final String? analysisSessionId;

  // Alternative classifications and actions
  @HiveField(38)
  final List<AlternativeClassification> alternatives;
  @HiveField(39)
  final String? suggestedAction;
  @HiveField(40)
  final bool? hasUrgentTimeframe;

  // Multilingual support
  @HiveField(41)
  final String? instructionsLang;
  @HiveField(42)
  final Map<String, String>? translatedInstructions;

  // Gamification & Engagement
  @HiveField(43)
  final int? pointsAwarded;
  @HiveField(44)
  final String? environmentalImpact;
  @HiveField(45)
  final List<String>? relatedItems;

  // Processing context
  @HiveField(46)
  final String? source;
  @HiveField(47)
  final DateTime timestamp;

  // List of model names that have been used for reanalysis on this classification
  @HiveField(48)
  final List<String>? reanalysisModelsTried;

  // The model that produced a user-confirmed correct result
  @HiveField(49)
  final String? confirmedByModel;

  // Enhanced AI Analysis v2.0 - Environmental Impact Fields (21+ data points)
  /// Recyclability level (fully, partially, not recyclable)
  @HiveField(62)
  final String? recyclability; // Using String for backward compatibility

  /// Hazard level (1-5 scale)
  @HiveField(63)
  final int? hazardLevel;

  /// CO2 impact in kg CO2 equivalent
  @HiveField(64)
  final double? co2Impact;

  /// Decomposition time estimate
  @HiveField(65)
  final String? decompositionTime;

  /// Personal protective equipment needed
  @HiveField(66)
  final List<String>? properEquipment;

  /// Component materials list
  @HiveField(67)
  final List<String>? materials;

  /// Detailed subcategory classification
  @HiveField(68)
  final String? subCategory;

  /// Common uses for this item
  @HiveField(69)
  final List<String>? commonUses;

  /// Eco-friendly alternatives
  @HiveField(70)
  final List<String>? alternativeOptions;

  /// City-specific regulations (key-value pairs)
  @HiveField(71)
  final Map<String, String>? localRegulations;

  // Enhanced AI Analysis v2.0 - Additional Environmental Data Points
  /// Water pollution impact level (1-5 scale)
  @HiveField(72)
  final int? waterPollutionLevel;

  /// Soil contamination risk (1-5 scale)
  @HiveField(73)
  final int? soilContaminationRisk;

  /// Biodegradability timeline in days
  @HiveField(74)
  final int? biodegradabilityDays;

  /// Recycling efficiency percentage (0-100)
  @HiveField(75)
  final int? recyclingEfficiency;

  /// Manufacturing energy footprint in kWh
  @HiveField(76)
  final double? manufacturingEnergyFootprint;

  /// Transportation carbon footprint
  @HiveField(77)
  final double? transportationFootprint;

  /// End-of-life environmental cost
  @HiveField(78)
  final String? endOfLifeCost;

  /// Circular economy potential (reuse/repurpose opportunities)
  @HiveField(79)
  final List<String>? circularEconomyPotential;

  /// Microplastic generation risk (boolean)
  @HiveField(80)
  final bool? generatesMicroplastics;

  /// Toxicity level for humans (1-5 scale)
  @HiveField(81)
  final int? humanToxicityLevel;

  /// Wildlife impact severity (1-5 scale)
  @HiveField(82)
  final int? wildlifeImpactSeverity;

  /// Resource scarcity indicator (common/uncommon/rare)
  @HiveField(83)
  final String? resourceScarcity;

  /// Disposal cost estimate in local currency
  @HiveField(84)
  final double? disposalCostEstimate;

  /// BBMP compliance status for Bangalore
  @HiveField(85)
  final String? bbmpComplianceStatus;

  /// Local guidelines version number
  @HiveField(86)
  final String? localGuidelinesVersion;

  /// Parse disposal instructions from various input formats
  static DisposalInstructions _parseDisposalInstructions(dynamic instructionsData) {
    if (instructionsData == null) {
      return DisposalInstructions(
        primaryMethod: 'Review required',
        steps: ['Please review manually'],
        hasUrgentTimeframe: false,
      );
    }

    // If it's already a Map, use the standard fromJson
    if (instructionsData is Map<String, dynamic>) {
      return DisposalInstructions.fromJson(instructionsData);
    }

    // If it's a string, create basic instructions from it
    if (instructionsData is String) {
      return DisposalInstructions(
        primaryMethod: instructionsData.length > 100 ? '${instructionsData.substring(0, 100)}...' : instructionsData,
        steps: DisposalInstructions._parseStepsFromString(instructionsData),
        hasUrgentTimeframe: false,
      );
    }

    // Fallback
    return DisposalInstructions(
      primaryMethod: 'Review required',
      steps: ['Please review manually'],
      hasUrgentTimeframe: false,
    );
  }

  /// Calculate dynamic points based on classification richness and environmental impact
  int calculatePoints() {
    var points = 10; // Base points for classification
    
    // Data richness bonus (up to 15 points)
    var dataFields = 0;
    if (subcategory != null && subcategory!.isNotEmpty) dataFields++;
    if (materialType != null && materialType!.isNotEmpty) dataFields++;
    if (recyclingCode != null) dataFields++;
    if (brand != null && brand!.isNotEmpty) dataFields++;
    if (visualFeatures.isNotEmpty) dataFields++;
    if (materials != null && materials!.isNotEmpty) dataFields++;
    if (commonUses != null && commonUses!.isNotEmpty) dataFields++;
    if (alternativeOptions != null && alternativeOptions!.isNotEmpty) dataFields++;
    if (circularEconomyPotential != null && circularEconomyPotential!.isNotEmpty) dataFields++;
    if (localRegulations != null && localRegulations!.isNotEmpty) dataFields++;
    
    // Award bonus points for detailed analysis (1-15 points)
    points += (dataFields * 1.5).round().clamp(0, 15);
    
    // Environmental impact bonus (up to 10 points)
    if (co2Impact != null && co2Impact! > 0) {
      points += 2;
    }
    if (waterPollutionLevel != null && waterPollutionLevel! > 3) {
      points += 2;
    }
    if (soilContaminationRisk != null && soilContaminationRisk! > 3) {
      points += 2;
    }
    if (recyclability == 'fully recyclable') {
      points += 3;
    } else if (recyclability == 'partially recyclable') {
      points += 1;
    }
    if (generatesMicroplastics == true) {
      points += 2; // Awareness bonus
    }
    
    // Complexity bonus (up to 5 points)
    if (requiresSpecialDisposal == true) {
      points += 3;
    }
    if (requiredPPE != null && requiredPPE!.isNotEmpty) {
      points += 2;
    }
    if (hasUrgentTimeframe == true) {
      points += 2;
    }
    
    // Local guidelines bonus (up to 5 points)
    if (bbmpComplianceStatus != null && bbmpComplianceStatus!.isNotEmpty) {
      points += 3;
    }
    if (localGuidelinesReference != null && localGuidelinesReference!.isNotEmpty) {
      points += 2;
    }
    
    // Confidence bonus/penalty (±5 points)
    if (confidence != null) {
      if (confidence! >= 0.9) {
        points += 5;
      } else if (confidence! >= 0.8) {
        points += 3;
      } else if (confidence! >= 0.7) {
        points += 1;
      } else if (confidence! < 0.5) {
        points -= 2;
      }
    }
    
    // Cap at reasonable maximum
    return points.clamp(5, 50);
  }
  
  /// Get environmental impact score (1-10 scale)
  double getEnvironmentalImpactScore() {
    var score = 5.0; // Neutral baseline
    
    // CO2 impact factor
    if (co2Impact != null) {
      if (co2Impact! > 10.0) {
        score += 2.0;
      } else if (co2Impact! > 5.0) {
        score += 1.0;
      } else if (co2Impact! < 1.0) {
        score -= 1.0;
      }
    }
    
    // Pollution factors
    if (waterPollutionLevel != null) {
      score += (waterPollutionLevel! - 3) * 0.5;
    }
    if (soilContaminationRisk != null) {
      score += (soilContaminationRisk! - 3) * 0.5;
    }
    
    // Recyclability factor
    if (recyclability == 'fully recyclable') {
      score -= 2.0;
    } else if (recyclability == 'not recyclable') {
      score += 1.5;
    }
    
    // Microplastics factor
    if (generatesMicroplastics == true) {
      score += 1.0;
    }
    
    // Toxicity factors
    if (humanToxicityLevel != null) {
      score += (humanToxicityLevel! - 3) * 0.3;
    }
    if (wildlifeImpactSeverity != null) {
      score += (wildlifeImpactSeverity! - 3) * 0.4;
    }
    
    return score.clamp(1.0, 10.0);
  }
  
  /// Get visual tags for this classification
  List<ClassificationTag> getClassificationTags() {
    final tags = <ClassificationTag>[];
    
    // Single-use vs Multi-use
    if (isSingleUse == true) {
      tags.add(const ClassificationTag(
        label: 'Single-Use',
        color: '#FF6B35', // Orange
        icon: 'warning',
        priority: 1,
      ));
    } else if (isSingleUse == false) {
      tags.add(const ClassificationTag(
        label: 'Multi-Use',
        color: '#4CAF50', // Green
        icon: 'autorenew',
        priority: 2,
      ));
    }
    
    // Recyclability
    if (recyclability != null) {
      switch (recyclability) {
        case 'fully recyclable':
          tags.add(const ClassificationTag(
            label: 'Fully Recyclable',
            color: '#2E7D32', // Dark Green
            icon: 'recycling',
            priority: 3,
          ));
          break;
        case 'partially recyclable':
          tags.add(const ClassificationTag(
            label: 'Partially Recyclable',
            color: '#F57C00', // Orange
            icon: 'recycling',
            priority: 4,
          ));
          break;
        case 'not recyclable':
          tags.add(const ClassificationTag(
            label: 'Not Recyclable',
            color: '#D32F2F', // Red
            icon: 'block',
            priority: 5,
          ));
          break;
      }
    }
    
    // Hazard level
    if (hazardLevel != null && hazardLevel! > 3) {
      tags.add(const ClassificationTag(
        label: 'Hazardous',
        color: '#C62828', // Dark Red
        icon: 'dangerous',
        priority: 6,
      ));
    }
    
    // Special disposal
    if (requiresSpecialDisposal == true) {
      tags.add(const ClassificationTag(
        label: 'Special Disposal',
        color: '#7B1FA2', // Purple
        icon: 'medical_services',
        priority: 7,
      ));
    }
    
    // Compostable
    if (isCompostable == true) {
      tags.add(const ClassificationTag(
        label: 'Compostable',
        color: '#388E3C', // Green
        icon: 'compost',
        priority: 8,
      ));
    }
    
    // BBMP Compliance (Bangalore specific)
    if (bbmpComplianceStatus != null && bbmpComplianceStatus!.isNotEmpty) {
      tags.add(ClassificationTag(
        label: 'BBMP: $bbmpComplianceStatus',
        color: '#1565C0', // Blue
        icon: 'verified',
        priority: 9,
      ));
    }
    
    // High CO2 impact
    if (co2Impact != null && co2Impact! > 5.0) {
      tags.add(const ClassificationTag(
        label: 'High CO₂ Impact',
        color: '#FF5722', // Deep Orange
        icon: 'co2',
        priority: 10,
      ));
    }
    
    // Sort by priority and return top 5
    tags.sort((a, b) => a.priority.compareTo(b.priority));
    return tags.take(5).toList();
  }

  /// Converts the classification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category,
      'subcategory': subcategory,
      'materialType': materialType,
      'recyclingCode': recyclingCode,
      'explanation': explanation,
      'disposalMethod': disposalMethod,
      'disposalInstructions': disposalInstructions.toJson(),
      'userId': userId,
      'region': region,
      'localGuidelinesReference': localGuidelinesReference,
      'imageUrl': imageUrl,
      'imageHash': imageHash,
      'imageMetrics': imageMetrics,
      'visualFeatures': visualFeatures,
      'isRecyclable': isRecyclable,
      'isCompostable': isCompostable,
      'requiresSpecialDisposal': requiresSpecialDisposal,
      'isSingleUse': isSingleUse,
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
      'reanalysisModelsTried': reanalysisModelsTried,
      'confirmedByModel': confirmedByModel,
      'pointsAwarded': pointsAwarded,
      'environmentalImpact': environmentalImpact,
      'relatedItems': relatedItems,
      'imageRelativePath': imageRelativePath,
      'thumbnailRelativePath': thumbnailRelativePath,
      // Enhanced AI Analysis v2.0 additional fields
      'recyclability': recyclability,
      'hazardLevel': hazardLevel,
      'co2Impact': co2Impact,
      'decompositionTime': decompositionTime,
      'properEquipment': properEquipment,
      'materials': materials,
      'subCategory': subCategory,
      'commonUses': commonUses,
      'alternativeOptions': alternativeOptions,
      'localRegulations': localRegulations,
      'waterPollutionLevel': waterPollutionLevel,
      'soilContaminationRisk': soilContaminationRisk,
      'biodegradabilityDays': biodegradabilityDays,
      'recyclingEfficiency': recyclingEfficiency,
      'manufacturingEnergyFootprint': manufacturingEnergyFootprint,
      'transportationFootprint': transportationFootprint,
      'endOfLifeCost': endOfLifeCost,
      'circularEconomyPotential': circularEconomyPotential,
      'generatesMicroplastics': generatesMicroplastics,
      'humanToxicityLevel': humanToxicityLevel,
      'wildlifeImpactSeverity': wildlifeImpactSeverity,
      'resourceScarcity': resourceScarcity,
      'disposalCostEstimate': disposalCostEstimate,
      'bbmpComplianceStatus': bbmpComplianceStatus,
      'localGuidelinesVersion': localGuidelinesVersion,
    };
  }

  /// Creates a copy with updated fields
  WasteClassification copyWith({
    String? id,
    String? itemName,
    String? category,
    String? subcategory,
    String? materialType,
    int? recyclingCode,
    String? explanation,
    String? disposalMethod,
    DisposalInstructions? disposalInstructions,
    String? userId,
    String? region,
    String? localGuidelinesReference,
    String? imageUrl,
    String? imageHash,
    Map<String, double>? imageMetrics,
    List<String>? visualFeatures,
    bool? isRecyclable,
    bool? isCompostable,
    bool? requiresSpecialDisposal,
    bool? isSingleUse,
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
    List<String>? reanalysisModelsTried,
    String? confirmedByModel,
    int? pointsAwarded,
    String? environmentalImpact,
    List<String>? relatedItems,
    String? imageRelativePath,
    String? thumbnailRelativePath,
    // Enhanced AI Analysis v2.0 additional fields
    String? recyclability,
    int? hazardLevel,
    double? co2Impact,
    String? decompositionTime,
    List<String>? properEquipment,
    List<String>? materials,
    String? subCategory,
    List<String>? commonUses,
    List<String>? alternativeOptions,
    Map<String, String>? localRegulations,
    int? waterPollutionLevel,
    int? soilContaminationRisk,
    int? biodegradabilityDays,
    int? recyclingEfficiency,
    double? manufacturingEnergyFootprint,
    double? transportationFootprint,
    String? endOfLifeCost,
    List<String>? circularEconomyPotential,
    bool? generatesMicroplastics,
    int? humanToxicityLevel,
    int? wildlifeImpactSeverity,
    String? resourceScarcity,
    double? disposalCostEstimate,
    String? bbmpComplianceStatus,
    String? localGuidelinesVersion,
  }) {
    return WasteClassification(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      materialType: materialType ?? this.materialType,
      recyclingCode: recyclingCode ?? this.recyclingCode,
      explanation: explanation ?? this.explanation,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      disposalInstructions: disposalInstructions ?? this.disposalInstructions,
      userId: userId ?? this.userId,
      region: region ?? this.region,
      localGuidelinesReference: localGuidelinesReference ?? this.localGuidelinesReference,
      imageUrl: imageUrl ?? this.imageUrl,
      imageHash: imageHash ?? this.imageHash,
      imageMetrics: imageMetrics ?? this.imageMetrics,
      visualFeatures: visualFeatures ?? this.visualFeatures,
      isRecyclable: isRecyclable ?? this.isRecyclable,
      isCompostable: isCompostable ?? this.isCompostable,
      requiresSpecialDisposal: requiresSpecialDisposal ?? this.requiresSpecialDisposal,
      isSingleUse: isSingleUse ?? this.isSingleUse,
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
      reanalysisModelsTried: reanalysisModelsTried ?? this.reanalysisModelsTried,
      confirmedByModel: confirmedByModel ?? this.confirmedByModel,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      relatedItems: relatedItems ?? this.relatedItems,
      imageRelativePath: imageRelativePath ?? this.imageRelativePath,
      thumbnailRelativePath: thumbnailRelativePath ?? this.thumbnailRelativePath,
      // Enhanced AI Analysis v2.0 additional fields
      recyclability: recyclability ?? this.recyclability,
      hazardLevel: hazardLevel ?? this.hazardLevel,
      co2Impact: co2Impact ?? this.co2Impact,
      decompositionTime: decompositionTime ?? this.decompositionTime,
      properEquipment: properEquipment ?? this.properEquipment,
      materials: materials ?? this.materials,
      subCategory: subCategory ?? this.subCategory,
      commonUses: commonUses ?? this.commonUses,
      alternativeOptions: alternativeOptions ?? this.alternativeOptions,
      localRegulations: localRegulations ?? this.localRegulations,
      waterPollutionLevel: waterPollutionLevel ?? this.waterPollutionLevel,
      soilContaminationRisk: soilContaminationRisk ?? this.soilContaminationRisk,
      biodegradabilityDays: biodegradabilityDays ?? this.biodegradabilityDays,
      recyclingEfficiency: recyclingEfficiency ?? this.recyclingEfficiency,
      manufacturingEnergyFootprint: manufacturingEnergyFootprint ?? this.manufacturingEnergyFootprint,
      transportationFootprint: transportationFootprint ?? this.transportationFootprint,
      endOfLifeCost: endOfLifeCost ?? this.endOfLifeCost,
      circularEconomyPotential: circularEconomyPotential ?? this.circularEconomyPotential,
      generatesMicroplastics: generatesMicroplastics ?? this.generatesMicroplastics,
      humanToxicityLevel: humanToxicityLevel ?? this.humanToxicityLevel,
      wildlifeImpactSeverity: wildlifeImpactSeverity ?? this.wildlifeImpactSeverity,
      resourceScarcity: resourceScarcity ?? this.resourceScarcity,
      disposalCostEstimate: disposalCostEstimate ?? this.disposalCostEstimate,
      bbmpComplianceStatus: bbmpComplianceStatus ?? this.bbmpComplianceStatus,
      localGuidelinesVersion: localGuidelinesVersion ?? this.localGuidelinesVersion,
    );
  }
}

/// Alternative classification suggestion
@HiveType(typeId: 1)
class AlternativeClassification {
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
  @HiveField(0)
  final String category;
  @HiveField(1)
  final String? subcategory;
  @HiveField(2)
  final double confidence;
  @HiveField(3)
  final String reason;

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
@HiveType(typeId: 2)
class DisposalInstructions {
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
      steps: _parseStepsFromJson(json['steps']),
      timeframe: json['timeframe'],
      location: json['location'],
      warnings: _parseListFromJson(json['warnings']),
      tips: _parseListFromJson(json['tips']),
      recyclingInfo: json['recyclingInfo'],
      estimatedTime: json['estimatedTime'],
      hasUrgentTimeframe: json['hasUrgentTimeframe'] ?? false,
    );
  }
  @HiveField(0)
  final String primaryMethod;
  @HiveField(1)
  final List<String> steps;
  @HiveField(2)
  final String? timeframe;
  @HiveField(3)
  final String? location;
  @HiveField(4)
  final List<String>? warnings;
  @HiveField(5)
  final List<String>? tips;
  @HiveField(6)
  final String? recyclingInfo;
  @HiveField(7)
  final String? estimatedTime;
  @HiveField(8)
  final bool hasUrgentTimeframe;

  /// Parse steps from various input formats (List, String with separators)
  static List<String> _parseStepsFromJson(dynamic stepsData) {
    if (stepsData == null) {
      return ['Please review manually'];
    }

    if (stepsData is List) {
      return List<String>.from(stepsData);
    }

    if (stepsData is String) {
      return _parseStepsFromString(stepsData);
    }

    return ['Please review manually'];
  }

  /// Parse list from various input formats
  static List<String>? _parseListFromJson(dynamic listData) {
    if (listData == null) {
      return null;
    }

    if (listData is List) {
      return List<String>.from(listData);
    }

    if (listData is String) {
      return _parseStepsFromString(listData);
    }

    return null;
  }

  /// Parse steps from string with various separators
  static List<String> _parseStepsFromString(String stepsString) {
    if (stepsString.trim().isEmpty) {
      return ['Please review manually'];
    }

    var steps = <String>[];

    // Try newline separation first
    if (stepsString.contains('\n')) {
      steps = stepsString.split('\n').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try comma separation
    else if (stepsString.contains(',')) {
      steps = stepsString.split(',').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try semicolon separation
    else if (stepsString.contains(';')) {
      steps = stepsString.split(';').map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Try numbered list pattern (1. 2. 3.)
    else if (RegExp(r'\d+\.').hasMatch(stepsString)) {
      steps = stepsString.split(RegExp(r'\d+\.')).map((step) => step.trim()).where((step) => step.isNotEmpty).toList();
    }
    // Single step
    else {
      steps = [stepsString.trim()];
    }

    return steps.isNotEmpty ? steps : ['Please review manually'];
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

// Enum to define recyclability levels
enum RecyclabilityLevel {
  fullyRecyclable,
  partiallyRecyclable,
  notRecyclable,
}

// Extension for recyclability levels
extension RecyclabilityLevelExtension on RecyclabilityLevel {
  String get name {
    switch (this) {
      case RecyclabilityLevel.fullyRecyclable:
        return 'Fully Recyclable';
      case RecyclabilityLevel.partiallyRecyclable:
        return 'Partially Recyclable';
      case RecyclabilityLevel.notRecyclable:
        return 'Not Recyclable';
    }
  }

  String get description {
    switch (this) {
      case RecyclabilityLevel.fullyRecyclable:
        return 'Can be completely recycled in standard facilities';
      case RecyclabilityLevel.partiallyRecyclable:
        return 'Some parts can be recycled, others require special handling';
      case RecyclabilityLevel.notRecyclable:
        return 'Cannot be recycled through standard waste management';
    }
  }

  String get color {
    switch (this) {
      case RecyclabilityLevel.fullyRecyclable:
        return '#4CAF50'; // Green
      case RecyclabilityLevel.partiallyRecyclable:
        return '#FF9800'; // Orange
      case RecyclabilityLevel.notRecyclable:
        return '#F44336'; // Red
    }
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
        return '#FFC107'; // Amber
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
        return '#FFE082'; // Light Amber
      case DryWasteSubcategory.plastic:
        return '#FFC107'; // Amber
      case DryWasteSubcategory.glass:
        return '#FFB300'; // Dark Amber
      case DryWasteSubcategory.metal:
        return '#FF8F00'; // Deep Amber
      case DryWasteSubcategory.carton:
        return '#FFCC02'; // Light Amber
      case DryWasteSubcategory.textile:
        return '#FFB74D'; // Amber
      case DryWasteSubcategory.rubber:
        return '#FFA726'; // Amber
      case DryWasteSubcategory.wood:
        return '#FF9800'; // Dark Amber
      case DryWasteSubcategory.other:
        return '#FFC107'; // Amber (same as parent category)
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

/// Classification tag for visual representation
class ClassificationTag {
  const ClassificationTag({
    required this.label,
    required this.color,
    required this.icon,
    required this.priority,
  });
  
  final String label;
  final String color; // Hex color
  final String icon; // Material icon name
  final int priority; // Lower number = higher priority
  
  /// Convert hex color to integer
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}
