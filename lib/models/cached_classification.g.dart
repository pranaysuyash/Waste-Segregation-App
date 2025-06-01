// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_classification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedClassificationAdapter extends TypeAdapter<CachedClassification> {
  @override
  final int typeId = 2;

  @override
  CachedClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedClassification(
      imageHash: fields[0] as String,
      classification: fields[1] as WasteClassification,
      timestamp: fields[2] as DateTime?,
      lastAccessed: fields[3] as DateTime?,
      useCount: fields[4] as int,
      imageSize: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedClassification obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.imageHash)
      ..writeByte(1)
      ..write(obj.classification)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.lastAccessed)
      ..writeByte(4)
      ..write(obj.useCount)
      ..writeByte(5)
      ..write(obj.imageSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
