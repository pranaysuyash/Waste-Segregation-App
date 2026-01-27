/// Test fixtures for WasteClassification
/// 
/// These fixtures represent the 15 canonical classification scenarios.
/// Used for:
/// - Golden tests (pipeline output verification)
/// - Widget tests (UI state rendering)
/// - Integration tests (end-to-end flows)
/// 
/// DO NOT MODIFY without updating snapshots and parity checklist.

import 'package:waste_segregation_app/models/waste_classification.dart';

/// Fixture IDs for reference in tests
class ClassificationFixtureIds {
  static const String plasticBottle = 'fixture-plastic-bottle';
  static const String wetWasteFood = 'fixture-wet-waste-food';
  static const String eWastePhone = 'fixture-ewaste-phone';
  static const String glassBottle = 'fixture-glass-bottle';
  static const String paperCardboard = 'fixture-paper-cardboard';
  static const String medicalWaste = 'fixture-medical-waste';
  static const String hazardousBattery = 'fixture-hazardous-battery';
  static const String metalCan = 'fixture-metal-can';
  static const String textileClothing = 'fixture-textile-clothing';
  static const String unknownLowConfidence = 'fixture-unknown-low-conf';
  static const String unknownUnclear = 'fixture-unknown-unclear';
  static const String multiMaterial = 'fixture-multi-material';
  static const String singleUsePlastic = 'fixture-single-use-plastic';
  static const String compostable = 'fixture-compostable';
  static const String requiresPPE = 'fixture-requires-ppe';
}

/// 1. Standard recyclable - plastic bottle
/// Expected: High confidence, clear disposal, shareable
WasteClassification get plasticBottleFixture => WasteClassification(
      id: ClassificationFixtureIds.plasticBottle,
      itemName: 'Plastic Water Bottle',
      category: 'Dry Waste',
      subcategory: 'Recyclable Plastic',
      materialType: 'PET (Polyethylene Terephthalate)',
      recyclingCode: 1,
      explanation:
          'Clear plastic bottle with recycling symbol #1 (PET). Clean and empty.',
      disposalMethod: 'Recycle',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Rinse and place in recycling bin',
        steps: [
          'Empty any remaining liquid',
          'Rinse briefly to remove residue',
          'Crush to save space (optional)',
          'Place in dry waste/recycling bin',
          'Keep cap on (check local guidelines)',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Do not burn - releases toxic fumes',
          'Do not litter - takes 450 years to decompose',
        ],
        tips: [
          'Caps can often be recycled with bottle',
          'Labels can stay on',
          'Consider reusable bottle alternatives',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['transparent', 'cylindrical', 'ridged'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: true,
      colorCode: '#2196F3',
      riskLevel: 'low',
      confidence: 0.94,
      modelVersion: 'v2.1',
      processingTimeMs: 850,
      alternatives: [
        AlternativeClassification(
          category: 'Hazardous Waste',
          subcategory: 'Chemical Container',
          confidence: 0.12,
          reason: 'If bottle contained chemicals or cleaning products',
        ),
      ],
      timestamp: DateTime(2026, 1, 15, 10, 30),
    );

/// 2. Wet waste - food scraps
/// Expected: Compostable, different color coding
WasteClassification get wetWasteFoodFixture => WasteClassification(
      id: ClassificationFixtureIds.wetWasteFood,
      itemName: 'Vegetable Peelings and Food Scraps',
      category: 'Wet Waste',
      subcategory: 'Food Waste',
      materialType: 'Organic Matter',
      explanation:
          'Organic food waste including vegetable peels, fruit scraps, and leftover food.',
      disposalMethod: 'Compost',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Place in wet waste bin or compost',
        steps: [
          'Collect in sealed container to prevent odors',
          'Place in green wet waste bin',
          'Or add to home compost pile',
          'Layer with dry leaves if composting',
        ],
        hasUrgentTimeframe: true,
        timeframe: 'Dispose within 24 hours to prevent odor/pests',
        warnings: [
          'Do not mix with dry waste',
          'Seal properly to prevent pest attraction',
        ],
        tips: [
          'Can be composted at home',
          'Great for garden fertilizer',
          'Reduces landfill methane emissions',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['organic', 'biodegradable', 'moist'],
      isRecyclable: false,
      isCompostable: true,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#4CAF50',
      riskLevel: 'low',
      confidence: 0.91,
      modelVersion: 'v2.1',
      processingTimeMs: 720,
      alternatives: [],
      timestamp: DateTime(2026, 1, 15, 12, 0),
    );

/// 3. E-waste - mobile phone
/// Expected: Special disposal, higher risk level
WasteClassification get eWastePhoneFixture => WasteClassification(
      id: ClassificationFixtureIds.eWastePhone,
      itemName: 'Old Mobile Phone',
      category: 'E-Waste',
      subcategory: 'Electronic Device',
      materialType: 'Mixed Electronics',
      explanation:
          'Electronic device containing batteries, circuit boards, and rare earth metals.',
      disposalMethod: 'E-Waste Collection',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Take to e-waste collection center',
        steps: [
          'Back up and wipe personal data',
          'Remove SIM and memory cards',
          'Do not throw in regular trash',
          'Find e-waste drop-off location',
          'Or schedule e-waste pickup',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Contains lithium battery - fire hazard if damaged',
          'Contains heavy metals - toxic if landfilled',
          'Personal data risk if not wiped',
        ],
        tips: [
          'Many retailers accept old phones',
          'Consider trade-in programs',
          'Remove batteries if possible',
          'Check for buyback programs',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['electronic', 'rectangular', 'screen'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: true,
      isSingleUse: false,
      colorCode: '#FF9800',
      riskLevel: 'medium',
      requiredPPE: ['gloves'],
      confidence: 0.88,
      modelVersion: 'v2.1',
      processingTimeMs: 1100,
      alternatives: [],
      timestamp: DateTime(2026, 1, 15, 14, 15),
    );

/// 4. Glass bottle
/// Expected: Recyclable but different handling than plastic
WasteClassification get glassBottleFixture => WasteClassification(
      id: ClassificationFixtureIds.glassBottle,
      itemName: 'Glass Sauce Jar',
      category: 'Dry Waste',
      subcategory: 'Glass',
      materialType: 'Glass',
      recyclingCode: 70,
      explanation: 'Clear glass container. Infinitely recyclable without quality loss.',
      disposalMethod: 'Recycle',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Rinse and recycle',
        steps: [
          'Remove lid (recycle separately if metal)',
          'Rinse out residue',
          'Place in recycling bin',
          'Do not break intentionally',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Broken glass - handle carefully',
          'Do not mix with other recyclables if broken',
        ],
        tips: [
          'Glass can be recycled infinitely',
          'Remove labels if required locally',
          'Great for storage reuse',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['transparent', 'rigid', 'smooth'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#2196F3',
      riskLevel: 'low',
      confidence: 0.93,
      modelVersion: 'v2.1',
      processingTimeMs: 680,
      alternatives: [],
      timestamp: DateTime(2026, 1, 15, 16, 45),
    );

/// 5. Paper/Cardboard
/// Expected: Recyclable, biodegradable
WasteClassification get paperCardboardFixture => WasteClassification(
      id: ClassificationFixtureIds.paperCardboard,
      itemName: 'Cardboard Box',
      category: 'Dry Waste',
      subcategory: 'Paper',
      materialType: 'Cardboard',
      recyclingCode: 20,
      explanation: 'Clean cardboard packaging material. Highly recyclable.',
      disposalMethod: 'Recycle',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Flatten and recycle',
        steps: [
          'Remove tape and labels',
          'Flatten to save space',
          'Keep dry',
          'Place in recycling bin',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Wet/soiled paper cannot be recycled',
          'Greasy pizza boxes go to compost',
        ],
        tips: [
          'Can be composted if soiled',
          'Great for garden mulch',
          'Reuse for storage',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['brown', 'fibrous', 'foldable'],
      isRecyclable: true,
      isCompostable: true,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#2196F3',
      riskLevel: 'low',
      confidence: 0.89,
      modelVersion: 'v2.1',
      processingTimeMs: 590,
      alternatives: [],
      timestamp: DateTime(2026, 1, 16, 9, 0),
    );

/// 6. Medical waste
/// Expected: High risk, special handling, warnings
WasteClassification get medicalWasteFixture => WasteClassification(
      id: ClassificationFixtureIds.medicalWaste,
      itemName: 'Used Syringe',
      category: 'Biomedical Waste',
      subcategory: 'Sharps',
      materialType: 'Medical Waste',
      explanation:
          'Medical sharp object. Biohazard risk. Special disposal required.',
      disposalMethod: 'Biohazard Disposal',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Place in sharps container',
        steps: [
          'DO NOT recap needle',
          'Place immediately in sharps container',
          'If no container, hard puncture-proof container',
          'Take to hospital/medical facility',
          'Never put in regular trash',
        ],
        hasUrgentTimeframe: true,
        timeframe: 'Immediate safe disposal required',
        warnings: [
          'NEVER handle with bare hands',
          'Puncture and infection risk',
          'Bloodborne pathogen hazard',
          'Illegal to dispose in regular trash',
        ],
        tips: [
          'Hospitals accept household medical waste',
          'Some pharmacies have sharps disposal',
          'Never try to bend or break needles',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['sharp', 'medical', 'plastic'],
      isRecyclable: false,
      isCompostable: false,
      requiresSpecialDisposal: true,
      isSingleUse: true,
      colorCode: '#F44336',
      riskLevel: 'high',
      requiredPPE: ['gloves', 'tongs'],
      confidence: 0.87,
      modelVersion: 'v2.1',
      processingTimeMs: 1250,
      alternatives: [],
      timestamp: DateTime(2026, 1, 16, 11, 30),
    );

/// 7. Hazardous - battery
/// Expected: Special disposal, environmental warnings
WasteClassification get hazardousBatteryFixture => WasteClassification(
      id: ClassificationFixtureIds.hazardousBattery,
      itemName: 'AA Battery',
      category: 'Hazardous Waste',
      subcategory: 'Battery',
      materialType: 'Alkaline/Manganese',
      explanation:
          'Household battery containing heavy metals. Toxic if landfilled.',
      disposalMethod: 'Hazardous Waste Collection',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Take to hazardous waste collection',
        steps: [
          'Store in dry place until disposal',
          'Tape terminals with non-conductive tape',
          'Find battery recycling location',
          'Do not throw in regular trash',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Contains mercury, lead, or cadmium',
          'Can leak and contaminate soil/water',
          'Fire hazard if terminals touch metal',
          'Toxic to wildlife',
        ],
        tips: [
          'Use rechargeable batteries instead',
          'Many electronics stores accept batteries',
          'Store different types separately',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['cylindrical', 'metallic', 'small'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: true,
      isSingleUse: true,
      colorCode: '#F44336',
      riskLevel: 'medium',
      requiredPPE: ['gloves'],
      confidence: 0.85,
      modelVersion: 'v2.1',
      processingTimeMs: 980,
      alternatives: [],
      timestamp: DateTime(2026, 1, 16, 13, 45),
    );

/// 8. Metal can
/// Expected: Recyclable, magnetic
WasteClassification get metalCanFixture => WasteClassification(
      id: ClassificationFixtureIds.metalCan,
      itemName: 'Aluminum Soda Can',
      category: 'Dry Waste',
      subcategory: 'Metal',
      materialType: 'Aluminum',
      recyclingCode: 41,
      explanation:
          'Aluminum beverage can. Highly valuable recyclable material.',
      disposalMethod: 'Recycle',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Rinse and recycle',
        steps: [
          'Rinse out residue',
          'Crush to save space (optional)',
          'Place in recycling bin',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Sharp edges if crushed improperly',
        ],
        tips: [
          'Aluminum recycles forever',
          'Most valuable household recyclable',
          'Recycling saves 95% energy vs new aluminum',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['metallic', 'cylindrical', 'light'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: true,
      colorCode: '#2196F3',
      riskLevel: 'low',
      confidence: 0.92,
      modelVersion: 'v2.1',
      processingTimeMs: 640,
      alternatives: [],
      timestamp: DateTime(2026, 1, 16, 15, 20),
    );

/// 9. Textile/Clothing
/// Expected: Reusable, donation option
WasteClassification get textileClothingFixture => WasteClassification(
      id: ClassificationFixtureIds.textileClothing,
      itemName: 'Cotton T-Shirt',
      category: 'Dry Waste',
      subcategory: 'Textile',
      materialType: 'Cotton',
      explanation: 'Clean cotton clothing. Can be donated or recycled.',
      disposalMethod: 'Donate or Recycle',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Donate if usable, recycle if worn',
        steps: [
          'If in good condition: donate to charity',
          'If worn out: textile recycling',
          'Wash before donating',
          'Check for stains or tears',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Do not throw in regular trash if avoidable',
        ],
        tips: [
          'Many charities accept used clothing',
          'Some retailers have textile recycling',
          'Can be repurposed as rags',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['fabric', 'soft', 'foldable'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#2196F3',
      riskLevel: 'low',
      confidence: 0.86,
      modelVersion: 'v2.1',
      processingTimeMs: 780,
      alternatives: [],
      timestamp: DateTime(2026, 1, 17, 10, 0),
    );

/// 10. Unknown - low confidence
/// Expected: Fallback UI, feedback prompt
WasteClassification get unknownLowConfidenceFixture => WasteClassification(
      id: ClassificationFixtureIds.unknownLowConfidence,
      itemName: 'Unknown Item',
      category: 'Requires Manual Review',
      subcategory: 'Low Confidence',
      explanation:
          'AI confidence too low for reliable classification. Manual review needed.',
      disposalMethod: 'Manual Identification',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Identify manually or seek help',
        steps: [
          'Try to identify material type visually',
          'Check for labels or markings',
          'When in doubt, contact waste authority',
          'Use feedback to help improve AI',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Do not dispose until properly identified',
          'May require special handling',
        ],
        tips: [
          'Take clearer photo with better lighting',
          'Ensure item fills most of frame',
          'Remove confusing background objects',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: [],
      isRecyclable: false,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#9E9E9E',
      riskLevel: 'unknown',
      confidence: 0.32,
      modelVersion: 'v2.1',
      processingTimeMs: 1200,
      clarificationNeeded: true,
      alternatives: [
        AlternativeClassification(
          category: 'Dry Waste',
          subcategory: 'Mixed',
          confidence: 0.28,
          reason: 'If appears to be non-organic material',
        ),
        AlternativeClassification(
          category: 'Wet Waste',
          subcategory: 'Organic',
          confidence: 0.21,
          reason: 'If appears to be food or plant matter',
        ),
      ],
      timestamp: DateTime(2026, 1, 17, 12, 30),
    );

/// 11. Unknown - unclear image
/// Expected: Different from low confidence - image quality issue
WasteClassification get unknownUnclearFixture => WasteClassification.fallback(
      'test_image_unclear.jpg',
      id: ClassificationFixtureIds.unknownUnclear,
    );

/// 12. Multi-material item
/// Expected: Complex disposal, multiple steps
WasteClassification get multiMaterialFixture => WasteClassification(
      id: ClassificationFixtureIds.multiMaterial,
      itemName: 'Tetra Pak Carton',
      category: 'Dry Waste',
      subcategory: 'Multi-material',
      materialType: 'Paper-Plastic-Aluminum Composite',
      explanation:
          'Multi-layer packaging. Requires special recycling process.',
      disposalMethod: 'Special Recycling',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Rinse and recycle at designated facility',
        steps: [
          'Rinse thoroughly',
          'Flatten to save space',
          'Check for local Tetra Pak recycling',
          'Some areas accept in regular recycling',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Cannot be recycled in standard paper stream',
          'Do not burn - mixed materials release toxins',
        ],
        tips: [
          'Check brand-specific recycling programs',
          'Some stores accept these for recycling',
          'Consider buying alternatives with less packaging',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['rectangular', 'layered', 'printed'],
      isRecyclable: true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: true,
      colorCode: '#FF9800',
      riskLevel: 'low',
      confidence: 0.79,
      modelVersion: 'v2.1',
      processingTimeMs: 1050,
      alternatives: [],
      timestamp: DateTime(2026, 1, 17, 14, 45),
    );

/// 13. Single-use plastic
/// Expected: Environmental impact messaging
WasteClassification get singleUsePlasticFixture => WasteClassification(
      id: ClassificationFixtureIds.singleUsePlastic,
      itemName: 'Plastic Straw',
      category: 'Dry Waste',
      subcategory: 'Single-Use Plastic',
      materialType: 'PP (Polypropylene)',
      explanation:
          'Single-use plastic item. Non-biodegradable. Avoid if possible.',
      disposalMethod: 'Landfill (unfortunately)',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Dispose in dry waste',
        steps: [
          'If clean: dry waste bin',
          'If soiled: wrap in paper first',
          'Consider refusing in future',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Too small for most recycling facilities',
          'Often contaminates recycling streams',
          'Takes 200+ years to decompose',
        ],
        tips: [
          'Switch to reusable metal/bamboo straws',
          'Refuse straws when ordering drinks',
          'Paper straws are better alternative',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['small', 'cylindrical', 'light'],
      isRecyclable: false,
      isCompostable: false,
      requiresSpecialDisposal: false,
      isSingleUse: true,
      colorCode: '#FF5722',
      riskLevel: 'low',
      confidence: 0.88,
      modelVersion: 'v2.1',
      processingTimeMs: 560,
      alternatives: [],
      timestamp: DateTime(2026, 1, 18, 9, 15),
    );

/// 14. Compostable (not food)
/// Expected: Home composting option
WasteClassification get compostableFixture => WasteClassification(
      id: ClassificationFixtureIds.compostable,
      itemName: 'Fallen Leaves',
      category: 'Wet Waste',
      subcategory: 'Yard Waste',
      materialType: 'Organic Plant Matter',
      explanation: 'Natural plant debris. Excellent composting material.',
      disposalMethod: 'Compost',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Compost at home or green bin',
        steps: [
          'Collect dry leaves',
          'Layer with green waste in compost',
          'Or place in wet waste bin',
          'Do not burn - air pollution',
        ],
        hasUrgentTimeframe: false,
        warnings: [
          'Do not burn - illegal in many areas',
          'Smoke hazard',
        ],
        tips: [
          'Great "brown" material for composting',
          'Can be used as garden mulch',
          'Shred for faster decomposition',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['dry', 'organic', 'leaf-shaped'],
      isRecyclable: false,
      isCompostable: true,
      requiresSpecialDisposal: false,
      isSingleUse: false,
      colorCode: '#4CAF50',
      riskLevel: 'low',
      confidence: 0.90,
      modelVersion: 'v2.1',
      processingTimeMs: 520,
      alternatives: [],
      timestamp: DateTime(2026, 1, 18, 11, 0),
    );

/// 15. Requires PPE
/// Expected: Safety warnings, equipment recommendations
WasteClassification get requiresPPEFixture => WasteClassification(
      id: ClassificationFixtureIds.requiresPPE,
      itemName: 'Broken Fluorescent Tube',
      category: 'Hazardous Waste',
      subcategory: 'Universal Waste',
      materialType: 'Glass with Mercury',
      explanation:
          'Contains mercury vapor. Toxic if released. Special handling required.',
      disposalMethod: 'Hazardous Waste Facility',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Take to hazardous waste facility',
        steps: [
          'Wear gloves and mask',
          'Do not use vacuum cleaner',
          'Ventilate area if broken',
          'Place in sealed container',
          'Take to designated facility',
        ],
        hasUrgentTimeframe: true,
        timeframe: 'Secure immediately if broken',
        warnings: [
          'CONTAINS MERCURY - neurotoxin',
          'Never use vacuum - spreads vapor',
          'Broken glass hazard',
          'Harmful if inhaled',
        ],
        tips: [
          'Consider LED alternatives',
          'Some retailers accept CFLs',
          'Keep original packaging for transport',
        ],
      ),
      region: 'Bangalore',
      visualFeatures: ['glass', 'tubular', 'fragile'],
      isRecyclable: false,
      isCompostable: false,
      requiresSpecialDisposal: true,
      isSingleUse: false,
      colorCode: '#F44336',
      riskLevel: 'high',
      requiredPPE: ['gloves', 'mask', 'eye_protection'],
      confidence: 0.84,
      modelVersion: 'v2.1',
      processingTimeMs: 1150,
      alternatives: [],
      timestamp: DateTime(2026, 1, 18, 13, 30),
    );

/// All fixtures as a list for batch testing
List<WasteClassification> get allClassificationFixtures => [
      plasticBottleFixture,
      wetWasteFoodFixture,
      eWastePhoneFixture,
      glassBottleFixture,
      paperCardboardFixture,
      medicalWasteFixture,
      hazardousBatteryFixture,
      metalCanFixture,
      textileClothingFixture,
      unknownLowConfidenceFixture,
      unknownUnclearFixture,
      multiMaterialFixture,
      singleUsePlasticFixture,
      compostableFixture,
      requiresPPEFixture,
    ];

/// Fixtures by category for category-specific tests
Map<String, List<WasteClassification>> get fixturesByCategory => {
      'Dry Waste': [
        plasticBottleFixture,
        glassBottleFixture,
        paperCardboardFixture,
        metalCanFixture,
        textileClothingFixture,
        multiMaterialFixture,
        singleUsePlasticFixture,
      ],
      'Wet Waste': [
        wetWasteFoodFixture,
        compostableFixture,
      ],
      'E-Waste': [
        eWastePhoneFixture,
      ],
      'Hazardous Waste': [
        hazardousBatteryFixture,
        requiresPPEFixture,
      ],
      'Biomedical Waste': [
        medicalWasteFixture,
      ],
      'Unknown': [
        unknownLowConfidenceFixture,
        unknownUnclearFixture,
      ],
    };

/// High-risk fixtures for safety-critical tests
List<WasteClassification> get highRiskFixtures => [
      medicalWasteFixture,
      hazardousBatteryFixture,
      requiresPPEFixture,
    ];

/// Recyclable fixtures for positive-path tests
List<WasteClassification> get recyclableFixtures => [
      plasticBottleFixture,
      glassBottleFixture,
      paperCardboardFixture,
      metalCanFixture,
      textileClothingFixture,
    ];
