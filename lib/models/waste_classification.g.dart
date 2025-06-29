// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waste_classification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WasteClassificationAdapter extends TypeAdapter<WasteClassification> {
  @override
  final int typeId = 0;

  @override
  WasteClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WasteClassification(
      id: fields[0] as String?,
      itemName: fields[1] as String,
      category: fields[2] as String,
      subcategory: fields[3] as String?,
      materialType: fields[4] as String?,
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
    );
  }

  @override
  void write(BinaryWriter writer, WasteClassification obj) {
    writer
      ..writeByte(77)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.subcategory)
      ..writeByte(4)
      ..write(obj.materialType)
      ..writeByte(5)
      ..write(obj.recyclingCode)
      ..writeByte(6)
      ..write(obj.explanation)
      ..writeByte(7)
      ..write(obj.disposalMethod)
      ..writeByte(8)
      ..write(obj.disposalInstructions)
      ..writeByte(9)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.region)
      ..writeByte(11)
      ..write(obj.localGuidelinesReference)
      ..writeByte(12)
      ..write(obj.imageUrl)
      ..writeByte(60)
      ..write(obj.imageRelativePath)
      ..writeByte(61)
      ..write(obj.thumbnailRelativePath)
      ..writeByte(13)
      ..write(obj.imageHash)
      ..writeByte(14)
      ..write(obj.imageMetrics)
      ..writeByte(15)
      ..write(obj.visualFeatures)
      ..writeByte(16)
      ..write(obj.isRecyclable)
      ..writeByte(17)
      ..write(obj.isCompostable)
      ..writeByte(18)
      ..write(obj.requiresSpecialDisposal)
      ..writeByte(19)
      ..write(obj.isSingleUse)
      ..writeByte(20)
      ..write(obj.colorCode)
      ..writeByte(21)
      ..write(obj.riskLevel)
      ..writeByte(22)
      ..write(obj.requiredPPE)
      ..writeByte(23)
      ..write(obj.brand)
      ..writeByte(24)
      ..write(obj.product)
      ..writeByte(25)
      ..write(obj.barcode)
      ..writeByte(26)
      ..write(obj.isSaved)
      ..writeByte(27)
      ..write(obj.userConfirmed)
      ..writeByte(28)
      ..write(obj.userCorrection)
      ..writeByte(29)
      ..write(obj.disagreementReason)
      ..writeByte(30)
      ..write(obj.userNotes)
      ..writeByte(31)
      ..write(obj.viewCount)
      ..writeByte(32)
      ..write(obj.clarificationNeeded)
      ..writeByte(33)
      ..write(obj.confidence)
      ..writeByte(34)
      ..write(obj.modelVersion)
      ..writeByte(35)
      ..write(obj.processingTimeMs)
      ..writeByte(36)
      ..write(obj.modelSource)
      ..writeByte(37)
      ..write(obj.analysisSessionId)
      ..writeByte(38)
      ..write(obj.alternatives)
      ..writeByte(39)
      ..write(obj.suggestedAction)
      ..writeByte(40)
      ..write(obj.hasUrgentTimeframe)
      ..writeByte(41)
      ..write(obj.instructionsLang)
      ..writeByte(42)
      ..write(obj.translatedInstructions)
      ..writeByte(43)
      ..write(obj.pointsAwarded)
      ..writeByte(44)
      ..write(obj.environmentalImpact)
      ..writeByte(45)
      ..write(obj.relatedItems)
      ..writeByte(46)
      ..write(obj.source)
      ..writeByte(47)
      ..write(obj.timestamp)
      ..writeByte(48)
      ..write(obj.reanalysisModelsTried)
      ..writeByte(49)
      ..write(obj.confirmedByModel)
      ..writeByte(62)
      ..write(obj.recyclability)
      ..writeByte(63)
      ..write(obj.hazardLevel)
      ..writeByte(64)
      ..write(obj.co2Impact)
      ..writeByte(65)
      ..write(obj.decompositionTime)
      ..writeByte(66)
      ..write(obj.properEquipment)
      ..writeByte(67)
      ..write(obj.materials)
      ..writeByte(68)
      ..write(obj.subCategory)
      ..writeByte(69)
      ..write(obj.commonUses)
      ..writeByte(70)
      ..write(obj.alternativeOptions)
      ..writeByte(71)
      ..write(obj.localRegulations)
      ..writeByte(72)
      ..write(obj.waterPollutionLevel)
      ..writeByte(73)
      ..write(obj.soilContaminationRisk)
      ..writeByte(74)
      ..write(obj.biodegradabilityDays)
      ..writeByte(75)
      ..write(obj.recyclingEfficiency)
      ..writeByte(76)
      ..write(obj.manufacturingEnergyFootprint)
      ..writeByte(77)
      ..write(obj.transportationFootprint)
      ..writeByte(78)
      ..write(obj.endOfLifeCost)
      ..writeByte(79)
      ..write(obj.circularEconomyPotential)
      ..writeByte(80)
      ..write(obj.generatesMicroplastics)
      ..writeByte(81)
      ..write(obj.humanToxicityLevel)
      ..writeByte(82)
      ..write(obj.wildlifeImpactSeverity)
      ..writeByte(83)
      ..write(obj.resourceScarcity)
      ..writeByte(84)
      ..write(obj.disposalCostEstimate)
      ..writeByte(85)
      ..write(obj.bbmpComplianceStatus)
      ..writeByte(86)
      ..write(obj.localGuidelinesVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WasteClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlternativeClassificationAdapter
    extends TypeAdapter<AlternativeClassification> {
  @override
  final int typeId = 1;

  @override
  AlternativeClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlternativeClassification(
      category: fields[0] as String,
      subcategory: fields[1] as String?,
      confidence: fields[2] as double,
      reason: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlternativeClassification obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.subcategory)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlternativeClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DisposalInstructionsAdapter extends TypeAdapter<DisposalInstructions> {
  @override
  final int typeId = 2;

  @override
  DisposalInstructions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DisposalInstructions(
      primaryMethod: fields[0] as String,
      steps: (fields[1] as List).cast<String>(),
      timeframe: fields[2] as String?,
      location: fields[3] as String?,
      warnings: (fields[4] as List?)?.cast<String>(),
      tips: (fields[5] as List?)?.cast<String>(),
      recyclingInfo: fields[6] as String?,
      estimatedTime: fields[7] as String?,
      hasUrgentTimeframe: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DisposalInstructions obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.primaryMethod)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.timeframe)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.warnings)
      ..writeByte(5)
      ..write(obj.tips)
      ..writeByte(6)
      ..write(obj.recyclingInfo)
      ..writeByte(7)
      ..write(obj.estimatedTime)
      ..writeByte(8)
      ..write(obj.hasUrgentTimeframe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisposalInstructionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
