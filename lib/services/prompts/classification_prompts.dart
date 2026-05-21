import 'dart:convert';

class ClassificationPrompts {
  ClassificationPrompts._();

  static String systemPrompt(String defaultRegion) => '''
You are an expert in international waste classification, recycling, and proper disposal practices. 
You are familiar with global and local waste management rules (including $defaultRegion), brand-specific packaging, and recycling codes. 
Your goal is to provide accurate, actionable, and safe waste sorting guidance based on the latest environmental standards.
''';

  static String get mainClassificationPrompt => '''
Analyze the provided waste item and return a comprehensive JSON object with detailed environmental analysis. Use your knowledge of materials science, environmental impact, and waste management to provide accurate assessments.

Classification Hierarchy & Instructions:

1. BASIC CLASSIFICATION:
   - Main category: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, Non-Waste
   - Subcategory: Most specific classification (e.g., "PET Plastic", "Food Scraps", "E-waste")
   - Material type: Primary material composition
   - Recycling code: For plastics (1-7), if identifiable

2. ENVIRONMENTAL IMPACT ANALYSIS (Enhanced v2.0):
   - recyclability: "fully recyclable", "partially recyclable", "not recyclable"
   - hazardLevel: Integer 1-5 (1=safe, 5=extremely hazardous)
   - co2Impact: CO2 equivalent in kg (estimate lifecycle impact)
   - decompositionTime: Natural decomposition timeline (e.g., "6 months", "500 years")
   - waterPollutionLevel: Integer 1-5 (potential for water contamination)
   - soilContaminationRisk: Integer 1-5 (soil pollution risk)
   - biodegradabilityDays: Integer days for natural breakdown
   - recyclingEfficiency: Percentage 0-100 (how much can actually be recycled)
   - manufacturingEnergyFootprint: Energy in kWh to produce this item
   - transportationFootprint: CO2 kg for typical transport to disposal
   - endOfLifeCost: Environmental cost description (e.g., "landfill space", "toxic leachate")
   - generatesMicroplastics: Boolean (does this create microplastic pollution?)
   - humanToxicityLevel: Integer 1-5 (health risk to humans)
   - wildlifeImpactSeverity: Integer 1-5 (impact on animals/ecosystems)
   - resourceScarcity: "common", "uncommon", "rare" (how scarce are source materials?)
   - disposalCostEstimate: Estimated cost in INR for proper disposal

3. CIRCULAR ECONOMY ANALYSIS:
   - circularEconomyPotential: List of reuse/repurpose opportunities
   - materials: List of component materials for better sorting
   - commonUses: List of typical uses for this item
   - alternativeOptions: List of eco-friendly alternatives

4. LOCAL GUIDELINES (BANGALORE BBMP FOCUS):
   - bbmpComplianceStatus: "compliant", "requires_attention", "violation" (BBMP regulations)
   - localGuidelinesVersion: "BBMP 2024" or relevant local authority
   - localRegulations: Key-value pairs of local rules (e.g., {"color_coding": "green_bin", "collection_day": "tuesday"})

5. SAFETY & HANDLING:
   - properEquipment: List of required PPE (e.g., ["gloves", "mask", "eye_protection"])
   - requiredPPE: Safety equipment needed for handling
   - riskLevel: "safe", "caution", "hazardous"

6. STANDARD FIELDS:
   - Disposal instructions with primaryMethod, steps, timeframe, location, warnings, tips
   - Visual features, brand, product, barcode (if visible)
   - Confidence score (0.0-1.0), clarificationNeeded boolean
   - Alternative classifications with reasoning
   - Multi-language support (hi, kn, en)

7. DYNAMIC POINTS CALCULATION:
   Instead of fixed pointsAwarded, use calculatePoints() method which considers:
   - Data richness (more detailed analysis = more points)
   - Environmental complexity (hazardous items = bonus points)
   - Local compliance (BBMP compliance = bonus points)
   - Confidence level (high confidence = bonus points)
   Range: 5-50 points based on analysis quality

SPECIAL INSTRUCTIONS FOR BANGALORE:
- Reference BBMP waste segregation rules where applicable
- Consider monsoon disposal challenges (May-October)
- Include color-coded bin recommendations (Green/Brown/Red)
- Factor in apartment vs independent house disposal differences
- Consider local recycling market rates for valuable materials

Rules:
- Return ONLY the JSON object
- Include all environmental analysis fields
- Use scientific estimates for environmental impacts
- Reference actual BBMP guidelines when possible
- Set pointsAwarded to null (will be calculated dynamically)

JSON STRUCTURE with ALL fields: itemName, category, subcategory, materialType, recyclingCode, explanation, disposalMethod, disposalInstructions, region, localGuidelinesReference, imageUrl, imageHash, imageMetrics, visualFeatures, isRecyclable, isCompostable, requiresSpecialDisposal, colorCode, riskLevel, requiredPPE, brand, product, barcode, isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount, clarificationNeeded, confidence, modelVersion, processingTimeMs, modelSource, analysisSessionId, alternatives, suggestedAction, hasUrgentTimeframe, instructionsLang, translatedInstructions, pointsAwarded, isSingleUse, environmentalImpact, relatedItems, recyclability, hazardLevel, co2Impact, decompositionTime, properEquipment, materials, subCategory, commonUses, alternativeOptions, localRegulations, waterPollutionLevel, soilContaminationRisk, biodegradabilityDays, recyclingEfficiency, manufacturingEnergyFootprint, transportationFootprint, endOfLifeCost, circularEconomyPotential, generatesMicroplastics, humanToxicityLevel, wildlifeImpactSeverity, resourceScarcity, disposalCostEstimate, bbmpComplianceStatus, localGuidelinesVersion
''';

  static String correctionPrompt(
    Map<String, dynamic> previousClassification,
    String userCorrection,
    String? userReason,
  ) =>
      '''
A user has reviewed the waste item classification and provided feedback or a correction.  
Please re-analyze the item and return an updated JSON response, as per the data model, with special attention to:

- Areas of disagreement: Update the classification or reasoning as needed.
- clarificationNeeded: Set to true if ambiguity remains or confidence is low.
- disagreementReason: Explain why the original classification may have been incorrect, and how the user correction changes the analysis.

Input Context:
- Previous classification: ${jsonEncode(previousClassification)}
- User correction: "$userCorrection"
- Reason (if provided): "${userReason ?? 'Not provided'}"

Instructions:
- Update all relevant fields, especially category, subcategory, materialType, and explanation.
- Add a disagreementReason field, explaining the change or clarification.
- Use the same JSON model as before; fill all fields as per updated analysis.

Output:
- Only the updated JSON object.
''';
}
