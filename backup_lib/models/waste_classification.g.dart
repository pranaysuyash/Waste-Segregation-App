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
      itemName: fields[0] as String,
      category: fields[1] as String,
      subcategory: fields[2] as String?,
      explanation: fields[3] as String,
      imageUrl: fields[4] as String?,
      disposalMethod: fields[5] as String?,
      recyclingCode: fields[6] as String?,
      isRecyclable: fields[8] as bool?,
      isCompostable: fields[9] as bool?,
      requiresSpecialDisposal: fields[10] as bool?,
      colorCode: fields[11] as String?,
      materialType: fields[12] as String?,
      timestamp: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WasteClassification obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.subcategory)
      ..writeByte(3)
      ..write(obj.explanation)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.disposalMethod)
      ..writeByte(6)
      ..write(obj.recyclingCode)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.isRecyclable)
      ..writeByte(9)
      ..write(obj.isCompostable)
      ..writeByte(10)
      ..write(obj.requiresSpecialDisposal)
      ..writeByte(11)
      ..write(obj.colorCode)
      ..writeByte(12)
      ..write(obj.materialType);
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
