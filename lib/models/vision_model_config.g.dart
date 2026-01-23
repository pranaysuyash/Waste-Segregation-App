// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vision_model_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisionModelTypeAdapter extends TypeAdapter<VisionModelType> {
  @override
  final int typeId = 30;

  @override
  VisionModelType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VisionModelType.smolVLM;
      case 1:
        return VisionModelType.mobileNetV3;
      case 2:
        return VisionModelType.efficientNet;
      case 3:
        return VisionModelType.yoloV8;
      case 4:
        return VisionModelType.yoloV11;
      case 5:
        return VisionModelType.openAI;
      case 6:
        return VisionModelType.gemini;
      case 7:
        return VisionModelType.roboflowCustom;
      case 8:
        return VisionModelType.tfliteCustom;
      default:
        return VisionModelType.smolVLM;
    }
  }

  @override
  void write(BinaryWriter writer, VisionModelType obj) {
    switch (obj) {
      case VisionModelType.smolVLM:
        writer.writeByte(0);
        break;
      case VisionModelType.mobileNetV3:
        writer.writeByte(1);
        break;
      case VisionModelType.efficientNet:
        writer.writeByte(2);
        break;
      case VisionModelType.yoloV8:
        writer.writeByte(3);
        break;
      case VisionModelType.yoloV11:
        writer.writeByte(4);
        break;
      case VisionModelType.openAI:
        writer.writeByte(5);
        break;
      case VisionModelType.gemini:
        writer.writeByte(6);
        break;
      case VisionModelType.roboflowCustom:
        writer.writeByte(7);
        break;
      case VisionModelType.tfliteCustom:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionModelTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnalysisModeAdapter extends TypeAdapter<AnalysisMode> {
  @override
  final int typeId = 31;

  @override
  AnalysisMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnalysisMode.instant;
      case 1:
        return AnalysisMode.batch;
      case 2:
        return AnalysisMode.onDevice;
      case 3:
        return AnalysisMode.hybrid;
      default:
        return AnalysisMode.instant;
    }
  }

  @override
  void write(BinaryWriter writer, AnalysisMode obj) {
    switch (obj) {
      case AnalysisMode.instant:
        writer.writeByte(0);
        break;
      case AnalysisMode.batch:
        writer.writeByte(1);
        break;
      case AnalysisMode.onDevice:
        writer.writeByte(2);
        break;
      case AnalysisMode.hybrid:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisionModelConfigAdapter extends TypeAdapter<VisionModelConfig> {
  @override
  final int typeId = 32;

  @override
  VisionModelConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisionModelConfig(
      modelType: fields[0] as VisionModelType,
      analysisMode: fields[1] as AnalysisMode,
      confidenceThreshold: fields[2] as double,
      maxImageSize: fields[3] as int,
      enableObjectDetection: fields[4] as bool,
      enableSegmentation: fields[5] as bool,
      batchSize: fields[6] as int,
      batchTimeoutSeconds: fields[7] as int,
      modelVersion: fields[8] as String?,
      customModelPath: fields[9] as String?,
      roboflowApiKey: fields[10] as String?,
      roboflowWorkspace: fields[11] as String?,
      roboflowProject: fields[12] as String?,
      preferOnDevice: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VisionModelConfig obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.modelType)
      ..writeByte(1)
      ..write(obj.analysisMode)
      ..writeByte(2)
      ..write(obj.confidenceThreshold)
      ..writeByte(3)
      ..write(obj.maxImageSize)
      ..writeByte(4)
      ..write(obj.enableObjectDetection)
      ..writeByte(5)
      ..write(obj.enableSegmentation)
      ..writeByte(6)
      ..write(obj.batchSize)
      ..writeByte(7)
      ..write(obj.batchTimeoutSeconds)
      ..writeByte(8)
      ..write(obj.modelVersion)
      ..writeByte(9)
      ..write(obj.customModelPath)
      ..writeByte(10)
      ..write(obj.roboflowApiKey)
      ..writeByte(11)
      ..write(obj.roboflowWorkspace)
      ..writeByte(12)
      ..write(obj.roboflowProject)
      ..writeByte(13)
      ..write(obj.preferOnDevice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionModelConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModelPerformanceMetricsAdapter extends TypeAdapter<ModelPerformanceMetrics> {
  @override
  final int typeId = 33;

  @override
  ModelPerformanceMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModelPerformanceMetrics(
      modelType: fields[0] as VisionModelType,
      totalInferences: fields[1] as int,
      averageLatencyMs: fields[2] as double,
      averageConfidence: fields[3] as double,
      successRate: fields[4] as double,
      totalCost: fields[5] as double,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ModelPerformanceMetrics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.modelType)
      ..writeByte(1)
      ..write(obj.totalInferences)
      ..writeByte(2)
      ..write(obj.averageLatencyMs)
      ..writeByte(3)
      ..write(obj.averageConfidence)
      ..writeByte(4)
      ..write(obj.successRate)
      ..writeByte(5)
      ..write(obj.totalCost)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelPerformanceMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
