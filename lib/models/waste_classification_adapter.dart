import 'package:hive/hive.dart';

import 'waste_classification.dart';

/// Hive adapter that migrates legacy field indices during deserialization.
///
/// The generated adapter dropped HiveField(3) `subcategory` and
/// HiveField(4) `materialType` in favour of HiveField(68) `subCategory` and
/// HiveField(67) `materials`. This adapter restores backward-compatibility so
/// persisted Hive data from older app versions deserialises correctly.
///
/// Only `read()` is overridden. `write()` inherits from the generated
/// [WasteClassificationAdapter], so it stays in sync with the model
/// automatically after `build_runner` regenerations.
class MigratingWasteClassificationAdapter extends WasteClassificationAdapter {
  @override
  WasteClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Migrate legacy HiveField(3) → HiveField(68) if subCategory is absent.
    if (fields[68] == null && fields[3] != null) {
      fields[68] = fields[3];
    }
    // Migrate legacy HiveField(4) → HiveField(67) if materials is absent.
    if (fields[67] == null && fields[4] != null) {
      fields[67] = [fields[4]];
    }

    return WasteClassification(
      id: fields[0] as String?,
      itemName: fields[1] as String,
      category: fields[2] as String,
      recyclingCode: fields[5] as int?,
      explanation: fields[6] as String,
      disposalMethod: fields[7] as String?,
      disposalInstructions: fields[8] as DisposalInstructions,
      userId: fields[9] as String?,
      region: fields[10] as String,
      localGuidelinesReference: fields[11] as String?,
      imageUrl: fields[12] as String?,
      imageHash: fields[13] as String?,
      imageMetrics: (fields[14] as Map?)?.cast<String, double>(),
      visualFeatures: (fields[15] as List).cast<String>(),
      isRecyclable: fields[16] as bool?,
      isCompostable: fields[17] as bool?,
      requiresSpecialDisposal: fields[18] as bool?,
      isSingleUse: fields[19] as bool?,
      colorCode: fields[20] as String?,
      riskLevel: fields[21] as String?,
      requiredPPE: (fields[22] as List?)?.cast<String>(),
      brand: fields[23] as String?,
      product: fields[24] as String?,
      barcode: fields[25] as String?,
      isSaved: fields[26] as bool?,
      userConfirmed: fields[27] as bool?,
      userCorrection: fields[28] as String?,
      disagreementReason: fields[29] as String?,
      userNotes: fields[30] as String?,
      viewCount: fields[31] as int?,
      clarificationNeeded: fields[32] as bool?,
      confidence: fields[33] as double?,
      modelVersion: fields[34] as String?,
      processingTimeMs: fields[35] as int?,
      modelSource: fields[36] as String?,
      analysisSessionId: fields[37] as String?,
      alternatives: (fields[38] as List).cast<AlternativeClassification>(),
      suggestedAction: fields[39] as String?,
      hasUrgentTimeframe: fields[40] as bool?,
      instructionsLang: fields[41] as String?,
      translatedInstructions: (fields[42] as Map?)?.cast<String, String>(),
      source: fields[46] as String?,
      timestamp: fields[47] as DateTime?,
      reanalysisModelsTried: (fields[48] as List?)?.cast<String>(),
      confirmedByModel: fields[49] as String?,
      pointsAwarded: fields[43] as int?,
      environmentalImpact: fields[44] as String?,
      relatedItems: (fields[45] as List?)?.cast<String>(),
      imageRelativePath: fields[60] as String?,
      thumbnailRelativePath: fields[61] as String?,
      recyclability: fields[62] as String?,
      hazardLevel: fields[63] as int?,
      co2Impact: fields[64] as double?,
      decompositionTime: fields[65] as String?,
      properEquipment: (fields[66] as List?)?.cast<String>(),
      materials: (fields[67] as List?)?.cast<String>(),
      subCategory: fields[68] as String?,
      commonUses: (fields[69] as List?)?.cast<String>(),
      alternativeOptions: (fields[70] as List?)?.cast<String>(),
      localRegulations: (fields[71] as Map?)?.cast<String, String>(),
      waterPollutionLevel: fields[72] as int?,
      soilContaminationRisk: fields[73] as int?,
      biodegradabilityDays: fields[74] as int?,
      recyclingEfficiency: fields[75] as int?,
      manufacturingEnergyFootprint: fields[76] as double?,
      transportationFootprint: fields[77] as double?,
      endOfLifeCost: fields[78] as String?,
      circularEconomyPotential: (fields[79] as List?)?.cast<String>(),
      generatesMicroplastics: fields[80] as bool?,
      humanToxicityLevel: fields[81] as int?,
      wildlifeImpactSeverity: fields[82] as int?,
      resourceScarcity: fields[83] as String?,
      disposalCostEstimate: fields[84] as double?,
      bbmpComplianceStatus: fields[85] as String?,
      localGuidelinesVersion: fields[86] as String?,
      qualityScore: fields[87] as double?,
      qualityReasons: (fields[88] as List?)?.cast<String>(),
      duplicateScore: fields[89] as double?,
      duplicateClusterId: fields[90] as String?,
      rawConfidence: fields[91] as double?,
      calibratedConfidence: fields[92] as double?,
      needsReview: fields[93] as bool?,
      reviewReason: fields[94] as String?,
      routeDecision: fields[95] as String?,
      routeReason: fields[96] as String?,
      policyPackId: fields[97] as String?,
      modelRoute: fields[98] as String?,
      analysisSource: fields[101] as String?,
      analysisFallbackReason: fields[102] as String?,
      routeLatencyMs: fields[99] as int?,
      routeCostUsd: fields[100] as double?,
      modelSelectionStrategy: fields[103] as String?,
      isOfflineHint: (fields[104] as bool?) ?? false,
    );
  }
}
