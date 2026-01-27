// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ab_testing_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ABTestConfigAdapter extends TypeAdapter<ABTestConfig> {
  @override
  final int typeId = 34;

  @override
  ABTestConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ABTestConfig(
      testId: fields[0] as String,
      name: fields[1] as String,
      variants: (fields[2] as List).cast<ABTestVariant>(),
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime?,
      trafficAllocation: fields[5] as double,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ABTestConfig obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.testId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.variants)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.trafficAllocation)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ABTestConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ABTestVariantAdapter extends TypeAdapter<ABTestVariant> {
  @override
  final int typeId = 35;

  @override
  ABTestVariant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ABTestVariant(
      variantId: fields[0] as String,
      name: fields[1] as String,
      strategy: fields[2] as ModelSelectionStrategy,
      config: fields[3] as VisionModelConfig,
      weight: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ABTestVariant obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.variantId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.strategy)
      ..writeByte(3)
      ..write(obj.config)
      ..writeByte(4)
      ..write(obj.weight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ABTestVariantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ABTestResultAdapter extends TypeAdapter<ABTestResult> {
  @override
  final int typeId = 36;

  @override
  ABTestResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ABTestResult(
      testId: fields[0] as String,
      variantId: fields[1] as String,
      userId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      latencyMs: fields[4] as int,
      cost: fields[5] as double,
      accuracy: fields[6] as double,
      userSatisfaction: fields[7] as double?,
      converted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ABTestResult obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.testId)
      ..writeByte(1)
      ..write(obj.variantId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.latencyMs)
      ..writeByte(5)
      ..write(obj.cost)
      ..writeByte(6)
      ..write(obj.accuracy)
      ..writeByte(7)
      ..write(obj.userSatisfaction)
      ..writeByte(8)
      ..write(obj.converted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ABTestResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
