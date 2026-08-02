// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_queue_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeadLetterClassificationAdapter
    extends TypeAdapter<DeadLetterClassification> {
  @override
  final int typeId = 101;

  @override
  DeadLetterClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeadLetterClassification(
      id: fields[0] as String,
      imageBytes: fields[1] as Uint8List,
      region: fields[2] as String,
      queuedAt: fields[3] as DateTime,
      failedAt: fields[6] as DateTime,
      retryCount: fields[4] as int,
      lastError: fields[5] as String,
      userId: fields[7] as String?,
      imageName: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeadLetterClassification obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageBytes)
      ..writeByte(2)
      ..write(obj.region)
      ..writeByte(3)
      ..write(obj.queuedAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.lastError)
      ..writeByte(6)
      ..write(obj.failedAt)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.imageName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadLetterClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QueuedClassificationAdapter extends TypeAdapter<QueuedClassification> {
  @override
  final int typeId = 100;

  @override
  QueuedClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedClassification(
      id: fields[0] as String,
      imageBytes: fields[1] as Uint8List,
      region: fields[2] as String,
      queuedAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
      userId: fields[5] as String?,
      imageName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedClassification obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageBytes)
      ..writeByte(2)
      ..write(obj.region)
      ..writeByte(3)
      ..write(obj.queuedAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.imageName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
